"""Alraune (mandrake) – flache Blattrosette, reif lugt ein kleiner Kopf mit glimmenden Augen hervor.
Frames 32x48, Pflanzposition x 15/16, y 37 (Rosettenmitte etwas darüber).
Aufruf: python mandrake.py <ausgabeordner> <beet_tile.png>
"""
import sys, math
from PIL import Image
import pix
from pix import grid, put, outline, to_image, W, H

# Ergänzungen: abgeleitete Grüntöne + Hauttöne aus der Projektpalette (hexen_palette.gpl)
pix.PAL.update({
    "q": (36, 74, 58),      # Giftgrün dunkel
    "Q": (98, 160, 110),    # Giftgrün hell
    "e": (74, 43, 39),      # Haut mittel
    "h": (107, 63, 51),     # Haut licht
    "H": (138, 82, 64),     # Haut Highlight
})

CX, CY = 16, 33   # Rosettenmitte


def leaf(g, angle_deg, length, width, cx=CX, cy=CY):
    """Breites, flach liegendes Blatt vom Zentrum aus. Licht oben links:
    zugewandte Hälfte hell, abgewandte dunkel, Mittelrippe Gold."""
    a = math.radians(angle_deg)
    ux, uy = math.cos(a), -math.sin(a)
    nx, ny = -uy, ux
    # Normale so drehen, dass sie zum Licht (oben links) zeigt
    if nx * -1 + ny * -1 < 0:
        nx, ny = -nx, -ny
    cells = {}
    for i in range(int(length * 4) + 1):
        t = i / (length * 4)
        half = width * math.sin(math.pi * (0.12 + 0.88 * t)) ** 0.7
        for j in range(-int(half * 4) - 1, int(half * 4) + 2):
            s = j / 4
            if abs(s) > half:
                continue
            x = round(cx + ux * length * t + nx * s)
            y = round(cy + uy * length * t * 0.75 + ny * s)   # 0.75: flach liegend (Draufsicht)
            if s > half * 0.6:
                c = "Q"
            elif s > 0:
                c = "G"
            else:
                c = "q"
            cells.setdefault((x, y), c)
    # Mittelrippe als dünne 1px-Linie
    for i in range(int(length * 2)):
        t = i / (length * 2)
        if length >= 8 and 0.35 < t < 0.8:
            x = round(cx + ux * length * t); y = round(cy + uy * length * t * 0.75)
            cells[(x, y)] = "g"
    for (x, y), c in cells.items():
        put(g, x, y, c)


HEAD = [
    "....hhhhh....",
    "...hHHHhhe...",
    "..hHkkhhkke..",
    "..hkMMhhMMe..",
    "..hhkMhhkMe..",
    "..hhhhhhhee..",
    "eeehhhhhheeee",
    "e.e.eeee.e..e",
]


def stage_seed():
    g = grid([])
    for x, y, c in [(15, 34, "w"), (16, 34, "w"), (14, 35, "w"), (15, 35, "l"), (16, 35, "w"),
                    (17, 35, "l"), (15, 36, "l"), (16, 36, "e"), (16, 33, "G"), (17, 32, "G")]:
        put(g, x, y, c)
    outline(g, "a")
    return g


def stage_sprout():
    g = grid([])
    leaf(g, 140, 6, 1.8)
    leaf(g, 50, 6, 1.8)
    leaf(g, 95, 5, 1.5)
    outline(g, "a")
    return g


def stage_growing():
    g = grid([])
    for ang, ln, wd in [(120, 9, 2.6), (65, 9, 2.6), (165, 10, 2.6), (15, 10, 2.6), (95, 8, 2.3)]:
        leaf(g, ang, ln, wd)
    for ang, ln, wd in [(215, 8, 2.4), (325, 8, 2.4)]:
        leaf(g, ang, ln, wd)
    outline(g, "a")
    return g


def stage_ripe():
    g = grid([])
    # hintere Blätter
    for ang, ln, wd in [(130, 11, 2.8), (55, 11, 2.8), (170, 12, 2.8), (10, 12, 2.8)]:
        leaf(g, ang, ln, wd)
    # Kopf lugt aus der Mitte
    for j, row in enumerate(HEAD):
        for i, ch in enumerate(row):
            if ch != ".":
                put(g, 10 + i, 24 + j, ch)
    # Blattschopf oben auf dem Kopf
    leaf(g, 115, 6, 1.6, cx=16, cy=24)
    leaf(g, 65, 6, 1.6, cx=16, cy=24)
    leaf(g, 90, 5, 1.3, cx=16, cy=24)
    # (Kopf wurde hier gezeichnet; Wurzelfinger links/rechts greifen in die Erde)
    # vordere Blätter überdecken den Hals -> Kopf steckt in der Erde
    for ang, ln, wd in [(215, 10, 2.8), (325, 10, 2.8), (265, 5, 2.4)]:
        leaf(g, ang, ln, wd)
    outline(g, "a")
    return g


def main(out, bed):
    fr = [to_image(f) for f in (stage_seed(), stage_sprout(), stage_growing(), stage_ripe())]
    sheet = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, f in enumerate(fr):
        sheet.alpha_composite(f, (i * W, 0))
    sheet.save(f"{out}/mandrake_stages.png")
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
    c.save(f"{out}/zwischenstand_mandrake.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
