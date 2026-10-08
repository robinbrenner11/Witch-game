"""Vorschauen für Flora/Fauna: Wald- und Garten-Szene (640x360 = Viewport),
jeweils Tag und Nacht, plus animiertes Nacht-GIF und eine Übersicht aller Teile.

Aufruf (aus dem Projektordner, nach forest.py und garden.py):
    python docs/art/nature_generator/preview.py

Die Nacht wird so gerechnet wie in Godot: Grafik × (Nachtfarbe #665C8F + Lichter).
Glühwürmchen werden danach unbeleuchtet obendrauf gemalt (wie unshaded).
"""
import math
from PIL import Image, ImageDraw, ImageFont
from nature import ROOT, _hash
import shadows as SH

FL = ROOT / "assets/environment/flora"
FA = ROOT / "assets/environment/fauna"
GROUND = ROOT / "assets/environment/ground"
OUT = ROOT / "docs/art/vorschau"
VW, VH = 640, 360
NIGHT = (0x66 / 255, 0x5C / 255, 0x8F / 255)


def sheet(name, folder=FL):
    im = Image.open(folder / f"{name}.png").convert("RGBA")
    return im


def frame(name, i, folder=FL):
    im = sheet(name, folder)
    h = im.height
    # Frame-Breite aus der Datei ableiten: Bekannte Breiten
    fw = FRAME_W.get(name, im.width)
    n = im.width // fw
    i %= n
    return im.crop((i * fw, 0, i * fw + fw, h))


FRAME_W = {"mushroom_moon_glow": 24, "mushroom_ember_glow": 24, "mushroom_ring_glow": 64,
           "tree_oak": 96, "tree_willow": 96, "tree_fir": 72, "tree_elder": 72,
           "fern_1": 32, "fern_2": 32, "grass_tuft_1": 16, "grass_tuft_2": 16, "grass_tuft_3": 16,
           "bush_lavender": 32, "mushroom_moon": 24, "mushroom_ember": 24, "mushroom_ring": 64,
           "firefly": 8}
FPS = {"tree_oak": 6, "tree_willow": 6, "tree_fir": 6, "tree_elder": 6, "fern_1": 4, "fern_2": 4,
       "grass_tuft_1": 4, "grass_tuft_2": 4, "grass_tuft_3": 4, "bush_lavender": 4,
       "mushroom_moon": 4, "mushroom_ember": 4, "mushroom_ring": 6}

# Lichter je Objekt: (Farbe, Energie, Radius in px, Versatz y vom Fußpunkt)
LIGHTS = {
    "mushroom_moon": ((0.62, 0.72, 1.0), 0.9, 40, -6),
    "mushroom_ember": ((1.0, 0.71, 0.40), 0.9, 40, -6),
    "mushroom_ring": ((0.85, 0.25, 0.6), 0.8, 70, -20),
    "flowers_ember": ((1.0, 0.71, 0.40), 0.5, 24, -10),
    "flowers_moon": ((0.85, 0.85, 1.0), 0.35, 20, -10),
    # vorhandene Lichter aus dem Spiel (zum realistischen Vergleich)
    "prop:campfire": ((1.0, 0.71, 0.40), 1.5, 90, -10),
    "plant:moon_chalice": ((0.75, 0.75, 1.0), 0.7, 40, -30),
    "plant:lantern_berry": ((1.0, 0.71, 0.40), 0.7, 40, -24),
    "plant:ghost_fern": ((0.55, 0.65, 1.0), 0.5, 32, -14),
}
FIREFLY_LIGHT = ((1.0, 0.8, 0.45), 0.55, 14)


def ground_from_corners(corners, atlas_name, w_tiles, h_tiles):
    """corners[y][x] = True, wenn die Ecke zum oberen Material (Gras) gehört.
    Tile-Index = TL*1 + TR*2 + BL*4 + BR*8 (wie in ASSETS.md beschrieben)."""
    atlas = Image.open(GROUND / "transitions" / atlas_name).convert("RGBA")
    img = Image.new("RGBA", (w_tiles * 32, h_tiles * 32))
    for ty in range(h_tiles):
        for tx in range(w_tiles):
            idx = (corners[ty][tx] * 1 + corners[ty][tx + 1] * 2 +
                   corners[ty + 1][tx] * 4 + corners[ty + 1][tx + 1] * 8)
            r, c = divmod(idx, 4)
            if idx == 15:                     # reines Gras: Basis-Tiles abwechseln
                tile = Image.open(GROUND / f"ground_grass_{1 + (tx * 7 + ty * 3) % 3}.png").convert("RGBA")
            else:
                tile = atlas.crop((c * 32, r * 32, c * 32 + 32, r * 32 + 32))
            img.alpha_composite(tile, (tx * 32, ty * 32))
    return img


def light_tex(radius):
    base = Image.open(ROOT / "assets/effects/lights/light_round_128.png").convert("RGBA")
    return base.resize((radius * 2, radius * 2), Image.BILINEAR)


def render(ground, objects, t, night, fireflies=()):
    """objects = [(name, fuß_x, fuß_y)]; t = Zeit in Sekunden."""
    img = ground.copy()
    lights = []
    glows = []
    # Bodenschatten zuerst, sie liegen unter allen Objekten
    for name, fx, fy in objects:
        if name.startswith("fence:"):
            SH.draw_shadow(img, "fence_post", fx, fy + 12)
        elif name.startswith("plant:"):
            SH.draw_shadow(img, "plant", fx, fy - 2)
        elif name.startswith("prop:"):
            SH.draw_shadow(img, name[5:], fx, fy)
        else:
            SH.draw_shadow(img, name, fx, fy)
    for name, fx, fy in sorted(objects, key=lambda o: o[2]):
        fps = FPS.get(name, 0)
        start = int(_hash(fx, fy, 3) * 8)                   # jede Instanz startet woanders
        idx = start + int(t * fps) if fps else 0
        if name.startswith("fence:"):
            mask = int(name.split(":")[1])
            atlas = Image.open(ROOT / "assets/environment/props/fence_atlas.png").convert("RGBA")
            im = atlas.crop(((mask % 4) * 32, (mask // 4) * 32, (mask % 4) * 32 + 32, (mask // 4) * 32 + 32))
            img.alpha_composite(im, (fx - 16, fy - 16))       # Kachel: Fuß = Kachelmitte
            continue
        if name.startswith("plant:"):
            im = Image.open(ROOT / f"assets/plants/{name[6:]}_stages.png").convert("RGBA").crop((96, 0, 128, 48))
            img.alpha_composite(im, (fx - 16, fy - 40))
            if name in LIGHTS:
                lights.append((name, fx, fy))
            continue
        if name == "witch":
            im = Image.open(ROOT / "assets/characters/witch_idle.png").convert("RGBA").crop((0, 0, 32, 64))
            img.alpha_composite(im, (fx - 16, fy - 63))
            continue
        if name.startswith("prop:"):
            im = Image.open(ROOT / f"assets/environment/props/{name[5:]}.png").convert("RGBA")
            if name.endswith("campfire"):
                im = im.crop((0, 0, 32, 32))
            img.alpha_composite(im, (fx - im.width // 2, fy - im.height))
            if name in LIGHTS:
                lights.append((name, fx, fy))
            continue
        im = frame(name, idx)
        img.alpha_composite(im, (fx - im.width // 2, fy - im.height))
        if name in LIGHTS:
            lights.append((name, fx, fy))
        if (FL / f"{name}_glow.png").exists():
            g = frame(f"{name}_glow", idx)
            glows.append((g, fx - g.width // 2, fy - g.height))
    if not night:
        return img
    fly_pos = []
    for i, (x0, y0) in enumerate(fireflies):
        x = x0 + 10 * math.sin(t * 0.9 + i * 1.7) + 4 * math.sin(t * 2.3 + i)
        y = y0 + 6 * math.sin(t * 1.3 + i * 2.1)
        fly_pos.append((int(x), int(y), int(t * 6) + i * 2))
    # Nacht: Albedo × (Nachtfarbe + Licht)
    w, h = img.size
    lum = [[list(NIGHT) for _ in range(w)] for _ in range(h)]
    all_lights = [(LIGHTS[n], fx, fy) for n, fx, fy in lights]
    blink = [0.0, 0.0, 0.4, 1.0, 1.0, 0.4]
    for x, y, fi in fly_pos:
        col, energy, rad = FIREFLY_LIGHT
        all_lights.append(((col, energy * blink[fi % 6], rad, 0), x, y))
    for (col, energy, rad, oy), fx, fy in all_lights:
        if energy <= 0:
            continue
        pulse = 1 + 0.12 * math.sin(t * 3 + fx)
        tex = light_tex(rad).load()
        cx, cy = fx, fy + oy
        for yy in range(-rad, rad):
            for xx in range(-rad, rad):
                X, Y = cx + xx, cy + yy
                if 0 <= X < w and 0 <= Y < h:
                    a = tex[xx + rad, yy + rad][3] / 255 * energy * pulse
                    if a > 0.01:
                        L = lum[Y][X]
                        for k in range(3):
                            L[k] += col[k] * a
    px = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            L = lum[y][x]
            px[x, y] = (min(255, int(r * L[0])), min(255, int(g * L[1])), min(255, int(b * L[2])), a)
    for g, gx, gy in glows:                       # unbeleuchtete Glow-Ebene
        img.alpha_composite(g, (gx, gy))
    for x, y, fi in fly_pos:
        img.alpha_composite(frame("firefly", fi, FA), (x - 4, y - 4))
    return img


# ---------------------------------------------------------------------------
def forest_scene():
    W, H = VW // 32, VH // 32 + 1
    corners = [[True] * (W + 1) for _ in range(H + 1)]
    for y in range(H + 1):                       # gewundener Trampelpfad
        cx = int(9 + 3 * math.sin(y * 0.5))
        for x in (cx, cx + 1, cx + 2):
            corners[y][x] = False
    ground = ground_from_corners(corners, "transition_grass_path.png", W, H)
    ground = ground.crop((0, 0, VW, VH))
    objs = [
        # Waldrand oben: dicht, Bäume überlappen
        ("tree_fir", 20, 60), ("tree_oak", 80, 50), ("tree_fir", 150, 40), ("tree_willow", 230, 70),
        ("tree_fir", 400, 50), ("tree_oak", 470, 40), ("tree_fir", 540, 70), ("tree_oak", 610, 50),
        ("tree_fir", 50, 140), ("tree_oak", 560, 150),
        # Mitte und unten
        ("tree_willow", 500, 236), ("tree_dead", 610, 280), ("tree_oak", 60, 320), ("tree_fir", 130, 380),
        ("tree_fir", 630, 390), ("tree_oak", 220, 400), ("tree_fir", 20, 250),
        ("bush_1", 160, 150), ("bush_2", 410, 120), ("bush_berries", 560, 330), ("bush_1", 110, 220),
        ("bush_2", 330, 110), ("bush_1", 450, 360),
        ("fern_1", 150, 200), ("fern_2", 420, 270), ("fern_1", 600, 190), ("fern_2", 250, 310),
        ("fern_1", 90, 270), ("fern_2", 380, 355),
        ("stump", 390, 320), ("log", 170, 262),
        ("rock_1", 470, 330), ("rock_2", 190, 168), ("rock_2", 540, 205),
        ("grass_tuft_1", 200, 220), ("grass_tuft_2", 360, 200), ("grass_tuft_3", 430, 170),
        ("grass_tuft_1", 580, 240), ("grass_tuft_2", 100, 180), ("grass_tuft_3", 270, 140),
        ("grass_tuft_1", 480, 300), ("grass_tuft_3", 330, 350),
        ("mushroom_moon", 410, 330), ("mushroom_ember", 180, 274), ("mushroom_moon", 490, 250),
        ("mushroom_ember", 580, 345), ("mushroom_ring", 430, 225),
        ("witch", 330, 250),
    ]
    flies = [(150, 180), (440, 150), (500, 260), (300, 260), (90, 230), (600, 200), (380, 290), (250, 120)]
    return ground, objs, flies


def garden_scene():
    W, H = VW // 32, VH // 32 + 1
    corners = [[True] * (W + 1) for _ in range(H + 1)]
    for y in range(4, 10):                       # offene Erde ums Beet
        for x in range(5, 16):
            corners[y][x] = False
    ground = ground_from_corners(corners, "transition_grass_soil.png", W, H)
    for row, ty in ((0, 5), (1, 7)):             # zwei Beetreihen
        for i, tx in enumerate(range(6, 14)):
            if i == 0:
                name = "ground_bed_cap_left_wet"
            elif tx == 13:
                name = "ground_bed_cap_right_wet"
            else:
                name = f"ground_bed_{4 + (i % 3)}"
            ground.alpha_composite(Image.open(GROUND / f"{name}.png").convert("RGBA"), (tx * 32, ty * 32))
    ground = ground.crop((0, 0, VW, VH))
    objs = []
    plants = ["moon_chalice", "lantern_berry", "mandrake", "nightshade", "blood_rose", "ghost_fern"]
    for row, ty in ((0, 5), (1, 7)):
        for i, tx in enumerate(range(6, 14)):
            if (i + row) % 2 == 0:
                objs.append((f"plant:{plants[(i + row * 3) % 6]}", tx * 32 + 16, ty * 32 + 32))
    # Zaun: Rechteck um den Garten mit Tor unten
    fence = set()
    for x in range(3, 18):
        fence.add((x, 2)); fence.add((x, 10))
    for y in range(2, 11):
        fence.add((3, y)); fence.add((17, y))
    for x in (9, 10, 11):
        fence.discard((x, 10))
    for (x, y) in fence:
        m = ((x - 1, y) in fence) * 1 + ((x + 1, y) in fence) * 2 + ((x, y - 1) in fence) * 4 + ((x, y + 1) in fence) * 8
        objs.append((f"fence:{m}", x * 32 + 16, y * 32 + 16))
    objs += [
        ("tree_elder", 50, 130), ("tree_elder", 600, 330), ("tree_oak", 600, 110), ("tree_fir", 20, 360),
        ("bush_lavender", 150, 120), ("bush_lavender", 186, 124), ("bush_lavender", 470, 122),
        ("bush_1", 520, 124), ("bush_berries", 30, 260),
        ("flowers_lilac", 140, 300), ("flowers_moon", 160, 310), ("flowers_ember", 470, 300),
        ("flowers_blood", 500, 312), ("flowers_moon", 520, 296), ("flowers_lilac", 260, 120),
        ("flowers_ember", 370, 118), ("flowers_blood", 410, 122),
        ("grass_tuft_2", 130, 200), ("grass_tuft_1", 520, 200), ("grass_tuft_3", 150, 250),
        ("stump", 540, 250), ("mushroom_ember", 548, 262), ("rock_2", 170, 210),
        ("prop:campfire", 330, 352), ("witch", 250, 345),
    ]
    flies = [(200, 150), (420, 140), (520, 280), (130, 280), (330, 300), (600, 200)]
    return ground, objs, flies


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, scene in (("wald", forest_scene), ("garten", garden_scene)):
        ground, objs, flies = scene()
        day = render(ground, objs, 0.0, False)
        night = render(ground, objs, 0.0, True, flies)
        both = Image.new("RGBA", (VW, VH * 2 + 4), (14, 10, 20, 255))
        both.alpha_composite(day, (0, 0))
        both.alpha_composite(night, (0, VH + 4))
        both.resize((both.width * 2, both.height * 2), Image.NEAREST).save(OUT / f"vorschau_{name}_tag_nacht_2x.png")
        gif = []
        for k in range(16):
            t = k / 8.0
            gif.append(render(ground, objs, t, True, flies).resize((VW * 2, VH * 2), Image.NEAREST).convert("RGB"))
        gif[0].save(OUT / f"vorschau_{name}_nacht_2x.gif", save_all=True, append_images=gif[1:],
                    duration=125, loop=0)
        print(f"  Vorschau {name}: Tag/Nacht + GIF")
    overview()


def overview():
    """Alle Teile in 3x mit Namen, auf Gras."""
    items = ["tree_oak", "tree_willow", "tree_fir", "tree_dead", "tree_elder",
             "stump", "log", "bush_1", "bush_2", "bush_berries", "bush_lavender",
             "fern_1", "fern_2", "grass_tuft_1", "grass_tuft_2", "grass_tuft_3", "rock_1", "rock_2",
             "mushroom_moon", "mushroom_ember", "mushroom_ring", "flowers_lilac", "flowers_moon",
             "flowers_ember", "flowers_blood"]
    font = ImageFont.truetype(str(ROOT / "assets/ui/fonts/m5x7.ttf"), 16)
    rows = [items[:5], items[5:11], items[11:18], items[18:21], items[21:]]
    grass = Image.open(GROUND / "ground_grass_1.png").convert("RGBA")
    row_imgs = []
    for row in rows:
        ims = [frame(n, 0) for n in row]
        widths = [max(im.width, int(font.getlength(n)) + 4) for n, im in zip(row, ims)]
        w = sum(cw + 8 for cw in widths) + 8
        h = max(im.height for im in ims) + 22
        c = Image.new("RGBA", (w, h))
        for y in range(0, h, 32):
            for x in range(0, w, 32):
                c.alpha_composite(grass, (x, y))
        x = 8
        d = ImageDraw.Draw(c)
        for n, im, cw in zip(row, ims, widths):
            c.alpha_composite(im, (x + (cw - im.width) // 2, h - 16 - im.height))
            d.text((x, h - 14), n, font=font, fill=(234, 223, 203))
            x += cw + 8
        row_imgs.append(c)
    W = max(r.width for r in row_imgs)
    H = sum(r.height + 4 for r in row_imgs)
    out = Image.new("RGBA", (W, H), (14, 10, 20, 255))
    y = 0
    for r in row_imgs:
        out.alpha_composite(r, (0, y))
        y += r.height + 4
    out.resize((W * 3, H * 3), Image.NEAREST).save(OUT / "uebersicht_flora_3x.png")
    print("  Übersicht: uebersicht_flora_3x.png")


if __name__ == "__main__":
    main()
