"""Licht-Texturen für PointLight2D im Pixel-Look: weiß, Alpha in harten Stufen
(keine weichen Verläufe), Farbe kommt in Godot über PointLight2D.color.
Dazu eine Nachtszene als Vorschau (simuliert CanvasModulate + additive Lichter).
Aufruf: python lights.py <ausgabeordner> <ordner_mit_bodentiles> <ordner_mit_pflanzen>
"""
import sys, os
import numpy as np
from PIL import Image

BANDS = [(0.25, 1.0), (0.5, 0.62), (0.75, 0.32), (1.0, 0.12)]   # (Radiusanteil, Alpha)


def banded(size, bands=BANDS, dither=True):
    r = size / 2
    y, x = np.mgrid[0:size, 0:size]
    d = np.hypot(x + 0.5 - r, y + 0.5 - r) / r
    a = np.zeros((size, size))
    for lim, al in reversed(bands):
        a[d <= lim] = al
    if dither:
        # Schachbrett-Dither genau auf den Stufengrenzen -> weicher, aber pixelig
        chk = ((x + y) % 2 == 0)
        for (lim, al), (_, nxt) in zip(bands, bands[1:] + [(0, 0.0)]):
            ring = (d > lim - 0.5 / r * 1.5) & (d <= lim) & chk
            a[ring] = nxt
    img = np.zeros((size, size, 4), np.uint8)
    img[..., :3] = 255
    img[..., 3] = (a * 255).round().astype(np.uint8)
    return Image.fromarray(img, "RGBA")


def main(out, ground, plants):
    os.makedirs(out, exist_ok=True)
    tex = {}
    for s in (32, 64, 128):
        tex[s] = banded(s)
        tex[s].save(os.path.join(out, f"light_round_{s}.png"))
    # kleines "Glimmen" (Augen, Funken): nur 2 Stufen
    glim = banded(16, [(0.4, 1.0), (1.0, 0.35)], dither=False)
    glim.save(os.path.join(out, "light_glimmer_16.png"))

    # -------------------------------------------- Nachtszene-Vorschau
    T = 32
    W_, H_ = 12, 7
    tile = lambda n: np.array(Image.open(os.path.join(ground, n + ".png")).convert("RGB"), float)
    base = np.zeros((H_ * T, W_ * T, 3))
    for cy in range(H_):
        for cx in range(W_):
            base[cy * T:(cy + 1) * T, cx * T:(cx + 1) * T] = tile(f"ground_grass_{1 + (cx * 7 + cy * 3) % 3}")
    for cx in range(2, 10):
        base[3 * T:4 * T, cx * T:(cx + 1) * T] = tile(f"ground_bed_{1 + cx % 3}")
    base[3 * T:4 * T, 1 * T:2 * T] = tile("ground_soil_1")
    base[3 * T:4 * T, 10 * T:11 * T] = tile("ground_soil_2")
    img = Image.fromarray(base.astype(np.uint8)).convert("RGBA")
    names = ["moon_chalice", "lantern_berry", "mandrake", "nightshade", "blood_rose", "ghost_fern"]
    for i, n in enumerate(names):
        sheet = Image.open(os.path.join(plants, f"{n}_stages.png")).convert("RGBA")
        img.alpha_composite(sheet.crop((96, 0, 128, 48)), ((3 + i) * T, 3 * T - 16))
    lit = np.array(img.convert("RGB"), float) / 255

    # Godot: Ergebnis ≈ Basis * (CanvasModulate + Σ Lichtfarbe * Energie * Texturalpha)
    modulate = np.array([0.40, 0.36, 0.56])
    light = np.zeros_like(lit) + modulate
    def add(cx, cy, size, color, energy):
        a = np.array(tex[size])[..., 3] / 255.0
        col = np.array(color) / 255.0
        x0, y0 = cx - size // 2, cy - size // 2
        for yy in range(size):
            for xx in range(size):
                X, Y = x0 + xx, y0 + yy
                if 0 <= X < W_ * T and 0 <= Y < H_ * T and a[yy, xx] > 0:
                    light[Y, X] += col * energy * a[yy, xx]
    add(3 * T + 16, 3 * T - 8, 64, (169, 155, 224), 1.6)    # Mondkelch: Flieder
    add(4 * T + 24, 3 * T, 128, (255, 181, 102), 1.5)       # Laternenbeere: Kerzenlicht
    add(5 * T + 16, 3 * T + 10, 32, (228, 88, 177), 1.4)    # Alraune: Magenta (Augen)
    add(8 * T + 16, 3 * T + 8, 64, (120, 140, 185), 1.2)    # Geisterfarn: Geisterblau
    night = np.clip(lit * light, 0, 1)
    # Vergleich: oben Tag (ohne Modulate), unten Nacht mit Lichtern
    day = (lit * 255).astype(np.uint8)
    nig = (night * 255).astype(np.uint8)
    gap = np.full((8, W_ * T, 3), 14, np.uint8)
    crop = lambda a: a[1 * T:6 * T, 1 * T:11 * T]
    comp = np.concatenate([crop(day), gap[:, :10 * T], crop(nig)], 0)
    Image.fromarray(comp).resize((comp.shape[1] * 3, comp.shape[0] * 3), Image.NEAREST).save(
        os.path.join(out, "vorschau_nacht_3x.png"))
    # Texturen-Übersicht
    sheet = Image.new("RGBA", (32 + 64 + 128 + 16 + 5 * 8, 128 + 16), (14, 10, 20, 255))
    x = 8
    for im in (glim, tex[32], tex[64], tex[128]):
        sheet.alpha_composite(im, (x, 8)); x += im.width + 8
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(os.path.join(out, "vorschau_lichttexturen_3x.png"))


if __name__ == "__main__":
    main(*sys.argv[1:4])
