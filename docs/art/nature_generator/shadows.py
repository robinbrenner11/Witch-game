"""Bodenschatten (Bitterbloom): einfache Pixel-Ovale, die unter Objekten liegen.

Aufruf (aus dem Projektordner):
    python docs/art/nature_generator/shadows.py

Warum eigene Grafiken statt eingebacken: Ein Schatten muss auf jedem Boden
funktionieren (Erde, Waldboden, Gras, Holzboden). Deshalb ist er ein reines
Tiefschwarz-Oval mit harten Pixeln und bekommt erst in Godot seine Deckkraft
(modulate.a ≈ 0.5). Er liegt UNTER allen Objekten (z_index −1 oder eigener Layer).

Ausgabe: assets/effects/shadows/shadow_<B>x<H>.png  und eine Zuordnungstabelle
         (SHADOWS unten), die auch in ASSETS.md steht.
"""
import math
from PIL import Image
from nature import ROOT, PAL

OUT = ROOT / "assets/effects/shadows"
ALPHA = 0.5             # Empfehlung für modulate.a (der Boden ist dunkel, daher kräftiger als üblich)

# Objekt -> (Breite, Höhe, Versatz x, Versatz y) des Schattens.
# Versatz = Mitte des Ovals relativ zum Fußpunkt des Objekts. Licht kommt von
# oben links, deshalb liegt der Schatten leicht rechts.
SHADOWS = {
    # Regel: etwa 8 px breiter als der Fuß des Objekts und 1 px unter dem Fußpunkt,
    # damit der Schatten unten und an den Seiten sichtbar hervorschaut.
    # Figuren
    "witch": (36, 8, 2, 1),
    "toad": (18, 5, 1, 1),
    # Bäume (breiter als der Stamm: Schatten der Krone am Stammfuß)
    "tree_oak": (88, 20, 6, -3),
    "tree_willow": (82, 18, 6, -2),
    "tree_fir": (62, 14, 4, -2),
    "tree_dead": (50, 12, 4, -1),
    "tree_elder": (64, 16, 4, -2),
    "hollow_tree": (180, 36, 8, -8),
    # Unterholz
    "bush_1": (36, 9, 2, 1), "bush_2": (52, 10, 2, 1), "bush_berries": (36, 9, 2, 1),
    "bush_lavender": (30, 7, 1, 1),
    "stump": (36, 9, 2, 1), "log": (66, 11, 2, 1),
    "rock_1": (34, 9, 2, 1), "rock_2": (18, 5, 1, 1),
    "fern_1": (30, 7, 1, 1), "fern_2": (30, 7, 1, 1),
    "wild_grass_1": (28, 7, 1, 1), "wild_grass_2": (28, 7, 1, 1), "wild_grass_3": (28, 7, 1, 1),
    "weed_thistle": (26, 7, 1, 1), "weed_dock": (28, 7, 1, 1),
    "flowers_lilac": (22, 6, 1, 1), "flowers_moon": (22, 6, 1, 1),
    "flowers_ember": (22, 6, 1, 1), "flowers_blood": (22, 6, 1, 1),
    "mushroom_moon": (24, 6, 1, 1), "mushroom_ember": (24, 6, 1, 1),
    # Garten-Objekte (vorhanden)
    "plant": (24, 6, 1, 1),             # alle Pflanzen auf dem Beet, ab Stufe 1
    "campfire": (38, 10, 1, 0),
    "cauldron": (54, 12, 2, 0),
    "bed": (38, 9, 2, 1),
    "lectern": (30, 8, 1, 1),
    "fence_post": (12, 4, 1, 1),        # pro Zaunpfosten (Kachelmitte + (0, +12))
    # Sammelobjekte (Wald)
    "forage_mushroom": (26, 6, 1, 1), "forage_berries": (36, 9, 2, 1), "forage_moss": (30, 7, 2, 1),
    # Begleiterin
    "cat": (22, 6, 1, 1),
    # Gartentor (pro Torpfosten wie beim Zaun)
    # Unterschlupf innen
    "shelter_armchair": (46, 10, 2, 1),
    "shelter_chest": (36, 9, 2, 1),
    "shelter_stove": (32, 8, 1, 1),
    "shelter_shelf": (60, 7, 0, 1),
    "shelter_books": (18, 5, 1, 1),
    "shelter_broom": (14, 5, 1, 1),
    "shelter_firewood": (30, 7, 1, 1),
}


def oval(w, h):
    """Pixel-Oval; die Enden etwas flacher, damit es nicht wie ein Ei wirkt."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y in range(h):
        for x in range(w):
            u = (x + 0.5 - w / 2) / (w / 2)
            v = (y + 0.5 - h / 2) / (h / 2)
            if abs(u) ** 2.4 + abs(v) ** 2 <= 1.0:
                px[x, y] = PAL["TS"] + (255,)
    return im


def size_name(w, h):
    return f"shadow_{w}x{h}"


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sizes = sorted({(w, h) for w, h, _, _ in SHADOWS.values()})
    for w, h in sizes:
        oval(w, h).save(OUT / f"{size_name(w, h)}.png")
    print(f"  {len(sizes)} Schatten-Größen nach assets/effects/shadows/")


def draw_shadow(img, name, fx, fy, alpha=ALPHA):
    """Für die Vorschauen: Schatten unter ein Objekt legen (Fußpunkt fx, fy)."""
    if name not in SHADOWS:
        return
    w, h, dx, dy = SHADOWS[name]
    sh = oval(w, h).load()
    px = img.load()
    x0 = fx + dx - w // 2
    y0 = fy + dy - h // 2
    for y in range(h):
        for x in range(w):
            if sh[x, y][3]:
                X, Y = x0 + x, y0 + y
                if 0 <= X < img.width and 0 <= Y < img.height:
                    r, g, b, a = px[X, Y]
                    t = PAL["TS"]
                    px[X, Y] = (int(r * (1 - alpha) + t[0] * alpha), int(g * (1 - alpha) + t[1] * alpha),
                                int(b * (1 - alpha) + t[2] * alpha), a)


if __name__ == "__main__":
    main()
