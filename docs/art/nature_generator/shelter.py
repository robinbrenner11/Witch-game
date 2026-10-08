"""Unterschlupf (Bitterbloom): hohler Uraltbaum – Außenansicht und Innenraum.

Aufruf (aus dem Projektordner):
    python docs/art/nature_generator/shelter.py

Ausgabe: assets/environment/shelter/
"""
import math
import sys
from PIL import Image
from nature import (Layer, foliage, limb, save, noise, SWAY, _hash, ROOT, PAL,
                    crown_sway, SWAY8_TOP, SWAY8_MID)

OUT = "assets/environment/shelter"
WOOD = ["E1", "E2", "E3", "E4"]
LEAF_OLD = ["NB", "L0", "L1", "GD", "L3"]          # alter Baum: tiefer, kühler


# ---------------------------------------------------------------------------
# Außenansicht: 192x224, Fußpunkt unten Mitte. Die Tür liegt unten in der Mitte.
W, H = 192, 224
CX, B = 96, 223
DOOR_X, DOOR_W, DOOR_TOP, DOOR_BOTTOM = 96, 11, 184, 219     # Mitte, halbe Breite


def trunk_layer():
    t = Layer(W, H)
    # Drei dicke Hauptäste, die sich in die Krone teilen (zuerst, liegen hinten)
    for pts in ([(84, 132, 14), (66, 110, 11), (50, 92, 8), (38, 80, 5)],
                [(108, 130, 14), (126, 108, 11), (142, 92, 8), (154, 80, 5)],
                [(96, 128, 13), (94, 104, 10), (98, 84, 7)]):
        limb(t, pts, WOOD, seed=303)
    # massiger, knorriger Stamm mit Ausbuchtungen
    limb(t, [(96, 223, 44), (95, 212, 40), (97, 198, 36), (94, 182, 33), (97, 166, 32),
             (95, 150, 33), (97, 136, 35), (96, 128, 32)], WOOD, seed=301)
    # Brettwurzeln: breite Bögen, die sich über den Boden legen
    for pts in ([(62, 206, 12), (44, 214, 9), (28, 219, 6), (12, 222, 3)],
                [(130, 206, 12), (148, 214, 9), (164, 219, 6), (180, 222, 3)],
                [(70, 214, 9), (56, 221, 5)],
                [(122, 214, 9), (138, 221, 5)],
                [(60, 196, 7), (42, 202, 5), (30, 208, 3)]):
        limb(t, pts, WOOD, seed=302)
    # tiefer Ast für die Laterne
    limb(t, [(66, 160, 6), (50, 150, 4), (40, 146, 2.5)], WOOD, seed=305, bark=False)
    # Rindenwülste: senkrechte dunkle Furchen, die dem Stamm Masse geben
    for x0 in (66, 74, 82, 90, 103, 111, 119, 126):
        for y in range(132, 214):
            x = x0 + int(round(2.5 * math.sin(y * 0.07 + x0)))
            if t.get(x, y) and noise(x, y, 6, 304) > 0.3:
                t.set(x, y, "E1" if x > CX else "E2")
                if noise(x, y, 3, 306) > 0.6 and t.get(x - 1, y) == "E3":
                    t.set(x - 1, y, "E4")                      # Licht auf der Wulstkante
    # Astloch (Knorren) links oben am Stamm
    for y in range(150, 158):
        for x in range(72, 80):
            d = math.hypot((x - 75.5) / 3.6, (y - 153.5) / 3.8)
            if d <= 1:
                t.set(x, y, "E1" if d < 0.6 else "E3")
    return t


def door(t):
    """Gewölbte Brettertür, tief im Stamm eingelassen, einen Spalt offen; warmes
    Licht fällt heraus. Zwei Wurzeln wachsen links und rechts hoch und bilden über
    der Tür einen Bogen; davor ein flacher Trittstein, darüber eine Mondsichel."""
    # Wurzelbogen (zuerst, die Laibung schneidet sich hinein). Eigene Ebene, damit
    # er eine dunkle Fuge zum Stamm bekommt und sich abhebt.
    arch = Layer(W, H)
    for side in (-1, 1):
        pts = [(DOOR_X + side * 20, 223, 4.5), (DOOR_X + side * 19, 206, 4.0),
               (DOOR_X + side * 17, 188, 3.6), (DOOR_X + side * 12, 172, 3.2),
               (DOOR_X + side * 4, 164, 3.0)]
        limb(arch, pts, ["E2", "E3", "E4", "LST"], seed=330 + side, bark=False)
    for y in range(H):
        for x in range(W):
            if arch.get(x, y) is None and any(arch.get(x + dx, y + dy) is not None
                                              for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                if t.get(x, y) is not None:
                    t.set(x, y, "E1")                        # Fuge zum Stamm
    t.paste(arch)
    # Laibung: tiefe Nische; oben und links im Schatten, unten rechts Licht
    for y in range(DOOR_TOP - 4, DOOR_BOTTOM + 1):
        for x in range(DOOR_X - DOOR_W - 4, DOOR_X + DOOR_W + 5):
            dx = (x - DOOR_X) / (DOOR_W + 4)
            dy = (y - (DOOR_TOP + 8)) / 12
            if not (y >= DOOR_TOP + 8 or dx * dx + dy * dy <= 1):
                continue
            edge_l = x < DOOR_X - DOOR_W
            edge_r = x > DOOR_X + DOOR_W
            top = y < DOOR_TOP + 1
            k = "TS" if (edge_l or top) else ("E2" if edge_r else "E1")
            t.set(x, y, k)
    for y in range(DOOR_TOP, DOOR_BOTTOM + 1):              # Türblatt
        for x in range(DOOR_X - DOOR_W, DOOR_X + DOOR_W + 1):
            dx = (x - DOOR_X) / DOOR_W
            dy = (y - (DOOR_TOP + 8)) / 8
            if y < DOOR_TOP + 8 and dx * dx + dy * dy > 1:
                continue
            plank = (x - DOOR_X + DOOR_W) % 5
            k = "E3" if plank == 0 else ("E2" if plank == 4 else "BORD")
            if x < DOOR_X - DOOR_W + 2:
                k = "E3"
            if y < DOOR_TOP + 3 and k == "BORD":
                k = "BOR"                                    # Oberkante fängt etwas Licht
            t.set(x, y, k)
    for x in range(DOOR_X - DOOR_W, DOOR_X + DOOR_W + 1):   # Querbeschläge in Gold
        for y in (DOOR_TOP + 10, DOOR_BOTTOM - 6):
            if t.get(x, y) not in (None, "E1", "TS"):
                t.set(x, y, "GOLDD" if x > DOOR_X else "GOLD")
    t.set(DOOR_X + DOOR_W - 3, DOOR_TOP + 20, "GOLDH")       # Türring
    t.set(DOOR_X + DOOR_W - 3, DOOR_TOP + 21, "GOLD")
    for y in range(DOOR_TOP + 4, DOOR_BOTTOM + 1):           # Lichtspalt rechts: Tür steht offen
        t.set(DOOR_X + DOOR_W + 1, y, "KL" if y > DOOR_TOP + 8 else "GOLDH")
        t.set(DOOR_X + DOOR_W + 2, y, "GOLD")
    # Trittstein vor der Tür (flach, Stein), Licht fällt darauf
    for y in range(219, 224):
        for x in range(DOOR_X - 15, DOOR_X + 16):
            d = abs(x - DOOR_X) / 15 + max(0, 220 - y) * 0.3
            if d > 1:
                continue
            k = "K3" if y < 221 else ("K2" if y < 223 else "K1")
            if y == 219 and x < DOOR_X:
                k = "KR2"
            if x > DOOR_X + DOOR_W and y < 222:
                k = "GOLDD"                                  # Lichtschein aus dem Spalt
            t.set(x, y, k)
    # Mondsichel in Gold im Scheitel des Wurzelbogens
    for y in range(156, 166):
        for x in range(DOOR_X - 5, DOOR_X + 6):
            if math.hypot(x - DOOR_X, y - 161) <= 4.3 and math.hypot(x - DOOR_X - 2, y - 160) > 3.2:
                t.set(x, y, "GOLD" if x < DOOR_X else "GOLDD")
    t.set(DOOR_X + 4, 157, "GOLDH")                         # kleiner Stern


def window(t, cx=114, cy=158, r=6):
    for y in range(cy - r - 2, cy + r + 3):
        for x in range(cx - r - 2, cx + r + 3):
            d = math.hypot(x - cx, y - cy)
            if d <= r + 1.6:
                t.set(x, y, "E1" if d > r + 0.5 else ("GOLDH" if (x - cx) + (y - cy) < -2 else "KL"))
    for k in range(-r, r + 1):                               # Fensterkreuz
        t.set(cx + k, cy, "E2")
        t.set(cx, cy + k, "E2")
    t.set(cx - 2, cy - 2, "LK")


def details(t):
    # Baumpilze (Konsolen) an der rechten Stammseite
    for x, y, w in ((124, 176, 6), (121, 183, 5), (126, 140, 5), (64, 190, 4)):
        for k in range(w):
            t.set(x + k, y, "LST" if k < w - 1 else "E3")
            t.set(x + k, y + 1, "E3")
        t.set(x, y - 1, "LS")
    # Moos auf den Wurzeln und am Stammfuß (oben, wo Licht hinkommt)
    for x in range(10, 184):
        if noise(x, 0, 5, 310) > 0.42:
            for y in range(194, 223):
                k = t.get(x, y)
                if k in WOOD and (t.get(x, y - 1) in (None, "o")):
                    t.set(x, y, "L3" if noise(x, y, 2, 311) > 0.5 else "GD")
                    if t.get(x, y + 1) in WOOD:
                        t.set(x, y + 1, "GD")
                    break
    # Efeu-Ranke am linken Stamm
    for y in range(132, 210):
        x = 60 + int(round(3 * math.sin(y * 0.15)))
        if t.get(x, y):
            t.set(x, y, "GD")
            if y % 4 == 0:
                t.set(x - 1, y, "L3")
                t.set(x + 1, y + 1, "GD")


def lantern(t, x=42, y=147):
    """Laterne hängt am tiefen Ast; Kette, Gehäuse, warmes Licht."""
    for k in range(1, 6):
        t.set(x, y + k, "E2" if k % 2 else "GOLDD")
    rows = [".ooo.", "oGGGo", "oKLKo", "oKKKo", "oGGGo", "..o.."]
    cmap = {"o": "E1", "G": "GOLDD", "K": "KL", "L": "LK"}
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch != ".":
                t.set(x - 2 + dx, y + 6 + dy, cmap[ch])


def crown_layer(fr=0):
    """Uralte Schirmkrone: breite, flache Laubetagen statt einer runden Kugel,
    dazwischen dunkle Lücken; aus der unteren Etage hängt silbrige Bartflechte."""
    c = Layer(W, H)
    sway = crown_sway(fr, 0.35, 0.7)
    masses = []
    for x in range(30, 170, 22):                         # obere Etage (schmaler)
        masses.append((x, 44 + 4 * math.sin(x * 0.07), 16))
    for x in range(14, 186, 21):                         # untere, breite Etage
        masses.append((x, 86 + 5 * math.sin(x * 0.05 + 1), 17))
    masses.append((96, 22, 22))                          # Wipfel
    masses.append((64, 28, 14)); masses.append((128, 28, 14))
    foliage(c, masses, LEAF_OLD, seed=320, clump=(3.5, 6.5), accent="G", accent_at=0.94,
            ao=0.32, offset=sway)
    c.cleanup(keep=("G",))
    # Bartflechte: büschelige, silbrig-grüne Strähnen unter der unteren Etage
    pt, pm = SWAY8_TOP[fr], SWAY8_MID[fr]
    for i, x0 in enumerate(range(12, 184, 11)):
        if _hash(i, 2, 340) < 0.25:
            continue
        L = 10 + int(14 * _hash(i, 1, 340))
        y0 = 94 + int(5 * _hash(i, 3, 340)) + int(5 * math.sin(x0 * 0.05 + 1))
        for k in range(L):
            t = k / L
            w = 2 if t < 0.6 else 1                       # oben breiter, unten dünn
            x = x0 + int(round(math.sin(k * 0.45 + i) * 0.8)) + (pm if t > 0.5 else 0)
            for dx in range(-w + 1, w):
                c.set(x + dx, y0 + k, "WO" if dx < 0 or t > 0.75 else "W2")
            if k % 3 == 1 and t < 0.8:                    # kleine Seitenfasern
                c.set(x + (w if (k // 3) % 2 else -w), y0 + k, "W3")
        c.set(x0 + (pm if True else 0), y0 + L, "SM")
    return c


def tree_exterior():
    trunk = trunk_layer()
    door(trunk)
    window(trunk)
    details(trunk)
    lantern(trunk)
    frames = []
    for fr in range(8):
        f = trunk.copy()
        f.paste(crown_layer(fr))
        frames.append(f.outline().image())
    return frames


# ---------------------------------------------------------------------------
# Innenraum: runder Raum im Stamm. Raumgrafik 320x256 (10x8 Kacheln), der Boden
# ist der Querschnitt des Baums mit Jahresringen. Möbel sind eigene Grafiken.
RW, RH = 320, 256
RCX, RCY, RRX, RRY = 160, 156, 136, 78          # Bodenellipse
WALL_H = 80
DOOR_HALF = 20                                  # Türöffnung unten Mitte (halbe Breite)


def floor_top(x):
    u = (x - RCX) / RRX
    return RCY - RRY * math.sqrt(max(0.0, 1 - u * u))


def room():
    t = Layer(RW, RH)
    # Rückwand: gewölbt, Maserung senkrecht, zu den Seiten dunkler (Rundung)
    for x in range(RCX - RRX, RCX + RRX + 1):
        yt = floor_top(x)
        side = abs(x - RCX) / RRX
        for y in range(int(yt - WALL_H), int(yt) + 1):
            h = (yt - y) / WALL_H                                  # 0 unten, 1 oben
            lum = 0.62 - side * 0.45 - h * 0.25 + (noise(x * 3, y * 0.15, 2.0, 401) - 0.5) * 0.35
            if (x + int(4 * math.sin(y * 0.05 + x * 0.3))) % 9 == 0:
                lum -= 0.25                                         # Maserfuge
            k = 3 if lum > 0.62 else (2 if lum > 0.42 else (1 if lum > 0.2 else 0))
            t.set(x, y, WOOD[k])
        # Darüber geht die Höhlung im Stamm nach oben ins Dunkle: harte Stufen
        # E1 -> Nachtviolett -> Tiefschwarz, mit welliger Grenze (Holzfasern)
        top = int(yt - WALL_H)
        b1 = top - 5 - int(4 * noise(x, 0, 6, 402))
        b2 = b1 - 8 - int(5 * noise(x, 0, 9, 407))
        for y in range(0, top):
            if y >= b1:
                k = "E1" if (x % 7) else "E2"
            elif y >= b2:
                k = "NV" if (x + y // 3) % 9 else "E1"
            else:
                k = "TS"
            t.set(x, y, k)
    # Boden: Jahresringe
    for y in range(int(RCY - RRY), int(RCY + RRY) + 1):
        for x in range(RCX - RRX, RCX + RRX + 1):
            u, v = (x - RCX) / RRX, (y - RCY) / RRY
            d = math.hypot(u, v)
            if d > 1:
                continue
            ring = d * 11 + 0.35 * noise(x, y, 16, 403) + 0.1 * math.sin(math.atan2(v, u) * 5)
            frac = ring - math.floor(ring)
            k = "E3"
            if frac < 0.06 and int(ring) % 2 == 0:
                k = "E2"                                            # feine Ringlinie
            if d > 0.93:
                k = "E2"                                            # Splint am Rand
            if d < 0.035:
                k = "E2"                                            # Mark
            ang = math.atan2(v, u)
            for ca, ln in ((0.9, 0.42), (3.6, 0.3)):                # zwei feine Trockenrisse
                wob = 0.06 * math.sin(d * 30 + ca)
                if abs(((ang - ca - wob + math.pi) % math.tau) - math.pi) < 0.006 / max(d, 0.05) and 0.06 < d < ln:
                    k = "E1"
            t.set(x, y, k)
    # Vorderrand: Schnittkante der Stammwand unten, mit Türöffnung
    for x in range(RCX - RRX - 8, RCX + RRX + 9):
        u = (x - RCX) / (RRX + 8)
        if abs(u) > 1:
            continue
        yb = RCY + (RRY + 8) * math.sqrt(1 - u * u)
        if abs(x - RCX) < DOOR_HALF and yb > RCY + RRY - 4:
            continue
        for y in range(int(yb - 9), int(yb) + 1):
            if t.get(x, y) in ("E3", "E4", "E2", "E1") and y < yb - 8:
                continue
            k = "E3" if y < yb - 6 else ("E2" if y < yb - 2 else "E1")
            t.set(x, y, k)
    # Türöffnung: Schwelle und Blick nach draußen (dunkel, ein Hauch Nacht)
    for x in range(RCX - DOOR_HALF + 2, RCX + DOOR_HALF - 1):
        for y in range(RCY + RRY - 2, RCY + RRY + 9):
            t.set(x, y, "NV" if y > RCY + RRY + 3 else "E2")
    for x in range(RCX - DOOR_HALF + 2, RCX + DOOR_HALF - 1, 3):
        t.set(x, RCY + RRY + 6, "NB")
    # Astloch in der Rückwand: Nachthimmel, Mondsichel, Sterne
    hx, hy = 104, int(floor_top(104) - 36)
    for y in range(hy - 13, hy + 14):
        for x in range(hx - 11, hx + 12):
            d = math.hypot((x - hx) / 10, (y - hy) / 12.5)
            if d <= 1.15:
                t.set(x, y, "E1" if d > 0.92 else ("E4" if d > 0.85 and x < hx else "NB"))
    for x, y in ((hx - 4, hy - 6), (hx + 5, hy + 4), (hx - 6, hy + 6)):
        t.set(x, y, "GK")
    for y in range(hy - 4, hy + 3):                          # Mondsichel
        for x in range(hx, hx + 6):
            if math.hypot(x - hx - 2, y - hy + 1) <= 3.2 and math.hypot(x - hx - 3.5, y - hy + 1.5) > 2.6:
                t.set(x, y, "EIS" if y < hy else "GEI")
    # Spiegel mit Goldrahmen an der rechten Wand (die Hexe ist eitel)
    mx, my = 290, int(floor_top(290) - 40)
    for y in range(my - 12, my + 13):
        for x in range(mx - 9, mx + 10):
            d = math.hypot((x - mx) / 8, (y - my) / 11)
            if d <= 1.12:
                if d > 0.88:
                    k = "GOLD" if (x < mx or y < my) else "GOLDD"
                else:
                    k = "NBH" if (x - mx) + (y - my) < -6 else "NB"
                t.set(x, y, k)
    t.set(mx - 3, my - 6, "EIS"); t.set(mx - 4, my - 5, "EIS"); t.set(mx + 2, my + 4, "NBH")
    t.set(mx, my - 13, "GOLDH"); t.set(mx, my + 13, "GOLDD")
    # Kräutergirlande über der Tür-Seite: Schnur im Bogen, getrocknete Bündel
    for x in range(198, 246):
        u = (x - 222) / 24
        y = int(floor_top(x) - 50 + 7 * (1 - u * u))
        t.set(x, y, "E2")
        if (x - 198) % 8 == 4:
            for dy in range(1, 6):
                for dx in range(-1 - dy // 3, 2 + dy // 3):
                    c = ["WO", "GD", "FL", "BORH"][(x // 8) % 4] if dy > 2 else "WO"
                    t.set(x + dx, y + dy, c)
    # Deckenbalken: knorriger Ast quer über den Raum, daran hängen die Gläser
    for x in range(RCX - RRX + 6, RCX + RRX - 5):
        u = (x - RCX) / RRX
        yc = 24 + 8 * u * u + 1.5 * math.sin(x * 0.11)
        thick = 4.5 + 1.2 * math.sin(x * 0.07 + 1)
        for y in range(int(yc - thick), int(yc + thick) + 1):
            rel = (y - yc) / thick
            k = "E4" if rel < -0.45 else ("E3" if rel < 0.2 else ("E2" if rel < 0.7 else "E1"))
            if k != "E1" and noise(x * 0.4, y * 3, 1.0, 408) > 0.8:
                k = WOOD[max(0, WOOD.index(k) - 1)]
            t.set(x, y, k)
    # Wurzelpfosten links und rechts der Tür
    for side in (-1, 1):
        x0 = RCX + side * (DOOR_HALF + 1)
        for y in range(RCY + RRY - 10, RCY + RRY + 8):
            for dx in range(-3, 4):
                w = 3.2 - (y - (RCY + RRY - 10)) * 0.05
                if abs(dx) <= w:
                    k = "E3" if dx * side < -1 else ("E2" if dx * side < 2 else "E1")
                    t.set(x0 + dx, y, k)
    return t.outline().image(), (hx, hy)


def beam_y(x):
    """Unterkante des Deckenbalkens bei x (für die Aufhängepunkte der Gläser)."""
    u = (x - RCX) / RRX
    return int(24 + 8 * u * u + 1.5 * math.sin(x * 0.11) + 4.5 + 1.2 * math.sin(x * 0.07 + 1))


# ---------------------------------------------------------------------------
# Möbel und Licht im Innenraum (alle mit Fußpunkt unten Mitte)
def fill(t, x0, y0, x1, y1, k):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            t.set(x, y, k)


def armchair():
    """Abgewetzter Ohrensessel aus Bordeaux-Samt mit Goldknöpfen und Decke. 40x44."""
    t = Layer(40, 44)
    for y in range(2, 30):                                   # hohe Rückenlehne
        for x in range(8, 32):
            if y < 7 and min(x - 8, 31 - x) < 7 - y:
                continue
            t.set(x, y, "BORH" if x < 12 else ("BORD" if x > 27 else "BOR"))
    for y in range(6, 24):                                   # Ohrenbacken
        for x in list(range(4, 9)) + list(range(31, 36)):
            if y < 9 and x in (4, 35):
                continue
            t.set(x, y, "BORH" if x < 7 else ("BORD" if x > 32 else "BOR"))
    for x, y in ((13, 9), (20, 8), (27, 9), (16, 15), (24, 15), (20, 21)):
        t.set(x, y, "GOLD"); t.set(x + 1, y + 1, "BORD")
    for y in range(20, 37):                                  # Armlehnen, rund
        for x in list(range(2, 9)) + list(range(31, 38)):
            if y < 22 and x in (2, 37):
                continue
            t.set(x, y, ("BORH" if x < 5 else "BOR") if x < 20 else ("BORD" if x > 34 else "BOR"))
    fill(t, 9, 27, 30, 33, "BOR")                            # Sitzkissen
    fill(t, 10, 27, 29, 27, "BORH")
    fill(t, 3, 34, 36, 39, "BORD")                           # Vorderkante
    fill(t, 3, 34, 36, 34, "BOR")
    for x in (5, 34):                                        # gedrechselte Füße
        t.set(x, 40, "E3" if x == 5 else "E2"); t.set(x, 41, "E2"); t.set(x, 42, "E2")
    # Strickdecke in Flieder: liegt über der rechten Armlehne und rutscht aufs Kissen
    for y in range(18, 41):
        for x in range(25, 39):
            top = 18 + max(0, (31 - x)) * 1.3 + 1.5 * math.sin(x * 0.9)   # weiche Oberkante
            bottom = 40 - (1 if (x % 3 == 0) else 0)                         # Fransen
            if y < top or y > bottom or x > 38:
                continue
            fold = (x - 25) % 4 == 3                                         # senkrechte Falten
            if x < 31:
                k = "INDH" if fold else "FL"
            else:
                k = "IND" if fold else "INDH"
            if (x + 2 * y) % 7 == 0 and not fold and x < 34:
                k = "LST"                                                    # Strickmuster
            t.set(x, y, k)
    return [t.outline().image()]


def rug():
    """Ovaler Teppich, Bordeaux mit Goldrand und Rautenmuster. 96x40, liegt flach."""
    t = Layer(96, 40)
    for y in range(40):
        for x in range(96):
            d = math.hypot((x - 47.5) / 46, (y - 19.5) / 19.0)
            if d > 1:
                continue
            if d > 0.9:
                k = "GOLDD"
            elif d > 0.84:
                k = "BORD"
            elif d > 0.8:
                k = "GOLD"
            else:
                k = "BORD"
                ux, uy = abs(x - 47.5) / 2.2, abs(y - 19.5)
                ring = ux + uy
                if 9 <= ring < 10 or 17 <= ring < 18:
                    k = "BOR"                                 # Rautenlinien
                if ring < 4:
                    k = "MG"                                  # Mitte: gedämpftes Magenta
                elif ring < 5:
                    k = "GOLDD"
                if (x + y) % 8 == 0 and 11 <= ring < 15:
                    k = "GOLDD"                               # Punkte im Zwischenfeld
            t.set(x, y, k)
    return [t.outline().image()]


def books():
    """Bücherstapel, quer gestapelt. 16x16."""
    t = Layer(16, 16)
    stack = [(2, 13, 12, "BORD"), (3, 10, 10, "IND"), (1, 7, 12, "GD"), (4, 4, 8, "E3")]
    for x0, y0, w, c in stack:
        fill(t, x0, y0, x0 + w - 1, y0 + 2, c)
        fill(t, x0 + 1, y0 + 1, x0 + w - 1, y0 + 1, "KN")     # Seiten
        t.set(x0, y0 + 1, "GOLD")                            # Goldprägung am Rücken
    return [t.outline().image()]


def stove():
    """Kleiner gusseiserner Bauchofen mit Rohr. 32x96, Feuer flackert (4 Frames).
    Das Rohr läuft bis oben in die dunkle Höhlung des Stamms."""
    IRON = ["K1", "K2", "K3", "KR2"]
    OY = 16
    base = Layer(32, 96)
    tmp = Layer(32, 80)
    for y in range(50, 74):                                  # Bauch
        for x in range(4, 28):
            d = math.hypot((x - 15.5) / 11, (y - 61) / 12)
            if d <= 1:
                lit = -(x - 15.5) / 11 * 0.7 - (y - 61) / 12 * 0.5
                tmp.set(x, y, IRON[2] if lit > 0.3 else (IRON[1] if lit > -0.35 else IRON[0]))
    fill(tmp, 6, 47, 25, 49, "K2"); fill(tmp, 6, 47, 25, 47, "KR2")   # Deckplatte
    fill(tmp, 13, 2, 18, 46, "K2")                          # Rohr
    for y in range(2, 47):
        tmp.set(13, y, "K3"); tmp.set(18, y, "K1")
    for y in (14, 30):
        fill(tmp, 12, y, 19, y + 1, "K1"); tmp.set(12, y, "KR2")
    fill(tmp, 12, 0, 19, 2, "K1")                           # Wanddurchführung
    for x, y in ((8, 74), (9, 75), (22, 74), (21, 75), (8, 76), (22, 76)):
        tmp.set(x, y, "K1")                                 # Füße
    for x in range(9, 23):
        tmp.set(x, 77, "K1")
    tmp.set(15, 79, "K1"); tmp.set(16, 79, "K1")
    fill(tmp, 13, 0, 18, 2, "K2")                           # Rohr läuft nach oben weiter
    base.paste(tmp, 0, OY)
    fill(base, 13, 0, 18, OY + 2, "K2")
    for y in range(0, OY + 3):
        base.set(13, y, "K3"); base.set(18, y, "K1")
    fill(base, 12, 6, 19, 7, "K1"); base.set(12, 6, "KR2")  # Manschette
    fires = [
        ["..K...", ".KLK..", "KLLLKK", "GKLKGG"],
        ["...K..", "..KLK.", ".KLLLK", "GGKLKG"],
        [".K..K.", "KLK.LK", "KLLKLK", "GKLLKG"],
        ["..KK..", ".KLLK.", "KKLLKK", "GGKKGG"],
    ]
    frames = []
    for fr in fires:
        t = base.copy()
        fill(t, 11, 57 + OY, 20, 66 + OY, "E1")              # Feueröffnung
        for y in range(54, 57):
            for x in range(11, 21):
                if math.hypot(x - 15.5, (y - 57) * 1.6) <= 5:
                    t.set(x, y + OY, "E1")
        for dy, row in enumerate(fr):
            for dx, ch in enumerate(row):
                if ch != ".":
                    t.set(13 + dx, 61 + dy + OY, {"K": "KL", "L": "LK", "G": "GOLD"}[ch])
        for x in range(11, 21, 2):                           # Rost
            t.set(x, 66 + OY, "K3")
        frames.append(t.outline().image())
    return frames


def chest():
    """Truhe aus Ebenholz mit Goldbeschlägen. 32x28, Frame 0 zu, 1 offen."""
    frames = []
    for opened in (False, True):
        t = Layer(32, 28)
        fill(t, 3, 12, 28, 27, "E2")
        for y in range(12, 28):
            t.set(3, y, "E3"); t.set(4, y, "E3"); t.set(28, y, "E1")
        for x in range(3, 29):
            t.set(x, 19, "E1")                               # Brettfuge
        if not opened:
            for y in range(6, 13):                           # gewölbter Deckel
                for x in range(3, 29):
                    if y < 9 and min(x - 3, 28 - x) < 9 - y:
                        continue
                    t.set(x, y, "E4" if y < 9 else "E3")
            fill(t, 14, 11, 17, 15, "GOLD"); t.set(15, 13, "E1")      # Schloss
        else:
            for y in range(1, 8):                            # Deckel hochgeklappt (Innenseite)
                fill(t, 4, y, 27, y, "E2" if y > 2 else "E3")
            fill(t, 4, 8, 27, 12, "E1")                      # dunkles Innere
            t.set(10, 10, "GOLDH"); t.set(21, 9, "GOLD")     # Glanz von etwas darin
        for x in (8, 23):                                    # Goldbänder
            for y in range(6 if not opened else 1, 28):
                if t.get(x, y) not in (None, "E1"):
                    t.set(x, y, "GOLDD" if x > 16 else "GOLD")
        frames.append(t.outline().image())
    return frames


def shelf():
    """Wurzelregal an der Wand: zwei Bretter auf knorrigen Wurzeln, Gläser,
    Bücher, ein Schädel und Kräuterbündel. 64x64, Fuß = Unterkante an der Wand."""
    t = Layer(64, 64)
    limb(t, [(7, 63, 2.6), (6, 40, 2.2), (8, 18, 2.0), (6, 2, 1.6)], WOOD, bark=False)
    limb(t, [(57, 63, 2.6), (58, 40, 2.2), (56, 18, 2.0), (58, 2, 1.6)], WOOD, bark=False)
    for y0 in (22, 46):
        fill(t, 2, y0, 61, y0 + 3, "E3")
        fill(t, 2, y0, 61, y0, "E4")
        fill(t, 2, y0 + 3, 61, y0 + 3, "E1")
    # oberes Brett: Gläser (Glas Geisterblau, Inhalt farbig), Bücher, Schädel
    for x0, content, h in ((11, "G", 9), (19, "BOR", 7), (26, "FL", 10)):
        y1 = 21
        fill(t, x0, y1 - h + 1, x0 + 5, y1, "GEI")
        fill(t, x0 + 1, y1 - h + 4, x0 + 4, y1 - 1, content)
        t.set(x0 + 1, y1 - h + 2, "EIS")                     # Glanz
        fill(t, x0 + 1, y1 - h - 1, x0 + 4, y1 - h, "E3")    # Korken
    for i, (c, h) in enumerate((("BORD", 12), ("IND", 11), ("GD", 12), ("E3", 10))):
        x = 36 + i * 3
        fill(t, x, 22 - h, x + 2, 21, c)
        t.set(x, 22 - h + 2, "GOLD")
    skull = [".kkkk.", "kkkkkk", "kekkek", "kkkkkk", ".kmmk.", ".k.k.."]
    for dy, row in enumerate(skull):
        for dx, ch in enumerate(row):
            if ch != ".":
                t.set(49 + dx, 16 + dy, {"k": "KN", "e": "E1", "m": "LS"}[ch])
    # unteres Brett: Kerzenstummel, großes Glas, liegende Bücher
    fill(t, 12, 39, 14, 45, "KN"); t.set(13, 38, "E1")
    fill(t, 20, 35, 29, 45, "GEI"); fill(t, 21, 38, 28, 44, "NB"); t.set(21, 36, "EIS")
    for x, y in ((23, 40), (26, 42), (24, 43)):
        t.set(x, y, "GD")                                    # eingelegte Kräuter
    fill(t, 34, 42, 50, 45, "BORD"); fill(t, 35, 39, 49, 41, "IND"); fill(t, 35, 42, 49, 42, "KN")
    # Kräuterbündel hängen unter dem oberen Brett
    for x0 in (15, 30, 44):
        t.set(x0, 26, "E2"); t.set(x0, 27, "E2")
        for dy in range(6):
            for dx in range(-1 - dy // 3, 2 + dy // 3):
                t.set(x0 + dx, 28 + dy, "L3" if dx < 0 else "GD")
    return [t.outline().image()]


def jar_hanging():
    """Glühwürmchen-Glas an einer Schnur. 16x32, 4 Frames (Glühwürmchen blinken)."""
    frames = []
    dots = [[(6, 20), (9, 23)], [(7, 21), (9, 24), (6, 25)], [(8, 20), (6, 23)], [(7, 22), (10, 21)]]
    for f in range(4):
        t = Layer(16, 32)
        for y in range(0, 13):
            t.set(8, y, "E2" if y % 2 else "E3")
        fill(t, 6, 13, 10, 14, "E3")                         # Deckel
        for y in range(15, 30):
            for x in range(3, 14):
                d = math.hypot((x - 8) / 5.4, (y - 22.5) / 7.6)
                if d <= 1:
                    t.set(x, y, "GEI" if d > 0.82 else "NB")
        t.set(5, 18, "EIS"); t.set(5, 19, "EIS")
        for x, y in dots[f]:
            t.set(x, y, "LK")
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if t.get(x + dx, y + dy) == "NB":
                    t.set(x + dx, y + dy, "GOLDH" if f % 2 else "GOLD")
        frames.append(t.outline().image())
    return frames


def candles():
    """Drei Kerzen mit Wachsnasen, Flammen flackern. 16x16, 3 Frames."""
    flames = [[(0, 0, "LK"), (0, -1, "KL"), (0, -2, "GOLDH")],
              [(0, 0, "LK"), (1, -1, "KL"), (1, -2, "GOLDH")],
              [(0, 0, "LK"), (0, -1, "KL"), (-1, -2, "KL")]]
    frames = []
    for f in range(3):
        t = Layer(16, 16)
        for i, (x, h) in enumerate(((4, 7), (8, 10), (12, 5))):
            fill(t, x - 1, 15 - h, x + 1, 15, "KN")
            fill(t, x + 1, 15 - h, x + 1, 15, "LS")
            t.set(x - 1, 15 - h + 2, "LS"); t.set(x - 2, 15 - h + 3, "KN")     # Wachsnase
            t.set(x, 15 - h - 1, "E1")                                          # Docht
            for dx, dy, c in flames[(f + i) % 3]:
                t.set(x + dx, 15 - h - 2 + dy, c)
        frames.append(t.outline().image())
    return frames


def broom():
    """Hexenbesen, an die Wand gelehnt. 16x48."""
    t = Layer(16, 48)
    for k in range(34):                                      # Stiel, leicht schräg
        x = 11 - k * 0.12
        t.set(x, 2 + k, "E4" if k % 5 else "E3")
        t.set(x + 1, 2 + k, "E2")
    for y in range(34, 48):                                  # Reisigbündel
        w = 2 + (y - 34) * 0.35
        for x in range(int(7 - w), int(8 + w) + 1):
            k = "GOLDD" if (x + y) % 3 else "WO"
            if x > 8 + w * 0.3:
                k = "E3" if (x + y) % 2 else "GOLDD"
            t.set(x, y, k)
    for x in range(5, 11):
        t.set(x, 36, "BORD")                                 # Bindung
    return [t.outline().image()]


def firewood():
    """Gestapeltes Feuerholz neben dem Ofen. 28x19."""
    t = Layer(28, 19)
    for cx, cy in ((6, 15), (14, 15), (22, 15), (10, 9), (18, 9), (14, 3)):
        for y in range(cy - 3, cy + 4):
            for x in range(cx - 4, cx + 4):
                d = math.hypot((x + 0.5 - cx) / 3.8, (y + 0.5 - cy) / 3.4)
                if d <= 1:
                    k = "E2" if d > 0.75 else ("E4" if d > 0.45 else "LST")
                    if 0.35 < d < 0.5:
                        k = "E3"
                    t.set(x, y, k)
    return [t.outline().image()]


def doormat():
    """Fußmatte an der Tür, geflochten. 40x12, liegt flach."""
    t = Layer(40, 12)
    for y in range(1, 11):
        for x in range(1, 39):
            if (x in (1, 38) and y in (1, 10)):
                continue
            k = "WO" if ((x // 2 + y) % 2) else "GOLDD"
            if y in (1, 10) or x in (1, 38):
                k = "E3"
            t.set(x, y, k)
    return [t.outline().image()]


def moonbeam_texture():
    """Weiche Lichttextur für ein PointLight2D (Mondstrahl schräg durchs Astloch).
    Lichttexturen dürfen weich sein, wie die vorhandenen light_round_*.png."""
    w, h = 128, 192
    im = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    px = im.load()
    x0, y0, x1, y1 = 20, 0, 100, 180
    L = math.hypot(x1 - x0, y1 - y0)
    for y in range(h):
        for x in range(w):
            t_ = ((x - x0) * (x1 - x0) + (y - y0) * (y1 - y0)) / (L * L)
            if t_ < 0 or t_ > 1.05:
                continue
            cx, cy = x0 + (x1 - x0) * t_, y0 + (y1 - y0) * t_
            d = math.hypot(x - cx, y - cy)
            width = 10 + 26 * t_
            a = max(0.0, 1 - d / width) ** 1.6 * (0.35 + 0.65 * t_) * (1 - max(0, t_ - 0.85) / 0.2)
            px[x, y] = (255, 255, 255, int(255 * min(1, a)))
    out = ROOT / "assets/effects/lights"
    im.save(out / "light_moonbeam.png")
    print("  light_moonbeam.png (128x192, weich, für PointLight2D)")


GLOW_EXT = ("KL", "LK", "GOLDH")


def main(names):
    if "exterior" in names:
        save(OUT, "hollow_tree", tree_exterior(), glow=GLOW_EXT)
    if "room" in names:
        img, hole = room()
        save(OUT, "shelter_room", [img], foot=False)
        print(f"    Astloch (Mondlicht) bei {hole}; Gläser hängen am Balken: "
              f"{[(x, beam_y(x)) for x in (66, 146, 186)]}")
    if "props" in names:
        save(OUT, "shelter_armchair", armchair())
        save(OUT, "shelter_rug", rug())
        save(OUT, "shelter_books", books())
        save(OUT, "shelter_stove", stove(), glow=("KL", "LK"))
        save(OUT, "shelter_chest", chest())
        save(OUT, "shelter_shelf", shelf())
        save(OUT, "shelter_jar", jar_hanging(), foot=False, glow=("LK", "GOLDH"))
        save(OUT, "shelter_candles", candles(), glow=("LK", "KL", "GOLDH"))
        save(OUT, "shelter_broom", broom())
        save(OUT, "shelter_firewood", firewood())
        save(OUT, "shelter_doormat", doormat())
        moonbeam_texture()


if __name__ == "__main__":
    main(sys.argv[1:] or ["exterior", "room", "props"])
