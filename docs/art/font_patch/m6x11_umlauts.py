"""Ergänzt m6x11 (Daniel Linssen) um die Zeichen, die die deutschen Texte brauchen.

m6x11 hat keine Umlaute, kein ß, keinen Mittelpunkt, Halbgeviertstrich und keine
Auslassungspunkte. Dieses Skript baut sie im selben Raster nach (1 Pixel = 64 Einheiten,
Striche 2 Pixel breit) und schreibt assets/ui/fonts/m6x11_de.ttf.
Aufruf im Projektordner: python docs/art/font_patch/m6x11_umlauts.py
"""
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

SRC = "assets/ui/fonts/m6x11.ttf"
OUT = "assets/ui/fonts/m6x11_de.ttf"
PX = 64

font = TTFont(SRC)
glyph_set = font.getGlyphSet()
cmap = font.getBestCmap()


def rect(pen, x, y, w, h):
    """Rechteck in Pixeln (x, y = links unten), im Uhrzeigersinn wie die Schrift."""
    x0, y0, x1, y1 = x * PX, y * PX, (x + w) * PX, (y + h) * PX
    pen.moveTo((x0, y0))
    pen.lineTo((x0, y1))
    pen.lineTo((x1, y1))
    pen.lineTo((x1, y0))
    pen.closePath()


def add_glyph(char, name, advance_px, draw):
    pen = TTGlyphPen(glyph_set)
    draw(pen)
    font["glyf"][name] = pen.glyph()
    if name not in font.getGlyphOrder():
        font.setGlyphOrder(font.getGlyphOrder() + [name])
    font["hmtx"][name] = (advance_px * PX, 0)
    for table in font["cmap"].tables:
        if table.isUnicode():
            table.cmap[ord(char)] = name


def with_dots(base, dots_y):
    def draw(pen):
        glyph_set[cmap[ord(base)]].draw(pen)
        rect(pen, 0, dots_y, 2, 2)
        rect(pen, 4, dots_y, 2, 2)
    return draw


# Großbuchstaben 11 px hoch: Punkte mit 1 px Abstand darüber (ragen über die
# Oberlänge hinaus, wie bei vielen Pixelschriften). Kleinbuchstaben 8 px hoch.
for upper, lower in [("Ä", "ä"), ("Ö", "ö"), ("Ü", "ü")]:
    add_glyph(upper, "uni%04X" % ord(upper), 7, with_dots(upper.translate(str.maketrans("ÄÖÜ", "AOU")), 12))
    add_glyph(lower, "uni%04X" % ord(lower), 7, with_dots(lower.translate(str.maketrans("äöü", "aou")), 9))

# ß: 6 px breit, Oberlänge wie b.
SHARP_S = [
    ".####.",
    "##..##",
    "##..##",
    "##.##.",
    "##.##.",
    "##..##",
    "##..##",
    "##..##",
    "##..##",
    "##.###",
    "##.##.",
]


def draw_sharp_s(pen):
    for row, line in enumerate(SHARP_S):
        y = len(SHARP_S) - 1 - row
        for x, c in enumerate(line):
            if c == "#":
                rect(pen, x, y, 1, 1)


add_glyph("ß", "germandbls", 7, draw_sharp_s)
add_glyph("·", "periodcentered", 3, lambda pen: rect(pen, 0, 4, 2, 2))
add_glyph("–", "endash", 7, lambda pen: rect(pen, 0, 4, 6, 2))


def draw_ellipsis(pen):
    for i in range(3):
        rect(pen, i * 3, 0, 2, 2)


add_glyph("…", "ellipsis", 9, draw_ellipsis)

font["maxp"].numGlyphs = len(font.getGlyphOrder())
font.save(OUT)
print("gespeichert:", OUT)
