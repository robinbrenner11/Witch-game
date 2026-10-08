"""Gemeinsame Helfer für Flora und Fauna (Bitterbloom).

Wird von forest.py, garden.py und preview.py importiert, nicht direkt aufgerufen.

Prinzip: Jede Grafik wird auf einer Layer (Raster aus Farbschlüsseln) gemalt,
danach bekommt sie automatisch eine Aubergine-Kontur. Kronen und Büsche werden
aus Kugeln zusammengesetzt und von OBEN LINKS beleuchtet, dann auf wenige
Paletten-Töne quantisiert (harte Stufen, keine Verläufe). Wiegen im Wind
entsteht, indem Zeilen um ganze Pixel verschoben werden.
"""
import math
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]

# ---------------------------------------------------------------------------
# Farben. Alles steht in hexen_palette.gpl; die mit * sind am 08.10. neu dazu.
PAL = {
    "o": (43, 22, 51),      # Aubergine – Kontur
    "TS": (14, 10, 20),     # Tiefschwarz
    "NV": (26, 20, 46),     # Nachtviolett
    "NB": (20, 27, 58),     # Nachtblau
    "NBH": (52, 70, 120),   # Nachtblau hell
    # Laub (Eiche, Büsche, Holunder)
    "L0": (22, 34, 46),     # * Laub Schatten
    "L1": (29, 52, 54),     # * Laub dunkel
    "GD": (36, 74, 58),     # Giftgruen dunkel
    "L3": (48, 98, 74),     # * Laub mittel
    "G": (63, 125, 90),     # Giftgruen
    "GH": (98, 160, 110),   # Giftgruen hell
    # Weide (kühler, silbrig)
    "W1": (33, 57, 68),     # * Weide dunkel
    "W2": (58, 96, 98),     # * Weide mittel
    "W3": (104, 146, 136),  # * Weide hell
    "SM": (214, 232, 222),  # Silber-Mondlicht
    # Holz
    "E1": (32, 20, 30), "E2": (52, 34, 46), "E3": (78, 52, 64), "E4": (104, 72, 84),
    "LST": (150, 136, 160),  # Laken Schatten tief (Schnittfläche, Glanz)
    # Rinde je Baumart (* neu 08.10.): E1 bleibt als gemeinsamer dunkelster Ton
    "OK2": (52, 40, 44), "OK3": (76, 62, 62), "OK4": (102, 88, 82),        # Eiche: graubraun
    "WI2": (46, 50, 52), "WI3": (70, 76, 72), "WI4": (98, 104, 94),        # Weide: grünlich-grau
    "FI2": (60, 30, 34), "FI3": (88, 48, 44), "FI4": (116, 70, 58),        # Tanne: rotbraun
    "DE2": (62, 56, 70), "DE3": (92, 86, 100), "DE4": (130, 124, 136),     # toter Baum: ausgebleicht
    "EL2": (66, 56, 54), "EL3": (94, 84, 76), "EL4": (126, 116, 102),      # Holunder: hell, korkig
    "LS": (198, 184, 190),   # Laken Schatten
    "KN": (234, 223, 203),   # Knochen
    "WO": (124, 124, 104),   # Welk oliv (Bartflechte)
    # Stein
    "K1": (38, 30, 58), "K2": (56, 50, 96), "K3": (82, 78, 140), "KR2": (104, 96, 140),
    # Licht kalt
    "GEI": (120, 140, 185), "EIS": (206, 214, 244), "GK": (240, 244, 255),
    # Licht warm
    "GOLD": (217, 164, 65), "GOLDD": (156, 104, 52), "GOLDH": (244, 204, 120),
    "KL": (255, 181, 102), "LK": (255, 246, 220),
    # Magie
    "M": (194, 48, 122), "MH": (228, 88, 177), "MR": (255, 210, 236), "MG": (92, 30, 78),
    # Blüten
    "FL": (169, 155, 224), "IND": (46, 42, 107), "INDH": (74, 69, 150),
    "BOR": (110, 24, 48), "BORD": (77, 18, 48), "BORH": (150, 44, 72),
}
NEW_COLORS = {
    "Laub Schatten": "L0", "Laub dunkel": "L1", "Laub mittel": "L3",
    "Weide dunkel": "W1", "Weide mittel": "W2", "Weide hell": "W3",
    "Rinde Eiche 2-4": "OK2-4", "Rinde Weide 2-4": "WI2-4", "Rinde Tanne 2-4": "FI2-4",
    "Rinde tot 2-4": "DE2-4", "Rinde Holunder 2-4": "EL2-4",
}
BARK = {
    "oak": ["E1", "OK2", "OK3", "OK4"], "willow": ["E1", "WI2", "WI3", "WI4"],
    "fir": ["E1", "FI2", "FI3", "FI4"], "dead": ["E1", "DE2", "DE3", "DE4"],
    "elder": ["E1", "EL2", "EL3", "EL4"],
}

LIGHT = (-0.55, -0.75, 0.62)          # von oben links, leicht auf die Betrachterin zu
_ln = math.sqrt(sum(c * c for c in LIGHT))
LIGHT = tuple(c / _ln for c in LIGHT)


# ---------------------------------------------------------------------------
def _hash(x, y, seed):
    h = (x * 374761393 + y * 668265263 + seed * 2147483647) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def noise(x, y, scale, seed=0):
    """Weiches Wertrauschen 0..1 (deterministisch), Körnung = scale Pixel."""
    fx, fy = x / scale, y / scale
    x0, y0 = math.floor(fx), math.floor(fy)
    tx, ty = fx - x0, fy - y0
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    a, b = _hash(x0, y0, seed), _hash(x0 + 1, y0, seed)
    c, d = _hash(x0, y0 + 1, seed), _hash(x0 + 1, y0 + 1, seed)
    return (a + (b - a) * tx) + ((c + (d - c) * tx) - (a + (b - a) * tx)) * ty


class Layer:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def set(self, x, y, k):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = k

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def paste(self, other, dx=0, dy=0):
        for y in range(other.h):
            for x in range(other.w):
                k = other.px[y][x]
                if k is not None:
                    self.set(x + dx, y + dy, k)

    def copy(self):
        n = Layer(self.w, self.h)
        n.px = [r[:] for r in self.px]
        return n

    def shift_rows(self, fn):
        """Zeile y wird um fn(y) Pixel waagerecht verschoben (Wiegen)."""
        n = Layer(self.w, self.h)
        for y in range(self.h):
            dx = fn(y)
            for x in range(self.w):
                k = self.px[y][x]
                if k is not None:
                    n.set(x + dx, y, k)
        return n

    def outline(self, key="o"):
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    k = self.get(x + dx, y + dy)
                    if k is not None and k != key:
                        add.append((x, y))
                        break
        for x, y in add:
            self.px[y][x] = key
        return self

    def cleanup(self, keep=()):
        """Einzelne Ausreißer-Pixel entfernen: Ein Pixel, dessen vier Nachbarn
        alle gleich (und anders) sind, übernimmt deren Farbe. keep = Farben,
        die als Akzent stehen bleiben dürfen (Blüten, Glanzpunkte)."""
        changes = []
        for y in range(self.h):
            for x in range(self.w):
                k = self.px[y][x]
                if k is None or k in keep:
                    continue
                ns = [self.get(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                if None in ns:
                    continue
                if ns.count(ns[0]) == 4 and ns[0] != k:
                    changes.append((x, y, ns[0]))
        for x, y, k in changes:
            self.px[y][x] = k
        return self

    def image(self):
        im = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                k = self.px[y][x]
                if k is not None:
                    im.putpixel((x, y), PAL[k] + (255,))
        return im


# ---------------------------------------------------------------------------
def blobs(layer, circles, tones, seed=1, edge=1.3, clump=3.0, clump_amt=0.32,
          ao=0.18, top=None, bottom=None, mask=None):
    """Krone/Busch aus Kugeln. circles = [(cx, cy, r), ...], spätere liegen vorn.
    tones = dunkel -> hell. Kanten werden per Rauschen ausgefranst (Laub)."""
    if top is None:
        top = min(cy - r for cx, cy, r in circles)
    if bottom is None:
        bottom = max(cy + r for cx, cy, r in circles)
    span = max(1.0, bottom - top)
    for y in range(layer.h):
        for x in range(layer.w):
            hit = None
            for i in range(len(circles) - 1, -1, -1):
                cx, cy, r = circles[i]
                rr = r + (noise(x, y, 2.6, seed + i) - 0.5) * 2 * edge
                d = math.hypot(x - cx, y - cy)
                if d <= rr:
                    hit = (cx, cy, max(rr, 0.5))
                    break
            if hit is None:
                continue
            if mask is not None and not mask(x, y):
                continue
            cx, cy, r = hit
            nx, ny = (x - cx) / r, (y - cy) / r
            nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
            lum = nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]
            lum = (lum + 0.35) / 1.35
            lum += (noise(x, y, clump, seed + 50) - 0.5) * 2 * clump_amt
            lum -= ao * (y - top) / span
            idx = int(lum * len(tones))
            layer.set(x, y, tones[max(0, min(len(tones) - 1, idx))])
    return layer


def _sphere_lum(nx, ny):
    nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
    return (nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2] + 0.35) / 1.35


def foliage(layer, masses, tones, seed=1, clump=(3.0, 5.0), density=1.0, ao=0.22,
            local=0.5, accent=None, accent_at=0.93, mask=None, offset=None):
    """Laubkrone aus vielen kleinen Büscheln. masses = große Kugeln [(cx, cy, r)],
    die die Gesamtform vorgeben; darin werden Büschel verteilt und jedes einzeln
    beleuchtet (local = Anteil des Büschel-Lichts, Rest = Licht der Gesamtform).
    Untere Büschel liegen vorn. accent = Farbe für die hellsten Spitzen."""
    clumps = []
    n = 0
    for mi, (mx, my, mr) in enumerate(masses):
        avg = (clump[0] + clump[1]) / 2
        count = int(density * 1.5 * (mr * mr) / (avg * avg)) + 3
        for j in range(count):
            n += 1
            a = _hash(n, mi, seed) * math.tau
            d = math.sqrt(_hash(n, mi + 99, seed)) * (mr - clump[0] * 0.5)
            r = clump[0] + _hash(n, mi + 7, seed) * (clump[1] - clump[0])
            clumps.append((mx + math.cos(a) * d, my + math.sin(a) * d, r, mi))
    clumps.sort(key=lambda c: c[1] + c[2] * 0.3)
    top = min(my - mr for mx, my, mr in masses)
    bottom = max(my + mr for mx, my, mr in masses)
    span = max(1.0, bottom - top)
    for cx, cy, r, mi in clumps:
        mx, my, mr = masses[mi]
        ox = offset(cx, cy, top, bottom) if offset else 0     # ganzes Büschel verschieben
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                rr = r + (noise(x, y, 1.7, seed + 3) - 0.5) * 1.1
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if d > rr:
                    continue
                if mask is not None and not mask(x, y):
                    continue
                g = _sphere_lum(max(-1, min(1, (x - mx) / mr)), max(-1, min(1, (y - my) / mr)))
                l = _sphere_lum((x + 0.5 - cx) / rr, (y + 0.5 - cy) / rr)
                lum = (1 - local) * g + local * l - ao * (y - top) / span
                idx = int(lum * len(tones))
                k = tones[max(0, min(len(tones) - 1, idx))]
                if accent and lum > accent_at:
                    k = accent
                layer.set(x + ox, y, k)
    return layer


def limb(layer, spine, tones, seed=3, bark=True):
    """Stamm/Ast entlang einer Linie. spine = [(x, y, halbe_Breite), ...].
    tones = 4 Holztöne dunkel -> hell; Licht von links."""
    for (x0, y0, w0), (x1, y1, w1) in zip(spine, spine[1:]):
        steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for s in range(steps + 1):
            t = s / steps
            cx, cy, hw = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, w0 + (w1 - w0) * t
            if hw < 0.75:
                layer.set(cx, cy, tones[1])
                continue
            for xi in range(int(math.floor(cx - hw)), int(math.ceil(cx + hw)) + 1):
                rel = (xi - cx) / (hw + 0.35)
                if abs(rel) > 1.0:
                    continue
                if rel < -0.45:
                    k = 3
                elif rel < 0.15:
                    k = 2
                elif rel < 0.65:
                    k = 1
                else:
                    k = 0
                if bark and hw >= 1.8 and k >= 1 and noise(xi * 4, cy * 0.5, 1.0, seed) > 0.78:
                    k -= 1                                 # Rindenfurche
                layer.set(xi, cy, tones[k])


def frames_to_sheet(frames):
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * w, 0))
    return sheet


def check(name, frames, foot=True):
    """Nur volle/leere Pixel, nur Palettenfarben, Fuß auf der untersten Zeile."""
    pal = set(PAL.values())
    ok = True
    cols = set()
    for i, f in enumerate(frames):
        for (n, c) in f.getcolors(1 << 16):
            if c[3] not in (0, 255):
                print(f"  ! {name} F{i}: halbtransparent")
                ok = False
            if c[3] == 255:
                cols.add(c[:3])
                if c[:3] not in pal:
                    print(f"  ! {name} F{i}: Fremdfarbe {c[:3]}")
                    ok = False
        if foot and f.getbbox() and f.getbbox()[3] != f.height:
            print(f"  ! {name} F{i}: steht nicht auf der untersten Zeile")
            ok = False
    w, h = frames[0].size
    print(f"  {name}: {w}x{h}, {len(frames)} Frame(s), {len(cols)} Farben {'ok' if ok else 'FEHLER'}")
    return ok


def glow_mask(frames, keys):
    """Nur die selbstleuchtenden Pixel (Farbschlüssel keys) – für eine zweite,
    unbeleuchtete Ebene in Godot (CanvasItemMaterial, light_mode = Unshaded)."""
    cols = {PAL[k] for k in keys}
    out = []
    for f in frames:
        g = Image.new("RGBA", f.size, (0, 0, 0, 0))
        src, dst = f.load(), g.load()
        for y in range(f.height):
            for x in range(f.width):
                c = src[x, y]
                if c[3] and c[:3] in cols:
                    dst[x, y] = c
        out.append(g)
    return out


def save(rel_dir, name, frames, foot=True, glow=None):
    out = ROOT / rel_dir
    out.mkdir(parents=True, exist_ok=True)
    check(name, frames, foot)
    frames_to_sheet(frames).save(out / f"{name}.png")
    if glow:
        frames_to_sheet(glow_mask(frames, glow)).save(out / f"{name}_glow.png")
        print(f"    + {name}_glow.png")
    return frames


SWAY = [0, 1, 0, -1]     # Phase je Frame beim Wiegen (Loop, 4 Frames)

# Wiegen mit 8 Frames: Die Wipfel schwingen vor, die Mitte folgt einen Frame
# später, unten bleibt alles ruhig. Ganze Laubbüschel bewegen sich, deshalb
# reißen keine Zeilen auf.
SWAY8_TOP = [0, 1, 1, 1, 0, -1, -1, -1]
SWAY8_MID = [-1, 0, 1, 1, 1, 0, -1, -1]


def crown_sway(frame, top_part=0.4, mid_part=0.7):
    """offset-Funktion für foliage(): Büschel oben/mitte/unten."""
    def fn(cx, cy, top, bottom):
        t = (cy - top) / max(1.0, bottom - top)
        if t < top_part:
            return SWAY8_TOP[frame]
        if t < mid_part:
            return SWAY8_MID[frame]
        return 0
    return fn
