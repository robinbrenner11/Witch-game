"""Erzeugt alle Ausgabedateien, Übersichten, Map-Vorschau und Prüfberichte."""
import sys, os, json
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import materials as M
import transitions as T
from core import N

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

mats = {'gras': M.make_grass(), 'erde': M.make_soil('erde'), 'weg': M.make_soil('weg'),
        'beet': M.make_beet(), 'pflaster': M.make_pflaster(), 'platte': M.make_platte()}
trans = T.build_all()


def save(a, path, scale=1):
    im = Image.fromarray(a.astype(np.uint8), 'RGB')  # wie Originale: RGB, voll deckend
    if scale > 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, optimize=True)


# ------------------------------------------------ Einzel-Tiles + Atlanten
tiles_dir = os.path.join(OUT, 'boden_tiles')
for n, vs in mats.items():
    for k, a in vs.items():
        save(a, os.path.join(tiles_dir, 'einzeln', f'boden_{n}_{k}.png'))
    row = np.concatenate([vs[k] for k in sorted(vs)], 1)
    save(row, os.path.join(tiles_dir, 'atlanten', f'atlas_{n}.png'))
for n, ts in trans.items():
    save(T.atlas(ts), os.path.join(tiles_dir, 'uebergaenge', f'uebergang_{n}.png'))

# Gesamt-Atlas: eine Zeile je Bodenart (6 Spalten), danach Übergangsatlanten nebeneinander
cols = 6
fill_atlas = np.zeros((len(mats) * N, cols * N, 3), np.uint8)
layout = {}
for r, (n, vs) in enumerate(mats.items()):
    for c, k in enumerate(sorted(vs)):
        fill_atlas[r * N:(r + 1) * N, c * N:(c + 1) * N] = vs[k]
        layout[f'boden_{n}_{k}'] = [c, r]
save(fill_atlas, os.path.join(tiles_dir, 'atlanten', 'atlas_boden_gesamt.png'))
with open(os.path.join(tiles_dir, 'atlanten', 'atlas_boden_gesamt_layout.json'), 'w') as f:
    json.dump({'tile_size': 32, 'columns': cols, 'tiles_col_row': layout}, f, indent=1)

# ------------------------------------------------ Kanten-Prüfung
report = []
for n, vs in mats.items():
    bad = 0
    groups = [[1, 2, 3], [4, 5, 6]] if n == 'beet' else [sorted(vs)]
    for a, b in [(vs[i], vs[j]) for g in groups for i in g for j in g]:
        if True:
            # Randstreifen identisch -> jede Kombination nahtlos wie Tile mit sich selbst
            if not (np.array_equal(a[:, :2], b[:, :2]) and np.array_equal(a[:2], b[:2])
                    and np.array_equal(a[:, -2:], b[:, -2:]) and np.array_equal(a[-2:], b[-2:])):
                bad += 1
    report.append(f'{n}: Randstreifen-Abweichungen zwischen Varianten = {bad}' + (' (trocken/nass je Gruppe geprueft)' if n == 'beet' else ''))
for n, ts in trans.items():
    up = {'gras_erde': 'gras', 'gras_weg': 'gras', 'pflaster_weg': 'pflaster'}[n]
    lo = {'gras_erde': 'erde', 'gras_weg': 'weg', 'pflaster_weg': 'weg'}[n]
    worst, fails = 0, 0
    keys = list(ts.keys())
    for ka in keys:
        ia = ka if isinstance(ka, int) else ka[1]
        for kb in keys:
            ib = kb if isinstance(kb, int) else kb[1]
            a, b = ts[ka].astype(int), ts[kb].astype(int)
            # horizontal: rechte Ecken von a == linke Ecken von b
            if ((ia >> 1) & 1, (ia >> 3) & 1) == ((ib >> 0) & 1, (ib >> 2) & 1):
                d = np.abs(a[:, -1] - b[:, 0]).sum(1).mean()
                worst = max(worst, d); fails += d > 60
            if ((ia >> 2) & 1, (ia >> 3) & 1) == ((ib >> 0) & 1, (ib >> 1) & 1):
                d = np.abs(a[-1] - b[0]).sum(1).mean()
                worst = max(worst, d); fails += d > 60
    report.append(f'{n}: max. mittl. Kantendifferenz {worst:.1f} (Fülltile-Inneres zum Vergleich ~15-50), Ausreißer>60: {fails}')
print('\n'.join(report))
with open(os.path.join(OUT, 'pruefbericht.txt'), 'w') as f:
    f.write('\n'.join(report) + '\n')

# ------------------------------------------------ Map-Vorschau (Vertex-Terrain)
W_, H_ = 30, 20
V = np.full((H_ + 1, W_ + 1), 'G')
yy, xx = np.mgrid[0:H_ + 1, 0:W_ + 1]
V[((xx - 7) / 5.2) ** 2 + ((yy - 6) / 3.6) ** 2 <= 1] = 'E'
V[(yy >= 12) & (yy <= 13)] = 'W'
V[(xx >= 15) & (xx <= 16) & (yy <= 12)] = 'W'
V[(xx >= 20) & (yy >= 1) & (yy <= 10)] = 'W'
V[(xx >= 22) & (yy >= 2) & (yy <= 9)] = 'P'
V[(xx >= 1) & (xx <= 10) & (yy >= 15) & (yy <= 19)] = 'W'
V[(yy >= 13) & (yy <= 16) & (xx >= 18) & (xx <= 19)] = 'W'
V[(xx - 25) ** 2 / 9 + (yy - 17.5) ** 2 / 2.6 <= 1] = 'E'
setmap = {frozenset('GE'): ('gras_erde', 'G'), frozenset('GW'): ('gras_weg', 'G'),
          frozenset('PW'): ('pflaster_weg', 'P')}
rng = np.random.default_rng(42)
mapimg = np.zeros((H_ * N, W_ * N, 3), np.uint8)
names = {'G': 'gras', 'E': 'erde', 'W': 'weg', 'P': 'pflaster'}
errors = 0
last = {}
for cy in range(H_):
    for cx in range(W_):
        c = [V[cy, cx], V[cy, cx + 1], V[cy + 1, cx], V[cy + 1, cx + 1]]
        s = frozenset(c)
        if len(s) == 1:
            n = names[c[0]]
            if n == 'erde' and 3 <= cx <= 9 and 4 <= cy <= 7:
                n = 'beet'
            if n == 'weg' and 2 <= cx <= 8 and 16 <= cy <= 18:
                n = 'platte'
            vs = mats[n]
            keys = sorted(vs)
            if n == 'beet':
                k = 1 + (cx % 3) if cx < 7 else 4 + (cx % 3)  # rechte Hälfte gegossen
            else:
                w = np.array([6, 6, 6] + [1] * (len(keys) - 3), float)
                k = keys[rng.choice(len(keys), p=w / w.sum())]
            t = vs[k]
        elif s in setmap:
            sname, upc = setmap[s]
            i = sum((1 << b) for b, v in enumerate(c) if v == upc)
            if i in T.ALT_IDS and rng.random() < 0.5:
                t = trans[sname][('alt', i)]
            else:
                t = trans[sname][i]
        else:
            t = np.zeros((N, N, 3), np.uint8); t[:] = (255, 0, 255); errors += 1
        mapimg[cy * N:(cy + 1) * N, cx * N:(cx + 1) * N] = t
print('Map-Zellen ohne passendes Übergangstile:', errors)
save(mapimg, os.path.join(OUT, 'vorschau', 'vorschau_map_1x.png'))
save(mapimg, os.path.join(OUT, 'vorschau', 'vorschau_map_2x.png'), 2)
# Ingame-Ausschnitt: 640x360-Viewport (CLAUDE.md), 3x skaliert
crop = mapimg[64:64 + 360, 160:160 + 640]
save(crop, os.path.join(OUT, 'vorschau', 'vorschau_viewport_640x360_3x.png'), 3)

# ------------------------------------------------ Übersichtsblätter
def sheet(rows, labels, scale, path, title):
    pad, lab_w = 8, 110
    h = sum(r.shape[0] * scale + pad for r in rows) + pad + 24
    w = max(r.shape[1] * scale for r in rows) + lab_w + 2 * pad
    im = Image.new('RGB', (w, h), (14, 10, 20))
    d = ImageDraw.Draw(im)
    d.text((pad, 6), title, fill=(234, 223, 203))
    y = 24 + pad
    for r, l in zip(rows, labels):
        d.text((pad, y + 4), l, fill=(217, 164, 65))
        im.paste(Image.fromarray(r).resize((r.shape[1] * scale, r.shape[0] * scale), Image.NEAREST), (lab_w, y))
        y += r.shape[0] * scale + pad
    im.save(path)


def spaced(tl):
    gap = np.zeros((N, 4, 3), np.uint8); gap[:] = (14, 10, 20)
    out = []
    for t in tl:
        out += [t, gap]
    return np.concatenate(out[:-1], 1)


rows = [spaced([vs[k] for k in sorted(vs)]) for vs in mats.values()]
sheet(rows, [f'{n} 1-{len(vs)}' for n, vs in mats.items()], 5,
      os.path.join(OUT, 'vorschau', 'uebersicht_fuelltiles.png'),
      'Fuelltiles - Spalten 1-3 ersetzen deine Originale, ab Spalte 4 neu')
trows, tl = [], []
for n, ts in trans.items():
    a = T.atlas(ts)
    trows.append(a); tl.append(n)
gap = np.zeros((5 * N, 12, 3), np.uint8); gap[:] = (14, 10, 20)
sheet([np.concatenate([trows[0], gap, trows[1], gap, trows[2]], 1)], ['Uebergaenge'], 3,
      os.path.join(OUT, 'vorschau', 'uebersicht_uebergaenge.png'),
      'gras_erde | gras_weg | pflaster_weg  - Index = TL*1+TR*2+BL*4+BR*8, Zeile 5 = Alternativen fuer 3,5,10,12')

# Corner-Schlüssel-Grafik
key = Image.new('RGB', (4 * 70 + 10, 5 * 70 + 10), (14, 10, 20))
d = ImageDraw.Draw(key)
for i in range(16):
    r, c = divmod(i, 4)
    x0, y0 = 10 + c * 70, 10 + r * 70
    d.rectangle([x0, y0, x0 + 60, y0 + 60], outline=(120, 110, 130))
    for b, (dx, dy) in enumerate([(0, 0), (1, 0), (0, 1), (1, 1)]):
        col = (63, 125, 90) if (i >> b) & 1 else (90, 68, 56)
        d.rectangle([x0 + 4 + dx * 34, y0 + 4 + dy * 34, x0 + 22 + dx * 34, y0 + 22 + dy * 34], fill=col)
    d.text((x0 + 24, y0 + 24), str(i), fill=(234, 223, 203))
for c, i in enumerate(T.ALT_IDS):
    x0, y0 = 10 + c * 70, 10 + 4 * 70
    d.rectangle([x0, y0, x0 + 60, y0 + 60], outline=(194, 48, 122))
    for b, (dx, dy) in enumerate([(0, 0), (1, 0), (0, 1), (1, 1)]):
        col = (63, 125, 90) if (i >> b) & 1 else (90, 68, 56)
        d.rectangle([x0 + 4 + dx * 34, y0 + 4 + dy * 34, x0 + 22 + dx * 34, y0 + 22 + dy * 34], fill=col)
    d.text((x0 + 18, y0 + 24), f'alt {i}', fill=(234, 223, 203))
key.save(os.path.join(OUT, 'boden_tiles', 'uebergaenge', 'corner_schluessel.png'))

# ------------------------------------------------ Vorher / Nachher
SRC = sys.argv[2]
rows, labels = [], []
for n in mats:
    old = [np.array(Image.open(os.path.join(SRC, f'boden_{n}_{k}.png')).convert('RGB')) for k in (1, 2, 3)]
    gap = np.zeros((N, 12, 3), np.uint8); gap[:] = (14, 10, 20)
    rows.append(np.concatenate([spaced(old), gap, spaced([mats[n][k] for k in (1, 2, 3)])], 1))
    labels.append(n)
sheet(rows, labels, 5, os.path.join(OUT, 'vorschau', 'vergleich_vorher_nachher.png'),
      'links: Original 1-3   |   rechts: ueberarbeitet 1-3 (gleiche Dateinamen)')
