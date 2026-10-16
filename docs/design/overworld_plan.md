# Overworld mit Höhen – technischer Plan

Stand: 16.10.2026 · Basis: Branch `village-hub` (`691cf95`) · Vorlage: KI-Weltkarte vom 15.10. (nur Inspiration, nicht 1:1)

Legende: ✅ vorhanden (im Code geprüft) · 🔮 Vorschlag (nicht entschieden) · ❓ Entscheidung von Robin nötig

---

## 0. Kurzfassung

Die KI-Karte lässt sich nicht direkt ins Spiel übernehmen, aber ihr **Aufbau** schon: welche Gebiete es gibt, wie sie zusammenhängen, was höher und was tiefer liegt. Der Weg dahin hat vier Stufen:

```text
KI-Karte ──► Weltgraph ──► Bauplan je Gebiet ──► Generator ──► spielbare Graybox ──► deine Grafiken
(Stimmung)   (Gebiete,      (Pixelbild in          (Script baut     (testen, Screens)   (Platzhalter-
              Wege, Höhe)    Aseprite, 1 px =       Boden, Klippen,                       Atlas übermalen)
                             1 Kachel)              Wasser, Wände)
```

Das Wichtigste daran:
- **Höhen sind keine neue Engine-Technik**, sondern ein zusätzlicher Kachel-Layer mit Kollision, wie Stardew Valley es macht. Das passt zum bestehenden Aufbau.
- **Du entwirfst Gebiete in Aseprite**, nicht im Godot-Editor: ein kleines Bild pro Gebiet, Farben = Höhe, Boden, Wasser. Ein Script macht daraus die Szene. Ändern heißt: Bild ändern, neu erzeugen.
- **Grafik und Layout sind getrennt.** Zuerst gibt es Platzhalter-Kacheln in einem festen Raster. Du übermalst sie später in Aseprite, und das Spiel sieht sofort richtig aus, ohne dass jemand neu baut.
- **Alles zuerst als Testszene**, bestehende Orte und Grafiken bleiben unangetastet, bis du sagst, dass es passt.

---

## 1. Was es schon gibt (✅)

| Baustein | Stand | Bedeutung für Höhen |
|---|---|---|
| Orte | Jeder Ort ist ein `Level` mit `Ground` (TileMapLayer), `Objects` (Y-sortiert) und `Exit`s. `Main` tauscht genau einen Ort, Überblendung beim Wechsel | Höhen kommen als weitere Layer in dieselbe Struktur |
| Größen | Garten 28 × 30, Seewald 34 × 26, Wald 34 × 26, Dorf 38 × 27 Kacheln. Sicht 20 × 11 Kacheln | Neue Gebiete in ähnlicher Größe |
| Ränder | Kamera und Außenwände ergeben sich aus der bemalten Fläche (`pixel_rect()`), unten 64 px HUD-Rand | Bleibt so. Klippen sind Wände **innerhalb** der Fläche |
| Boden | Ein TileSet mit 9 Terrains (Gras, Erde, Weg, Pflaster, Platten, Friedhof, Gartenerde, Waldboden, Wiese), Modus „Ecken“ (Übergänge über Ecken-Kacheln). Schrittgeräusch je Terrain | Generator malt Boden über dieselben Terrains |
| Kollision | Physik-Layer 1 `world`, 2 `interactable`, 3 `enemies`. Hexe, Wächter, Käfer prallen an `world` ab. **Zauber prallen auch an `world` ab** (`spell.gd`) | Wichtig für die Frage, ob man von oben hinunterzaubern kann (❓ 6.2) |
| Wasser | `Lake` ist ein gezeichneter Platzhalter mit Kollision und Mondspiegelung je nach Mondphase | Wird durch Wasser-Kacheln ersetzt, die Spiegelung bleibt als Idee |
| Deko | `Decor`-Szenen mit Fußpunkt, Schatten, Kollision, Licht | Bäume usw. funktionieren auf jeder Höhe |
| Spielstand | `Garden` speichert Beete und Pflanzen **nach Kachel-Koordinate**, `Wilds` Sammelobjekte nach Ort und Position | Ein umgebauter Garten verschiebt alte Beete (siehe 7) |
| Generatoren | `docs/art/ground_generator`, `docs/art/world_generator` (Python, erzeugen Grafiken). Boden und Deko von Seewald und Dorf entstanden mit einem Hilfsskript, das nicht im Repo liegt | Der Welt-Generator wäre der gleiche Ansatz, diesmal im Repo |

---

## 2. Vom Bild zur Welt: wie man die KI-Karte übersetzt

### 2.1 Weltgraph (Papier, kein Code)

Aus der Karte nehmen wir nur Lage, Verbindungen und Höhe. Vorschlag (🔮), mit den bestehenden Orten:

```text
 Höhe 2 (oben)   [Ruinen-Plateau] ──Brücke über den Bach── [Uraltbaum + Garten-Plateau]          [Friedhof]
                                                                  │ Treppe                          │ Nordpfad 🔒
 Höhe 1 (Mitte)                         Wasserfall ──► [Seewald mit See und Insel] ──Waldweg── [Dorf] ──Schluchtbrücke 🔒── [Berge]
                                                         │ Ranken-Treppe 🔒        └─Hexenpforte─┘
 Höhe 0 (unten)  [Sumpf] ◄──────────────────────────────┘
                                                         │ Süd
 Höhe 1                                           [Tiefer Wald: Hexenring, Befall] ── [Turmruine, Blütenherz?]
                                                         │
 Höhe 0                                           [Moor mit Steinbogen]  (spät)
```

Drei Höhenstufen reichen (🔮): **0 tief** (Sumpf, Moor, Schlucht, Seeufer), **1 normal** (Seewald, Dorf, tiefer Wald), **2 hoch** (Garten-Plateau, Ruinen, Berge). Innerhalb eines Gebiets gibt es meist nur zwei Stufen, damit es lesbar bleibt.

### 2.2 Bauplan pro Gebiet (Aseprite)

Für jedes Gebiet malst du ein kleines Bild: **1 Pixel = 1 Kachel**, also z. B. 34 × 26 Pixel für den Seewald. Als unterste Ebene kannst du einen vergrößerten Ausschnitt der KI-Karte darunterlegen und abpausen.

| Aseprite-Ebene | Was die Farben heißen |
|---|---|
| `height` | Grauwert = Höhenstufe (schwarz 0, grau 1, weiß 2). Wo zwei Stufen aneinanderstoßen, entsteht automatisch eine Klippe |
| `ground` | eine Farbe je Terrain (Gras, Erde, Weg, Pflaster …, feste Farbtabelle) |
| `water` | blau = tiefes Wasser (nicht begehbar), hellblau = flaches Ufer (begehbar) |
| `marks` | einzelne Pixel als Markierung: Treppe, Ausgang, Baum, Laterne, Sammelstelle, Spot für NPCs |

Ebenen exportierst du als PNGs (z. B. `seewald_height.png`, `seewald_ground.png` …). Die Farbtabelle lege ich als Aseprite-Palette ins Repo, damit du sie nur anklicken musst.

### 2.3 Generator (Python, im Repo unter `tools/world_builder/`)

Liest die PNGs und schreibt in die Szene:
- `Ground`: Boden über die vorhandenen Terrains (Übergänge wie bisher).
- `Cliffs` (neu): Kanten, Wände, Ecken und Treppen, die er selbst aus den Höhenstufen ausrechnet.
- `Water` (neu): Wasser und Ufer.
- Platzhalter-Objekte an den `marks` (Bäume als vorhandene `Decor`-Szenen, Ausgänge als `Exit`).

**Regel:** Der Generator überschreibt nur seine eigenen Layer (`Ground`, `Cliffs`, `Water`) und die von ihm gesetzten Objekte (eigener Node `Generated`). Was du von Hand im Editor dazustellst, bleibt beim Neu-Erzeugen erhalten.

**Warum kein Tiled oder LDtk?** Beide können so etwas auch, bringen aber ein weiteres Programm und ein Import-Plugin ins Projekt. Aseprite hast du schon und lernst es gerade.

---

## 3. Höhen technisch (Stufe 1: optische Höhe wie in Stardew)

### 3.1 Prinzip

```text
   Seitenansicht                       Draufsicht im Spiel (3/4-Ansicht)

   ┌──────────── Plateau (Höhe 2)       ░░░░░░░░░░░░  Plateau: normaler Boden
   │                                    ▀▀▀▀▀▀▀▀▀▀▀▀  Kante (Rand, 1 Reihe)
   │  Felswand                          ▓▓▓▓▓▓▓▓▓▓▓▓  Wand: nimmt Bodenfläche ein,
   │                                    ▓▓▓▓▓▓▓▓▓▓▓▓  1–2 Kachelreihen hoch, Kollision
   └──────────── Boden (Höhe 1)         ▄▄▄▄▄▄▄▄▄▄▄▄  Fuß (Schatten, Geröll)
                                        ░░░░░░░░░░░░  unterer Boden
```

- Die Höhe ist **nur gemalt**. Oben und unten ist für das Spiel ganz normaler Boden. Die Wandkacheln dazwischen sind feste Hindernisse.
- **Sichtbare Wände nur nach Süden** (zur Kamera). Nach Norden, Osten und Westen zeigt eine Klippe nur einen schmalen Rand mit Kollision. So machen es fast alle Top-down-Spiele. Die Illusion trägt, und es gibt keine Sortierprobleme.
- **Treppen und Rampen** sind Lücken in der Wand mit eigenen Kacheln. Schrittgeräusch „stone“, optional etwas langsamer.

### 3.2 Aufbau im Level

```text
Lakewood (Level)
├─ Ground    TileMapLayer   Boden (wie bisher)
├─ Water     TileMapLayer   Wasser + Ufer, Kollision auf tiefem Wasser, animierte Kacheln
├─ Cliffs    TileMapLayer   Kanten, Wände, Treppen; Kollision; unter Objects gezeichnet
├─ Objects   Y-sortiert     Hexe, Bäume, NPCs … (wie bisher)
│   └─ Generated            vom Generator gesetzte Platzhalter
└─ Exits
```

- **Warum `Cliffs` unter `Objects` reicht:** Eine Figur oben auf dem Plateau steht nördlich der Wand, ihr Sprite ragt nach oben und überdeckt die Wand nie. Eine Figur unten steht südlich davor und wird darüber gezeichnet. Das passt ohne Y-Sortierung der Wand. Nur bei sehr breiten Objekten direkt an Ost- oder Westkanten kann es haken; dann bekommt die Wand dort Y-Sortierung. Das prüfen wir im Test.
- **Kollision:** Polygone pro Kachel im TileSet (Godot kann das direkt). Neuer Physik-Layer 4 `cliffs` (🔮, ❓ 6.2): Hexe, NPCs und Käfer prallen ab, Zauber fliegen darüber. Dazu kommt je eine Zeile in Hexe, NPC und Käfer (`collision_mask`).
- **Wasser:** eigenes Terrain „Wasser/Ufer“ im Ecken-Modus wie der Boden. Animation über die eingebaute Kachel-Animation des TileSets (3–4 Frames). Der Wasserfall ist eine `Decor`-Szene mit Animation, Geräusch-Loop (`Sfx.make_loop_player`) und Gischt.

### 3.3 Höhe lesbar machen (gehört zum Kachel-Design)

- Wand dunkler als beide Böden, Licht von oben links: obere Kante hell, Fuß mit Schattenstreifen.
- Tiefe Gebiete bekommen mehr Nachtblau und Bodennebel (eine `NightTint`-Variante pro Level, 🔮).
- An Kanten Aussichtspunkte, an Treppen Laternen als Wegweiser.

### 3.4 Was später kommen kann (Stufe 2 und 3)

| Stufe | Was | Wann |
|---|---|---|
| 1 | optische Höhe, Klippen, Treppen (dieser Plan) | jetzt |
| 2 | Höhe über Ortswechsel: Berg oder Ruine als eigenes Level, Aufgang = `Exit` | geht schon heute |
| 3 | echte Ebenen: unter einer Brücke durchgehen und oben drüber. Eine Treppe schaltet die Kollisionsebene der Hexe um, Objekte liegen in zwei Ebenen | erst, wenn ein Gebiet es wirklich braucht (z. B. die Schluchtbrücke) |

---

## 4. Grafik und Layout trennen: der Platzhalter-Atlas

Damit du nicht auf fertige Grafiken warten musst und sie trotzdem 1:1 passen:

1. Ich erzeuge für jedes neue Set einen **Platzhalter-Atlas** mit festem Raster und beschrifteten Feldern (neue Dateien, nichts Bestehendes wird überschrieben):
   - `assets/environment/cliffs/cliff_rock_atlas.png` (Felsklippe)
   - `assets/environment/cliffs/cliff_wall_atlas.png` (Stützmauer, gleiches Raster, anderes Material)
   - `assets/environment/water/water_atlas.png` (Wasser, Ufer, Animationsframes)
2. Dazu eine Beschreibung des Rasters (`*_layout.json`, wie schon bei `ground_atlas_layout.json`) und eine Vorlage-Datei für Aseprite mit Hilfslinien.
3. Du übermalst die Felder in Aseprite und speicherst unter demselben Namen. Das Spiel zeigt sofort deine Grafik, an jeder Klippe in jedem Gebiet.

**Klippen-Set, ungefähr 24 Felder** (gleiches Raster für Fels und Mauer):

| Gruppe | Felder |
|---|---|
| Südwand (sichtbar) | links, Mitte ×2, rechts; bei 2 Reihen Höhe je oben und unten |
| Kanten | Nordrand, Ostrand, Westrand (schmal) |
| Ecken | 4 Außenecken, 4 Innenecken |
| Fuß | Schattenstreifen unten, Ecken links und rechts |
| Treppe | oben, Mitte, unten, Wange links und rechts |

**Wasser-Set:** tiefes Wasser, flaches Wasser, Ufer-Übergänge (Ecken-Modus wie der Boden), je 3–4 Frames. Dazu Wasserfall (oben, Mitte, Becken), Steg und Brücke als `Decor`.

---

## 5. Umsetzung in Schritten

Jeder Schritt ist einzeln spielbar und ein eigener Commit auf einem neuen Branch `overworld` (von `village-hub` aus).

| # | Schritt | Ergebnis | Umfang |
|---|---|---|---|
| W1 | **Höhen-Test** (`scenes/world/test/height_test.tscn`, nicht verbunden mit dem Spiel, Start per Debug-Taste) | Plateau mit Felsklippe und Stützmauer, Treppe, Rampe, Seeufer, Wasserfall als Platzhalter. Kollision, Layer `cliffs`. Screenshots in 640 × 360 | mittel |
| W2 | **Platzhalter-Atlanten** + Raster-Vorlagen für Aseprite | Klippen- und Wasser-Set einsatzbereit, du kannst parallel zeichnen | klein |
| W3 | **Generator** + Farbtabelle + Palette | Höhen-Test wird aus einem Bauplan-Bild erzeugt statt von Hand | mittel |
| W4 | **Weltgraph festlegen** (Dokument, mit dir) | Gebiete, Höhen, Verbindungen, Sperren, Reihenfolge | klein |
| W5 | **Bestehende Gebiete neu erzeugen**, eins nach dem anderen, zuerst als `_v2`-Szene neben dem Original | Seewald, dann tiefer Wald, Dorf, zuletzt Garten. Umstellen der Ausgänge erst nach deinem Okay | je mittel |
| W6 | **Sichtbare Sperren** | Mondsteg, Wasserfall-Höhle, Ranken-Treppe, Brücke (hängt am Item-Kreislauf) | je klein |
| W7 | **Neue Gebiete** | Ruinen, Sumpf, Friedhof, Berge, Moor | je mittel bis groß |

**Prüfung bei W1** (automatisch, Godot headless, wie beim Dorf):
- Die Hexe kommt nicht durch Wände, Ecken und Kanten, auch nicht mit Schweben oder Ausweichen.
- Treppen und Rampen sind in beiden Richtungen begehbar.
- Käfer und Wächter bleiben an Klippen hängen, ohne zu zittern.
- Zauber verhalten sich an Kanten wie entschieden (❓ 6.2).
- Sortierung: Bäume, Hexe und NPCs an Kante und Fuß werden richtig vor oder hinter gezeichnet.
- Alle Szenen laden ohne neue Fehler.

**Prüfung bei W1 durch dich:** Erkennt man auf den Screenshots ohne Erklärung, was oben und was unten ist? Fühlt sich die Treppe wie ein Übergang an?

---

## 6. Entscheidungen (❓)

1. **Wandhöhe pro Stufe:** 1 Kachelreihe (32 px, halb so hoch wie die Hexe, wirkt wie eine Stufe oder Mauer) oder 2 Reihen (64 px, wirkt wie eine echte Klippe). Vorschlag: Stützmauer 1 Reihe, Felsklippe 2 Reihen. Der Höhen-Test zeigt beides.
2. **Zaubern über Kanten:** Fliegen Zauber über Klippen (eigener Layer `cliffs`) oder prallen sie ab (Klippen auf `world`)? Vorschlag: Sie fliegen darüber. Von oben hinunterzaubern fühlt sich gut an, und Käfer kommen trotzdem nicht hoch.
3. **Garten und Seewald zusammenlegen?** Plateau oben, Treppe runter zum See, alles in einer Szene. Erst nach dem Höhen-Test entscheiden.
4. **Generator ins Repo** (`tools/world_builder/`) statt wie bisher außerhalb? Vorschlag: ja, damit er mit dem Spiel wächst.
5. **Alte Spielstände:** Siehe 7.

---

## 7. Risiken

| Risiko | Was passiert | Gegenmittel |
|---|---|---|
| Spielstand beim Garten-Umbau | Beete und Pflanzen sind nach Kachel-Koordinaten gespeichert. Verschiebt sich der Garten, liegen alte Beete im Zaun oder in der Klippe | Beetfläche an denselben Koordinaten lassen, oder einmalige Umrechnung beim Laden, oder bewusst „Neues Spiel“ (es ist noch ein Prototyp) |
| Sammelstellen | `Wilds` merkt sich Positionen je Ort. Nach einem Umbau können Sammelobjekte in Wänden stehen | Generator setzt Sammelstellen über `marks`; beim Laden aussortieren, was auf Klippe oder Wasser liegt (gleiches Prinzip wie beim robusten Laden) |
| NPC-Wege | Der Wächter läuft in geraden Linien zwischen Spots | Spots im Bauplan markieren; Generator prüft, ob die Linien frei sind (wie beim Dorf per Script) |
| Platz für Kampf | Die KI-Karte ist eng und voll | Regel für Baupläne: Kampfflächen mindestens 8 × 6 Kacheln frei, Wege mindestens 3 Kacheln breit |
| Hand-Änderungen gehen verloren | Neu erzeugen überschreibt Layer | Generator schreibt nur in `Ground`, `Cliffs`, `Water` und `Generated` |
| Godot 4.7 | Ich arbeite mit TileMapLayer, TileSet-Kollision, Terrains und Kachel-Animation, die es seit 4.3 gibt. Neuere Details prüfe ich beim Bau headless | – |

---

## 8. Nicht in diesem Plan

- KI-Karte 1:1 abbilden oder als Hintergrundbild nutzen.
- Eine einzige große Weltkarte statt einzelner Orte.
- Echte Ebenen (Stufe 3) vor einem konkreten Fall.
- Finale Grafiken (die machst du; der Plan sorgt nur dafür, dass sie ohne Umbau passen).
- Weltkarte im Grimoire (eigenes Thema, sobald der Weltgraph steht).
