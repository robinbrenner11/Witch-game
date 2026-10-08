"""Ruhigere Böden (Vorschlag 08.10.2026): Gras nur noch als Inseln, Grundfläche
ist Erde (Garten) bzw. Waldboden (Wald).

Aufruf (aus dem Projektordner):
  python docs/art/ground_generator/calm.py assets/environment/ground
Benötigt: numpy, pillow, scipy (wie build.py)

Erzeugt im Ausgabeordner:
  ground_earth_1..5.png         Gartenerde, ruhig (1-3 Basis, 4 Moos, 5 Blatt + Zweig)
  ground_forest_floor_1..5.png  Waldboden mit Laubstreu (1-3 Basis, 4 Moos, 5 Zweig + Pilz)
  ground_meadow_1..5.png        Grasmatte für Inseln (1-3 Basis, 4 Blüten, 5 Klee)
  transitions/transition_meadow_earth.png         Grasinsel über Gartenerde
  transitions/transition_meadow_forest_floor.png  Grasinsel über Waldboden
  transitions/transition_forest_floor_path.png    Waldboden über Trampelpfad
  transitions/transition_earth_path.png           Gartenerde über Trampelpfad
  transitions/transition_meadow_path.png          Wiese über Trampelpfad
Übergänge wie gehabt: 4x5 Tiles, Index = TL*1 + TR*2 + BL*4 + BR*8, Bit = oberes Material.

Warum ruhiger: Das alte Gras hatte 14-16 Halmstriche pro Tile, gleichmäßig verteilt,
dazu feines Hell-Dunkel-Rauschen. Auf großer Fläche wirkt das wie ein Teppich. Hier
tragen nur große, weiche Tonflächen die Fläche; Details kommen in kleinen Gruppen.
"""
import os
import sys
import numpy as np
from PIL import Image
from core import *
import materials as M
from transitions import soft_edge_set, atlas, mask_field, clean_mask, make_noise, ALT_IDS, PAD, PX, PY
from core import pnoise

GRAS = M.GRAS
ERDE = M.ERDE
# Waldboden: dunkler und violetter als Gartenerde, damit Wald und Garten sich unterscheiden
WALD = [(16, 11, 22), (23, 16, 29), (31, 21, 36), (40, 28, 43), (51, 36, 50), (65, 47, 58), (82, 60, 68)]
# Laubstreu: gedämpft, damit sie nicht mit Blüten/Pilzen konkurriert
LITTER = [(84, 24, 48), (104, 72, 84), (120, 88, 56), (96, 94, 72), (130, 96, 104)]
MOSS = [GRAS[1], GRAS[2], GRAS[3], GRAS[4]]


def calm_field(seed, seed_var, levels, lo=-0.7, hi=0.8, fine=0.15):
    """Nur große, weiche Tonflächen (niedrige Frequenzen), kaum Feinrauschen."""
    w = M.W
    c = pnoise(seed, maxf=3, minf=1)()
    c = (1 - w) * c + w * pnoise(seed_var, maxf=3, minf=1)()
    h = pnoise(seed + 1, maxf=7, decay=0.5, minf=4)()
    h = (1 - w) * h + w * pnoise(seed_var + 1, maxf=7, decay=0.5, minf=4)()
    f = c + fine * h
    idx = np.full((N, N), levels[1])
    idx[f < lo] = levels[0]
    idx[f > hi] = levels[2]
    return idx


def inner(x, y):
    return 3 <= edge_dist(x, y)


# ---------------------------------------------------------------- Gartenerde
def make_hof():
    rng = np.random.default_rng(900)
    common = poisson(rng, 4, 8, region=lambda x, y: edge_dist(x, y) < 3)
    v = {}
    for k in range(1, 6):
        r = np.random.default_rng(900 + k)
        idx = calm_field(901, 910 + k, (1, 2, 3), lo=-0.95, hi=1.25)
        pts = list(common) + poisson(r, 3, 9, region=inner, existing=common)
        for (x, y) in pts:                                   # wenige, kleine Krumen
            stamp_rel(idx, M.CLOD[2], x, y, M.CREL, 0, 6, base=2)
        for (x, y) in poisson(r, 2, 10, region=inner, existing=pts):
            stamp_rel(idx, M.PEBBLE, x, y, {'h': 3, 'm': 2, 'd': -2}, 0, 6, base=2)
        for _ in range(5):
            x, y = int(r.integers(3, 29)), int(r.integers(3, 29))
            idx[y, x] = max(idx[y, x] - 1, 0)
        v[k] = render(idx, ERDE)
    M.finish(v)
    e = ERDE
    moss = ["..mm..", ".mMMm.", "mMMMmm", ".mmms.", "..ss.."]
    stamp_abs(v[4], moss, 12, 12, {'m': MOSS[1], 'M': MOSS[2], 's': e[1]})
    stamp_abs(v[4], [".m", "mM", "s."], 20, 18, {'m': MOSS[1], 'M': MOSS[2], 's': e[1]})
    stamp_abs(v[5], M.LEAF, 11, 12, {'R': M.BORD, 'r': (90, 26, 46), 'd': (60, 18, 36), 's': e[1]})
    stamp_abs(v[5], ["hh....", "..hhh.", ".....h", "ssssss"], 15, 19,
              {'h': e[5], 's': lambda o: shade(o, 0.75)})
    return v


# ---------------------------------------------------------------- Waldboden
LEAVES = [[".aa", "aab", ".bs"], ["aa.", "abb", ".s."], [".a", "ab", "s."], ["ab", "bs"]]


def make_waldboden():
    rng = np.random.default_rng(950)
    common = poisson(rng, 5, 7, region=lambda x, y: edge_dist(x, y) < 3)
    v = {}
    for k in range(1, 6):
        r = np.random.default_rng(950 + k)
        idx = calm_field(951, 960 + k, (2, 3, 4), lo=-0.85, hi=1.2)
        img = render(idx, WALD)
        pts = list(common)
        # Laub liegt in 2-3 Haufen, dazwischen bleibt der Boden ruhig
        for (cx, cy) in poisson(r, 3, 11, region=lambda x, y: 6 <= x <= 24 and 6 <= y <= 24):
            for j in range(6):
                a = r.uniform(0, 6.28)
                d = r.uniform(0, 4.5)
                pts.append((int(cx + np.cos(a) * d), int(cy + np.sin(a) * d * 0.7)))
        for i, (x, y) in enumerate(pts):
            col = LITTER[(x * 7 + y * 3) % len(LITTER)]
            pat = LEAVES[(x + 2 * y) % len(LEAVES)]
            stamp_abs(img, pat, x, y, {'a': col, 'b': shade(col, 0.8), 's': WALD[0]}, wrap=True)
        v[k] = img
    M.finish(v)
    w = WALD
    moss = ["..mmm..", ".mMMMm.", "mMMMMMm", ".mmMmm.", "..sss.."]
    stamp_abs(v[4], moss, 11, 12, {'m': MOSS[0], 'M': MOSS[1], 's': w[0]})
    stamp_abs(v[4], [".mm", "mMm", ".s."], 20, 19, {'m': MOSS[0], 'M': MOSS[1], 's': w[0]})
    stamp_abs(v[5], ["h......", ".hh....", "...hhh.", "......h", ".sssss."], 10, 12,
              {'h': (78, 52, 64), 's': w[0]})
    stamp_abs(v[5], M.MUSHROOM_S, 19, 19, {'o': (150, 80, 46), 'O': (230, 150, 90),
                                           'b': (150, 136, 118), 's': w[0]})
    return v


# ---------------------------------------------------------------- Wiese (für Inseln)
def make_wiese():
    rng = np.random.default_rng(1000)
    common = poisson(rng, 6, 6, region=lambda x, y: edge_dist(x, y) < 3)
    v = {}
    for k in range(1, 6):
        r = np.random.default_rng(1000 + k)
        idx = calm_field(1001, 1010 + k, (2, 3, 4), lo=-1.05, hi=1.6, fine=0.08)
        pts = list(common)
        # Halme nur in 2-3 kleinen Gruppen statt flächig
        for (cx, cy) in poisson(r, 3, 10, region=lambda x, y: 6 <= x <= 25 and 6 <= y <= 25):
            for j in range(4):
                pts.append((cx + int(r.integers(-3, 4)), cy + int(r.integers(-2, 3))))
        for (x, y) in pts:
            pat, _ = M.GRASS_STAMPS[(x * 7 + y * 13) % len(M.GRASS_STAMPS)]
            stamp_rel(idx, pat, x, y, M.GREL, 0, 5, base=min(idx[y % N, x % N], 3))
        v[k] = render(idx, GRAS)
    M.finish(v)
    g = GRAS
    stamp_abs(v[4], M.FLOWER, 10, 11, {'p': M.BONE, 'y': M.GOLD, 's': g[1]})
    stamp_abs(v[4], M.FLOWER, 19, 18, {'p': (200, 188, 168), 'y': M.GOLD, 's': g[1]})
    stamp_abs(v[5], M.CLOVER, 11, 13, {'c': g[4], 'C': g[5], 's': g[1]})
    stamp_abs(v[5], M.CLOVER, 17, 17, {'c': g[4], 'C': g[5], 's': g[1]})
    stamp_abs(v[5], M.CLOVER, 13, 19, {'c': g[3], 'C': g[4], 's': g[1]})
    return v


# ---------------------------------------------------------------- gewachsene Graskante
def _h(x, y, seed):
    """deterministisch je Pixel auf dem 32er-Torus -> Nachbarkacheln entscheiden gleich."""
    v = ((x % N) * 73856093) ^ ((y % N) * 19349663) ^ (seed * 83492791)
    v = (v ^ (v >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((v ^ (v >> 16)) & 0xFFFF) / 65535.0


def meadow_edge_set(upper, lower, seed, ramp, low_shadow_k=0.78):
    """Grasinsel ohne 'Teppichkante': unruhigere Grenze, keine durchgehende
    Seitenkante, Halme wachsen über den Rand, einzelne Halme stehen davor.
    Gleiche Kachel-Logik wie soft_edge_set (Index = TL*1 + TR*2 + BL*4 + BR*8)."""
    p0 = make_noise(seed)
    fine = pnoise(seed + 3, maxf=10, decay=0.2, minf=7)
    p = lambda X, Y: p0(X, Y) + 0.22 * fine(X, Y)
    pv = pnoise(seed + 7, maxf=4, decay=0.8, minf=2)
    tiles = {}
    s_ = slice(PAD, PAD + N)
    for key in list(range(16)) + [('alt', a) for a in ALT_IDS]:
        i = key if isinstance(key, int) else key[1]
        if i == 15:
            tiles[key] = upper.copy(); continue
        if i == 0:
            tiles[key] = lower.copy(); continue
        Mf = mask_field(i, PX, PY, p, pv if not isinstance(key, int) else None, amp=0.34) > 0.5
        Mf = clean_mask(Mf, min_size=12)
        out_p = np.where(Mf[..., None], np.pad(upper, ((PAD, PAD), (PAD, PAD), (0, 0)), mode="wrap"),
                         np.pad(lower, ((PAD, PAD), (PAD, PAD), (0, 0)), mode="wrap")).astype(np.uint8)
        H_, W_ = Mf.shape
        gx = PX % N
        gy = PY % N

        def inside(y, x):
            return 0 <= y < H_ and 0 <= x < W_ and Mf[y, x]

        for y in range(H_):
            for x in range(W_):
                X, Y = int(gx[y, x]), int(gy[y, x])
                if Mf[y, x]:
                    # Kante nur stellenweise dunkler (statt durchgehender Seitenkante)
                    if not inside(y + 1, x) and _h(X, Y, seed) > 0.45:
                        out_p[y, x] = ramp[1]
                    elif not inside(y - 1, x) and _h(X, Y, seed + 1) > 0.5:
                        out_p[y, x] = ramp[4]                      # Licht auf der Oberkante
                else:
                    # Halme wachsen über den Rand nach oben/außen
                    below = inside(y + 1, x)
                    near = below or inside(y, x - 1) or inside(y, x + 1)
                    if below and _h(X, Y, seed + 2) > 0.45:
                        out_p[y, x] = ramp[3] if _h(X, Y, seed + 3) > 0.4 else ramp[4]
                        if y > 0 and _h(X, Y, seed + 4) > 0.65 and not inside(y - 1, x):
                            out_p[y - 1, x] = ramp[4]              # längerer Halm
                    elif near and _h(X, Y, seed + 5) > 0.7:
                        out_p[y, x] = ramp[3]
                    elif inside(y - 1, x) and _h(X, Y, seed + 6) > 0.35:
                        # leichter Schlagschatten unter der Kante (nicht überall)
                        out_p[y, x] = (out_p[y, x].astype(float) * low_shadow_k).astype(np.uint8)
        # einzelne Halmbüschel, die vor der Insel stehen (Abstand 2-4 px)
        for y in range(H_):
            for x in range(W_):
                if Mf[y, x]:
                    continue
                X, Y = int(gx[y, x]), int(gy[y, x])
                if _h(X, Y, seed + 9) < 0.985:
                    continue
                close = any(inside(y + dy, x + dx) for dy in range(-4, 5) for dx in range(-4, 5))
                touching = any(inside(y + dy, x + dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1))
                if close and not touching:
                    for dx, dy, c in ((0, 0, 3), (0, -1, 4), (-1, 0, 2), (1, 0, 3), (1, -1, 4)):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < H_ and 0 <= xx < W_ and not Mf[yy, xx]:
                            out_p[yy, xx] = ramp[c]
        tiles[key] = out_p[s_, s_].copy()
    return tiles


def main(out):
    os.makedirs(os.path.join(out, "transitions"), exist_ok=True)
    mats = {"earth": make_hof(), "forest_floor": make_waldboden(), "meadow": make_wiese()}
    for name, v in mats.items():
        for k, img in v.items():
            Image.fromarray(img).save(os.path.join(out, f"ground_{name}_{k}.png"))
    weg = M.make_soil('weg')[1]
    sets = {
        "meadow_earth": meadow_edge_set(mats["meadow"][1], mats["earth"][1], 1100, GRAS),
        "meadow_forest_floor": meadow_edge_set(mats["meadow"][1], mats["forest_floor"][1], 1110, GRAS),
        "forest_floor_path": soft_edge_set(mats["forest_floor"][1], weg, 1120, WALD, low_shadow_k=0.7),
        # Ergänzung: Wege durch Garten und über Grasinseln
        "earth_path": soft_edge_set(mats["earth"][1], weg, 1130, ERDE, low_shadow_k=0.75),
        "meadow_path": meadow_edge_set(mats["meadow"][1], weg, 1140, GRAS, low_shadow_k=0.72),
    }
    for name, tiles in sets.items():
        Image.fromarray(atlas(tiles)).save(os.path.join(out, "transitions", f"transition_{name}.png"))
    print("  Böden: earth, forest_floor, meadow (je 5) + 5 Übergangssets")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ausgabe_calm")
