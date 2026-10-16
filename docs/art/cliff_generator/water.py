"""Platzhalter für Wasser (32x32 pro Feld): tief, Ufer, flach, Durchgang.
Durchgang sieht aus wie tiefes Wasser, ist aber begehbar (z. B. der Mondsteg
unter einem Gate). Robin übermalt die Felder später; das Raster bleibt.
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


def tile(kind):
    px = [[DEEP] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            # leichte Wellen: kurze helle Striche in versetzten Reihen
            if (y % 8 == 3) and ((x + y * 3) % 16) < 4:
                px[y][x] = MID
    if kind == "shore":
        for y in range(T):
            for x in range(T):
                if (x + y) % 2 == 0:
                    px[y][x] = MID
        for y in range(T):
            for x in range(T):
                if y % 8 == 3 and ((x + y * 3) % 16) < 4:
                    px[y][x] = LIGHT
    if kind == "shallow":
        for y in range(T):
            for x in range(T):
                px[y][x] = MID if (y % 8 != 3 or ((x + y * 3) % 16) >= 4) else FOAM
    return px


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/environment/water"
    os.makedirs(out, exist_ok=True)
    img = Image.new("RGBA", (4 * T, T), (0, 0, 0, 0))
    for name, (col, row, _c) in LAYOUT.items():
        px = tile("deep" if name == "pass" else name)
        for y in range(T):
            for x in range(T):
                img.putpixel((col * T + x, row * T + y), px[y][x] + (255,))
    img.save(os.path.join(out, "water_placeholder.png"))
    layout = {"tile_size": T, "texture": "water_placeholder.png",
              "tiles": {n: {"col": c, "row": r, "collision": k} for n, (c, r, k) in LAYOUT.items()}}
    with open(os.path.join(out, "water_layout.json"), "w", encoding="utf-8") as f:
        json.dump(layout, f, indent=1)
    print("Wasser-Platzhalter nach", out)


if __name__ == "__main__":
    main()
