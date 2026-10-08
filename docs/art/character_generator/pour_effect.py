"""Zauber-Ausgießen: Effekt-Sprites (Bitterbloom).

Aufruf (aus dem Projektordner):
    python docs/art/character_generator/pour_effect.py

Ablauf im Spiel: Bei Frame 3 der Hexen-Animation startet an den Fingerspitzen
der Orb und fliegt per Tween im Bogen zur Zielpflanze. Dort spielt der
Sprühregen; die Funken liegen als zweite Ebene genau darüber.

Ausgabe in assets/effects/:
    pour_orb.png          2 Frames à 8x8   – Tropfen-Orb (Wabbeln), EINFÄRBBAR
    pour_rain.png         6 Frames à 32x48 – Platzen + Sprühregen, EINFÄRBBAR
    pour_sparks.png       6 Frames à 32x48 – Magenta-Funken, NICHT einfärben
Einfärbbar heißt: fast weiße Töne, Godot färbt per `modulate` in der Trankfarbe.
Regen und Funken haben dasselbe Format wie die Pflanzen (32x48, unten bündig
mit dem Beet-Tile), also genau wie eine Pflanze positionieren.
Vorschau: docs/art/vorschau/vorschau_pour_effekt_4x.gif
"""
import math
import random
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
FX = ROOT / "assets" / "effects"
PREVIEW = ROOT / "docs" / "art" / "vorschau"

W = (240, 244, 255, 255)   # Glanz kalt – Hauptton, wird eingefärbt
Q = (198, 184, 190, 255)   # Laken Schatten – Schattenseite der Tropfen
O = (150, 136, 160, 255)   # Laken Schatten tief – Kontur, nur am Orb
M = (194, 48, 122, 255)    # Magenta
MH = (228, 88, 177, 255)   # Magenta hell
P = (255, 210, 236, 255)   # Magenta hell rosa
D = (92, 30, 78, 255)      # Magenta gedaempft

RW, RH, N = 32, 48, 6
BURST = (16, 6)            # Platzpunkt über der Pflanze
GROUND = 44                # hier landen die Tropfen (Beetmitte)


def put(img, x, y, c):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def orb():
    rows = [[".oooo.",
             "owwwqo",
             "owWwqo",
             "owwwqo",
             "oqqqqo",
             ".oooo."],
            [".oooo..",
             "owWwqo.",
             "owwwqqo",
             ".oqqqo.",
             "..ooo.."]]
    cmap = {"o": O, "w": W, "W": W, "q": Q}
    out = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    for i, r in enumerate(rows):
        oy = (8 - len(r)) // 2
        for y, row in enumerate(r):
            for x, ch in enumerate(row):
                if ch != ".":
                    out.putpixel((i * 8 + 1 + x, oy + y), cmap[ch])
    # Glanzpunkt oben links (Licht von oben links) bleibt reines Weiß-Blau
    return out


def rain_and_sparks():
    rnd = random.Random(11)
    drops = []
    for i in range(24):
        # gleichmäßig über einen Fächer verteilt, damit der Regen das ganze Tile trifft
        ang = math.radians(180 + 180 * (i + rnd.uniform(0.1, 0.9)) / 24)
        sp = rnd.uniform(3.0, 6.5)
        drops.append([BURST[0], BURST[1], math.cos(ang) * sp, math.sin(ang) * sp * 0.5,
                      rnd.uniform(0, 1)])
    rain = Image.new("RGBA", (RW * N, RH), (0, 0, 0, 0))
    sparks = Image.new("RGBA", (RW * N, RH), (0, 0, 0, 0))

    # F1: Orb platzt – kleiner Stern
    ox = 0
    cx, cy = BURST
    for dx, dy, c in [(0, 0, W), (-1, 0, W), (1, 0, W), (0, -1, W), (0, 1, Q),
                      (-2, 0, Q), (2, 0, Q), (0, -2, W), (-2, -2, W), (2, -2, W),
                      (-2, 2, Q), (2, 2, Q)]:
        put(rain, ox + cx + dx, cy + dy, c)

    landed = {}
    for f in range(1, N):
        ox = f * RW
        for i, d in enumerate(drops):
            if i in landed:
                if landed[i] == f - 1:          # Spritzer genau einen Frame
                    x = ox + d[0]
                    put(rain, x - 1, GROUND - 1, Q)
                    put(rain, x + 1, GROUND - 1, Q)
                    put(rain, x, GROUND, W)
                continue
            d[0] += d[2]
            d[1] += d[3]
            d[2] *= 0.7                        # seitlicher Schwung lässt nach
            d[3] += 3.4 + d[4] * 2.4              # Schwerkraft
            d[0] = min(max(d[0], 2), RW - 3)
            if d[1] >= GROUND:
                d[1] = GROUND
                landed[i] = f
                put(rain, ox + d[0], GROUND, W)
                continue
            x, y = ox + d[0], d[1]
            if d[3] > 2.5:                      # fallend: Strich, heller Kopf unten
                put(rain, x, y - 1, Q)
                put(rain, x, y, W)
            else:                               # Sprühphase: einzelner Tropfen
                put(rain, x, y, W)

    # Funken: zwinkern im Platzbereich und fallen langsam mit dem Regen
    spark_paths = [
        [(13, 4, "big"), (11, 8, "dot"), (10, 13, "dim"), None, None, None],
        [(20, 3, "dot"), (22, 6, "big"), (23, 11, "dot"), (23, 17, "dim"), None, None],
        [None, (8, 10, "dot"), (7, 16, "big"), (7, 23, "dot"), (6, 30, "dim"), None],
        [None, None, (18, 18, "dot"), (19, 24, "big"), (19, 31, "dot"), (20, 38, "dim")],
        [None, None, None, (26, 26, "dot"), (25, 33, "big"), (25, 40, "dim")],
        [(16, 1, "dot"), None, None, None, (12, 38, "dot"), (12, 43, "dim")],
    ]
    for path in spark_paths:
        for f, s in enumerate(path):
            if not s:
                continue
            x, y, kind = s
            x += f * RW
            if kind == "big":
                put(sparks, x, y, P)
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    put(sparks, x + dx, y + dy, MH)
            elif kind == "dot":
                put(sparks, x, y, MH)
                put(sparks, x + 1, y + 1, M)
            else:
                put(sparks, x, y, D)
    return rain, sparks


def main():
    FX.mkdir(parents=True, exist_ok=True)
    o = orb()
    rain, sparks = rain_and_sparks()
    o.save(FX / "pour_orb.png")
    rain.save(FX / "pour_rain.png")
    sparks.save(FX / "pour_sparks.png")

    # Vorschau: Mondkelch reif + Effekt, links normal (weiß), rechts grün eingefärbt
    plant = Image.open(ROOT / "assets" / "plants" / "moon_chalice_stages.png").convert("RGBA")
    plant = plant.crop((96, 0, 128, 48))
    tint = (98, 160, 110)          # Giftgrün hell als Beispiel-Trankfarbe
    gif = []
    for f in range(N):
        canvas = Image.new("RGBA", (2 * RW + 24, RH + 8), (52, 64, 52, 255))
        for k in range(2):
            x0 = 8 + k * (RW + 8)
            canvas.alpha_composite(plant, (x0, 4))
            r = rain.crop((f * RW, 0, f * RW + RW, RH))
            if k == 1:
                px = r.load()
                for yy in range(RH):
                    for xx in range(RW):
                        c = px[xx, yy]
                        if c[3]:
                            px[xx, yy] = tuple(c[i] * tint[i] // 255 for i in range(3)) + (255,)
            canvas.alpha_composite(r, (x0, 4))
            canvas.alpha_composite(sparks.crop((f * RW, 0, f * RW + RW, RH)), (x0, 4))
        gif.append(canvas.resize((canvas.width * 4, canvas.height * 4), Image.NEAREST).convert("RGB"))
    gif[0].save(PREVIEW / "vorschau_pour_effekt_4x.gif", save_all=True, append_images=gif[1:],
                duration=100, loop=0)
    print("pour_orb 16x8 (2), pour_rain 192x48 (6), pour_sparks 192x48 (6)")


if __name__ == "__main__":
    main()


def scene_preview(tint=(98, 160, 110)):
    """Szenen-Vorschau: Hexe (unten) zaubert auf die Pflanze ein Tile vor ihr.
    Orb fliegt im Bogen (wie später per Tween), dann Regen + Funken."""
    witch = Image.open(ROOT / "assets" / "characters" / "witch_pour_down.png").convert("RGBA")
    idle = Image.open(ROOT / "assets" / "characters" / "witch_idle.png").convert("RGBA").crop((0, 0, 32, 64))
    plant = Image.open(ROOT / "assets" / "plants" / "moon_chalice_stages.png").convert("RGBA").crop((96, 0, 128, 48))
    rain = Image.open(FX / "pour_rain.png").convert("RGBA")
    sparks = Image.open(FX / "pour_sparks.png").convert("RGBA")
    orb_img = Image.open(FX / "pour_orb.png").convert("RGBA")

    def tinted(img):
        img = img.copy()
        px = img.load()
        for y in range(img.height):
            for x in range(img.width):
                c = px[x, y]
                if c[3]:
                    px[x, y] = tuple(c[i] * tint[i] // 255 for i in range(3)) + (255,)
        return img

    rain, orb_img = tinted(rain), tinted(orb_img)
    cw, ch = 96, 128
    feet = (48, 60)                       # Füße der Hexe = Tile-Mitte
    wpos = (feet[0] - 16, feet[1] - 63)
    ppos = (feet[0] - 16, feet[1])        # Pflanze ein Tile weiter unten, unten bündig
    start = (wpos[0] + 26, wpos[1] + 31)  # Orb-Start aus witch_actions (Frame 3)
    end = (ppos[0] + BURST[0], ppos[1] + BURST[1])
    ctrl = ((start[0] + end[0]) / 2 + 14, min(start[1], end[1]) - 14)

    # (Hexen-Frame oder None=Idle, Orb-t oder None, Regen-Frame oder None)
    timeline = [(0, None, None), (1, None, None), (2, 0.0, None), (3, 0.35, None),
                (4, 0.7, None), (4, None, 0), (None, None, 1), (None, None, 2),
                (None, None, 3), (None, None, 4), (None, None, 5), (None, None, None),
                (None, None, None)]
    frames = []
    for k, (wf, t, rf) in enumerate(timeline):
        c = Image.new("RGBA", (cw, ch), (52, 64, 52, 255))
        c.alpha_composite(witch.crop((wf * 32, 0, wf * 32 + 32, 64)) if wf is not None else idle, wpos)
        c.alpha_composite(plant, ppos)
        if t is not None:
            x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * ctrl[0] + t * t * end[0]
            y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * ctrl[1] + t * t * end[1]
            o = orb_img.crop(((k % 2) * 8, 0, (k % 2) * 8 + 8, 8))
            c.alpha_composite(o, (int(x) - 4, int(y) - 4))
        if rf is not None:
            c.alpha_composite(rain.crop((rf * 32, 0, rf * 32 + 32, 48)), ppos)
            c.alpha_composite(sparks.crop((rf * 32, 0, rf * 32 + 32, 48)), ppos)
        frames.append(c.resize((cw * 4, ch * 4), Image.NEAREST).convert("RGB"))
    frames[0].save(PREVIEW / "vorschau_pour_szene_4x.gif", save_all=True,
                   append_images=frames[1:], duration=110, loop=0)


if __name__ == "__main__":
    scene_preview()
