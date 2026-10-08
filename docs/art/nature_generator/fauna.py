"""Ambient-Fauna (Bitterbloom): Motte, Fledermaus, Eule, Kröte.

Aufruf (aus dem Projektordner):
    python docs/art/nature_generator/fauna.py

Die Tiere sind so klein, dass jedes Pixel zählt; deshalb sind sie hier als
Zeichenraster von Hand gesetzt statt prozedural erzeugt. Zeichen -> Farbschlüssel
steht je Tier in der cmap. '.' = durchsichtig.
Ausgabe: assets/environment/fauna/  (Animationsfolgen siehe ASSETS.md)
"""
from nature import Layer, save, ROOT
from PIL import Image

FAUNA = "assets/environment/fauna"


def draw(rows, cmap, w, h, ox=0, oy=0, layer=None):
    t = layer or Layer(w, h)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                t.set(ox + x, oy + y, cmap[ch])
    return t


# ---------------------------------------------------------------------------
# Motte 8x8, 4 Frames Flügelschlag (Loop, ca. 12 FPS). Ohne Kontur, wie die
# Glühwürmchen: so klein, dass eine Kontur sie nur dunkel macht.
MOTH = [
    ["w.....v", "ww...vv", "wwwbvvv", ".wwbvv.", "..wbv..", "...b..."],       # offen
    [".w...v.", ".ww.vv.", "..wbv..", "..wbv..", "...b...", "......."],       # halb
    ["...w...", "..wbv..", "..wbv..", "...b...", ".......", "......."],       # zu
    [".w...v.", ".ww.vv.", "..wbv..", "..wbv..", "...b...", "......."],       # halb
]


def moth(light="LS", shade="LST"):
    cmap = {"w": light, "v": shade, "b": "E2"}
    return [draw(r, cmap, 8, 8, 0, 1).image() for r in MOTH]


# ---------------------------------------------------------------------------
# Fledermaus 16x12, 4 Frames Flügelschlag (Loop, ca. 10 FPS), Vorderansicht.
BAT = [
    [  # Flügel oben
        "#..............#",
        "##............##",
        ".##...a..a...##.",
        ".###..aaaa..###.",
        "..####aeea####..",
        "...###BBBB###...",
        "......BBBB......",
        ".......BB.......",
    ],
    [  # Mitte
        "................",
        "................",
        "......a..a......",
        "#.....aaaa.....#",
        "##...#aeea#...##",
        ".#####BBBB#####.",
        "......BBBB......",
        ".......BB.......",
    ],
    [  # Flügel unten
        "................",
        "................",
        "......a..a......",
        "......aaaa......",
        "..####aeea####..",
        ".#####BBBB#####.",
        "##..##BBBB##..##",
        "#......BB......#",
    ],
    [  # Mitte
        "................",
        "................",
        "......a..a......",
        "#.....aaaa.....#",
        "##...#aeea#...##",
        ".#####BBBB#####.",
        "......BBBB......",
        ".......BB.......",
    ],
]


def bat():
    """Mit feiner Mondlicht-Kante oben auf den Flügeln, damit die Silhouette
    nachts lesbar bleibt (sonst verschwindet sie komplett im Dunkeln)."""
    cmap = {"#": "NV", "a": "E2", "e": "GOLD", "B": "E1"}
    frames = []
    for r in BAT:
        t = draw(r, cmap, 16, 12, 0, 2)
        rim = [(x, y) for y in range(12) for x in range(16)
               if t.get(x, y) == "NV" and t.get(x, y - 1) is None]
        for i, (x, y) in enumerate(rim):
            if i % 2 == 0:
                t.set(x, y, "NBH")                           # nur jede zweite: dezent
        t.set(6, 3, "E3") if t.get(6, 3) else None             # Ohrspitzen
        frames.append(t.outline().image())
    return frames


# ---------------------------------------------------------------------------
# Eule 16x18 sitzend; Fußpunkt = Krallen unten Mitte (auf den Ast setzen).
# Frames: 0 ruhig, 1 Blinzeln, 2 Kopf nach links, 3 Kopf nach rechts.
OWL_BODY = [
    ".wwbbcbbbbcbbww.",
    "wWbbcbbbbbbcbwww",
    "wWbcbbcbbcbbcbww",
    "wWbbbcbbbbcbbbww",
    ".WbcbbbbbbbbcbW.",
    ".wWbbbcbbcbbbww.",
    "..wWWbbbbbbwww..",
    "...wwwwwwwwww...",
    "....g.gg.gg.g...",
]


def owl_head(shift=0, closed=False):
    eye = ["FF", "FF"] if closed else ["YP", "YY"]
    if closed:
        e1, e2 = "hhhh", "FFFF"
    rows = [
        "..t........t..",
        "..tt......tt..",
        "..hhhhhhhhhh..",
        ".hhFFFhhFFFhh.",
    ]
    if closed:
        rows += [".hFhhhFFhhhFh.", ".hFFFFFFFFFFh."]
    else:
        rows += [".hFYYPFFYYPFh.", ".hFYYYFFYYYFh."]
    rows += [".hhFFFkkFFFhh.", "..hhhhhkhhhh.."]
    if shift:
        out = []
        for r in rows:
            core = r[1:-1]
            core = core[1:] + "." if shift < 0 else "." + core[:-1]
            out.append(r[0] + core + r[-1])
        rows = out
    return rows


def owl():
    cmap = {"t": "E3", "h": "E3", "F": "LS", "Y": "GOLDH", "P": "TS", "k": "GOLDD",
            "w": "E2", "W": "E3", "b": "E4", "c": "LST", "g": "GOLDD"}
    frames = []
    for shift, closed in ((0, False), (0, True), (-1, False), (1, False)):
        t = Layer(16, 18)
        draw(OWL_BODY, cmap, 16, 18, 0, 9, t)
        draw(owl_head(shift, closed), cmap, 16, 18, 1, 0, t)
        frames.append(t.outline().image())
    # Frame 4: Gefieder aufplustern (Körper 1 px breiter, Kopf 1 px tiefer)
    t = Layer(16, 18)
    puffed = ["w" + r[1:-1].replace(".", "w", 1)[::-1].replace(".", "w", 1)[::-1] + "w" for r in OWL_BODY[:-1]]
    draw(puffed + [OWL_BODY[-1]], cmap, 16, 18, 0, 9, t)
    draw(owl_head(0, True), cmap, 16, 18, 1, 1, t)
    frames.append(t.outline().image())
    return frames


def owl_fly():
    """Abflug/Flug 32x20, 4 Frames (8 FPS): 0 Absprung (Flügel waagerecht),
    dann 1 oben - 2 Mitte - 3 unten im Loop. Flügel als breite Flächen mit
    gespreizten Schwungfedern an der Spitze."""
    import math
    cmap = {"t": "E3", "h": "E3", "F": "LS", "Y": "GOLDH", "P": "TS", "k": "GOLDD",
            "w": "E2", "b": "E4", "c": "LST", "g": "GOLDD"}
    body = ["..t......t..", "..hhhhhhhh..", ".hFYPFFYPFh.", ".hFYYkkYYFh.", ".hhhhkkhhhh.",
            ".wbbcbbcbbw.", ".wbcbbbbcbw.", "..wbbbbbbw..", "...wwwwww...", "...g.gg.g..."]
    frames = []
    for ang in (8, 48, 10, -34):
        t = Layer(32, 20)
        for side in (-1, 1):
            a = math.radians(ang)
            dx, dy = side * math.cos(a), -math.sin(a)
            nx, ny = -dy * side, dx * side                    # Normale, zeigt nach unten/hinten
            if ny < 0:
                nx, ny = -nx, -ny
            sx, sy = 16 + side * 4, 10
            for k in range(15):
                cx, cy = sx + dx * k, sy + dy * k
                w = 5.2 * (1 - k / 19) + 1.0                  # breite Flügelfläche
                feather = k >= 10
                for o in range(0, int(w * 3) + 1):
                    off = o / 3
                    if feather and int(off) % 2 == 1 and off > 0.9:
                        continue                              # Lücken zwischen den Schwungfedern
                    px, py = cx + nx * off, cy + ny * off
                    t.set(px, py, "E3" if off < 1 else ("E2" if off < w - 0.6 else "E1"))
        draw(body, cmap, 32, 20, 10, 9, t)
        frames.append(t.outline().image())
    return frames


# ---------------------------------------------------------------------------
# Kröte 16x16; Fußpunkt unten Mitte. Ein kleiner Schatten bleibt beim Hüpfen
# am Boden. Frames: 0 sitzen, 1 atmen, 2 quaken (Kehlblase), 3 ducken,
# 4 Absprung, 5 Luft hoch, 6 Luft sinkend, 7 Landung.
TOAD_SIT = [
    "...oo....oo...",
    "..oYPo..oYPo..",
    "..oooommoooo..",
    ".mHHmmmmmmmmm.",
    "mHwHmmmmmwmmmd",
    "mmmmmwmmmmmmdd",
    ".mmMbbbbbbMmd.",
    "ffmmbbbbbbmmff",
    "ff.mmmmmmmm.ff",
]
TOAD_BREATHE = TOAD_SIT[:6] + [
    ".mmMbbbbbbMmd.",
    "ffmbbbbbbbbmff",
    "ff.mmbbbbmm.ff",
]
TOAD_CROAK = TOAD_SIT[:6] + [
    ".mmMLLLLLLMmd.",
    "ffmLLLLLLLLmff",
    "ff.LLLLLLLL.ff",
    "....LLLLLL....",
]
TOAD_CROUCH = [
    "...oo....oo...",
    "..oYPo..oYPo..",
    ".moooommoooom.",
    "mHwHmmmmmwmmmd",
    "mmmmmwmmmmmmdd",
    ".mmMbbbbbbMmd.",
    "fffmmmmmmmmfff",
]
TOAD_TAKEOFF = [                 # Absprung: gestreckt, Hinterbeine noch am Boden
    "...oo....oo...",
    "..oYPo..oYPo..",
    "..oooommoooo..",
    ".mHHmmmmmmmmm.",
    "mHwHmmmmmwmmmd",
    "mmmmmwmmmmmmdd",
    ".mmMbbbbbbMmd.",
    "..mmmmmmmmmm..",
    ".ff........ff.",
    "ff..........ff",
]
TOAD_LAND = [                    # Landung: breit gestaucht
    "...oo....oo...",
    ".moYPo..oYPom.",
    "mmoooommoooomm",
    "mHwHmmmmmwmmmd",
    ".mmMbbbbbbMmd.",
    "fffmmmmmmmmfff",
]
TOAD_AIR = [
    "...oo....oo...",
    "..oYPo..oYPo..",
    "..oooommoooo..",
    ".mHHmmmmmmmmm.",
    "mHwHmmmmmwmmmd",
    ".mmMbbbbbbMmd.",
    "..ffmmmmmmff..",
    ".ff........ff.",
]


def toad():
    cmap = {"o": "GD", "Y": "GOLD", "P": "TS", "m": "GD", "H": "L3", "w": "WO", "d": "L1",
            "M": "L0", "b": "WO", "f": "L1", "L": "LS"}
    shadow = ["..ssssssssss..", ".ssssssssssss."]
    specs = [(TOAD_SIT, 6, False), (TOAD_BREATHE, 6, False), (TOAD_CROAK, 5, False),
             (TOAD_CROUCH, 8, False), (TOAD_TAKEOFF, 5, False), (TOAD_AIR, 1, True),
             (TOAD_AIR, 4, True), (TOAD_LAND, 9, False)]
    frames = []
    for rows, oy, airborne in specs:
        t = Layer(16, 16)
        draw(rows, cmap, 16, 16, 1, oy, t)
        t.outline()
        if airborne:                               # Schatten bleibt am Boden
            draw(shadow, {"s": "NV"}, 16, 16, 1, 14, t)
        frames.append(t.image())
    return frames


def main():
    save(FAUNA, "moth", moth(), foot=False)
    save(FAUNA, "moth_dark", moth("LST", "E4"), foot=False)
    save(FAUNA, "bat", bat(), foot=False)
    save(FAUNA, "owl", owl(), glow=("GOLDH",))
    save(FAUNA, "owl_fly", owl_fly(), foot=False, glow=("GOLDH",))
    save(FAUNA, "toad", toad())




# ---------------------------------------------------------------------------
def preview():
    """Kleine Nachtszene (320x180, 3x) mit allen Tieren: Eule auf dem toten Baum,
    Motten am Glutpilz, Kröte im Gras, Fledermaus fliegt durch."""
    import math
    import preview as P
    import compare as C
    G = ROOT / "assets/environment/ground"
    W, H = 10, 6
    grass = C.blob_corners(W, H, [(2.5, 4.5, 2.6, 1.6)])
    ground = C.build_ground(G, W, H, "forest_floor", grass,
                            base_set="transition_meadow_forest_floor.png").crop((0, 0, 320, 180))
    objs = [("tree_dead", 230, 170), ("mushroom_ember", 150, 150), ("mushroom_moon", 270, 120),
            ("tree_fir", 30, 150), ("bush_1", 300, 178), ("fern_1", 120, 170), ("wild_grass_2", 60, 176)]
    flies = [(90, 90), (200, 60)]
    fa = ROOT / FAUNA
    sheets = {n: Image.open(fa / f"{n}.png").convert("RGBA") for n in
              ("moth", "moth_dark", "bat", "owl", "owl_glow", "toad")}

    def fr(name, w, i):
        im = sheets[name]
        i %= im.width // w
        return im.crop((i * w, 0, i * w + w, im.height))

    def lit(im, k):
        im = im.copy()
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a:
                    px[x, y] = (min(255, int(r * k[0])), min(255, int(g * k[1])), min(255, int(b * k[2])), a)
        return im

    N = P.NIGHT
    owl_seq = [0] * 10 + [1, 0] + [0] * 6 + [2] * 6 + [0] * 4 + [3] * 6 + [0] * 4 + [1, 0]
    toad_seq = [0, 0, 1, 1] * 3 + [0, 2, 2, 2, 0] + [0, 1, 1, 0] + [3, 4, 5, 6, 7] + [0] * 4
    frames = []
    n = 48
    for k in range(n):
        t = k / 10
        img = P.render(ground, objs, t, True, flies)
        # Eule auf dem Ast des toten Baums: Fußpunkt Baum (230,170) + (18, -69)
        o = fr("owl", 16, owl_seq[k % len(owl_seq)])
        ox, oy = 230 + 18 - 8, 170 - 69 - 18
        img.alpha_composite(lit(o, N), (ox, oy))
        img.alpha_composite(fr("owl_glow", 16, owl_seq[k % len(owl_seq)]), (ox, oy))
        # Kröte im Gras: hüpft einmal ein Stück nach rechts
        ts = toad_seq[k % len(toad_seq)]
        hop = sum(3 for j in range(k % len(toad_seq)) if toad_seq[j] in (4, 5, 6))
        img.alpha_composite(lit(fr("toad", 16, ts), N), (70 + hop - 8, 160 - 15))
        # Motten kreisen um den Glutpilz (warm angeleuchtet)
        warm = (N[0] + 0.7, N[1] + 0.5, N[2] + 0.25)
        for j, name in enumerate(("moth", "moth_dark", "moth")):
            a = t * (2.4 + j * 0.5) + j * 2.1
            mx = 150 + math.cos(a) * (9 + j * 4)
            my = 138 + math.sin(a * 1.3) * (6 + j * 2) - j * 3
            img.alpha_composite(lit(fr(name, 8, k + j), warm), (int(mx) - 4, int(my) - 4))
        # Fledermaus quert das Bild
        bx = -20 + (k * 9) % 380
        by = 40 + math.sin(k * 0.6) * 6
        img.alpha_composite(lit(fr("bat", 16, k), N), (int(bx), int(by)))
        frames.append(img.resize((960, 540), Image.NEAREST).convert("RGB"))
    out = ROOT / "docs/art/vorschau/vorschau_fauna_nacht_3x.gif"
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=100, loop=0)
    print("  Vorschau: vorschau_fauna_nacht_3x.gif")


if __name__ == "__main__":
    main()
    preview()
