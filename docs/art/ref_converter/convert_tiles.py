"""Textur-Vorlage (mehrere Streifen nebeneinander, z. B. Wasserarten) in nahtlose
32x32-Kacheln umrechnen.

Aufruf:
  python convert_tiles.py <vorlage.png> <ausgabe.png> --streifen 4 --nimm 0,2,1,0 [--ohne-deko 0] [--vorschau ordner]

  --streifen: wie viele Texturen nebeneinander in der Vorlage liegen
  --nimm:     welcher Streifen in welches Feld der Ausgabe kommt (Reihenfolge der Felder,
              z. B. für Wasser: tief, Ufer, flach, Durchgang)

Schritte: Pixelraster messen und Vorlage zurückrechnen (wie convert_ref.py), dann pro Streifen
den 32x32-Ausschnitt suchen, dessen Ränder am besten ineinander übergehen (rechter Rand passt
zum linken, unterer zum oberen). Ausschnitte mit Deko (Seerosen, Funken) werden gemieden,
weil sie sich beim Kacheln sichtbar wiederholen. Danach Palette einrasten und die Naht
durch Tausch einzelner Pixel weiter glätten.
"""
import argparse
import os
import numpy as np
from PIL import Image
from convert_ref import measure, to_native, load_gpl, GPL

T = 32


def seam_cost(img, x, y):
    t = img[y:y + T + 1, x:x + T + 1, :3].astype(float)
    # Spalte nach dem Ausschnitt soll aussehen wie die erste Spalte, ebenso die Zeile darunter
    c = np.abs(t[:T, T] - t[:T, 0]).sum() + np.abs(t[T, :T] - t[0, :T]).sum()
    return c


def busy_cost(img, x, y, base, limit):
    """Pixel, die stark vom Grundton abweichen (Seerosen, Lichtpunkte), kosten extra."""
    t = img[y:y + T, x:x + T, :3].astype(float)
    d = np.sqrt(((t - base) ** 2).sum(axis=2))
    # warme/gräuliche Pixel (Seerosen, Blüten) zählen immer
    warm = t[:, :, 0] > t[:, :, 2] - 20
    return ((d > limit) | warm).sum()


def best_tile(strip, calm):
    h, w = strip.shape[:2]
    base = np.median(strip[:, :, :3].reshape(-1, 3), axis=0)
    best = None
    for y in range(0, h - T - 1):
        for x in range(0, w - T - 1):
            c = seam_cost(strip, x, y) + 40 * busy_cost(strip, x, y, base, 45 if calm else 90)
            if best is None or c < best[0]:
                best = (c, x, y)
    _, x, y = best
    return strip[y:y + T, x:x + T].copy(), (x, y)


def snap(tile, pal):
    g = tile.copy()
    for yy in range(T):
        for xx in range(T):
            d = ((pal - g[yy, xx, :3]) ** 2).sum(1)
            g[yy, xx, :3] = pal[d.argmin()]
    return g


def remove_decor(tile):
    """Seerosen und Blüten (grün, rot, gold) durch den häufigsten Wasserton ersetzen."""
    g = tile.copy()
    px = [tuple(p[:3]) for row in g for p in row]
    is_water = lambda c: c[2] > c[1] and int(c[0]) < int(c[2]) - 20   # deutlich blau, nicht gräulich
    water = [c for c in px if is_water(c)]
    base = max(set(water), key=water.count)
    for yy in range(T):
        for xx in range(T):
            if not is_water(tuple(g[yy, xx, :3])):
                g[yy, xx, :3] = base
    return g


def heal_seams(tile):
    """Randpixel an den Nachbarn auf der anderen Seite angleichen, wenn sie stark abweichen."""
    g = tile.copy()
    for i in range(T):
        for (a, b) in (((i, 0), (i, T - 1)), ((0, i), (T - 1, i))):
            pa, pb = g[a][:3].astype(int), g[b][:3].astype(int)
            if np.abs(pa - pb).sum() > 120:
                # den helleren Ausreißer durch seinen Innennachbarn ersetzen
                inner = (a[0], 1) if a[1] == 0 and b[1] == T - 1 else (1, a[1])
                g[a][:3] = g[inner][:3]
    return g


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vorlage")
    ap.add_argument("ausgabe")
    ap.add_argument("--streifen", type=int, default=4)
    ap.add_argument("--nimm", default="0,1,2,3")
    ap.add_argument("--ohne-deko", default="", help="Streifen, aus denen Seerosen usw. entfernt werden, z. B. 0")
    ap.add_argument("--vorschau")
    a = ap.parse_args()

    src = np.array(Image.open(a.vorlage).convert("RGBA")).astype(int)
    src[:, :, 3] = 255
    px, ox = measure(src[:, :, :3].astype(float), src[:, :, 3], 1)
    py, oy = measure(src[:, :, :3].astype(float), src[:, :, 3], 0, px)
    print(f"Raster: {px:.3f} (Versatz {ox:.2f}, {oy:.2f})")
    nat = to_native(src, px, ox, py, oy)
    sw = nat.shape[1] // a.streifen
    # Rand zwischen den Streifen meiden (dort mischen sich die Texturen)
    strips = [nat[2:-2, i * sw + 2:(i + 1) * sw - 2] for i in range(a.streifen)]
    print("Streifen je", strips[0].shape[1], "x", strips[0].shape[0], "Pixel")
    pal = load_gpl(GPL)
    tiles = []
    for i, s in enumerate(strips):
        calm = str(i) in a.ohne_deko.split(",")
        t, pos = best_tile(s, calm)
        t = heal_seams(snap(t, pal))
        if str(i) in a.ohne_deko.split(","):
            t = remove_decor(t)
        tiles.append(t)
        print(f"Streifen {i}: Ausschnitt bei {pos}")
    order = [int(v) for v in a.nimm.split(",")]
    out = np.zeros((T, T * len(order), 4), np.uint8)
    for k, i in enumerate(order):
        out[:, k * T:(k + 1) * T] = tiles[i]
    Image.fromarray(out).save(a.ausgabe)
    if a.vorschau:
        Image.fromarray(nat).save(os.path.join(a.vorschau, "native.png"))
        # jede Kachel 3x3 gekachelt, damit Nähte sichtbar werden
        pv = Image.new("RGBA", (len(tiles) * (3 * T + 8), 3 * T), (0, 0, 0, 255))
        for i, t in enumerate(tiles):
            im = Image.fromarray(t)
            for yy in range(3):
                for xx in range(3):
                    pv.paste(im, (i * (3 * T + 8) + xx * T, yy * T))
        pv.resize((pv.width * 3, pv.height * 3), Image.NEAREST).save(os.path.join(a.vorschau, "kacheln_3x3.png"))


if __name__ == "__main__":
    main()
