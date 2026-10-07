"""Nachtschatten-Kuppel: geisterhaft blaue Glocke über dem 3x3-Bereich, die leicht pocht.
Alles unter der Kuppel welkt (in Godot: gehemmte Pflanzen per modulate entsättigen).
Aufruf: python nightshade_aura.py <effekt-ordner> <ui-ordner> [vorschauordner]
        z. B. python nightshade_aura.py assets/effects assets/ui docs/art/vorschau

Mehrere Nachtschatten nebeneinander: Die Kuppeln verschmelzen (siehe unten,
render_domes / field / smin). Im Spiel als Shader umsetzen, das Einzel-Sprite
ist Referenz und Fallback. Außerdem: debuff_nightshade.png (16x16, für später).

nightshade_dome.png – 4 Frames à 120x120 nebeneinander (480x120).
  Liegt ÜBER den Pflanzen (halbtransparent). Der Wurzelpunkt des Nachtschattens
  liegt bei (60, 69) im Frame. Die Kuppel deckt genau das 3x3-Feld ab.
  Pochen: Frames 0-1-2-1 abspielen, Frame 0 etwas länger halten (Ruhepuls).
"""
import sys, os, math
from PIL import Image

GHOST = (120, 140, 185)      # Geisterblau
PALE = (206, 214, 244)       # Eisblau hell (neu, schon bei den Tränken genutzt)
DEEP = (52, 70, 120)         # Nachtblau hell
WHITE = (240, 244, 255)      # neu: Glanzpunkt

S = 120
CX, CY = 60, 64              # Mitte des 3x3-Bereichs am Boden
ROOT = (60, 69)              # Wurzel des Nachtschattens (Beetmitte + 5 px)
RX = 49                      # Kuppel deckt 3 Tiles (96 px) ab
RY_GROUND = 47               # Bodenellipse
RY_DOME = 60                 # Höhe der Glocke nach oben
PULSE = [0.0, 0.5, 1.0]      # Intensität der drei Frames (0 = Ruhe)


def inside(x, y, grow=0.0):
    ry = (RY_DOME if y < CY else RY_GROUND) + grow
    return ((x - CX) / (RX + grow)) ** 2 + ((y - CY) / ry) ** 2 <= 1.0


def frame(t):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fill_a = round(28 + 26 * t)
    rim_a = round(150 + 90 * t)
    mask = [[inside(x, y) for x in range(S)] for y in range(S)]

    for y in range(S):
        for x in range(S):
            if not mask[y][x]:
                # Puls-Schein knapp außerhalb, nur auf dem Höhepunkt
                if t >= 1.0 and inside(x, y, grow=1.5) and (x + y) % 2 == 0:
                    im.putpixel((x, y), GHOST + (70,))
                continue
            edge = any(not (0 <= x + dx < S and 0 <= y + dy < S and mask[y + dy][x + dx])
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge:
                # Rand: oben links heller (Licht), unten rechts dunkler
                lit = (x - CX) + (y - CY) < -10
                col = PALE if lit else GHOST
                a = rim_a if lit else round(rim_a * 0.75)
                im.putpixel((x, y), col + (a,))
            else:
                # Glasfüllung: zur Mitte hin klarer, am Rand dichter (Fresnel), als
                # 2-Stufen-Dither statt weichem Verlauf
                d = ((x - CX) / RX) ** 2 + ((y - CY) / (RY_DOME if y < CY else RY_GROUND)) ** 2
                if d > 0.72 and (x + y) % 2 == 0:
                    im.putpixel((x, y), GHOST + (min(255, fill_a + 40),))
                else:
                    im.putpixel((x, y), DEEP + (fill_a,))

    # Bodenring: hinten gestrichelt, vorne durchgehend
    for step in range(0, 360, 2):
        a = math.radians(step)
        x = round(CX + (RX - 2) * math.cos(a))
        y = round(CY + (RY_GROUND - 3) * math.sin(a))
        front = math.sin(a) > 0
        if not front and (step // 2) % 3 == 0:
            continue
        im.putpixel((x, y), (PALE if front else GHOST) + (round((110 if front else 70) + 60 * t),))

    # Glanzbogen oben links und ein kleiner Stern
    for step in range(200, 262, 2):
        a = math.radians(step)
        x = round(CX + (RX - 7) * math.cos(a))
        y = round(CY + (RY_DOME - 8) * math.sin(a))
        im.putpixel((x, y), PALE + (round(150 + 70 * t),))
        if 214 <= step <= 236:
            im.putpixel((x + 1, y + 1), PALE + (round(90 + 50 * t),))
    sx, sy = CX - 22, CY - 34
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
        a = 255 if (dx, dy) == (0, 0) else round(120 + 100 * t)
        im.putpixel((sx + dx, sy + dy), WHITE + (a,))
    return im


def build():
    frames = [frame(t) for t in PULSE] + [frame(PULSE[1])]
    sheet = Image.new("RGBA", (S * len(frames), S), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * S, 0))
    return frames, sheet


def wilt(spr):
    """Vorschau für Godot-modulate: entsättigt, kühl, dunkler."""
    r, g, b, a = spr.split()
    grey = Image.merge("RGB", (r, g, b)).convert("L")
    r2 = grey.point(lambda v: int(v * 0.55))
    g2 = grey.point(lambda v: int(v * 0.62))
    b2 = grey.point(lambda v: int(v * 0.85))
    return Image.merge("RGBA", (r2, g2, b2, a))


def preview(frames, root, preview_dir):
    gp = lambda *p: os.path.join(root, *p)
    bed = Image.open(gp("assets", "environment", "ground", "ground_bed_1.png")).convert("RGBA")
    soil = Image.open(gp("assets", "environment", "ground", "ground_soil_1.png")).convert("RGBA")
    stages = lambda n: Image.open(gp("assets", "plants", n + "_stages.png")).convert("RGBA")
    ns = stages("nightshade").crop((96, 0, 128, 48))
    neigh = {
        (0, 0): stages("mandrake").crop((32, 0, 64, 48)),
        (1, 0): stages("blood_rose").crop((32, 0, 64, 48)),
        (2, 0): stages("lantern_berry").crop((32, 0, 64, 48)),
        (0, 2): stages("ghost_fern").crop((32, 0, 64, 48)),
        (2, 2): stages("mandrake").crop((32, 0, 64, 48)),
    }
    order = [0, 1, 2, 1]
    durations = [700, 180, 260, 180]
    out = []
    for fi in order:
        W, H = 192, 176
        scene = Image.new("RGBA", (W, H), (14, 10, 20, 255))
        for ty in range(0, H, 32):
            for tx in range(0, W, 32):
                scene.alpha_composite(soil, (tx, ty))
        ox, oy = 48, 48
        for ty in range(3):
            for tx in range(3):
                scene.alpha_composite(bed, (ox + tx * 32, oy + ty * 32))
        root_of = lambda tx, ty: (ox + tx * 32 + 16, oy + ty * 32 + 21)
        for ty in range(3):
            for tx in range(3):
                x, y = root_of(tx, ty)
                spr = ns if (tx, ty) == (1, 1) else neigh.get((tx, ty))
                if spr is None:
                    continue
                if (tx, ty) != (1, 1):
                    spr = wilt(spr)
                scene.alpha_composite(spr, (x - 16, y - 37))
        rx, ry = root_of(1, 1)
        scene.alpha_composite(frames[fi], (rx - ROOT[0], ry - ROOT[1]))
        scene.alpha_composite(Image.new("RGBA", scene.size, (20, 27, 58, 60)))
        out.append(scene.resize((W * 3, H * 3), Image.NEAREST))
    out[2].save(os.path.join(preview_dir, "vorschau_nachtschatten_kuppel_3x.png"))
    out[0].convert("RGB").save(os.path.join(preview_dir, "vorschau_nachtschatten_kuppel_3x.gif"),
                               save_all=True, append_images=[o.convert("RGB") for o in out[1:]],
                               duration=durations, loop=0)


def main(out_dir, preview_dir=None):
    frames, sheet = build()
    sheet.save(os.path.join(out_dir, "nightshade_dome.png"))
    if preview_dir:
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
        preview(frames, root, preview_dir)




# ================================================================ Verschmelzende Kuppeln
# Mehrere Nachtschatten nebeneinander: Die Kuppeln überlappen nicht, sondern
# wachsen zu einer gemeinsamen Glocke zusammen (weiche Vereinigung "smooth min").
# Im Spiel am besten als Shader auf einer Fläche über dem Garten, der die
# Positionen aller Nachtschatten bekommt. Diese Funktion ist die Referenz dafür.

K_SMOOTH = 0.35   # wie weich die Kuppeln ineinanderfließen (0 = harte Kante)


def smin(a, b, k=K_SMOOTH):
    h = max(k - abs(a - b), 0.0) / k
    return min(a, b) - h * h * k * 0.25


def field(x, y, centers):
    v = 99.0
    for cx, cy in centers:
        ry = RY_DOME if y < cy else RY_GROUND
        d = ((x - cx) / RX) ** 2 + ((y - cy) / ry) ** 2
        v = smin(v, d) if v < 99 else d
    return v


def render_domes(w, h, centers, t):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fill_a = round(28 + 26 * t)
    rim_a = round(150 + 90 * t)
    F = [[field(x, y, centers) for x in range(w)] for y in range(h)]
    ins = lambda x, y: 0 <= x < w and 0 <= y < h and F[y][x] <= 1.0
    for y in range(h):
        for x in range(w):
            if not ins(x, y):
                if t >= 1.0 and 0 <= x < w and F[y][x] <= 1.07 and (x + y) % 2 == 0:
                    im.putpixel((x, y), GHOST + (70,))
                continue
            edge = not all(ins(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge:
                # Lichtrichtung aus dem Feldgradienten: Rand oben links heller
                gx = F[y][min(x + 1, w - 1)] - F[y][max(x - 1, 0)]
                gy = F[min(y + 1, h - 1)][x] - F[max(y - 1, 0)][x]
                lit = gx + gy < 0
                im.putpixel((x, y), (PALE if lit else GHOST) + ((rim_a if lit else round(rim_a * 0.75)),))
            elif F[y][x] > 0.72 and (x + y) % 2 == 0:
                im.putpixel((x, y), GHOST + (min(255, fill_a + 40),))
            else:
                im.putpixel((x, y), DEEP + (fill_a,))
    # Glanzbogen und Stern je Kuppel, aber nur, wo keine Nachbarkuppel ist
    others = lambda px_, py_, me: any(
        ((px_ - cx) / RX) ** 2 + ((py_ - cy) / (RY_DOME if py_ < cy else RY_GROUND)) ** 2 < 0.8
        for (cx, cy) in centers if (cx, cy) != me)
    for c in centers:
        cx, cy = c
        for step in range(200, 262, 2):
            a = math.radians(step)
            x = round(cx + (RX - 7) * math.cos(a)); y = round(cy + (RY_DOME - 8) * math.sin(a))
            if 0 <= x < w and 0 <= y < h and not others(x, y, c):
                im.putpixel((x, y), PALE + (round(150 + 70 * t),))
        sx, sy = cx - 22, cy - 34
        if not others(sx, sy, c):
            for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                im.putpixel((sx + dx, sy + dy), WHITE + ((255 if (dx, dy) == (0, 0) else round(120 + 100 * t)),))
        # Bodenring nur vorne und nur außerhalb der anderen Kuppeln
        for step in range(0, 180, 2):
            a = math.radians(step)
            x = round(cx + (RX - 2) * math.cos(a)); y = round(cy + (RY_GROUND - 3) * math.sin(a))
            if 0 <= x < w and 0 <= y < h and not others(x, y, c):
                im.putpixel((x, y), PALE + (round(110 + 60 * t),))
    return im


# ---------------------------------------------------------------- Debuff
DEBUFF = [
    "................",
    ".....aaaaaa.....",
    "...aaPPPPPPaa...",
    "..aPffffffffPa..",
    ".aPffffddddffPa.",
    ".aPfffdffffdfPa.",
    "aPffffdffffdffPa",
    "aPffffdfffSSSfPa",
    "aPffffdfffSSSfPa",
    "aPfSSfdffffSffPa",
    "aPffSSdfffffffPa",
    "aPffffdfSSffffPa",
    "aaPPPPPPPPPPPPaa",
    ".aaaaaaaaaaaaaa.",
    "................",
    "................",
]


def debuff_icon():
    """Kleine Kuppel mit verwelkter, hängender Blüte."""
    col = {"a": (43, 22, 51), "P": PALE, "f": DEEP, "d": (24, 26, 40), "S": (124, 124, 104)}
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y, r in enumerate(DEBUFF):
        for x, ch in enumerate(r):
            if ch in col:
                im.putpixel((x, y), col[ch] + (255,))
    return im


def tint_witch(spr, t):
    """Vorschau: Hexe in der Kuppel kühl-blau getönt (in Godot: modulate)."""
    r, g, b, a = spr.split()
    return Image.merge("RGBA", (r.point(lambda v: int(v * 0.7)), g.point(lambda v: int(v * 0.8)),
                                b.point(lambda v: min(255, int(v * 1.1 + 12))), a))


def preview_merged(root, preview_dir):
    gp = lambda *p: os.path.join(root, *p)
    bed = Image.open(gp("assets", "environment", "ground", "ground_bed_1.png")).convert("RGBA")
    soil = Image.open(gp("assets", "environment", "ground", "ground_soil_1.png")).convert("RGBA")
    stages = lambda n: Image.open(gp("assets", "plants", n + "_stages.png")).convert("RGBA")
    ns = stages("nightshade").crop((96, 0, 128, 48))
    md = stages("mandrake").crop((64, 0, 96, 48))
    gf = stages("ghost_fern").crop((64, 0, 96, 48))
    witch = Image.open(gp("assets", "characters", "witch_idle.png")).convert("RGBA").crop((0, 0, 32, 64))
    icon = debuff_icon()
    W, H = 320, 224
    ox, oy = 48, 40
    cols, rows = 7, 5
    shades = {(1, 1), (2, 1), (4, 2)}
    others = {(0, 0): md, (3, 0): gf, (0, 2): gf, (3, 2): md, (5, 3): md, (6, 1): gf, (1, 3): md}
    root_of = lambda tx, ty: (ox + tx * 32 + 16, oy + ty * 32 + 21)
    centers = [(root_of(tx, ty)[0], root_of(tx, ty)[1] - 5) for tx, ty in shades]
    inside = lambda x, y: field(x, y, centers) <= 1.0
    order, durations, out = [0, 1, 2, 1], [700, 180, 260, 180], []
    domes = {i: render_domes(W, H, centers, t) for i, t in enumerate(PULSE)}
    wpos = root_of(3, 1)   # Hexe steht zwischen den Kuppeln, in der Glocke
    for fi in order:
        scene = Image.new("RGBA", (W, H), (14, 10, 20, 255))
        for ty in range(0, H, 32):
            for tx in range(0, W, 32):
                scene.alpha_composite(soil, (tx, ty))
        for ty in range(rows):
            for tx in range(cols):
                scene.alpha_composite(bed, (ox + tx * 32, oy + ty * 32))
        sprites = []
        for (tx, ty) in shades:
            sprites.append((root_of(tx, ty), ns))
        for (tx, ty), spr in others.items():
            x, y = root_of(tx, ty)
            sprites.append(((x, y), wilt(spr) if inside(x, y - 5) else spr))
        sprites.append(((wpos[0], wpos[1] + 6), "witch"))
        for (x, y), spr in sorted(sprites, key=lambda s: s[0][1]):
            if spr == "witch":
                w_ = tint_witch(witch, 0)
                scene.alpha_composite(w_, (x - 16, y - 60))
                scene.alpha_composite(icon, (x - 8, y - 82))
            else:
                scene.alpha_composite(spr, (x - 16, y - 37))
        scene.alpha_composite(domes[fi])
        scene.alpha_composite(Image.new("RGBA", scene.size, (20, 27, 58, 60)))
        out.append(scene.resize((W * 3, H * 3), Image.NEAREST))
    out[2].save(os.path.join(preview_dir, "vorschau_kuppeln_verschmolzen_3x.png"))
    out[0].convert("RGB").save(os.path.join(preview_dir, "vorschau_kuppeln_verschmolzen_3x.gif"),
                               save_all=True, append_images=[o.convert("RGB") for o in out[1:]],
                               duration=durations, loop=0)
    big = icon.resize((128, 128), Image.NEAREST)
    bg = Image.new("RGBA", (144, 144), (14, 10, 20, 255)); bg.alpha_composite(big, (8, 8))
    bg.save(os.path.join(preview_dir, "vorschau_debuff_8x.png"))


if __name__ == "__main__":
    # Aufruf: python nightshade_aura.py <effekt-ordner> <ui-ordner> [vorschauordner]
    fx_dir, ui_dir = sys.argv[1], sys.argv[2]
    prev = sys.argv[3] if len(sys.argv) > 3 else None
    main(fx_dir, prev)
    debuff_icon().save(os.path.join(ui_dir, "debuff_nightshade.png"))
    if prev:
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
        preview_merged(root, prev)
