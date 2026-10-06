"""Corner-basierte Übergangssets (16 Tiles + 4 Alternativen für gerade Kanten).

Tile-Index = TL*1 + TR*2 + BL*4 + BR*8 ; Bit = 1 heißt: diese Ecke gehört zum OBEREN Material.
Atlas 4 Spalten: Zeile r, Spalte c -> Index r*4+c. Zeile 4 = Alternativen für Index 3, 5, 10, 12.
"""
import numpy as np
from core import *
import materials as M

PAD = 3
PY, PX = np.mgrid[-PAD:N + PAD, -PAD:N + PAD]
ALT_IDS = [3, 5, 10, 12]


def bits(i):
    return (i >> 0) & 1, (i >> 1) & 1, (i >> 2) & 1, (i >> 3) & 1


def mask_field(i, X, Y, p, pv=None, amp=0.27):
    tl, tr, bl, br = bits(i)
    tx = np.clip((X + 0.5) / N, 0, 1)
    ty = np.clip((Y + 0.5) / N, 0, 1)
    # Smoothstep statt linear: Grenzen laufen weicher um Ecken
    tx = tx * tx * (3 - 2 * tx)
    ty = ty * ty * (3 - 2 * ty)
    b = (tl * (1 - tx) * (1 - ty) + tr * tx * (1 - ty) + bl * (1 - tx) * ty + br * tx * ty)
    m = 0.5 + (b - 0.5) * 2.4 + amp * p(X, Y)
    if pv is not None:
        # Variantenwelle verschwindet zum Tile-Rand hin -> Kanten bleiben kompatibel
        wx = np.sin(np.pi * np.clip((X + 0.5) / N, 0, 1))
        wy = np.sin(np.pi * np.clip((Y + 0.5) / N, 0, 1))
        m = m + 0.3 * pv(X, Y) * (wx * wy) ** 0.7
    return m


def make_noise(seed):
    a = pnoise(seed, maxf=4, decay=0.8, minf=2)
    b = pnoise(seed + 1, maxf=9, decay=0.3, minf=6)
    return lambda X, Y: (0.85 * a(X, Y) + 0.12 * b(X, Y))


def clean_mask(Mf, min_size=24):
    """Kleine Inseln/Löcher entfernen -> ruhige, bewusst wirkende Kante."""
    from scipy import ndimage
    for target in (True, False):
        lab, n = ndimage.label(Mf == target)
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        for j, s in enumerate(sizes, 1):
            if s < min_size:
                Mf[lab == j] = not target
    # Ein-Pixel-Zacken glätten
    for _ in range(2):
        nb = sum(np.roll(np.roll(Mf, dy, 0), dx, 1).astype(int)
                 for dy, dx in [(1, 0), (-1, 0), (0, 1), (0, -1)])
        Mf = np.where(Mf & (nb <= 1), False, Mf)
        Mf = np.where(~Mf & (nb >= 3), True, Mf)
    return Mf


TUFT_UP = [(0, -1, 3), (0, -2, 4), (-1, -1, 2), (2, -1, 3), (2, -2, 4), (3, -1, 2)]
TUFT_UP_S = [(0, -1, 3), (0, -2, 4), (1, -1, 2)]


def soft_edge_set(upper, lower, seed, up_ramp, low_shadow_k=0.62):
    """Gras liegt als leicht erhöhte Matte über dem unteren Material (Licht oben links)."""
    p = make_noise(seed)
    pv = pnoise(seed + 7, maxf=4, decay=0.8, minf=2)
    tiles = {}
    for key in list(range(16)) + [('alt', a) for a in ALT_IDS]:
        i = key if isinstance(key, int) else key[1]
        if i == 15:
            tiles[key] = upper.copy(); continue
        if i == 0:
            tiles[key] = lower.copy(); continue
        Mf = mask_field(i, PX, PY, p, pv if not isinstance(key, int) else None) > 0.5
        Mf = clean_mask(Mf)
        s = slice(PAD, PAD + N)
        m = Mf[s, s]
        up = lambda dy, dx: Mf[PAD + dy:PAD + dy + N, PAD + dx:PAD + dx + N]
        out = np.where(m[..., None], upper, lower).astype(np.uint8)
        low = out.astype(float)
        # Schlagschatten auf dem Boden: 1px unter/rechts kräftig, 2. Reihe unten leicht
        sh1 = (~m) & (up(-1, 0) | up(0, -1) | up(-1, -1))
        sh2 = (~m) & ~sh1 & up(-2, 0)
        out[sh1] = (low[sh1] * low_shadow_k).astype(np.uint8)
        out[sh2] = (low[sh2] * ((1 + low_shadow_k) / 2)).astype(np.uint8)
        # Seitenkante der Matte: unten 2px (dunkel + mittel), rechts 1px dunkel
        bot = m & ~up(1, 0)
        bot2 = m & ~bot & ~up(2, 0)
        right = m & ~bot & ~up(0, 1)
        top = m & ~bot & ~bot2 & (~up(-1, 0) | ~up(0, -1))
        out[bot2] = up_ramp[2]
        out[bot] = up_ramp[1]
        out[right] = up_ramp[1]
        out[top] = up_ramp[3]
        # Halmbüschel, die nach oben aus der Matte ragen (bewusst gesetzt, mit Abstand)
        last = -9
        cand = [(y, x) for y in range(3, N - 1) for x in range(3, N - 4) if m[y, x] and not m[y - 1, x]]
        cand.sort(key=lambda q: (q[1] * 11 + q[0] * 5 + i * 7) % 13)
        placed = []
        for (y, x) in cand:
            if any(abs(x - px) + abs(y - py) < 7 for py, px in placed):
                continue
            shape = TUFT_UP if (x + y + i) % 3 else TUFT_UP_S
            ok = all(0 <= x + dx < N and 1 <= y + dy and not m[y + dy, x + dx] or m[y + dy, x + dx]
                     for dx, dy, _ in shape)
            if not ok:
                continue
            for dx, dy, c in shape:
                if not m[y + dy, x + dx]:
                    out[y + dy, x + dx] = up_ramp[c]
            placed.append((y, x))
            if len(placed) >= 4:
                break
        tiles[key] = out
    return tiles


def cobble_set(lower, seed):
    """Pflaster endet steinweise im Weg: nur ganze Steine, 1px Aubergine-Fuge als Rahmen."""
    from scipy import ndimage
    p = make_noise(seed)
    pv = pnoise(seed + 7, maxf=4, decay=0.8, minf=2)
    fill = M.make_pflaster()[1]
    pts = list(M.PFL_POINTS)
    # Voronoi auf gepolstertem Raster, damit Nachbarpixel jenseits der Kante bekannt sind
    d = np.stack([tdist(PX, PY, px, py) for px, py in pts])
    order = np.argsort(d, axis=0)
    ds = np.take_along_axis(d, order, axis=0)
    lab = order[0]
    grout = (ds[1] - ds[0] < 1.0) | (ds[2] - ds[0] < 2.3)
    ptx = np.array([q[0] for q in pts])[lab].astype(float)
    pty = np.array([q[1] for q in pts])[lab].astype(float)
    ux = ptx + N * np.round((PX - ptx) / N)
    uy = pty + N * np.round((PY - pty) / N)
    s = slice(PAD, PAD + N)
    tiles = {}
    for key in list(range(16)) + [('alt', a) for a in ALT_IDS]:
        i = key if isinstance(key, int) else key[1]
        if i == 15:
            tiles[key] = fill.copy(); continue
        if i == 0:
            tiles[key] = lower.copy(); continue
        mv = mask_field(i, ux, uy, p, pv if not isinstance(key, int) else None) > 0.5
        stone = mv & ~grout
        frame = ndimage.binary_dilation(stone, structure=np.ones((3, 3), bool)) & ~stone
        area = stone | frame
        shadow = ~area & (np.roll(area, 1, 0) | np.roll(area, 1, 1))
        out = lower.copy()
        st, fr, sh = stone[s, s], frame[s, s], shadow[s, s]
        out[st] = fill[st]
        out[fr] = M.AUB
        out[sh] = (lower[sh] * 0.72).astype(np.uint8)
        tiles[key] = out
    return tiles


def atlas(tiles):
    a = np.zeros((5 * N, 4 * N, 3), np.uint8)
    for i in range(16):
        r, c = divmod(i, 4)
        a[r * N:(r + 1) * N, c * N:(c + 1) * N] = tiles[i]
    for c, i in enumerate(ALT_IDS):
        a[4 * N:5 * N, c * N:(c + 1) * N] = tiles[('alt', i)]
    return a


def build_all():
    g = M.make_grass()[1]
    e = M.make_soil('erde')[1]
    w = M.make_soil('weg')[1]
    return {
        'gras_erde': soft_edge_set(g, e, 700, M.GRAS),
        'gras_weg': soft_edge_set(g, w, 710, M.GRAS, low_shadow_k=0.68),
        'pflaster_weg': cobble_set(w, 720),
    }
