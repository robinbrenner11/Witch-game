"""Garten-Grundausstattung (Bitterbloom): Holunder, Nachtlavendel, Blumenbüschel,
Zaun als Autotile.

Aufruf (aus dem Projektordner):
    python docs/art/nature_generator/garden.py               # alles
    python docs/art/nature_generator/garden.py tree_elder    # nur eins

Ausgabe: assets/environment/flora/  und  assets/environment/props/fence_atlas.png
"""
import math
import sys
from PIL import Image
from nature import (Layer, foliage, limb, save, check, noise, SWAY, _hash, ROOT, BARK,
                    crown_sway, SWAY8_TOP, SWAY8_MID)

FLORA = "assets/environment/flora"
WOOD = ["E1", "E2", "E3", "E4"]
LEAF = ["L0", "L1", "GD", "L3"]
S = 1.5                     # wie im Wald: Entwurf im kleinen Raster, neu gezeichnet in 1,5x


def X(v):
    return (v + 0.5) * S - 0.5


def sp(points):
    return [(X(x), X(y), w * S) for x, y, w in points]


def ms(circles):
    return [(X(x), X(y), r * S) for x, y, r in circles]


# Holunder – der klassische Hexenbaum: mehrere Stämmchen, flache weiße Blütendolden
def tree_elder():
    """Holunder: mehrere Stämmchen, luftige Krone aus kleinen Blattgruppen mit
    Lücken (man sieht die Äste), flache weiße Blütendolden. 8 Frames."""
    W, H = 72, 96
    bark = BARK["elder"]
    trunk = Layer(W, H)
    for pts in ([(23, 63, 2.4), (21, 52, 1.8), (16, 40, 1.4), (13, 30, 1.0), (10, 22, 0.7)],
                [(25, 63, 2.2), (26, 50, 1.7), (31, 38, 1.3), (35, 29, 1.0), (39, 21, 0.7)],
                [(24, 62, 1.8), (24, 48, 1.4), (23, 34, 1.0), (24, 20, 0.7)],
                [(16, 40, 0.9), (8, 34, 0.6)], [(31, 38, 0.9), (40, 34, 0.6)]):
        limb(trunk, sp(pts), bark, bark=False)
    limb(trunk, sp([(22, 62, 1.0), (18, 63, 0.6)]), bark, bark=False)
    limb(trunk, sp([(26, 62, 1.0), (30, 63, 0.6)]), bark, bark=False)
    # Korkwarzen: helle Punkte auf der Rinde (typisch für Holunder)
    for y in range(40, 94, 5):
        for x in range(20, 52):
            if trunk.get(x, y) in ("EL2", "EL3") and (x * 7 + y) % 11 == 0:
                trunk.set(x, y, "EL4")
    masses = ms([(14, 24, 10), (34, 23, 10), (24, 15, 10), (24, 29, 9), (6, 30, 5), (42, 30, 5)])
    umbels = [(18, 23), (36, 11), (53, 22), (28, 39), (47, 40), (13, 40), (60, 36), (39, 28),
              (25, 15), (8, 30)]
    top = min(y - r for _, y, r in masses)
    bottom = max(y + r for _, y, r in masses)
    frames = []
    for fr in range(8):
        sway = crown_sway(fr)
        crown = Layer(W, H)
        # luftig: wenige, kleine Büschel -> Lücken, durch die Äste schauen
        foliage(crown, masses, LEAF, seed=101, clump=(2.0, 3.4), density=0.3,
                accent="G", accent_at=0.9, offset=sway)
        crown.cleanup(keep=("G",))
        for i, (ux, uy) in enumerate(umbels):              # Dolden schwingen mit
            ox = sway(ux, uy, top, bottom)
            w = 3 if i % 3 else 2
            for dy in range(-2, 1):
                for dx in range(-w, w + 1):
                    if dx * dx / (w + 0.5) ** 2 + (dy + 0.5) ** 2 / 2.6 > 1:
                        continue
                    if (dx + dy + i) % 2 == 0 or dy == 0:
                        lit = dx < 0 or dy < -1
                        crown.set(ux + dx + ox, uy + dy, "KN" if lit else "LS")
                    else:
                        crown.set(ux + dx + ox, uy + dy, "LST")
            crown.set(ux - 1 + ox, uy - 2, "KN")
        f = trunk.copy()
        f.paste(crown)
        frames.append(f.outline().image())
    return frames


# Nachtlavendel – graugrüner Horst mit vielen violetten Blütenähren, wiegt
def bush_lavender():
    W, H = 32, 32
    base = Layer(W, H)
    foliage(base, [(16, 27, 6), (10, 29, 4), (22, 29, 4)], ["L0", "L1", "W1", "W2"],
            seed=111, clump=(2.0, 3.0))
    base.cleanup()
    stems = []
    for i in range(11):
        x0 = 8 + i * 1.6 + (_hash(i, 1, 112) - 0.5) * 2
        h = int(11 + 9 * (1 - abs(x0 - 16) / 10) * (0.7 + 0.5 * _hash(i, 2, 112)))
        lean = (x0 - 16) * 0.35
        stems.append((x0, h, lean, i))
    frames = []
    for p in SWAY:
        st = Layer(W, H)
        spikes = Layer(W, H)
        for x0, h, lean, i in stems:
            for s in range(h):
                tt = s / h
                x = x0 + lean * tt + (p if tt > 0.6 else 0)
                y = 27 - s
                if tt < 0.62:
                    st.set(x, y, "W1" if i % 2 else "W2")
                else:                                  # Blütenähre
                    c = "FL" if (s + i) % 3 == 0 else ("INDH" if (s + i) % 3 == 1 else "IND")
                    if x < x0 + lean * tt + p * 0.5 and (s % 2 == 0):
                        c = "FL"
                    spikes.set(x, y, c)
                    if s % 2 == 0 and tt < 0.92:
                        spikes.set(x + 1, y, "INDH" if (i % 2) else "IND")
        f = Layer(W, H)
        f.paste(st)
        f.paste(base)
        spikes.outline()
        f.paste(spikes)
        f.outline()
        frames.append(f.image())
    return frames


# Blumenbüschel 32x32: Blatthorst unten, Stiele ohne Kontur, Blüten mit Kontur
# Blüten 5x5 (vorher 3x3 – in Spielgröße waren das nur Punkte). Zeichen:
# a = Licht, b = Schatten, c = Mitte/Glut, '.' = leer. Anker = Mitte oben.
BLOOM = {
    "bell": [".aab.", "aaabb", "aabbb", "abbbc", "a.b.c"],      # hängende Glocke
    "star": ["..a..", ".aab.", "aacbb", ".abb.", ".b.b."],      # Sternblüte mit Mitte
    "lantern": [".bb.", "baab", "bcab", "bacb", ".bb."],       # Lampion mit Glutkern
    "cup": ["a...b", "aa.bb", "acccb", ".abb.", "..b.."],      # offene Schale
}


def _flowers(shape, cols, seed):
    """cols = (Licht, Schatten, Mitte/Glut). Vier große Blüten auf einem Blatthorst."""
    base = Layer(32, 32)
    foliage(base, [(16, 27, 6), (10, 28, 4), (22, 28, 4)], LEAF, seed=seed, clump=(2.0, 3.0))
    base.cleanup()
    stems = Layer(32, 32)
    blooms = Layer(32, 32)
    heads = []
    for i in range(4):
        x = 8 + i * 5.3 + (_hash(i, 1, seed) - 0.5) * 2
        top = int(6 + 7 * abs(x - 16) / 9 + 3 * _hash(i, 2, seed))
        heads.append((int(round(x)), top))
    rows = BLOOM[shape]
    for i, (x, top) in enumerate(heads):
        for y in range(top + len(rows) - 1, 28):
            stems.set(x, y, "GD" if y < 24 else "L1")
        if i % 2 == 0:
            stems.set(x - 1, top + 8, "L3"); stems.set(x - 2, top + 7, "L3")    # Blättchen
        w = len(rows[0])
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != ".":
                    blooms.set(x - w // 2 + dx, top + dy, cols["abc".index(ch)])
    f = Layer(32, 32)
    f.paste(stems)
    f.paste(base)
    blooms.outline()
    f.paste(blooms)
    f.outline()
    return [f.image()]


def flowers_lilac():
    """Fliederglocken"""
    return _flowers("bell", ("FL", "INDH", "IND"), 121)


def flowers_moon():
    """Mondblumen: knochenweiße Sterne mit goldener Mitte"""
    return _flowers("star", ("KN", "LS", "GOLD"), 122)


def flowers_ember():
    """Glutlaternen: kleine Lampions mit warmem Kern"""
    return _flowers("lantern", ("KL", "GOLDD", "LK"), 123)


def flowers_blood():
    """Blutnelken: Bordeaux-Schalen mit Magenta-Herz"""
    return _flowers("cup", ("BORH", "BOR", "MH"), 124)


# ---------------------------------------------------------------------------
# Wildgras und Unkraut: räumbare Objekte (Stardew-Prinzip: Boden ruhig, Gras obendrauf)
def _wild(blades, seed, flower=None):
    """Dichter Halmbüschel. blades = Anzahl; Halme fächern vom Fuß nach außen."""
    frames = []
    spec = []
    for i in range(blades):
        t = i / (blades - 1)
        x0 = 9 + t * 14 + (_hash(i, 1, seed) - 0.5) * 3
        h = int(9 + 11 * (1 - abs(t - 0.5) * 1.4) * (0.7 + 0.5 * _hash(i, 2, seed)))
        lean = (t - 0.5) * 9 + (_hash(i, 3, seed) - 0.5) * 3
        spec.append((x0, h, lean, i))
    spec.sort(key=lambda b: -b[1])                     # lange Halme hinten
    for p in SWAY:
        t_ = Layer(32, 32)
        for x0, h, lean, i in spec:
            for k in range(h):
                tt = k / h
                x = x0 + lean * tt * tt + (p if tt > 0.55 else 0) + (p if tt > 0.85 else 0)
                y = 31 - k
                lit = lean < 0
                if tt < 0.3:
                    c = "L0" if i % 2 else "L1"
                elif tt < 0.6:
                    c = "GD" if lit else "L1"
                elif tt < 0.85:
                    c = "L3" if lit else "GD"
                else:
                    c = "G" if lit else "L3"
                t_.set(x, y, c)
                if tt < 0.45:                          # Halme sind unten breiter
                    t_.set(x + (1 if lean >= 0 else -1), y, "L1" if lit else "L0")
            if i % 5 == 0:
                t_.set(x0 + lean + p * 2, 31 - h, "GH")
        if flower:
            for fx, fy, a, b in flower:
                fx += p
                t_.set(fx, fy, a); t_.set(fx - 1, fy, b); t_.set(fx + 1, fy, b); t_.set(fx, fy - 1, b)
        frames.append(t_.outline().image())
    return frames


def wild_grass_1():
    return _wild(15, 201)


def wild_grass_2():
    return _wild(19, 202)


def wild_grass_3():
    """mit zwei kleinen Blüten (Knochen)"""
    return _wild(14, 203, flower=[(12, 12, "KN", "LS"), (21, 9, "KN", "LS")])


def weed_thistle():
    """Distel: stachelige Blätter, violetter Kopf. Wiegt kaum (steif)."""
    t = Layer(32, 32)
    foliage(t, [(16, 27, 6), (10, 28, 4), (22, 28, 4)], LEAF, seed=211, clump=(1.8, 2.6))
    for x, y in ((8, 25), (6, 27), (24, 25), (26, 27), (11, 23), (21, 23)):   # Blattstacheln
        t.set(x, y, "L3"); t.set(x - (1 if x < 16 else -1), y - 1, "GD")
    for k in range(13):                                # Stängel
        t.set(16, 25 - k, "GD"); t.set(17, 25 - k, "L1")
    for x, y in ((14, 19), (13, 18), (19, 17), (20, 16)):
        t.set(x, y, "L3")
    head = ["..i.i..", ".iIiIi.", "iIFFIii", ".iIIii.", "..ggg..", "..gGg.."]
    cmap = {"i": "IND", "I": "INDH", "F": "FL", "g": "GD", "G": "L3"}
    for dy, row in enumerate(head):
        for dx, ch in enumerate(row):
            if ch != ".":
                t.set(13 + dx, 7 + dy, cmap[ch])
    return [t.cleanup(keep=("FL", "INDH", "L3")).outline().image()]


def weed_dock():
    """Ampfer: breite, flache Blattrosette am Boden"""
    t = Layer(32, 32)
    leaves = [(-1.15, 13), (-0.55, 15), (0.05, 14), (0.6, 15), (1.15, 12)]
    for ang, L in leaves:
        for k in range(L):
            tt = k / L
            cx = 16 + math.sin(ang) * k * 1.1
            cy = 30.5 - math.cos(ang) * k * 0.8
            half = 3.4 * math.sin(math.pi * min(1, tt * 1.05 + 0.05))
            for o in range(-3, 4):
                if abs(o) > half:
                    continue
                px, py = cx + math.cos(ang) * o, cy + math.sin(ang) * o * 0.75
                lit = (o < 0) == (ang <= 0.2)
                c = "BORD" if abs(o) < 0.6 and tt > 0.15 else ("L3" if lit else "GD")
                if lit and abs(o) > half - 1 and k % 3 == 0:
                    c = "G"
                t.set(px, py, c)
    return [t.cleanup(keep=("BORD", "G")).outline().image()]


# ---------------------------------------------------------------------------
# Zaun als Autotile: 16 Kacheln (4x4), Index = links*1 + rechts*2 + oben*4 + unten*8.
# Jede Kachel wird mitten in einem 3x3-Ausschnitt mit ihren Nachbarn gemalt und
# dann ausgeschnitten, damit Riegel und Kontur über die Kachelgrenze lückenlos
# weiterlaufen.
POST_X = (14, 17)        # Pfosten x 14..17
POST_TOP, POST_FOOT = 9, 28
RAILS = ((14, 16), (21, 23))


def _post(t, ox, oy):
    for y in range(POST_TOP, POST_FOOT + 1):
        for x in range(POST_X[0], POST_X[1] + 1):
            k = ["E4", "E3", "E2", "E1"][x - POST_X[0]]
            if y == POST_TOP and x in (POST_X[0], POST_X[1]):
                continue                                  # angeschrägte Spitze
            if y == POST_TOP + 1 and x == POST_X[0]:
                k = "LST"
            t.set(ox + x, oy + y, k)
    t.set(ox + 15, oy + POST_FOOT - 4, "E2")              # Astloch


def _rail_h(t, ox, oy, x0, x1):
    for (ya, yb) in RAILS:
        for x in range(x0, x1 + 1):
            for y in range(ya, yb + 1):
                k = "E4" if y == ya else ("E3" if y < yb else "E2")
                if noise(ox + x, y, 1.0, 5) > 0.85 and y != ya:
                    k = "E2"
                t.set(ox + x, oy + y, k)


def _rail_v(t, ox, oy, y0, y1):
    for y in range(y0, y1 + 1):
        t.set(ox + 15, oy + y, "E3")
        t.set(ox + 16, oy + y, "E2")


def _fence_piece(t, ox, oy, mask):
    L, R, U, D = mask & 1, mask & 2, mask & 4, mask & 8
    if U:
        _rail_v(t, ox, oy, -6, POST_TOP + 2)
    if D:
        _rail_v(t, ox, oy, POST_FOOT - 2, 31 + 12)
    if L:
        _rail_h(t, ox, oy, -3, POST_X[0] - 1)
    if R:
        _rail_h(t, ox, oy, POST_X[1] + 1, 34)
    _post(t, ox, oy)


def fence_atlas():
    atlas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    tiles = []
    opposite = {1: 2, 2: 1, 4: 8, 8: 4}
    offs = {1: (-32, 0), 2: (32, 0), 4: (0, -32), 8: (0, 32)}
    for mask in range(16):
        t = Layer(96, 96)
        # Nachbarn zuerst (nur der Teil, der zu uns zeigt), oben liegende zuerst
        for bit in (4, 1, 2, 8):
            if mask & bit:
                dx, dy = offs[bit]
                _fence_piece(t, 32 + dx, 32 + dy, opposite[bit])
        _fence_piece(t, 32, 32, mask)
        t.outline()
        tile = t.image().crop((32, 32, 64, 64))
        tiles.append(tile)
        atlas.alpha_composite(tile, ((mask % 4) * 32, (mask // 4) * 32))
    check("fence_atlas (16 Kacheln)", tiles, foot=False)
    out = ROOT / "assets/environment/props"
    atlas.save(out / "fence_atlas.png")
    return tiles


# ---------------------------------------------------------------------------
# Gartentor: ersetzt eine Zaunkachel. Die Nachbarkacheln behandeln das Tor wie
# Zaun (Bit gesetzt), ihre Riegel enden an den Torpfosten am Kachelrand.
def _gate_post(t, ox, oy, x0):
    for y in range(POST_TOP - 2, POST_FOOT + 1):            # Torpfosten etwas höher
        for x in range(x0, x0 + 4):
            if y == POST_TOP - 2 and x in (x0, x0 + 3):
                continue
            t.set(ox + x, oy + y, ["E4", "E3", "E2", "E1"][x - x0])
    t.set(ox + x0 + 1, oy + POST_TOP - 2, "GOLD")            # Goldkappe


def _gate_leaf(t, ox, oy, width, lift):
    """Torflügel als Bretterwand mit senkrechten Planken, goldene Scharniere links,
    Riegel rechts. width = sichtbare Breite (wird beim Öffnen schmaler, weil er
    sich wegdreht), lift = so viel rutscht die Oberkante nach oben."""
    x0 = 4
    x1 = x0 + width - 1
    y0 = RAILS[0][0] - 3 - lift
    y1 = RAILS[1][1] + 2
    for x in range(x0, x1 + 1):
        top = y0 + (1 if (x - x0) % 4 == 3 else 0)           # Plankenenden leicht versetzt
        for y in range(top, y1 + 1):
            plank = (x - x0) % 4
            k = "E4" if plank == 0 else ("E3" if plank in (1, 2) else "E1")
            if y == top:
                k = "E4" if plank != 3 else "E3"
            if y == y1:
                k = "E1"
            if width <= 6:                                     # fast hochkant: nur die Kante
                k = "E3" if x == x0 else "E2"
            t.set(ox + x, oy + y, k)
    if width > 6:
        for y in (y0 + 3, y1 - 3):                            # Scharniere
            t.set(ox + x0, oy + y, "GOLD"); t.set(ox + x0 + 1, oy + y, "GOLDD")
        t.set(ox + x1 - 1, oy + (y0 + y1) // 2, "GOLDH")       # Riegel
        t.set(ox + x1, oy + (y0 + y1) // 2, "GOLD")


def gate_h():
    """Tor in einem waagerechten Zaunlauf, 32x32, 4 Frames: 0 zu ... 3 offen."""
    frames = []
    for width, lift in ((24, 0), (16, 1), (8, 2), (3, 3)):
        t = Layer(96, 96)
        _fence_piece(t, 0, 32, 2)                           # linker Nachbar: Riegel nach rechts
        _fence_piece(t, 64, 32, 1)                          # rechter Nachbar: Riegel nach links
        _gate_post(t, 32, 32, 0)
        _gate_post(t, 32, 32, 28)
        _gate_leaf(t, 32, 32, width, lift)
        t.outline()
        frames.append(t.image().crop((32, 32, 64, 64)))
    return frames


def gate_v():
    """Tor in einem senkrechten Zaunlauf, 32x32, 2 Frames: 0 zu, 1 offen."""
    frames = []
    for opened in (False, True):
        t = Layer(96, 96)
        _fence_piece(t, 32, 0, 8)                           # oberer Nachbar
        _fence_piece(t, 32, 64, 4)                          # unterer Nachbar
        for y in range(0, 32):                              # Pfosten oben, Flügel nach unten
            pass
        _post(t, 32, 32 - 14)                               # Torpfosten oben (an der Kachelkante)
        if not opened:
            for y in range(32 + 6, 32 + 30):                # Flügel von der Seite: schmal, mit Riegel
                t.set(32 + 15, y, "E3"); t.set(32 + 16, y, "E2")
                if y in (32 + 12, 32 + 22):
                    t.set(32 + 14, y, "E4"); t.set(32 + 17, y, "E2")
            t.set(32 + 17, 32 + 26, "GOLD")
        else:                                               # aufgeschwungen: Flügel zeigt nach rechts
            for x in range(32 + 18, 32 + 31):
                for y in (32 + 8, 32 + 13):
                    t.set(x, y, "E4" if y == 32 + 8 else "E3")
                    t.set(x, y + 1, "E2")
            for y in range(32 + 8, 32 + 15):
                t.set(32 + 30, y, "E2")
        t.outline()
        frames.append(t.image().crop((32, 32, 64, 64)))
    return frames


ALL = {"wild_grass_1": wild_grass_1, "wild_grass_2": wild_grass_2, "wild_grass_3": wild_grass_3,
       "weed_thistle": weed_thistle, "weed_dock": weed_dock,
       "tree_elder": tree_elder, "bush_lavender": bush_lavender,
       "flowers_lilac": flowers_lilac, "flowers_moon": flowers_moon,
       "flowers_ember": flowers_ember, "flowers_blood": flowers_blood}


GLOW_KEYS = {
    "flowers_ember": ("KL", "LK"),
    "flowers_moon": ("KN", "GOLD"),
}


def main(names):
    for n in names:
        if n == "fence_atlas":
            fence_atlas()
        elif n in ("gate_h", "gate_v"):
            save("assets/environment/props", f"fence_{n}", globals()[n](), foot=False)
        else:
            save(FLORA, n, ALL[n](), glow=GLOW_KEYS.get(n))


if __name__ == "__main__":
    main(sys.argv[1:] or list(ALL) + ["fence_atlas", "gate_h", "gate_v"])
