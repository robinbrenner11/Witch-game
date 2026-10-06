"""Laternenbeere (lantern_berry) – Hirtenstab-Stiel mit hängenden, warm glühenden Beeren.
Frames 32x48, Pflanzposition x 15/16, y 37.
Aufruf: python lantern_berry.py <ausgabeordner> <beet_tile.png>
"""
import sys
from PIL import Image
from pix import grid, put, outline, to_image, W, H


def stamp(g, tpl, x0, y0):
    for j, row in enumerate(tpl):
        for i, ch in enumerate(row):
            if ch != ".":
                put(g, x0 + i, y0 + j, ch)


# Blätter: links (Spitze oben links, zum Licht) und rechts (Spitze oben rechts, Schattenseite)
LEAF_L = [".mm.....",
          "mbbbm...",
          "mbbbbbm.",
          ".dbgbbbm",
          "..ddggbb",
          "....dddg"]
LEAF_R = [".....mm.",
          "...mbbbm",
          ".mbbbddd",
          "mbggdddd",
          "gdddddd.",
          "gddd...."]
LEAF_L_S = ["mm....",
            "mbbm..",
            ".ddggb",
            "...ddg"]
LEAF_R_S = ["....mm",
            "..mbbb",
            "ggddd.",
            "gdd..."]
# Beeren: Licht oben links (Knochen), Körper Kerzenlicht, Schatten Gold
BERRY = [".ccc.",
         "cwccc",
         "ccccg",
         "cccgg",
         ".ggg."]
BERRY_S = [".cc.",
           "cwcg",
           ".gg."]
BERRY_UNRIPE = [".bb.",
                "bMbd",
                "bbdd",
                ".dd."]
BERRY_UNRIPE_S = [".b.",
                  "Mbd",
                  ".d."]


def stem(g, top_y, top_x):
    """Senkrechter Stiel vom Fuß (15,38) bis (top_x, top_y), leicht nach links geneigt.
    Links hell (Bordeaux), rechts dunkel."""
    for y in range(38, top_y - 1, -1):
        t = (38 - y) / max(1, 38 - top_y)
        x = round(15 + (top_x - 15) * t)
        put(g, x, y, "b"); put(g, x + 1, y, "d")


def arc(g, pts):
    """Bogen des Hirtenstabs: oben hell (Magenta-Kante), unten dunkel."""
    for x, y in pts:
        put(g, x, y, "m"); put(g, x, y + 1, "d")


def thread(g, x, y0, y1):
    for y in range(y0, y1 + 1):
        put(g, x, y, "d")


ARC_RIPE = [(12, 10), (12, 9), (13, 8), (14, 7), (15, 6), (16, 6), (17, 5), (18, 5), (19, 5), (20, 5),
            (21, 5), (22, 6), (23, 6), (24, 7), (25, 8), (26, 9), (27, 10), (27, 11), (28, 12), (28, 13)]
ARC_GROW = [(13, 15), (14, 14), (15, 13), (16, 13), (17, 13), (18, 13), (19, 14), (20, 15), (21, 16), (21, 17)]


def stage_seed():
    g = grid([])
    stamp(g, [".gg.",
              "gcgg",
              "ggdd",
              ".dd."], 14, 33)
    outline(g, "a")
    return g


def stage_sprout():
    g = grid([])
    stem(g, 29, 15)
    arc(g, [(15, 28), (16, 27), (17, 27), (18, 28), (18, 29)])
    stamp(g, LEAF_L_S, 9, 30)
    stamp(g, LEAF_R_S, 17, 32)
    outline(g, "a")
    return g


def stage_growing():
    g = grid([])
    stem(g, 16, 13)
    arc(g, ARC_GROW)
    stamp(g, LEAF_L, 5, 29)
    stamp(g, LEAF_R, 16, 22)
    stamp(g, LEAF_L_S, 7, 20)
    # unreife Beeren: dunkel, ohne Glühen
    thread(g, 21, 20, 20)
    stamp(g, BERRY_UNRIPE, 20, 21)
    thread(g, 17, 16, 17)
    stamp(g, BERRY_UNRIPE_S, 16, 18)
    outline(g, "a")
    return g


def stage_ripe():
    g = grid([])
    stem(g, 11, 12)
    arc(g, ARC_RIPE)
    stamp(g, LEAF_L, 4, 27)
    stamp(g, LEAF_R, 16, 20)
    stamp(g, LEAF_L, 4, 16)
    stamp(g, LEAF_R_S, 17, 31)
    # drei Laternen in unterschiedlicher Höhe, frei unter dem Bogen hängend
    thread(g, 18, 7, 9)
    stamp(g, BERRY_S, 17, 10)
    thread(g, 23, 8, 13)
    stamp(g, BERRY, 21, 14)
    thread(g, 28, 15, 17)
    stamp(g, BERRY, 26, 18)
    outline(g, "a")
    # warme Glimmpunkte (kein Verlauf – echtes Licht macht Godot)
    for x, y in [(31, 16), (19, 18), (24, 25), (30, 27), (15, 13)]:
        put(g, x, y, "c")
    return g


def main(out, bed):
    fr = [to_image(f) for f in (stage_seed(), stage_sprout(), stage_growing(), stage_ripe())]
    sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, f in enumerate(fr):
        sheet.alpha_composite(f, (i * W, 0))
    sheet.save(f"{out}/lantern_berry_stages.png")
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
    c.save(f"{out}/zwischenstand_lantern_berry.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
