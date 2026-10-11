"""Platzhalter-Icons für die Kampftränke (11.10.2026).

Färbt die Flüssigkeit des Wachstumstranks (assets/items/potion_growth.png) in
neue Farben um. Nur bis Robin eigene Icons zeichnet; dann diese Dateien
einfach überschreiben.

Aufruf aus dem Projektordner:  python docs/art/item_generators/combat_potions_platzhalter.py
"""
from PIL import Image

SOURCE = "assets/items/potion_growth.png"
# Flüssigkeit im Wachstumstrank: dunkel, mittel, hell
LIQUID = ["#244a3a", "#3f7d5a", "#62a06e"]
TARGETS = {
    # Heiltrank: Bordeaux-Rot wie die Lebensleiste
    "potion_mending": ["#6e1830", "#a3243c", "#d4475e"],
    # Glutbombe: Glut und Kerzenlicht
    "potion_ember_bomb": ["#9c4a24", "#e07a35", "#ffb566"],
    # Dornennebel: Oliv wie die Würge-Ranken der Bitterblüte
    "potion_thorn_mist": ["#2b3a1e", "#5c7a2e", "#9db04a"],
}


def hex_to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


source = Image.open(SOURCE).convert("RGBA")
for name, colors in TARGETS.items():
    mapping = {hex_to_rgb(a): hex_to_rgb(b) for a, b in zip(LIQUID, colors)}
    image = source.copy()
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a and (r, g, b) in mapping:
                pixels[x, y] = mapping[(r, g, b)] + (a,)
    image.save(f"assets/items/{name}.png")
    print("geschrieben:", name)
