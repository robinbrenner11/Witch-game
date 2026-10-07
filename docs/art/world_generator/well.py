"""Platzhalter: alter Steinbrunnen (32x40, Fußpunkt unten Mitte), in den die
Hexe Dinge wirft, die sie nicht mehr braucht. Dunkles Wasser mit einem
Magenta-Glimmen: Der Brunnen ist nicht ganz gewöhnlich.
Licht von oben links, Aubergine-Kontur, Farben aus hexen_palette.gpl.
Aufruf: python well.py <ausgabeordner_props> [vorschauordner]
        z. B. python well.py assets/environment/props docs/art/vorschau
"""
import sys, os
from PIL import Image

from props import Canvas, C, ellipse_points

C.update({
    "s": (66, 58, 92), "S": (104, 96, 140), "t": (30, 22, 44),   # Stein (Kesselrand-Töne)
    "v": (26, 20, 46),                                             # Nachtviolett: Wasser
})


def well():
    c = Canvas(32, 40)
    # Steinring als Ellipse, Wasser innen
    for x, y in ellipse_points(15.5, 22, 14, 9):
        c.put(x, y, "s")
    for x, y in ellipse_points(15.5, 21, 10, 5.5):
        c.put(x, y, "v")
    # Licht oben links auf dem Ring, Schatten unten rechts
    for x, y in ellipse_points(15.5, 22, 14, 9):
        if c.get(x, y) == "s":
            if x + (y - 22) * 1.5 < 10:
                c.put(x, y, "S")
            elif x + (y - 22) * 1.5 > 26:
                c.put(x, y, "t")
    # Fugen zwischen den Steinen
    for x, y in ((6, 17), (12, 14), (20, 14), (26, 17), (5, 25), (11, 29), (20, 29), (27, 25)):
        c.put(x, y, "t")
    # Vorderwand des Brunnens (sichtbare Steinreihe unter dem Ring)
    for y in range(29, 37):
        for x in range(3, 29):
            if ((x - 15.5) / 13.5) ** 2 <= 1.0:
                c.put(x, y, "s" if (x // 5 + y // 3) % 2 else "S" if y < 31 else "s")
    for x in range(3, 29):
        c.put(x, 33, "t")
        c.put(x, 36, "t")
    # Glimmen im Wasser
    c.put(13, 20, "m")
    c.put(18, 22, "M")
    c.put(19, 22, "m")
    c.put(16, 19, "u")
    c.outline("a")
    return c.image()


def main(out_dir, preview_dir=None):
    im = well()
    im.save(os.path.join(out_dir, "well.png"))
    if preview_dir:
        bg = Image.new("RGBA", (40, 48), (14, 10, 20, 255))
        bg.alpha_composite(im, (4, 4))
        bg.resize((160, 192), Image.NEAREST).save(os.path.join(preview_dir, "vorschau_brunnen_4x.png"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
