"""Inventar-Icons 16x16: je Pflanze ein Samentütchen und ein Ernte-Item.
Aufruf: python icons.py <ausgabeordner>
"""
import sys, os, math
from PIL import Image
import pix
from pix import put, outline, DARKER

pix.PAL.update({
    "q": (36, 74, 58), "Q": (98, 160, 110),                         # Grün dunkel/hell
    "e": (74, 43, 39), "h": (107, 63, 51), "H": (138, 82, 64),      # Haut (Alraune)
    "u": (52, 70, 120), "U": (120, 140, 185),                       # Nachtblau hell, Geisterblau
    "p": (200, 188, 168), "P": (150, 136, 118),                     # Papier Schatten
})
S = 16


def blank():
    # pix arbeitet auf 32x48; wir zeichnen oben links und schneiden 16x16 aus
    return [["."] * pix.W for _ in range(pix.H)]


def rows(g, lines, x0=0, y0=0):
    for j, r in enumerate(lines):
        for i, ch in enumerate(r):
            if ch != ".":
                put(g, x0 + i, y0 + j, ch)


def mirror8(left):
    """Linke Hälfte (8 Zeichen) spiegeln, rechte Seite abdunkeln (Licht oben links)."""
    out = []
    for r in left:
        r = r.ljust(8, ".")
        out.append(r + "".join(DARKER.get(c, c) if c != "g" else c for c in reversed(r)))
    return out


def img(g):
    im = pix.to_image(g).crop((0, 0, S, S))
    return im


# ---------------------------------------------------------------- Samentütchen
PACKET = [
    "................",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...PPPPPPPPPP...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...wwwwwwwwwp...",
    "...pppppppppP...",
    "................",
    "................",
]
# Emblem: dunkles Etikett (5x5) mit Goldrand – Motiv je Pflanze
EMBLEM = {
    "moon_chalice": ["l.l.l", "lllll", ".lwl.", "..g..", "..g.."],
    "lantern_berry": [".mmm.", "m...m", "....m", "...cc", "...cc"],
    "mandrake": [".GQG.", "..G..", ".hhh.", "hMhMh", ".hhh."],
    "nightshade": ["..Q..", ".g.g.", "Mb.Mb", "bd.bd", "..Mb."],
    "blood_rose": [".mbm.", "mbdbd", ".bdd.", "..q..", ".Qq.."],
    "ghost_fern": [".UUU.", "U...U", "U.w.U", ".U.UU", "...u."],
}


def seed_packet(name):
    g = blank()
    rows(g, PACKET)
    # Etikett: Goldrahmen 7x7 mit dunklem Feld
    for y in range(5, 12):
        for x in range(5, 12):
            edge = y in (5, 11) or x in (5, 11)
            put(g, x, y, "g" if edge else "k")
    for j, r in enumerate(EMBLEM[name]):
        for i, ch in enumerate(r):
            if ch != ".":
                put(g, 6 + i, 6 + j, ch)
    # Schnur am Knick
    put(g, 12, 3, "g"); put(g, 13, 4, "g"); put(g, 13, 5, "d")
    outline(g, "a")
    return img(g)


# ---------------------------------------------------------------- Ernte-Items
def item_moon_chalice():
    g = blank()
    rows(g, mirror8([
        "........",
        ".......M",
        "..M...Ml",
        "..MM..ll",
        "..MlM.lw",
        "...MlMlw",
        "...Mllww",
        "...IIllw",
        "....IIIl",
        "......Ig",
        ".......g",
        ".....QGg",
        "....qG.g",
        ".......g",
    ]))
    outline(g, "a")
    for x, y in [(1, 2), (14, 5)]:          # Funken
        put(g, x, y, "w")
    return img(g)


BERRY = [".ccc.", "cwccc", "ccccg", "cccgg", ".ggg."]
BERRY_S = [".cc.", "cwcg", ".gg."]


def item_lantern_berry():
    g = blank()
    arc = [(1, 7), (1, 6), (2, 5), (3, 4), (4, 3), (5, 2), (6, 2), (7, 1), (8, 1), (9, 1),
           (10, 2), (11, 2), (12, 3), (13, 4), (13, 5), (14, 6)]
    for x, y in arc:
        put(g, x, y, "m"); put(g, x, y + 1, "d")
    for x, y0, y1 in [(4, 5, 8), (11, 4, 9), (8, 3, 5)]:   # Fäden
        for y in range(y0, y1 + 1):
            put(g, x, y, "d")
    rows(g, BERRY, 2, 9)
    rows(g, BERRY, 9, 10)
    rows(g, BERRY_S, 7, 6)
    outline(g, "a")
    return img(g)


def item_mandrake():
    g = blank()
    rows(g, [
        "......Q..Q......",
        ".....QGQQGQ.....",
        "......GqqG......",
        ".......qq.......",
        ".....hhhhhh.....",
        "....hHHhhhhe....",
        "....hHkkhkke....",
        "....hkMMhkMe....",
        "....hhkMhhMe....",
        "....hhhhhhee....",
        "...e.hhhhee.e...",
        "....e.hhhe.e....",
        "......hhe.......",
        ".....he.he......",
        ".....e...e......",
    ])
    outline(g, "a")
    return img(g)


def item_nightshade():
    g = blank()
    rows(g, [
        "........QQ......",
        "......qQGGQ.....",
        ".....qqGGQ......",
        "......g..g......",
        ".....g....g.....",
        "....g...g..g....",
    ])
    b3 = ["Mbb", "bbd", "bdd"]
    for x, y in [(3, 6), (6, 7), (9, 6), (11, 9), (5, 10), (8, 11)]:
        rows(g, b3, x, y)
    outline(g, "a")
    return img(g)


def item_blood_rose():
    g = blank()
    rows(g, [
        "...mmmmm........",
        "..mbbbbbm.......",
        ".mbdddbbbd......",
        ".mbdMbdbbd......",
        ".mbbddbbdd......",
        "..dbbbbddd......",
        "...dddddd.......",
        "....QqqdQ.......",
        "......bd........",
        ".......bd.......",
        "...QG...bdg.....",
        "...qGG...bd.....",
        "....qq....bd....",
        "........g..bd...",
        "............bd..",
    ])
    outline(g, "a")
    return img(g)


def item_ghost_fern():
    g = blank()
    # Wedel diagonal von unten links nach oben rechts, Spitze eingerollt
    pts = [(3 + i * 0.75, 14 - i * 0.9) for i in range(12)]
    for k, (x, y) in enumerate(pts):
        if 1 <= k <= 9 and k % 2 == 1:
            ln = 3 if k < 5 else 2
            for j in range(1, ln + 1):
                put(g, round(x - j * 0.9), round(y - j * 0.45), "U")   # Lichtseite
                put(g, round(x + j * 0.9), round(y + j * 0.3), "u")
    for x, y in pts:
        put(g, round(x), round(y), "u")
    rows(g, [".UU.", "U..U", "Uw.U", ".uU."], 10, 1)
    outline(g, "a")
    put(g, 14, 6, "w"); put(g, 7, 2, "U")
    return img(g)


ITEMS = {
    "moon_chalice": item_moon_chalice, "lantern_berry": item_lantern_berry,
    "mandrake": item_mandrake, "nightshade": item_nightshade,
    "blood_rose": item_blood_rose, "ghost_fern": item_ghost_fern,
}


def main(out):
    os.makedirs(out, exist_ok=True)
    names = list(ITEMS)
    atlas = Image.new("RGBA", (S * len(names), S * 2), (0, 0, 0, 0))
    for i, n in enumerate(names):
        s = seed_packet(n); it = ITEMS[n]()
        s.save(os.path.join(out, f"seed_{n}.png"))
        it.save(os.path.join(out, f"crop_{n}.png"))
        atlas.alpha_composite(s, (i * S, 0)); atlas.alpha_composite(it, (i * S, S))
    atlas.save(os.path.join(out, "items_plants_atlas.png"))
    # Vorschau auf Inventar-Slots (4x)
    slot = 22
    pv = Image.new("RGBA", (len(names) * (slot + 4) + 4, 2 * (slot + 4) + 4), (14, 10, 20, 255))
    for r in range(2):
        for i in range(len(names)):
            x0, y0 = 4 + i * (slot + 4), 4 + r * (slot + 4)
            for y in range(slot):
                for x in range(slot):
                    edge = x in (0, slot - 1) or y in (0, slot - 1)
                    pv.putpixel((x0 + x, y0 + y), (217, 164, 65, 255) if edge else (43, 22, 51, 255))
            pv.alpha_composite(atlas.crop((i * S, r * S, (i + 1) * S, (r + 1) * S)), (x0 + 3, y0 + 3))
    pv.resize((pv.width * 4, pv.height * 4), Image.NEAREST).save(os.path.join(out, "vorschau_items_4x.png"))


if __name__ == "__main__":
    main(sys.argv[1])
