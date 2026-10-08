"""Wald-Grundausstattung (Bitterbloom): Bäume, Totholz, Sträucher, Farne, Gras,
Steine, Leuchtpilze, Hexenring, Glühwürmchen.

Aufruf (aus dem Projektordner):
    python docs/art/nature_generator/forest.py            # alles
    python docs/art/nature_generator/forest.py tree_oak   # nur eins

Ausgabe: assets/environment/flora/  und  assets/environment/fauna/
Alle Grafiken: Fußpunkt = unten Mitte (Ausnahme Glühwürmchen, siehe ASSETS.md).
"""
import math
import sys
from nature import (Layer, blobs, foliage, limb, save, noise, SWAY, _hash, BARK,
                    SWAY8_TOP, SWAY8_MID, crown_sway)

FLORA = "assets/environment/flora"
FAUNA = "assets/environment/fauna"
WOOD = ["E1", "E2", "E3", "E4"]
LEAF = ["L0", "L1", "GD", "L3"]

# Bäume werden im 64er-Raster entworfen und mit S = 1,5 neu gezeichnet (nicht
# hochskaliert): Die Pixel bleiben scharf, die Laubbüschel behalten ihre Größe.
S = 1.5


def X(v):
    return (v + 0.5) * S - 0.5


def sp(points):
    """Stamm-/Astlinie skalieren: [(x, y, halbe_Breite)]"""
    return [(X(x), X(y), w * S) for x, y, w in points]


def ms(circles):
    """Kronen-Kugeln skalieren: [(cx, cy, r)]"""
    return [(X(x), X(y), r * S) for x, y, r in circles]


# ---------------------------------------------------------------------------
# Verdrehte Eiche – breite, wolkige Krone, knorriger Stamm mit Wurzeln
def tree_oak():
    W, H = 96, 120
    trunk = Layer(W, H)
    bark = BARK["oak"]
    limb(trunk, sp([(32, 79, 4.5), (31, 72, 3.5), (33.5, 64, 3.2), (30.5, 55, 3.0),
                    (32, 46, 3.0), (32, 40, 2.6)]), bark, seed=4)
    for pts in ([(30, 77, 1.6), (25, 79, 1.0), (22, 79, 0.6)],
                [(34, 77, 1.6), (39, 79, 1.0), (43, 79, 0.6)],
                [(32, 78, 1.2), (31, 79, 1.0)]):
        limb(trunk, sp(pts), bark, bark=False)
    for pts in ([(31, 53, 1.8), (24, 47, 1.2), (19, 42, 0.8)],
                [(33, 50, 1.8), (40, 45, 1.2), (46, 40, 0.8)],
                [(31, 46, 1.4), (27, 40, 0.9)]):
        limb(trunk, sp(pts), bark, bark=False)
    masses = ms([(17, 27, 12), (47, 25, 12), (32, 16, 13), (10, 36, 7), (54, 36, 7),
                 (24, 36, 10), (40, 36, 10), (32, 28, 12)])
    frames = []
    for fr in range(8):                                   # 8 Frames: Wipfel vor, Mitte folgt
        crown = Layer(W, H)
        foliage(crown, masses, LEAF, seed=11, clump=(3.5, 6.5), accent="G", accent_at=0.9,
                offset=crown_sway(fr))
        crown.cleanup(keep=("G",))
        f = trunk.copy()
        f.paste(crown)
        frames.append(f.outline().image())
    return frames


# Weide – runde Haube, lange hängende Zweige mit silbrigen Spitzen
def tree_willow():
    W, H = 96, 144
    trunk = Layer(W, H)
    bark = BARK["willow"]
    limb(trunk, sp([(32, 95, 5), (31, 88, 4.2), (33, 78, 3.6), (31, 66, 3.2), (32, 54, 2.8),
                    (32, 40, 2.4)]), bark, seed=9)
    limb(trunk, sp([(30, 93, 1.6), (25, 95, 0.9)]), bark, bark=False)
    limb(trunk, sp([(34, 93, 1.6), (39, 95, 0.9)]), bark, bark=False)
    limb(trunk, sp([(32, 60, 1.5), (22, 46, 1.0)]), bark, bark=False)
    limb(trunk, sp([(32, 56, 1.5), (43, 44, 1.0)]), bark, bark=False)
    dome_masses = ms([(32, 21, 15), (17, 29, 10), (47, 29, 10), (32, 31, 12)])

    # hängende Zweige: zufällige Abstände, Längen und Krümmung
    strands = []
    x = 6.0
    i = 0
    while x < 90:
        i += 1
        mid = 1 - abs(x - 47.5) / 48
        length = int((18 + 40 * mid * (0.55 + 0.6 * _hash(i, 1, 7))) * S)
        y0 = int((22 + 10 * (1 - mid) + 6 * _hash(i, 2, 7)) * S)
        front = _hash(i, 3, 7) > 0.4
        strands.append((x, y0, length, front, _hash(i, 4, 7) * 6.28))
        x += 1.5 + _hash(i, 5, 7) * 2.5

    def draw_strand(f, s, fr):
        x0, y0, L, front, ph = s
        pt, pm = SWAY8_TOP[fr], SWAY8_MID[fr]
        for k in range(L):
            t = k / L
            y = y0 + k
            # die Spitzen schwingen am weitesten und einen Frame später (Peitscheneffekt)
            dx = 0 if t < 0.3 else (pt if t < 0.65 else 2 * pm)
            xx = int(round(x0 + math.sin(ph + t * 2.2) * 1.2 * t)) + dx
            if front:
                c = "W3" if t > 0.82 else ("W2" if t > 0.3 else "W1")
            else:
                c = "W1" if t > 0.5 else "L0"
            f.set(xx, y, c)
            if k % 3 == 1 and t > 0.15:             # kleine Blätter abwechselnd links/rechts
                f.set(xx + (1 if (k // 3) % 2 else -1), y, "W2" if front else "L1")
        if front and L > 50:
            f.set(int(round(x0 + math.sin(ph + 2.2) * 1.2)) + 2 * pm, y0 + L, "SM")

    frames = []
    for fr in range(8):
        dome = Layer(W, H)
        foliage(dome, dome_masses, ["L0", "L1", "W1", "W2"], seed=21, clump=(3.0, 5.5),
                accent="W3", accent_at=0.88, offset=crown_sway(fr, 0.3, 0.6))
        dome.cleanup(keep=("W3",))
        f = Layer(W, H)
        for st in strands:
            if not st[3]:
                draw_strand(f, st, fr)
        f.paste(trunk)
        f.paste(dome)
        for st in strands:
            if st[3]:
                draw_strand(f, st, fr)
        frames.append(f.outline().image())
    return frames


# Tanne – schmal, spitz, gestufte Äste mit hängenden Spitzen, sehr dunkel und kühl
def tree_fir():
    W, H = 72, 144
    TONES = ["NB", "L0", "L1", "GD"]
    trunk = Layer(W, H)
    bark = BARK["fir"]
    limb(trunk, sp([(24, 95, 3.2), (24, 84, 2.4), (24, 70, 2.0)]), bark, seed=13)
    limb(trunk, sp([(22, 94, 1.2), (19, 95, 0.7)]), bark, bark=False)
    limb(trunk, sp([(26, 94, 1.2), (29, 95, 0.7)]), bark, bark=False)

    # (Spitze, Basis, halbe Breite) von oben nach unten, im 48er-Entwurf
    tiers = [(1, 15, 6), (8, 27, 10), (19, 40, 13), (32, 54, 16), (46, 68, 19), (60, 82, 22)]
    tiers = [(int(X(a)), int(X(b)), h * S) for a, b, h in tiers]
    def crown_frame(fr):
        crown = Layer(W, H)
        for ti in range(len(tiers) - 1, -1, -1):
            # ganze Stufen schwingen: obere vor, mittlere einen Frame später, untere ruhig
            off = SWAY8_TOP[fr] if ti <= 1 else (SWAY8_MID[fr] if ti <= 3 else 0)
            apex, base, hw = tiers[ti]
            for x in range(W):
                dx = x - 35.5
                droop = int(round(2.2 * noise(x, ti * 10, 2.0, 40))) + (1 if abs(dx) > hw * 0.6 else 0)
                for y in range(apex, base + droop + 1):
                    t = min(1.0, (y - apex) / (base - apex))
                    half = hw * t + (noise(x, y, 2.0, 41 + ti) - 0.5) * 2.2
                    if abs(dx) > half:
                        continue
                    rel = dx / max(hw * t, 1.0)
                    lum = 0.66 - rel * 0.5 + (noise(x, y, 1.6, 50 + ti) - 0.5) * 0.4
                    if ti > 0:
                        gap = y - (tiers[ti - 1][1] + 1)
                        if 0 <= gap <= 3:
                            lum -= 0.45 - gap * 0.1
                    lum -= 0.25 * (y > base)
                    if rel < 0.2 and (x - y // 2) % 3 == 0 and noise(x, y, 2.0, 60) > 0.45:
                        lum += 0.25
                    k = int(lum * len(TONES))
                    crown.set(x + off, y, TONES[max(0, min(len(TONES) - 1, k))])
        return crown.cleanup()

    frames = []
    for fr in range(8):
        f = trunk.copy()
        f.paste(crown_frame(fr))
        frames.append(f.outline().image())
    return frames


# Toter Baum – kahle, verdrehte Äste, Bartflechte; steht still
def tree_dead():
    W, H = 96, 120
    t = Layer(W, H)
    bark = BARK["dead"]
    limb(t, sp([(32, 79, 4.5), (31, 70, 3.6), (33, 58, 3.0), (31, 46, 2.6), (32, 36, 2.0)]), bark, seed=17)
    for pts in ([(30, 77, 1.5), (24, 79, 0.8)], [(34, 77, 1.5), (41, 79, 0.8)]):
        limb(t, sp(pts), bark, bark=False)
    branches = [
        [(31, 50, 2.0), (22, 42, 1.5), (14, 36, 1.0), (8, 27, 0.6)],
        [(22, 42, 1.0), (19, 32, 0.7), (21, 24, 0.5)],
        [(14, 36, 0.8), (6, 37, 0.5)],
        [(33, 44, 1.8), (42, 36, 1.4), (50, 28, 1.0), (55, 18, 0.6)],
        [(42, 36, 0.9), (47, 40, 0.6), (54, 39, 0.4)],
        [(50, 28, 0.7), (45, 20, 0.5)],
        [(32, 36, 1.6), (30, 26, 1.1), (33, 16, 0.8), (31, 8, 0.5)],
        [(30, 26, 0.8), (24, 18, 0.5)],
        [(33, 16, 0.6), (38, 11, 0.4)],
        [(32, 60, 1.2), (38, 57, 0.8), (40, 55, 0.5)],          # abgebrochener Stummel
    ]
    for b in branches:
        limb(t, sp(b), bark, bark=False)
    # Bartflechte hängt von den Ästen
    for x, y, L in ((16, 38, 5), (12, 36, 4), (45, 37, 6), (51, 31, 4), (25, 44, 3), (36, 22, 4)):
        L = int(L * S)
        for k in range(L):
            t.set(X(x), X(y) + k, "WO" if k < L - 1 else "LST")
    return [t.outline().image()]


# ---------------------------------------------------------------------------
# Totholz
def stump():
    """Baumstumpf mit Schnittfläche, Moos und zwei kleinen Pilzen. 32x32."""
    W, H = 32, 32
    t = Layer(W, H)
    limb(t, [(16, 31, 8.5), (16, 22, 7.5), (16, 17, 7.2)], WOOD, seed=31)
    for sp in ([(9, 30, 2.2), (4, 31, 1.0)], [(23, 30, 2.2), (28, 31, 1.0)]):
        limb(t, sp, WOOD, bark=False)
    for y in range(12, 20):                              # Schnittfläche (Ellipse)
        for x in range(W):
            d = ((x - 16) / 7.6) ** 2 + ((y - 16) / 3.4) ** 2
            if d <= 1:
                ring = int(math.hypot((x - 15.5) / 7.6, (y - 15.8) / 3.4) * 4)
                t.set(x, y, ["E3", "E4", "E3", "E4", "E2"][min(ring, 4)])
    t.set(14, 15, "LST"); t.set(15, 15, "LST"); t.set(12, 14, "LST")
    for x, y in ((9, 21), (10, 21), (11, 22), (9, 22), (10, 23), (8, 24), (9, 25)):
        t.set(x, y, "GD")
    t.set(9, 21, "L3"); t.set(10, 21, "L3")
    for x, y in ((22, 27), (25, 28)):                    # Pilzchen
        t.set(x, y, "LS"); t.set(x, y - 1, "KN"); t.set(x - 1, y - 1, "KN"); t.set(x + 1, y - 1, "LS")
    return [t.outline().image()]


def log():
    """Liegender Stamm mit Schnittfläche links, Moosrücken und Farnspross. 64x32."""
    W, H = 64, 32
    t = Layer(W, H)
    for x in range(8, 60):                               # Zylinder liegend: Licht von oben
        top = 12 + int(round(noise(x, 0, 6, 33) * 1.6))
        for y in range(top, 31):
            rel = (y - top) / (31 - top)
            k = 3 if rel < 0.22 else (2 if rel < 0.55 else (1 if rel < 0.85 else 0))
            if k >= 1 and noise(x * 0.5, y * 3, 1.0, 34) > 0.8:
                k -= 1                                   # Rinde läuft waagerecht
            t.set(x, y, WOOD[k])
    for y in range(11, 32):                              # Schnittfläche
        for x in range(2, 16):
            d = ((x - 8.5) / 5.6) ** 2 + ((y - 21.5) / 9.6) ** 2
            if d <= 1:
                ring = int(math.sqrt(d) * 4)
                t.set(x, y, ["E4", "E3", "E4", "E3", "E2"][min(ring, 4)])
    t.set(8, 20, "LST"); t.set(8, 21, "LST"); t.set(7, 18, "E2")
    for x in range(20, 50):                              # Moosrücken
        h = int(1 + 2.5 * noise(x, 1, 4, 35))
        top = 12 + int(round(noise(x, 0, 6, 33) * 1.6))
        for y in range(top - h + 1, top + 2):
            t.set(x, y, "L3" if y < top else "GD")
    for i, (x, y) in enumerate(((44, 9), (45, 8), (46, 7), (47, 7), (43, 8), (42, 7), (41, 7))):
        t.set(x, y, "L3" if i % 2 else "G")
    return [t.outline().image()]


# Sträucher
def _bush(masses, seed, extra=None, w=32, h=32):
    t = Layer(w, h)
    foliage(t, masses, LEAF, seed=seed, clump=(2.5, 4.0), accent="G", accent_at=0.9)
    t.cleanup(keep=("G",))
    if extra:
        extra(t)
    return t


def bush_1():
    t = _bush([(16, 20, 11), (9, 24, 7), (23, 24, 7)], 61)
    return [t.outline().image()]


def bush_2():
    """breiter, flacher Busch (48x32)"""
    t = _bush([(14, 22, 9), (26, 18, 10), (36, 23, 9), (24, 26, 8)], 62, w=48)
    return [t.outline().image()]


def bush_berries():
    """Busch mit dunklen Bordeaux-Beeren (nur Deko)."""
    def berries(t):
        for i, (x, y) in enumerate(((10, 18), (19, 14), (23, 22), (13, 25), (7, 23), (21, 27), (16, 20))):
            t.set(x, y, "BOR"); t.set(x + 1, y, "BORD"); t.set(x, y + 1, "BORD")
            t.set(x, y - 1 if i % 2 else y, "BORH" if i % 2 else "BOR")
    t = _bush([(16, 20, 11), (9, 23, 7), (23, 23, 7)], 63, berries)
    return [t.outline().image()]


# Farne: geschlossene, gezackte Wedel, die sich nach außen biegen
def _fern(fronds, seed, w=32, h=32, tones=("L1", "GD", "L3", "G"), tip="GH"):
    """fronds = [(Startwinkel in Grad, Länge, Krümmung)], 0 = senkrecht nach oben."""
    dark, rib, lit, bright = tones
    frames = []
    order = sorted(fronds, key=lambda f: abs(f[0]))     # steile hinten, flache vorn
    for p in SWAY:
        t = Layer(w, h)
        for fi, (ang, length, curl) in enumerate(order):
            x, y = w / 2 - 0.5, h - 1.5
            a = math.radians(ang)
            for s in range(length):
                tt = s / length
                a += math.radians(curl) * (0.4 + tt)
                x += math.sin(a)
                y -= math.cos(a)
                if tt < 0.12:
                    t.set(x, y, rib)
                    continue
                sway = p if tt > 0.55 else 0
                half = 2.6 * math.sin(math.pi * min(1.0, (tt - 0.08) * 1.1)) * (1 - 0.3 * tt)
                if s % 2 == 1:
                    half *= 0.35                      # tiefe Kerben zwischen den Fiedern
                nx, ny = math.cos(a), math.sin(a)     # quer zur Wedelrichtung
                steps = int(half * 2) + 1
                for k in range(-steps, steps + 1):
                    off = k / 2
                    if abs(off) > half:
                        continue
                    px, py = x + nx * off + sway, y + ny * off
                    side = nx * off * -1 + ny * off * -1   # >0: Seite zeigt nach oben links
                    if abs(off) < 0.6:
                        c = rib
                    elif side > 0:
                        c = bright if (abs(off) > half - 0.8 and s % 4 == 0) else lit
                    else:
                        c = dark
                    t.set(px, py, c)
            t.set(x + (p if True else 0), y, tip)
        frames.append(t.cleanup(keep=(tip, tones[3])).outline().image())
    return frames


def fern_1():
    return _fern([(-70, 17, 3.5), (-36, 20, 3), (-4, 21, -0.5), (30, 20, -3), (64, 17, -3.5)], 71)


def fern_2():
    return _fern([(-80, 14, 4), (-50, 17, 3.5), (-20, 19, 2), (14, 19, -2), (44, 17, -3.5), (76, 14, -4)], 72)


# Grasbüschel 16x16, wiegen. Bewusst OHNE Kontur (wie die Halme im Boden-Tile),
# sonst werden die 1-px-Halme zu dunklen Strichen.
def _tuft(blades, flower=None):
    frames = []
    for p in SWAY:
        t = Layer(16, 16)
        for bi, (x0, h, lean) in enumerate(blades):
            for s in range(h):
                tt = s / h
                x = x0 + lean * tt * tt + (p if tt > 0.6 else 0)
                if tt < 0.25:
                    c = "L1"
                elif tt < 0.6:
                    c = "GD"
                elif tt < 0.75:
                    c = "L3"
                elif tt < 0.9:
                    c = "G"
                else:
                    c = "GH"
                t.set(x, 15 - s, c)
        for x in range(4, 13):                     # dunkler Fuß erdet das Büschel
            if t.get(x, 15) is not None or t.get(x, 14) is not None:
                t.set(x, 15, "L0")
        if flower:
            fx, fy, a, b = flower
            fx += p
            t.set(fx, fy + 1, "GD"); t.set(fx, fy + 2, "GD")
            t.set(fx, fy, a); t.set(fx - 1, fy, b); t.set(fx + 1, fy, b); t.set(fx, fy - 1, b)
        frames.append(t.image())
    return frames


def grass_tuft_1():
    return _tuft([(5, 9, -2.5), (7, 12, -1), (8, 13, 0.5), (10, 10, 2), (6, 7, -3.5), (11, 7, 3.5)])


def grass_tuft_2():
    return _tuft([(4, 7, -2), (6, 11, -1.5), (8, 9, 0), (9, 12, 1), (11, 8, 2.5)], (9, 3, "KN", "LS"))


def grass_tuft_3():
    return _tuft([(5, 10, -2), (7, 13, -0.5), (9, 11, 1.5), (11, 6, 3)], (6, 3, "FL", "INDH"))


# Steine mit Moos
def _rock(masses, seed, w, h, moss=True):
    t = Layer(w, h)
    blobs(t, masses, ["K1", "K2", "K3", "KR2"], seed=seed, edge=0.6, clump=4, clump_amt=0.12, ao=0.3)
    if moss:
        top = min(cy - r for cx, cy, r in masses)
        for y in range(h):
            for x in range(w):
                k = t.get(x, y)
                if k and y < top + 4 + 3 * noise(x, 0, 3, seed) and noise(x, y, 2.5, seed + 9) > 0.45:
                    t.set(x, y, "L3" if noise(x, y, 1.5, seed + 4) > 0.55 else "GD")
    t.cleanup()
    return t


def rock_1():
    return [_rock([(16, 22, 9), (10, 25, 6), (22, 25, 6)], 81, 32, 32).outline().image()]


def rock_2():
    return [_rock([(8, 10, 5), (11, 11, 4)], 82, 16, 16).outline().image()]


# ---------------------------------------------------------------------------
# Leuchtpilze: Kappen pulsieren, Sporen steigen auf. 4 Frames, Loop.
GLOW = {
    "moon": ["GEI", "EIS", "GK"],            # Mondpilz: kühl, silbrig-blau
    "ember": ["GOLDD", "GOLD", "GOLDH", "KL", "LK"],   # Glutpilz: warm wie Kerzenlicht
    "hex": ["MG", "M", "MH", "MR"],          # Hexenring: Magie
}


def _cap(t, x, y, w, ramp, level, stem_h):
    """Ein Pilz: kurzer Stiel + gewölbte Kappe (Halbkugel), Rand unten dunkler.
    w = halbe Kappenbreite, level -1..1 = Leuchtstärke (pulsiert)."""
    for s in range(stem_h):
        t.set(x, y - s, "LST" if s == 0 else "LS")
        if w >= 2:
            t.set(x + 1, y - s, "LST")
    rim = y - stem_h
    hc = max(1, w)                                   # Kappenhöhe
    n = len(ramp)
    for dy in range(-hc, 1):
        for dx in range(-w - 1, w + 2):
            ex = (dx - 0.5 * (w >= 2)) / (w + 0.6)
            ey = (dy - 0.2) / (hc + 0.4)
            if ex * ex + ey * ey > 1.0:
                continue
            lit = -ex * 0.6 - ey * 0.8
            i = 1 + level + (1 if lit > 0.55 else 0) + (1 if lit > 0.95 else 0)
            if dy == 0:
                i -= 1                               # Rand/Unterseite
            t.set(x + dx, rim + dy, ramp[max(0, min(n - 1, i))])
    t.set(x - max(0, w - 1), rim - hc + (1 if w >= 2 else 0), ramp[-1])   # Glanzpunkt oben links


def _mushrooms(kind, caps, w=24, h=20):
    """Pilzgruppe, Kappen pulsieren versetzt, Sporen steigen auf. 4 Frames."""
    ramp = GLOW[kind]
    pulse = [0, 1, 2, 1]
    spores = [[(7, 6)], [(7, 3), (16, 7)], [(8, 1), (16, 4)], [(17, 2)]]
    frames = []
    for f in range(4):
        t = Layer(w, h)
        for i, (x, y, cw, sh) in enumerate(caps):
            level = pulse[(f + i) % 4] - 1
            _cap(t, x, y, cw, ramp, level, sh)
        t.outline()
        for x, y in spores[f]:
            t.set(x, y, ramp[-1])
        frames.append(t.image())
    return frames


def mushroom_moon():
    """Mondpilze: drei kühl leuchtende Kappen. 24x20 (vorher 16x16)."""
    return _mushrooms("moon", [(8, 19, 4, 4), (16, 19, 3, 3), (12, 19, 2, 2)])


def mushroom_ember():
    """Glutpilze: warm wie Kerzenlicht. 24x20."""
    return _mushrooms("ember", [(9, 19, 3, 6), (16, 19, 4, 3), (4, 19, 2, 2)])


def mushroom_ring():
    """Hexenring: Kreis aus kleinen Magenta-Pilzen, das Leuchten läuft im Kreis.
    64x48, 8 Frames. Die Mitte ist frei (begehbar)."""
    W, H = 64, 48
    ramp = GLOW["hex"]
    n = 12
    spots = []
    for i in range(n):
        a = i / n * math.tau + 0.2
        x = 32 + math.cos(a) * 26 + (_hash(i, 1, 90) - 0.5) * 3
        y = 27 + math.sin(a) * 14 + (_hash(i, 2, 90) - 0.5) * 2
        size = 3 if _hash(i, 3, 90) < 0.45 else 2
        spots.append((int(round(x)), int(round(y)), size, i))
    spots.sort(key=lambda s: s[1])                  # hintere zuerst
    frames = []
    for f in range(8):
        t = Layer(W, H)
        sparks = []
        for x, y, size, i in spots:
            phase = (i / n * 8 - f) % 8
            level = 1 if phase < 1.5 else 0
            _cap(t, x, y + 6, size, ramp, level, 1 + size)
            if phase < 1:
                sparks.append((x, y + 3 - size * 2 - 2))
        t.outline()
        for x, y in sparks:
            t.set(x, y, "MR"); t.set(x, y - 2, "MH")
        frames.append(t.image())
    return frames


# Glühwürmchen: 8x8, 6 Frames Blinken (Loop). Die Bewegung macht das Spiel.
def firefly():
    stages = [0, 0, 1, 2, 3, 1]
    frames = []
    for st in stages:
        t = Layer(8, 8)
        t.set(4, 4, "E2")                           # winziger Körper
        if st >= 1:
            t.set(4, 4, "GOLD")
        if st >= 2:
            t.set(4, 4, "GOLDH")
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                t.set(4 + dx, 4 + dy, "GOLD")
        if st >= 3:
            t.set(4, 4, "LK")
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                t.set(4 + dx, 4 + dy, "GOLDH")
            for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
                t.set(4 + dx, 4 + dy, "GOLDD")
        frames.append(t.image())
    return frames


# ---------------------------------------------------------------------------
TREES = {"tree_oak": tree_oak, "tree_willow": tree_willow, "tree_fir": tree_fir,
         "tree_dead": tree_dead}
SMALL = {"stump": stump, "log": log, "bush_1": bush_1, "bush_2": bush_2,
         "bush_berries": bush_berries, "fern_1": fern_1, "fern_2": fern_2,
         "grass_tuft_1": grass_tuft_1, "grass_tuft_2": grass_tuft_2, "grass_tuft_3": grass_tuft_3,
         "rock_1": rock_1, "rock_2": rock_2}
GLOWING = {"mushroom_moon": mushroom_moon, "mushroom_ember": mushroom_ember,
           "mushroom_ring": mushroom_ring, "firefly": firefly}
ALL = dict(TREES, **SMALL, **GLOWING)


# Selbstleuchtende Farben je Grafik -> <name>_glow.png
GLOW_KEYS = {
    "mushroom_moon": ("GEI", "EIS", "GK"),
    "mushroom_ember": ("GOLD", "GOLDH", "KL", "LK"),
    "mushroom_ring": ("M", "MH", "MR"),
}


def main(names):
    for n in names:
        save(FAUNA if n.startswith("firefly") else FLORA, n, ALL[n](), foot=n != "firefly",
             glow=GLOW_KEYS.get(n))


if __name__ == "__main__":
    main(sys.argv[1:] or list(ALL))
