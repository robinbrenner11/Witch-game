"""Geisterfarn (ghost_fern) – breiter Fächer aus Farnwedeln; jung eingerollt (Spiralen),
reif entrollt mit geisterhaft schimmernden Knochen-Spitzen.
Frames 32x48, Pflanzposition x 15/16, y 37.
Aufruf: python ghost_fern.py <ausgabeordner> <beet_tile.png>
"""
import sys, math
from PIL import Image
import pix
from pix import grid, put, outline, to_image, W, H

pix.PAL.update({
    "u": (52, 70, 120),     # Nachtblau hell
    "U": (120, 140, 185),   # Geisterblau
})
BX, BY = 16, 37


def bez(p0, p1, p2, t):
    return ((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])


def frond(g, ctrl, tip, pinna=3.0, upto=1.0):
    """Wedel als Bogen vom Fuß über ctrl zur Spitze. Fiederblättchen abwechselnd
    links/rechts, zur Spitze kürzer. Lichtseite (oben) Geisterblau, Schatten Nachtblau hell."""
    base = (BX, BY)
    n = 60
    pts = [bez(base, ctrl, tip, i / n * upto) for i in range(n + 1)]
    for k in range(4, n, 6):
        t = k / n
        (x0, y0), (x1, y1) = pts[k - 1], pts[k + 1]
        dx, dy = x1 - x0, y1 - y0
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        ln = max(1, round(pinna * (1 - t * 0.75)))
        for sgn in (1, -1):
            # Blättchen leicht nach vorn (Richtung Spitze) geneigt
            vx, vy = nx * sgn + dx / L * 0.5, ny * sgn + dy / L * 0.5
            vl = math.hypot(vx, vy)
            vx, vy = vx / vl, vy / vl
            col = "U" if vy < 0.2 else "u"
            for j in range(1, ln + 1):
                put(g, round(pts[k][0] + vx * j), round(pts[k][1] + vy * j), col)
    for i, (x, y) in enumerate(pts):
        put(g, round(x), round(y), "i" if i < n * 0.25 else "u")
    return round(pts[-1][0]), round(pts[-1][1])


CURL_L = [".UU.",
          "U..U",
          "Uw.U",
          ".uu."]
CURL_R = [".UU.",
          "U..U",
          "U.wU",
          ".uu."]


def curl(g, x, y, right):
    tpl = CURL_R if right else CURL_L
    for j, row in enumerate(tpl):
        for i, ch in enumerate(row):
            if ch != ".":
                put(g, x - 1 + i, y - 3 + j, ch)


def stage_seed():
    g = grid([])
    curl(g, 16, 36, False)
    outline(g, "a")
    return g


def stage_sprout():
    g = grid([])
    for ctrl, tip, right in [((14, 31), (12, 29), False), ((18, 30), (20, 28), True), ((16, 30), (16, 27), False)]:
        tx, ty = frond(g, ctrl, tip, pinna=0)
        curl(g, tx, ty, right)
    outline(g, "a")
    return g


FRONDS_RIPE = [((9, 28), (1, 29)), ((10, 17), (5, 14)), ((16, 12), (17, 7)),
               ((22, 17), (27, 14)), ((23, 28), (31, 29))]
FRONDS_GROW = [((11, 32), (5, 31)), ((11, 25), (7, 22)), ((16, 22), (16, 18)),
               ((21, 25), (25, 22)), ((21, 32), (27, 31))]


def stage_growing():
    g = grid([])
    for ctrl, tip in FRONDS_GROW:
        tx, ty = frond(g, ctrl, tip, pinna=2.2, upto=0.85)
        curl(g, tx, ty, tx > BX)
    outline(g, "a")
    return g


def stage_ripe():
    g = grid([])
    tips = [frond(g, ctrl, tip, pinna=3.0) for ctrl, tip in FRONDS_RIPE]
    outline(g, "a")
    for tx, ty in tips:                      # schimmernde Spitzen
        put(g, tx, ty, "w")
    for x, y, c in [(3, 20, "w"), (29, 21, "U"), (11, 9, "U"), (22, 6, "w"), (9, 24, "U"), (24, 24, "w")]:
        put(g, x, y, c)
    return g


def main(out, bed):
    fr = [to_image(f) for f in (stage_seed(), stage_sprout(), stage_growing(), stage_ripe())]
    sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, f in enumerate(fr):
        sheet.alpha_composite(f, (i * W, 0))
    sheet.save(f"{out}/ghost_fern_stages.png")
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
    c.save(f"{out}/zwischenstand_ghost_fern.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
