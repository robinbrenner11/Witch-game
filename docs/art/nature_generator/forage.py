"""Sammelobjekte für den Wald (Bitterbloom): Pilz, Beerenstrauch, Feder, Moosstein.

Aufruf (aus dem Projektordner):
    python docs/art/nature_generator/forage.py

Für jedes Objekt:
  assets/environment/forage/forage_<name>.png          Weltgrafik, 4 Frames:
        0-1 ruhig, 2 großes Glitzern, 3 kleines Glitzern (2 FPS, Loop) –
        das Glitzern verrät: hier kann man etwas einsammeln.
  assets/environment/forage/forage_<name>_picked.png   nur Strauch und Moosstein
        (bleiben nach dem Pflücken leer stehen; Pilz und Feder verschwinden)
  assets/items/forage_<name>.png                        Inventar-Icon 16x16
Die Dateinamen sind neutral – Name und Wirkung im Spiel entscheidet Robin.
"""
import math
from nature import Layer, foliage, blobs, save, noise, _hash, ROOT

FORAGE = "assets/environment/forage"
ITEMS = "assets/items"
LEAF = ["L0", "L1", "GD", "L3"]


def glint_frames(base, gx, gy):
    """4 Frames aus einer fertigen Layer: ruhig, ruhig, großes, kleines Glitzern.
    Das Glitzern liegt über der Kontur (wird nach outline() gesetzt)."""
    frames = []
    for st in (0, 0, 2, 1):
        f = base.copy()
        if st >= 1:
            f.set(gx, gy, "LK")
        if st == 2:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                f.set(gx + dx, gy + dy, "GOLDH")
            for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
                f.set(gx + dx, gy + dy, "GOLDD")
        frames.append(f.image())
    return frames


def draw(t, rows, cmap, ox, oy):
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                t.set(ox + x, oy + y, cmap[ch])


# ---------------------------------------------------------------------------
# Pilz (Röhrling): dicke, dunkle Bordeaux-Kappe, ockerfarbener Stiel mit rotem Netz
def bolete(t, x, y, w, stem_h):
    """x, y = Fußpunkt; w = halbe Kappenbreite."""
    sw = max(1, w // 3)
    for k in range(stem_h):                                  # blasser Stiel, unten bauchig
        bulge = 1 if k < stem_h // 2 else 0
        for dx in range(-sw - bulge, sw + bulge + 1):
            c = "KN" if dx < 0 else "LS"
            if (dx * 2 + k) % 4 == 0 and k > 0 and dx >= 0:
                c = "LST"                                     # feines Netz
            t.set(x + dx, y - k, c)
    cy = y - stem_h
    hc = max(2, w)
    for dy in range(-hc, 1):
        for dx in range(-w - 1, w + 2):
            ex, ey = dx / (w + 0.8), (dy - 0.3) / (hc + 0.5)
            if ex * ex + ey * ey > 1:
                continue
            lit = -ex * 0.6 - ey * 0.8
            c = "BORH" if lit > 0.75 else ("BOR" if lit > 0.05 else "BORD")
            if dy == 0:
                c = "GOLDD"                                   # Röhren an der Unterseite
            t.set(x + dx, cy + dy, c)
    t.set(x - w // 2, cy - hc + 1, "KN")                      # Glanz


def forage_mushroom():
    t = Layer(24, 20)
    bolete(t, 16, 19, 4, 3)
    bolete(t, 9, 19, 6, 4)
    bolete(t, 3, 19, 2, 2)
    for x in (2, 3, 13, 14, 19, 20):                          # etwas Moos am Fuß
        t.set(x, 19, "GD")
    t.outline()
    return glint_frames(t, 6, 5)


def icon_mushroom():
    t = Layer(16, 16)
    bolete(t, 6, 14, 6, 4)
    bolete(t, 13, 14, 2, 2)
    return [t.outline().image()]


# ---------------------------------------------------------------------------
# Beerenstrauch mit blassen, geisterblauen Beeren (leuchten nachts ganz leicht)
BERRIES = [(9, 15), (14, 11), (20, 14), (12, 21), (18, 20), (24, 19), (7, 22), (16, 16)]


def berry_bush(with_berries=True):
    t = Layer(32, 32)
    foliage(t, [(16, 20, 11), (9, 24, 7), (23, 24, 7)], LEAF, seed=501, clump=(2.0, 3.2),
            accent="G", accent_at=0.92)
    t.cleanup(keep=("G",))
    if with_berries:
        for i, (x, y) in enumerate(BERRIES):
            for dx, dy, c in ((0, 0, "GEI"), (1, 0, "NBH"), (0, 1, "NBH"), (1, 1, "GEI")):
                t.set(x + dx, y + dy, c)
            t.set(x, y, "EIS")
            if i % 3 == 0:
                t.set(x, y, "GK")
    else:
        for x, y in BERRIES[::2]:                              # leere Stielchen
            t.set(x, y + 1, "GD")
    return t.outline()


def forage_berries():
    return glint_frames(berry_bush(True), 14, 10)


def icon_berries():
    """Traube aus runden, geisterblauen Beeren mit Stiel und Blatt."""
    t = Layer(16, 16)
    berry = [".eg.", "eggn", "ggnn", ".nn."]
    for x, y in ((3, 5), (7, 4), (10, 6), (5, 8), (9, 9), (3, 10), (7, 11)):
        draw(t, berry, {"e": "EIS", "g": "GEI", "n": "NBH"}, x - 1, y - 1)
    for x, y in ((8, 1), (8, 2), (8, 3)):
        t.set(x, y, "GD")
    for x, y in ((9, 1), (10, 1), (11, 2), (10, 2)):
        t.set(x, y, "L3")
    t.set(6, 4, "GK"); t.set(4, 9, "GK")
    return [t.outline().image()]


# ---------------------------------------------------------------------------
# Rabenfeder: schwarz mit blau-violettem Schimmer, liegt schräg am Boden
FEATHER = [
    "...........vs.",
    ".........vvVsa",
    "........vvVvsa",
    ".......vvVvsaa",
    "......vvVvsaa.",
    ".....vvVvsaa..",
    "....vvVvsaa...",
    "...vvVvsaa....",
    "..vvVvsaa.....",
    "..vvvsaa......",
    "..vvsa........",
    ".ss...........",
    "s.............",
]


def forage_feather():
    t = Layer(16, 16)
    draw(t, FEATHER, {"v": "NV", "V": "INDH", "a": "TS", "s": "LST"}, 1, 2)
    t.set(6, 9, "MG"); t.set(10, 5, "NBH")                     # Schimmer
    t.outline()
    return glint_frames(t, 11, 4)


def icon_feather():
    t = Layer(16, 16)
    draw(t, FEATHER, {"v": "NV", "V": "INDH", "a": "TS", "s": "LS"}, 1, 1)
    t.set(6, 8, "MG"); t.set(10, 4, "NBH"); t.set(8, 6, "IND")
    return [t.outline().image()]


# ---------------------------------------------------------------------------
# Mondmoos: Moospolster auf einem Stein, die Spitzen schimmern silbrig
def moss_stone(with_moss=True):
    t = Layer(24, 18)
    blobs(t, [(12, 12, 7), (7, 13, 5), (17, 13, 5)], ["K1", "K2", "K3", "KR2"],
          seed=511, edge=0.5, clump=4, clump_amt=0.1, ao=0.3)
    if with_moss:
        for x in range(3, 22):
            top = 3 + int(3 * abs(x - 12) / 7) + int(1.5 * noise(x, 0, 3, 512))
            for y in range(top, top + 5 + (1 if 7 < x < 17 else 0)):
                c = "L3" if y <= top + 1 else ("GD" if y < top + 4 else "L1")
                if y == top and (x * 3) % 4 == 0:
                    c = "SM"                                   # silbrige Spitzen
                elif y <= top + 1 and x % 3 == 1:
                    c = "W3"
                t.set(x, y, c)
    else:
        for x, y in ((8, 9), (14, 8), (16, 10)):               # Reste
            t.set(x, y, "GD")
    return t.cleanup(keep=("SM", "W3")).outline()


def forage_moss():
    return glint_frames(moss_stone(True), 15, 3)


def icon_moss():
    """Moosballen: gewölbtes Polster mit silbrigen Spitzen, unten Erdkrume."""
    t = Layer(16, 16)
    for y in range(3, 14):
        for x in range(1, 15):
            d = math.hypot((x - 7.5) / 6.8, (y - 9) / 5.2)
            if d > 1 or y > 12:
                continue
            lit = -(x - 7.5) / 6.8 * 0.6 - (y - 9) / 5.2 * 0.8
            c = "L3" if lit > 0.3 else ("GD" if lit > -0.35 else "L1")
            if y < 8 and (x * 3 + y) % 5 == 0:
                c = "SM"
            elif y < 9 and (x + y) % 4 == 0:
                c = "W3"
            t.set(x, y, c)
    for x in range(3, 13):
        t.set(x, 13, "E2" if x % 3 else "E3")
    return [t.cleanup(keep=("SM", "W3")).outline().image()]


def main():
    save(FORAGE, "forage_mushroom", forage_mushroom())
    save(FORAGE, "forage_berries", forage_berries(), glow=("EIS", "GK"))
    save(FORAGE, "forage_berries_picked", [berry_bush(False).image()])
    save(FORAGE, "forage_feather", forage_feather(), foot=False)
    save(FORAGE, "forage_moss", forage_moss(), glow=("SM",))
    save(FORAGE, "forage_moss_picked", [moss_stone(False).image()])
    save(ITEMS, "forage_mushroom", icon_mushroom(), foot=False)
    save(ITEMS, "forage_berries", icon_berries(), foot=False)
    save(ITEMS, "forage_feather", icon_feather(), foot=False)
    save(ITEMS, "forage_moss", icon_moss(), foot=False)


if __name__ == "__main__":
    main()
