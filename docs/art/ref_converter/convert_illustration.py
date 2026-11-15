"""Große Abbildung aus einer KI-Vorlage, 1:1 im Raster der Vorlage (ohne Verkleinern).

Für Bilder, die größer im Spiel stehen dürfen als ein Sprite, z. B. die Digitalis-Formen
im Grimoire. Die Vorlage wird auf ihr eigenes Pixelraster zurückgerechnet (wie
convert_ref.py, Schritte 1-2), zugeschnitten und auf wenige Farben reduziert. Die Farben
bleiben die der Vorlage: Einrasten auf hexen_palette.gpl zog das Magenta der Glocken
nach Violett.

Aufruf:
  python docs/art/ref_converter/convert_illustration.py <vorlage.png> <ausgabe.png> [--raster 8.11] [--farben 32]
  --raster: Größe eines Vorlagen-Pixels, wenn die Messung ein Teilraster erwischt
            (Digitalis-Sichel: gemessen 4.05, richtig 8.11)
"""
import argparse
import numpy as np
from PIL import Image

import convert_ref as cr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vorlage")
    ap.add_argument("ausgabe")
    ap.add_argument("--raster", type=float)
    ap.add_argument("--farben", type=int, default=32)
    a = ap.parse_args()

    src = np.array(Image.open(a.vorlage).convert("RGBA")).astype(int)
    rgb, alpha = src[:, :, :3].astype(float), src[:, :, 3]
    px, ox = cr.measure(rgb, alpha, 1, a.raster)
    py, oy = cr.measure(rgb, alpha, 0, a.raster)
    print(f"Raster: {px:.3f} x {py:.3f}")
    nat = cr.to_native(src, px, ox, py, oy)
    ys, xs = np.where(nat[:, :, 3] > 0)
    nat = nat[ys.min():ys.max() + 1, xs.min():xs.max() + 1]

    # Farben reduzieren (Octree hält das Gold kräftiger als Median Cut),
    # Transparenz bleibt hart (nur 0 oder 255).
    rgb_img = Image.fromarray(nat[:, :, :3].astype(np.uint8))
    reduced = np.array(rgb_img.quantize(colors=a.farben, method=Image.Quantize.FASTOCTREE).convert("RGB"))
    out = np.dstack([reduced, np.where(nat[:, :, 3] > 0, 255, 0)]).astype(np.uint8)
    Image.fromarray(out).save(a.ausgabe)
    print(f"gespeichert: {a.ausgabe} ({out.shape[1]}x{out.shape[0]})")


if __name__ == "__main__":
    main()
