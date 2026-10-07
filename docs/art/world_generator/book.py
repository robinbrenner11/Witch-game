"""Platzhalter: Lesepult mit dem Buch der alten Hexe (32x40, Fußpunkt unten
Mitte), leeres Pult und eine lose Buchseite (16x16) zum Aufheben.
Licht von oben links, Aubergine-Kontur, Farben aus hexen_palette.gpl.
Aufruf: python book.py <ausgabeordner_props> [vorschauordner]
        z. B. python book.py assets/environment/props docs/art/vorschau
"""
import sys, os
from PIL import Image

from props import Canvas, C

# Ergänzungen aus der erweiterten Palette (siehe docs/art/neue_farben.md)
C.update({
    "1": (32, 20, 30), "2": (52, 34, 46), "3": (78, 52, 64), "4": (104, 72, 84),   # Ebenholz
    "s": (198, 184, 190), "S": (150, 136, 160),                                    # Laken-Schatten
    "B": (150, 44, 72),                                                            # Bordeaux hell
})


def lectern(with_book):
    c = Canvas(32, 40)
    # Fuß
    for x in range(10, 22):
        c.put(x, 36, "3")
    for x in range(9, 23):
        c.put(x, 37, "2")
        c.put(x, 38, "1")
    # Säule, links Licht
    for y in range(22, 36):
        for x in range(14, 18):
            c.put(x, y, "3" if x == 14 else ("1" if x == 17 else "2"))
    # Pultplatte
    for y in range(14, 23):
        for x in range(4, 28):
            c.put(x, y, "2")
    for x in range(4, 28):
        c.put(x, 14, "4")
        c.put(x, 22, "1")
    for y in range(14, 22):
        c.put(4, y, "3")
    if with_book:
        # Einband
        for y in range(8, 20):
            for x in range(5, 27):
                c.put(x, y, "b")
        for x in range(5, 27):
            c.put(x, 8, "B")
        # Seiten, zum Falz hin im Schatten
        for y in range(9, 19):
            for x in range(6, 15):
                c.put(x, y, "w")
            for x in range(17, 26):
                c.put(x, y, "w")
            c.put(14, y, "s")
            c.put(17, y, "s")
        for y in range(8, 20):
            c.put(15, y, "d")
            c.put(16, y, "d")
        # Schriftzeilen
        for y in (11, 13, 15, 17):
            for x in list(range(7, 13)) + list(range(19, 25)):
                if (x * 5 + y) % 4:
                    c.put(x, y, "S")
        # Ein Rezept-Zeichen in Magenta und ein Lesezeichen aus Gold
        c.put(21, 11, "m")
        c.put(22, 11, "M")
        c.put(16, 20, "g")
        c.put(16, 21, "g")
    c.outline("a")
    return c.image()


def loose_page():
    c = Canvas(16, 16)
    for y in range(3, 14):
        for x in range(4, 12):
            c.put(x, y, "w")
    for y in range(3, 14):
        c.put(11, y, "s")
    for x in range(4, 12):
        c.put(x, 13, "s")
    # Eselsohr oben rechts
    c.put(11, 3, ".")
    c.put(10, 3, "s")
    c.put(11, 4, "S")
    for y in (6, 8, 10):
        for x in range(5, 10):
            if (x * 7 + y) % 4:
                c.put(x, y, "S")
    # Magentafarbene Rune: Die Seite ist magisch.
    c.put(8, 11, "m")
    c.put(7, 11, "M")
    c.outline("a")
    return c.image()


def main(out_dir, preview_dir=None):
    full, empty, page = lectern(True), lectern(False), loose_page()
    full.save(os.path.join(out_dir, "lectern_book.png"))
    empty.save(os.path.join(out_dir, "lectern.png"))
    page.save(os.path.join(out_dir, "loose_page.png"))
    if preview_dir:
        sheet = Image.new("RGBA", (96, 48), (14, 10, 20, 255))
        sheet.alpha_composite(full, (4, 4))
        sheet.alpha_composite(empty, (36, 4))
        sheet.alpha_composite(page, (72, 20))
        sheet.resize((96 * 4, 48 * 4), Image.NEAREST).save(os.path.join(preview_dir, "vorschau_buch_4x.png"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
