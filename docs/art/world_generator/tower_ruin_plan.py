"""Bauplan Turmruine (28x22): erhöhtes Turmfundament (Höhe 2, Mauer) in der
Mitte, Treppe im Süden; drumherum Erde und ein Trampelpfad vom Nordeingang."""
import math, random
from PIL import Image
W, H = 28, 22
OUT = "tools/world_builder/plans/tower_ruin/"
GRAY, WHITE = (128,128,128,255), (255,255,255,255)
PATH, SLAB, EARTH, FOREST = (153,115,76,255), (89,102,128,255), (74,51,41,255), (56,33,51,255)
WALL = (110,24,48,255)
STAIR, STONE = (217,164,65,255), (234,223,203,255)
height = Image.new("RGBA", (W,H), GRAY)
ground = Image.new("RGBA", (W,H), EARTH)
material = Image.new("RGBA", (W,H), (0,0,0,0))
marks = Image.new("RGBA", (W,H), (0,0,0,0))
cx, cy, rx, ry = 13.5, 10.5, 8.2, 6.6
rng = random.Random(4)
for y in range(H):
    for x in range(W):
        # Rand: dunkler Waldboden, damit die Ruine in der Mitte heraussticht
        if x < 2 or x > W-3 or y > H-3:
            ground.putpixel((x,y), FOREST)
        d = ((x+0.5-cx)/rx)**2 + ((y+0.5-cy)/ry)**2
        if d <= 1.0:
            height.putpixel((x,y), WHITE)
            material.putpixel((x,y), WALL)
            # Alter Turmboden aus Platten, zur Mitte hin aufgebrochen (Erde)
            ground.putpixel((x,y), SLAB)
# Trampelpfad: vom Nordeingang links um die Ruine herum zur Treppe im Süden
pts = [(13,0),(13,2),(8,3),(4,6),(3,11),(5,16),(9,18),(13,18)]
for (x0,y0),(x1,y1) in zip(pts, pts[1:]):
    n = max(abs(x1-x0), abs(y1-y0))
    for i in range(n+1):
        x = round(x0 + (x1-x0)*i/n); y = round(y0 + (y1-y0)*i/n)
        for dx in (0,1):
            if height.getpixel((x+dx,y)) == GRAY:
                ground.putpixel((x+dx,y), PATH)
# Treppe in der untersten Reihe der Plattform, zwei Spalten breit
bottom = max(y for y in range(H) if height.getpixel((13,y)) == WHITE)
for x in (13,14):
    marks.putpixel((x,bottom), STAIR)
# Steine (keine Bäume: im Epizentrum wächst nichts mehr)
for x,y in [(1,1),(25,2),(22,19),(2,19),(24,12),(19,1),(6,20),(26,7)]:
    if height.getpixel((x,y)) == GRAY:
        marks.putpixel((x,y), STONE)
for name, im in [("height",height),("ground",ground),("material",material),("marks",marks)]:
    im.save(OUT + name + ".png")
for y in range(H):
    print("".join("#" if height.getpixel((x,y))==WHITE else ("=" if marks.getpixel((x,y))[3] else ("." if ground.getpixel((x,y))!=PATH else "p")) for x in range(W)))
print("Treppe Reihe", bottom)
