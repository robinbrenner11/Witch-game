"""Ergänzt Alagard (Hewett Tsoi / Pix3M) um die Zeichen, die die deutschen Texte brauchen.

Alagard enthält nur ASCII (plus ¢ £ ¥ €). Dieses Skript baut Umlaute, ß, ·, ×, – und …
im selben Raster nach (1 Pixel = 64 Einheiten, Striche 2 Pixel breit wie im Original)
und schreibt assets/ui/fonts/alagard_de.ttf.
Aufruf im Projektordner: python docs/art/font_patch/alagard_umlauts.py
"""
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

SRC = "assets/ui/fonts/alagard.ttf"
OUT = "assets/ui/fonts/alagard_de.ttf"
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


def bitmap(rows):
    """Zeichnet ein Pixelraster; die letzte Zeile liegt auf der Grundlinie."""
    def draw(pen):
        for row, line in enumerate(rows):
            y = len(rows) - 1 - row
            for x, c in enumerate(line):
                if c == "#":
                    rect(pen, x, y, 1, 1)
    return draw


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


def with_dots(base, dots_y, dots_x, dot_h):
    """Grundbuchstabe plus zwei 2 px breite Punkte; Breite bleibt wie beim Grundbuchstaben."""
    def draw(pen):
        glyph_set[cmap[ord(base)]].draw(pen)
        for x in dots_x:
            rect(pen, x, dots_y, 2, dot_h)
    return base, draw


def advance_of(char):
    return font["hmtx"][cmap[ord(char)]][0] // PX


# Großbuchstaben sind 11 px hoch (Zeilen 0–10): Punkte 1 px hoch mit 1 px Abstand
# darüber. Kleinbuchstaben 8 px hoch: Punkte 2×2 mit 1 px Abstand.
# Die x-Lage folgt den Stämmen bzw. der Rundung des jeweiligen Buchstabens.
UMLAUTS = {
    "Ä": with_dots("A", 12, (1, 5), 1),
    "Ö": with_dots("O", 12, (1, 5), 1),
    "Ü": with_dots("U", 12, (1, 7), 1),
    "ä": with_dots("a", 9, (1, 4), 2),
    "ö": with_dots("o", 9, (1, 4), 2),
    "ü": with_dots("u", 9, (1, 6), 2),
}
for char, (base, draw) in UMLAUTS.items():
    add_glyph(char, "uni%04X" % ord(char), advance_of(base), draw)

# ß: Oberlänge wie B, unten leicht ausgestellt wie die übrigen Stämme.
add_glyph("ß", "germandbls", 8, bitmap([
    "..###...",
    ".##.##..",
    "##..##..",
    "##.##...",
    "##.#....",
    "##.###..",
    "##..###.",
    "##...##.",
    "##...##.",
    "##.###..",
    "##.##...",
]))
add_glyph("·", "periodcentered", 3, lambda pen: rect(pen, 0, 3, 2, 2))
add_glyph("×", "multiply", 8, bitmap([
    "##...##",
    ".##.##.",
    "..###..",
    ".##.##.",
    "##...##",
    ".......",
]))
add_glyph("–", "endash", 7, lambda pen: rect(pen, 0, 3, 6, 2))


def draw_ellipsis(pen):
    for i in range(3):
        rect(pen, i * 3, 0, 2, 2)


add_glyph("…", "ellipsis", 9, draw_ellipsis)

font["maxp"].numGlyphs = len(font.getGlyphOrder())
font.save(OUT)
print("gespeichert:", OUT)
