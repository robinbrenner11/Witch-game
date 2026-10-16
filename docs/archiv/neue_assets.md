# Neue Grafiken vom 07.10.2026

Alle Grafiken entstehen aus Python-Generatoren (Pillow) und lassen sich dort
anpassen. Gemeinsame Stilregeln: harte Pixel, kein Anti-Aliasing, Licht oben
links, Aubergine-Outlines, gelockerte Palette (siehe `neue_farben.md`).

## Tränke – `assets/items/`

Generator: `docs/art/item_generators/potions.py` · Vorschau: `vorschau/vorschau_traenke_8x.png`

| Datei | Größe | Form |
|---|---|---|
| `potion_will_o_wisp.png` | 16×16 | kleines Tropfen-Fläschchen, Geisterblau/Flieder, heller Kern, zwei Funken schweben heraus |
| `potion_moon_harvest.png` | 16×16 | breite, bauchige Flasche, grün, goldene Mondsichel |
| `potion_liquid_moonlight.png` | 16×16 | schlanke, hohe Phiole, hell schimmernd, goldener Stopfen und Fuß |
| `potion_endless_night.png` | 16×16 | kantige Rautenflasche, Nachthimmel mit Sternen, Bordeaux-Siegel |

Alle fünf Trank-Silhouetten (inkl. Wachstumstrank, Hexenschlamm) sind verschieden, damit man sie in der Hotbar auseinanderhält.

## Bett – `assets/environment/props/`

Generator: `docs/art/world_generator/bed.py` · Vorschau: `vorschau/vorschau_bett_4x.png`

| Datei | Größe | Hinweis |
|---|---|---|
| `bed.png` | 32×64 (1×2 Tiles) | leeres Bett, Kopfteil oben, Fußteil unten; Kollision über beide Tiles |
| `bed_sleeping.png` | 32×64 | Hexe schläft, Decke bis über die Nase; während des Schlafens statt `bed.png` zeigen |

## Brau-Fenster – `assets/ui/`

Generator: `docs/art/ui_generator/brew_window.py` · Vorschau: `vorschau/vorschau_braufenster_v2_2x.png`, `vorschau/vorschau_braufenster_teile_6x.png`

**In 1× gespeichert**, im Spiel doppelt so groß anzeigen (Fenster-Root `scale = 2`). Fenstergröße im Mockup: 190×168 (1×).

| Datei | Größe | Hinweis |
|---|---|---|
| `brew_panel.png` | 15×15 | Fensterrahmen, **9-Slice, Ränder je 6 px**; Grund ist leicht transparent |
| `brew_slot.png` | 20×20 | Zutaten-Feld, leer mit schwachem Runenkreis; Icon 16×16 bei (2, 2) |
| `brew_slot_result.png` | 24×24 | Ergebnis-Feld mit Goldrahmen; Icon 16×16 bei (4, 4) |
| `brew_arrow.png` | 18×9 | Pfeil inaktiv (Gold) |
| `brew_arrow_active.png` | 18×9 | Pfeil aktiv (Magenta, funkelt) |
| `brew_button.png` | 16×12 | Knopf, **9-Slice, Ränder je 4 px**; im Mockup auf 46×16 gestreckt |
| `brew_button_pressed.png` | 16×12 | Knopf gedrückt |
| `brew_button_disabled.png` | 16×12 | Knopf inaktiv (< 2 Zutaten) |
| `brew_unknown.png` | 16×16 | "?" für unbekannte Rezepte |
| `brew_pip.png` | 5×5 | Kapazitäts-Raute belegt (Gold) |
| `brew_pip_empty.png` | 5×5 | Kapazitäts-Raute frei (Umriss) |
| `brew_cauldron.png` | 56×36 | Kessel im Fenster, grüner Sud |
| `brew_cauldron_ready.png` | 56×36 | Kessel im Fenster, Sud glüht magenta (brau-bereit) |

Inventar-Plätze im Fenster: bestehende `hotbar_slot.png` (2× vorskaliert) auf 20×20 anzeigen.

## Nachtschatten – `assets/effects/` und `assets/ui/`

Generator: `docs/art/plant_generators/nightshade_aura.py` · Vorschauen: `vorschau/vorschau_nachtschatten_kuppel_3x.gif`, `vorschau/vorschau_kuppeln_verschmolzen_3x.gif`, `vorschau/vorschau_debuff_8x.png`

| Datei | Größe | Hinweis |
|---|---|---|
| `effects/nightshade_dome.png` | 4 Frames à 120×120 (480×120) | Kuppel über dem 3×3-Bereich, **über** den Pflanzen; Wurzelpunkt des Nachtschattens bei (60, 69) im Frame; Abspielen 0-1-2-1 (Frame 0 länger). Referenz/Fallback – im Spiel als Shader, damit mehrere Kuppeln verschmelzen |
| `ui/debuff_nightshade.png` | 16×16 | Debuff-Icon (kleine Kuppel mit verwelkter Blüte), für später |

Welken der Pflanzen unter der Kuppel: keine eigene Grafik, per `modulate` / kleinem Shader (entsättigt, kühl-dunkel).
