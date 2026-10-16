# Test: Waldboden für den Seewald (Lake Woods) – 15.10.2026

**Status: Testdateien, nichts eingebaut.** Keine Szene, kein TileSet, keine bestehende Grafik und
keine Palette wurde verändert. Alles liegt in neuen Dateien (Liste am Ende).

---

## 1. Was über das pixel-plugin lief und was nicht

Das Plugin war in der Cloud-Sitzung, in der das entstanden ist, **nicht installiert**. Dein lokales
Plugin und dein Aseprite unter Windows waren von dort nicht erreichbar. Deshalb:

- Plugin **willibrandon/pixel-plugin v0.5.0** aus GitHub geholt. Der mitgelieferte MCP-Server
  `pixel-mcp` (Linux-Build) ist derselbe, den das Plugin bei dir startet.
- **Aseprite v1.3.18 aus dem offiziellen Quellcode** als reine Kommandozeilenversion gebaut
  (ohne Oberfläche). Der Build meldet sich als `1.x-dev`, das Plugin hat damit problemlos gearbeitet.
- Die Plugin-Tools wurden **direkt über MCP aufgerufen**, nicht über die Slash-Befehle `/pixel-*`.
  Das sind dieselben Tools, die in Claude Code als `mcp__aseprite__*` erscheinen.

**Über das Plugin ausgeführt (56 Aufrufe, 0 Fehler):**
`create_canvas` (32×32, RGB) · `set_palette` (alle 76 Farben aus `hexen_palette.gpl`) ·
`add_layer` ×2 · `delete_layer` · `add_frame` ×6 · `draw_rectangle` ×7 · `draw_pixels` ×14 ·
`save_as` · `export_sprite` ×7 · `get_pixels` ×14 (Kontrolle) · `get_sprite_info` · `get_palette`

**Nicht über das Plugin:**
- **Der Pixelentwurf selbst** (welche Farbe auf welchen Pixel) kommt aus einem Python-Skript
  (`ground_generator/seewald_waldboden.py`). Das Plugin zeichnet Pixel, Linien und Formen, hat aber
  nichts für kachelbare Texturen (kein Wrap, kein Kachel-Modus).
- **Kachelprüfung, Vorschauen und Vorher/Nachher** habe ich mit eigenen Skripten gemacht. Das Plugin
  hat dafür kein Werkzeug.
- **Bewusst nicht benutzt:** `apply_auto_shading`, `draw_with_dither`, `suggest_antialiasing`,
  `quantize_palette`. Die arbeiten mit Antialiasing, Dithering oder Verläufen und widersprechen
  damit unseren Stilregeln.

**Was am Plugin aufgefallen ist:**
- `get_pixels` bricht bei einer leeren Ebene mit „No cel found“ ab, statt transparente Pixel zu liefern.
- `export_sprite` schreibt immer **RGBA**-PNGs. Unsere Bodentiles sind **RGB**. Ich habe die Exporte
  verlustfrei nach RGB umgeschrieben (alle Pixel waren voll deckend, Pixel vorher/nachher identisch geprüft).
- Der Server meldet sich im MCP-Handshake als Version `0.1.0`, im Log als `0.5.0`. Funktioniert aber.

**Kontrolle, dass das Plugin wirklich das gezeichnet hat, was geplant war:**
1. Über das Plugin selbst zurückgelesen (`get_pixels`): 14 von 14 Ebenen pixelgleich mit dem Entwurf.
2. Unabhängig davon die `.aseprite`-Datei mit Aseprite per Lua-Skript geöffnet und jeden Frame gerendert:
   7 von 7 pixelgleich. Datei: 32×32, RGB, 7 Frames, Ebenen `Boden` und `Laub & Details`, 76 Palettenfarben.
3. Exportierte PNGs gegen den Entwurf: 7 von 7 pixelgleich.

---

## 2. Bestand: Größen und Formate (geprüft, nicht geändert)

| Was | Größe | Format |
|---|---|---|
| Bodentiles (`ground_*_N.png`) | 32×32 | PNG, RGB ohne Alpha (59 Stück) |
| `ground_atlas.png` | 192×256 (6×8 Tiles) | PNG, RGB |
| Übergänge (`transitions/*.png`) | 128×160 (4×5 Tiles à 32) | PNG, RGB |
| `ground_tileset.tres` | `tile_size = 32×32` | Terrain-Set mit Ecken-Bits |

Die neuen Testdateien halten sich daran: 32×32, PNG, RGB.

**Was der Seewald nutzt** (`scenes/world/lakewood.tscn`, nur auf dem Branch `village-hub`):
`forest_floor_1–5` (308 Zellen), `meadow_1–5` (263), `path` aus dem Atlas, Übergänge
`meadow_forest_floor` und `meadow_path`.

Hinweis: Ich sehe nur den Stand auf GitHub. Was du lokal schon überarbeitet und noch nicht gepusht
hast, ist nicht berücksichtigt. Im Styleguide (Abschnitt 12) steht noch „assets/tiles/ (16×16)“,
das ist veraltet (richtig: `assets/environment/ground/`, 32×32).

---

## 3. Welche Bodentiles verbessert werden müssen

Kennzahl „Rasterwirkung“: wie stark sich ein 32er-Raster in einer großen Zufallsfläche abzeichnet
(Abweichung des Helligkeitsprofils über die Kachelposition, in % der Gesamtstreuung). Kleiner ist besser.

| Tile | Problem | Rasterwirkung (Spalten/Zeilen) |
|---|---|---|
| **forest_floor** (Hauptfläche im Seewald) | Alle 5 Varianten teilen einen 2 px breiten Rand, **in dem Blattstückchen liegen**. Die wiederholen sich alle 32 px und bilden ein Punktraster. Laub ist gleichmäßig wie Konfetti verteilt, keine Cluster. 13–16 der 14–18 Farben stehen **nicht** in `hexen_palette.gpl`. | 49 / 31 |
| **meadow** | Wiederkehrende dunkle C-Flecken an gleicher Stelle, in schmalen Wiesenstreifen deutlich sichtbar. Alle 5 Farben nicht in der gpl. | 35 / 31 |
| **path** | Stärkstes Raster der drei, Farben nicht in der gpl. | 51 / 34 |
| **Übergänge** | Enthalten jeweils die alte Füllung. Jede neue Füllung braucht neu erzeugte Übergänge. | – |

Allgemein: Fast alle Bodentiles benutzen Farben aus den Generator-Rampen (GRAS, ERDE, WALD …), die
nie in `hexen_palette.gpl` eingetragen wurden. Entweder trägt man die Rampen nach, oder man färbt
die Böden auf die Palette um. **Das musst du entscheiden.**

Angefangen habe ich beim **Waldboden**, weil er die größte Fläche im Seewald hat und am deutlichsten rastert.

---

## 4. Der Prototyp

**Dateien:**
- `assets/environment/ground/test_lakewood/ground_lakewood_floor.aseprite` – Quelle zum Bearbeiten:
  1 Datei, **7 Frames = 7 Varianten**, Ebenen `Boden` und `Laub & Details`, Palette = `hexen_palette.gpl`.
  Tipp: In Aseprite *View → Tiled Mode → Both* zeigt beim Bearbeiten sofort, ob die Kanten passen.
- `assets/environment/ground/test_lakewood/ground_lakewood_floor_1..7.png` – Export für Godot, 32×32 RGB.

**Varianten und vorgeschlagene Häufigkeit** (als `probability` im TileSet; noch **nicht** eingetragen):

| # | Inhalt | Anteil |
|---|---|---|
| 1 | ruhig: Erdkrumen, Dellen, ein paar alte Blätter | 36 % |
| 2 | ruhig + ein warmes Ockerblatt | 24 % |
| 3 | Laubhaufen (rot/ocker), außermittig | 12 % |
| 4 | Moos + zwei nasse Kiesel (Seenähe) | 9 % |
| 5 | Zweig + Weidenblätter (die Weiden am See) | 12 % |
| 6 | Pfütze mit Mondglanz (selten) | 3 % |
| 7 | Hexenspur: drei Magenta-Sporen (sehr selten) | 4 % |

**Was anders ist als vorher:**
- **Nur Palettenfarben**, 9–12 pro Kachel (Richtwert 8–12). Grund ist Ebenholz 2, Dellen und
  Schattenseiten Ebenholz 1, Lichtkanten Ebenholz 3/4, Schlagschatten Tiefschwarz.
- **Kein gemeinsamer Randstreifen mit Details mehr.** Die Grundfläche ist eine einzige Farbe. Kein
  Detail wird an der Kante abgeschnitten oder läuft auf die Nachbarkachel über (auch kein Schatten).
  Deshalb passt jede Variante neben jede andere, ohne dass sich etwas an den Kanten wiederholt.
- **Klare Cluster statt Rauschen:** Erdkrumen (oben links hell, unten rechts dunkel), Dellen
  (umgekehrt), Blätter mit Lichtkante oben links und Schlagschatten unten rechts. 0 lose Einzelpunkte
  (Ausnahme: ein Sporenpunkt in Variante 7).
- **Laub liegt in losen Gruppen**, nicht gleichmäßig verteilt. Die häufigen Varianten 1+2 sind
  bewusst unauffällig, damit sich nichts Markantes im Raster wiederholt.
- **Warme Akzente:** ocker/gold glimmende Blätter. **Magenta** nur in der seltenen Hexenspur
  (Magie bleibt etwas Besonderes). **Seebezug:** Weidenlaub, Moos, Kiesel, Pfütze.
- Kein Antialiasing, keine Verläufe, kein Dithering.

---

## 5. Prüfung (Kanten, Wiederholung, Palette)

| Prüfung | Ergebnis |
|---|---|
| Größe / Format / deckend | 7/7: 32×32, PNG RGB, alle Pixel voll deckend |
| Farben außerhalb `hexen_palette.gpl` | 0 (alt: 13–16 je Kachel) |
| Farben je Kachel | 9–12 (alt: 14–18) |
| Details über die Kante | keine (aus dem Aufbau garantiert, keine Umbruch-Koordinaten) |
| Alle 49 Paare links/rechts und oben/unten + Ecken | keine Naht sichtbar (siehe Kantenprüfung). Kantendifferenz höchstens 14,1 (links/rechts) bzw. 9,1 (oben/unten), im Kachelinneren 7–14. Den Höchstwert hat Variante 7 neben sich selbst, weil dort an beiden Rändern Details liegen. Alt: 18,9 / 12,8 |
| Eckpixel aller Varianten | identisch (Grundfarbe) |
| Rasterwirkung (Spalten/Zeilen) | **25 / 17** (alt: 49 / 31) |

Vorschauen in `docs/art/vorschau/`:
- `test_lakewood_varianten_8x.png` – alle Varianten 8-fach, daneben der alte Waldboden
- `test_lakewood_kantenpruefung_2x.png` – jede Variante neben jeder (oben i+j, unten j+i)
- `test_lakewood_testflaeche_1x.png` / `_2x.png` – 20×12 Kacheln zufällig nach Anteil, Tag + Nacht
- `test_lakewood_vorher_nachher_2x.png` / `_nacht_2x.png` – echter Seewald-Ausschnitt (640×360, wie ein Bildschirm)

Die Nachtbilder sind vereinfacht: `#665C8F` multipliziert (wie `night_tint.gd`) plus zwei warme
Lichtinseln. Godots Lichtberechnung ist das nicht genau.

---

## 6. Ehrliche Einschätzung

**Besser:** ruhiger, sauberer, palettentreu, deutlich weniger Raster. Baumschatten und Deko heben
sich besser ab.

**Noch nicht gut:**
- **Übergänge:** Im Vorher/Nachher sieht man an der Grenze zu Wiese und Weg einen Rand, weil die
  Übergangskacheln noch die alte Füllung enthalten. **So kann es noch nicht in die Szene.**
- **In Lichtinseln glitzert der alte Boden mehr.** Seine Blattfarben sind heller und gesättigter,
  liegen aber außerhalb der Palette. Den neuen Boden mit helleren Ockertönen zu versuchen (Gold dunkel
  als Blattlicht) habe ich getestet. Tagsüber wurde das wieder ein orange gesprenkelter Teppich, deshalb
  verworfen. Mehr Glimmen besser über Deko/Licht als über die Bodenkachel.
- Variante 1 ist mit 36 % die häufigste. Mit sehr gutem Auge sieht man ihr Muster auf großen
  leeren Flächen. In der echten Szene verdecken Bäume, Büsche und Gras das weitgehend.
- Pfütze und Hexenspur sind markant. Wenn sie stören: Anteil senken oder lieber von Hand als Deko setzen.

---

## 7. Vorschläge für die nächsten Schritte (nichts davon umgesetzt)

1. **Übergänge `meadow_forest_floor` und `forest_floor_path` neu erzeugen**, als Testdateien. Der
   Generator `calm.py` nimmt die Füllung als Eingabe, das ist überschaubar.
2. **TileSet** (erst nach deinem OK): Anteile als `probability` eintragen. Dazu je Variante eine
   *transponierte* Alternative (an der Diagonale gespiegelt). Dabei bleibt das Licht oben links, und
   aus 7 Varianten werden 14, ohne neue Grafik.
3. Dasselbe Verfahren für **Wiese** und **Weg**.
4. **Palettenentscheidung** für die Böden (Rampen nachtragen oder umfärben).
5. Auf Wunsch eine **separate Testszene** (`test_lakewood.tscn`), damit du die Kacheln in Godot
   ausprobieren kannst, ohne den Seewald anzufassen.

---

## Neue Dateien (nichts überschrieben)

```text
assets/environment/ground/test_lakewood/ground_lakewood_floor.aseprite
assets/environment/ground/test_lakewood/ground_lakewood_floor_1..7.png
docs/art/vorschau/test_lakewood_*.png                      (6 Vorschauen)
docs/art/ground_generator/seewald_waldboden.py             (Pixelentwurf)
docs/art/ground_generator/seewald_waldboden_plugin.py      (Ablauf über das pixel-plugin)
docs/art/ground_generator/kachel_pruefung.py               (Prüfskript)
docs/art/ground_generator/pruefbericht_test_lakewood.json  (alle Messwerte + Plugin-Protokoll)
docs/art/test_lakewood_bodentile.md                        (diese Datei)
```

Godot legt beim nächsten Öffnen für die neuen PNGs `.import`-Dateien an. Das ist normal und ändert
nichts an bestehenden Szenen. Die `.aseprite`-Datei ignoriert Godot.
