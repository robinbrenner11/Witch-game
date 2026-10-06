"""Ergänzungen zum Boden-Set (zweite Runde):
- Friedhofsgras (6 Varianten)
- Beet-Endstücke links/rechts/einzeln, trocken + nass
- Übergänge: soil↔path, grass↔cobble, graveyard↔path
- Platten mit Kantensteinen (Rahmen-Set): slab↔grass, slab↔path, slab↔graveyard
Aufruf: python extra.py <ausgabeordner>
"""
import sys, os
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from core import N, hx, shade
import materials as M
import transitions as T

OUT = sys.argv[1]

# ---------------------------------------------------------------- Friedhofsgras
# Gleiche Struktur wie das Gras, aber auf eine kühle Nachtblau-Rampe umgefärbt
# (Friedhof: mehr Nachtblau, weniger Wärme, Magenta als Magie).
FRIED = [(14, 15, 30), (19, 24, 42), (25, 33, 54), (32, 44, 64), (41, 58, 76), (55, 78, 92), (76, 102, 112)]
RECOLOR = {tuple(a): b for a, b in zip(M.GRAS, FRIED)}
RECOLOR.update({
    M.GOLD: (169, 155, 224),          # Blütenmitte -> Flieder
    M.KERZE: (196, 190, 214),         # Pilzkappe -> fahles Knochenweiß
    (176, 98, 52): (110, 104, 140),   # Pilz Schatten -> kühles Grau-Violett
    (196, 178, 150): (150, 146, 170),
    (150, 136, 118): (96, 92, 120),
})


def recolor(a):
    out = a.copy()
    flat = out.reshape(-1, 3)
    for i, px in enumerate(map(tuple, flat)):
        if px in RECOLOR:
            flat[i] = RECOLOR[px]
    return out


def make_graveyard():
    g = M.make_grass()
    return {k: recolor(v) for k, v in g.items()}


# ---------------------------------------------------------------- Beet-Endstücke
def bed_caps(bed, soil):
    """Damm endet abgerundet in der Erde. Rundung über die ganze Tile-Höhe,
    damit übereinander liegende Endstücke nahtlos anschließen."""
    # Rundung nur am Damm (Zeilen ~5-26); die Furchen enden auf Höhe der Dammspitze,
    # damit übereinander liegende Endstücke an y=0/31 gleich weit reichen.
    prof = np.zeros(N, int)
    for y in range(N):
        if 5 <= y <= 26:
            r = 11.0
            prof[y] = round(r - np.sqrt(max(r * r - (y - 15.5) ** 2, 0)))
        else:
            prof[y] = 8

    def build(left, right):
        out = soil.copy()
        for y in range(N):
            x0 = 4 + prof[y] if left else 0
            x1 = N - 1 - (4 + prof[y]) if right else N - 1
            out[y, x0:x1 + 1] = bed[y, x0:x1 + 1]
            dam = 6 <= y <= 25                          # Dammzeilen (Furchen oben/unten)
            if left and dam:                            # Stirnseite zum Licht: helle Kante
                out[y, x0] = M.BEET[5]
                out[y, x0 + 1] = M.BEET[4]
                if x0 - 1 >= 0:                         # feine Trennlinie zur Erde
                    out[y, x0 - 1] = shade(soil[y, x0 - 1], 0.6)
            if right:                                   # Stirnseite im Schatten + Schlagschatten
                if dam:
                    out[y, x1] = M.BEET[0]
                    out[y, x1 - 1] = M.BEET[1]
                for k, f in ((1, 0.55), (2, 0.8)):
                    if x1 + k < N:
                        out[y, x1 + k] = shade(soil[y, x1 + k], f)
        return out
    return {"left": build(True, False), "right": build(False, True), "single": build(True, True)}


# ---------------------------------------------------------------- Platten mit Kantensteinen
STEIN = M.STEIN


def kerb_set(slab, lower, joint_offset=0):
    """Corner-Set mit gerader Kante (Platten sind gebaut, nicht gewachsen).
    Jede Ecke = ein 16x16-Viertel. 2px Kantenstein + 1px Fuge + Schlagschatten."""
    tiles = {}
    for key in list(range(16)) + [("alt", a) for a in T.ALT_IDS]:
        i = key if isinstance(key, int) else key[1]
        jo = joint_offset + (4 if not isinstance(key, int) else 0)
        if i == 15:
            tiles[key] = slab.copy(); continue
        if i == 0:
            tiles[key] = lower.copy(); continue
        tl, tr, bl, br = T.bits(i)
        m = np.zeros((N, N), bool)
        m[:16, :16], m[:16, 16:], m[16:, :16], m[16:, 16:] = tl, tr, bl, br

        def M_(y, x):  # Maske mit Fortsetzung über den Tile-Rand (gleiche Ecke)
            if 0 <= y < N and 0 <= x < N:
                return m[y, x]
            return m[min(max(y, 0), N - 1), min(max(x, 0), N - 1)]
        out = lower.copy()
        out[m] = slab[m]
        for y in range(N):
            for x in range(N):
                if not m[y, x]:
                    # Schlagschatten unten/rechts der Fläche
                    if M_(y - 1, x) or M_(y, x - 1):
                        out[y, x] = shade(lower[y, x], 0.62)
                    elif M_(y - 2, x):
                        out[y, x] = shade(lower[y, x], 0.8)
                    continue
                d_up = next((k for k in (1, 2, 3) if not M_(y - k, x)), 0)
                d_lf = next((k for k in (1, 2, 3) if not M_(y, x - k)), 0)
                d_dn = next((k for k in (1, 2, 3) if not M_(y + k, x)), 0)
                d_rt = next((k for k in (1, 2, 3) if not M_(y, x + k)), 0)
                ds = [d for d in (d_up, d_lf, d_dn, d_rt) if d]
                if not ds:
                    continue
                d = min(ds)
                lit = (d_up == d) or (d_lf == d)
                if d == 1:
                    c = STEIN[5] if lit else STEIN[1]
                elif d == 2:
                    c = STEIN[4] if lit else STEIN[2]
                else:
                    c = M.AUB                          # Fuge zwischen Kantenstein und Platten
                # Stoßfugen im Kantenstein alle 8 px
                horiz = d_up == d or d_dn == d
                pos = x if horiz else y
                if d < 3 and (pos + jo) % 8 == 0:
                    c = M.AUB
                out[y, x] = c
        tiles[key] = out
    return tiles


def soil_path_set(soil, path):
    """Erde liegt locker über dem festgetretenen Weg; ohne Grashalme."""
    keep = T.TUFT_UP, T.TUFT_UP_S
    T.TUFT_UP, T.TUFT_UP_S = [], []
    try:
        return T.soft_edge_set(soil, path, 730, M.ERDE, low_shadow_k=0.7)
    finally:
        T.TUFT_UP, T.TUFT_UP_S = keep


def save(a, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.fromarray(a.astype(np.uint8), "RGB").save(path, optimize=True)


def main():
    grass = M.make_grass()[1]
    soil = M.make_soil("erde")[1]
    path = M.make_soil("weg")[1]
    beet = M.make_beet()
    slab = M.make_platte()[1]
    grave = make_graveyard()

    tiles = {}
    for k, v in grave.items():
        tiles[f"ground_graveyard_{k}"] = v
    for wet, src in (("dry", beet[1]), ("wet", beet[4])):
        for side, v in bed_caps(src, soil).items():
            tiles[f"ground_bed_cap_{side}_{wet}"] = v
    for name, a in tiles.items():
        save(a, os.path.join(OUT, "ground", name + ".png"))

    trans = {
        "soil_path": soil_path_set(soil, path),
        "cobble_grass": T.cobble_set(grass, 740),
        "graveyard_path": T.soft_edge_set(grave[1], path, 750, FRIED, low_shadow_k=0.68),
        "slab_grass": kerb_set(slab, grass),
        "slab_path": kerb_set(slab, path, 2),
        "slab_graveyard": kerb_set(slab, grave[1], 6),
    }
    for n, ts in trans.items():
        save(T.atlas(ts), os.path.join(OUT, "ground", "transitions", f"transition_{n}.png"))

    # Kanten-Prüfung wie im Original-Werkzeug
    report = []
    groups = {"graveyard": [grave[k] for k in sorted(grave)]}
    for n, vs in groups.items():
        bad = sum(1 for a in vs for b in vs if not (
            np.array_equal(a[:, :2], b[:, :2]) and np.array_equal(a[:2], b[:2])
            and np.array_equal(a[:, -2:], b[:, -2:]) and np.array_equal(a[-2:], b[-2:])))
        report.append(f"{n}: Randstreifen-Abweichungen zwischen Varianten = {bad}")
    for n, ts in trans.items():
        worst, fails = 0, 0
        for ka in ts:
            ia = ka if isinstance(ka, int) else ka[1]
            for kb in ts:
                ib = kb if isinstance(kb, int) else kb[1]
                a, b = ts[ka].astype(int), ts[kb].astype(int)
                if ((ia >> 1) & 1, (ia >> 3) & 1) == ((ib >> 0) & 1, (ib >> 2) & 1):
                    dd = np.abs(a[:, -1] - b[:, 0]).sum(1).mean(); worst = max(worst, dd); fails += dd > 60
                if ((ia >> 2) & 1, (ia >> 3) & 1) == ((ib >> 0) & 1, (ib >> 1) & 1):
                    dd = np.abs(a[-1] - b[0]).sum(1).mean(); worst = max(worst, dd); fails += dd > 60
        report.append(f"{n}: max. mittl. Kantendifferenz {worst:.1f}, Ausreißer>60: {fails}")
    # Endstücke: Kante zur Erde (links bzw. rechts) muss exakt erde_1 sein
    for side, col in (("left", 0), ("right", -1)):
        for wet in ("dry", "wet"):
            a = tiles[f"ground_bed_cap_{side}_{wet}"]
            report.append(f"bed_cap_{side}_{wet}: Außenkante == Erde: {np.array_equal(a[:, col], soil[:, col])}")
    print("\n".join(report))
    with open(os.path.join(OUT, "pruefbericht_extra.txt"), "w") as f:
        f.write("\n".join(report) + "\n")
    return tiles, trans


if __name__ == "__main__":
    main()
