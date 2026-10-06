"""Gemeinsame Werkzeuge: periodisches Rauschen, Fenster, Stempel, Paletten."""
import numpy as np

N = 32
YY, XX = np.mgrid[0:N, 0:N]


def hx(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def pnoise(seed, maxf=4, decay=1.0, minf=1):
    """Exakt 32-periodisches glattes Feld (Summe ganzzahliger Kosinuswellen)."""
    rng = np.random.default_rng(seed)
    comps = []
    for kx in range(-maxf, maxf + 1):
        for ky in range(0, maxf + 1):
            if ky == 0 and kx <= 0:
                continue
            r = (kx * kx + ky * ky) ** 0.5
            if r > maxf + 0.5 or r < minf - 0.01:
                continue
            comps.append((kx, ky, rng.normal() / r ** decay, rng.uniform(0, 2 * np.pi)))

    def f(X=XX, Y=YY):
        v = np.zeros(np.shape(X), float)
        for kx, ky, a, p in comps:
            v += a * np.cos(2 * np.pi * (kx * X + ky * Y) / N + p)
        return v
    s = f().std()
    return lambda X=XX, Y=YY: f(X, Y) / s


def window(m0=2, m1=7):
    """0 im Randstreifen, 1 im Inneren – Varianten teilen sich so die Kanten."""
    d = np.minimum(np.minimum(XX, N - 1 - XX), np.minimum(YY, N - 1 - YY)).astype(float)
    return np.clip((d - m0) / (m1 - m0), 0, 1)


def tdist(ax, ay, bx, by):
    dx = np.abs(ax - bx) % N
    dy = np.abs(ay - by) % N
    dx = np.minimum(dx, N - dx)
    dy = np.minimum(dy, N - dy)
    return np.hypot(dx, dy)


def poisson(rng, n, mind, region=None, existing=(), tries=3000):
    """Punkte auf dem Torus mit Mindestabstand. region(x,y)->bool filtert."""
    pts = list(existing)
    out = []
    t = 0
    while len(out) < n and t < tries:
        t += 1
        x, y = int(rng.integers(0, N)), int(rng.integers(0, N))
        if region and not region(x, y):
            continue
        if all(tdist(x, y, px, py) >= mind for px, py in pts):
            pts.append((x, y))
            out.append((x, y))
    return out


def edge_dist(x, y):
    return min(x, y, N - 1 - x, N - 1 - y)


def stamp_rel(idx, pat, ax, ay, rel, lo, hi, wrap=True, base=None):
    """Relativer Stempel: Zeichen -> Index-Offset zur Grundfarbe am Ankerpunkt."""
    b = idx[ay % N, ax % N] if base is None else base
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch == '.' or ch == ' ':
                continue
            x, y = ax + i, ay + j
            if not wrap and not (0 <= x < N and 0 <= y < N):
                continue
            idx[y % N, x % N] = int(np.clip(b + rel[ch], lo, hi))


def stamp_abs(img, pat, ax, ay, cmap, wrap=False):
    """Absoluter Farbstempel auf RGB-Bild. cmap: Zeichen -> RGB oder Funktion(alt)->RGB."""
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch in '. ':
                continue
            x, y = ax + i, ay + j
            if not wrap and not (0 <= x < N and 0 <= y < N):
                continue
            c = cmap[ch]
            old = tuple(img[y % N, x % N])
            img[y % N, x % N] = c(old) if callable(c) else c


def render(idx, ramp):
    ramp = np.array(ramp, dtype=np.uint8)
    return ramp[idx]


def shade(c, k):
    return tuple(int(np.clip(v * k, 0, 255)) for v in c)
