"""Laternenpfahl (Platzhalter) für den Garten.

Die Laterne stammt aus Robins Uraltbaum (assets/environment/shelter/hollow_tree.png),
damit sie zum Stil der Vorlage passt; der Pfahl ist einfach dazugemalt.
Licht von oben links: linke Pfahlkante hell, rechte dunkel.
Aufruf im Projektordner: python docs/art/nature_generator/lantern_post.py
"""
from PIL import Image

TREE = "assets/environment/shelter/hollow_tree.png"
TREE_GLOW = "assets/environment/shelter/hollow_tree_glow.png"
OUT = "assets/environment/props/lantern_post.png"
OUT_GLOW = "assets/environment/props/lantern_post_glow.png"

# Ausschnitt der Laterne im Baum (ohne Haken).
LANTERN_BOX = (60, 175, 67, 187)
W, H = 11, 38

OUTLINE = (43, 22, 51, 255)      # Aubergine
WOOD_LIGHT = (110, 70, 40, 255)
WOOD = (74, 43, 39, 255)
WOOD_DARK = (46, 26, 28, 255)
STONE_LIGHT = (89, 102, 128, 255)
STONE = (58, 62, 92, 255)

tree = Image.open(TREE).convert("RGBA")
tree_glow = Image.open(TREE_GLOW).convert("RGBA")
img = Image.new("RGBA", (W, H))
glow = Image.new("RGBA", (W, H))

lantern = tree.crop(LANTERN_BOX)
lantern_glow = tree_glow.crop(LANTERN_BOX)
lx = (W - lantern.width) // 2
img.alpha_composite(lantern, (lx, 0))
glow.alpha_composite(lantern_glow, (lx, 0))

top = lantern.height
# Pfahl: 3 px breit, mit Kontur links und rechts.
for y in range(top, H - 2):
    img.putpixel((3, y), OUTLINE)
    img.putpixel((4, y), WOOD_LIGHT)
    img.putpixel((5, y), WOOD)
    img.putpixel((6, y), WOOD_DARK)
    img.putpixel((7, y), OUTLINE)
# Querbrett unter der Laterne.
for x in range(2, 9):
    img.putpixel((x, top), OUTLINE)
    img.putpixel((x, top + 1), WOOD_LIGHT if x < 6 else WOOD)
# Feldstein am Fuß.
for x in range(1, 10):
    img.putpixel((x, H - 3), STONE_LIGHT if x < 5 else STONE)
    img.putpixel((x, H - 2), STONE)
    img.putpixel((x, H - 1), OUTLINE)
img.putpixel((0, H - 2), OUTLINE)
img.putpixel((10, H - 2), OUTLINE)

img.save(OUT)
glow.save(OUT_GLOW)
print("gespeichert:", OUT, OUT_GLOW)
