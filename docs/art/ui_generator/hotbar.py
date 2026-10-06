"""Hotbar-Grafiken: Slot (normal/gewählt), Hintergrund-Panel, Ziffern-Font.
Gezeichnet wird in 1x, gespeichert in 2x – die UI ist doppelt so grob wie die
Welt, damit die 16er-Icons gut lesbar sind.
Aufruf: python hotbar.py <ausgabeordner>
"""
import sys, os
from PIL import Image

PAL = {
    "k": (14, 10, 20), "a": (43, 22, 51), "d": (77, 18, 48),
    "g": (217, 164, 65), "c": (255, 181, 102), "w": (234, 223, 203),
    "h": (138, 82, 64),     # Gold im Schatten (Haut Highlight)
    "m": (194, 48, 122),
}
ALPHA = {"K": ((14, 10, 20), 215)}   # halbtransparentes Tiefschwarz
SCALE = 2


def to_image(rows):
    w, h = len(rows[0]), len(rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in PAL:
                im.putpixel((x, y), PAL[ch] + (255,))
            elif ch in ALPHA:
                col, a = ALPHA[ch]
                im.putpixel((x, y), col + (a,))
    return im.resize((w * SCALE, h * SCALE), Image.NEAREST)


def slot(border_tl, border_br, fill, inner_tl, inner_br, corner=None):
    """20x20: Rand, darin 1px Fase (Licht oben links), darin 16x16 für das Icon.
    Ecken bleiben frei, das wirkt weicher als ein harter Kasten."""
    S = 20
    g = [["."] * S for _ in range(S)]
    for y in range(S):
        for x in range(S):
            if x in (0, S - 1) or y in (0, S - 1):
                g[y][x] = border_tl if (x == 0 or y == 0) else border_br
            elif x in (1, S - 2) or y in (1, S - 2):
                g[y][x] = inner_tl if (x == 1 or y == 1) else inner_br
            else:
                g[y][x] = fill
    for x, y in ((0, 0), (S - 1, 0), (0, S - 1), (S - 1, S - 1)):
        g[y][x] = "."
    if corner:
        # kleine Gold-Winkel innen an den Ecken
        for x, y in ((1, 1), (S - 2, 1), (1, S - 2), (S - 2, S - 2)):
            g[y][x] = corner
        g[0][1] = g[1][0] = "c"   # Glanzpunkt oben links, wo das Licht herkommt
    return ["".join(r) for r in g]


# Normal: eingelassene, dunkle Mulde. Schatten innen oben links, schwacher
# Bordeaux-Schimmer unten rechts.
SLOT = slot("a", "a", "K", "k", "d")
# Gewählt: Goldrahmen (unten rechts im Schatten), Mulde in Aubergine aufgehellt.
SLOT_SELECTED = slot("g", "h", "a", "k", "d", corner="g")

# Panel als 9-Slice: 7x7, die Ecken (3px) bleiben fest, die Mitte wird gestreckt.
PANEL = [
    ".aaaaa.",
    "agKKKga",
    "aKKKKKa",
    "aKKKKKa",
    "aKKKKKa",
    "agKKKga",
    ".aaaaa.",
]

# Ziffern 3x5, Knochen-Weiß; Aubergine-Kontur kommt automatisch dazu.
DIGITS = {
    "0": ["www", "w.w", "w.w", "w.w", "www"],
    "1": [".w.", "ww.", ".w.", ".w.", "www"],
    "2": ["www", "..w", "www", "w..", "www"],
    "3": ["www", "..w", ".ww", "..w", "www"],
    "4": ["w.w", "w.w", "www", "..w", "..w"],
    "5": ["www", "w..", "www", "..w", "www"],
    "6": ["www", "w..", "www", "w.w", "www"],
    "7": ["www", "..w", ".w.", ".w.", ".w."],
    "8": ["www", "w.w", "www", "w.w", "www"],
    "9": ["www", "w.w", "www", "..w", "www"],
}


def digit_cell(d):
    """5x7-Zelle: Ziffer mittig, ringsum 1px Aubergine-Kontur (auch diagonal,
    damit sie auf jedem Icon lesbar bleibt)."""
    g = [["."] * 5 for _ in range(7)]
    for y, r in enumerate(DIGITS[d]):
        for x, ch in enumerate(r):
            if ch == "w":
                g[y + 1][x + 1] = "w"
    for y in range(7):
        for x in range(5):
            if g[y][x] == "." and any(
                0 <= x + dx < 5 and 0 <= y + dy < 7 and g[y + dy][x + dx] == "w"
                for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                g[y][x] = "a"
    return ["".join(r) for r in g]


def digits_font(out):
    cells = [digit_cell(d) for d in "0123456789"]
    rows = ["".join(c[y] for c in cells) for y in range(7)]
    to_image(rows).save(os.path.join(out, "hotbar_digits.png"))
    # BMFont-Textformat, das Godot direkt als Font importiert. Vorschub 4 statt 5:
    # Nachbarziffern teilen sich eine Konturspalte.
    cw, ch = 5 * SCALE, 7 * SCALE
    lines = [
        'info face="HotbarDigits" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0' % ch,
        "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0" % (ch, ch, cw * 10, ch),
        'page id=0 file="hotbar_digits.png"',
        "chars count=10",
    ]
    for i, d in enumerate("0123456789"):
        lines.append("char id=%d x=%d y=0 width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                     % (ord(d), i * cw, cw, ch, 4 * SCALE))
    with open(os.path.join(out, "hotbar_digits.fnt"), "w", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    to_image(SLOT).save(os.path.join(out, "hotbar_slot.png"))
    to_image(SLOT_SELECTED).save(os.path.join(out, "hotbar_slot_selected.png"))
    to_image(PANEL).save(os.path.join(out, "hotbar_panel.png"))
    digits_font(out)
