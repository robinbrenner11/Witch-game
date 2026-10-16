"""Prototyp Waldboden für den Seewald (Lake Woods), 32×32, kachelbar – TESTSTAND 15.10.2026.

Entwurf der Pixel (welche Farbe wohin). Gezeichnet, gespeichert und exportiert
werden die Kacheln danach über das pixel-plugin (pixel-mcp -> Aseprite), siehe
seewald_waldboden_plugin.py und docs/art/test_lakewood_bodentile.md.

Aufruf (aus dem Projektordner):
  python docs/art/ground_generator/seewald_waldboden.py docs/art/hexen_palette.gpl <ausgabeordner>
Erzeugt: ground_lakewood_floor_1..7.design.png + design_spec.json (Ebenen getrennt)
Benötigt: numpy, pillow

Kachel-Regeln
- Grundfläche ist eine einzige Farbe (Ebenholz 2). Kein Detail wird an der Kante
  abgeschnitten oder läuft auf die Nachbarkachel über (auch kein Schlagschatten).
  Dadurch passt jede Variante neben jede andere (Godot würfelt die Varianten),
  ohne gemeinsamen Randstreifen mit festen Details (der erzeugte beim alten
  Waldboden ein Punktraster alle 32 px).
- Grundfläche ist ruhig (eine Grundfarbe); Leben kommt aus kleinen, klar
  geformten Clustern: Erdkrumen, Dellen, Laubreste, wenige Hauptmotive.
- Licht von oben links: Krumen oben links hell, unten rechts dunkel;
  Dellen oben links dunkel, unten rechts hell; Schlagschatten nach unten rechts.
- Nur Farben aus docs/art/hexen_palette.gpl.
"""
import numpy as np, json, sys, os

N = 32
GPL = sys.argv[1] if len(sys.argv) > 1 else 'hexen_palette.gpl'


def load_gpl(path):
    pal = {}
    for line in open(path, encoding='utf-8'):
        p = line.split()
        if len(p) >= 4 and all(t.isdigit() for t in p[:3]):
            pal[" ".join(p[3:])] = tuple(int(t) for t in p[:3])
    return pal


PAL = load_gpl(GPL)
C = lambda name: PAL[name]          # KeyError = Farbe nicht in der Palette -> gewollt

# ---- Farbrollen (alle aus hexen_palette.gpl) ----
GRUND = C("Ebenholz 2")             # Grundfarbe Waldboden
TIEF = C("Ebenholz 1")              # Dellen, Schattenseite von Krumen
LICHT = C("Ebenholz 3")             # Lichtkante oben links
GLANZ = C("Ebenholz 4")             # einzelner Glanzpunkt auf großen Krumen
SCHLAG = C("Tiefschwarz")           # Schlagschatten
ROT = {"h": C("Bordeaux hell"), "m": C("Bordeaux"), "d": C("Bordeaux tief")}
OCKER = {"h": C("Gold dunkel"), "m": C("Gold sehr dunkel"), "d": C("Rinde Tanne 3")}
ALT = {"h": C("Gold sehr dunkel"), "m": C("Rinde Tanne 3"), "d": C("Bordeaux tief")}   # alte Blätter: gedämpft, aber warm (glimmen in Lichtinseln)
REST = [C("Bordeaux tief"), C("Rinde Tanne 3"), C("Rinde Tanne 3"), C("Gold sehr dunkel")]   # alte Laubreste, gedämpft
WEIDE = {"h": C("Weide hell"), "m": C("Weide mittel"), "d": C("Weide dunkel")}
MOOS = {"h": C("Laub mittel"), "m": C("Giftgruen dunkel"), "d": C("Laub dunkel")}
KIESEL = {"h": C("Rinde tot 4"), "m": C("Rinde tot 3"), "d": C("Rinde tot 2")}
ZWEIG = {"h": C("Ebenholz 4"), "m": C("Ebenholz 3"), "d": C("Ebenholz 1")}
WASSER = {"rand": C("Tiefschwarz"), "w": C("Nachtblau"), "w2": C("Nachtblau hell"), "glanz": C("Geisterblau")}
MAGIE = {"kern": C("Magenta"), "hof": C("Magenta gedaempft")}

EDGE = 0          # Kleinteile (Krumen, Laubreste) dürfen bis an den Rand, aber nie darüber
MOTIV = 2         # Hauptmotive halten 2 px Abstand zum Rand


def inside(pts, margin=EDGE):
    return all(margin <= x <= N - 1 - margin and margin <= y <= N - 1 - margin for x, y in pts)


def auto_shade(pts):
    """Form -> {(x,y): 'h'|'m'|'d'}: oben/links offen = hell, unten/rechts offen = dunkel."""
    s = set(pts)
    out = {}
    for (x, y) in s:
        lit = (x, y - 1) not in s or (x - 1, y) not in s
        dark = (x + 1, y) not in s or (x, y + 1) not in s
        if len(s) <= 2:
            out[(x, y)] = 'h' if lit and not dark or (x, y) == min(s, key=lambda p: p[0] + p[1]) else 'm'
        elif lit and dark:
            # schmale Stellen: nach Lage zur Lichtseite entscheiden
            out[(x, y)] = 'h' if ((x, y - 1) not in s and (x - 1, y) not in s) else 'd' if ((x + 1, y) not in s and (x, y + 1) not in s) else 'm'
        elif lit:
            out[(x, y)] = 'h'
        elif dark:
            out[(x, y)] = 'd'
        else:
            out[(x, y)] = 'm'
    return out


LEAF_SHAPES = [
    [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)],                     # rund
    [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2)],                     # schräg
    [(1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (1, 2), (2, 2)],     # breit
    [(2, 0), (1, 1), (2, 1), (0, 2), (1, 2)],                     # schräg andersrum
    [(0, 0), (1, 0), (0, 1), (1, 1), (2, 2)],                     # mit Stiel
]
WILLOW_SHAPES = [
    [(0, 0), (1, 1), (2, 1), (3, 2)],
    [(3, 0), (2, 1), (1, 1), (0, 2)],
    [(0, 0), (1, 0), (2, 1), (3, 1), (4, 2)],
]
CLUMPS = [                       # Erdkrumen: g = Glanz, h = Licht, m = Grund, d = Schatten
    ["gh.", "hmd", ".dd"],
    ["h.", "hd"],
    [".gh.", "hmmd", ".ddd"],
]
DENTS = [                        # Dellen: oben links Schatten, unten rechts Licht
    ["dd.", ".dh"],
    ["ddd", ".hh"],
    ["d.", "dh"],
]


def torus_dist(a, b):
    dx = abs(a[0] - b[0]); dy = abs(a[1] - b[1])
    return (min(dx, N - dx) ** 2 + min(dy, N - dy) ** 2) ** .5


class Tile:
    def __init__(self, name, seed):
        self.name = name
        self.rng = np.random.default_rng(seed)
        self.soil = np.zeros((N, N, 3), np.uint8); self.soil[:] = GRUND
        self.feat = {}            # Ebene "Laub & Details": (x,y) -> RGB
        self.shadow = set()       # Schlagschatten, liegen auf derselben Ebene unter den Objekten
        self.taken = set()        # belegte Pixel inkl. 1 px Abstand
        self.margin = MOTIV       # Randabstand für put(); Kleinteile setzen ihn kurz auf EDGE

    # -------- Bodenebene
    def soil_stamp(self, pat, x0, y0, cmap):
        pts = [(x0 + i, y0 + j) for j, row in enumerate(pat) for i, ch in enumerate(row) if ch != '.']
        if not inside(pts) or any(p in self.taken for p in pts):
            return False
        for j, row in enumerate(pat):
            for i, ch in enumerate(row):
                if ch in cmap:
                    self.soil[y0 + j, x0 + i] = cmap[ch]
        self._reserve(pts, 1)
        return True

    def texture(self, n_clumps, n_dents, n_bits):
        tries = 0
        while n_clumps and tries < 400:
            tries += 1
            if self.soil_stamp(CLUMPS[self.rng.integers(len(CLUMPS))], *self.rng.integers(EDGE, N - EDGE, 2), {'g': GLANZ, 'h': LICHT, 'd': TIEF}):
                n_clumps -= 1
        while n_dents and tries < 800:
            tries += 1
            if self.soil_stamp(DENTS[self.rng.integers(len(DENTS))], *self.rng.integers(EDGE, N - EDGE, 2), {'h': LICHT, 'd': TIEF}):
                n_dents -= 1
        while n_bits and tries < 1200:      # Laubreste: 2er-Cluster, gedämpft
            tries += 1
            x, y = (int(v) for v in self.rng.integers(EDGE, N - EDGE - 1, 2))
            pts = [(x, y), (x + 1, y)] if self.rng.random() < .5 else [(x, y), (x + 1, y + 1)]
            if inside(pts) and not any(p in self.taken for p in pts):
                col = REST[int(self.rng.integers(len(REST)))]
                for p in pts:
                    self.feat[p] = col
                self._reserve(pts, 1)
                n_bits -= 1

    def litter(self, n, centers=1, spread=4.5):
        """Alte, gedämpfte Blätter (Mitteltöne, weicher Schatten in Ebenholz 1).
        Liegen in losen Gruppen um wenige Zentren statt gleichmäßig verteilt (sonst Teppich-Wirkung)."""
        self.margin = EDGE
        cs = [tuple(int(v) for v in self.rng.integers(3, N - 3, 2)) for _ in range(centers)]
        tries = 0
        while n and tries < 800:
            tries += 1
            cx, cy = cs[tries % len(cs)]
            x = int(round(cx + self.rng.normal(0, spread))); y = int(round(cy + self.rng.normal(0, spread * .8)))
            shape = [LEAF_SHAPES[i] for i in (0, 1, 3, 4)][int(self.rng.integers(4))]
            pts = [(x + dx, y + dy) for dx, dy in shape]
            if any(p in self.taken for p in pts):
                continue
            sh = auto_shade(pts)
            cast = [(px + 1, py + 1) for px, py in pts if (px + 1, py + 1) not in sh]
            if not inside(pts + cast, EDGE) or any(c in self.taken for c in cast):
                continue
            for c in cast:
                self.soil[c[1], c[0]] = TIEF
            for q, k in sh.items():
                self.feat[q] = ALT[k]
            self._reserve(pts + cast, 1)
            n -= 1
        self.margin = MOTIV

    def _reserve(self, pts, pad):
        for (x, y) in pts:
            for dy in range(-pad, pad + 1):
                for dx in range(-pad, pad + 1):
                    self.taken.add((x + dx, y + dy))

    # -------- Detailebene
    def put(self, shaded, colors, cast=True, force=False):
        pts = list(shaded)
        cast_pts = [(x + 1, y + 1) for x, y in pts if (x + 1, y + 1) not in shaded] if cast else []
        if not inside(pts + cast_pts, self.margin):
            return False
        if not force and any(p in self.taken and p not in self.feat for p in pts):
            return False
        for q in cast_pts:
            if q not in self.feat:
                self.shadow.add(q)
            else:  # Schatten fällt auf ein darunterliegendes Blatt: dessen Dunkelton
                pass
        for p, k in shaded.items():
            self.feat[p] = colors[k]
            self.shadow.discard(p)
        self._reserve(pts + cast_pts, 0)
        return True

    def leaf(self, x, y, fam, shape):
        return self.put(auto_shade([(x + dx, y + dy) for dx, dy in LEAF_SHAPES[shape]]), fam, force=True)

    def willow(self, x, y, shape):
        pts = [(x + dx, y + dy) for dx, dy in WILLOW_SHAPES[shape]]
        return self.put({p: ('h' if i == 0 else 'm' if i < len(pts) - 1 else 'd') for i, p in enumerate(pts)}, WEIDE, force=True)

    def pile(self, cx, cy, n, fams, spread=3.6):
        placed = 0
        for _ in range(80):
            if placed >= n:
                break
            a, d = self.rng.uniform(0, 2 * np.pi), self.rng.uniform(0, spread)
            x, y = int(round(cx + np.cos(a) * d)), int(round(cy + np.sin(a) * d * .75))
            if self.leaf(x, y, fams[placed % len(fams)], int(self.rng.integers(len(LEAF_SHAPES)))):
                placed += 1
        return placed

    def blob(self, cx, cy, rx, ry, colors, jag=0.3, cast=False):
        pts = []
        for y in range(cy - ry - 1, cy + ry + 2):
            for x in range(cx - rx - 1, cx + rx + 2):
                d = ((x - cx) / (rx + .5)) ** 2 + ((y - cy) / (ry + .5)) ** 2
                if d < 1 - jag * self.rng.uniform(0, 1) * (d > .5):
                    pts.append((x, y))
        return self.put(auto_shade(pts), colors, cast=cast, force=True)

    def image(self):
        img = self.soil.copy()
        for (x, y) in self.shadow:
            img[y, x] = SCHLAG
        for (x, y), c in self.feat.items():
            img[y, x] = c
        return img

    def details_rgba(self):
        det = np.zeros((N, N, 4), np.uint8)
        for (x, y) in self.shadow:
            det[y, x] = (*SCHLAG, 255)
        for (x, y), c in self.feat.items():
            det[y, x] = (*c, 255)
        return det


def build():
    T = []
    # 1 Ruhig: nur Bodenstruktur und Laubreste (häufigste Kachel)
    t = Tile("ground_lakewood_floor_1", 101); t.leaf(21, 20, OCKER, 4); t.texture(6, 3, 2); t.litter(5, 5, 2.0); T.append(t)
    # 2 Ruhig mit einzelnem Blatt
    t = Tile("ground_lakewood_floor_2", 202); t.leaf(6, 22, OCKER, 1); t.leaf(23, 8, OCKER, 4); t.texture(5, 3, 2); t.litter(5, 5, 2.0); T.append(t)
    # 3 Laubhaufen (warmer Akzent), außermittig oben rechts
    t = Tile("ground_lakewood_floor_3", 303); t.pile(19, 11, 6, [ROT, OCKER, ROT, OCKER]); t.texture(5, 2, 2); t.litter(4, 1); T.append(t)
    # 4 Moos + Kiesel (Seenähe), Moos unten links, Kiesel oben rechts
    t = Tile("ground_lakewood_floor_4", 404)
    t.blob(8, 21, 3, 2, MOOS, jag=0.45); t.blob(12, 24, 1, 1, MOOS)
    t.put(auto_shade([(22, 7), (23, 7), (22, 8), (23, 8)]), KIESEL)
    t.put(auto_shade([(26, 11), (27, 11)]), KIESEL)
    t.texture(6, 3, 0); T.append(t)
    # 5 Zweig + Weidenblätter (Weiden am See)
    t = Tile("ground_lakewood_floor_5", 505)
    twig = [(14, 6), (15, 7), (16, 7), (17, 8), (18, 9), (19, 9), (20, 10), (21, 11), (22, 11), (18, 8)]
    t.put({p: ('h' if i in (0, 9) else 'm') for i, p in enumerate(twig)}, ZWEIG)
    t.willow(5, 20, 0); t.willow(20, 23, 2)
    t.texture(5, 2, 2); t.litter(3, 3, 2.0); T.append(t)
    # 6 Pfütze (selten): nasse Senke, kühler Mondglanz. Von Hand gesetzt.
    t = Tile("ground_lakewood_floor_6", 606)
    PUDDLE = ["...RRRRR...",
              ".RRwwwwwRR.",
              "RwGGwwwwww2",
              ".2wwwwwGw2.",
              "..222222..."]
    key = {'R': 'rand', 'w': 'w', 'G': 'glanz', '2': 'w2'}
    x0, y0 = 7, 15
    sh = {(x0 + i, y0 + j): key[ch] for j, row in enumerate(PUDDLE) for i, ch in enumerate(row) if ch != '.'}
    t.put(sh, WASSER, cast=False, force=True)
    for (x, y) in list(sh):                        # nasses Ufer unten rechts fängt Licht
        for q in ((x + 1, y + 1), (x, y + 1), (x + 1, y)):
            if q not in sh and inside([q]) and q[0] + q[1] > x0 + y0 + 9:
                t.soil[q[1], q[0]] = LICHT
    t._reserve(list(sh), 2)
    t.texture(5, 1, 2); t.litter(5, 1); T.append(t)
    # 7 Hexenspur (sehr selten): Magenta-Sporen
    t = Tile("ground_lakewood_floor_7", 707)
    for (x, y) in [(10, 9), (18, 14), (12, 19)]:
        t.put({(x, y): 'kern', (x - 1, y): 'hof', (x + 1, y): 'hof', (x, y - 1): 'hof', (x, y + 1): 'hof'}, MAGIE, cast=False, force=True)
    t.put({(15, 11): 'hof'}, MAGIE, cast=False, force=True)
    t.leaf(22, 22, ROT, 0)
    t.texture(5, 2, 2); t.litter(4, 1); T.append(t)
    return T


WEIGHTS = {1: 36, 2: 24, 3: 12, 4: 9, 5: 12, 6: 3, 7: 4}

if __name__ == '__main__':
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)
    from PIL import Image
    tiles = build()
    spec = []
    for t in tiles:
        Image.fromarray(t.image(), 'RGB').save(f"{out}/{t.name}.design.png")
        spec.append({"name": t.name, "soil": t.soil.tolist(), "details": t.details_rgba().tolist()})
    json.dump({"weights": WEIGHTS, "tiles": spec}, open(f"{out}/design_spec.json", "w"))
    print("ok", len(tiles))
