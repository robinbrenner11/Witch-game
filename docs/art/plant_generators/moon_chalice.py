"""Mondkelch (moon_chalice) – 4 Wachstumsstufen, Frames 32x48, handgepixelt.
Aufruf: python moon_chalice.py <ausgabeordner> <beet_tile.png>
Pflanzposition (Stielfuß): x 15/16, y 37.
"""
import sys
from PIL import Image
from pix import mirror, grid, put, outline, to_image, W, H, DARKER

RIPE_HEAD = [
    "................",
    "................",
    "...............M",
    "..............Ml",
    "..............lw",
    "..M..........llw",
    "..MM........lllw",
    "..MlM.......llcw",
    "...MlM......llgw",
    "...MllM....lllgw",
    "...MlllM...llgww",
    "....MlllMMlllgww",
    "....Illllllllwww",
    "....IIllllllwwww",
    ".....IIllllllwww",
    "......IIIllllllw",
    "........IIIIIIIg",
    "...........IIIIg",
    "...............g",
]

LEAVES = [
    "...m............",
    "...mmI..........",
    "...mIIIm........",
    "...iIIIIIm......",
    "...iIgIIIIm....g",
    "....iigIIIIm...g",
    ".....iigIIIIm..g",
    "......iiggIIIm.g",
    ".......iiggIIImg",
    "........iiiggIIg",
    "m.........iiiggg",
    "mmI.........iiig",
    ".mIIIm.........g",
    ".iIIIIIm.......g",
    ".iIgIIIIm......g",
    "..iigIIIIm.....g",
    "...iiggIIIIm...g",
    "....iiiggIIIIm.g",
    ".....iiiigggIIgg",
    ".......iiiiiiigg",
    "..........iiiii.",
]

GROWING_HEAD = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "...............M",
    "..............Mb",
    ".............Mbb",
    ".............mbb",
    "............mbbb",
    "............mbbb",
    "............Mbbb",
    "............mbbd",
    ".............mbd",
    "..............bd",
    "..............gd",
    "...............g",
    "...............g",
]

SPROUT = [
    *["................"] * 20,
    "................",
    "...............M",
    "..............Mb",
    "..............mb",
    "..............mb",
    "..............bd",
    "...............g",
    "...............g",
    "...............g",
    "........m......g",
    "........mmI....g",
    ".........iIIm..g",
    ".........iigIm.g",
    "..........iigImg",
    "...........iiigg",
    "...............g",
    "...............g",
    "................",
]

SEED = [
    *["................"] * 31,
    "..............aa",
    ".............mbb",
    "............mMbb",
    "............mbMb",
    "............mbbM",
    "............bbbb",
    ".............dbb",
    "..............dd",
]


def leaf_layer(part, dx=0, dy=0):
    """Blattpixel aus LEAVES (linke Hälfte, Stielspalte 15 ausgenommen).
    'lower' = unteres Blatt, 'upper' = oberes Blatt."""
    px = []
    for y, row in enumerate(LEAVES):
        for x, ch in enumerate(row[:15]):
            if ch == ".":
                continue
            lower = (y >= 10 and x <= 9) or y >= 12
            if (part == "lower") == lower:
                px.append((x + dx, y + dy, ch))
    return px


def compose(head, left, right):
    """Kopf (Blüte/Knospe) gespiegelt, Blätter links/rechts einzeln platziert,
    damit die Pflanze nicht spiegelsymmetrisch wirkt."""
    g = grid(mirror(head))
    for side, shifts in (("L", left), ("R", right)):
        for part, (dx, dy) in shifts.items():
            for x, y, ch in leaf_layer(part, dx, dy):
                if 0 <= x <= 14:
                    yy = len(head) + y
                    if side == "L":
                        put(g, x, yy, ch)
                    else:
                        put(g, 31 - x, yy, DARKER.get(ch, ch))
    for y in range(len(head) - 2, 39):     # Stiel: links Gold, rechts Bordeaux dunkel
        g[y][15] = "g"; g[y][16] = "d"
    return g


def frames():
    seed = grid(mirror(SEED))
    outline(seed, "a")
    sprout = grid(mirror(SPROUT))
    for y in range(26, 38):
        if sprout[y][16] == "g":
            sprout[y][16] = "d"
    outline(sprout, "a")

    # Stufe 3: Blätter kleiner (Richtung Stiel geschoben und abgeschnitten)
    growing = compose(GROWING_HEAD,
                      {"upper": (3, 2), "lower": (3, 0)},
                      {"upper": (4, 1), "lower": (2, 0)})
    outline(growing, "a")

    # Stufe 4: rechtes oberes Blatt steiler und höher, rechtes unteres kürzer
    ripe = compose(RIPE_HEAD,
                   {"upper": (0, 0), "lower": (0, 0)},
                   {"upper": (2, -2), "lower": (1, 0)})
    for y in range(2, 10):                  # Kelch neigt sich leicht zum Licht
        ripe[y] = ripe[y][1:] + ["."]
    outline(ripe, "a")
    sparks = [(5, 1, "M"), (29, 3, "M"), (1, 12, "l"), (30, 16, "M"), (24, 0, "w")]
    for cx, cy in [(27, 9), (4, 17)]:
        sparks += [(cx, cy, "w"), (cx - 1, cy, "l"), (cx + 1, cy, "l"), (cx, cy - 1, "l"), (cx, cy + 1, "l")]
    for x, y, ch in sparks:
        put(ripe, x, y, ch)
    return [seed, sprout, growing, ripe]

def main(out, bed):
    fr = [to_image(f) for f in frames()]
    sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, f in enumerate(fr):
        sheet.alpha_composite(f, (i * W, 0))
    sheet.save(f"{out}/moon_chalice_stages.png")
    bed_t = Image.open(bed).convert("RGBA")
    pv = Image.new("RGBA", (W * 4 + 3 * 8, H), (14, 10, 20, 255))
    for i in range(4):
        x0 = i * (W + 8)
        pv.alpha_composite(bed_t, (x0, 16))
        pv.alpha_composite(bed_t.crop((0, 16, 32, 32)), (x0, 0))
        pv.alpha_composite(fr[i], (x0, 0))
    pv.resize((pv.width * 4, pv.height * 4), Image.NEAREST).save(f"{out}/preview_moon_chalice_4x.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
