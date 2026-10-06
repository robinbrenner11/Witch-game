"""Testkarte für die neuen Sets: je Paar ein kleines Feld, plus Beetreihen mit Endstücken."""
import sys, os
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from core import N
import materials as M
import transitions as T
import extra as X

X.OUT = sys.argv[1]
tiles, trans = X.main()
fills = {'G': M.make_grass(), 'E': M.make_soil('erde'), 'W': M.make_soil('weg'),
         'P': M.make_pflaster(), 'S': M.make_platte(), 'F': X.make_graveyard()}
pairs = {frozenset('EW'): ('soil_path', 'E'), frozenset('GP'): ('cobble_grass', 'P'),
         frozenset('FW'): ('graveyard_path', 'F'), frozenset('SG'): ('slab_grass', 'S'),
         frozenset('SW'): ('slab_path', 'S'), frozenset('SF'): ('slab_graveyard', 'S')}
rng = np.random.default_rng(3)


def render(V):
    H_, W_ = V.shape[0] - 1, V.shape[1] - 1
    img = np.zeros((H_ * N, W_ * N, 3), np.uint8)
    for cy in range(H_):
        for cx in range(W_):
            c = [V[cy, cx], V[cy, cx + 1], V[cy + 1, cx], V[cy + 1, cx + 1]]
            s = frozenset(c)
            if len(s) == 1:
                vs = fills[c[0]]; keys = sorted(vs)
                w = np.array([6, 6, 6] + [1] * (len(keys) - 3), float)
                t = vs[keys[rng.choice(len(keys), p=w / w.sum())]]
            else:
                n, up = pairs[s]
                i = sum(1 << b for b, v in enumerate(c) if v == up)
                t = trans[n][('alt', i)] if i in T.ALT_IDS and rng.random() < .5 else trans[n][i]
            img[cy * N:(cy + 1) * N, cx * N:(cx + 1) * N] = t
    return img


def field(w, h, base, rects):
    V = np.full((h + 1, w + 1), base)
    for ch, x0, y0, x1, y1 in rects:
        V[y0:y1 + 1, x0:x1 + 1] = ch
    return V


maps = [
    field(10, 7, 'W', [('E', 1, 1, 3, 5), ('F', 5, 1, 9, 6), ('S', 7, 3, 8, 4)]),
    field(10, 7, 'G', [('P', 1, 1, 3, 4), ('S', 5, 2, 8, 5)]),
    field(10, 7, 'W', [('S', 2, 2, 6, 4)]),
]
imgs = [render(V) for V in maps]
# Beetreihen mit Endstücken auf Erde
soil = fills['E']; beet = M.make_beet()
bed = np.zeros((4 * N, 10 * N, 3), np.uint8)
for r in range(4):
    for c in range(10):
        bed[r * N:(r + 1) * N, c * N:(c + 1) * N] = soil[1 + (r + c) % 3]
wet = lambda r: 'wet' if r >= 2 else 'dry'
for r in (0, 1, 2):
    row = [('left',)] + [(None, 1 + c % 3) for c in range(4)] + [('right',)]
    for c, t in enumerate(row):
        if t[0] is None:
            a = beet[t[1] + (3 if r == 2 else 0)]
        else:
            a = tiles[f'ground_bed_cap_{t[0]}_{wet(r)}']
        bed[r * N:(r + 1) * N, (c + 1) * N:(c + 2) * N] = a
bed[3 * N:4 * N, 8 * N:9 * N] = tiles['ground_bed_cap_single_dry']
gap = np.full((8, 10 * N, 3), (14, 10, 20), np.uint8)
full = np.concatenate([imgs[0], gap, imgs[1], gap, imgs[2], gap, bed], 0)
Image.fromarray(full).resize((full.shape[1] * 2, full.shape[0] * 2), Image.NEAREST).save(
    os.path.join(sys.argv[1], 'vorschau_neue_boeden_2x.png'))
