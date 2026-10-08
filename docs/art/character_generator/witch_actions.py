"""Aktions-Animationen der Hexe (Bitterbloom).

Aufruf (aus dem Projektordner):
    python docs/art/character_generator/witch_actions.py            # alle fertigen Animationen
    python docs/art/character_generator/witch_actions.py pour_down  # nur eine

Arbeitsweise: Grundlage ist der passende Idle-Frame aus
assets/characters/witch_idle.png. Der Körper ab der Hüfte (Füße!) bleibt
pixelgleich, darüber werden Arm, Hand und Fläschchen als kleine Stempel
gemalt. Neue Teile bekommen eine Aubergine-Kontur.

Ausgabe:
    assets/characters/witch_<aktion>_<richtung>.png   (Frames à 32x64 nebeneinander)
    docs/art/vorschau/vorschau_<aktion>_4x.gif        (alle fertigen Richtungen)
    docs/art/vorschau/vergleich_<aktion>_4x.png       (Idle neben Schlüssel-Frame)
"""
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
CHAR = ROOT / "assets" / "characters"
PREVIEW = ROOT / "docs" / "art" / "vorschau"
FW, FH = 32, 64

# Zeichen -> Farbe. Alles außer den markierten Tönen steht schon in hexen_palette.gpl.
C = {
    "#": (14, 10, 20),     # Tiefschwarz (Finger, Kontur wie im Bestand)
    "a": (43, 22, 51),     # Aubergine (Kontur neuer Teile)
    "b": (77, 18, 48),     # Bordeaux dunkel (Ärmel)
    "r": (110, 24, 48),    # Bordeaux (Ärmel-Licht)
    "s": (107, 63, 51),    # Haut licht
    "t": (74, 43, 39),     # Haut mittel
    "G": (217, 164, 65),   # Gold
    "k": (156, 104, 52),   # Gold dunkel
    "g": (31, 36, 74),     # Glas leer
    "n": (52, 70, 120),    # Nachtblau hell (Glas-Mittelton)
    "l": (120, 140, 185),  # Geisterblau (Glanz)
    "m": (194, 48, 122),   # Magenta
    "M": (228, 88, 177),   # Magenta hell
    "P": (255, 210, 236),  # Magenta hell rosa (Funkenkern)
    "d": (92, 30, 78),     # Magenta gedaempft (verglühende Funken)
}

IDLE_INDEX = {"down": 0, "up": 1, "side": 2}


def idle(direction):
    sheet = Image.open(CHAR / "witch_idle.png").convert("RGBA")
    i = IDLE_INDEX[direction]
    return sheet.crop((i * FW, 0, i * FW + FW, FH))


def stamp(img, rows, x0, y0):
    """Malt ein Zeichenraster; '.' bleibt durchsichtig/unverändert."""
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch == "." or ch == " ":
                continue
            x, y = x0 + dx, y0 + dy
            if 0 <= x < FW and 0 <= y < FH:
                img.putpixel((x, y), C[ch] + (255,))


def shift(img, y1, dx=0, dy=0, y0=0):
    """Verschiebt die Zeilen y0..y1-1 um (dx, dy), z. B. Oberkörper beim Bücken
    oder nur den Kopf beim Trinken. Alles darunter (Beine, Füße) bleibt stehen.
    Was beim Verschieben frei wird, füllt das Original auf, damit keine Löcher
    in der Silhouette entstehen."""
    out = img.copy()
    part = img.crop((0, y0, FW, y1))
    keep_from = y1 + min(dy, 0)          # beim Hochschieben: Saum aus dem Original
    for y in range(y0, min(y1, keep_from)):
        for x in range(FW):
            out.putpixel((x, y), (0, 0, 0, 0))
    tmp = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    for y in range(part.height):
        for x in range(FW):
            c = part.getpixel((x, y))
            nx, ny = x + dx, y0 + y + dy
            if c[3] and 0 <= nx < FW and 0 <= ny < FH:
                tmp.putpixel((nx, ny), c)
    out.alpha_composite(tmp)
    return out


def shift_upper(img, dy, until_y):
    return shift(img, until_y, 0, dy)


# --------------------------------------------------------------------------
# Zauber-Ausgießen: keine Flasche mehr. Die Hexe streckt die Hand mit den
# schwarzen Fingern aus, an den Fingerspitzen sprühen Magenta-Funken, und der
# Trank fliegt als Tropfen-Orb (eigener Effekt, siehe pour_effect) zur Pflanze.

SLEEVE_OUT = ["aa....",
              "abba..",
              "arbbaa",
              ".abbba",
              "..abba",
              "...aGa"]                  # Ärmel schräg nach außen, Goldreif am Ende
SLEEVE_HALF = ["aaa..",
               "abba.",
               "arbba",
               ".abba",
               "..aGa"]                  # Arm halb gehoben
HAND_FIST = ["a##a",
             "###a",
             "a##."]                     # Finger locker zusammen
HAND_SPREAD = [".a##.",
               "a####",
               "#.#.#",
               "#...#"]                  # Finger gespreizt, Handfläche Richtung Pflanze
HAND_HALF = [".a##",
             "a###",
             "#.##",
             "#..."]                     # Finger schließen sich wieder

SPARK_BIG = [".M.",
             "MPM",
             ".M."]
SPARK_MID = ["m.",
             ".M"]


def pour_down():
    base = idle("down")
    frames = []

    # F1 – Hand heben (Arm halb draußen), erstes Glimmen
    f = base.copy()
    stamp(f, SLEEVE_HALF, 20, 23)
    stamp(f, HAND_FIST, 24, 28)
    stamp(f, ["m"], 27, 30)
    frames.append(f)

    # F2 – Arm ausgestreckt, Finger gespreizt, Funken an den Fingerspitzen
    f = shift_upper(base, 1, 34)
    stamp(f, SLEEVE_OUT, 20, 21)
    stamp(f, HAND_SPREAD, 24, 26)
    stamp(f, SPARK_MID, 24, 30)
    stamp(f, ["M"], 28, 31)
    frames.append(f)

    # F3 – Stoß: Hand 1 px vor, große Funken, hier startet der Orb
    f = shift_upper(base, 1, 34)
    stamp(f, SLEEVE_OUT, 20, 22)
    stamp(f, HAND_SPREAD, 24, 27)
    stamp(f, SPARK_BIG, 23, 31)
    stamp(f, SPARK_BIG, 27, 30)
    stamp(f, ["m"], 30, 28)
    frames.append(f)

    # F4 – halten, Funken verglühen
    f = shift_upper(base, 1, 34)
    stamp(f, SLEEVE_OUT, 20, 22)
    stamp(f, HAND_HALF, 24, 27)
    stamp(f, ["d", ".", "m"], 24, 31)
    stamp(f, ["d.", ".d"], 28, 30)
    frames.append(f)

    # F5 – Arm sinkt zurück
    f = base.copy()
    stamp(f, SLEEVE_HALF, 20, 24)
    stamp(f, HAND_FIST, 24, 29)
    frames.append(f)

    # Startpunkt des Orbs je Frame (Fingerspitzen), Koordinaten im 32x64-Frame
    orb = [None, None, (26, 31), None, None]
    return frames, orb


# --------------------------------------------------------------------------
# Gemeinsame Stempel für die übrigen Richtungen/Aktionen

VIAL_UP = [".aGa.",          # Fläschchen aufrecht (nur beim Trinken)
           ".aka.",
           "algga",
           "anggg",
           "agggg",
           ".aaa."]
VIAL_TILT_L = ["aGa...",     # Öffnung nach links oben (zum Mund, Seitenansicht)
               "akna..",
               ".aggaa",
               ".agggga",
               "..aggga",
               "...aaa."]
VIAL_TILT_R = ["...aGa",     # Öffnung nach rechts oben (Vorderansicht, an den Mund)
               "..anka",
               "aagga.",
               "agggga",
               "aggga.",
               ".aaa.."]
VIAL_STEEP = [".aGa",        # fast über Kopf: Öffnung oben, Boden zeigt hoch weg
              "akna",
              "aggga",
              "agga.",
              ".aa.."]

SPREAD_UP = ["#...#",        # Rückansicht: gespreizte Finger zeigen nach oben/vorn
             "#.#.#",
             "a####",
             ".a##."]
SPREAD_SIDE = ["a##.#",      # Seitenansicht: Finger gespreizt nach vorn/unten
               "a####",
               "a##.#",
               ".#..#"]
FIST_SIDE = ["a##a",
             "####",
             "a##."]
GRAB = ["a##a",              # Griff um einen Stängel
        "####",
        ".##."]
PALM_UP = ["#.#.#",          # Hand offen, Finger nach oben (beim Schnippen/Anheben)
           "#####",
           "a###a",
           ".a#a."]
SNAP_CLICK = ["#....",       # Schnipp-Moment: ein Finger springt ab
              ".#.##",
              "a####",
              ".a##a"]
FOREARM_UP = ["aGGa",        # Unterarm senkrecht nach oben, Goldreif oben
              "abba",
              "arba",
              "abba",
              ".abba"]
SLEEVE_DOWN = ["abba",       # Arm hängt gestreckt nach unten (Ernten)
               "arba",
               "abba",
               "abba",
               "abba",
               "abba",
               "aGGa"]

# Seitenansicht: Arm vorne am Körper
S_SLEEVE_OUT = ["aa.....",
                "abbaa..",
                "arbbbaa",
                ".aabbba",
                "....aGa"]
S_SLEEVE_HALF = ["aa...",
                 "abba.",
                 "arbba",
                 ".abba",
                 "..aGa"]
S_SLEEVE_DOWN = ["aaa..",
                 "abba.",
                 "arbba",
                 ".abba",
                 ".abba",
                 "..abba",
                 "..abba",
                 "...aGa"]
S_SLEEVE_TO_MOUTH = ["...aGa",
                     "..abba",
                     ".abbra",
                     "abbba.",
                     "abba..",
                     ".aa..."]


def spark(f, x, y, kind="big"):
    if kind == "big":
        stamp(f, SPARK_BIG, x - 1, y - 1)
    elif kind == "mid":
        stamp(f, SPARK_MID, x, y)
    elif kind == "dot":
        stamp(f, ["M"], x, y)
    else:
        stamp(f, ["d"], x, y)


# ---- Zauber-Ausgießen: oben und Seite -------------------------------------
def pour_up():
    base = idle("up")
    fr = []
    f = base.copy()                                   # F1 Arm halb
    stamp(f, SLEEVE_HALF, 20, 23); stamp(f, FIST_SIDE, 24, 27); spark(f, 27, 26, "dot")
    fr.append(f)
    f = shift_upper(base, 1, 34)                      # F2 ausgestreckt
    stamp(f, SLEEVE_OUT, 20, 21); stamp(f, SPREAD_UP, 24, 22)
    spark(f, 24, 21, "mid"); spark(f, 28, 20, "dot")
    fr.append(f)
    f = shift_upper(base, 1, 34)                      # F3 Stoß, Orb startet
    stamp(f, SLEEVE_OUT, 20, 22); stamp(f, SPREAD_UP, 24, 22)
    spark(f, 25, 20, "big"); spark(f, 29, 21, "big"); spark(f, 27, 18, "dot")
    fr.append(f)
    f = shift_upper(base, 1, 34)                      # F4 verglühen
    stamp(f, SLEEVE_OUT, 20, 22); stamp(f, [".##.", "a###", ".a#a"], 24, 23)
    spark(f, 25, 21, "dim"); spark(f, 29, 20, "dim"); spark(f, 27, 19, "dot")
    fr.append(f)
    f = base.copy()                                   # F5 zurück
    stamp(f, SLEEVE_HALF, 20, 24); stamp(f, FIST_SIDE, 24, 28)
    fr.append(f)
    return fr, [None, None, (26, 20), None, None]


def pour_side():
    base = idle("side")
    fr = []
    f = base.copy()                                   # F1 Arm halb vor
    stamp(f, S_SLEEVE_HALF, 15, 21); stamp(f, FIST_SIDE, 19, 25); spark(f, 23, 26, "dot")
    fr.append(f)
    f = shift(base, 34, 1, 1)                         # F2 vorgebeugt, Finger gespreizt
    stamp(f, S_SLEEVE_OUT, 16, 21); stamp(f, SPREAD_SIDE, 22, 24)
    spark(f, 27, 25, "mid"); spark(f, 26, 28, "dot")
    fr.append(f)
    f = shift(base, 34, 1, 1)                         # F3 Stoß, Orb startet
    stamp(f, S_SLEEVE_OUT, 17, 22); stamp(f, SPREAD_SIDE, 23, 25)
    spark(f, 29, 26, "big"); spark(f, 27, 29, "big"); spark(f, 30, 23, "dot")
    fr.append(f)
    f = shift(base, 34, 1, 1)                         # F4 verglühen
    stamp(f, S_SLEEVE_OUT, 17, 22); stamp(f, FIST_SIDE, 23, 25)
    spark(f, 28, 26, "dim"); spark(f, 27, 29, "dim"); spark(f, 30, 24, "dot")
    fr.append(f)
    f = base.copy()                                   # F5 zurück
    stamp(f, S_SLEEVE_HALF, 15, 22); stamp(f, FIST_SIDE, 19, 26)
    fr.append(f)
    return fr, [None, None, (28, 27), None, None]


# ---- Ernten: bücken, greifen, herausziehen, anheben -----------------------
ARM_REACH = ["aa...",        # Arm schräg nach außen-unten (Vorder-/Rückansicht)
             "abba.",
             "arbba",
             ".abba",
             ".abba",
             "..abba",
             "..abba",
             "..abba",
             "...aGa"]
S_ARM_REACH = ["aa....",     # Seitenansicht: Arm nach vorn-unten
               "abba..",
               "arbba.",
               ".abba.",
               "..abba",
               "..abba",
               "...abba",
               "...abba",
               "....aGa"]
CLAW_DOWN = ["a##a",         # greifende Finger nach unten
             "####",
             "#.##",
             "#..#"]
FIST = ["a##a",
        "####",
        "a##a"]


def _harvest(base, reach, arm_x, arm_y, hand_dx, bends):
    """bends: (dx, dy) für F1-F3; F4 steht wieder aufrecht."""
    fr = []
    hands = [CLAW_DOWN, FIST, FIST]
    for k, (bx, by) in enumerate(bends):
        f = shift(base, 34, bx, by)
        lift = -3 if k == 2 else 0                    # F3: Hand zieht nach oben
        ay = arm_y + by + lift
        stamp(f, reach, arm_x + bx, ay)
        stamp(f, hands[k], arm_x + bx + hand_dx, ay + len(reach))
        fr.append(f)
    return fr


def harvest_down():
    base = idle("down")
    fr = _harvest(base, ARM_REACH, 21, 27, 2, [(0, 2), (0, 4), (0, 2)])
    f = base.copy()                                   # F4 Hand vor dem Körper, offen
    stamp(f, SLEEVE_HALF, 20, 22); stamp(f, PALM_UP, 23, 23)
    fr.append(f)
    return fr, None


def harvest_up():
    base = idle("up")
    fr = _harvest(base, ARM_REACH, 21, 27, 2, [(0, 2), (0, 4), (0, 2)])
    f = base.copy()
    stamp(f, SLEEVE_HALF, 20, 22); stamp(f, PALM_UP, 23, 23)
    fr.append(f)
    return fr, None


def harvest_side():
    base = idle("side")
    fr = _harvest(base, S_ARM_REACH, 17, 26, 3, [(2, 2), (3, 4), (2, 2)])
    f = base.copy()                                   # F4 Hand vor dem Körper
    stamp(f, S_SLEEVE_HALF, 15, 21); stamp(f, PALM_UP, 19, 21)
    fr.append(f)
    return fr, None


# ---- Trinken: Fläschchen zum Mund, Kopf zurück, absetzen -------------------
def drink_down():
    base = idle("down")
    fr = []
    f = base.copy()                                   # F1 Flasche vor der Brust
    stamp(f, ["aaaa.", "abbba", "arbba", ".aaa."], 20, 29)
    stamp(f, [".aGGa"], 20, 28); stamp(f, ["a###a", "a##a."], 20, 26)
    stamp(f, VIAL_UP, 20, 20)
    fr.append(f)
    f = base.copy()                                   # F2 an den Mund
    stamp(f, FOREARM_UP, 19, 17)
    stamp(f, VIAL_TILT_L, 15, 10); stamp(f, ["a###", "a##a"], 19, 14)
    fr.append(f)
    f = shift(base, 15, 0, -1)                        # F3 Kopf leicht zurück
    stamp(f, FOREARM_UP, 19, 15)
    stamp(f, VIAL_STEEP, 15, 7); stamp(f, ["a###", "a##a"], 18, 12)
    fr.append(f)
    f = base.copy()                                   # F4 absetzen
    stamp(f, FOREARM_UP, 20, 20)
    stamp(f, ["a###", "a##a"], 20, 18); stamp(f, VIAL_UP, 20, 12)
    fr.append(f)
    f = base.copy()                                   # F5 Hand sinkt
    stamp(f, ["aaaa.", "abbba", "arbba", ".aaa."], 20, 31)
    stamp(f, [".aGGa"], 20, 30); stamp(f, ["a###a", "a##a."], 20, 28)
    stamp(f, VIAL_UP, 20, 22)
    fr.append(f)
    return fr, None


def drink_up():
    base = idle("up")
    fr = []
    f = base.copy()                                   # F1 Arm hebt sich an der Seite
    stamp(f, SLEEVE_HALF, 20, 22); stamp(f, FIST_SIDE, 23, 26)
    fr.append(f)
    f = base.copy()                                   # F2 Ellbogen hoch, Hand vor dem Gesicht
    stamp(f, ["...aa.", "..abba", ".abrba", "abbba.", "abba..", ".aa..."], 20, 12)
    fr.append(f)
    f = shift(base, 15, 0, 1)                         # F3 Kopf zurück (Hinterkopf sinkt)
    stamp(f, ["...aa.", "..abba", ".abrba", "abbba.", "abba..", ".aa..."], 20, 11)
    stamp(f, ["aGa"], 19, 14)
    fr.append(f)
    f = base.copy()                                   # F4 absetzen
    stamp(f, SLEEVE_HALF, 20, 21); stamp(f, FIST_SIDE, 23, 25)
    fr.append(f)
    f = base.copy()                                   # F5 Hand sinkt
    stamp(f, SLEEVE_HALF, 20, 24); stamp(f, FIST_SIDE, 23, 28)
    fr.append(f)
    return fr, None


def drink_side():
    base = idle("side")
    fr = []
    f = base.copy()                                   # F1 Flasche vor dem Körper
    stamp(f, S_SLEEVE_HALF, 15, 22); stamp(f, FIST_SIDE, 19, 26)
    stamp(f, VIAL_UP, 19, 20)
    fr.append(f)
    f = base.copy()                                   # F2 zum Mund
    stamp(f, S_SLEEVE_TO_MOUTH, 15, 16)
    stamp(f, FIST_SIDE, 19, 13); stamp(f, VIAL_TILT_L, 19, 8)
    fr.append(f)
    f = shift(base, 15, -1, 0)                        # F3 Kopf zurück
    stamp(f, S_SLEEVE_TO_MOUTH, 15, 15)
    stamp(f, FIST_SIDE, 19, 12); stamp(f, VIAL_STEEP, 20, 7)
    fr.append(f)
    f = base.copy()                                   # F4 absetzen
    stamp(f, S_SLEEVE_HALF, 15, 19); stamp(f, FIST_SIDE, 19, 22)
    stamp(f, VIAL_UP, 19, 16)
    fr.append(f)
    f = base.copy()                                   # F5 Hand sinkt
    stamp(f, S_SLEEVE_HALF, 15, 23); stamp(f, FIST_SIDE, 19, 27)
    stamp(f, VIAL_UP, 19, 21)
    fr.append(f)
    return fr, None


# ---- Schnippen: Hand heben, schnippen, Funken verglühen, senken ------------
UPPER_ARM = ["aa...",       # Oberarm: Schulter -> Ellbogen (verbindet den
             "abba.",       # erhobenen Unterarm mit dem Körper)
             "arbba",
             ".abba",
             "..aaa"]


def _snap(base, sleeve_xy, hand_xy, sparks):
    fr = []
    sx, sy = sleeve_xy
    hx, hy = hand_xy
    f = base.copy()                                   # F1 Hand heben
    stamp(f, UPPER_ARM, sx - 4, sy + 3)
    stamp(f, FOREARM_UP, sx, sy + 2); stamp(f, PALM_UP, hx, hy + 2)
    fr.append(f)
    f = base.copy()                                   # F2 Schnipp + Funken
    stamp(f, UPPER_ARM, sx - 4, sy + 1)
    stamp(f, FOREARM_UP, sx, sy); stamp(f, SNAP_CLICK, hx, hy)
    for x, y, k in sparks[0]:
        spark(f, x, y, k)
    fr.append(f)
    f = base.copy()                                   # F3 Funken verglühen
    stamp(f, UPPER_ARM, sx - 4, sy + 1)
    stamp(f, FOREARM_UP, sx, sy); stamp(f, PALM_UP, hx, hy)
    for x, y, k in sparks[1]:
        spark(f, x, y, k)
    fr.append(f)
    f = base.copy()                                   # F4 Hand senken
    stamp(f, SLEEVE_HALF, sx - 2, sy + 6); stamp(f, FIST_SIDE, sx + 2, sy + 10)
    fr.append(f)
    return fr, None


def snap_down():
    return _snap(idle("down"), (25, 17), (24, 13),
                 [[(25, 11, "big"), (29, 12, "big"), (27, 9, "dot")],
                  [(25, 9, "dim"), (29, 10, "dot"), (27, 7, "dim")]])


def snap_up():
    return _snap(idle("up"), (25, 17), (24, 13),
                 [[(25, 11, "big"), (29, 12, "big"), (27, 9, "dot")],
                  [(25, 9, "dim"), (29, 10, "dot"), (27, 7, "dim")]])


def snap_side():
    return _snap(idle("side"), (21, 18), (20, 14),
                 [[(22, 12, "big"), (26, 13, "big"), (24, 10, "dot")],
                  [(22, 10, "dim"), (27, 11, "dot"), (25, 8, "dim")]])


BUILDERS = {
    "pour_down": pour_down, "pour_up": pour_up, "pour_side": pour_side,
    "harvest_down": harvest_down, "harvest_up": harvest_up, "harvest_side": harvest_side,
    "drink_down": drink_down, "drink_up": drink_up, "drink_side": drink_side,
    "snap_down": snap_down, "snap_up": snap_up, "snap_side": snap_side,
}


# --------------------------------------------------------------------------
def sheet(frames):
    out = Image.new("RGBA", (FW * len(frames), FH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * FW, 0))
    return out


def check(name, frames):
    """Füße/Saum (Zeilen 56-63) pixelgleich mit dem Idle-Frame derselben Richtung,
    nichts außerhalb 32x64, keine halbtransparenten Pixel.
    Hinweis: Idle steht bei der Rückansicht auf y = 62 (Kleid deckt die Füße) und
    bei der Seite bei x = 17-22. Gleich wie Idle heißt: gleich wie Walk."""
    ok = True
    ref = idle(name.split("_")[1])
    for i, f in enumerate(frames):
        if f.size != (FW, FH):
            print(f"  ! {name} F{i+1}: falsche Größe {f.size}")
            ok = False
        for y in range(56, FH):
            for x in range(FW):
                if f.getpixel((x, y)) != ref.getpixel((x, y)):
                    print(f"  ! {name} F{i+1}: Fußbereich weicht bei ({x},{y}) von Idle ab")
                    ok = False
                    break
        alphas = {f.getpixel((x, y))[3] for x in range(FW) for y in range(FH)}
        if not alphas <= {0, 255}:
            print(f"  ! {name} F{i+1}: halbtransparente Pixel")
            ok = False
    print(f"  {name}: {'ok' if ok else 'FEHLER'} ({len(frames)} Frames)")
    return ok


BG = (52, 64, 52, 255)   # dunkles Gartengrün als Vorschau-Hintergrund


def preview(action, results, fps):
    """GIF 4x mit allen vorhandenen Richtungen nebeneinander + Größenvergleich."""
    PREVIEW.mkdir(parents=True, exist_ok=True)
    dirs = [d for d in ("down", "up", "side") if f"{action}_{d}" in results]
    n = max(len(results[f"{action}_{d}"][0]) for d in dirs)
    gif = []
    for i in range(n):
        canvas = Image.new("RGBA", (len(dirs) * (FW + 8) + 8, FH + 8), BG)
        for j, d in enumerate(dirs):
            fr = results[f"{action}_{d}"][0]
            canvas.alpha_composite(fr[min(i, len(fr) - 1)], (8 + j * (FW + 8), 4))
        gif.append(canvas.resize((canvas.width * 4, canvas.height * 4), Image.NEAREST).convert("RGB"))
    gif[0].save(PREVIEW / f"vorschau_{action}_4x.gif", save_all=True, append_images=gif[1:],
                duration=int(1000 / fps), loop=0, disposal=2)

    # Standbild: Idle | alle Frames, je Richtung eine Zeile
    canvas = Image.new("RGBA", ((n + 1) * (FW + 4) + 4, len(dirs) * (FH + 4) + 4), BG)
    for j, d in enumerate(dirs):
        canvas.alpha_composite(idle(d), (4, 4 + j * (FH + 4)))
        for i, fr in enumerate(results[f"{action}_{d}"][0]):
            canvas.alpha_composite(fr, (4 + (i + 1) * (FW + 4), 4 + j * (FH + 4)))
    canvas.resize((canvas.width * 4, canvas.height * 4), Image.NEAREST).save(
        PREVIEW / f"vergleich_{action}_4x.png")


FPS = {"pour": 8, "harvest": 8, "drink": 7, "snap": 10}


def main(names):
    results = {}
    for name in names:
        frames, mouth = BUILDERS[name]()
        check(name, frames)
        sheet(frames).save(CHAR / f"witch_{name}.png")
        results[name] = (frames, mouth)
        if mouth and any(mouth):
            print(f"  {name} Orb-Start je Frame: {mouth}")
    for action in sorted({n.split('_')[0] for n in names}):
        preview(action, results, FPS[action])


if __name__ == "__main__":
    main(sys.argv[1:] or list(BUILDERS))
