"""Macht aus den Wasserkacheln (water_placeholder.png, 4 Kacheln nebeneinander)
eine Animation mit 4 Frames: water_animated.png, Frames untereinander.

Jede Kachel wird pro Frame ein Stück verschoben (mit Umbruch innerhalb der
Kachel), so ziehen Lichtstreifen und Wellenmuster langsam weiter. Es entstehen
keine neuen Farben, die Kacheln bleiben in sich nahtlos.

Aufruf (nach jeder Änderung an water_placeholder.png):
    python docs/art/ref_converter/animate_water.py
"""

from pathlib import Path

from PIL import Image

WATER = Path(__file__).resolve().parents[3] / "assets" / "environment" / "water"
TILE = 32
FRAMES = 4
# Verschiebung pro Frame (x, y) je Kachel: tief, Ufer, flach, Durchgang.
# Flaches Wasser zieht schneller, tiefes kaum.
SHIFT = [(1, 0), (1, 1), (2, 0), (1, 0)]


def main() -> None:
    source = Image.open(WATER / "water_placeholder.png").convert("RGBA")
    columns = source.width // TILE
    out = Image.new("RGBA", (source.width, TILE * FRAMES))
    for column in range(columns):
        tile = source.crop((column * TILE, 0, column * TILE + TILE, TILE))
        dx, dy = SHIFT[column] if column < len(SHIFT) else (1, 0)
        for frame in range(FRAMES):
            shifted = Image.new("RGBA", (TILE, TILE))
            for y in range(TILE):
                for x in range(TILE):
                    shifted.putpixel(((x + dx * frame) % TILE, (y + dy * frame) % TILE), tile.getpixel((x, y)))
            out.paste(shifted, (column * TILE, frame * TILE))
    out.save(WATER / "water_animated.png")
    print("water_animated.png:", out.size)


if __name__ == "__main__":
    main()
