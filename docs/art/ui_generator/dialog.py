"""Dialog-UI für spätere NPC-Gespräche – gleicher Stil wie das Brau-Fenster.
In 1x gespeichert, Godot zeigt doppelt so groß an (scale = 2 am UI-Root).

Aufruf (aus dem Projektordner):
    python docs/art/ui_generator/dialog.py

Teile (assets/ui/):
- dialog_panel.png          Dialogfenster, 9-Slice, Ränder je 8 px, Grund leicht transparent
- dialog_ornament.png       Mond-Ornament 20x9, mittig auf die Oberkante des Fensters
- dialog_nameplate.png      Namensschild, 9-Slice, Ränder je 5 px
- dialog_portrait_frame.png Portraitrahmen, 9-Slice, Ränder je 6 px, Mitte frei –
                            passt zu JEDER Portraitgröße (Größe ist noch offen)
- dialog_portrait_bg.png    Hintergrund hinter dem Portrait, 8x8 (kacheln)
- dialog_next.png           "weiter"-Pfeil, 4 Frames à 8x8 (wippt, 6 FPS)
- dialog_cursor.png         Auswahl-Cursor, 2 Frames à 8x8 (funkelt, 3 FPS)
- dialog_choice_bg.png      markierte Antwort, 9-Slice, Ränder je 4 px
Vorschau: docs/art/vorschau/vorschau_dialog_2x.png
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
from brew_window import PAL, ALPHA, to_image, blank, nine_slice   # gleiche Farben wie das Brau-Fenster

PAL = dict(PAL)
PAL.update({"n": (26, 20, 46), "i": (46, 42, 107), "I": (74, 69, 150)})
ALPHA = dict(ALPHA)
ALPHA.update({"V": ((92, 30, 78), 210)})      # Auswahl-Hintergrund, leicht transparent

import brew_window
brew_window.PAL.update(PAL)
brew_window.ALPHA.update(ALPHA)
UI = os.path.join(ROOT, "assets", "ui")


def put(g, x, y, ch):
    if 0 <= y < len(g) and 0 <= x < len(g[0]):
        g[y][x] = ch


def frame_border(g, w, h, inner="d"):
    """Aubergine außen, Gold, dunkles Bordeaux innen."""
    for x in range(w):
        for y in range(h):
            e = min(x, y, w - 1 - x, h - 1 - y)
            if e == 0:
                g[y][x] = "a"
            elif e == 1:
                g[y][x] = "g" if (x < w - 2 and y < h - 2) else "h"   # Gold, unten/rechts im Schatten
            elif e == 2:
                g[y][x] = inner


def gem(g, x, y):
    """kleiner Magenta-Stein (3x3) mit Goldfassung."""
    for dx, dy, ch in ((1, 0, "g"), (0, 1, "g"), (2, 1, "h"), (1, 2, "h"),
                       (1, 1, "M"), (0, 0, "a"), (2, 2, "a")):
        put(g, x + dx, y + dy, ch)
    put(g, x + 1, y + 1, "M")


def dialog_panel():
    w = h = 32
    g = blank(w, h, "K")
    frame_border(g, w, h)
    for cx, cy in ((1, 1), (w - 6, 1), (1, h - 6), (w - 6, h - 6)):    # Eckzier
        gem(g, cx + 1, cy + 1)
        put(g, cx + 4, cy + 2, "g"); put(g, cx + 2, cy + 4, "g")
    # Keine Zier auf den Kanten: Die Kanten werden beim 9-Slice gestreckt,
    # Muster würden dabei zu Balken. Zier nur in den Ecken und als Ornament.
    return to_image(g)


def ornament():
    """Mondsichel mit zwei Sternen, sitzt mittig auf der Oberkante."""
    rows = [
        "........aaaa........",
        "......aaGgga........",
        ".a...agGa..a....a...",
        "aMa.agga........aMa.",
        ".a..aggaa.......a...",
        "....ahgga..a........",
        ".....ahhgaaa........",
        "......aahha.........",
        "........aa..........",
    ]
    return to_image([list(r) for r in rows])


def nameplate():
    w, h = 16, 14
    g = blank(w, h, "b")
    frame_border(g, w, h, inner="d")
    for x in range(3, w - 3):
        put(g, x, 3, "B")                                   # Lichtkante oben
    return to_image(g)


def portrait_frame():
    w = h = 24
    g = blank(w, h, ".")
    for x in range(w):
        for y in range(h):
            e = min(x, y, w - 1 - x, h - 1 - y)
            if e == 0:
                g[y][x] = "a"
            elif e == 1:
                g[y][x] = "g" if (x < w - 2 and y < h - 2) else "h"
            elif e == 2:
                g[y][x] = "a"
            elif e == 3:
                g[y][x] = "d"
    for cx, cy in ((0, 0), (w - 4, 0), (0, h - 4), (w - 4, h - 4)):
        gem(g, cx + 1 if cx == 0 else cx, cy + 1 if cy == 0 else cy)
    return to_image(g)


def portrait_bg():
    g = blank(8, 8, "n")
    put(g, 2, 1, "i"); put(g, 6, 5, "i"); put(g, 5, 2, "a")
    return to_image(g)


def next_arrow():
    rows = ["aaaaaaa", "agGggha", ".aggha.", "..aha..", "...a..."]
    frames = Image.new("RGBA", (32, 8), (0, 0, 0, 0))
    for i, dy in enumerate((0, 1, 2, 1)):
        g = blank(8, 8, ".")
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                if ch != ".":
                    put(g, x, y + dy, ch)
        frames.alpha_composite(to_image(g), (i * 8, 0))
    return frames


def cursor():
    a = ["..a.....", "..aMa...", "..amMa..", "..ammMa.", "..amma..", "..ama...", "..aa....", "........"]
    b = ["..a.....", "..aMa...", "..aMMa..", "..amMMa.", "..amma..", "..ama...", "..aa..M.", ".....M.."]
    out = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    for i, rows in enumerate((a, b)):
        out.alpha_composite(to_image([list(r) for r in rows]), (i * 8, 0))
    return out


def choice_bg():
    w, h = 12, 12
    g = blank(w, h, "V")
    for y in range(h):
        put(g, 0, y, "m"); put(g, 1, y, "v")
    return to_image(g)


def mockup(parts):
    """640x360: Garten bei Nacht, darüber das Dialogfenster (UI in 1x, dann 2x)."""
    sys.path.insert(0, os.path.join(ROOT, "docs", "art", "nature_generator"))
    import preview as P
    import compare as C
    G = P.ROOT / "assets/environment/ground"
    gB, oB, fB = C.garden_B(G)
    bg = P.render(gB, oB, 0, True, fB)
    ui = Image.new("RGBA", (320, 180), (0, 0, 0, 0))
    font = ImageFont.truetype(os.path.join(UI, "fonts", "m5x7.ttf"), 16)
    ui.alpha_composite(nine_slice(parts["dialog_panel"], 304, 70, 8), (8, 104))
    ui.alpha_composite(parts["dialog_ornament"], (150, 100))
    # Portrait: Rahmen 9-Slice um ein 48x48-Platzhalterbild
    pb = Image.new("RGBA", (48, 48))
    for y in range(0, 48, 8):
        for x in range(0, 48, 8):
            pb.alpha_composite(parts["dialog_portrait_bg"], (x, y))
    d = ImageDraw.Draw(pb)
    d.ellipse((14, 8, 34, 30), fill=PAL["a"])
    d.ellipse((6, 28, 42, 60), fill=PAL["a"])
    d.fontmode = "1"
    d.text((20, 12), "?", font=font, fill=PAL["g"])
    ui.alpha_composite(pb, (20, 116))
    ui.alpha_composite(nine_slice(parts["dialog_portrait_frame"], 56, 56, 6), (16, 112))
    ui.alpha_composite(nine_slice(parts["dialog_nameplate"], 58, 14, 5), (80, 98))
    d = ImageDraw.Draw(ui)
    d.fontmode = "1"
    d.text((86, 99), "Nachbarin", font=font, fill=PAL["w"])
    d.text((82, 114), "Du bist also die Neue im alten Garten?", font=font, fill=PAL["w"])
    ui.alpha_composite(nine_slice(parts["dialog_choice_bg"], 150, 12, 4), (88, 130))
    ui.alpha_composite(parts["dialog_cursor"].crop((0, 0, 8, 8)), (80, 132))
    d.text((94, 129), "Ja, seit ein paar Nächten.", font=font, fill=PAL["w"])
    d.text((94, 142), "Wer will das wissen?", font=font, fill=(198, 184, 190))
    ui.alpha_composite(parts["dialog_next"].crop((8, 0, 16, 8)), (296, 162))
    screen = bg.copy()
    screen.alpha_composite(ui.resize((640, 360), Image.NEAREST))
    sheet = Image.new("RGBA", (200, 40), (14, 10, 20, 255))
    x = 4
    for n in ("dialog_panel", "dialog_ornament", "dialog_nameplate", "dialog_portrait_frame",
              "dialog_portrait_bg", "dialog_next", "dialog_cursor", "dialog_choice_bg"):
        sheet.alpha_composite(parts[n], (x, 4))
        x += parts[n].width + 4
    out = Image.new("RGBA", (1280, 720 + 8 + 240), (14, 10, 20, 255))
    out.alpha_composite(screen.resize((1280, 720), Image.NEAREST), (0, 0))
    out.alpha_composite(sheet.crop((0, 0, x, 40)).resize((x * 6, 240), Image.NEAREST), (0, 728))
    out.save(os.path.join(ROOT, "docs", "art", "vorschau", "vorschau_dialog_2x.png"))


def main():
    parts = {
        "dialog_panel": dialog_panel(), "dialog_ornament": ornament(), "dialog_nameplate": nameplate(),
        "dialog_portrait_frame": portrait_frame(), "dialog_portrait_bg": portrait_bg(),
        "dialog_next": next_arrow(), "dialog_cursor": cursor(), "dialog_choice_bg": choice_bg(),
    }
    for n, im in parts.items():
        im.save(os.path.join(UI, f"{n}.png"))
        print(f"  {n}.png {im.size}")
    mockup(parts)
    print("  Vorschau: vorschau_dialog_2x.png")


if __name__ == "__main__":
    main()
