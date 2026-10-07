# Asset-Übersicht (für Claude Code)

Alle Grafiken sind auf Palette und 32er-Raster geprüft, harte Pixelkanten, keine Skalierung nötig. Seit 07.10.2026 ist die Palette gelockert: Zwischentöne sind erlaubt und stehen alle in `docs/art/hexen_palette.gpl`.
`docs/` enthält eine `.gdignore` und wird deshalb von Godot nicht importiert. Dort liegen nur Referenzen und Vorschauen.

## Hexe – `assets/characters/`

| Datei | Größe | Inhalt |
|---|---|---|
| `witch_walk_down.png` | 256×64 | 8 Frames à 32×64, Laufen nach unten |
| `witch_walk_up.png` | 256×64 | 8 Frames à 32×64, Laufen nach oben (Rückansicht) |
| `witch_walk_side.png` | 256×64 | 8 Frames à 32×64, Laufen nach **rechts**; links = `flip_h = true` |
| `witch_idle.png` | 96×64 | 3 Frames: 0 = unten, 1 = oben, 2 = Seite (rechts) |
| `witch_sprite_frames.tres` | – | fertige SpriteFrames (Pfade zeigen schon auf `res://assets/characters/`) |

- Animationen: `idle_down`, `idle_up`, `idle_side` (5 FPS), `walk_down`, `walk_up`, `walk_side` (8 FPS, Loop).
- Frame-Reihenfolge Walk: 0 Contact A · 1 Down · 2 Passing · 3 Up · 4 Contact B · 5 Down · 6 Passing · 7 Up.
- Füße stehen in jedem Frame auf der untersten Pixelzeile (y = 63), mittig (x = 16).
- **AnimatedSprite2D:** `centered = true`, `offset = Vector2(0, -32)`. Damit liegen die Füße auf dem Ursprung des Player-Nodes.
- **Kollision nur an den Füßen:** RectangleShape2D 16×8 bei `position = Vector2(0, -4)` statt des bisherigen 32×32-Quadrats. Das ist die Voraussetzung für Y-Sort (Hexe kann vor/hinter Objekten stehen).
- Das Wippen beim Laufen ist im Bild enthalten, also nicht per Code bewegen.
- Ersetzt `witch_placeholder.png`.

## Boden – `assets/environment/ground/`

32×32 Fülltiles, voll deckend (kein Alpha nötig).

| Material | Dateien | Verwendung |
|---|---|---|
| `grass` | 1–3 Basis, 4 helle Blüten, 5 Glimmerpilz, 6 Magenta-Blüten | Garten, Wiese |
| `soil` | 1–3 Basis, 4 Wurzel, 5 Pilzgruppe | offene Erde |
| `path` | 1–3 Basis, 4 Laub, 5 Kiesel/Mulde | Trampelpfad |
| `bed` | 1–3 **trocken**, 4–6 **gegossen** (je gleiches Muster) | Beet; eine Pflanzposition mittig pro Tile |
| `cobble` | 1–3 Basis, 4 Moos, 5 Riss/Kerzenwachs | Dorf |
| `slab` | 1–3 Basis, 4 Moos/Farn, 5 Magenta-Rune | Hexenhaus, Friedhof |
| `graveyard` | 1–3 Basis, 4 fahle Blüten, 5 bleicher Pilz, 6 Magenta-Blüten | Friedhof: Gras in kühlem Nachtblau |
| `bed_cap_*` | `left`/`right`/`single`, jeweils `_dry` und `_wet` | Beet-Endstücke: Damm endet abgerundet in der Erde |

- Alle Varianten eines Materials haben denselben 2px-Rand und passen daher beliebig nebeneinander.
- Mischung beim Malen: Basis 1–3 gleich oft, Deko-Varianten zusammen höchstens 10–15 %.
- Für den TileSet ist `ground_atlas.png` gedacht (6 Spalten × 8 Zeilen; Zeile 6 = graveyard, Zeile 7 = Beet-Endstücke). Welches Tile wo liegt, steht in `ground_atlas_layout.json` (Spalte, Zeile). Die Zeilen 0–5 sind unverändert.
- `bed_1–3` ↔ `bed_4–6`: trocken/nass entspricht später dem Gieß-Zustand. Bei `bed_1` gehört also `bed_4` als nasse Version dazu usw.
- **Beet-Reihe legen:** `bed_cap_left` · `bed_1..3` … · `bed_cap_right`. Ein einzelnes Beet-Tile ist `bed_cap_single`. Die Endstücke schließen außen nahtlos an `soil` an. Die Pflanzposition bleibt mittig wie bei `bed` (das Endstück selbst ist bepflanzbar).

### Übergänge – `transitions/`

Jeweils 4×5 Tiles (128×160), erstes Material im Namen = „oberes“ Material:

| Datei | Art |
|---|---|
| `transition_grass_soil.png` | Gras-Matte über Erde, mit Halmen |
| `transition_grass_path.png` | Gras-Matte über Weg |
| `transition_soil_path.png` | lockere Erde über festgetretenem Weg |
| `transition_graveyard_path.png` | Friedhofsgras über Weg |
| `transition_cobble_path.png` | Pflaster endet steinweise im Weg |
| `transition_cobble_grass.png` | Pflaster endet steinweise im Gras |
| `transition_slab_grass.png` | Platten mit Kantensteinen im Gras |
| `transition_slab_path.png` | Platten mit Kantensteinen im Weg |
| `transition_slab_graveyard.png` | Platten mit Kantensteinen im Friedhofsgras (Grabplatten, Wege) |

Die Platten-Sets haben bewusst gerade Kanten (jede Ecke = ein 16×16-Viertel) mit 2px-Kantenstein. Platten sind gebaut, nicht gewachsen. Dadurch lassen sich auch freistehende Plattenflächen, Terrassen und Grabplatten legen.

- Godot TileSet → Terrain Set, Modus **Match Corners**, zwei Terrains pro Atlas (oberes Material = erstes im Namen).
- Tile-Index = `TL·1 + TR·2 + BL·4 + BR·8`. Ein gesetztes Bit heißt, dass die Ecke zum ersten Material gehört (grass bzw. cobble). Das Tile in Zeile r, Spalte c hat den Index r·4+c.
- Zeile 5 enthält Alternativen für gerade Kanten (Index 3, 5, 10, 12): gleiche Ecken eintragen, dann variiert Godot zufällig.
- Grafische Hilfe: `docs/art/referenz/transition_corner_key.png`.

### Grenzen

- Wo **drei** Materialien an einer Ecke zusammentreffen, gibt es kein Tile. Immer einen Streifen eines Materials dazwischen lassen. Das ist bei Corner-Terrains normal.
- Paare ohne eigenes Set (z. B. soil↔cobble, graveyard↔grass) über einen Weg- oder Grasstreifen verbinden.
- Leuchtakzente im Boden (Pilze, Rune) sind nur Farbe. Echtes Licht siehe unten.

## Inventar-Icons – `assets/items/`

16×16, transparenter Hintergrund, Aubergine-Kontur. Für die UI ganzzahlig skalieren (2× oder 3×).

| Datei | Inhalt |
|---|---|
| `seed_<pflanze>.png` | Samentütchen mit Etikett (Pflanzen-Emblem auf dunklem Feld, Goldrahmen) |
| `crop_<pflanze>.png` | Ernte-Item (Mondkelch-Blüte, Laternenbeeren, Alraune, Nachtschatten-Traube, Blutrose, Farnwedel) |
| `items_plants_atlas.png` | alle 12 als Atlas 96×32: Zeile 0 Samen, Zeile 1 Ernte, Spalten in der Reihenfolge moon_chalice, lantern_berry, mandrake, nightshade, blood_rose, ghost_fern |

`<pflanze>` ist derselbe Name wie bei `assets/plants/<pflanze>_stages.png`. Damit lassen sich Samen, Pflanze und Ernte über einen gemeinsamen Schlüssel verbinden (z. B. `plant_id = "mandrake"`).

## Licht – `assets/effects/lights/`

Weiße Texturen mit Alpha in harten Stufen (pixeliger Lichtkegel statt weichem Verlauf). Die **Farbe kommt über `PointLight2D.color`**, so reicht eine Textur für alle Lichter.

| Datei | Verwendung |
|---|---|
| `light_round_32.png` | kleine Lichter (Alraunen-Augen, Kerze) |
| `light_round_64.png` | Pflanzen (Mondkelch, Geisterfarn), Laterne |
| `light_round_128.png` | große warme Quellen (Laternenbeere, Kessel, Fenster) |
| `light_glimmer_16.png` | winziges Glimmen (Funken, Rune) |

Empfohlene Werte (aus der Vorschau `docs/art/vorschau/vorschau_nacht_3x.png`):
- Nacht: `CanvasModulate.color = Color("#665C8F")` (≈ 0.40/0.36/0.56)
- Mondkelch: Farbe `#A99BE0`, Energie 1.6, Textur 64
- Laternenbeere: Farbe `#FFB566`, Energie 1.5, Textur 128
- Alraune (Augen): Farbe `#E458B1`, Energie 1.4, Textur 32
- Geisterfarn: Farbe `#788CB9`, Energie 1.2, Textur 64
- Lichter nur im Reif-Stadium einschalten. So wird das Reifwerden zur sichtbaren Belohnung.
- Texture Filter der Lichter ebenfalls **Nearest**, sonst verwischen die Stufen.

## Pflanzen – `assets/plants/`

Jede Pflanze ist ein Spritesheet **128×48**: 4 Frames à 32×48 nebeneinander, transparenter Hintergrund.
Frame 0 = Samen, 1 = Keimling, 2 = wachsend, 3 = erntereif.

| Datei | Name | Silhouette | Reif-Stadium |
|---|---|---|---|
| `moon_chalice_stages.png` | Mondkelch | aufrecht, Kelchblüte oben | leuchtende Blüte + Funken |
| `lantern_berry_stages.png` | Laternenbeere | Hirtenstab-Bogen nach rechts | 3 warm glühende Beeren |
| `mandrake_stages.png` | Alraune | flache Rosette | Kopf mit glühenden Augen lugt hervor |
| `nightshade_stages.png` | Nachtschatten | runder Busch | Beerentrauben (Stufe 2: Blüten) |
| `blood_rose_stages.png` | Blutrose | schmale, hohe Ranke | große offene Rose, goldene Tropfen an Dornen |
| `ghost_fern_stages.png` | Geisterfarn | breiter Fächer | entrollte Wedel, schimmernde Spitzen |

**Ausrichtung:** Das untere 32×32 jedes Frames deckt sich mit dem Beet-Tile. Die Pflanze wurzelt bei x 15/16, y 37 im Frame, also etwas unter der Tile-Mitte. Darüber darf sie 16 px über das Tile hinauswachsen.

**In Godot:** `Sprite2D` mit `hframes = 4`, `frame = growth_stage`, `centered = true`, `offset = Vector2(0, -8)`.
Dann liegt die Node-Position genau auf der **Mitte des Beet-Tiles**. Für spätere Y-Sortierung kann der Ursprung stattdessen an den Wurzelpunkt: Node bei Tile-Mitte + (0, 5), `offset = Vector2(0, -13)`.

**Leuchten:** Es ist nur angedeutet (helle Pixel und Funken). Für den Mondkelch, die Laternenbeere (warm), die Alraunen-Augen und den Geisterfarn lohnt sich im Reif-Stadium ein kleines `PointLight2D`.

## Tränke – `assets/items/` (07.10.2026)

16×16 wie `potion_growth.png`. Generator: `docs/art/item_generators/potions.py` · Vorschau: `vorschau/vorschau_traenke_8x.png`.
Jeder Trank hat eine eigene Flaschensilhouette, damit man sie in der Hotbar auseinanderhält.

| Datei | Trank | Form |
|---|---|---|
| `potion_will_o_wisp.png` | Irrlicht | kleines Tropfen-Fläschchen, Geisterblau/Flieder, heller Kern, zwei Funken schweben heraus |
| `potion_moon_harvest.png` | Mondernte | breite, bauchige Flasche, grün, goldene Mondsichel |
| `potion_liquid_moonlight.png` | Flüssiges Mondlicht | schlanke, hohe Phiole, hell schimmernd, goldener Stopfen und Fuß |
| `potion_endless_night.png` | Ewige Nacht | kantige Rautenflasche, Nachthimmel mit Sternen, Bordeaux-Siegel |

## Bett – `assets/environment/props/` (07.10.2026)

Generator: `docs/art/world_generator/bed.py` · Vorschau: `vorschau/vorschau_bett_4x.png`

| Datei | Größe | Hinweis |
|---|---|---|
| `bed.png` | 32×64 (1×2 Tiles) | leeres Bett, Kopfteil oben, Fußteil unten; Kollision über beide Tiles |
| `bed_sleeping.png` | 32×64 | Hexe schläft, Decke bis über die Nase; während des Schlafens statt `bed.png` zeigen |

## Brau-Fenster – `assets/ui/brew_*` (07.10.2026)

Generator: `docs/art/ui_generator/brew_window.py` (Positionen in `window_v2`, Feld-Bogen in `slot_positions`) · Vorschau: `vorschau/vorschau_braufenster_v2_2x.png` (vier Zustände), `vorschau/vorschau_braufenster_teile_6x.png`

**In 1× gespeichert**, im Spiel doppelt so groß anzeigen (Fenster-Root `scale = 2`). Fenstergröße im Mockup: 190×168 (1×).
Inventar-Plätze im Fenster: bestehende `hotbar_slot.png` (2× vorskaliert) auf 20×20 anzeigen.

| Datei | Größe | Hinweis |
|---|---|---|
| `brew_panel.png` | 15×15 | Fensterrahmen, **9-Slice, Ränder je 6 px**; Grund leicht transparent |
| `brew_slot.png` | 20×20 | Zutaten-Feld, leer mit schwachem Runenkreis; Icon 16×16 bei (2, 2) |
| `brew_slot_result.png` | 24×24 | Ergebnis-Feld mit Goldrahmen; Icon 16×16 bei (4, 4) |
| `brew_arrow.png` / `brew_arrow_active.png` | 18×9 | Pfeil inaktiv (Gold) / aktiv (Magenta, funkelt) |
| `brew_button.png` | 16×12 | Knopf, **9-Slice, Ränder je 4 px**; im Mockup auf 46×16 gestreckt |
| `brew_button_pressed.png` / `brew_button_disabled.png` | 16×12 | gedrückt / inaktiv (< 2 Zutaten) |
| `brew_unknown.png` | 16×16 | „?“ für unbekannte Rezepte |
| `brew_pip.png` / `brew_pip_empty.png` | 5×5 | Kapazitäts-Raute belegt (Gold) / frei (Umriss) |
| `brew_cauldron.png` / `brew_cauldron_ready.png` | 56×36 | Kessel im Fenster: grüner Sud / Sud glüht magenta (brau-bereit) |

## Nachtschatten-Kuppel – `assets/effects/` und `assets/ui/` (07.10.2026)

Generator: `docs/art/plant_generators/nightshade_aura.py` (Funktionen `field`, `smin`, `render_domes` = Vorlage für den Shader) · Vorschauen: `vorschau/vorschau_nachtschatten_kuppel_3x.gif`, `vorschau/vorschau_kuppeln_verschmolzen_3x.gif`, `vorschau/vorschau_debuff_8x.png`

| Datei | Größe | Hinweis |
|---|---|---|
| `effects/nightshade_dome.png` | 480×120 (4 Frames à 120×120) | Kuppel über dem 3×3-Bereich, **über** den Pflanzen; Wurzelpunkt des Nachtschattens bei (60, 69) im Frame; Abspielen 0-1-2-1 (Frame 0 länger). Referenz/Fallback, im Spiel als Shader, damit mehrere Kuppeln verschmelzen |
| `ui/debuff_nightshade.png` | 16×16 | Debuff-Icon (kleine Kuppel mit verwelkter Blüte), für später |

Welken der Pflanzen unter der Kuppel: keine eigene Grafik, sondern per `modulate` bzw. kleinem Shader (entsättigt, kühl-dunkel).

## Referenzen – `docs/art/`

- `styleguide.pdf`, `hexen_palette.gpl` (Palette für Aseprite/GIMP, inkl. der 7 abgeleiteten Töne für die Pflanzen: Indigo, Indigo hell, Flieder, Giftgrün dunkel/hell, Nachtblau hell, Geisterblau, sowie der 27 Zwischentöne vom 07.10.2026, siehe `neue_farben.md`)
- `plant_generators/`: Python-Scripts für Pflanzen, Icons (`icons.py`) und Licht (`lights.py`)
- `item_generators/potions.py`, `world_generator/bed.py`, `ui_generator/brew_window.py`, `plant_generators/nightshade_aura.py`: Generatoren der Grafiken vom 07.10.2026 (Details: `neue_assets.md`)
- `ground_generator/extra.py`: Erweiterung für Friedhofsgras, Beet-Endstücke und die neuen Übergänge (+ `extra_preview.py`, `pruefbericht_extra.txt`)
- `vorschau/vorschau_neue_boeden_2x.png`, `vorschau_items_4x.png`, `vorschau_nacht_3x.png`
- `vorschau/uebersicht_pflanzen.png`: alle Pflanzen in 1× und 3×
- `referenz/witch_concept.webp`: Designvorlage der Hexe
- `referenz/witch_base_32x64.png`: Rohfassung (Basis des Pixeleditors)
- `vorschau/`: Testkarten und Lauf-GIF
- `ground_generator/`: Python-Script, mit dem die Bodentiles erzeugt wurden (nur zum Nachjustieren)
