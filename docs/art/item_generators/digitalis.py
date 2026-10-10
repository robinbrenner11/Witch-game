"""Digitalis, die Waffe der Hexe: ein Fingerhut als Stab.

Aufruf (aus dem Projektordner):
    python docs/art/item_generators/digitalis.py <Zielordner>

Entscheidungen (09.10. und 10.10.2026, siehe game_design.md, Abschnitt 6):
- oben eingerollt wie ein kleiner Hirtenstab, viele Fingerhut-Glocken in
  kräftigem Lila, Griff ganz in Gold;
- Stängel dunkel (Ebenholz), Blätter grün; fast so hoch wie die Hexe;
- die Spitze glimmt immer leicht (Idle), beim Angriff glühen die Blüten auf.

Alles ist von Hand als Pixelraster gesetzt (Glocken als kleine Stempel, Bogen
als Ring), nichts wird skaliert. Licht von oben links, Kontur Aubergine, auf
der Schattenseite Nachtviolett.

Ausgabe (alle Frames 24×60, waagerecht nebeneinander; Fußpunkt zwischen
Pixelspalte 10 und 11 an der Unterkante, Spitze bei Pixel (16, 10)):
- digitalis_idle.png / _glow.png      4 Frames, Spitze pulsiert (4 FPS, Loop)
- digitalis_attack.png / _glow.png    4 Frames, Blüten glühen auf (12 FPS, einmal)
- digitalis_icon.png / _glow.png      16×16 für Hotbar, Inventar, Grimoire
Die _glow-Ebenen enthalten nur die selbstleuchtenden Pixel (wie bei Pilzen
und Trank-Effekten): als zweites Sprite darüber, light_mode = Unshaded.
"""
import math
import sys
from pathlib import Path

from PIL import Image

W, H = 24, 60
SX = 10  # linke Spalte des Schafts; Fußpunkt x = SX + 1
# Golddraht-Wicklung = Stelle der Hand. Der Stab endet oben auf Kopfhöhe der
# Hexe (62 px über dem Boden, er schwebt also 2 px), dann liegt ihre Hand
# (ca. 24 bis 28 px über dem Boden) genau auf diesen Zeilen.
GRIP_TOP, GRIP_BOTTOM = 36, 43

BASE = {
    "o": (43, 22, 51),       # Aubergine (Kontur)
    "x": (26, 20, 46),       # Nachtviolett (Kontur Schattenseite)
    "D": (110, 70, 40),      # Gold sehr dunkel (neu)
    "d": (156, 104, 52),     # Gold dunkel
    "g": (217, 164, 65),     # Gold
    "h": (244, 204, 120),    # Gold hell
    "w": (255, 246, 220),    # Lichtkern warmweiss
    "1": (32, 20, 30),       # Ebenholz 1 (Stängel Schatten)
    "2": (78, 52, 64),       # Ebenholz 3 (Stängel)
    "3": (104, 72, 84),      # Ebenholz 4 (Stängel Licht)
    "8": (130, 124, 136),    # Rinde tot 4 (Randlicht am Bogen)
    "5": (36, 74, 58),       # Giftgrün dunkel (Blatt)
    "6": (63, 125, 90),      # Giftgrün (Blatt)
    "7": (98, 160, 110),     # Giftgrün hell (Blatt)
    "v": (58, 22, 80),       # Lila tief (neu)
    "q": (106, 36, 148),     # Lila dunkel (neu)
    "p": (154, 60, 200),     # Lila (neu)
    "l": (199, 123, 232),    # Lila hell (neu)
    "L": (236, 200, 255),    # Lila glühend (neu, nur beim Angriff)
    "c": (234, 223, 203),    # Knochen (Lippe der Glocke)
    "k": (198, 184, 190),    # Laken Schatten (Lippe im Schatten)
    "M": (92, 30, 78),       # Magenta gedämpft (Glimmen, schwach)
    "m": (194, 48, 122),     # Magenta
    "n": (228, 88, 177),     # Magenta hell
    "r": (255, 210, 236),    # Magenta hell rosa
}
OUTLINE = set("ox")
PURPLE = set("vqplLck")

LARGE = [".lp.",
         "lppq",
         "lppq",
         "lpqq",
         "kvvk",
         ".c.."]
MED = [".l.",
       "lpq",
       "lqq",
       "kvk"]
BUD = ["lp",
       "qv"]
TINY = ["p",
        "q"]
LARGE_L = [r[::-1] for r in LARGE]
MED_L = [r[::-1] for r in MED]

# Glocken: (Form, x, y, hinten?, Stiel (x, y) oder None). Reihenfolge = hinten nach vorne.
# Rechts hängt die Traube (Fingerhut blüht einseitig), links nur wenige.
BELLS = [
    (BUD, SX - 3, 11, True, (SX - 1, 11)),
    (MED_L, SX - 4, 16, True, (SX - 1, 16)),
    (MED_L, SX - 4, 22, True, (SX - 1, 22)),
    (TINY, SX + 3, 9, False, (SX + 2, 9)),
    (BUD, SX + 3, 12, False, (SX + 2, 12)),
    (MED, SX + 7, 17, True, None),
    (MED, SX + 3, 15, False, (SX + 2, 15)),
    (MED, SX + 7, 23, True, None),
    (LARGE, SX + 3, 18, False, (SX + 2, 19)),
    (MED, SX + 7, 29, True, None),
    (LARGE, SX + 2, 23, False, (SX + 2, 23)),
    (LARGE, SX + 3, 28, False, (SX + 2, 28)),
]

# Aufglühen beim Angriff: jede Stufe hellt die Glockenfarben auf.
BLOOM_SHIFT = [
    {},
    {"v": "q", "q": "p", "k": "c"},
    {"v": "q", "q": "p", "p": "l", "l": "L", "k": "c"},
]
DARKER = {"l": "p", "p": "q", "q": "v", "c": "k"}

# Glimmen der Spitze: Farben der Knospe je Stufe (oben, Mitte links, Mitte
# rechts, unten …) und zusätzliche Schein-Pixel rundherum.
TIP_SHAPE = [".a",
             "ab",
             "ca",
             ".c"]
TIP_LEVELS = [
    {"a": "m", "b": "n", "c": "M"},
    {"a": "n", "b": "r", "c": "m"},
    {"a": "n", "b": "r", "c": "n"},
    {"a": "r", "b": "w", "c": "n"},
]
TIP_X, TIP_Y = 15, 8
# Schein um die Knospe (nur auf leeren Pixeln, nur in der Glow-Ebene sichtbar)
HALO = {2: [(TIP_X + 2, TIP_Y + 1), (TIP_X - 1, TIP_Y + 2)],
        3: [(TIP_X + 2, TIP_Y + 1), (TIP_X - 1, TIP_Y + 2), (TIP_X + 1, TIP_Y + 4), (TIP_X + 2, TIP_Y + 3)]}
# Funken beim Angriff (frei schwebend um die Spitze)
SPARKS = [(TIP_X + 4, TIP_Y - 1), (TIP_X - 2, TIP_Y - 1), (TIP_X + 4, TIP_Y + 5), (TIP_X + 6, TIP_Y + 2)]


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [["." for _ in range(w)] for _ in range(h)]
        self.glow = set()

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def put(self, x, y, ch, over=None, glowing=False):
        if not self.inside(x, y):
            return
        cur = self.px[y][x]
        if over is not None and cur != "." and cur not in over:
            return
        self.px[y][x] = ch
        if glowing:
            self.glow.add((x, y))

    def stamp(self, rows, x0, y0, over=None, glowing=False):
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch not in " .":
                    self.put(x0 + dx, y0 + dy, ch, over, glowing)

    def outline(self):
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] != ".":
                    continue
                nb = [(x + a, y + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                filled = [(a, b) for a, b in nb if self.inside(a, b) and self.px[b][a] not in OUTLINE | {"."}]
                if filled:
                    shadow = all(a <= x and b <= y for a, b in filled)
                    add.append((x, y, "x" if shadow else "o"))
        for x, y, ch in add:
            self.px[y][x] = ch

    def images(self, colors):
        img = Image.new("RGBA", (self.w, self.h))
        glow = Image.new("RGBA", (self.w, self.h))
        for y in range(self.h):
            for x in range(self.w):
                ch = self.px[y][x]
                if ch != ".":
                    img.putpixel((x, y), colors[ch] + (255,))
                    if (x, y) in self.glow:
                        glow.putpixel((x, y), colors[ch] + (255,))
        return img, glow


def bell(cv, rows, x0, y0, behind, bloom):
    """Glocke mit eigener Kontur. Vorne liegende Glocken überdecken die
    dahinter, aber nie Stängel, Gold oder Blätter."""
    over = {".", "o", "x"} if behind else {".", "o", "x"} | PURPLE
    h, w = len(rows), len(rows[0])
    filled = {(dx, dy) for dy in range(h) for dx in range(w) if rows[dy][dx] not in " ."}
    for dx, dy in filled:
        for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (dx + ax, dy + ay) not in filled:
                cv.put(x0 + dx + ax, y0 + dy + ay, "o", over)
    shift = BLOOM_SHIFT[bloom]
    for dx, dy in filled:
        ch = rows[dy][dx]
        if behind:
            ch = DARKER.get(ch, ch)
        ch = shift.get(ch, ch)
        cv.put(x0 + dx, y0 + dy, ch, over, glowing=bloom > 0)


def draw_staff(tip=0, bloom=0, sparks=False):
    cv = Canvas(W, H)
    # Stängel bis in den Bogen
    for y in range(4, 33):
        cv.put(SX, y, "3" if y % 6 else "2")
        cv.put(SX + 1, y, "1" if y > 6 else "2")
    # Hirtenstab-Bogen als Ring, 2 px dick
    cx, cy = 13.5, 5.0
    for y in range(0, 9):
        for x in range(SX, 20):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy)
            if not (2.0 <= d <= 4.1) or (dy > 0.5 and dx < 0) or dy > 2.6:
                continue
            outer = d > 3.05
            if outer and dx < 1.0:
                ch = "8" if dy < -1.5 else "3"   # Randlicht oben links
            elif outer:
                ch = "2"
            else:
                ch = "2" if dx < 0 else "1"
            cv.put(x, y, ch)
    cv.put(SX, 4, "8"); cv.put(SX, 5, "3")
    # Stiel der Spitze
    cv.put(TIP_X + 1, TIP_Y, "1")
    # Glocken
    for rows, x, y, behind, stalk in BELLS:
        if stalk:
            cv.put(stalk[0], stalk[1], "2", over={".", "o", "x"})
        bell(cv, rows, x, y, behind, bloom)
    # Blätter am Kragen (lanzettlich, grün)
    cv.stamp([".....7",
              "...776",
              "..7665",
              ".7665.",
              "7665..",
              "65...."], SX - 6, 27, over={".", "o", "x"})
    cv.stamp(["76..",
              ".665",
              "..55"], SX + 2, 33, over={".", "o", "x"})
    # Kragen mit Magenta-Stein
    cv.stamp(["hggd",
              "gnmD",
              "dddD"], SX - 1, 32)
    # Griff aus Gold; oben, wo die Hand ihn hält, mit Golddraht umwickelt
    for y in range(35, 57):
        if GRIP_TOP <= y <= GRIP_BOTTOM:
            cv.put(SX, y, "h" if y % 2 == 0 else "g")
            cv.put(SX + 1, y, "g" if y % 2 == 0 else "D")
        else:
            cv.put(SX, y, "g")
            cv.put(SX + 1, y, "d")
    cv.put(SX, GRIP_BOTTOM + 3, "h"); cv.put(SX, GRIP_BOTTOM + 4, "w"); cv.put(SX, 53, "h")
    for y in (GRIP_TOP - 1, GRIP_BOTTOM + 1):
        cv.put(SX - 1, y, "d"); cv.put(SX, y, "h"); cv.put(SX + 1, y, "g"); cv.put(SX + 2, y, "D")
    # Fuß mit kleinen goldenen Wurzeln
    cv.put(SX, 57, "d"); cv.put(SX + 1, 57, "D")
    cv.put(SX, 58, "d")
    cv.put(SX - 1, 58, "d"); cv.put(SX - 2, 59, "D")
    cv.put(SX + 1, 58, "D"); cv.put(SX + 2, 59, "D")
    # Spitze: glimmende Knospe
    lv = TIP_LEVELS[tip]
    for dy, row in enumerate(TIP_SHAPE):
        for dx, key in enumerate(row):
            if key != ".":
                cv.put(TIP_X + dx, TIP_Y + dy, lv[key], glowing=True)
    cv.outline()
    # Schein und Funken erst nach der Kontur: frei schwebende Lichtpunkte
    for x, y in HALO.get(tip, []):
        if cv.px[y][x] in {".", "o", "x"}:
            cv.put(x, y, "M" if tip < 3 else "m", glowing=True)
    if sparks:
        for i, (x, y) in enumerate(SPARKS):
            if cv.px[y][x] == ".":
                cv.put(x, y, "r" if i % 2 == 0 else "n", glowing=True)
    return cv.images(BASE)


def strip(frames):
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h))
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    return out


ICON = [
    "................",
    "...........833..",
    "..........3...2.",
    ".........32...1.",
    "........32....n.",
    ".......32.lp.nr.",
    "......32.llq..m.",
    ".....32..kvv....",
    "....mg.lp.c.....",
    "...gd..lpq......",
    "..hd...kvk......",
    ".hd.....c.......",
    ".gd.............",
    ".d..............",
    "................",
    "................",
]


def draw_icon():
    """16×16 für Hotbar, Inventar und Grimoire: der Stab schräg wie ein
    Werkzeug-Icon, Goldgriff unten links, Haken mit Spitze oben rechts,
    zwei Glocken hängen nach unten. Von Hand gesetzt, Kontur automatisch."""
    cv = Canvas(16, 16)
    for y, row in enumerate(ICON):
        for x, ch in enumerate(row):
            if ch != ".":
                # Leuchten nur die Spitze (oben rechts), nicht der Kragen-Stein.
                cv.put(x, y, ch, glowing=ch in "nrm" and x >= 12)
    cv.outline()
    return cv.images(BASE)


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    idle = [draw_staff(tip=t) for t in (0, 1, 2, 1)]
    attack = [draw_staff(tip=3, bloom=b, sparks=s) for b, s in ((1, False), (2, True), (2, False), (1, False))]
    for name, frames in (("idle", idle), ("attack", attack)):
        strip([f[0] for f in frames]).save(out / f"digitalis_{name}.png")
        strip([f[1] for f in frames]).save(out / f"digitalis_{name}_glow.png")
    icon, icon_glow = draw_icon()
    icon.save(out / "digitalis_icon.png")
    icon_glow.save(out / "digitalis_icon_glow.png")
    print("fertig:", ", ".join(sorted(p.name for p in out.glob("digitalis_*.png"))))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/items/digitalis")
