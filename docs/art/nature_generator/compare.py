"""Vergleichs-Mockup: jetziges Gras vs. Vorschlag (Erde/Waldboden + Grasinseln + Wildgras).

Aufruf (aus dem Projektordner):
    python docs/art/ground_generator/calm.py assets/environment/ground
    python docs/art/nature_generator/compare.py assets/environment/ground

Gleiche Objekte, gleiche Positionen – nur der Boden und das Gras ändern sich.
Ausgabe: docs/art/vorschau/vergleich_garten_2x.png, vergleich_wald_2x.png,
         vorschlag_nacht_2x.png, vorschlag_garten_2x.gif
"""
import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import preview as P
from nature import ROOT, _hash

FONT = ImageFont.truetype(str(ROOT / "assets/ui/fonts/m5x7.ttf"), 32)
for n in ("wild_grass_1", "wild_grass_2", "wild_grass_3"):
    P.FRAME_W[n] = 32
    P.FPS[n] = 4


def tile(path):
    return Image.open(path).convert("RGBA")


def atlas_tile(atlas, idx):
    r, c = divmod(idx, 4)
    return atlas.crop((c * 32, r * 32, c * 32 + 32, r * 32 + 32))


def build_ground(G, W, H, base, grass_c, path_c=None, base_set=None, path_set=None):
    """Boden aus Eck-Rastern. grass_c/path_c[y][x] = True, wenn die Ecke Gras/Weg ist.
    Eine Kachel nutzt immer nur EIN Übergangsset (zwei Materialien pro Ecke)."""
    img = Image.new("RGBA", (W * 32, H * 32))
    g_atlas = tile(G / "transitions" / base_set)
    p_atlas = tile(G / "transitions" / path_set) if path_set else None
    for ty in range(H):
        for tx in range(W):
            cs = [(tx, ty), (tx + 1, ty), (tx, ty + 1), (tx + 1, ty + 1)]
            if path_c and any(path_c[y][x] for x, y in cs):
                bits = [not path_c[y][x] for x, y in cs]       # oberes Material = Waldboden
                idx = bits[0] * 1 + bits[1] * 2 + bits[2] * 4 + bits[3] * 8
                im = atlas_tile(p_atlas, idx)
            elif any(grass_c[y][x] for x, y in cs):
                bits = [grass_c[y][x] for x, y in cs]
                idx = bits[0] * 1 + bits[1] * 2 + bits[2] * 4 + bits[3] * 8
                if idx == 15:
                    im = tile(G / f"ground_meadow_{1 + (tx * 7 + ty * 3) % 3}.png")
                else:
                    im = atlas_tile(g_atlas, idx)
            else:
                v = (tx * 7 + ty * 3) % 11
                k = 4 if v == 0 else (5 if v == 5 else 1 + (tx * 5 + ty * 2) % 3)
                im = tile(G / f"ground_{base}_{k}.png")
            img.alpha_composite(im, (tx * 32, ty * 32))
    return img


def blob_corners(W, H, blobs):
    """Grasinseln als Ellipsen auf dem Eckraster: (cx, cy, rx, ry) in Kachel-Einheiten."""
    c = [[False] * (W + 1) for _ in range(H + 1)]
    for y in range(H + 1):
        for x in range(W + 1):
            for cx, cy, rx, ry in blobs:
                wob = 0.25 * math.sin(x * 1.7 + y * 0.9)
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1 + wob:
                    c[y][x] = True
    return c


# ---------------------------------------------------------------------------
def garden_B(G):
    W, H = P.VW // 32, P.VH // 32 + 1
    grass = blob_corners(W, H, [(1.5, 1.5, 3.5, 2.5), (19, 1.5, 3, 2.5), (1, 10, 2.5, 3),
                                (19.5, 10.5, 3, 2.5), (4.5, 6, 1.2, 1.6), (16.5, 6.5, 1.3, 1.5),
                                (10, 1, 2.5, 1.2)])
    for y in range(4, 10):                      # Beetbereich bleibt frei
        for x in range(5, 16):
            grass[y][x] = False
    ground = build_ground(G, W, H, "earth", grass, base_set="transition_meadow_earth.png")
    for row, ty in ((0, 5), (1, 7)):
        for i, tx in enumerate(range(6, 14)):
            name = ("ground_bed_cap_left_wet" if i == 0 else
                    "ground_bed_cap_right_wet" if tx == 13 else f"ground_bed_{4 + (i % 3)}")
            ground.alpha_composite(tile(P.GROUND / f"{name}.png"), (tx * 32, ty * 32))
    ground = ground.crop((0, 0, P.VW, P.VH))
    _, objs, flies = P.garden_scene()
    objs = [o for o in objs if not o[0].startswith("grass_tuft")]
    objs += [("wild_grass_1", 120, 108), ("wild_grass_2", 218, 108), ("wild_grass_3", 560, 108),
             ("wild_grass_2", 70, 200), ("wild_grass_1", 135, 240), ("wild_grass_3", 590, 220),
             ("wild_grass_1", 500, 250), ("wild_grass_2", 150, 330), ("wild_grass_1", 420, 330),
             ("weed_thistle", 200, 290), ("weed_dock", 470, 220), ("weed_dock", 240, 200),
             ("wild_grass_3", 330, 60), ("wild_grass_1", 610, 60)]
    return ground, objs, flies


def forest_B(G):
    W, H = P.VW // 32, P.VH // 32 + 1
    path = [[False] * (W + 1) for _ in range(H + 1)]
    for y in range(H + 1):
        cx = int(9 + 3 * math.sin(y * 0.5))
        for x in (cx, cx + 1, cx + 2):
            path[y][x] = True
    grass = blob_corners(W, H, [(16, 7.5, 2.6, 1.9), (3.5, 6.5, 2.2, 1.6), (17.5, 1.5, 1.8, 1.2)])
    for y in range(H + 1):                       # Abstand zum Weg: 1 Kachel
        for x in range(W + 1):
            near = any(path[yy][xx] for yy in range(max(0, y - 1), min(H, y + 1) + 1)
                       for xx in range(max(0, x - 1), min(W, x + 1) + 1))
            if near:
                grass[y][x] = False
    ground = build_ground(G, W, H, "forest_floor", grass, path_c=path,
                          base_set="transition_meadow_forest_floor.png", path_set="transition_forest_floor_path.png")
    ground = ground.crop((0, 0, P.VW, P.VH))
    _, objs, flies = P.forest_scene()
    objs = [o for o in objs if not o[0].startswith("grass_tuft")]
    objs += [("wild_grass_1", 470, 225), ("wild_grass_2", 540, 250), ("wild_grass_3", 510, 210),
             ("wild_grass_1", 100, 205), ("wild_grass_2", 140, 230), ("weed_dock", 70, 225),
             ("wild_grass_3", 570, 60), ("weed_thistle", 480, 270)]
    return ground, objs, flies


def label(img, text):
    d = ImageDraw.Draw(img)
    for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
        d.text((16 + dx, 8 + dy), text, font=FONT, fill=(14, 10, 20))
    d.text((16, 8), text, font=FONT, fill=(234, 223, 203))
    return img


def stack(a, b, la, lb):
    a2 = label(a.resize((P.VW * 2, P.VH * 2), Image.NEAREST), la)
    b2 = label(b.resize((P.VW * 2, P.VH * 2), Image.NEAREST), lb)
    out = Image.new("RGBA", (P.VW * 2, P.VH * 4 + 8), (14, 10, 20, 255))
    out.alpha_composite(a2, (0, 0))
    out.alpha_composite(b2, (0, P.VH * 2 + 8))
    return out


def main(G):
    G = Path(G)
    out = P.OUT
    gA, oA, fA = P.garden_scene()
    gB, oB, fB = garden_B(G)
    wA, owA, fwA = P.forest_scene()
    wB, owB, fwB = forest_B(G)
    stack(P.render(gA, oA, 0, False), P.render(gB, oB, 0, False),
          "Jetzt: Gras als Fläche", "Vorschlag: Erde + Grasinseln + Wildgras").save(out / "vergleich_garten_2x.png")
    stack(P.render(wA, owA, 0, False), P.render(wB, owB, 0, False),
          "Jetzt: Gras als Fläche", "Vorschlag: Waldboden + Laub + Grasinseln").save(out / "vergleich_wald_2x.png")
    stack(P.render(gB, oB, 0, True, fB), P.render(wB, owB, 0, True, fwB),
          "Vorschlag Garten, Nacht", "Vorschlag Wald, Nacht").save(out / "vorschlag_nacht_2x.png")
    gif = [P.render(gB, oB, k / 8, False).resize((P.VW * 2, P.VH * 2), Image.NEAREST).convert("RGB")
           for k in range(8)]
    gif[0].save(out / "vorschlag_garten_2x.gif", save_all=True, append_images=gif[1:], duration=125, loop=0)
    print("  Vergleich: vergleich_garten_2x.png, vergleich_wald_2x.png, vorschlag_nacht_2x.png, vorschlag_garten_2x.gif")


if __name__ == "__main__":
    main(sys.argv[1])
