"""Bauplan für den Garten (Zielbild: art_src/inspo/Nächtlicher Hexengarten ..., 18.10.2026).

Kompakter Zaungarten direkt unter dem Uraltbaum, Weg in der Mitte, Beete links,
Kräuterbeet, Kessel und Feuer rechts, dichter Waldrand rundherum.
Erzeugt height.png, ground.png und marks.png (1 Pixel = 1 Kachel).
Alle Angaben unten in Szenen-Kacheln; der Plan beginnt bei ORIGIN.
Aufruf im Projektordner: python tools/world_builder/plans/garden/make_plan.py
"""
import json
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ORIGIN = (14, -4)
SIZE = (24, 27)  # Spalten 14..37, Reihen -4..22

GROUND = {
    "grass": (64, 125, 89), "soil": (92, 61, 46), "path": (153, 115, 76),
    "earth": (74, 51, 41), "forest_floor": (56, 33, 51),
    "meadow": (84, 128, 92),
}
MARK = {
    "lantern": (255, 181, 102), "tree": (63, 125, 90), "bush": (46, 94, 68),
    "rock": (234, 223, 203),
}

ground = Image.new("RGBA", SIZE, GROUND["grass"] + (255,))
marks = Image.new("RGBA", SIZE, (0, 0, 0, 0))
height = Image.new("RGBA", SIZE, (128, 128, 128, 255))


def paint(name, cols, rows):
    for c in cols:
        for r in rows:
            ground.putpixel((c - ORIGIN[0], r - ORIGIN[1]), GROUND[name] + (255,))


def mark(name, cells):
    for c, r in cells:
        marks.putpixel((c - ORIGIN[0], r - ORIGIN[1]), MARK[name] + (255,))


# Waldrand links, rechts und hinter dem Baum.
paint("forest_floor", range(14, 17), range(-4, 23))
paint("forest_floor", range(35, 38), range(-4, 23))
paint("forest_floor", range(14, 38), range(-4, -2))
# Wiese unterhalb des Zauns (hier wächst Wildkraut).
paint("meadow", range(17, 35), range(15, 23))
# Beete links, Kräuterbeet rechts oben.
paint("soil", range(19, 24), range(7, 12))
paint("soil", range(27, 32), range(7, 9))
# Erde ums Feuer. (Steinplatten am Kessel verlaufen mit den Übergängen zu
# einer großen grauen Fläche, deshalb dort nur Gras.)
paint("earth", range(27, 30), range(12, 14))
# Weg von der Baumtür durch beide Tore bis zum Ausgang.
paint("path", [25], range(4, 23))

# Laternen: an beiden Toren, in den Zaunecken, am Weg nach Süden.
mark("lantern", [(24, 6), (26, 6), (18, 6), (32, 6), (24, 13), (26, 13),
                 (18, 13), (24, 18), (26, 21), (22, 4), (29, 4)])
# Bäume: dichter Rand links, rechts, oben und unten.
mark("tree", [(14, -3), (16, -1), (14, 1), (16, 3), (14, 5), (16, 7), (14, 9), (16, 11),
              (14, 13), (16, 15), (14, 17), (16, 19), (14, 21),
              (37, -3), (35, -1), (37, 1), (35, 3), (37, 5), (35, 7), (37, 9), (35, 11),
              (37, 13), (35, 15), (37, 17), (35, 19), (37, 21),
              (18, -3), (20, -2), (31, -2), (33, -3), (19, 1), (32, 1),
              (18, 21), (21, 22), (29, 22), (32, 21), (19, 17), (31, 17)])
mark("bush", [(15, -2), (15, 2), (15, 6), (15, 10), (15, 14), (15, 18),
              (36, -2), (36, 2), (36, 6), (36, 10), (36, 14), (36, 18),
              (17, 0), (20, 2), (31, 2), (34, 0), (22, 20), (28, 20), (33, 16), (18, 16)])
mark("rock", [(20, 19), (30, 19), (17, 3)])

height.save(os.path.join(HERE, "height.png"))
ground.save(os.path.join(HERE, "ground.png"))
marks.save(os.path.join(HERE, "marks.png"))
with open(os.path.join(HERE, "plan.json"), "w", encoding="utf-8") as f:
    json.dump({
        "scene": "res://scenes/world/garden.tscn",
        "levels": 3,
        "default_level": 1,
        "default_ground": "grass",
        "origin": list(ORIGIN),
        "depth_shade": False,
    }, f, indent=1)
print("Plan geschrieben:", HERE)
