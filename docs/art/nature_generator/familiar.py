"""Begleiterin (Vertraute) für später: schwarze Katze (Bitterbloom).

Aufruf (aus dem Projektordner):
    python docs/art/nature_generator/familiar.py

Schwarz mit violettem Schimmer, goldene Augen (leuchten nachts, Glow-Ebene),
Halsband in Magenta mit Goldglöckchen. Die Aubergine-Kontur ist heller als das
Fell und wirkt dadurch wie eine Lichtkante – so bleibt die Katze auf dunklem
Boden sichtbar.

Alle Frames 32x24, Fußpunkt unten Mitte (16, 23). Seite = Blick nach RECHTS.
Ausgabe: assets/characters/familiar/cat_<animation>.png (+ _glow)
"""
import math
from nature import Layer, save, ROOT

OUT = "assets/characters/familiar"
FUR = ["TS", "NV", "IND", "INDH"]          # Schatten -> Glanz
W, H = 32, 24


def lum(nx, ny):
    nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
    return (-0.55 * nx - 0.75 * ny + 0.62 * nz + 0.35) / 1.35


def ellipse(t, cx, cy, rx, ry, ramp=FUR, bias=0.0):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if nx * nx + ny * ny > 1:
                continue
            l = lum(nx, ny) + bias
            # schwarzes Fell: fast alles Tiefschwarz/Nachtviolett, Indigo nur als Glanzkante
            k = 0 if l < 0.42 else (1 if l < 0.8 else (2 if l < 0.95 else 3))
            t.set(x, y, ramp[k])


def line(t, pts, k, width=1):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for s in range(n + 1):
            x = x0 + (x1 - x0) * s / n
            y = y0 + (y1 - y0) * s / n
            for w in range(width):
                t.set(x + w, y, k)


def ears(t, cx, top, spread=3, back=False):
    for side in (-1, 1):
        x = cx + side * spread
        t.set(x, top, "NV"); t.set(x, top + 1, "NV"); t.set(x - side, top + 1, "NV")
        t.set(x, top + 2, "NV"); t.set(x - side, top + 2, "NV")
        if not back:
            t.set(x - side * 0, top + 2, "MG")               # Innenohr


def eyes_front(t, cx, y, closed=False):
    for side in (-1, 1):
        x = cx + side * 2 - (1 if side < 0 else 0)
        if closed:
            t.set(x, y + 1, "IND"); t.set(x + 1, y + 1, "IND")
        else:
            t.set(x, y, "GOLDH"); t.set(x + 1, y, "GOLD")
            t.set(x, y + 1, "GOLD"); t.set(x + 1, y + 1, "TS")


def collar(t, cx, y, half=3):
    for x in range(cx - half, cx + half + 1):
        t.set(x, y, "M" if x < cx else "MG")
    t.set(cx, y + 1, "GOLD")                                  # Glöckchen


def tail(t, pts):
    line(t, pts, "NV", 2)
    x, y = pts[-1]
    t.set(x, y, "IND")


# ---------------------------------------------------------------------------
TAIL_SWAY = [0, 1, 2, 1]


def sit_down(f):
    """Sitzen, Blick nach unten (Vorderansicht). Schwanz wiegt, Frame 3 blinzelt."""
    t = Layer(W, H)
    s = TAIL_SWAY[f]
    tail(t, [(20, 22), (23, 21), (25, 18 - s), (24 + s, 15 - s)])
    ellipse(t, 16, 17, 5.5, 6.2)                              # Körper
    for x in (13, 14, 18, 19):                                # Vorderbeine
        for y in range(19, 24):
            t.set(x, y, "NV" if x in (13, 18) else "TS")
    t.set(13, 23, "IND"); t.set(18, 23, "IND")                # Pfoten
    ellipse(t, 16, 9, 4.6, 4.0)                               # Kopf
    ears(t, 16, 3)
    eyes_front(t, 16, 8, closed=(f == 3))
    t.set(16, 11, "MG")                                       # Nase
    collar(t, 16, 13)
    return t


def sit_up(f):
    """Sitzen von hinten. Schwanz liegt am Boden und wiegt."""
    t = Layer(W, H)
    s = TAIL_SWAY[f]
    ellipse(t, 16, 17, 5.5, 6.2, bias=-0.08)
    ellipse(t, 16, 9, 4.6, 4.0, bias=-0.08)
    ears(t, 16, 3, back=True)
    for x in range(12, 21):
        t.set(x, 13, "MG")                                    # Halsband hinten
    tail(t, [(16, 22), (12, 23), (8, 22 - s // 2), (6 - s, 20 - s)])
    return t


def sit_side(f):
    """Sitzen seitlich (Blick nach rechts). Schwanz wiegt, Frame 2 zuckt ein Ohr."""
    t = Layer(W, H)
    s = TAIL_SWAY[f]
    tail(t, [(11, 22), (7, 22), (5, 20 - s), (5 + s, 17 - s)])
    ellipse(t, 14, 17, 5.2, 6.0)
    for y in range(18, 24):                                   # Vorderbein
        t.set(18, y, "NV"); t.set(19, y, "TS")
    t.set(18, 23, "IND")
    ellipse(t, 18, 9, 4.2, 3.8)
    for dx, dy in ((0, 0), (0, 1), (-1, 1), (0, 2), (-1, 2)):  # Ohren
        t.set(16 + dx, 4 + dy - (1 if f == 2 else 0), "NV")
        t.set(20 + dx, 4 + dy, "NV")
    t.set(16, 6, "MG")
    t.set(20, 8, "GOLDH"); t.set(21, 8, "TS"); t.set(20, 9, "GOLD")   # Auge
    t.set(22, 10, "MG")                                       # Nase
    for x in range(16, 20):
        t.set(x, 13, "M" if x < 18 else "MG")
    t.set(19, 14, "GOLD")
    return t


# Laufen seitlich: 6 Frames Trab; Beinversatz vorne/hinten, nah/fern
LEG_CYCLE = [(-2, 1), (-1, 2), (0, 2), (1, 1), (2, 0), (0, 0)]


def walk_side(f):
    t = Layer(W, H)
    bob = 1 if f in (1, 4) else 0
    lf, lb = LEG_CYCLE[f], LEG_CYCLE[(f + 3) % 6]
    # ferne Beine (dunkel) zuerst
    for bx, (dx, lift) in ((20, lb), (10, lf)):
        line(t, [(bx + 1, 17 - bob), (bx + 1 - dx, 23 - lift)], "TS", 2)
    tail(t, [(8, 15 - bob), (5, 13 - bob), (4, 10 - bob - (f % 3 == 0)), (6, 8 - bob)])
    ellipse(t, 14, 16 - bob, 7.2, 3.6)                       # Körper
    ellipse(t, 20, 15 - bob, 3.6, 3.6)                       # Brust
    for bx, (dx, lift) in ((20, lf), (10, lb)):               # nahe Beine (heller)
        line(t, [(bx, 17 - bob), (bx + dx, 23 - lift)], "NV", 2)
        t.set(bx + dx, 23 - lift, "IND")
    ellipse(t, 23, 10 - bob, 3.8, 3.4)                       # Kopf
    for dx, dy in ((0, 0), (0, 1), (-1, 1), (0, 2), (-1, 2)):
        t.set(22 + dx, 5 + dy - bob, "NV"); t.set(25 + dx, 5 + dy - bob, "NV")
    t.set(22, 7 - bob, "MG")
    t.set(24, 9 - bob, "GOLDH"); t.set(25, 9 - bob, "TS")
    t.set(27, 11 - bob, "MG")
    for y in range(12, 15):
        t.set(20, y - bob, "M" if y < 14 else "MG")
    t.set(21, 15 - bob, "GOLD")
    return t


def walk_down(f):
    """Laufen auf die Kamera zu: Vorderpfoten abwechselnd, leichtes Wippen."""
    t = Layer(W, H)
    bob = 1 if f in (1, 3) else 0
    s = [0, 1, 0, -1][f]
    tail(t, [(19, 14 - bob), (22, 11 - bob), (23 + s, 7 - bob)])
    ellipse(t, 16, 16 - bob, 5.2, 4.6)
    for i, x in enumerate((13, 18)):                          # Vorderbeine abwechselnd
        lift = 2 if (f % 2 == 1 and (i == f // 2)) else 0
        for y in range(18 - bob, 24 - lift):
            t.set(x, y, "NV"); t.set(x + 1, y, "TS")
        t.set(x, 23 - lift, "IND")
    ellipse(t, 16, 10 - bob, 4.6, 4.0)
    ears(t, 16, 4 - bob)
    eyes_front(t, 16, 9 - bob)
    t.set(16, 12 - bob, "MG")
    collar(t, 16, 14 - bob)
    return t


def walk_up(f):
    """Laufen von der Kamera weg: Rücken, Schwanz steil nach oben."""
    t = Layer(W, H)
    bob = 1 if f in (1, 3) else 0
    s = [0, 1, 0, -1][f]
    ellipse(t, 16, 16 - bob, 5.2, 4.8, bias=-0.08)
    for i, x in enumerate((13, 18)):                          # Hinterbeine abwechselnd
        lift = 2 if (f % 2 == 1 and (i == f // 2)) else 0
        for y in range(19 - bob, 24 - lift):
            t.set(x, y, "NV"); t.set(x + 1, y, "TS")
    ellipse(t, 16, 9 - bob, 4.4, 3.8, bias=-0.08)
    ears(t, 16, 3 - bob, back=True)
    for x in range(12, 21):
        t.set(x, 13 - bob, "MG")
    tail(t, [(16, 18 - bob), (16 + s, 13 - bob), (17 + s, 8 - bob), (16 + 2 * s, 5 - bob)])
    return t


def sleep(f):
    """Eingerollt schlafen, atmet (2 Frames, 1-2 FPS)."""
    t = Layer(W, H)
    br = 0.4 if f else 0.0
    ellipse(t, 16, 19, 8.5, 4.3 + br)
    ellipse(t, 10, 18, 3.6, 3.2 + br)                         # Kopf eingekuschelt
    for dx, dy in ((0, 0), (1, 0), (0, 1)):
        t.set(8 + dx, 14 + dy, "NV"); t.set(11 + dx, 14 + dy, "NV")
    t.set(9, 18, "IND"); t.set(10, 18, "IND")                 # geschlossenes Auge
    line(t, [(23, 20), (21, 23), (14, 23), (9, 22)], "NV", 2)  # Schwanz ums Gesicht
    t.set(9, 21, "IND")
    t.set(12, 20, "M"); t.set(13, 20, "GOLD")                 # Halsband blitzt hervor
    return t


ANIMS = {
    "cat_idle_down": (sit_down, 4), "cat_idle_up": (sit_up, 4), "cat_idle_side": (sit_side, 4),
    "cat_walk_down": (walk_down, 4), "cat_walk_up": (walk_up, 4), "cat_walk_side": (walk_side, 6),
    "cat_sleep": (sleep, 2),
}


def main():
    for name, (fn, n) in ANIMS.items():
        frames = [fn(i).outline().image() for i in range(n)]
        save(OUT, name, frames, glow=("GOLDH",) if "sleep" not in name else None)


if __name__ == "__main__":
    main()
