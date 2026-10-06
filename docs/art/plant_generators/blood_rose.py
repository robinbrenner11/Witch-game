"""Blutrose (blood_rose) – schmale, hohe Zickzack-Ranke mit Golddornen, oben eine einzelne Rose.
Reif: Rose geöffnet, goldene Tropfen an den Dornen.
Frames 32x48, Pflanzposition x 15/16, y 37.
Aufruf: python blood_rose.py <ausgabeordner> <beet_tile.png>
"""
import sys
from PIL import Image
import pix
from pix import grid, put, outline, to_image, W, H

pix.PAL.update({"q": (36, 74, 58), "Q": (98, 160, 110)})   # Blattgrün (wie Alraune)

ROSE = [
    "....mmmmm....",
    "..mmbbbbbmm..",
    ".mbbbdddbbbm.",
    "mbbddbbbddbbd",
    "mbdbbmmbbdbbd",
    "mbdbmbbdbdbbd",
    "mbdbbddbbdbdd",
    ".bbddbbbddbd.",
    ".dbbbdddbbdd.",
    "..ddbbbbbdd..",
    "...ddddddd...",
    "..QqqdddqqQ..",
    ".Qq.......qQ.",
]
BUD = [
    ".Mb.",
    "mbbd",
    "mbbd",
    "Gbdq",
    "Gqqq",
    ".qq.",
]
LEAF_L = ["QG..",
          "GGq.",
          ".qqq"]
LEAF_R = ["..GQ",
          ".Gqq",
          "qqq."]


def stamp(g, tpl, x0, y0):
    for j, row in enumerate(tpl):
        for i, ch in enumerate(row):
            if ch != ".":
                put(g, x0 + i, y0 + j, ch)


def vine(g, top_y, period=14, amp=1):
    """Zickzack-Ranke von unten bis top_y. Gibt die Knickpunkte (für Dornen) zurück."""
    xs = {}
    for y in range(38, top_y - 1, -1):
        p = ((38 - y) % period) / period
        tri = 4 * p if p < 0.25 else (2 - 4 * p if p < 0.75 else 4 * p - 4)
        xs[y] = 15 + round(amp * tri)
    prev = None
    for y in range(38, top_y - 1, -1):
        x = xs[y]
        put(g, x, y, "b"); put(g, x + 1, y, "d")
        if prev is not None and prev != x:
            put(g, min(prev, x) + 1, y + 1, "b")   # Diagonale geschlossen halten
        prev = x
    corners = []
    for y in range(37, top_y, -1):
        x = xs[y]
        if x > xs[y + 1] and x >= xs[y - 1]:
            corners.append((x, y, 1))
        elif x < xs[y + 1] and x <= xs[y - 1]:
            corners.append((x, y, -1))
    # pro Knick nur ein Dorn
    out = []
    for c in corners:
        if not out or (abs(out[-1][1] - c[1]) >= 6 and out[-1][2] != c[2]):
            out.append(c)
    return out


def thorns(g, corners, drops=False):
    for x, y, side in corners:
        if side > 0:
            put(g, x + 2, y, "g"); put(g, x + 3, y - 1, "g")
            if drops:
                put(g, x + 3, y + 1, "c"); put(g, x + 3, y + 2, "g")
        else:
            put(g, x - 1, y, "g"); put(g, x - 2, y - 1, "g")
            if drops:
                put(g, x - 2, y + 1, "c"); put(g, x - 2, y + 2, "g")


def stage_seed():
    g = grid([])
    stamp(g, [".g.",
              ".b.",
              "mbd",
              "bdd",
              ".d."], 14, 32)
    outline(g, "a")
    return g


def stage_sprout():
    g = grid([])
    c = vine(g, 28)
    thorns(g, c[:1])
    stamp(g, LEAF_L, 11, 30)
    stamp(g, LEAF_R, 18, 27)
    outline(g, "a")
    return g


def stage_growing():
    g = grid([])
    c = vine(g, 13)
    thorns(g, c)
    stamp(g, LEAF_L, 11, 32)
    stamp(g, LEAF_R, 18, 25)
    stamp(g, LEAF_L, 11, 19)
    tx = [x for x, y, _ in []] or None
    stamp(g, BUD, 14, 7)
    outline(g, "a")
    return g


def stage_ripe():
    g = grid([])
    c = vine(g, 13)
    thorns(g, c, drops=True)
    stamp(g, LEAF_L, 11, 32)
    stamp(g, LEAF_R, 18, 25)
    stamp(g, LEAF_L, 11, 19)
    stamp(g, ROSE, 10, 1)
    outline(g, "a")
    return g


def main(out, bed):
    fr = [to_image(f) for f in (stage_seed(), stage_sprout(), stage_growing(), stage_ripe())]
    sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, f in enumerate(fr):
        sheet.alpha_composite(f, (i * W, 0))
    sheet.save(f"{out}/blood_rose_stages.png")
    bed_t = Image.open(bed).convert("RGBA")
    pv = Image.new("RGBA", (W * 4 + 3 * 8, H), (14, 10, 20, 255))
    for i in range(4):
        x0 = i * (W + 8)
        pv.alpha_composite(bed_t, (x0, 16))
        pv.alpha_composite(bed_t.crop((0, 16, 32, 32)), (x0, 0))
        pv.alpha_composite(fr[i], (x0, 0))
    big = pv.resize((pv.width * 4, pv.height * 4), Image.NEAREST)
    bg = Image.new("RGBA", sheet.size, (14, 10, 20, 255)); bg.alpha_composite(sheet)
    c = Image.new("RGBA", (big.width, big.height + 116), (14, 10, 20, 255))
    c.alpha_composite(big); c.alpha_composite(bg, (0, big.height + 10))
    c.alpha_composite(bg.resize((256, 96), Image.NEAREST), (150, big.height + 10))
    c.save(f"{out}/zwischenstand_blood_rose.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
