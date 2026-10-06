# Asset-Übersicht (für Claude Code)

Alle Grafiken sind auf Palette und 32er-Raster geprüft, harte Pixelkanten, keine Skalierung nötig.
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

## Referenzen – `docs/art/`

- `styleguide.pdf`, `hexen_palette.gpl` (Palette für Aseprite/GIMP, inkl. der 7 abgeleiteten Töne für die Pflanzen: Indigo, Indigo hell, Flieder, Giftgrün dunkel/hell, Nachtblau hell, Geisterblau)
- `plant_generators/`: Python-Scripts für Pflanzen, Icons (`icons.py`) und Licht (`lights.py`)
- `ground_generator/extra.py`: Erweiterung für Friedhofsgras, Beet-Endstücke und die neuen Übergänge (+ `extra_preview.py`, `pruefbericht_extra.txt`)
- `vorschau/vorschau_neue_boeden_2x.png`, `vorschau_items_4x.png`, `vorschau_nacht_3x.png`
- `vorschau/uebersicht_pflanzen.png`: alle Pflanzen in 1× und 3×
- `referenz/witch_concept.webp`: Designvorlage der Hexe
- `referenz/witch_base_32x64.png`: Rohfassung (Basis des Pixeleditors)
- `vorschau/`: Testkarten und Lauf-GIF
- `ground_generator/`: Python-Script, mit dem die Bodentiles erzeugt wurden (nur zum Nachjustieren)
