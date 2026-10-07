"""Brau-Fenster am Kessel: Teile für Godot plus Mockup-Vorschau.
Anders als die Hotbar wird hier in 1x gespeichert; Godot zeigt das Fenster
doppelt so groß an (z. B. scale = 2 am Fenster-Root). So ist die spätere
einstellbare UI-Größe schon vorbereitet.
Aufruf: python brew_window.py <ausgabeordner> [vorschauordner]

Aktueller Stand = Version 2 (unten): mitwachsende Felder im Bogen über dem Kessel,
Kessel aufrüstbar (Kapazität), Kapazitäts-Rauten, "?" für unbekannte Rezepte.
Version 1 (feste 3 Felder, Funktion mockup) bleibt nur als Referenz im Code.

Teile:
- brew_panel.png            Fensterrahmen, 9-Slice (Ränder je 6 px)
- brew_slot.png             Zutaten-Feld 20x20 (Icon 16x16 mittig)
- brew_slot_result.png      Ergebnis-Feld 24x24 (Icon 16x16 mittig)
- brew_arrow.png            Pfeil zwischen Zutaten und Ergebnis
- brew_arrow_active.png     Pfeil, wenn gebraut werden kann
- brew_button.png           Knopf, 9-Slice (Ränder je 4 px)
- brew_button_pressed.png   Knopf gedrückt
- brew_button_disabled.png  Knopf inaktiv (weniger als 2 Zutaten)
- brew_unknown.png          "?"-Icon 16x16 für unbekannte Rezepte
- brew_pip.png / brew_pip_empty.png   Kapazitäts-Raute 5x5, belegt / frei
- brew_cauldron.png / brew_cauldron_ready.png   Kessel im Fenster 56x36,
                            grüner Sud / magenta glühend (brau-bereit)
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

PAL = {
    "k": (14, 10, 20), "a": (43, 22, 51), "d": (77, 18, 48), "b": (110, 24, 48),
    "B": (150, 44, 72),                     # neu: Bordeaux hell
    "g": (217, 164, 65), "G": (244, 204, 120),  # neu: Gold hell
    "h": (138, 82, 64),                     # Gold im Schatten (wie Hotbar)
    "c": (255, 181, 102), "w": (234, 223, 203),
    "m": (194, 48, 122), "M": (228, 88, 177),
    "v": (92, 30, 78),                      # neu: gedämpftes Magenta für Runen
}
ALPHA = {"K": ((14, 10, 20), 230)}           # Fenstergrund, fast deckend


def to_image(g):
    h, w = len(g), len(g[0])
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            ch = g[y][x]
            if ch in PAL:
                im.putpixel((x, y), PAL[ch] + (255,))
            elif ch in ALPHA:
                col, a = ALPHA[ch]
                im.putpixel((x, y), col + (a,))
    return im


def blank(w, h, ch="."):
    return [[ch] * w for _ in range(h)]


# ---------------------------------------------------------------- Fensterrahmen
def panel():
    """15x15, Ränder 6 px. Von außen: Kontur, Goldlinie (Licht oben links),
    Kontur, Bordeaux-Innenkante, dann Fenstergrund. In jeder Ecke ein
    Magenta-Stein."""
    S = 15
    g = blank(S, S, "K")
    for y in range(S):
        for x in range(S):
            e = min(x, y, S - 1 - x, S - 1 - y)
            lit = (x <= y) if (x < S // 2 and y < S // 2) else (x < S - 1 - y and y < S // 2) or (x < S // 2 and y < S - 1 - x)
            if e == 0:
                g[y][x] = "a"
            elif e == 1:
                g[y][x] = "g" if (x == 1 or y == 1) and x < S - 2 and y < S - 2 else "h"
            elif e == 2:
                g[y][x] = "a"
            elif e == 3:
                g[y][x] = "d"
    # runde Außenecken
    for x, y in ((0, 0), (S - 1, 0), (0, S - 1), (S - 1, S - 1)):
        g[y][x] = "."
    # Eck-Steine (3x3 Raute) über der Goldlinie
    for cx, cy in ((2, 2), (S - 3, 2), (2, S - 3), (S - 3, S - 3)):
        for dx, dy, ch in ((0, -1, "a"), (-1, 0, "a"), (1, 0, "a"), (0, 1, "a"),
                           (0, 0, "m"), (-1, -1, "a"), (1, 1, "a"), (1, -1, "a"), (-1, 1, "a")):
            g[cy + dy][cx + dx] = ch
        g[cy][cx] = "M" if (cx, cy) == (2, 2) else "m"
        g[cy - 1][cx] = "m"; g[cy][cx - 1] = "m"
        g[cy + 1][cx] = "b"; g[cy][cx + 1] = "b"
    g[1][1] = "G"
    return g


# ---------------------------------------------------------------- Felder
def slot(size, border_tl, border_br, fill, inner_tl, inner_br, corner=None, rune=None):
    """Wie die Hotbar-Slots: Rand, 1 px Fase (Licht oben links), Mulde."""
    S = size
    g = blank(S, S)
    for y in range(S):
        for x in range(S):
            if x in (0, S - 1) or y in (0, S - 1):
                g[y][x] = border_tl if (x == 0 or y == 0) else border_br
            elif x in (1, S - 2) or y in (1, S - 2):
                g[y][x] = inner_tl if (x == 1 or y == 1) else inner_br
            else:
                g[y][x] = fill
    for x, y in ((0, 0), (S - 1, 0), (0, S - 1), (S - 1, S - 1)):
        g[y][x] = "."
    if corner:
        for x, y in ((1, 1), (S - 2, 1), (1, S - 2), (S - 2, S - 2)):
            g[y][x] = corner
        g[0][1] = g[1][0] = "c"
    if rune:
        # schwacher Runenkreis im leeren Feld: zeigt "hier kommt etwas hinein"
        c = (S - 1) / 2
        for y in range(S):
            for x in range(S):
                r = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
                if 4.6 <= r <= 5.4 and (x + y) % 2 == 0:
                    g[y][x] = rune
        for x, y in ((int(c), int(c) - 2), (int(c) + 1, int(c) + 3), (int(c) - 2, int(c) + 1)):
            g[y][x] = rune
    return g


def result_slot():
    """24x24 mit Goldrahmen und Magenta-Glimmen in den Innenecken."""
    g = slot(24, "g", "h", "a", "k", "d", corner="g")
    for x, y in ((2, 2), (21, 2), (2, 21), (21, 21)):
        g[y][x] = "v"
    for x, y in ((3, 2), (2, 3), (20, 2), (21, 3), (2, 20), (3, 21), (21, 20), (20, 21)):
        g[y][x] = "v"
    return g


# ---------------------------------------------------------------- Pfeil
ARROW = [
    "......aa......",
    "......aga.....",
    "aaaaaaagga....",
    "aGggggggggga..",
    "agggggggggggga",
    "ahhhhhhhhhhha.",
    "aaaaaaahha....",
    "......aha.....",
    "......aa......",
]


def arrow(active):
    g = [list(r) for r in ARROW]
    if active:
        swap = {"G": "w", "g": "M", "h": "m"}
        g = [[swap.get(ch, ch) for ch in r] for r in g]
    # ein paar Funken hinter dem Pfeil, aktiv heller
    g = [r + ["."] * 0 for r in g]
    out = blank(18, 9)
    for y in range(9):
        for x in range(14):
            out[y][x + 4] = g[y][x]
    spark = "M" if active else "v"
    for x, y in ((1, 4), (2, 2), (0, 6), (3, 5)):
        out[y][x] = spark if active or (x + y) % 2 == 0 else "."
    if active:
        out[2][2] = "w"
    return out


# ---------------------------------------------------------------- Knopf
def button(pressed):
    """16x12, Ränder 4 px. Bordeaux mit Goldrand; gedrückt dunkler und das
    Licht wandert nach unten."""
    W, H = 16, 12
    g = blank(W, H)
    for y in range(H):
        for x in range(W):
            e = min(x, y, W - 1 - x, H - 1 - y)
            if e == 0:
                g[y][x] = "a"
            elif e == 1:
                g[y][x] = ("g" if (x == 1 or y == 1) else "h") if not pressed else ("h" if (x == 1 or y == 1) else "g")
            else:
                g[y][x] = "d" if pressed else "b"
    for x, y in ((0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)):
        g[y][x] = "."
    if not pressed:
        for x in range(2, W - 2):
            g[2][x] = "B"                  # Glanzkante oben
        for x in range(2, W - 2):
            g[H - 3][x] = "d"              # Schatten unten
        g[1][1] = "G"
    else:
        for x in range(2, W - 2):
            g[2][x] = "a"                  # eingedrückt: Schatten oben
    return g


# ---------------------------------------------------------------- Mockup
def nine_slice(src, w, h, m):
    """Einfaches 9-Slice wie in Godot (Mitte und Ränder gekachelt-gestreckt)."""
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sw, sh = src.size
    def part(x0, y0, x1, y1, tw, th):
        return src.crop((x0, y0, x1, y1)).resize((max(tw, 1), max(th, 1)), Image.NEAREST)
    cw, ch = w - 2 * m, h - 2 * m
    out.alpha_composite(part(0, 0, m, m, m, m), (0, 0))
    out.alpha_composite(part(sw - m, 0, sw, m, m, m), (w - m, 0))
    out.alpha_composite(part(0, sh - m, m, sh, m, m), (0, h - m))
    out.alpha_composite(part(sw - m, sh - m, sw, sh, m, m), (w - m, h - m))
    out.alpha_composite(part(m, 0, sw - m, m, cw, m), (m, 0))
    out.alpha_composite(part(m, sh - m, sw - m, sh, cw, m), (m, h - m))
    out.alpha_composite(part(0, m, m, sh - m, m, ch), (0, m))
    out.alpha_composite(part(sw - m, m, sw, sh - m, m, ch), (w - m, m))
    out.alpha_composite(part(m, m, sw - m, sh - m, cw, ch), (m, m))
    return out


def mockup(parts, root, preview_dir):
    items = os.path.join(root, "assets", "items")
    ui = os.path.join(root, "assets", "ui")
    icon = lambda n: Image.open(os.path.join(items, n + ".png")).convert("RGBA")
    # Hotbar-Slots liegen in 2x vor: für das 1x-Mockup halbieren
    hb = Image.open(os.path.join(ui, "hotbar_slot.png")).convert("RGBA")
    hb = hb.resize((hb.width // 2, hb.height // 2), Image.NEAREST)
    font_path = os.path.join(ui, "fonts", "m5x7.ttf")
    font = ImageFont.truetype(font_path, 16)

    W, H = 190, 138
    win = nine_slice(parts["brew_panel"], W, H, 6)
    d = ImageDraw.Draw(win)
    d.fontmode = "1"
    d.text((10, 4), "Kessel", font=font, fill=PAL["w"])

    # Brau-Zeile
    y0 = 20
    xs = [14, 36, 58]
    filled = ["crop_mandrake", "crop_ghost_fern", "crop_moon_chalice"]
    for x, n in zip(xs, filled):
        win.alpha_composite(parts["brew_slot"], (x, y0 + 2))
        win.alpha_composite(icon(n), (x + 2, y0 + 4))
    win.alpha_composite(parts["brew_arrow_active"], (84, y0 + 7))
    win.alpha_composite(parts["brew_slot_result"], (108, y0))
    win.alpha_composite(icon("potion_moon_harvest"), (112, y0 + 4))
    btn = nine_slice(parts["brew_button"], 46, 16, 4)
    win.alpha_composite(btn, (136, y0 + 4))
    d.text((143, y0 + 4), "Brauen", font=font, fill=PAL["w"])
    d.text((14, y0 + 26), "Mondernte", font=font, fill=PAL["g"])

    # Trennlinie
    for x in range(10, W - 10):
        win.putpixel((x, 60), PAL["d"] + (255,))
        if x % 4 == 0:
            win.putpixel((x, 60), PAL["h"] + (255,))

    # Inventar 8x3
    inv = ["crop_mandrake", "crop_ghost_fern", "crop_lantern_berry", "seed_mandrake",
           "potion_growth", "potion_sludge", None, None,
           "crop_nightshade", "crop_moon_chalice", "seed_ghost_fern", "potion_will_o_wisp",
           None, None, None, None,
           "potion_endless_night", "potion_liquid_moonlight", None, None, None, None, None, None]
    for i, n in enumerate(inv):
        cx, cy = 13 + (i % 8) * 20, 66 + (i // 8) * 21
        win.alpha_composite(hb, (cx, cy))
        if n and os.path.exists(os.path.join(items, n + ".png")):
            win.alpha_composite(icon(n), (cx + 2, cy + 2))

    # auf das Spielbild legen, falls vorhanden, sonst dunkler Grund
    bgp = os.path.join(root, "docs", "art", "vorschau", "vorschau_viewport_640x360_3x.png")
    if os.path.exists(bgp):
        bg = Image.open(bgp).convert("RGBA").resize((640, 360), Image.NEAREST)
    else:
        bg = Image.new("RGBA", (640, 360), (20, 27, 58, 255))
    shade = Image.new("RGBA", bg.size, (14, 10, 20, 140))
    bg.alpha_composite(shade)
    big = win.resize((W * 2, H * 2), Image.NEAREST)
    bg.alpha_composite(big, ((640 - W * 2) // 2, (360 - H * 2) // 2))
    bg.resize((1280, 720), Image.NEAREST).save(os.path.join(preview_dir, "vorschau_braufenster_2x.png"))
    # Einzelteile nebeneinander, 6x
    sheet = Image.new("RGBA", (150, 30), (14, 10, 20, 255))
    x = 2
    for n in ("brew_panel", "brew_slot", "brew_slot_result", "brew_arrow", "brew_arrow_active",
              "brew_button", "brew_button_pressed"):
        sheet.alpha_composite(parts[n], (x, 3))
        x += parts[n].width + 2
    sheet.resize((sheet.width * 6, sheet.height * 6), Image.NEAREST).save(
        os.path.join(preview_dir, "vorschau_braufenster_teile_6x.png"))


def main(out_dir, preview_dir=None):
    parts = {
        "brew_panel": to_image(panel()),
        "brew_slot": to_image(slot(20, "a", "a", "K", "k", "d", rune="v")),
        "brew_slot_result": to_image(result_slot()),
        "brew_arrow": to_image(arrow(False)),
        "brew_arrow_active": to_image(arrow(True)),
        "brew_button": to_image(button(False)),
        "brew_button_pressed": to_image(button(True)),
    }
    for n, im in parts.items():
        im.save(os.path.join(out_dir, n + ".png"))
    if preview_dir:
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
        mockup(parts, root, preview_dir)




# ================================================================ Version 2
# Mitwachsende Felder im Bogen über dem Kessel (Kessel aufrüstbar).
# Neue Teile: "?"-Icon für unbekannte Rezepte, Knopf deaktiviert, Kapazitäts-Punkte.

UNKNOWN = [
    "................",
    "................",
    ".....aaaaaa.....",
    "....aMMmmmma....",
    "...aMma..amma...",
    "...aaa...amma...",
    ".........amma...",
    "........amma....",
    ".......amma.....",
    "......amma......",
    "......amma......",
    "......aaaa......",
    "......aMma......",
    "......amma......",
    "......aaaa......",
    "................",
]


def button_disabled():
    g = button(True)
    swap = {"g": "a", "h": "a", "d": "k", "a": "a"}
    return [[swap.get(ch, ch) for ch in r] for r in g]


PIP = ["..a..", ".aGa.", "aggha", ".aha.", "..a.."]
PIP_EMPTY = ["..a..", ".a.a.", "a...a", ".a.a.", "..a.."]


def ui_cauldron(ready):
    """Großer Kessel fürs Fenster, 56x36. ready=True: Sud glüht magenta."""
    W, H = 56, 36
    col = {
        "o": (14, 10, 20), "b0": (24, 18, 36), "b1": (38, 30, 58), "b2": (56, 50, 96),
        "b3": (82, 78, 140), "r0": (30, 22, 44), "r1": (66, 58, 92), "r2": (104, 96, 140),
    }
    sud = {"q": PAL["d"], "G": PAL["m"], "Q": PAL["M"], "w": (255, 210, 236)} if ready else \
          {"q": (36, 74, 58), "G": (63, 125, 90), "Q": (98, 160, 110), "w": PAL["w"]}
    col.update(sud)
    g = [[None] * W for _ in range(H)]
    cx = 27.5
    for y in range(H):
        for x in range(W):
            bx, by = (x - cx) / 24.5, (y - 20) / 13.0
            if bx * bx + by * by <= 1 and y >= 9:
                if x < cx - 12 and y < 24:
                    c = "b2" if x > cx - 21 else "b3"
                elif x > cx + 14 or y > 29:
                    c = "b0"
                else:
                    c = "b1"
                g[y][x] = c
    # Beine
    for lx in (10, 27, 44):
        for y in range(31, 35):
            g[y][lx] = "b0"; g[y][lx + 1] = "b0"
    # Rand und Sud
    for y in range(H):
        for x in range(W):
            rx, ry = (x - cx) / 26.5, (y - 9) / 6.0
            if rx * rx + ry * ry <= 1:
                g[y][x] = "r2" if (x < cx - 8 and y <= 8) else ("r0" if x > cx + 10 or y > 11 else "r1")
            sx, sy = (x - cx) / 22.0, (y - 9) / 3.6
            if sx * sx + sy * sy <= 1:
                g[y][x] = "q" if x > cx + 12 else ("Q" if (x < cx - 6 and y <= 8) else "G")
    for x, y in [(12, 8), (20, 10), (31, 7), (38, 9), (25, 8)]:
        g[y][x] = "w"                       # Blasen
    for x, y in [(13, 8), (32, 7)]:
        g[y][x] = "Q"
    # Kontur
    add = []
    for y in range(H):
        for x in range(W):
            if g[y][x] is None and any(0 <= x + dx < W and 0 <= y + dy < H and g[y + dy][x + dx]
                                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                add.append((x, y))
    for x, y in add:
        g[y][x] = "o"
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y in range(H):
        for x in range(W):
            if g[y][x]:
                im.putpixel((x, y), col[g[y][x]] + (255,))
    return im


def slot_positions(k, cx, base_y, spacing=22):
    """k sichtbare Felder im flachen Bogen, mittig um cx. Außen etwas tiefer."""
    out = []
    for i in range(k):
        off = (i - (k - 1) / 2) / 1.0
        dx = off * spacing
        dy = round(off * off * 3)
        out.append((round(cx + dx) - 10, base_y + dy))
    return out


def window_v2(parts, root, ingredients, capacity, result, title_name):
    items = os.path.join(root, "assets", "items")
    ui = os.path.join(root, "assets", "ui")
    icon = lambda n: Image.open(os.path.join(items, n + ".png")).convert("RGBA")
    hb = Image.open(os.path.join(ui, "hotbar_slot.png")).convert("RGBA")
    hb = hb.resize((hb.width // 2, hb.height // 2), Image.NEAREST)
    font = ImageFont.truetype(os.path.join(ui, "fonts", "m5x7.ttf"), 16)

    W, H = 190, 168
    win = nine_slice(parts["brew_panel"], W, H, 6)
    d = ImageDraw.Draw(win)
    d.fontmode = "1"
    d.text((10, 4), "Kessel", font=font, fill=PAL["w"])

    cx = 62
    ready = len(ingredients) >= 2
    # Kessel zuerst, die Felder schweben im Bogen darüber
    caul = parts["brew_cauldron_ready" if ready else "brew_cauldron"]
    win.alpha_composite(caul, (cx - 28, 42))
    visible = min(len(ingredients) + 1, capacity)
    for i, (x, y) in enumerate(slot_positions(visible, cx, 16)):
        win.alpha_composite(parts["brew_slot"], (x, y))
        if i < len(ingredients):
            win.alpha_composite(icon(ingredients[i]), (x + 2, y + 2))
    # Kapazität als Punkte unter dem Kessel
    px0 = cx - (capacity * 7 - 2) // 2
    for i in range(capacity):
        pip = parts["brew_pip"] if i < len(ingredients) else parts["brew_pip_empty"]
        win.alpha_composite(pip, (px0 + i * 7, 76))
    if title_name:
        tw = d.textlength(title_name, font=font)
        d.text((cx - tw // 2, 79), title_name, font=font, fill=PAL["g"])

    win.alpha_composite(parts["brew_arrow_active" if ready else "brew_arrow"], (120, 28))
    win.alpha_composite(parts["brew_slot_result"], (144, 20))
    if result:
        ic = parts["brew_unknown"] if result == "?" else icon(result)
        win.alpha_composite(ic, (148, 24))
    btn_src = parts["brew_button"] if ready else parts["brew_button_disabled"]
    win.alpha_composite(nine_slice(btn_src, 46, 16, 4), (133, 50))
    d.text((140, 50), "Brauen", font=font, fill=PAL["w"] if ready else PAL["h"])

    for x in range(10, W - 10):
        win.putpixel((x, 94), (PAL["h"] if x % 4 == 0 else PAL["d"]) + (255,))
    inv = ["crop_mandrake", "crop_ghost_fern", "crop_lantern_berry", "crop_nightshade",
           "crop_moon_chalice", "crop_blood_rose", "potion_growth", "potion_sludge"]
    for i in range(24):
        x, y = 13 + (i % 8) * 20, 99 + (i // 8) * 21
        win.alpha_composite(hb, (x, y))
        if i < len(inv):
            win.alpha_composite(icon(inv[i]), (x + 2, y + 2))
    return win


def mockup_v2(parts, root, preview_dir):
    states = [
        (["crop_mandrake"], 3, None, ""),
        (["crop_mandrake", "crop_ghost_fern"], 3, "potion_growth", "Wachstumstrank"),
        (["crop_mandrake", "crop_nightshade", "crop_lantern_berry"], 3, "?", "???"),
        (["crop_blood_rose", "crop_nightshade", "crop_mandrake", "crop_moon_chalice"], 5, "?", "???"),
    ]
    wins = [window_v2(parts, root, a, c, r, t) for a, c, r, t in states]
    gap = 8
    w, h = wins[0].size
    sheet = Image.new("RGBA", (2 * w + 3 * gap, 2 * h + 3 * gap), (20, 27, 58, 255))
    for i, im in enumerate(wins):
        sheet.alpha_composite(im, (gap + (i % 2) * (w + gap), gap + (i // 2) * (h + gap)))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(
        os.path.join(preview_dir, "vorschau_braufenster_v2_2x.png"))


def main_v2(out_dir, preview_dir=None):
    parts = {
        "brew_panel": to_image(panel()),
        "brew_slot": to_image(slot(20, "a", "a", "K", "k", "d", rune="v")),
        "brew_slot_result": to_image(result_slot()),
        "brew_arrow": to_image(arrow(False)),
        "brew_arrow_active": to_image(arrow(True)),
        "brew_button": to_image(button(False)),
        "brew_button_pressed": to_image(button(True)),
        "brew_button_disabled": to_image(button_disabled()),
        "brew_unknown": to_image([list(r) for r in UNKNOWN]),
        "brew_pip": to_image([list(r) for r in PIP]),
        "brew_pip_empty": to_image([list(r) for r in PIP_EMPTY]),
        "brew_cauldron": ui_cauldron(False),
        "brew_cauldron_ready": ui_cauldron(True),
    }
    for n, im in parts.items():
        im.save(os.path.join(out_dir, n + ".png"))
    if preview_dir:
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
        mockup_v2(parts, root, preview_dir)


if __name__ == "__main__":
    out = sys.argv[1]
    prev = sys.argv[2] if len(sys.argv) > 2 else None
    main_v2(out, prev)
    if prev:
        # Teile-Übersicht (6x) zusätzlich ausgeben
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")
        parts = {n: Image.open(os.path.join(out, n + ".png")).convert("RGBA") for n in (
            "brew_panel", "brew_slot", "brew_slot_result", "brew_arrow", "brew_arrow_active",
            "brew_button", "brew_button_pressed", "brew_button_disabled", "brew_unknown",
            "brew_pip", "brew_pip_empty")}
        sheet = Image.new("RGBA", (200, 30), (14, 10, 20, 255))
        x = 2
        for im in parts.values():
            sheet.alpha_composite(im, (x, 3)); x += im.width + 2
        sheet.resize((sheet.width * 6, sheet.height * 6), Image.NEAREST).save(
            os.path.join(prev, "vorschau_braufenster_teile_6x.png"))
