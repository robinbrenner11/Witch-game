"""Pflanzen-Vorlage (große Pixel-Art, z. B. KI-Bild mit 4 Stufen nebeneinander)
in ein Spritesheet mit 4 Frames à 32x48 umrechnen.

Aufruf:
  python convert_ref.py <vorlage.png> <ausgabe.png> [--soil N] [--hoehe 48] [--breite 32] [--kontur] [--quadrat] [--vorschau ordner]
  --hoehe: Frame-Höhe (Standard 48; hohe, schmale Pflanzen z. B. 64). Der Stielfuß
  liegt immer 11 px über der Unterkante, das erwartet plant.gd.

Schritte:
 1. Pixelraster der Vorlage messen (Größe und Versatz eines Vorlagen-Pixels)
 2. Vorlage auf ihr eigenes Raster zurückrechnen (Farbe aus der Zellmitte)
 3. Stufen finden (Spalten mit Inhalt), optional Erdhügel abschneiden (--soil:
    so viele Vorlagen-Pixelzeilen von unten weg)
 4. Alle Stufen mit demselben Faktor auf 32x48 verkleinern, Stielfuß x 16, y 37.
    Gold, Magenta und helle Töne zählen mehr, damit dünne Kanten bleiben
 5. Auf hexen_palette.gpl einrasten, Flächen glätten, Kontur schließen, Störpixel weg
"""
import argparse
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GPL = os.path.join(HERE, "..", "hexen_palette.gpl")
FW, FH, FOOT = 32, 48, 37      # FH/FOOT setzt main() aus --hoehe


# ---------- 1. Raster messen ----------
def measure(rgb, alpha, axis, fixed=None):
    d = np.abs(np.diff(rgb, axis=axis)).sum(axis=2)
    m = (alpha[:-1, :] > 200) if axis == 0 else (alpha[:, :-1] > 200)
    e = (d * m).sum(axis=1 - axis)
    pos = np.arange(len(e))
    best = (0, 0, 0)
    for p in ([fixed] if fixed else np.arange(4.0, 14.0, 0.005)):
        z = (e * np.exp(2j * np.pi * pos / p)).sum()
        s = abs(z) / e.sum()
        if s > best[0]:
            best = (s, p, (np.angle(z) / (2 * np.pi) * p) % p)
    return best[1], best[2]


# ---------- 2. Eigenes Raster ----------
def to_native(src, px, ox, py, oy):
    h, w = src.shape[:2]
    nx, ny = int((w - ox) / px), int((h - oy) / py)
    out = np.zeros((ny, nx, 4), np.uint8)
    for j in range(ny):
        for i in range(nx):
            x0, y0 = ox + i * px, oy + j * py
            blk = src[int(y0 + py * 0.25):int(y0 + py * 0.75) + 1, int(x0 + px * 0.25):int(x0 + px * 0.75) + 1]
            p = blk.reshape(-1, 4)
            if len(p) == 0 or (p[:, 3] > 160).mean() < 0.5:
                continue
            p = p[p[:, 3] > 160]
            med = np.median(p[:, :3], axis=0)
            out[j, i] = (*p[((p[:, :3] - med) ** 2).sum(axis=1).argmin()][:3], 255)
    return out


# ---------- 3. Stufen ----------
def stages(nat, soils):
    occ = (nat[:, :, 3] > 0).any(axis=0)
    runs, s = [], None
    for x, v in enumerate(list(occ) + [False]):
        if v and s is None:
            s = x
        if not v and s is not None:
            # kleine Splitter (Glanzpunkte, Funken zwischen den Stufen) ignorieren
            if (nat[:, s:x, 3] > 0).sum() >= 40:
                runs.append((s, x))
            s = None
    if len(runs) != 4:
        raise SystemExit(f"Erwarte 4 Stufen, gefunden: {runs}")
    out = []
    for (x0, x1), soil in zip(runs, soils):
        sub = nat[:, x0:x1].copy()
        rows = np.where((sub[:, :, 3] > 0).any(axis=1))[0]
        last = rows.max() - soil
        sub[last + 1:] = 0
        out.append((sub, rows.min(), last))
    return out


# ---------- 4. Verkleinern ----------
def weight(c):
    r, g, b = (int(v) for v in c)
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    if r > 180 and g > 110 and b < 140:    # Gold, Kerzenlicht
        return 2.2
    if r > 150 and g < 120:                 # Magenta, Rot-Kanten
        return 1.6
    if lum > 150:                           # helle Blüten
        return 1.3
    if lum < 30:                            # Kontur
        return 1.15
    return 1.0


def shrink(sub, last, f):
    xs = np.where(sub[last, :, 3] > 0)[0]
    foot_x = (xs.min() + xs.max() + 1) / 2
    out = np.zeros((FH, FW, 4), np.uint8)
    for r in range(FH):
        for c in range(FW):
            sy0 = last + 1 - (FOOT + 1 - r) / f
            sx0 = foot_x + (c - FW / 2) / f
            votes, cover = {}, 0.0
            for y in range(int(np.floor(sy0)), int(np.ceil(sy0 + 1 / f))):
                for x in range(int(np.floor(sx0)), int(np.ceil(sx0 + 1 / f))):
                    if not (0 <= y < sub.shape[0] and 0 <= x < sub.shape[1]) or sub[y, x, 3] == 0:
                        continue
                    a = max(0, min(sy0 + 1 / f, y + 1) - max(sy0, y)) * max(0, min(sx0 + 1 / f, x + 1) - max(sx0, x))
                    if a <= 0:
                        continue
                    cover += a
                    k = tuple(int(v) for v in sub[y, x, :3])
                    votes[k] = votes.get(k, 0) + a * weight(k)
            if votes and cover * f * f >= 0.45:
                out[r, c] = (*max(votes, key=votes.get), 255)
    return out


# ---------- 5. Palette und Aufräumen ----------
def load_gpl(path):
    cols = []
    for line in open(path, encoding="utf8"):
        p = line.split()
        if len(p) >= 3 and all(s.isdigit() for s in p[:3]):
            cols.append(tuple(int(s) for s in p[:3]))
    return np.array(sorted(set(cols)), float)


def snap(fr, pal):
    g = fr.copy()
    ys, xs = np.where(g[:, :, 3] > 0)
    for y, x in zip(ys, xs):
        d = ((pal - g[y, x, :3]) ** 2).sum(1)
        g[y, x, :3] = pal[d.argmin()]
    return g


def lum(c):
    return 0.3 * int(c[0]) + 0.59 * int(c[1]) + 0.11 * int(c[2])


def tidy(fr):
    h, w = fr.shape[:2]
    g = fr.copy()
    accent = lambda c: weight(c) >= 1.3
    # Glätten: Körperpixel an die umgebende Mehrheit angleichen
    for _ in range(2):
        src = g.copy()
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                me = tuple(src[y, x, :3])
                if not src[y, x, 3] or accent(me):
                    continue
                n = [tuple(src[y + dy, x + dx, :3]) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                     if (dy or dx) and src[y + dy, x + dx, 3]]
                if len(n) < 7:
                    continue
                best = max(set(n), key=n.count)
                if best != me and n.count(best) >= 5 and not accent(best):
                    g[y, x, :3] = best
    # Dunkle Sprenkel mitten in hellen Flächen (Konturreste) aufhellen
    src = g.copy()
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if not src[y, x, 3] or lum(src[y, x]) >= 45:
                continue
            n = [tuple(src[y + dy, x + dx, :3]) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                 if (dy or dx) and src[y + dy, x + dx, 3]]
            light = [c for c in n if lum(c) > 100]
            if len(n) == 8 and len(light) >= 7:
                g[y, x, :3] = max(set(light), key=light.count)
    # Kontur: die dunkelste Farbe im Frame ist die Kontur; dunkle Randpixel werden Kontur
    cols = {tuple(p[:3]) for row in g for p in row if p[3]}
    outline = min(cols, key=lum)
    src = g.copy()
    for y in range(h):
        for x in range(w):
            if not src[y, x, 3]:
                continue
            edge = any(not (0 <= y + dy < h and 0 <= x + dx < w) or not src[y + dy, x + dx, 3]
                       for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge and lum(src[y, x]) < 45:
                g[y, x, :3] = outline
    # Störpixel: Inseln aus 1-2 dunklen Pixeln entfernen
    seen = set()
    for y in range(h):
        for x in range(w):
            if not g[y, x, 3] or (y, x) in seen:
                continue
            comp, stack = [], [(y, x)]
            seen.add((y, x))
            while stack:
                cy, cx = stack.pop()
                comp.append((cy, cx))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and g[ny, nx, 3] and (ny, nx) not in seen:
                            seen.add((ny, nx))
                            stack.append((ny, nx))
            if len(comp) <= 2 and not any(lum(g[p]) > 130 for p in comp):
                for p in comp:
                    g[p][3] = 0
    return g


def add_outline(fr, col=(43, 22, 51)):
    h, w = fr.shape[:2]
    g = fr.copy()
    for y in range(h):
        for x in range(w):
            if fr[y, x, 3]:
                continue
            if any(0 <= y + dy < h and 0 <= x + dx < w and fr[y + dy, x + dx, 3]
                   for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                g[y, x] = (*col, 255)
    return g


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vorlage")
    ap.add_argument("ausgabe")
    ap.add_argument("--soil", default="0",
                    help="Erdhügel abschneiden: Vorlagen-Pixelzeilen von unten, eine Zahl oder vier (je Stufe), z. B. 8,11,15,15")
    ap.add_argument("--hoehe", type=int, default=48)
    ap.add_argument("--breite", type=int, default=32)
    ap.add_argument("--kontur", action="store_true",
                    help="außen 1 px Aubergine-Kontur ergänzen (wenn sie beim Verkleinern verloren geht)")
    ap.add_argument("--quadrat", action="store_true", help="Pixelgröße in y = in x")
    ap.add_argument("--vorschau")
    a = ap.parse_args()
    global FW, FH, FOOT
    FW, FH, FOOT = a.breite, a.hoehe, a.hoehe - 11

    src = np.array(Image.open(a.vorlage).convert("RGBA")).astype(int)
    px, ox = measure(src[:, :, :3].astype(float), src[:, :, 3], 1)
    # --quadrat: Vorlagen-Pixel sind quadratisch, nur der Versatz in y wird gemessen
    # (die Messung in y erwischt sonst manchmal ein Vielfaches)
    py, oy = measure(src[:, :, :3].astype(float), src[:, :, 3], 0, px if a.quadrat else None)
    print(f"Raster: {px:.3f} x {py:.3f} (Versatz {ox:.2f}, {oy:.2f})")
    nat = to_native(src, px, ox, py, oy)
    if a.vorschau:
        Image.fromarray(nat).save(os.path.join(a.vorschau, "native.png"))
    soils = [int(v) for v in a.soil.split(",")]
    st = stages(nat, soils * 4 if len(soils) == 1 else soils)
    # gemeinsamer Faktor: höchste und breiteste Stufe müssen passen
    hmax = max(last - top + 1 for _, top, last in st)
    wmax = max(sub.shape[1] for sub, _, _ in st)
    f = min(1.0, (FOOT + 1) / hmax, (FW - 1) / wmax)
    print(f"Vorlage {wmax}x{hmax} Pixel -> Faktor {f:.3f}")
    pal = load_gpl(GPL)
    sheet = np.zeros((FH, FW * 4, 4), np.uint8)
    for i, (sub, top, last) in enumerate(st):
        fr = tidy(snap(shrink(sub, last, f), pal))
        if a.kontur:
            fr = add_outline(fr)
        sheet[:, i * FW:(i + 1) * FW] = fr
    Image.fromarray(sheet).save(a.ausgabe)
    cols = {tuple(p[:3]) for row in sheet for p in row if p[3]}
    print(f"Farben im Sheet: {len(cols)}")


if __name__ == "__main__":
    main()
