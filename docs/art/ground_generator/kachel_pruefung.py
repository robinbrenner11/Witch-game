"""Prüfbericht für Bodentiles: Format, Palette, Farben, Randstreifen, Nahtstellen, Rasterwirkung.

Aufruf: python kachel_pruefung.py <palette.gpl> weights=36,24,... <tile1.png> <tile2.png> ...
        (statt weights=... ein beliebiges Wort = alle Varianten gleich häufig)
Kennzahlen:
- naht_*: mittlere Farbdifferenz an der Kachelkante (Kachel neben sich selbst); innen_*: dasselbe
  zwischen benachbarten Pixeln im Inneren. Naht nicht größer als innen = keine sichtbare Kante.
- schlechteste_naht_*: größter Wert über alle Paare A|B (jede Variante neben jeder).
- rasterwirkung: Abweichung des mittleren Helligkeitsprofils über x mod 32 / y mod 32 in einer
  großen Zufallsfläche, in % der Gesamtstreuung. Kleiner = weniger sichtbares 32er-Raster.
- lose_einzelpunkte: Pixel, die ringsum nur Grundfarbe haben (Rauschen statt Cluster).
Benötigt: numpy, pillow
"""
import sys, json, itertools, numpy as np
from PIL import Image

def load_gpl(path):
    pal = {}
    for line in open(path, encoding='utf-8'):
        p = line.split()
        if len(p) >= 4 and all(t.isdigit() for t in p[:3]):
            pal[tuple(int(t) for t in p[:3])] = " ".join(p[3:])
    return pal

def lum(a):
    return a[..., 0] * .2126 + a[..., 1] * .7152 + a[..., 2] * .0722

def lattice(tiles, weights, n=64, seed=1):
    """Luminanzprofil über x mod 32 / y mod 32 in einer großen Zufallsfläche.
    Flaches Profil = kein sichtbares 32er-Raster. Rückgabe: max. Abweichung in % der Gesamt-Streuung."""
    rng = np.random.default_rng(seed)
    p = np.array(weights, float); p /= p.sum()
    L = [lum(t.astype(float)) for t in tiles]
    acc = np.zeros((32, 32)); 
    for _ in range(n * n):
        acc += L[rng.choice(len(L), p=p)]
    mean_tile = acc / (n * n)
    allpix = np.concatenate([l.ravel() for l in L])
    sd = allpix.std()
    colprof = mean_tile.mean(0); rowprof = mean_tile.mean(1)
    return {"spalten_abw_max": round(float(np.abs(colprof - colprof.mean()).max() / sd * 100), 1),
            "zeilen_abw_max": round(float(np.abs(rowprof - rowprof.mean()).max() / sd * 100), 1),
            "pixel_abw_max": round(float(np.abs(mean_tile - mean_tile.mean()).max() / sd * 100), 1)}

def check(paths, gpl, weights=None, ring=2):
    pal = load_gpl(gpl)
    rep = {"dateien": [], "fehler": []}
    arrs = []
    for p in paths:
        im = Image.open(p)
        info = {"datei": p.split('/')[-1], "groesse": list(im.size), "modus": im.mode}
        rgba = np.array(im.convert('RGBA'))
        info["voll_deckend"] = bool((rgba[..., 3] == 255).all())
        a = rgba[..., :3]
        cols = {tuple(c) for c in a.reshape(-1, 3)}
        fremd = [('#%02x%02x%02x' % c) for c in cols if c not in pal]
        info["farben"] = len(cols)
        info["farben_ausserhalb_palette"] = fremd
        info["palettenfarben"] = sorted(pal[c] for c in cols if c in pal)
        # Lose Einzelpunkte: Pixel, dessen 8 Nachbarn alle Grundfarbe sind (Rauschen statt Cluster)
        vals, cnt = np.unique(a.reshape(-1, 3), axis=0, return_counts=True)
        base = vals[cnt.argmax()]
        isbase = (a == base).all(-1)
        nb_base = np.ones(a.shape[:2], bool)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy or dx:
                    nb_base &= np.roll(np.roll(isbase, dy, 0), dx, 1)
        info["lose_einzelpunkte"] = int((~isbase & nb_base).sum())
        info["grundfarbe_anteil"] = round(float(isbase.mean()), 2)
        # Selbst-Kachelung: Naht vs. Innen (mittlere Farbdifferenz benachbarter Pixel)
        af = a.astype(int)
        inner_h = np.abs(af[:, 1:] - af[:, :-1]).sum(-1).mean()
        inner_v = np.abs(af[1:, :] - af[:-1, :]).sum(-1).mean()
        info["naht_links_rechts"] = round(float(np.abs(af[:, 0] - af[:, -1]).sum(-1).mean()), 2)
        info["naht_oben_unten"] = round(float(np.abs(af[0, :] - af[-1, :]).sum(-1).mean()), 2)
        info["innen_mittel_h"] = round(float(inner_h), 2); info["innen_mittel_v"] = round(float(inner_v), 2)
        if im.size != (32, 32): rep["fehler"].append(f"{p}: Größe {im.size}")
        if fremd: rep["fehler"].append(f"{p}: Farben außerhalb der Palette {fremd}")
        if not info["voll_deckend"]: rep["fehler"].append(f"{p}: nicht voll deckend")
        rep["dateien"].append(info); arrs.append(af)
    # Randstreifen identisch über alle Varianten, je Kante
    ref = arrs[0]
    edges = {"oben": (slice(0, ring), slice(None)), "unten": (slice(32 - ring, 32), slice(None)),
             "links": (slice(None), slice(0, ring)), "rechts": (slice(None), slice(32 - ring, 32))}
    rep["randstreifen_identisch"] = {k: all((x[s] == ref[s]).all() for x in arrs) for k, s in edges.items()}
    # alle Paare: Naht A|B (horizontal) und A über B (vertikal) + Ecken (2x2-Blöcke)
    worst_h = max(float(np.abs(A[:, -1] - B[:, 0]).sum(-1).mean()) for A, B in itertools.product(arrs, arrs))
    worst_v = max(float(np.abs(A[-1, :] - B[0, :]).sum(-1).mean()) for A, B in itertools.product(arrs, arrs))
    rep["paare_geprueft"] = len(arrs) ** 2
    rep["schlechteste_naht_horizontal"] = round(worst_h, 2)
    rep["schlechteste_naht_vertikal"] = round(worst_v, 2)
    rep["eckpixel_identisch"] = all(all((x[y, xx] == ref[y, xx]).all() for x in arrs) for y in (0, 31) for xx in (0, 31))
    if weights is None: weights = [1] * len(arrs)
    rep["rasterwirkung"] = lattice(arrs, weights)
    return rep

if __name__ == '__main__':
    gpl = sys.argv[1]; mode = sys.argv[2]; paths = sys.argv[3:]
    w = None
    if mode.startswith('weights='):
        w = [float(v) for v in mode.split('=')[1].split(',')]
    print(json.dumps(check(paths, gpl, w), indent=1, ensure_ascii=False))
