"""Platzhalter für Wasser (32x32 pro Feld): tief, Ufer, flach, Durchgang.
Durchgang sieht aus wie tiefes Wasser, ist aber begehbar (z. B. der Mondsteg
unter einem Gate). Robin übermalt die Felder später; das Raster bleibt.

Animation (03.11.2026): FRAMES Bilder pro Feld. Frame k liegt rechts daneben
als eigener Block: Spalten k*4 .. k*4+3 in derselben Reihenfolge (tief, Ufer,
flach, Durchgang). So bleiben die Felder von Frame 0 dort, wo sie immer
waren, und schon gebaute Orte stimmen weiter. Die Wellenstriche wandern pro
Frame 4 Pixel nach rechts; nach FRAMES Bildern ist das Muster wieder am
Anfang, die Schleife hat also keinen Sprung.
Aufruf: python docs/art/cliff_generator/water.py assets/environment/water
"""
import json
import os
import sys

from PIL import Image

T = 32
DEEP = (20, 27, 58)
MID = (38, 54, 94)
LIGHT = (78, 106, 154)
FOAM = (150, 170, 205)
# Feldname -> (Spalte, Zeile, Kollision)
LAYOUT = {"deep": (0, 0, "full"), "shore": (1, 0, "full"), "shallow": (2, 0, "none"), "pass": (3, 0, "none")}
# Bilder pro Feld und Sekunden pro Bild (ruhiges Wasser, nicht hektisch).
FRAMES = 4
FRAME_DURATION = 0.3
# So weit wandert das Muster pro Bild (Pixel). Muster-Periode 16 = FRAMES * SHIFT.
SHIFT = 4


def wave(x, y, frame):
    """Kurze helle Striche in versetzten Reihen, pro Bild ein Stück weiter."""
    return y % 8 == 3 and ((x - frame * SHIFT + y * 3) % 16) < 4


def tile(kind, frame=0):
    px = [[DEEP] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            if wave(x, y, frame):
                px[y][x] = MID
    if kind == "shore":
        for y in range(T):
            for x in range(T):
                if (x + y) % 2 == 0:
                    px[y][x] = MID
        for y in range(T):
            for x in range(T):
                if wave(x, y, frame):
                    px[y][x] = LIGHT
    if kind == "shallow":
        for y in range(T):
            for x in range(T):
                px[y][x] = FOAM if wave(x, y, frame) else MID
    return px


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/environment/water"
    os.makedirs(out, exist_ok=True)
    block = len(LAYOUT)
    img = Image.new("RGBA", (FRAMES * block * T, T), (0, 0, 0, 0))
    for frame in range(FRAMES):
        for name, (col, row, _c) in LAYOUT.items():
            px = tile("deep" if name == "pass" else name, frame)
            left = (frame * block + col) * T
            for y in range(T):
                for x in range(T):
                    img.putpixel((left + x, row * T + y), px[y][x] + (255,))
    img.save(os.path.join(out, "water_placeholder.png"))
    layout = {"tile_size": T, "texture": "water_placeholder.png",
              "frames": FRAMES, "frame_duration": FRAME_DURATION,
              "tiles": {n: {"col": c, "row": r, "collision": k} for n, (c, r, k) in LAYOUT.items()}}
    with open(os.path.join(out, "water_layout.json"), "w", encoding="utf-8") as f:
        json.dump(layout, f, indent=1)
    print("Wasser-Platzhalter nach", out)


if __name__ == "__main__":
    main()
