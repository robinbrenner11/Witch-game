"""Platzhalter-Objekte für die Welt (32x32, Fußpunkt unten Mitte): Hexenfeuer,
Kessel – dazu die Trank-Icons (16x16) für das Inventar.
Licht von oben links, Aubergine-Kontur, nur Palettenfarben.
Aufruf: python props.py <ausgabeordner_props> <ausgabeordner_items>
"""
import sys, os
from PIL import Image

C = {
    "k": (14, 10, 20), "a": (43, 22, 51), "d": (77, 18, 48), "b": (110, 24, 48),
    "m": (194, 48, 122), "M": (228, 88, 177), "g": (217, 164, 65),
    "c": (255, 181, 102), "w": (234, 223, 203),
    "e": (74, 43, 39), "h": (107, 63, 51), "H": (138, 82, 64),
    "u": (52, 70, 120), "U": (120, 140, 185), "n": (20, 27, 58),
    "G": (63, 125, 90), "q": (36, 74, 58), "Q": (98, 160, 110),
    "i": (46, 42, 107), "I": (74, 69, 150),
}


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["."] * w for _ in range(h)]

    def put(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

    def get(self, x, y):
        return self.g[y][x] if 0 <= x < self.w and 0 <= y < self.h else "."

    def outline(self, col="a", only_below=None):
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] != ".":
                    continue
                if any(self.get(x + dx, y + dy) not in "." for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    if only_below is None or y >= only_below:
                        add.append((x, y))
        for x, y in add:
            self.g[y][x] = col

    def image(self):
        im = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                ch = self.g[y][x]
                if ch in C:
                    im.putpixel((x, y), C[ch] + (255,))
        return im


def ellipse_points(cx, cy, rx, ry):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                yield x, y


# Flammenhöhe pro Spalte (x 10..22) je Animationsframe – drei züngelnde Spitzen.
FLAMES = [
    [2, 4, 7, 9, 8, 10, 13, 11, 8, 9, 6, 4, 2],
    [2, 5, 8, 7, 9, 12, 11, 9, 10, 8, 5, 3, 1],
    [1, 4, 6, 8, 10, 9, 12, 13, 9, 7, 7, 4, 2],
]


def campfire(frame):
    cv = Canvas(32, 32)
    # Asche-Mulde
    for x, y in ellipse_points(16, 26, 9, 2.6):
        cv.put(x, y, "k")
    # Flammen: außen Magenta-Spitzen (Hexenfeuer), Körper Gold, innen Kerzenlicht, Kern Knochen
    heights = FLAMES[frame]
    base = 24
    for i, hgt in enumerate(heights):
        x = 10 + i
        edge = min(i, len(heights) - 1 - i)
        for k in range(hgt):
            y = base - k
            top = hgt - k
            if top <= 2 and hgt >= 6:
                col = "m" if top == 1 else "M"
            elif edge == 0 or top <= 3:
                col = "g"
            elif edge >= 4 and 1 <= k < hgt * 0.35:
                col = "w"
            else:
                col = "c"
            cv.put(x, y, col)
    # Holzscheite über Kreuz, vor den Flammen (hell oben links, dunkel unten rechts)
    for t in range(13):
        cv.put(10 + t, 25 + t // 6, "h"); cv.put(10 + t, 26 + t // 6, "e")
        cv.put(22 - t, 25 + t // 6, "H" if t < 4 else "h"); cv.put(22 - t, 26 + t // 6, "e")
    # Steinring: einzelne Steine, oben links aufgehellt
    stones = [(6, 26), (9, 29), (13, 30), (18, 30), (23, 29), (26, 26), (24, 23), (8, 23)]
    for sx, sy in stones:
        for x, y in ellipse_points(sx, sy, 2.2, 1.6):
            cv.put(x, y, "u")
        cv.put(sx - 1, sy - 1, "U"); cv.put(sx, sy - 1, "U")
        cv.put(sx + 1, sy + 1, "n")
    cv.outline("a", only_below=20)
    return cv.image()


# Blasen im Sud je Frame (x, y, Farbe)
BUBBLES = [
    [(12, 14, "Q"), (19, 15, "w"), (16, 13, "Q")],
    [(14, 15, "w"), (20, 14, "Q"), (11, 15, "Q")],
]


def cauldron(frame):
    cv = Canvas(32, 32)
    # drei kurze Füße
    for fx in (9, 16, 23):
        cv.put(fx, 29, "k"); cv.put(fx, 28, "k")
    # bauchiger Topf: oben links Indigo-Glanz, sonst fast schwarz
    for x, y in ellipse_points(16, 22, 10, 6.5):
        col = "a"
        if (x - 16) + (y - 22) * 1.3 < -7:
            col = "i"
        if (x - 16) + (y - 22) * 1.3 < -11:
            col = "I"
        if (x - 16) + (y - 22) > 8:
            col = "k"
        cv.put(x, y, col)
    # Rand und Sud
    for x, y in ellipse_points(16, 15, 10, 3.2):
        cv.put(x, y, "k")
    for x, y in ellipse_points(16, 15, 8.5, 2.2):
        cv.put(x, y, "G" if (x - 16) + (y - 15) * 2 > -4 else "Q")
    for x, y in ellipse_points(16, 15.8, 7.5, 1.4):
        if (x - 16) > 2:
            cv.put(x, y, "q")
    for bx, by, col in BUBBLES[frame]:
        cv.put(bx, by, col)
    cv.put(8, 14, "I"); cv.put(9, 13, "I")   # Glanz am Rand
    cv.outline("a")
    return cv.image()


def potion(liquid, light, dark, bubble=None):
    """16x16 Rundkolben mit Korken. liquid/light/dark: Farben des Inhalts."""
    cv = Canvas(16, 16)
    for x, y in ellipse_points(7.5, 10.5, 4.6, 4.2):
        if y >= 9:
            col = liquid
            if x + y < 15:
                col = light
            if x - y > 0 or y >= 14:
                col = dark
        else:
            col = "n"   # leeres, dunkles Glas oberhalb des Füllstands
        cv.put(x, y, col)
    for y in range(4, 7):
        for x in range(6, 10):
            cv.put(x, y, "n")
    for x in range(6, 10):
        cv.put(x, 4, "g")                    # Goldring am Hals
    for y in range(1, 4):
        for x in range(6, 10):
            cv.put(x, y, "H" if x < 8 else "e")   # Korken
    cv.put(5, 8, "w"); cv.put(4, 9, "w")      # Glanzlicht oben links
    if bubble:
        cv.put(*bubble)
    cv.outline("a")
    return cv.image()


if __name__ == "__main__":
    out_props, out_items = sys.argv[1], sys.argv[2]
    os.makedirs(out_props, exist_ok=True)
    sheet = Image.new("RGBA", (32 * len(FLAMES), 32), (0, 0, 0, 0))
    for f in range(len(FLAMES)):
        sheet.alpha_composite(campfire(f), (32 * f, 0))
    sheet.save(os.path.join(out_props, "campfire.png"))
    sheet = Image.new("RGBA", (32 * len(BUBBLES), 32), (0, 0, 0, 0))
    for f in range(len(BUBBLES)):
        sheet.alpha_composite(cauldron(f), (32 * f, 0))
    sheet.save(os.path.join(out_props, "cauldron.png"))
    potion("G", "Q", "q", (9, 11, "Q")).save(os.path.join(out_items, "potion_growth.png"))
    potion("h", "H", "e", (6, 12, "d")).save(os.path.join(out_items, "potion_sludge.png"))
