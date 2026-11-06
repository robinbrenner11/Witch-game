"""Platzhalter für Sperren (Gates) im Seewald, bis Robin echte Grafiken macht.

- swamp_vines.png (64x64): Ranken-Treppe S4 zu, ruhige Bitterblüten-Ranken mit
  Dornen und Knospen, quer über die Treppe gewachsen.
- swamp_vines_open.png (64x64): Ranken verbrannt oder geschnitten, nur
  verkohlte Stümpfe am Rand und Asche.
- moon_bridge.png (192x32): Mondsteg S1, Planken aus Mondlicht. Zu zeigt ihn
  das Spiel nur schwach schimmernd (die Spiegelung weist auf die Insel).

Licht von oben links, Aubergine-Kontur, Palettenfarben.
Aufruf: python gates.py <ausgabeordner>
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from props import C, Canvas  # noqa: E402

# Zusätzliche Töne aus hexen_palette.gpl
C.update({
    "s": (214, 232, 222),  # Silber-Mondlicht
    "S": (240, 244, 255),  # Glanz kalt
    "p": (92, 30, 78),     # Magenta gedämpft
    "z": (32, 20, 30),     # Ebenholz 1 (verkohlt)
    "Z": (52, 34, 46),     # Ebenholz 2
    "y": (78, 52, 64),     # Ebenholz 3 (Asche)
    "l": (22, 34, 46),     # Laub Schatten
})


def vine_path(rng, start, end, wobble):
    """Punkte entlang einer geschwungenen Linie von start nach end."""
    (x0, y0), (x1, y1) = start, end
    phase = rng.uniform(0, math.tau)
    steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2)
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t + math.sin(t * math.pi * 2 + phase) * wobble
        yield round(x), round(y)


def swamp_vines():
    rng = random.Random(7)
    c = Canvas(64, 64)
    # Hinten: dichtes, dunkles Geflecht (Tiefe), damit nichts durchscheint.
    for _ in range(14):
        y0, y1 = rng.randint(0, 63), rng.randint(0, 63)
        for x, y in vine_path(rng, (0, y0), (63, y1), rng.uniform(3, 9)):
            c.put(x, y, "l")
            c.put(x, y + 1, "l")
    # Vorn: dicke Ranken, 3 px, Licht oben links
    thick = []
    for i in range(7):
        y0 = 4 + i * 9 + rng.randint(-3, 3)
        y1 = rng.randint(4, 60)
        pts = list(vine_path(rng, (-2, y0), (65, y1), rng.uniform(4, 8)))
        thick.append(pts)
        for x, y in pts:
            c.put(x, y + 1, "q")
            c.put(x, y, "G")
            c.put(x, y - 1, "G")
    for pts in thick:
        for x, y in pts:
            if (x + y) % 3 == 0:
                c.put(x, y - 1, "Q")
    # Blätter: kleine Tropfen an den Ranken
    for pts in thick:
        for x, y in pts[6::14]:
            dy = -3 if rng.random() < 0.5 else 3
            for lx, ly in ((0, 0), (1, 0), (0, dy // 3), (-1, 0)):
                c.put(x + lx, y + dy + ly, "q")
            c.put(x, y + dy, "G")
    # Dornen
    for pts in thick:
        for x, y in pts[3::8]:
            dy = -2 if rng.random() < 0.5 else 2
            c.put(x, y + dy, "a")
    c.outline("a")
    # Knospen: ruhige Bitterblüten, geschlossen, mit hellem Punkt oben links
    for pts in thick[1:6]:
        x, y = pts[rng.randint(len(pts) // 6, len(pts) * 5 // 6)]
        bud = [(0, -4), (1, -4), (-1, -3), (0, -3), (1, -3), (2, -3),
               (-1, -2), (0, -2), (1, -2), (2, -2), (0, -1), (1, -1)]
        for dx, dy in bud:
            c.put(x + dx, y + dy, "m")
        for dx, dy in ((2, -3), (2, -2), (1, -1)):
            c.put(x + dx, y + dy, "p")
        c.put(x, y - 3, "M")
        c.put(x - 1, y - 3, "M")
        for dx, dy in ((0, -5), (1, -5), (-2, -3), (-2, -2), (3, -3), (3, -2), (-1, -1), (2, -1)):
            if c.get(x + dx, y + dy) in ".l":
                c.put(x + dx, y + dy, "a")
    return c.image()


def swamp_vines_open():
    rng = random.Random(11)
    c = Canvas(64, 64)
    # Verkohlte Stümpfe am linken und rechten Rand, wo die Ranken herkamen
    for side in (0, 63):
        for y in rng.sample(range(8, 58), 4):
            length = rng.randint(3, 6)
            for i in range(length):
                x = side + (i if side == 0 else -i)
                c.put(x, y, "z")
                c.put(x, y + 1, "z")
                if i < length - 1:
                    c.put(x, y - 1, "Z")
            c.put(side + (length if side == 0 else -length), y, "y")
    # Asche auf den Stufen
    for _ in range(26):
        c.put(rng.randint(6, 57), rng.randint(4, 60), rng.choice("yyZ"))
    return c.image()


def moon_bridge():
    c = Canvas(192, 32)
    # Planken quer zur Laufrichtung, mit Fugen; leicht unregelmäßig.
    rng = random.Random(3)
    x = 0
    while x < 192:
        w = rng.randint(9, 12)
        top, bottom = 7 + rng.randint(0, 1), 24 - rng.randint(0, 1)
        for px in range(x, min(x + w, 192)):
            for py in range(top, bottom + 1):
                ch = "s"
                if py == top or px == x:
                    ch = "S"  # Licht oben links
                elif py >= bottom - 1 or px == x + w - 1:
                    ch = "U"
                c.put(px, py, ch)
        x += w + 2
    # Lichtfunken über dem Steg
    for _ in range(14):
        c.put(rng.randint(2, 189), rng.choice((3, 4, 27, 28)), "S")
    return c.image()


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    swamp_vines().save(os.path.join(out, "swamp_vines.png"))
    swamp_vines_open().save(os.path.join(out, "swamp_vines_open.png"))
    moon_bridge().save(os.path.join(out, "moon_bridge.png"))


if __name__ == "__main__" and "--mist" not in sys.argv:
    main()


def bloom_mist(seed):
    """Blütennebel S5 (128x64): schwere, olive-violette Schwaden aus
    Pixelklumpen, darin Magenta-Knospen, die durchglimmen. Zwei Varianten
    (seed) zum Überblenden, damit der Nebel wabert."""
    rng = random.Random(seed)
    c = Canvas(128, 64)
    blobs = []
    for _ in range(48):
        blobs.append((rng.uniform(0, 128), rng.uniform(8, 56), rng.uniform(10, 20), rng.uniform(6, 10)))
    for y in range(64):
        for x in range(128):
            v = 0.0
            for bx, by, rx, ry in blobs:
                v = max(v, 1 - (((x - bx) / rx) ** 2 + ((y - by) / ry) ** 2))
            # Ränder ausfransen, oben und unten dünner
            edge = min(min(y, 63 - y) / 8.0, min(x, 127 - x) / 14.0)
            v *= min(1.0, edge)
            if v > 0.5:
                c.put(x, y, "p")
            elif v > 0.2:
                c.put(x, y, "i")
            elif v > 0.05 and (x + y) % 2 == 0:
                c.put(x, y, "i")
    for _ in range(7):
        x, y = rng.randint(8, 119), rng.randint(14, 50)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (0, -1)):
            c.put(x + dx, y + dy, "m")
        c.put(x, y - 1, "M")
    return c.image()


if __name__ == "__main__" and "--mist" in sys.argv:
    out = sys.argv[1]
    bloom_mist(5).save(os.path.join(out, "bloom_mist_1.png"))
    bloom_mist(9).save(os.path.join(out, "bloom_mist_2.png"))
