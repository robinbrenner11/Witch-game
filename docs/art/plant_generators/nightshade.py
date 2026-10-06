"""Nachtschatten (nightshade) – runder, dichter Busch (Kuppel aus vielen kleinen Blättern),
reif mit Bordeaux-Beerentrauben und Magenta-Glanzpunkten.
Frames 32x48, Pflanzposition x 15/16, y 37.
Aufruf: python nightshade.py <ausgabeordner> <beet_tile.png>
"""
import sys, random
from PIL import Image
from pix import grid, put, outline, to_image, W, H, DARKER

# Blatt-"Schuppe": Licht oben links
SCALES = [
    [".lI..",
     "IIIi.",
     "iigin",
     ".inn."],
    ["..Il.",
     ".IIIi",
     "Iiiin",
     ".nn.."],
    [".Ii.",
     "IIgi",
     "iin.",
     ".n.."],
]
FLOWER = [".l.",
          "lgl",
          ".l."]
BERRIES = ["Mb.",
           "bdMb",
           ".Mbd",
           ".bd."]


def stamp(g, tpl, x0, y0, darken=0):
    for j, row in enumerate(tpl):
        for i, ch in enumerate(row):
            if ch == ".":
                continue
            for _ in range(darken):
                ch = DARKER.get(ch, ch)
            put(g, x0 + i, y0 + j, ch)


def lobes(g, circles):
    """Busch aus überlappenden Blattwolken (hinten zuerst). Jede Wolke ist für sich
    von oben links beleuchtet; an Kanten zu dahinterliegenden Wolken entsteht eine
    dunkle Linie, damit die Wolken lesbar bleiben."""
    owner = {}
    for k, (cx, cy, r) in enumerate(circles):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + ((y - cy) * 1.15) ** 2 <= r * r + 1:
                    owner[(x, y)] = k
    for (x, y), k in owner.items():
        cx, cy, r = circles[k]
        d = ((x - cx) + (y - cy)) / r
        c = "I" if d < -0.45 else ("i" if d < 0.55 else "n")
        if d < -1.0:
            c = "l"
        # Kante zu einer Wolke dahinter -> Schattenlinie
        for nx, ny in ((x, y + 1), (x + 1, y)):
            if owner.get((nx, ny), k) < k:
                pass
        if owner.get((x, y - 1), k) < k and d > -0.6:
            c = "n"
        put(g, x, y, c)
    # Blattspitzen: einzelne helle Zacken an der Oberkante
    for (x, y), k in owner.items():
        if (x, y - 1) not in owner and (x + y) % 3 == 0:
            cx, cy, r = circles[k]
            if (x - cx) + (y - cy) < 0:
                put(g, x, y - 1, "I")


def berries(g, x, y):
    """Traube aus drei Beeren mit goldenem Kelch."""
    put(g, x + 1, y - 1, "g")
    for bx, by in ((x, y), (x + 2, y), (x + 1, y + 2)):
        put(g, bx, by, "M"); put(g, bx + 1, by, "b")
        put(g, bx, by + 1, "b"); put(g, bx + 1, by + 1, "d")


def stage_seed():
    g = grid([])
    for x, y, c in [(14, 35, "i"), (15, 35, "I"), (17, 34, "I"), (18, 34, "i"), (16, 36, "n"), (16, 37, "i")]:
        put(g, x, y, c)
    put(g, 15, 34, "M")
    outline(g, "a")
    return g


def stage_sprout():
    g = grid([])
    lobes(g, [(14, 33, 3), (18, 34, 3)])
    put(g, 16, 37, "n")
    outline(g, "a")
    return g


def stage_growing():
    g = grid([])
    lobes(g, [(11, 28, 4), (18, 27, 5), (9, 32, 4), (16, 32, 5), (22, 32, 4)])
    for x, y in [(9, 27), (18, 25), (21, 31), (13, 32)]:
        stamp(g, FLOWER, x, y)
    outline(g, "a")
    return g


def stage_ripe():
    g = grid([])
    lobes(g, [(10, 22, 5), (17, 19, 6), (24, 23, 5),
              (6, 28, 5), (15, 26, 6), (25, 29, 5),
              (11, 33, 5), (20, 33, 5)])
    for x, y in [(8, 24), (17, 21), (24, 26), (12, 30), (20, 30), (5, 31), (26, 32)]:
        berries(g, x, y)
    outline(g, "a")
    return g


def main(out, bed):
    fr = [to_image(f) for f in (stage_seed(), stage_sprout(), stage_growing(), stage_ripe())]
    sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, f in enumerate(fr):
        sheet.alpha_composite(f, (i * W, 0))
    sheet.save(f"{out}/nightshade_stages.png")
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
    c.save(f"{out}/zwischenstand_nightshade.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
