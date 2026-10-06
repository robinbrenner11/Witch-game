"""Hilfsfunktionen: ASCII-Pixelraster -> Sprite. Linke Hälfte zeichnen, spiegeln,
rechte Hälfte abdunkeln (Licht von oben links), Aubergine-Kontur automatisch."""
from PIL import Image

PAL = {
    "k": (14, 10, 20), "a": (43, 22, 51), "n": (20, 27, 58),
    "d": (77, 18, 48), "b": (110, 24, 48), "m": (194, 48, 122),
    "M": (228, 88, 177), "g": (217, 164, 65), "c": (255, 181, 102),
    "w": (234, 223, 203), "G": (63, 125, 90),
    "i": (46, 42, 107), "I": (74, 69, 150), "l": (169, 155, 224),
}
# Abdunkeln für die lichtabgewandte (rechte) Seite
DARKER = {"I": "i", "i": "n", "l": "I", "M": "m", "m": "b", "b": "d", "w": "l", "G": "n"}
W, H = 32, 48


def mirror(rows, darken=True, center_override=None):
    """rows: Liste von 16-Zeichen-Strings (linke Hälfte). Gibt 32er-Zeilen zurück."""
    out = []
    for r in rows:
        r = r.ljust(16, ".")[:16]
        right = "".join(DARKER.get(ch, ch) if darken else ch for ch in reversed(r))
        out.append(r + right)
    return out


def grid(rows):
    rows = [r.ljust(W, ".")[:W] for r in rows]
    rows += ["." * W] * (H - len(rows))
    return [list(r) for r in rows]


def put(g, x, y, ch):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = ch


def outline(g, col="a", skip="."):
    add = []
    for y in range(H):
        for x in range(W):
            if g[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and g[ny][nx] not in ".*":
                    add.append((x, y)); break
    for x, y in add:
        g[y][x] = col


def to_image(g):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y in range(H):
        for x in range(W):
            ch = g[y][x]
            if ch in PAL:
                im.putpixel((x, y), PAL[ch] + (255,))
    return im
