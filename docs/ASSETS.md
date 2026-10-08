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

### Aktionen der Hexe (07.10.2026)

Generator: `docs/art/character_generator/witch_actions.py` · Vorschauen: `vorschau/vorschau_<aktion>_4x.gif` (alle drei Richtungen nebeneinander), `vorschau/vergleich_<aktion>_4x.png` (Idle links, danach alle Frames)

Jede Aktion gibt es als `_down`, `_up` und `_side` (Blick nach **rechts**, links = `flip_h = true`). Alle Frames sind 32×64 groß und liegen waagerecht nebeneinander. Gleiches Setup wie Walk (`centered = true`, `offset = Vector2(0, -32)`). Der Unterkörper ab y = 56 ist pixelgleich mit Idle, die Füße stehen also exakt wie bei Idle und Walk.

| Datei | Größe | Frames | FPS | Abspielen | Ablauf |
|---|---|---|---|---|---|
| `witch_pour_<r>.png` | 160×64 | 5 | 8 | einmal | Zauber-Ausgießen: 1 Hand heben · 2 Finger spreizen, Funken · 3 Stoß (**Orb startet**) · 4 Funken verglühen · 5 Arm sinkt. Keine Flasche, der Trank kommt als Orb-Effekt (siehe Effekte) |
| `witch_harvest_<r>.png` | 128×64 | 4 | 8 | einmal | 1 bücken und greifen · 2 tiefer, Griff · 3 herausziehen · 4 aufrecht, Hand offen vor dem Körper. Leere Hand, das Item legt das Spiel nicht hinein |
| `witch_drink_<r>.png` | 160×64 | 5 | 7 | einmal | 1 Fläschchen vor der Brust · 2 an den Mund · 3 Kopf leicht zurück · 4 absetzen · 5 Hand sinkt. Bei `_up` nur Rücken und gehobener Ellbogen |
| `witch_snap_<r>.png` | 128×64 | 4 | 10 | einmal | 1 Hand heben · 2 Schnipp mit Magenta-Funken · 3 Funken verglühen · 4 Hand senken. Für „Erde wecken“ (Beet anlegen) und später Zauber |

- Animationsnamen in den SpriteFrames: `pour_down`, `pour_up`, `pour_side` usw., jeweils **ohne Loop**. Nach `animation_finished` zurück auf `idle_<r>`.
- **Orb-Startpunkt** (Fingerspitzen in Frame 3 von `pour`), als Offset zur Player-Position: unten `(10, -33)`, oben `(10, -44)`, rechts `(12, -37)`, links `(-13, -37)`.
- Die schwarzen Finger tragen einen goldenen Armreif, damit die Hand vor dem dunklen Haar und Kleid lesbar bleibt.
- Kontur: Der Körper bleibt in Tiefschwarz wie bei Idle und Walk, neue Teile (Ärmel, Hand, Fläschchen) haben eine Aubergine-Kontur (Entscheidung vom 07.10.).

### Effekt Zauber-Ausgießen – `assets/effects/` (07.10.2026)

Generator: `docs/art/character_generator/pour_effect.py` · Vorschauen: `vorschau/vorschau_pour_szene_4x.gif` (Gesamtablauf, Trank grün eingefärbt), `vorschau/vorschau_pour_effekt_4x.gif` (weiß / eingefärbt)

| Datei | Größe | Frames | Hinweis |
|---|---|---|---|
| `pour_orb.png` | 16×8 | 2 à 8×8 | Tropfen-Orb, wabbelt (Frames im Wechsel). **Einfärbbar** per `modulate` in der Trankfarbe. Fliegt per Tween im Bogen vom Orb-Startpunkt zur Pflanze, ca. 0,3 s |
| `pour_rain.png` | 192×48 | 6 à 32×48 | Orb platzt über der Pflanze, fächert auf, regnet aufs Beet, kleine Spritzer. **Einfärbbar**. 10 FPS, einmal |
| `pour_sparks.png` | 192×48 | 6 à 32×48 | Magenta-Funken, gleiches Timing wie `pour_rain`, als zweite Ebene darüber. **Nicht** einfärben |

- `pour_rain` und `pour_sparks` haben dasselbe Format wie die Pflanzen (unten bündig mit dem Beet-Tile). Gleich positionieren wie eine Pflanze: Tile-Mitte, `centered = true`, `offset = Vector2(0, -8)`. Der Platzpunkt liegt bei (16, 6) im Frame, dort landet der Orb.
- Ersetzt den ursprünglich geplanten `pour_stream.png` (Entscheidung vom 07.10.: zaubern statt gießen).
- Für die 3×3-Tränke (Wachstum, Mondernte) den Regen auf jedem der 9 Tiles abspielen, gern um 0–2 Frames versetzt.

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

## Böden v2: Erde und Waldboden statt Gras-Fläche (08.10.2026)

**Entscheidung 08.10.2026 (Robin):** Gras ist nicht mehr die Grundfläche. Der Garten liegt auf ruhiger **Gartenerde**, der Wald auf **Waldboden mit Laub**. Gras gibt es nur noch als **Inseln** (Übergangs-Set) und als **Wildgras-Büschel** (Objekte, siehe Flora). Vorbild ist Stardew: Der Boden ist ruhig, das Gras liegt obendrauf.

Generator: `docs/art/ground_generator/calm.py` · Vergleich: `vorschau/vergleich_garten_2x.png`, `vorschau/vergleich_wald_2x.png` (oben alt, unten neu), `vorschau/vorschlag_nacht_2x.png`, `vorschau/vorschlag_garten_2x.gif` · Mockup-Script: `docs/art/nature_generator/compare.py`

| Material | Dateien | Verwendung |
|---|---|---|
| `earth` | `ground_earth_1–3` Basis, `_4` Moosfleck, `_5` Blatt + Zweig | Garten-Grundfläche. Ton wie die Erde um die Beete, Beete passen nahtlos darauf |
| `forest_floor` | `ground_forest_floor_1–3` Basis, `_4` Moos, `_5` Zweig + Pilz | Wald-Grundfläche, dunkel-violett, Laub in Haufen |
| `meadow` | `ground_meadow_1–3` Basis, `_4` Blüten, `_5` Klee | Füllung großer Grasinseln, deutlich ruhiger als das alte `grass` |

Übergänge in `transitions/`, Aufbau wie bisher (4×5 Tiles, Index = `TL·1 + TR·2 + BL·4 + BR·8`, Bit = **erstes** Material im Namen, Zeile 4 = Alternativen für 3, 5, 10, 12):

| Datei | oberes Material | unteres Material |
|---|---|---|
| `transition_meadow_earth.png` | Wiese (Grasinsel) | Gartenerde |
| `transition_meadow_forest_floor.png` | Wiese (Grasinsel) | Waldboden |
| `transition_forest_floor_path.png` | Waldboden | Trampelpfad (`path`) |
| `transition_earth_path.png` | Gartenerde | Trampelpfad (`path`) – Wege durch den Garten |
| `transition_meadow_path.png` | Wiese | Trampelpfad (`path`) – Wege über Grasinseln |

- Mischung beim Malen: Basis 1–3 gleich oft, Deko-Varianten 4/5 zusammen höchstens 10–15 %.
- Wie bei allen Corner-Terrains treffen an einer Ecke höchstens **zwei** Materialien zusammen. Grasinseln im Wald brauchen deshalb **eine Kachel Abstand zum Weg**.
- **Grasränder (08.10. überarbeitet):** Die drei Wiesen-Übergänge haben keine durchgehende „Teppichkante“ mehr. Die Grenze ist unruhiger, Halme wachsen über den Rand, und einzelne Büschel stehen davor. Die Kachel-Logik bleibt gleich.
- Die alten `grass`-Tiles und -Übergänge bleiben im Projekt (z. B. für spätere Wiesen-Orte), werden in Garten und Wald aber nicht mehr als Fläche benutzt.

## Inventar-Icons – `assets/items/`

16×16, transparenter Hintergrund, Aubergine-Kontur. Für die UI ganzzahlig skalieren (2× oder 3×).

| Datei | Inhalt |
|---|---|
| `seed_<pflanze>.png` | Samentütchen mit Etikett (Pflanzen-Emblem auf dunklem Feld, Goldrahmen) |
| `crop_<pflanze>.png` | Ernte-Item (Mondkelch-Blüte, Laternenbeeren, Alraune, Nachtschatten-Traube, Blutrose, Farnwedel) |
| ~~`items_plants_atlas.png`~~ (08.10. entfernt, im Spiel nicht benutzt; Generator `plant_generators/icons.py`) | alle 12 als Atlas 96×32: Zeile 0 Samen, Zeile 1 Ernte, Spalten in der Reihenfolge moon_chalice, lantern_berry, mandrake, nightshade, blood_rose, ghost_fern |

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

**Umgesetzt:** Im Spiel zeichnet `assets/effects/shaders/nightshade_domes.gdshader` die Aura als Nebel (nicht als Glas, Entscheidung vom 07.10.). Welken: `assets/effects/shaders/wilt.gdshader`. `nightshade_dome.png` wurde nicht benutzt und am 08.10. entfernt (Generator: `plant_generators/nightshade_aura.py`).

## Flora und Fauna – `assets/environment/flora/`, `fauna/` (08.10.2026)

Generatoren: `docs/art/nature_generator/forest.py` (Wald), `garden.py` (Garten, Wildgras, Unkraut, Zaun), `preview.py` (Vorschauen), gemeinsame Helfer in `nature.py`.
**Hinweis:** Die Szenen-Vorschauen `vorschau_wald_*` und `vorschau_garten_*` zeigen noch den alten Gras-Boden. Maßgeblich für den Boden ist der Abschnitt „Böden v2“.
Vorschauen: `vorschau/vorschau_wald_tag_nacht_2x.png`, `vorschau/vorschau_garten_tag_nacht_2x.png` (jeweils oben Tag, unten Nacht mit Nachtfärbung und Lichtern), `vorschau/vorschau_wald_nacht_2x.gif`, `vorschau/vorschau_garten_nacht_2x.gif` (Wiegen, Pulsieren, Glühwürmchen), `vorschau/uebersicht_flora_3x.png` (alle Teile mit Namen).

**Fußpunkt** ist bei allen Grafiken **unten Mitte** (unterste Pixelzeile). Für Y-Sort wie bei der Hexe: `centered = true`, `offset = Vector2(0, -Höhe/2)`, Node-Position = Fußpunkt. Kollision nur am Fuß, siehe Spalte „Kollision“ (RectangleShape2D, `position = Vector2(0, -Höhe/2)` der Form).

Animierte Grafiken als `AnimatedSprite2D` im **Loop**. Im `_ready()` einen zufälligen Startframe setzen (`frame = randi() % Anzahl`), sonst wiegen alle Bäume im Gleichtakt.
**Jedes Objekt bekommt einen Bodenschatten**, siehe Abschnitt „Bodenschatten“ weiter unten.

### Bäume (Wald und Garten)

| Datei | Frame | Frames | FPS | Kollision | Hinweis |
|---|---|---|---|---|---|
| `tree_oak.png` | 96×120 | 8 | 6 | 16×8 | verdrehte Eiche, breite Laubkrone, graubraune Rinde |
| `tree_willow.png` | 96×144 | 8 | 6 | 18×8 | Weide mit hängenden Zweigen und silbrigen Spitzen, grünlich-graue Rinde; Zweigspitzen schwingen bis 2 px |
| `tree_fir.png` | 72×144 | 8 | 6 | 12×8 | dunkle Tanne mit Stufen, rotbraune Rinde, für den Waldrand |
| `tree_dead.png` | 96×120 | 1 | – | 16×8 | toter Baum, ausgebleichte silbrige Rinde, Bartflechte; steht still |
| `tree_elder.png` | 72×96 | 8 | 6 | 14×6 | **Garten:** Holunder (Hexenbaum), luftige Krone, helle Korkrinde, weiße Blütendolden |

**Wiegen (08.10. überarbeitet):** 8 Frames bei 6 FPS. Ganze Laubbüschel bewegen sich (keine aufreißenden Zeilen): Die Wipfel schwingen vor, die Mitte folgt einen Frame später, der untere Teil bleibt ruhig. Am äußersten Ausschlag gibt es jeweils einen Frame Pause.

Die Bäume sind etwa 2× so hoch wie die Hexe, damit der Wald über ihr aufragt. Sie verdecken sie also, wenn sie dahinter steht (Y-Sort). Wer möchte, kann die Krone bei Überdeckung halbtransparent schalten. Das ist später ein schöner Komfort, aber nicht nötig.

### Unterholz und Boden-Deko

| Datei | Frame | Frames | FPS | Kollision | Hinweis |
|---|---|---|---|---|---|
| `bush_1.png` | 32×32 | 1 | – | 24×10 | runder Busch |
| `bush_2.png` | 48×32 | 1 | – | 40×10 | breiter, flacher Busch |
| `bush_berries.png` | 32×32 | 1 | – | 24×10 | Busch mit Bordeaux-Beeren (nur Deko) |
| `stump.png` | 32×32 | 1 | – | 18×8 | Baumstumpf mit Moos und Pilzchen |
| `log.png` | 64×32 | 1 | – | 52×10 | liegender Stamm, Schnittfläche links |
| `rock_1.png` / `rock_2.png` | 32×32 / 16×16 | 1 | – | 22×10 / – | Steine mit Moos |
| `fern_1.png`, `fern_2.png` | 32×32 | 4 | 4 | – | Farne, Wedelspitzen wiegen |
| `grass_tuft_1–3.png` | 16×16 | 4 | 4 | – | Grasbüschel (2 = weiße, 3 = Flieder-Blüte), **ohne Kontur** wie die Halme im Boden |
| `bush_lavender.png` | 32×32 | 4 | 4 | – | **Garten:** Nachtlavendel, Blütenähren wiegen |
| `flowers_lilac.png` | 32×32 | 1 | – | – | **Garten:** Fliederglocken |
| `flowers_moon.png` (+`_glow`) | 32×32 | 1 | – | – | **Garten:** Mondblumen, weiß mit Goldmitte, schimmern nachts |
| `flowers_ember.png` (+`_glow`) | 32×32 | 1 | – | – | **Garten:** Glutlaternen, kleine warme Lampions |
| `flowers_blood.png` | 32×32 | 1 | – | – | **Garten:** Blutnelken, Bordeaux mit Magenta-Herz |
| `wild_grass_1–3.png` | 32×32 | 4 | 4 | – | **Wildgras** (Stardew-Prinzip), dichte Büschel, wiegen; 3 = mit Blüten. Als **räumbares Objekt** gedacht, auf Erde, Waldboden und Grasinseln |
| `weed_thistle.png` | 32×32 | 1 | – | – | Unkraut: Distel mit violettem Kopf, räumbar |
| `weed_dock.png` | 32×32 | 1 | – | – | Unkraut: Ampfer-Rosette am Boden, räumbar |

Wildgras und Unkraut sind grafisch nur Deko. Ob das Wegräumen etwas bringt (z. B. ab und zu ein Samen, passend zu „Samen durch Aufräumen“), ist noch **nicht entschieden**.

### Leuchtpilze

| Datei | Frame | Frames | FPS | Licht (PointLight2D + `NightLight`) |
|---|---|---|---|---|
| `mushroom_moon.png` (+`_glow`) | 24×20 | 4 | 4 | `Color(0.62, 0.72, 1.0)`, `base_energy` 0.9, Radius ca. 40 px, 6 px über dem Fuß |
| `mushroom_ember.png` (+`_glow`) | 24×20 | 4 | 4 | `Color(1.0, 0.71, 0.40)`, `base_energy` 0.9, Radius ca. 40 px |
| `mushroom_ring.png` (+`_glow`) | 64×48 | 8 | 6 | Hexenring: `Color(0.85, 0.25, 0.6)`, `base_energy` 0.8, Radius ca. 70 px, Mitte des Rings. Das Leuchten läuft im Kreis, die Mitte ist frei begehbar |

- Pilze und Blumen wurden am 08.10. vergrößert (Kappen bzw. Blüten etwa doppelt so groß), damit sie in Spielgröße nicht nur Punkte sind.
- **Glow-Ebene:** `<name>_glow.png` hat dieselben Frames, enthält aber nur die selbstleuchtenden Pixel. Als zweites `AnimatedSprite2D` direkt darüber legen, mit `CanvasItemMaterial`, `light_mode = Unshaded` (wie bei Hexe und Trank-Effekten), gleiche FPS und gleicher Startframe. Dann strahlen Kappen und Blüten nachts durch, während der Rest normal dunkel wird.
- Lichttextur: vorhandenes `effects/lights/light_round_64.png` bzw. `_128.png`.
- Die Pilze passen thematisch gut zum Wald-Sammeln. Ob man sie pflücken kann, ist eine Gameplay-Entscheidung. Grafisch sind sie nur Deko.

### Zaun – `assets/environment/props/fence_atlas.png`

128×128, **16 Kacheln à 32×32** als Autotile. Kachel-Index = `links·1 + rechts·2 + oben·4 + unten·8` (gesetztes Bit = Nachbar ist auch Zaun), Kachel in Spalte `index % 4`, Zeile `index / 4`.
- Index 0 = einzelner Pfosten, 3 = waagerechte Mitte, 12 = senkrechte Mitte, 10 = Ecke oben links (rechts + unten), 9 = Ecke oben rechts (links + unten) usw.
- Riegel und Kontur laufen nahtlos über die Kachelgrenzen, Lücken (Tor) entstehen einfach durch Weglassen von Kacheln.
- **Gartentor** (`fence_gate_h.png`, 4 Frames à 32×32: 0 zu … 3 offen, 8 FPS beim Öffnen) ersetzt eine Kachel in einem **waagerechten** Zaunlauf. Bei den Nachbarn das Bit zum Tor wie bei Zaun setzen: Ihre Riegel enden an den Torpfosten. Der Flügel ist eine Bretterwand mit Goldscharnieren und dreht sich beim Öffnen um den linken Pfosten. `fence_gate_v.png` (2 Frames: zu, offen) ist für **senkrechte** Zaunläufe. Kollision nur, solange das Tor zu ist.
- In Godot als eigene `TileMapLayer` „Fence“ über dem Boden, `y_sort_enabled`. Das Tor ist besser ein eigenes Objekt (AnimatedSprite2D + Interaktion) an der Stelle der Kachel. Kollision pro Kachel als schmaler Streifen am Pfostenfuß. Oder per Script: Index aus den Nachbarn berechnen und Kachel setzen.

### Glühwürmchen – `assets/environment/fauna/firefly.png`

48×8, **6 Frames à 8×8**, Blinken: aus, aus, glimmen, hell, hell, glimmen. Mitte des Frames = Körper (4, 4), **kein Fußpunkt**.
- Bewegung macht das Spiel: kleine Szene `Firefly` mit `AnimatedSprite2D` (6 FPS, Loop, zufälliger Startframe, `light_mode = Unshaded`) und einem kleinen `PointLight2D` (`light_glimmer_16.png`, warm, `base_energy` ca. 0.5) mit `NightLight`-Script. Position per Script wandern lassen (überlagerte Sinuswellen, ca. 10 px Ausschlag, langsam).
- Nur nachts sichtbar: `visible`/`modulate.a` an `DayCycle.night_factor()` koppeln.
- Alternative für viele auf einmal: `GPUParticles2D` mit derselben Textur (Particle-Animation, `CanvasItemMaterial` mit `particles_animation`).

### Ambient-Fauna – `assets/environment/fauna/` (08.10.2026)

Generator: `docs/art/nature_generator/fauna.py` (von Hand gesetzte Pixelraster) · Vorschau: `vorschau/vorschau_fauna_nacht_3x.gif`

Reine Atmosphäre, kein Gameplay. Die Tiere werden per Script bewegt, die Grafiken liefern nur die Animation.

| Datei | Frame | Frames | Animationen (Frame-Folge, FPS) | Fußpunkt | Hinweis |
|---|---|---|---|---|---|
| `moth.png`, `moth_dark.png` | 8×8 | 4 | `fly` 0-1-2-3, 12 FPS, Loop | Mitte | Kreisen um Lichtquellen (Laterne, Glutpilz, Lagerfeuer): Ellipse ca. 10×6 px, leicht unregelmäßig. Ohne Kontur. Zwei Farbvarianten mischen |
| `bat.png` | 16×12 | 4 | `fly` 0-1-2-3, 10 FPS, Loop | Mitte | Fliegt ab und zu quer durchs Bild (Wellenlinie), nur nachts, z. B. alle 30–90 s. Feine Mondlicht-Kante oben auf den Flügeln, damit man sie nachts erkennt |
| `owl.png` (+`_glow`) | 16×18 | 5 | `idle` 0 · `blink` 0-1-0 · `look_left` 2 · `look_right` 3 · `ruffle` 0-4-4-0 (Gefieder aufplustern), per Script zufällig wechseln | Krallen unten Mitte |
| `owl_fly.png` (+`_glow`) | 32×20 | 4 | `takeoff` 0, dann `fly` 1-2-3 im Loop, 8 FPS | Mitte | Abflug: breite Flügel mit gespreizten Schwungfedern. Beim Wegfliegen Position per Tween nach oben/außen | Sitzt auf dem toten Baum: Fußpunkt Baum **+ (18, −69)** = rechter Ast. Augen-Glow unbeleuchtet (wie bei den Pilzen), nachts sieht man fast nur die Augen. Optional: fliegt weg, wenn die Hexe sehr nah kommt |
| `toad.png` | 16×16 | 8 | `idle` 0-1, 2 FPS · `croak` 0-2-2-0, 4 FPS · `hop` 3-4-5-6-7, 10 FPS (Ducken, Absprung, Luft hoch, Luft sinkend, Landung; während 4–6 ca. 9 px vorwärts) | unten Mitte | Garten und Grasinseln. Sitzt meist, quakt manchmal, hüpft weg, wenn die Hexe nah kommt. Frame 4 = in der Luft, der Schatten bleibt am Boden |

- Alle außer der Motte haben eine Aubergine-Kontur.
- Nachts dunkel wie alles andere (normale Beleuchtung). Nur die Eulenaugen sind unshaded.
- Die Animationsnamen sind Vorschläge für die SpriteFrames.

### Neue Farben

6 Laub- und Weidentöne, siehe `docs/art/neue_farben.md` (Abschnitt 08.10.2026). Sie sind in `hexen_palette.gpl` nachgetragen. Alle anderen Töne stammen aus der bestehenden Palette.

## Unterschlupf: hohler Uraltbaum – `assets/environment/shelter/` (08.10.2026)

Generator: `docs/art/nature_generator/shelter.py` · Vorschauen: `vorschau/vorschau_uraltbaum_tag_nacht_2x.png` (außen, mit Eiche und Hexe zum Größenvergleich), `vorschau/vorschau_unterschlupf_innen_2x.png` (innen, links ohne, rechts mit Nachtlicht), `vorschau/vorschau_unterschlupf_nacht_2x.gif`

### Außen (im Garten)

| Datei | Frame | Frames | FPS | Hinweis |
|---|---|---|---|---|
| `hollow_tree.png` (+`_glow`) | 192×224 | 8 | 6 | Uraltbaum mit breiter Schirmkrone in zwei Etagen und hängender Bartflechte. Tür tief im Stamm, von einem Wurzelbogen gerahmt, Mondsichel darüber, Trittstein davor. Glow-Ebene: Türspalt, Fenster, Laterne |

- **Fußpunkt** unten Mitte (96, 223). `centered = true`, `offset = Vector2(0, -112)`.
- **Tür** unten Mitte, 22 px breit, Unterkante 4 px über dem Fußpunkt → hier liegt der Ausgang `ToShelter` (Exit-Bereich ca. 24×12 direkt vor der Tür).
- **Kollision:** zwei Rechtecke links und rechts der Tür (je ca. 32×14 am Stammfuß), damit man nur durch die Tür hineingeht. Die Wurzeln sind begehbar.
- **Lichter** (PointLight2D + `NightLight`, relativ zum Fußpunkt): Tür `(+14, −5)` warm, Energie 1.0, Radius ca. 50 · Laterne `(−52, −67)` warm, 1.1, Radius ca. 40, `flicker` 0.1 · Fenster `(+18, −65)` warm, 0.6, Radius ca. 30.

### Innen (Szene `shelter.tscn`)

| Datei | Frame | Frames | FPS | Fußpunkt | Hinweis |
|---|---|---|---|---|---|
| `shelter_room.png` | 320×256 | 1 | – | – | Raumgrafik: gewölbte Stammwand, Boden = Baumquerschnitt, Astloch mit Mond, Deckenbalken (daran hängen die Gläser), Höhlung oben ins Dunkle, Spiegel mit Goldrahmen und Kräutergirlande an der Wand, Wurzelpfosten an der Tür. Als Hintergrund (Sprite2D, `centered = false`), außerhalb transparent → Hintergrund dunkel (`#0E0A14`) |
| `shelter_shelf.png` | 64×64 | 1 | – | unten Mitte | Wurzelregal an der Rückwand (Gläser, Bücher, Schädel, Kräuterbündel) |
| `shelter_stove.png` (+`_glow`) | 32×96 | 4 | 8 | unten Mitte | Bauchofen, Feuer flackert; das Rohr läuft bis oben in die dunkle Höhlung |
| `shelter_firewood.png` | 28×19 | 1 | – | unten Mitte | Feuerholz neben dem Ofen |
| `shelter_broom.png` | 16×48 | 1 | – | unten Mitte | Hexenbesen, an die rechte Wand gelehnt |
| `shelter_doormat.png` | 40×12 | 1 | – | – | Fußmatte innen an der Tür, liegt **flach** wie der Teppich |
| `shelter_armchair.png` | 40×44 | 1 | – | unten Mitte | Ohrensessel (Bordeaux-Samt, Fliederdecke) |
| `shelter_rug.png` | 96×40 | 1 | – | – | Teppich, liegt **flach unter allem** (nicht Y-sortiert) |
| `shelter_books.png` | 16×16 | 1 | – | unten Mitte | Bücherstapel neben dem Sessel |
| `shelter_chest.png` | 32×28 | 2 | – | unten Mitte | Truhe: Frame 0 zu, 1 offen (für späteres Lager) |
| `shelter_candles.png` (+`_glow`) | 16×16 | 3 | 6 | unten Mitte | drei Kerzen, Flammen flackern |
| `shelter_jar.png` (+`_glow`) | 16×32 | 4 | 4 | **oben Mitte** (Aufhängung) | hängendes Glühwürmchen-Glas |
| `effects/lights/light_moonbeam.png` | 128×192 | – | – | – | weiche Lichttextur für den Mondstrahl (wie `light_round_*`) |

Koordinaten in Raum-Pixeln (Ursprung oben links der Raumgrafik), so wie in der Vorschau:
- **Begehbarer Boden:** Ellipse Mitte `(160, 156)`, Radien ca. `128 × 70`. Als `CollisionPolygon2D` die Außenseite davon sperren. **Tür** unten Mitte bei `(160, 236)`, 40 px breit → Ausgang `ToGarden`.
- **Möbel (Fußpunkte):** Regal `(74, 104)`, Kerzen `(122, 104)`, Rezeptpult `(160, 128)`, Ofen `(252, 100)`, Feuerholz `(222, 106)`, Besen `(300, 150)`, Truhe `(58, 170)`, Teppich-Mitte `(212, 176)`, Sessel `(226, 186)`, Bücher `(252, 190)`, Fußmatte-Mitte `(160, 226)`. Gläser hängen am Deckenbalken bei `(128, 29)` und `(168, 28)` (Aufhängepunkt = oberes Ende der Schnur). Die lose Seite kann z. B. neben die Truhe.
- **Lichter:** Mondstrahl (`light_moonbeam.png`, kühl `Color(0.6, 0.7, 1.0)`, Energie 0.9) mit Lichtmitte bei `(148, 126)`; die Textur fällt schräg von links oben nach rechts unten · Ofen `(252, 84)`, warm `Color(1, 0.62, 0.32)`, 1.1, `flicker` 0.1 · Kerzen `(122, 92)`, warm, 0.8, `flicker` 0.1 · je Glas ein kleines warmes Licht (0.75) ca. 22 px unter dem Aufhängepunkt.
- Raumgrafik hat 19 Farben (Wand, Boden, Spiegel, Girlande, Balken in einem Bild).
- Das Mondlicht ist im Spiel auch nachts das hellste kalte Licht im Raum, deshalb liegen Pult und Weg zur Tür darin.
- Viele Teile im Regal → 18 Farben (über dem Richtwert, aber nötig für die vielen Gläser).

## Sammelobjekte Wald – `assets/environment/forage/` und `assets/items/` (08.10.2026)

Generator: `docs/art/nature_generator/forage.py` · Vorschau: `vorschau/vorschau_sammelobjekte_5x.png`

**Nur Grafiken.** Name, Wirkung, Fundorte und Nachwachsen entscheidet Robin, deshalb sind die Dateinamen neutral.

| Objekt | Weltgrafik | Frames | nach dem Pflücken | Icon |
|---|---|---|---|---|
| Pilz (Röhrling, dunkle Bordeaux-Kappe) | `forage_mushroom.png` 24×20 | 4 | verschwindet | `items/forage_mushroom.png` |
| Beerenstrauch (geisterblaue Beeren) | `forage_berries.png` (+`_glow`) 32×32 | 4 | `forage_berries_picked.png` (leerer Strauch) | `items/forage_berries.png` |
| Feder (schwarz, blau-violett schimmernd) | `forage_feather.png` 16×16 | 4 | verschwindet | `items/forage_feather.png` |
| Mondmoos auf Stein (silbrige Spitzen) | `forage_moss.png` (+`_glow`) 24×18 | 4 | `forage_moss_picked.png` (Stein ohne Moos) | `items/forage_moss.png` |

- **Glitzern als Hinweis:** Frames 0–1 ruhig, 2 großes, 3 kleines Glitzern. Bei 2 FPS im Loop blitzt es etwa alle 2 s kurz auf. Das passt zu „Discovery“: Man findet die Sachen, ohne dass Pfeile darauf zeigen.
- Fußpunkt unten Mitte. Die Feder liegt flach und hat keinen Fußpunkt und keinen Schatten.
- Beeren und Moos leuchten nachts ganz leicht (Glow-Ebene `light_mode = Unshaded`). So findet man sie im Dunkeln.

## Begleiterin: schwarze Katze – `assets/characters/familiar/` (08.10.2026, für später)

Generator: `docs/art/nature_generator/familiar.py` · Vorschauen: `vorschau/vorschau_katze_4x.gif`, `vorschau/vorschau_katze_tag_nacht_5x.png`

**Noch nicht einbauen.** Laut Reihenfolge kommt die Begleiterin später. Die Grafiken liegen bereit.

Schwarz mit violettem Schimmer, goldene Augen (Glow-Ebene, leuchten nachts), Halsband in Magenta mit Goldglöckchen. Alle Frames 32×24, Fußpunkt unten Mitte `(16, 23)`, Seite = Blick nach **rechts** (links = `flip_h`). Gleiches Setup wie die Hexe: `centered = true`, `offset = Vector2(0, -12)`.

| Datei | Frames | FPS | Inhalt |
|---|---|---|---|
| `cat_idle_down.png` (+`_glow`) | 4 | 4 | sitzt, Schwanz wiegt, Frame 3 blinzelt |
| `cat_idle_up.png` | 4 | 4 | sitzt von hinten, Schwanz am Boden wiegt |
| `cat_idle_side.png` (+`_glow`) | 4 | 4 | sitzt seitlich, Schwanz wiegt, Frame 2 zuckt ein Ohr |
| `cat_walk_down.png` (+`_glow`) | 4 | 8 | läuft auf die Kamera zu |
| `cat_walk_up.png` | 4 | 8 | läuft weg, Schwanz steil nach oben |
| `cat_walk_side.png` (+`_glow`) | 6 | 10 | Trab, Beine im Wechsel, leichtes Wippen |
| `cat_sleep.png` | 2 | 1 | eingerollt, atmet |

(`cat_idle_up` und `cat_walk_up` haben zwar `_glow`-Dateien, die sind aber leer, weil man die Augen von hinten nicht sieht.)

## Dialog-UI – `assets/ui/dialog_*` (08.10.2026, für später)

Generator: `docs/art/ui_generator/dialog.py` (nutzt Farben und 9-Slice-Logik von `brew_window.py`) · Vorschau: `vorschau/vorschau_dialog_2x.png` (Dialog über dem Garten bei Nacht, darunter alle Teile)

Gleicher Stil wie das Brau-Fenster, **in 1× gespeichert**, Anzeige mit `scale = 2`. Schrift: `m5x7`, Größe 16.

| Datei | Größe | Hinweis |
|---|---|---|
| `dialog_panel.png` | 32×32 | Dialogfenster, **9-Slice, Ränder je 8 px**, Grund leicht transparent. Im Mockup 304×70 (1×) am unteren Rand |
| `dialog_ornament.png` | 20×9 | Mondsichel mit Sternen, mittig auf die Oberkante des Fensters |
| `dialog_nameplate.png` | 16×14 | Namensschild, **9-Slice, Ränder je 5 px**, links oben auf der Fensterkante |
| `dialog_portrait_frame.png` | 24×24 | Portraitrahmen, **9-Slice, Ränder je 6 px**, Mitte frei → passt zu jeder Portraitgröße (Größe noch offen; Mockup: 48×48) |
| `dialog_portrait_bg.png` | 8×8 | Hintergrund hinter dem Portrait, kacheln |
| `dialog_next.png` | 4 Frames à 8×8 | „weiter“-Pfeil, wippt, 6 FPS |
| `dialog_cursor.png` | 2 Frames à 8×8 | Auswahl-Cursor, funkelt, 3 FPS |
| `dialog_choice_bg.png` | 12×12 | markierte Antwort, **9-Slice, Ränder je 4 px**, leicht transparent |

Die Portraits selbst kommen aus einer anderen KI. Im Mockup steht ein Platzhalter (Silhouette mit „?“).

## Bodenschatten – `assets/effects/shadows/` (08.10.2026)

Generator: `docs/art/nature_generator/shadows.py` · Vergleich: `vorschau/vergleich_schatten_2x.png` (links ohne, rechts mit)

Ohne Schatten schweben alle Objekte leicht über dem Boden. Die Schatten sind schlichte Pixel-Ovale in Tiefschwarz mit harten Kanten. Sie werden **nicht** in die Objekte eingebacken, damit sie auf jedem Boden funktionieren.

- In Godot: `Sprite2D` mit `centered = true`, **`modulate = Color(1, 1, 1, 0.5)`**. Der Boden im Spiel ist dunkel, deshalb ist der Wert kräftiger als bei Stardew üblich. Der Schatten liegt **unter allen Objekten**, z. B. `z_index = -1` oder eine eigene Ebene „Shadows“ zwischen Boden und Objekten.
- Am einfachsten wird er Kind der jeweiligen Objekt-Szene, mit `position` = Versatz aus der Tabelle (relativ zum Fußpunkt). Dann wandert er mit, auch bei der Hexe und der Kröte.
- Regel: etwa 8 px breiter als der Fuß des Objekts und leicht nach rechts unten versetzt (Licht von oben links), damit er sichtbar hervorschaut.
- Für neue Objekte: Größe in `SHADOWS` in `shadows.py` eintragen und das Script ausführen.

| Objekt | Datei | Versatz zum Fußpunkt |
|---|---|---|
| `witch` | `shadow_36x8.png` | `(+2, +1)` |
| `toad` | `shadow_18x5.png` | `(+1, +1)` |
| `tree_oak` | `shadow_88x20.png` | `(+6, -3)` |
| `tree_willow` | `shadow_82x18.png` | `(+6, -2)` |
| `tree_fir` | `shadow_62x14.png` | `(+4, -2)` |
| `tree_dead` | `shadow_50x12.png` | `(+4, -1)` |
| `tree_elder` | `shadow_64x16.png` | `(+4, -2)` |
| `hollow_tree` | `shadow_180x36.png` | `(+8, -8)` |
| `bush_1` | `shadow_36x9.png` | `(+2, +1)` |
| `bush_2` | `shadow_52x10.png` | `(+2, +1)` |
| `bush_berries` | `shadow_36x9.png` | `(+2, +1)` |
| `bush_lavender` | `shadow_30x7.png` | `(+1, +1)` |
| `stump` | `shadow_36x9.png` | `(+2, +1)` |
| `log` | `shadow_66x11.png` | `(+2, +1)` |
| `rock_1` | `shadow_34x9.png` | `(+2, +1)` |
| `rock_2` | `shadow_18x5.png` | `(+1, +1)` |
| `fern_1` | `shadow_30x7.png` | `(+1, +1)` |
| `fern_2` | `shadow_30x7.png` | `(+1, +1)` |
| `wild_grass_1` | `shadow_28x7.png` | `(+1, +1)` |
| `wild_grass_2` | `shadow_28x7.png` | `(+1, +1)` |
| `wild_grass_3` | `shadow_28x7.png` | `(+1, +1)` |
| `weed_thistle` | `shadow_26x7.png` | `(+1, +1)` |
| `weed_dock` | `shadow_28x7.png` | `(+1, +1)` |
| `flowers_lilac` | `shadow_22x6.png` | `(+1, +1)` |
| `flowers_moon` | `shadow_22x6.png` | `(+1, +1)` |
| `flowers_ember` | `shadow_22x6.png` | `(+1, +1)` |
| `flowers_blood` | `shadow_22x6.png` | `(+1, +1)` |
| `mushroom_moon` | `shadow_24x6.png` | `(+1, +1)` |
| `mushroom_ember` | `shadow_24x6.png` | `(+1, +1)` |
| `plant` | `shadow_24x6.png` | `(+1, +1)` |
| `campfire` | `shadow_38x10.png` | `(+1, +0)` |
| `cauldron` | `shadow_54x12.png` | `(+2, +0)` |
| `bed` | `shadow_38x9.png` | `(+2, +1)` |
| `lectern` | `shadow_30x8.png` | `(+1, +1)` |
| `fence_post` | `shadow_12x4.png` | `(+1, +1)` |
| `forage_mushroom` | `shadow_26x6.png` | `(+1, +1)` |
| `forage_berries` | `shadow_36x9.png` | `(+2, +1)` |
| `forage_moss` | `shadow_30x7.png` | `(+2, +1)` |
| `cat` | `shadow_22x6.png` | `(+1, +1)` |
| `shelter_armchair` | `shadow_46x10.png` | `(+2, +1)` |
| `shelter_chest` | `shadow_36x9.png` | `(+2, +1)` |
| `shelter_stove` | `shadow_32x8.png` | `(+1, +1)` |
| `shelter_shelf` | `shadow_60x7.png` | `(+0, +1)` |
| `shelter_books` | `shadow_18x5.png` | `(+1, +1)` |
| `shelter_broom` | `shadow_14x5.png` | `(+1, +1)` |
| `shelter_firewood` | `shadow_30x7.png` | `(+1, +1)` |

## Referenzen – `docs/art/`

- `styleguide.pdf`, `hexen_palette.gpl` (Palette für Aseprite/GIMP, inkl. der 7 abgeleiteten Töne für die Pflanzen: Indigo, Indigo hell, Flieder, Giftgrün dunkel/hell, Nachtblau hell, Geisterblau, sowie der 27 Zwischentöne vom 07.10.2026, siehe `neue_farben.md`)
- `plant_generators/`: Python-Scripts für Pflanzen, Icons (`icons.py`) und Licht (`lights.py`)
- `item_generators/potions.py`, `world_generator/bed.py`, `ui_generator/brew_window.py`, `plant_generators/nightshade_aura.py`: Generatoren der Grafiken vom 07.10.2026 (Details: `neue_assets.md`)
- `ground_generator/extra.py`: Erweiterung für Friedhofsgras, Beet-Endstücke und die neuen Übergänge (+ `extra_preview.py`, `pruefbericht_extra.txt`)
- `vorschau/vorschau_neue_boeden_2x.png`, `vorschau_items_4x.png`, `vorschau_nacht_3x.png`
- `vorschau/uebersicht_pflanzen.png`: alle Pflanzen in 1× und 3×
- `character_generator/witch_actions.py`, `character_generator/pour_effect.py`: Aktions-Animationen der Hexe und Zauber-Ausgießen-Effekt (07.10.2026)
- `nature_generator/`: Flora und Fauna für Wald und Garten (`forest.py`, `garden.py`, `preview.py`, Helfer `nature.py`, 08.10.2026)
- `referenz/witch_concept.webp`: Designvorlage der Hexe
- `referenz/witch_base_32x64.png`: Rohfassung (Basis des Pixeleditors)
- `vorschau/`: Testkarten und Lauf-GIF
- `ground_generator/`: Python-Script, mit dem die Bodentiles erzeugt wurden (nur zum Nachjustieren)
