"""Bett der Hexe, 32x64 (1x2 Tiles), Top-down wie die übrigen Props.
Aufruf: python bed.py <ausgabeordner> [vorschauordner]

Dunkles, leicht violettes Holz mit Goldknäufen, Bettwäsche in Bordeaux,
helle Kissen und ein kleines Magenta-Kissen. Licht von oben links.
"""
import sys, os
from PIL import Image

W, H = 32, 64

C = {
    "a": (43, 22, 51),     # Aubergine – Kontur
    # Holz (neu: violettstichige Ebenholz-Rampe)
    "w1": (32, 20, 30), "w2": (52, 34, 46), "w3": (78, 52, 64), "w4": (104, 72, 84),
    # Gold
    "o": (156, 104, 52), "g": (217, 164, 65), "G": (244, 204, 120),
    # Kissen / Laken (Knochen + neue Schatten Richtung Flieder)
    "s": (234, 223, 203), "s2": (198, 184, 190), "s3": (150, 136, 160),
    # Bordeaux
    "d2": (54, 14, 36), "d": (77, 18, 48), "b": (110, 24, 48), "B": (150, 44, 72),
    # Magenta
    "m": (194, 48, 122), "M": (228, 88, 177),
    # Hexe (aus witch_idle.png): Haar, Haut
    "k": (14, 10, 20), "e": (74, 43, 39), "h": (107, 63, 51), "H": (138, 82, 64),
}


def new():
    return [[None] * W for _ in range(H)]


def rect(g, x0, y0, x1, y1, col):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = col


def px(g, x, y, col):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = col


def hline(g, x0, x1, y, col):
    rect(g, x0, y, x1, y, col)


def vline(g, x, y0, y1, col):
    rect(g, x, y0, x, y1, col)


def rounded(g, x0, y0, x1, y1, fill, light, shade, edge="a"):
    """Gefülltes Rechteck mit abgeschnittenen Ecken, Licht oben links."""
    rect(g, x0, y0, x1, y1, fill)
    hline(g, x0 + 1, x1 - 1, y0 + 1, light)
    vline(g, x0 + 1, y0 + 1, y1 - 2, light)
    hline(g, x0 + 1, x1 - 1, y1 - 1, shade)
    vline(g, x1 - 1, y0 + 2, y1 - 1, shade)
    hline(g, x0 + 1, x1 - 1, y0, edge)
    hline(g, x0 + 1, x1 - 1, y1, edge)
    vline(g, x0, y0 + 1, y1 - 1, edge)
    vline(g, x1, y0 + 1, y1 - 1, edge)


def knob(g, cx, cy):
    """Goldknauf 3x3 mit Glanzpunkt oben links."""
    rect(g, cx - 1, cy - 1, cx + 1, cy + 1, "g")
    px(g, cx - 1, cy - 1, "G")
    px(g, cx + 1, cy + 1, "o")
    px(g, cx, cy + 1, "o")
    px(g, cx + 1, cy, "o")


CX = 16  # Mitte des Betts


def draw_hair(g, covered):
    """Haarmasse auf den Kissen. covered=True: Decke bis über die Nase gezogen."""
    rows = {13: (12, 19), 14: (11, 20)}
    for y in range(15, 24):
        rows[y] = (10, 21)
    for y, (x0, x1) in rows.items():
        hline(g, x0, x1, y, "k")
    for x, y in [(10, 24), (11, 24), (20, 24), (21, 24), (9, 22), (22, 21), (9, 23), (22, 23)]:
        px(g, x, y, "k")                    # Strähnen fallen übers Kissen
    for x, y in [(13, 14), (12, 16), (11, 19), (19, 15), (20, 18), (12, 22)]:
        px(g, x, y, "a")                    # Glanzlinien
    px(g, 19, 14, "g")                      # goldene Haarnadel
    px(g, 20, 15, "o")


def draw_face(g):
    face = {
        16: (14, 17), 17: (13, 18), 18: (13, 18), 19: (13, 18),
        20: (13, 18), 21: (14, 17), 22: (15, 16),
    }
    for y, (x0, x1) in face.items():
        hline(g, x0, x1, y, "h")
        px(g, x0, y, "H") if y < 21 else None
        px(g, x1, y, "e")
    # geschlossene Augen als kleine Wimpernbögen
    px(g, 14, 19, "k"); px(g, 15, 19, "e")
    px(g, 17, 19, "k"); px(g, 16, 19, "e")
    px(g, 15, 21, "b"); px(g, 16, 21, "d")  # Lippen
    px(g, 15, 17, "g")                      # Goldpunkt auf der Stirn
    px(g, 18, 20, "g")                      # Goldakzent auf der Wange


def draw_lump(g, top):
    """Körperform unter der Decke: weiche Wölbung, Licht oben links."""
    widths = {}
    for y in range(top, 53):
        t = y - top
        if t < 3:
            w = 7 + t          # Schultern runden sich nach außen
        elif y < 38:
            w = 9
        elif y < 46:
            w = 8
        else:
            w = 7 - (y - 46) // 2
        widths[y] = w
    for y, w in widths.items():
        for x in range(CX - w, CX + w + 1):
            if x <= CX - w + 1:
                c = "B"
            elif x >= CX + w - 1:
                c = "d"
            else:
                c = "b"
            px(g, x, y, c)
        px(g, CX + w + 1, y, "d2")          # Schlagschatten der Wölbung rechts
    # Lichtkante oben auf den Schultern
    hline(g, CX - widths[top] + 1, CX + 2, top, "B")
    # Mulde zwischen den Beinen
    for y in range(46, 53):
        px(g, CX, y, "d")


def draw(sleeping=None):
    g = new()

    # --- Kopfteil: zwei Pfosten, dazwischen ein Paneel mit flachem Bogen
    for x0 in (2, 26):
        rect(g, x0, 2, x0 + 3, 16, "w2")
        vline(g, x0, 2, 16, "w3")          # Lichtkante links
        vline(g, x0 + 3, 2, 16, "w1")      # Schattenkante rechts
    arch = [5, 4, 4, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 4, 4, 5]  # Oberkante je Spalte x=6..25
    for i, top in enumerate(arch):
        x = 6 + i
        rect(g, x, top, x, 14, "w2")
        px(g, x, top, "w4" if x < 16 else "w3")
    # eingelassenes Feld mit Goldrand und Mondsichel-Ornament
    rect(g, 9, 6, 22, 12, "w1")
    hline(g, 9, 22, 6, "o"); hline(g, 9, 22, 12, "o")
    vline(g, 9, 6, 12, "o"); vline(g, 22, 6, 12, "o")
    hline(g, 10, 21, 7, "w2")
    for x, y in [(15, 8), (14, 9), (14, 10), (15, 11), (16, 11)]:
        px(g, x, y, "g")
    px(g, 16, 8, "G")
    px(g, 18, 9, "M")  # kleiner Magenta-Stern neben der Sichel
    knob(g, 3, 1); knob(g, 28, 1)

    # --- Matratze / Laken unter allem
    rect(g, 4, 15, 27, 57, "s2")

    # --- Kissen
    rounded(g, 5, 15, 15, 22, "s", "s", "s2")
    rounded(g, 16, 15, 26, 22, "s", "s", "s2")
    hline(g, 7, 13, 21, "s3"); hline(g, 18, 24, 21, "s3")
    # Delle in der Kissenmitte
    hline(g, 8, 11, 18, "s2"); hline(g, 19, 22, 18, "s2")
    if sleeping:
        draw_hair(g, sleeping == "covered")
        if sleeping == "face":
            draw_face(g)
    else:
        # kleines rundes Magenta-Zierkissen (nur im leeren Bett)
        cx0, cy0 = 13, 20
        rounded(g, cx0, cy0, cx0 + 5, cy0 + 5, "m", "M", "b")
        for x, y in [(cx0, cy0), (cx0 + 5, cy0), (cx0, cy0 + 5), (cx0 + 5, cy0 + 5)]:
            px(g, x, y, "s")

    # --- umgeschlagenes Laken mit Goldnaht (verdeckt: bis über die Nase gezogen)
    sy = 20 if sleeping == "covered" else 25
    if sleeping == "covered":
        rect(g, 4, sy + 4, 27, 28, "b")
    rect(g, 4, sy, 27, sy + 3, "s")
    hline(g, 4, 27, sy, "s2")
    hline(g, 4, 27, sy + 3, "s3")
    for x in range(5, 27, 2):
        px(g, x, sy + 2, "g")

    # --- Decke in Bordeaux
    rect(g, 4, 29, 27, 55, "b")
    rect(g, 4, 29, 8, 40, "B")             # Lichtfläche oben links
    hline(g, 4, 27, 29, "B")
    vline(g, 26, 30, 55, "d")              # Schattenseite rechts
    vline(g, 27, 29, 55, "d")
    # Goldbordüre unten an der Decke
    hline(g, 4, 27, 53, "o")
    for x in range(5, 27, 3):
        px(g, x, 53, "g")
    if sleeping:
        draw_lump(g, 29 if sleeping == "face" else 25)
    # Decke fällt über die Seiten und das Fußende
    vline(g, 3, 25, 56, "d")
    vline(g, 28, 25, 56, "d2")
    hline(g, 4, 27, 55, "d")
    hline(g, 3, 28, 56, "d2")

    # --- Fußteil
    rect(g, 2, 57, 29, 62, "w2")
    hline(g, 3, 28, 57, "w4")
    hline(g, 3, 28, 58, "w3")
    hline(g, 2, 29, 62, "w1")
    for x0 in (2, 26):
        rect(g, x0, 56, x0 + 3, 62, "w2")
        vline(g, x0, 56, 62, "w3")
        vline(g, x0 + 3, 56, 62, "w1")
    knob(g, 3, 56); knob(g, 28, 56)

    # --- Kontur außen in Aubergine
    add = []
    for y in range(H):
        for x in range(W):
            if g[y][x] is not None:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and g[ny][nx] not in (None, "a"):
                    add.append((x, y)); break
    for x, y in add:
        g[y][x] = "a"
    return g


def to_image(g):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y in range(H):
        for x in range(W):
            if g[y][x]:
                im.putpixel((x, y), C[g[y][x]] + (255,))
    return im


def main(out_dir, preview_dir=None):
    im = to_image(draw())
    im.save(os.path.join(out_dir, "bed.png"))
    # Gewählt: Decke bis über die Nase. ("face" bleibt als Variante im Code.)
    im2 = to_image(draw(sleeping="covered"))
    im2.save(os.path.join(out_dir, "bed_sleeping.png"))
    if preview_dir:
        # Vorschau auf Steinplatten-Boden, falls vorhanden, sonst dunkler Grund
        root = os.path.join(os.path.dirname(__file__), "..", "..", "..")
        bg = Image.new("RGBA", (120, 96), (14, 10, 20, 255))
        tile_path = os.path.join(root, "assets", "environment", "ground", "ground_slab_1.png")
        if os.path.exists(tile_path):
            t = Image.open(tile_path).convert("RGBA")
            for ty in range(0, 96, t.height):
                for tx in range(0, 120, t.width):
                    bg.alpha_composite(t, (tx, ty))
        bg.alpha_composite(im, (16, 16))
        bg.alpha_composite(im2, (72, 16))
        bg.resize((bg.width * 4, bg.height * 4), Image.NEAREST).save(
            os.path.join(preview_dir, "vorschau_bett_4x.png"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
