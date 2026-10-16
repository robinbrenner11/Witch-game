"""Platzhalter-Atlanten für Klippen (Fels) und Stützmauern, 32x32 pro Feld.

Beide Atlanten haben dasselbe Raster (siehe LAYOUT unten und
assets/environment/cliffs/cliff_layout.json). Robin übermalt die Felder später
in Aseprite und speichert unter demselben Namen; das Spiel zeigt dann sofort
die neue Grafik, weil der World-Builder nur Feld-Koordinaten kennt.

Licht von oben links: Oberkante hell, rechte Kanten dunkler, Fuß mit Schatten.
Aufruf: python docs/art/cliff_generator/cliffs.py assets/environment/cliffs
"""
import json
import os
import random
import sys

from PIL import Image

T = 32

# Feldname -> (Spalte, Zeile, Kollision). Kollision: full, rim_n, rim_e, rim_w,
# rim_ne, rim_nw, in_ne, in_nw, stair_l, stair_r, none.
LAYOUT = {}
ENDS = ["left_outer", "middle", "right_outer", "left_inner", "right_inner", "solo"]
for row, kind in enumerate(["top", "mid", "bottom", "single"]):
    for col, end in enumerate(ENDS):
        LAYOUT[f"face_{kind}_{end}"] = (col, row, "full")
for col, (name, coll) in enumerate([("rim_n", "rim_n"), ("rim_e", "rim_e"), ("rim_w", "rim_w"),
                                    ("rim_ne", "rim_ne"), ("rim_nw", "rim_nw"),
                                    ("rim_inner_ne", "in_ne"), ("rim_inner_nw", "in_nw")]):
    LAYOUT[name] = (col, 4, coll)
for col, end in enumerate(["left", "middle", "right", "solo"]):
    LAYOUT[f"shadow_{end}"] = (col, 5, "none")
# Abdunklung tieferer Flächen: 1 bzw. 2 Stufen unter der höchsten im Ort.
LAYOUT["depth_1"] = (4, 5, "none")
LAYOUT["depth_2"] = (5, 5, "none")
for i, kind in enumerate(["top", "mid", "bottom", "single"]):
    for j, side in enumerate(["left", "middle", "right"]):
        col = (i % 2) * 3 + j
        row = 6 + i // 2
        coll = {"left": "stair_l", "middle": "none", "right": "stair_r"}[side]
        LAYOUT[f"stair_{kind}_{side}"] = (col, row, coll)

COLS, ROWS = 8, 8

OUTLINE = (43, 22, 51)
SHADOW = (20, 10, 30, 140)
DEPTH = {"depth_1": (14, 16, 40, 60), "depth_2": (14, 16, 40, 115)}

MATERIALS = {
    "rock": {
        "dark": (44, 34, 58), "base": (64, 53, 80), "light": (90, 78, 104),
        "lip": (132, 118, 130), "lip2": (104, 92, 112), "foot": (30, 22, 40),
        "tread": (100, 88, 106), "riser": (40, 30, 52),
    },
    "wall": {
        "dark": (52, 38, 58), "base": (78, 61, 82), "light": (104, 88, 104),
        "lip": (160, 144, 140), "lip2": (128, 112, 118), "foot": (32, 22, 40),
        "tread": (118, 102, 112), "riser": (46, 32, 54),
    },
}


def body_pattern(mat, kind, seed):
    """32x32 Fels- oder Mauerfläche, kachelbar in x und y."""
    m = MATERIALS[mat]
    px = [[m["base"]] * T for _ in range(T)]
    rng = random.Random(seed)
    if mat == "rock":
        # Brocken: jede Zelle gehört zum nächsten Saatpunkt (über die
        # Kachelränder hinweg gerechnet, damit Nachbarkacheln nahtlos passen).
        # Oben links im Brocken hell, unten rechts dunkel, Fugen fast schwarz.
        seeds = [(rng.uniform(0, T), rng.uniform(0, T)) for _ in range(6)]
        for y in range(T):
            for x in range(T):
                dists = []
                for sx, sy in seeds:
                    dx = min(abs(x - sx), T - abs(x - sx))
                    dy = min(abs(y - sy), T - abs(y - sy)) * 1.25
                    sgn_x = (x - sx + T / 2) % T - T / 2
                    sgn_y = (y - sy + T / 2) % T - T / 2
                    dists.append(((dx * dx + dy * dy) ** 0.5, sgn_x, sgn_y))
                dists.sort(key=lambda d: d[0])
                (d0, ox, oy), d1 = dists[0], dists[1][0]
                if d1 - d0 < 1.3:
                    px[y][x] = OUTLINE
                elif ox + oy < -5:
                    px[y][x] = m["light"]
                elif ox + oy > 5:
                    px[y][x] = m["dark"]
        for _ in range(10):
            x, y = rng.randrange(T), rng.randrange(T)
            if px[y][x] == m["base"]:
                px[y][x] = m["light"]
    else:
        # Mauersteine: Lagen von 8 px, Fugen versetzt, Licht oben links am Stein
        for y in range(T):
            course = y // 8
            off = 8 if course % 2 else 0
            for x in range(T):
                if y % 8 == 7:
                    px[y][x] = OUTLINE
                elif (x + off) % 16 == 15:
                    px[y][x] = OUTLINE
                elif y % 8 == 0 or (x + off) % 16 == 0:
                    px[y][x] = m["light"]
                elif (x + off) % 16 == 14 or y % 8 == 6:
                    px[y][x] = m["dark"]
    return px


def face_tile(mat, kind, end):
    m = MATERIALS[mat]
    px = body_pattern(mat, kind, 7)
    if kind in ("top", "single"):
        jag = [0, 1, 1, 0, 0, 1, 2, 1, 0, 0, 0, 1, 1, 0, 1, 2, 2, 1, 0, 0, 1, 0, 0, 1, 1, 2, 1, 0, 0, 1, 0, 0]
        for x in range(T):
            px[0][x] = m["lip"]
            px[1][x] = m["lip"]
            px[2][x] = m["lip2"]
            px[3][x] = OUTLINE if mat == "rock" else m["lip2"]
            if mat == "rock":
                # Kante bricht unregelmäßig ab, darunter liegt Schatten
                for y in range(3, 4 + jag[x]):
                    px[y][x] = m["lip2"]
                px[4 + jag[x]][x] = OUTLINE
                px[5 + jag[x]][x] = m["dark"]
            if mat == "wall":
                px[4][x] = m["lip2"] if x % 8 else OUTLINE
                px[5][x] = OUTLINE
    if kind in ("bottom", "single"):
        for y in range(T - 4, T):
            for x in range(T):
                if y >= T - 2 or (x * 7 + y * 3) % 5 == 0:
                    px[y][x] = m["foot"]
        for x in range(T):
            px[T - 1][x] = OUTLINE
    left = end in ("left_outer", "solo")
    right = end in ("right_outer", "solo")
    for y in range(T):
        if left:
            px[y][0] = OUTLINE
            px[y][1] = OUTLINE
            px[y][2] = m["lip2"] if kind in ("top", "single") and y < 4 else m["light"]
        if right:
            px[y][T - 1] = OUTLINE
            px[y][T - 2] = OUTLINE
            px[y][T - 3] = m["dark"]
            px[y][T - 4] = m["dark"]
        if end == "left_inner":
            for x in range(4):
                px[y][x] = m["foot"] if x < 2 else m["dark"]
        if end == "right_inner":
            px[y][T - 1] = OUTLINE
    return px


def empty():
    return [[None] * T for _ in range(T)]


def rim_tile(mat, name):
    m = MATERIALS[mat]
    px = empty()

    def north():
        for x in range(T):
            px[0][x] = OUTLINE
            px[1][x] = OUTLINE
            px[2][x] = m["lip"]
            px[3][x] = m["lip2"]

    def west():
        for y in range(T):
            px[y][0] = OUTLINE
            px[y][1] = OUTLINE
            px[y][2] = m["lip"]
            px[y][3] = m["lip2"]

    def east():
        for y in range(T):
            px[y][T - 1] = OUTLINE
            px[y][T - 2] = OUTLINE
            px[y][T - 3] = m["dark"]

    if name == "rim_n":
        north()
    elif name == "rim_e":
        east()
    elif name == "rim_w":
        west()
    elif name == "rim_ne":
        east()
        north()
    elif name == "rim_nw":
        west()
        north()
    elif name == "rim_inner_ne":
        for y in range(4):
            for x in range(T - 4, T):
                px[y][x] = OUTLINE if (x >= T - 2 or y < 2) else m["dark"]
    elif name == "rim_inner_nw":
        for y in range(4):
            for x in range(4):
                px[y][x] = OUTLINE if (x < 2 or y < 2) else m["lip"]
    return px


def shadow_tile(end):
    px = empty()
    x0 = 3 if end in ("left", "solo") else 0
    x1 = T - 3 if end in ("right", "solo") else T
    for y in range(8):
        for x in range(x0, x1):
            px[y][x] = SHADOW
    for x in range(x0, x1):
        if x % 2 == 0:
            px[8][x] = SHADOW
    return px


def stair_tile(mat, kind, side):
    m = MATERIALS[mat]
    px = [[m["tread"]] * T for _ in range(T)]
    for y in range(T):
        step = y % 8
        for x in range(T):
            if step < 2:
                px[y][x] = m["lip2"]
            elif step >= 6:
                px[y][x] = m["riser"]
    if kind in ("top", "single"):
        for x in range(T):
            px[0][x] = m["lip"]
            px[1][x] = m["lip"]
    if kind in ("bottom", "single"):
        for y in range(T - 3, T):
            for x in range(T):
                px[y][x] = m["tread"]
        for x in range(T):
            px[T - 1][x] = m["riser"]
    for y in range(T):
        if side == "left":
            for x in range(5):
                px[y][x] = OUTLINE if x < 2 else m["base"] if x < 4 else m["light"]
        if side == "right":
            for x in range(T - 5, T):
                px[y][x] = OUTLINE if x >= T - 2 else m["dark"]
    return px


def build(mat):
    img = Image.new("RGBA", (COLS * T, ROWS * T), (0, 0, 0, 0))
    for name, (col, row, _coll) in LAYOUT.items():
        if name.startswith("face_"):
            _, kind, end = name.split("_", 2)
            px = face_tile(mat, kind, end)
        elif name.startswith("rim_"):
            px = rim_tile(mat, name)
        elif name.startswith("depth_"):
            px = [[DEPTH[name]] * T for _ in range(T)]
        elif name.startswith("shadow_"):
            px = shadow_tile(name.split("_", 1)[1])
        else:
            _, kind, side = name.split("_", 2)
            px = stair_tile(mat, kind, side)
        for y in range(T):
            for x in range(T):
                c = px[y][x]
                if c is None:
                    continue
                img.putpixel((col * T + x, row * T + y), c if len(c) == 4 else c + (255,))
    return img


def guide(out_path):
    """Vorlage zum Übermalen: Atlas 4x vergrößert mit Raster und Feldnamen."""
    from PIL import ImageDraw
    s = 4
    atlas = build("rock").resize((COLS * T * s, ROWS * T * s), Image.NEAREST)
    img = Image.new("RGBA", atlas.size, (234, 223, 203, 255))
    img.alpha_composite(atlas)
    d = ImageDraw.Draw(img)
    for name, (col, row, coll) in LAYOUT.items():
        x, y = col * T * s, row * T * s
        d.rectangle([x, y, x + T * s - 1, y + T * s - 1], outline=(217, 164, 65, 255))
        label = name.replace("face_", "").replace("stair_", "st_").replace("rim_inner_", "in_")
        d.rectangle([x + 2, y + 2, x + 6 * len(label) + 4, y + 13], fill=(14, 10, 20, 200))
        d.text((x + 4, y + 2), label, fill=(234, 223, 203, 255))
        if coll != "none":
            d.text((x + 4, y + T * s - 13), coll, fill=(194, 48, 122, 255))
    img.save(out_path)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/environment/cliffs"
    os.makedirs(out, exist_ok=True)
    for mat in MATERIALS:
        build(mat).save(os.path.join(out, f"cliff_{mat}.png"))
    layout = {
        "tile_size": T,
        "columns": COLS,
        "rows": ROWS,
        "materials": {"rock": "cliff_rock.png", "wall": "cliff_wall.png"},
        "tiles": {name: {"col": c, "row": r, "collision": coll} for name, (c, r, coll) in LAYOUT.items()},
    }
    with open(os.path.join(out, "cliff_layout.json"), "w", encoding="utf-8") as f:
        json.dump(layout, f, indent=1)
    guide(os.path.join(os.path.dirname(os.path.abspath(__file__)), "vorlage_raster.png"))
    print(f"{len(LAYOUT)} Felder je Material nach {out}, Vorlage: docs/art/cliff_generator/vorlage_raster.png")


if __name__ == "__main__":
    main()
