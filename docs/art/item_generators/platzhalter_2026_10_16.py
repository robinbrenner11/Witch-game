"""Platzhalter-Icons (16x16) für die Items aus docs/design/welt_und_items.md:
drei neue Tränke im Stil der bestehenden Kolben (props.potion) und vier
Zutaten als einfache Formen. Echte Grafiken kommen später von Robin.
Aufruf: python docs/art/item_generators/platzhalter_2026_10_16.py assets/items
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "world_generator"))
from props import Canvas, C, ellipse_points, potion  # noqa: E402

C.update({
    "s": (150, 160, 190), "S": (205, 214, 232),   # Reinigungsnebel: silbrig
    "v": (60, 44, 92), "V": (104, 82, 140),       # Dämmertrank: Dämmerviolett
    "r": (150, 40, 60), "R": (210, 90, 100),      # Heiltrank II: tiefrot
    "t": (92, 66, 48), "T": (130, 98, 70),        # Rinde
    "l": (120, 190, 150), "L": (190, 240, 200),   # Sumpflicht
})


def bark():
    cv = Canvas(16, 16)
    for y in range(3, 14):
        for x in range(5, 11):
            cv.put(x, y, "T" if (x + y // 3) % 3 == 0 else "t")
    for y in range(4, 13, 3):
        cv.put(6, y, "h"); cv.put(9, y + 1, "h")
    cv.outline("a")
    return cv.image()


def moon_water():
    cv = Canvas(16, 16)
    for x, y in ellipse_points(7.5, 9.5, 5.0, 4.5):
        cv.put(x, y, "U" if x + y < 15 else "u")
    cv.put(6, 7, "w"); cv.put(5, 8, "w")
    for x in range(6, 10):
        cv.put(x, 4, "U")
    cv.outline("a")
    return cv.image()


def swamp_light():
    cv = Canvas(16, 16)
    for x, y in ellipse_points(7.5, 7.5, 3.8, 3.8):
        cv.put(x, y, "L" if x + y < 15 else "l")
    for y in range(11, 15):
        cv.put(7, y, "q"); cv.put(8, y, "q")
    cv.outline("a")
    return cv.image()


def bloom_bud():
    cv = Canvas(16, 16)
    for x, y in ellipse_points(7.5, 8.5, 4.2, 5.0):
        cv.put(x, y, "M" if x + y < 14 else "m")
    for x in range(5, 11):
        cv.put(x, 13, "q")
    cv.put(6, 6, "w")
    cv.outline("a")
    return cv.image()


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/items"
    os.makedirs(out, exist_ok=True)
    potion("s", "S", "u").save(os.path.join(out, "potion_cleansing_mist.png"))
    potion("v", "V", "i").save(os.path.join(out, "potion_dusk.png"))
    potion("r", "R", "d").save(os.path.join(out, "potion_mending_strong.png"))
    bark().save(os.path.join(out, "willow_bark.png"))
    moon_water().save(os.path.join(out, "moon_water.png"))
    swamp_light().save(os.path.join(out, "swamp_light.png"))
    bloom_bud().save(os.path.join(out, "bloom_bud.png"))
    print("7 Icons nach", out)
