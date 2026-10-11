"""Platzhalter-Icon für die Sichel-Form von Digitalis (11.10.2026).

Zeichnet einen Sichelmond mit Magenta-Schneide an einem kurzen Goldgriff,
16×16 wie digitalis_icon.png. Die Kampfleiste zeigt es im Kampf. Nur bis
Robin ein eigenes Icon zeichnet; dann die Datei einfach überschreiben.

Aufruf aus dem Projektordner:  python docs/art/item_generators/sickle_icon_platzhalter.py
"""
import math

from PIL import Image

OUT = "assets/items/digitalis/digitalis_sickle_icon.png"
SIZE = 16
PALETTE = {
    "a": "#2b1633",  # Umriss (Aubergine)
    "p": "#eadfcb",  # Klinge, Licht von oben links (Knochen)
    "m": "#c6b8be",  # Klinge im Schatten
    "g": "#e458b1",  # Schneide (Magie)
    "s": "#4e3440",  # Stängel
    "o": "#d9a441",  # Griff (Gold)
    "q": "#9c6834",  # Griff im Schatten
    "r": "#f4cc78",  # Glanz am Griff
}

grid = [["." for _ in range(SIZE)] for _ in range(SIZE)]
# Klinge: großer Kreis minus versetzter kleiner Kreis ergibt den Sichelmond.
cx, cy, outer = 8.6, 8.0, 6.4
ix, iy, inner = 9.9, 9.6, 4.5
for y in range(SIZE):
    for x in range(SIZE):
        px, py = x + 0.5, y + 0.5
        if (math.hypot(px - cx, py - cy) <= outer and math.hypot(px - ix, py - iy) > inner
                and py <= 11.6 and not (px < cx - 1 and py > 10.6)):
            if math.hypot(px - ix, py - iy) <= inner + 0.9:
                grid[y][x] = "g"
            elif px + py < cx + cy - 2.0:
                grid[y][x] = "p"
            else:
                grid[y][x] = "m"
# Stängel und Griff diagonal nach unten links.
for (x, y), color in zip([(1, 14), (2, 13), (3, 12), (4, 11), (5, 10)], "qooss"):
    grid[y][x] = color
grid[13][3] = "r"
# Umriss um alles, was gefüllt ist.
outlined = [row[:] for row in grid]
for y in range(SIZE):
    for x in range(SIZE):
        if grid[y][x] != ".":
            continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < SIZE and 0 <= ny < SIZE and grid[ny][nx] != ".":
                outlined[y][x] = "a"
                break

image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
for y in range(SIZE):
    for x in range(SIZE):
        key = outlined[y][x]
        if key != ".":
            value = PALETTE[key].lstrip("#")
            image.putpixel((x, y), tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (255,))
image.save(OUT)
print("geschrieben:", OUT)
