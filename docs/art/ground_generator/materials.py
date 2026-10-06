"""Fülltiles aller Bodenarten. Jede Funktion liefert {variante: RGB-Array}."""
import numpy as np
from core import *

# ---------------------------------------------------------------- Paletten
# Styleguide-Anker (CLAUDE.md): Tiefschwarz 0E0A14, Aubergine 2B1633, Nachtblau 141B3A,
# Bordeaux 6E1830, Magenta C2307A, Gold D9A441, Kerzenlicht FFB566, Giftgrün 3F7D5A, Knochen EADFCB.
# Rampen sind hue-geshiftet: Schatten Richtung Aubergine/Nachtblau, Lichter wärmer.
AUB = hx('2B1633')
TIEF = hx('0E0A14')
BORD = hx('6E1830')
MAG = hx('C2307A')
GOLD = hx('D9A441')
KERZE = hx('FFB566')
GIFT = hx('3F7D5A')
BONE = hx('EADFCB')

GRAS = [(18, 22, 30), (24, 36, 36), (30, 49, 42), (38, 64, 50), (49, 84, 60), (63, 112, 78), GIFT]
ERDE = [(24, 14, 24), (33, 21, 28), (43, 29, 32), (55, 39, 37), (70, 51, 45), (90, 68, 56), (112, 88, 70)]
WEG = [(38, 26, 32), (54, 40, 40), (68, 53, 47), (81, 64, 54), (96, 77, 63), (114, 94, 75), (136, 115, 92)]
BEET = [(20, 11, 20), (29, 18, 25), (39, 25, 30), (51, 34, 35), (65, 46, 42), (82, 61, 52)]
STEIN = [AUB, (48, 40, 60), (60, 53, 74), (72, 66, 87), (86, 80, 101), (104, 98, 118), (124, 118, 136)]
PLATTE = [(20, 20, 38), (36, 38, 56), (45, 48, 67), (54, 58, 78), (65, 69, 90), (80, 85, 106), (98, 103, 124)]

W = window(2, 8)
RING = 2


def ring_copy(dst, src, r=RING):
    m = np.ones((N, N), bool)
    m[r:N - r, r:N - r] = False
    dst[m] = src[m]


def finish(variants):
    """Randstreifen aller Varianten = Variante 1 -> beliebig kombinierbar."""
    ref = variants[1]
    for k, v in variants.items():
        if k != 1:
            ring_copy(v, ref)
    return variants


# ---------------------------------------------------------------- Deko-Stempel (absolut)
def dk(c, k=0.7):
    return lambda old: shade(old, k)


FLOWER_BONE = (["..p..", ".pyp.", "..ps."],)
FLOWER = [".p.", "pyp", ".ps"]
FLOWER_BIG = [".p.p", "pyyp", ".pps", "..s."]
MUSHROOM = [".oO.", "oOOo", "sbbs", ".ws."]
MUSHROOM_S = ["oO", "bs"]
LEAF = ["..R.", ".RrR", "rRr.", ".ds."]
CLOVER = [".c.", "cCc", ".cs"]


# ---------------------------------------------------------------- GRAS (Garten)
GRASS_STAMPS = [
    (["a..", "b.a", "bcb", ".c."], 3),
    ([".a.", "ab.", "bc.", "c.."], 3),
    (["a.a", "b.b", "cbc"], 3),
    (["a", "b", "c"], 2),
    (["..a", ".ab", "abc", "bc."], 3),
]
GREL = {'a': 2, 'b': 1, 'c': -1}


def grass_base(seed_var, w=W):
    c = pnoise(331, maxf=5, minf=2)()
    h = pnoise(332, maxf=7, decay=0.6, minf=3)()
    v = pnoise(seed_var, maxf=4, minf=2)()
    c = (1 - w) * c + w * v
    h2 = pnoise(seed_var + 1, maxf=7, decay=0.6, minf=3)()
    h = (1 - w) * h + w * h2
    f = c + 0.45 * h
    idx = np.full((N, N), 2)
    idx[f < -0.85] = 1
    idx[f > 0.85] = 3
    return idx


def grass(seed, density, common_pts, interior=True):
    rng = np.random.default_rng(seed)
    idx = grass_base(seed)
    pts = list(common_pts)
    if interior:
        pts += poisson(rng, density, 4.2, region=lambda x, y: 4 <= x <= 25 and 4 <= y <= 25,
                       existing=common_pts)
    for (x, y) in pts:
        pat, _ = GRASS_STAMPS[(x * 7 + y * 13) % len(GRASS_STAMPS)]
        rel = GREL if (x + 2 * y) % 3 else {'a': 1, 'b': 1, 'c': -1}
        stamp_rel(idx, pat, x, y, rel, 0, 5, base=min(idx[y, x], 3))
    # vereinzelte Giftgrün-Spitzen (Garten-Glimmer)
    for (x, y) in pts[::7]:
        if idx[y % N, x % N] >= 4:
            idx[y % N, x % N] = 6
    return idx


def make_grass():
    rng = np.random.default_rng(5)
    common = poisson(rng, 40, 4.2, region=lambda x, y: edge_dist(x, y) < 4)
    v = {}
    for k, (seed, dens) in {1: (100, 14), 2: (101, 16), 3: (102, 15),
                            4: (103, 12), 5: (104, 12), 6: (105, 11)}.items():
        v[k] = render(grass(seed, dens, common), GRAS)
    finish(v)
    # Deko: 4 = Blüten, 5 = Pilz + Klee, 6 = Glimmer-Blüten (magisch)
    g = GRAS
    stamp_abs(v[4], FLOWER, 9, 10, {'p': BONE, 'y': GOLD, 's': g[0]})
    stamp_abs(v[4], FLOWER, 20, 19, {'p': (200, 188, 168), 'y': GOLD, 's': g[0]})
    stamp_abs(v[4], ["p", "s"], 14, 23, {'p': BONE, 's': g[1]})
    stamp_abs(v[4], ["p"], 24, 8, {'p': (200, 188, 168)})
    stamp_abs(v[5], MUSHROOM, 15, 13, {'o': (176, 98, 52), 'O': KERZE, 'b': (196, 178, 150),
                                        's': g[0], 'w': (150, 136, 118)})
    stamp_abs(v[5], MUSHROOM_S, 20, 17, {'o': (176, 98, 52), 'O': KERZE, 'b': (150, 136, 118), 's': g[0]})
    stamp_abs(v[5], CLOVER, 8, 22, {'c': g[4], 'C': g[5], 's': g[0]})
    stamp_abs(v[6], FLOWER, 11, 16, {'p': MAG, 'y': KERZE, 's': g[0]})
    stamp_abs(v[6], FLOWER, 21, 9, {'p': (150, 36, 98), 'y': GOLD, 's': g[0]})
    stamp_abs(v[6], ["p", "s"], 19, 23, {'p': MAG, 's': g[1]})
    return v


# ---------------------------------------------------------------- ERDE (wild, Garten/Wald)
CLOD = [
    [".hh.", "hmmm", "mmms", ".ss."],
    ["hh.", "hms", ".s."],
    [".h.", "hms", ".s."],
    ["hhh.", "hmmm", "mmss", ".s.."],
]
CREL = {'h': 2, 'm': 1, 's': -1}
PEBBLE = [".hm", "hmm", ".dd"]


def soil_base(c_seed, h_seed, seed_var, levels, w=W):
    c = pnoise(c_seed, maxf=5, minf=2)()
    h = pnoise(h_seed, maxf=8, decay=0.4, minf=3)()
    c = (1 - w) * c + w * pnoise(seed_var, maxf=4, minf=2)()
    h = (1 - w) * h + w * pnoise(seed_var + 50, maxf=8, decay=0.4, minf=3)()
    f = c + 0.35 * h
    idx = np.full((N, N), levels[1])
    idx[f < -0.55] = levels[0]
    idx[f > 0.75] = levels[2]
    return idx


def make_soil(kind):
    if kind == 'erde':
        ramp, levels, cseed, hseed, cl_n, peb_n, base_seed = ERDE, (1, 2, 3), 121, 122, 7, 3, 200
    else:
        ramp, levels, cseed, hseed, cl_n, peb_n, base_seed = WEG, (2, 3, 4), 176, 177, 3, 5, 300
    rng = np.random.default_rng(base_seed)
    common_cl = poisson(rng, 12, 5.5, region=lambda x, y: edge_dist(x, y) < 3)
    common_pb = poisson(rng, 6, 6, region=lambda x, y: edge_dist(x, y) < 3, existing=common_cl)
    v = {}
    for k in range(1, 6):
        r = np.random.default_rng(base_seed + k)
        idx = soil_base(cseed, hseed, base_seed + k, levels)
        cl = list(common_cl)[: (12 if kind == "erde" else 2)]
        cl += poisson(r, cl_n, 5.5, region=lambda x, y: 3 <= edge_dist(x, y) and edge_dist(x, y) < 13,
                      existing=common_cl + common_pb)
        for (x, y) in cl:
            pat = CLOD[(x * 3 + y * 5) % len(CLOD)]
            if kind == 'weg':
                pat = CLOD[2]
            stamp_rel(idx, pat, x, y, CREL, 0, len(ramp) - 1, base=levels[1])
        pb = list(common_pb) + poisson(r, peb_n, 6, region=lambda x, y: 3 <= edge_dist(x, y) < 13,
                                       existing=cl + common_pb)
        for (x, y) in pb:
            stamp_rel(idx, PEBBLE, x, y, {'h': 3, 'm': 2, 'd': -2}, 0, len(ramp) - 1, base=levels[1])
        # Krümel / Einzelpixel
        for _ in range(10 if kind == 'erde' else 6):
            x, y = int(r.integers(2, 30)), int(r.integers(2, 30))
            idx[y, x] = max(idx[y, x] - 1, 0) if r.random() < .6 else min(idx[y, x] + 2, len(ramp) - 1)
        v[k] = render(idx, ramp)
    finish(v)
    e = ramp
    if kind == 'erde':
        # 4 = Wurzel + Blatt, 5 = Pilzgruppe
        root = ["hh.....", "ssh....", "..sshh.", "....ssh", "......s"]
        stamp_abs(v[4], root, 8, 9, {'h': e[4], 's': e[0]})
        stamp_abs(v[4], ["h..", "sh.", ".sh", "..s"], 18, 12, {'h': e[4], 's': e[0]})
        stamp_abs(v[4], LEAF, 19, 20, {'R': BORD, 'r': (90, 26, 46), 'd': (60, 18, 36), 's': e[0]})
        stamp_abs(v[5], MUSHROOM, 12, 12, {'o': (176, 98, 52), 'O': KERZE, 'b': (196, 178, 150),
                                            's': e[0], 'w': (150, 136, 118)})
        stamp_abs(v[5], MUSHROOM_S, 17, 15, {'o': (176, 98, 52), 'O': KERZE, 'b': (150, 136, 118), 's': e[0]})
        stamp_abs(v[5], MUSHROOM_S, 10, 18, {'o': (150, 80, 46), 'O': (230, 150, 90), 'b': (150, 136, 118), 's': e[0]})
    else:
        # 4 = Laub, 5 = Kiesel-Häufung + Fußspur-Mulde
        stamp_abs(v[4], LEAF, 10, 11, {'R': BORD, 'r': (90, 26, 46), 'd': (60, 18, 36), 's': e[1]})
        stamp_abs(v[4], [".g.", "gGg", ".gs"], 20, 18, {'g': (150, 112, 50), 'G': GOLD, 's': e[1]})
        for (x, y) in [(12, 18), (15, 20), (18, 16), (20, 21)]:
            stamp_abs(v[5], [".hm", "hmm", ".dd"], x, y, {'h': e[6], 'm': e[5], 'd': e[0]})
        stamp_abs(v[5], ["mmm.", "mmmm", ".mm."], 8, 9, {'m': dk(None, 0.85)})
    return v


# ---------------------------------------------------------------- BEET (bestellte Reihen)
def make_beet():
    v = {}
    ridge_top = 5 + np.round(0.8 * np.cos(2 * np.pi * np.arange(N) / N * 2 + 1.0)
                             + 0.5 * np.cos(2 * np.pi * np.arange(N) / N * 3 + 2.0)).astype(int)
    ridge_bot = 26 + np.round(0.7 * np.cos(2 * np.pi * np.arange(N) / N * 2 + 2.6)
                              + 0.4 * np.cos(2 * np.pi * np.arange(N) / N * 5)).astype(int)
    for k in range(1, 4):
        r = np.random.default_rng(400 + k)
        tex = pnoise(41 if k == 1 else 41 + k * 3, maxf=8, decay=0.4)()
        tex = (1 - W) * pnoise(41, maxf=8, decay=0.4)() + W * tex
        idx = np.full((N, N), 1)
        for x in range(N):
            t, b = ridge_top[x], ridge_bot[x]
            for y in range(N):
                if t <= y <= b:
                    lvl = 3 if tex[y, x] > 0.2 else 2
                    if y == t:
                        lvl = 4
                    elif y == t + 1:
                        lvl = 4 if tex[y, x] > -0.3 else 3
                    elif y == b:
                        lvl = 1
                    elif y == b - 1:
                        lvl = 2
                    idx[y, x] = lvl
                else:
                    idx[y, x] = 0 if (y == b + 1 or y == (t - 1)) and tex[y, x] < 0.6 else 1
        # Erdklumpen auf dem Damm
        for (x, y) in poisson(r, 6, 6, region=lambda x, y: 4 <= x <= 26 and 10 <= y <= 20):
            stamp_rel(idx, ["hh.", "hms", ".s."], x, y, {'h': 2, 'm': 1, 's': -1}, 0, 5, base=2)
        for (x, y) in poisson(r, 4, 5, region=lambda x, y: 3 <= x <= 28 and 8 <= y <= 23):
            idx[y, x] = 1
        v[k] = render(idx, BEET)
    finish(v)
    # nasse Varianten (gegossen): dunkler, kühler, Glanzpunkte
    for k in range(1, 4):
        a = v[k].astype(float)
        wet = a * np.array([0.74, 0.72, 0.80])
        wet = wet.astype(np.uint8)
        v[k + 3] = wet
    # Glanz bewusst nur innen, nicht am Rand
    for k, pts in {4: [(9, 7), (22, 8), (15, 18)], 5: [(12, 8), (25, 12)], 6: [(7, 9), (18, 7), (21, 20)]}.items():
        for (x, y) in pts:
            v[k][y, x] = (84, 74, 96); v[k][y, x + 1] = (58, 48, 68)
    return v


# ---------------------------------------------------------------- PFLASTER (Dorf)
def voronoi(points):
    d = np.stack([tdist(XX, YY, px, py) for px, py in points])
    order = np.argsort(d, axis=0)
    ds = np.take_along_axis(d, order, axis=0)
    return order[0], ds[0], ds[1], ds[2]


PFL_POINTS = [(4, 3), (14, 2), (23, 6), (31, 12), (8, 11), (18, 10), (2, 19), (11, 22),
              (25, 18), (5, 29), (18, 28), (28, 26), (15, 16), (29, 1)]


def cobble(points, tone_seed, grout_w=1.0):
    lab, d1, d2, d3 = voronoi(points)
    grout = (d2 - d1 < grout_w) | (d3 - d1 < 2.3)
    idx = np.full((N, N), 3)
    rng = np.random.default_rng(tone_seed)
    tones = {}
    for i, (px, py) in enumerate(points):
        tones[i] = [2, 3, 3, 4, 2][(px * 5 + py * 11) % 5]
    for y in range(N):
        for x in range(N):
            if grout[y, x]:
                idx[y, x] = 0
                continue
            t = tones[lab[y, x]]
            up, lf = grout[(y - 1) % N, x], grout[y, (x - 1) % N]
            dn, rt = grout[(y + 1) % N, x], grout[y, (x + 1) % N]
            dn2 = grout[(y + 2) % N, x]
            up2, lf2 = grout[(y - 2) % N, x], grout[y, (x - 2) % N]
            if up and lf:
                t += 3
            elif up or lf:
                t += 2
            elif up2 or lf2:
                t += 1
            if dn or rt:
                t = min(t, tones[lab[y, x]]) - 1
                if dn and rt:
                    t -= 1
            idx[y, x] = int(np.clip(t, 1, 6))
    return idx, lab, grout


def make_pflaster():
    v, meta = {}, {}
    inner = [(15, 16)]
    alt = {1: [(15, 16)], 2: [(13, 15), (19, 18)], 3: [(16, 14)], 4: [(14, 17)], 5: [(17, 16)]}
    for k in range(1, 6):
        pts = [p for p in PFL_POINTS if p not in inner] + alt[k]
        idx, lab, grout = cobble(pts, k)
        r = np.random.default_rng(500 + k)
        # Fleckige Steinoberfläche (2er-Cluster)
        for (x, y) in poisson(r, 12, 4, region=lambda x, y: edge_dist(x, y) >= 3):
            if not grout[y, x] and 2 <= idx[y, x] <= 4:
                idx[y, x] -= 1
                if x + 1 < N and not grout[y, x + 1]:
                    idx[y, x + 1] = max(idx[y, x + 1] - 1, 1)
        v[k] = render(idx, STEIN)
        meta[k] = (idx, grout)
    finish(v)
    # tiefe Fugenpunkte in Tiefschwarz-Aubergine
    for k in range(1, 6):
        idx, grout = meta[k]
    # Deko 4: Moos in Fugen, 5: Riss + Bordeaux-Blatt + Wachstropfen
    idx, grout = meta[4]
    moss_pts = [(x, y) for y in range(5, 27) for x in range(5, 27) if grout[y, x]]
    r = np.random.default_rng(9)
    cx, cy = 12, 14
    for (x, y) in moss_pts:
        dd = ((x - cx) ** 2 + (y - cy) ** 2) ** .5
        if dd < 6.5 and r.random() < 0.85:
            v[4][y, x] = GRAS[3] if (x + y) % 3 else GRAS[4]
        elif dd < 8 and r.random() < 0.3:
            v[4][y, x] = GRAS[2]
    for (x, y) in [(22, 21), (23, 22)]:
        if grout[y, x]:
            v[4][y, x] = GRAS[3]
    idx5, grout5 = meta[5]
    crack = [(10, 9), (11, 10), (11, 11), (12, 12), (12, 13)]
    for (x, y) in crack:
        if not grout5[y, x]:
            v[5][y, x] = STEIN[1]
            if not grout5[y, x + 1]:
                v[5][y, x + 1] = STEIN[5] if idx5[y, x + 1] >= 3 else v[5][y, x + 1]
    stamp_abs(v[5], LEAF, 19, 18, {'R': BORD, 'r': (90, 26, 46), 'd': (60, 18, 36), 's': AUB})
    # Kerzenwachs-Tropfen (Dorf = Kerzenlicht)
    stamp_abs(v[5], [".w", "ww"], 22, 9, {'w': (214, 196, 166)})
    stamp_abs(v[5], ["w"], 25, 11, {'w': (184, 166, 140)})
    return v


# ---------------------------------------------------------------- PLATTE (Friedhof / Hexenhaus)
def slab_layout():
    """Laeuferverband: Fugen y=0,16; Reihe 0: x=0,16; Reihe 1: x=8,24."""
    joint = np.zeros((N, N), bool)
    slab = np.zeros((N, N), int)
    joint[0, :] = joint[16, :] = True
    for y in range(N):
        row = 0 if y < 16 else 1
        for x in range(N):
            if row == 0:
                if x in (0, 16):
                    joint[y, x] = True
                slab[y, x] = 0 if x < 16 else 1
            else:
                if x in (8, 24):
                    joint[y, x] = True
                slab[y, x] = 2 if 8 <= x < 24 else 3
    return joint, slab


def make_platte():
    joint, slab = slab_layout()
    tone = {0: 3, 1: 2, 2: 3, 3: 2}
    v, meta = {}, {}
    for k in range(1, 6):
        f = (1 - W) * pnoise(61, maxf=6, decay=0.5, minf=2)() + W * pnoise(61 + k, maxf=6, decay=0.5, minf=2)()
        idx = np.zeros((N, N), int)
        for y in range(N):
            for x in range(N):
                if joint[y, x]:
                    idx[y, x] = 0
                    continue
                t = tone[slab[y, x]] + (1 if f[y, x] > 0.9 else 0) - (1 if f[y, x] < -1.0 else 0)
                up, lf = joint[(y - 1) % N, x], joint[y, (x - 1) % N]
                dn, rt = joint[(y + 1) % N, x], joint[y, (x + 1) % N]
                if up or lf:
                    t = tone[slab[y, x]] + 2
                if dn or rt:
                    t = 1
                if (up or lf) and (dn or rt):
                    t = tone[slab[y, x]]
                idx[y, x] = int(np.clip(t, 1, 6))
        # abgeschlagene Ecken (gemeinsam, an Fugenkreuzen)
        for (x, y) in [(15, 15), (1, 17), (23, 31), (17, 1)]:
            idx[y, x] = 0 if joint[(y + 1) % N, x] or joint[y, (x + 1) % N] or joint[(y - 1) % N, x] else 1
        meta[k] = idx
        v[k] = render(idx, PLATTE)
    finish(v)
    P = PLATTE
    cracks = {
        2: [(5, 6, 'c'), (6, 7, 'c'), (6, 8, 'c'), (7, 9, 'c'), (7, 10, 'c'), (8, 11, 'c')],
        3: [(11, 23, 'c'), (12, 24, 'c'), (12, 25, 'c')],
        5: [(9, 4, 'c'), (9, 5, 'c'), (10, 6, 'c'), (10, 7, 'c'), (11, 8, 'c')],
    }
    for k, cs in cracks.items():
        for (x, y, _) in cs:
            v[k][y, x] = P[1]
            v[k][y, x + 1] = P[5] if not joint[y, x + 1] else v[k][y, x + 1]
    # 4: Moos kriecht aus der Fuge + kleines Farnblatt
    for (x, y) in [(15, 17), (16, 17), (16, 18), (17, 18), (16, 19), (8, 18), (8, 19), (9, 19),
                   (14, 16), (15, 16), (17, 16), (18, 16), (19, 15), (16, 14), (16, 15)]:
        v[4][y, x] = GRAS[3] if (x + y) % 2 else GRAS[2]
    for (x, y) in [(18, 17), (16, 20), (13, 16)]:
        v[4][y, x] = GRAS[4]
    fern = ["..f", ".fF", "fF.", "s.."]
    stamp_abs(v[4], fern, 21, 22, {'f': GRAS[3], 'F': GRAS[5], 's': P[1]})
    # 5: schwach glimmende Rune (Magenta = Magie/Gefahr) auf einer Platte
    rune = ["..m..", ".m.m.", "mmMmm", ".m.m.", "..m.."]
    stamp_abs(v[5], rune, 19, 5, {'m': (96, 40, 84), 'M': MAG})
    return v
