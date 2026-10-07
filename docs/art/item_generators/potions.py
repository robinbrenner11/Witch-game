"""Trank-Icons 16x16 (gleiche Familie wie potion_growth / potion_sludge).
Aufruf: python potions.py <ausgabeordner> [vorschauordner]

Jede Flasche ist ein ASCII-Raster. Licht kommt von oben links: Glanz links,
Schattenseite rechts. Neben der Hexen-Palette gibt es ein paar Zwischentöne
(mit "neu" markiert), damit die Füllungen weicher abgestuft wirken.
"""
import sys, os
from PIL import Image

PAL = {
    # Basis (hexen_palette.gpl)
    "a": (43, 22, 51),     # Aubergine – Kontur
    "n": (20, 27, 58),     # Nachtblau – Glasrand
    "w": (234, 223, 203),  # Knochen – Glanz
    "e": (74, 43, 39),     # Haut mittel – Korken dunkel
    "h": (107, 63, 51),    # Haut licht – Korken
    "H": (138, 82, 64),    # Haut Highlight – Korken hell
    "g": (217, 164, 65),   # Gold
    "i": (46, 42, 107),    # Indigo
    "I": (74, 69, 150),    # Indigo hell
    "U": (120, 140, 185),  # Geisterblau
    "l": (169, 155, 224),  # Flieder
    # neu
    "N": (31, 36, 74),     # leeres Glas, etwas heller als der Rand
    "o": (156, 104, 52),   # Gold dunkel (Schattenseite des Rings)
    "p": (206, 214, 244),  # Eisblau hell
    "s": (255, 246, 220),  # Lichtkern, warmweiß
    "G": (63, 125, 90),    # Giftgrün (Basis)
    "q": (36, 74, 58),     # Giftgrün dunkel (Basis)
    "Q": (98, 160, 110),   # Giftgrün hell (Basis)
    "v": (214, 232, 222),  # neu: Silber-Mondlicht
    "k": (14, 10, 20),     # Tiefschwarz (Basis)
    "K": (26, 20, 46),     # neu: Nachtviolett, Schattenseite der Ewigen Nacht
    "b": (110, 24, 48),    # Bordeaux (Basis)
    "d": (77, 18, 48),     # Bordeaux dunkel (Basis)
    "B": (150, 44, 72),    # neu: Bordeaux hell (Siegel-Glanz)
}

S = 16

POTIONS = {
    # Irrlicht: kleines Tropfen-Fläschchen, ein heller Kern, zwei Funken schweben heraus
    "potion_will_o_wisp": [
        "................",
        ".....aaaaaa.....",
        ".....aHHheal....",
        ".....aHhhea..U..",
        ".....agggoa.....",
        "......anna..p...",
        ".....anwNna.....",
        "....anwNNNna....",
        "....anNNNNna....",
        "....anllUUna....",
        "...anlpslUIna...",
        "...anlssUUIna...",
        "...anUlUUIina...",
        "....anIIiina....",
        ".....aannaa.....",
        "................",
    ],
    # Mondernte: breite, bauchige Flasche, kurzer Hals, goldene Mondsichel, Silberfunke
    "potion_moon_harvest": [
        "................",
        "................",
        "......aaaa......",
        "......aHea......",
        "......agoa......",
        ".....annnna.....",
        "...aannwNNnaa...",
        "..anwNNNNNNNna..",
        ".anwQQQQQGGGqna.",
        ".anQQGggGGGGqna.",
        ".anQGgGGGGvGqna.",
        ".anGGggGGGGqqna.",
        ".anGGGGGGGqqqna.",
        "..anqGGGGqqqna..",
        "...aannnnnnaa...",
        "................",
    ],
    # Flüssiges Mondlicht: schlanke, hohe Phiole, goldener Stopfen und Fuß
    "potion_liquid_moonlight": [
        "......aaaa......",
        "......agga......",
        ".....aggooa.....",
        "......anna......",
        "......anna......",
        ".....anwNna.....",
        "....anwpppna....",
        "....anpsplna....",
        "....anppllna....",
        "....anpllUna....",
        "....anllUUna....",
        "....anlUUIna....",
        "....anUUIIna....",
        "....anIIiina....",
        ".....aoggoa.....",
        "......aaaa......",
    ],
    # Ewige Nacht: kantige Rautenflasche, fast schwarzer Inhalt mit Sternen, Bordeaux-Siegel
    "potion_endless_night": [
        "................",
        ".....aaaaaa.....",
        ".....aBbbda.....",
        ".....abbdda.....",
        "......anna......",
        "......abda......",
        ".....anwNna.....",
        "....anwIiina....",
        "...anwIikKina...",
        "..anIikkskKina..",
        "..anilkkkKKina..",
        "...anikKKKina...",
        "....aniKKina....",
        ".....anIina.....",
        "......aaaa......",
        "................",
    ],
}

VARIANTS = {}


def to_image(rows, extra=None):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        assert len(r) == S, (y, r, len(r))
        for x, ch in enumerate(r):
            if ch != ".":
                im.putpixel((x, y), PAL[ch] + (255,))
    for (x, y), ch in (extra or {}).items():
        im.putpixel((x, y), PAL[ch] + (255,))
    return im


def build():
    out = {name: to_image(rows) for name, rows in POTIONS.items()}
    for name, (base, extra) in VARIANTS.items():
        out[name] = to_image(POTIONS[base], extra)
    return out


def main(out_dir, preview_dir=None):
    imgs = build()
    for name, im in imgs.items():
        if name in POTIONS:
            im.save(os.path.join(out_dir, name + ".png"))
    if preview_dir:
        save_preview(imgs, preview_dir)


def save_preview(imgs, preview_dir, scale=8):
    """Vergleich mit den bestehenden Tränken auf dunklem Hotbar-Grund."""
    root = os.path.join(os.path.dirname(__file__), "..", "..", "..")
    names = ["potion_growth", "potion_sludge"] + list(imgs)
    tiles = []
    for n in names:
        if n in imgs:
            tiles.append(imgs[n])
        else:
            tiles.append(Image.open(os.path.join(root, "assets", "items", n + ".png")).convert("RGBA"))
    pad = 4
    w = len(tiles) * (S + pad) + pad
    sheet = Image.new("RGBA", (w, S + 2 * pad), (14, 10, 20, 255))
    for i, t in enumerate(tiles):
        sheet.alpha_composite(t, (pad + i * (S + pad), pad))
    sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST).save(
        os.path.join(preview_dir, "vorschau_traenke_8x.png"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
