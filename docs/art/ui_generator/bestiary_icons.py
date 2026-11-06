"""Platzhalter-Bildchen (16x16) für das Bestiarium im Grimoire.

Käfer von oben in den Farben ihrer Spielfigur (scripts/world/blight_beetle.gd):
Aubergine-Panzer bzw. Bordeaux beim Dornkäfer, Magenta-Blüte auf dem Rücken,
dunkle Kontur, Licht von oben links.
Aufruf: python docs/art/ui_generator/bestiary_icons.py assets/ui/bestiary
"""
import os
import sys

from PIL import Image

OUT = "#0E0A14"
BLOOM = "#E458B1"
BLOOM_DARK = "#C2307A"
CORE = "#D9A441"

ICONS = {
    "blight_beetle": ({"o": OUT, "s": "#3A1840", "S": "#6E2A5E", "b": BLOOM, "B": BLOOM_DARK, "c": CORE}, [
        "................",
        "......o..o......",
        ".......oo.......",
        "......oooo......",
        ".....ossSSo.....",
        "oo..oSSsbbso..oo",
        "..ooSSsbccbsoo..",
        "....oSsBbbBso...",
        "oo..oSssBBsso.oo",
        "..ooSSsssssssoo.",
        "....oSsssssso...",
        "oo..oSsssssso.oo",
        "....oosssssoo...",
        "......ooooo.....",
        "................",
        "................",
    ]),
    "blight_beetle_horned": ({"o": OUT, "s": "#4D1230", "S": "#6E1830", "b": BLOOM, "B": BLOOM_DARK, "c": CORE}, [
        "...o........o...",
        "....o..oo..o....",
        ".....oooooo.....",
        "......oooo......",
        ".....ossSSo.....",
        "oo..oSSsbbso..oo",
        "..ooSSsbccbsoo..",
        "....oSsBbbBso...",
        "oo..oSssBBsso.oo",
        "..ooSSsssssssoo.",
        "....oSsssssso...",
        "oo..oSsssssso.oo",
        "....oosssssoo...",
        "......ooooo.....",
        "................",
        "................",
    ]),
}


def draw(colors, rows):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, key in enumerate(row[:16]):
            if key in colors:
                img.putpixel((x, y), Image.new("RGB", (1, 1), colors[key]).getpixel((0, 0)) + (255,))
    return img


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/ui/bestiary"
    os.makedirs(out, exist_ok=True)
    for name, (colors, rows) in ICONS.items():
        assert len(rows) == 16, name
        draw(colors, rows).save(os.path.join(out, name + ".png"))
    print("Bestiarium-Bildchen nach", out)


if __name__ == "__main__":
    main()
