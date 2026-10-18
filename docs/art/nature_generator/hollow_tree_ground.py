"""Bodenfleck unter dem Uraltbaum: aufgeworfene dunkle Erde zwischen den Wurzeln,
außen Moos, das mit Dither ins Gras übergeht. Liegt flach unter dem Baum, damit
die Wurzeln im Boden stecken statt auf ihm zu sitzen.

Aufruf: python docs/art/nature_generator/hollow_tree_ground.py assets/environment/shelter
Ursprung des Bildes = Fußpunkt des Baums (Tür): Bildmitte x, Zeile ORIGIN_Y.
"""
import os
import sys
import numpy as np
from PIL import Image

W, H = 320, 104
ORIGIN_Y = 44            # Zeile des Fußpunkts im Bild
CX, CY = -12, 12         # Mitte des Flecks relativ zum Fußpunkt (Wurzeln reichen links weiter)
RX, RY = 150, 44

# Töne aus dem Gartenboden und der Palette
EARTH_DEEP = (33, 21, 28)
EARTH = (43, 29, 32)
EARTH_LIGHT = (55, 39, 37)
MOSS_DARK = (29, 52, 54)     # Laub dunkel
MOSS = (38, 64, 50)          # Gras mittel aus dem Garten
MOSS_LIGHT = (88, 113, 73)   # Moosgrün


def value_noise(w, h, cell, seed):
    rng = np.random.default_rng(seed)
    gw, gh = w // cell + 2, h // cell + 2
    g = rng.uniform(-1, 1, (gh, gw))
    ys, xs = np.mgrid[0:h, 0:w] / cell
    x0, y0 = xs.astype(int), ys.astype(int)
    fx, fy = xs - x0, ys - y0
    a = g[y0, x0] * (1 - fx) + g[y0, x0 + 1] * fx
    b = g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/environment/shelter"
    ys, xs = np.mgrid[0:H, 0:W]
    px = xs - W / 2 - CX
    py = ys - ORIGIN_Y - CY
    d = np.sqrt((px / RX) ** 2 + (py / RY) ** 2)
    d = d + 0.16 * value_noise(W, H, 10, 7) + 0.06 * value_noise(W, H, 4, 3)
    fleck = value_noise(W, H, 5, 11)
    img = np.zeros((H, W, 4), np.uint8)
    checker = (xs + ys) % 2 == 0

    def put(mask, col):
        img[mask] = (*col, 255)

    put(d < 1.0, MOSS_DARK)
    put((d < 1.0) & (fleck > 0.35), MOSS)
    put((d < 1.0) & (fleck > 0.7), MOSS_LIGHT)
    put(d < 0.82, EARTH_LIGHT)
    put(d < 0.72, EARTH)
    put((d < 0.72) & (fleck > 0.45), MOSS_DARK)      # Moosinseln auf der Erde
    put(d < 0.5, EARTH_DEEP)                          # dort, wo die Wurzeln eintauchen
    # Außenrand: Moos löst sich im Schachbrett ins Gras auf (keine weiche Kante)
    edge = (d >= 0.93) & (d < 1.0) & checker
    img[edge] = 0
    Image.fromarray(img).save(os.path.join(out, "hollow_tree_ground.png"))
    print("Bodenfleck nach", out)


if __name__ == "__main__":
    main()
