"""Platzhalter Blütenherz (Boss Turmruine), bis Robin die große Grafik macht
(docs/auftraege/grafik_auftrag_bitterbloom.md).

64x64, Fußpunkt unten Mitte. Nach bitterbloom.md: olive Ranken wie ein Korsett,
fleischige Magenta-Knospe wie eine geschlossene Hand, die sich in Phase 2–3 zu
einer stacheligen, asymmetrischen Blüte öffnet; Wurzeln am Boden.
  bloom_heart_1.png  Phase 1: geschlossen, pulsiert
  bloom_heart_2.png  Phase 2: aufgebrochen, Risse leuchten
  bloom_heart_3.png  Phase 3: offen, stachelig
  bloom_heart_cleansed.png  gereinigt: bleich, Ranken fallen ab, ein heller Kern
  bloom_bud.png      16x16 Schildknospe (Phase 3)
Aufruf: python bloom_heart.py <ausgabeordner>
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from props import C, Canvas, ellipse_points  # noqa: E402

C.update({
    "o": (92, 88, 52),     # Oliv dunkel (Ranken)
    "O": (124, 124, 104),  # Welk oliv (Hochlicht)
    "p": (92, 30, 78),     # Magenta gedämpft
    "r": (255, 210, 236),  # Magenta hell rosa (Glanz)
    "z": (32, 20, 30),     # Ebenholz 1 (Wurzel)
    "Z": (52, 34, 46),     # Ebenholz 2
    "y": (198, 184, 190),  # Laken Schatten (bleich)
})


def roots(c, rng, color="z", light="Z"):
    for i in range(7):
        angle = math.pi * (0.05 + 0.9 * i / 6) + rng.uniform(-0.1, 0.1)
        x, y = 32.0, 57.0
        for step in range(rng.randint(10, 18)):
            x += math.cos(angle) * 1.6
            y += abs(math.sin(angle)) * 0.35
            angle += rng.uniform(-0.25, 0.25)
            c.put(round(x), round(y), color)
            c.put(round(x), round(y) - 1, light)


def bulb(c, open_amount, rng):
    """Fleischige Knospe auf einem Wurzelstiel; ab Phase 2 bricht sie oben
    auf und Blütenblätter mit Stacheln quellen heraus."""
    cx, cy = 32, 40
    # Stiel zu den Wurzeln
    for y in range(50, 59):
        for x in range(29, 36):
            c.put(x, y, "Z" if x < 32 else "z")
    for x, y in ellipse_points(cx, cy, 12, 13):
        c.put(x, y, "m")
    for x, y in ellipse_points(cx - 4, cy - 4, 5, 5):
        c.put(x, y, "M")
    for x, y in ellipse_points(cx + 5, cy + 6, 6, 6):
        if c.get(x, y) == "m":
            c.put(x, y, "p")
    if open_amount == 0:
        c.put(cx - 6, cy - 8, "r")
        c.put(cx - 5, cy - 8, "r")
        return
    top = (cx, cy - 9)
    petals = 5 if open_amount == 1 else 9
    fan = 1.4 if open_amount == 1 else 2.6
    for i in range(petals):
        a = -math.pi / 2 + (i / (petals - 1) - 0.5) * fan + rng.uniform(-0.1, 0.1)
        length = rng.uniform(9, 13) if open_amount == 1 else rng.uniform(14, 21)
        for t in range(int(length)):
            w = max(0, int(3 * (1 - t / length)))
            px = top[0] + math.cos(a) * t
            py = top[1] + math.sin(a) * t
            for k in range(-w, w + 1):
                qx = round(px - math.sin(a) * k * 0.7)
                qy = round(py + math.cos(a) * k * 0.7)
                c.put(qx, qy, "M" if k <= 0 and t < length * 0.6 else "m")
        c.put(round(top[0] + math.cos(a) * length), round(top[1] + math.sin(a) * length), "w")
    # Leuchtender Kern im Spalt
    r = 4 if open_amount == 1 else 6
    for x, y in ellipse_points(top[0], top[1] + 2, r, r - 1):
        c.put(x, y, "p")
    for x, y in ellipse_points(top[0] - 1, top[1] + 1, r // 2, max(1, r // 2 - 1)):
        c.put(x, y, "r")


def corset(c, rng, broken=0.0):
    """Olive Ranken, die sich spiralig um die Knospe winden."""
    for turn in range(4):
        y0 = 24 + turn * 8
        for x in range(18, 47):
            if rng.random() < broken:
                continue
            y = y0 + round(math.sin((x - 18) / 28 * math.pi) * 4) + (x - 18) // 9
            if c.get(x, y) != ".":
                c.put(x, y, "o")
                c.put(x, y - 1, "O" if x < 32 else "o")


def heart(stage, seed=1):
    rng = random.Random(seed)
    c = Canvas(64, 64)
    roots(c, rng)
    bulb(c, stage - 1, rng)
    corset(c, rng, broken=[0.0, 0.35, 0.7][stage - 1])
    c.outline("a")
    # Risse: schwarze Linien mit Magenta in Phase 2
    if stage >= 2:
        for x, y in [(26, 44), (27, 45), (28, 46), (38, 30), (39, 31), (37, 29)]:
            c.put(x, y, "k")
    return c.image()


def cleansed():
    rng = random.Random(2)
    c = Canvas(64, 64)
    roots(c, rng, "Z", "y")
    # Bleiche, geschlossene Hülle, ruhig
    for x, y in ellipse_points(32, 44, 9, 10):
        c.put(x, y, "y")
    for x, y in ellipse_points(29, 41, 4, 4):
        c.put(x, y, "w")
    # Abgefallene Rankenstücke am Boden
    for x in range(16, 24):
        c.put(x, 56, "o")
    for x in range(42, 49):
        c.put(x, 57, "o")
    # Heller Kern, der durchscheint (Kerzenlicht: geheilt, warm)
    for x, y in ellipse_points(32, 45, 3, 3):
        c.put(x, y, "c")
    c.put(31, 44, "w")
    c.outline("a")
    return c.image()


def shield_bud():
    c = Canvas(16, 16)
    for x, y in ellipse_points(8, 9, 4.5, 5.5):
        c.put(x, y, "m")
    for x, y in ellipse_points(6.5, 7, 1.6, 2):
        c.put(x, y, "M")
    c.put(6, 6, "r")
    for x in range(4, 13):
        c.put(x, 11 + (x % 3 == 0), "o")
    c.outline("a")
    return c.image()


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    for stage in (1, 2, 3):
        heart(stage).save(os.path.join(out, f"bloom_heart_{stage}.png"))
    cleansed().save(os.path.join(out, "bloom_heart_cleansed.png"))
    shield_bud().save(os.path.join(out, "bloom_bud.png"))


if __name__ == "__main__":
    main()
