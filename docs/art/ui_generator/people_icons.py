"""Platzhalter-Bildchen (16x16) für das People-Kapitel im Grimoire.

Eine Kopf-und-Schultern-Silhouette pro NPC in den Farben seiner
Graybox-Figur (scenes/npcs/<id>.tscn), dunkle Aubergine-Kontur, Licht von
oben links. Robins echte Porträts ersetzen sie später unter demselben Namen.
Aufruf: python docs/art/ui_generator/people_icons.py assets/ui/people
"""
import os
import sys

from PIL import Image

OUT = "#2B1633"
BONE = "#EADFCB"
CANDLE = "#FFB566"

# Je NPC eine Zeichnung als Zeichenraster: Buchstabe -> Farbe.
ICONS = {
    "watchman": ({
        "o": OUT, "h": "#1C0F22", "s": "#B98B6E", "c": "#6E1830", "C": "#8E2A44", "l": CANDLE, "b": BONE,
    }, [
        "................",
        ".....oooooo.....",
        "....ohhhhhho....",
        "...oooooooooo...",
        ".....osssso.....",
        ".....osbsbo.....",
        ".....ossss o....",
        "......oooo......",
        "....ooCccco.....",
        "...oCCccccco....",
        "..oCCcccccccoo..",
        "..oCcccccccoloo.",
        "..oCcccccccolllo",
        "..occcccccccoloo",
        "..occcccccccooo.",
        "..oooooooooooo..",
    ]),
    "mother_moss": ({
        "o": OUT, "m": "#3F6140", "M": "#5C8050", "s": "#9E8C73", "b": BONE, "w": "#4F3329", "u": "#BFD1F2",
    }, [
        "............uuu.",
        "....oooooo..uuu.",
        "...oMMMMMMo..w..",
        "..oMMmmmmMMo.w..",
        "..oMmossssmo.w..",
        "..oMmosbsbmo.w..",
        "..oMmossssmo.w..",
        "..oMMmooooMMow..",
        ".oMMMMmmmmMMMw..",
        ".oMmMMmmmmmMMw..",
        "oMMmmmmmmmmmMwo.",
        "oMmmmmmmmmmmmwo.",
        "oMmmmmmmmmmmmwo.",
        "ommmmmmmmmmmmwo.",
        "ommmmmmmmmmmmwo.",
        "oooooooooooooooo",
    ]),
    "ugo": ({
        "o": OUT, "g": "#5C6130", "G": "#7F8E4D", "y": "#80904D", "b": BONE, "r": "#6E1830", "R": "#8E2A44",
    }, [
        "................",
        "......oooo......",
        ".....oRRrro.....",
        "....oooooooo....",
        "..oo........oo..",
        ".oGGo......oGGo.",
        ".oGbGooooooGbGo.",
        "oGGGGGGGGGGGGGGo",
        "oGgggggggggggggo",
        "oGgooooooooooggo",
        "oGgggggggggggggo",
        "oGggyyyyyyyyyggo",
        "oGgyyyyyyyyyyygo",
        "oggyyyyyyyyyyygo",
        ".oggggggggggggo.",
        "..oooooooooooo..",
    ]),
    "gnarl": ({
        "o": OUT, "k": "#C2307A", "K": "#E458B1", "s": "#8C8566", "b": BONE, "d": "#9E8566", "c": "#4F3329",
    }, [
        "..........oo....",
        ".........oKko...",
        "........oKkko...",
        ".......oKkkko...",
        "....ooKkkkkko...",
        "...oKkkkkkkkko..",
        "...oooooooooooo.",
        "....osssssssso..",
        "....osbsssbsso..",
        "....osssssssso..",
        "....oddddddddo..",
        "...ocdddddddddo.",
        "..occcdddddddco.",
        "..occccddddccco.",
        "..occcccddccccco",
        "..oooooooooooooo",
    ]),
}


def draw(colors, rows):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, key in enumerate(row[:16]):
            if key in colors:
                img.putpixel((x, y), Image.new("RGB", (1, 1), colors[key]).getpixel((0, 0)) + (255,))
    return img


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/ui/people"
    os.makedirs(out, exist_ok=True)
    for name, (colors, rows) in ICONS.items():
        assert len(rows) == 16, name
        draw(colors, rows).save(os.path.join(out, name + ".png"))
    print("People-Bildchen nach", out)


if __name__ == "__main__":
    main()
