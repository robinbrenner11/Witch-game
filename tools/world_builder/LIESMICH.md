# World-Builder: Orte aus Bauplänen

Stand: 16.10.2026 (Höhen-Test W1). Plan dazu: `docs/design/overworld_plan.md`.

Ein Ort wird als kleines Bild entworfen, **1 Pixel = 1 Kachel**. Der Builder macht daraus Boden, Klippen, Mauern, Treppen und Deko in der Szene. Ändern heißt: Bild ändern, neu bauen.

## Bauplan anlegen

Ein Ordner pro Ort unter `tools/world_builder/plans/<ort>/` (der Ordner `plans/` wird von Godot nicht importiert):

| Datei | Pflicht | Inhalt |
|---|---|---|
| `plan.json` | ja | Zielszene und Einstellungen, siehe unten |
| `height.png` | ja | Höhe als Grauwert: **schwarz = 0 (tief), grau = 1 (normal), weiß = 2 (hoch)** |
| `ground.png` | nein | Boden. Farbe = Terrain-Farbe aus dem Boden-TileSet (Gras, Erde, Weg, Pflaster, Platten, Friedhof, Gartenerde, Waldboden, Wiese) |
| `material.png` | nein | Deckende Pixel = **Mauer** statt Fels. Gilt für die Wand am Südrand und die Ränder dieser Fläche |
| `marks.png` | nein | Einzelne Pixel auf transparentem Grund: Treppe, Laterne, Baum, Trauerweide, Busch, Stein |

Alle Bilder gleich groß. In Aseprite: eine Datei mit Ebenen `height`, `ground`, `material`, `marks` anlegen, ganz unten eine Ebene mit dem vergrößerten Ausschnitt der KI-Karte zum Abpausen. Dann jede Ebene einzeln als PNG speichern, zum Beispiel indem man nur diese Ebene sichtbar lässt und exportiert (die Ebene mit der KI-Karte vorher ausblenden). Wie das in deiner Aseprite-Version am schnellsten geht, schauen wir beim ersten echten Plan zusammen an.

**Palette:** `plans/bauplan_palette.gpl` in Aseprite laden (Palette → Laden). Darin stehen alle Höhen-, Boden-, Material- und Markierungsfarben mit Namen. Andere Farben ordnet der Builder der nächstliegenden zu (Boden) bzw. meldet sie (Markierungen).

`plan.json`, Beispiel `plans/height_test/plan.json`:

```json
{
 "scene": "res://scenes/world/test/height_test.tscn",
 "levels": 3,
 "default_level": 1,
 "default_ground": "forest_floor",
 "rows_per_level": {"rock": 2, "wall": 1}
}
```

Optional: `"ground_priority"` (Reihenfolge, welches Terrain sich an Ecken durchsetzt, Standard: Weg vor Platten vor Pflaster … vor Waldboden) und `"depth_shade": false` (tiefere Flächen nicht abdunkeln).

Die Zielszene muss es schon geben (Level mit `Ground` und `Objects`). Ausgänge, See, Wasserfall, Gegner, NPC-Spots usw. setzt man wie bisher von Hand in die Szene.

## Regeln

- **Wände entstehen am Südrand der höheren Fläche** und werden aus ihr herausgeschnitten: Fels 2 Reihen pro Stufe, Mauer 1 Reihe (`rows_per_level`). Zwei Stufen Unterschied = doppelt so hoch. Die begehbare Fläche oben ist also um die Wandhöhe kleiner als gemalt; die tiefere Fläche bleibt genau so, wie sie gemalt ist.
- **Nach Norden, Osten, Westen** gibt es nur einen schmalen Rand (6 px Kollision), keine sichtbare Wand.
- **Treppe:** ein Treppen-Pixel irgendwo auf die Wand malen (am einfachsten in die unterste Reihe der höheren Fläche). Die ganze Wandspalte wird dort zur Treppe. Mehrere Spalten nebeneinander = breite Treppe, die äußeren bekommen Wangen mit Kollision. Unter Treppen liegt Stein (Schrittgeräusch).
- Eine Wand braucht genug Fläche über sich. Ist die höhere Fläche schmaler als die Wand hoch, meldet der Builder das.
- Deko-Markierungen auf einer Wand werden ignoriert (mit Meldung).
- Gleicher Plan = gleiche Szene. Varianten (Bodenkacheln, welcher Baum) hängen fest an der Position, nicht am Zufall.

## Bauen

**Im Editor:** `tools/world_builder/build_in_editor.gd` im Skript-Editor öffnen, dann **Datei → Ausführen** (Strg+Umschalt+X). Baut alle Pläne. Ist eine betroffene Szene gerade offen, fragt Godot, ob sie neu geladen werden soll: Ja.

**Ohne Editor** (im Projektordner):

```text
godot --headless --script res://tools/world_builder/build.gd             # alle Pläne
godot --headless --script res://tools/world_builder/build.gd -- seewald  # nur einer
```

Meldungen (zu schmale Wand, Treppe nicht auf einer Wand, unbekannte Farbe) stehen in der Ausgabe.

**Was der Builder überschreibt:** nur `Ground`, `Depth`, `Cliffs` und `Objects/Generated`. Alles andere in der Szene bleibt, wie es ist. Deshalb Bäume, die bleiben sollen, entweder als Markierung in den Plan malen oder von Hand unter `Objects/Decor` setzen, nicht unter `Generated`.

## Was entsteht

| Node | Inhalt |
|---|---|
| `Ground` | Boden. Übergänge nur zwischen Terrains, für die es im Boden-TileSet einen Übergang gibt; sonst harte Kante (an Klippen liegt die unter der Wand) |
| `Depth` | Abdunklung tieferer Flächen: 1 bzw. 2 Stufen unter der höchsten Stelle im Ort |
| `Cliffs` | Wände, Ränder, Treppen, Schattenstreifen am Wandfuß. Kollision auf Physik-Layer 4 `cliffs` |
| `Objects/Generated` | Deko an den Markierungen (Bäume zufällig aus Tanne, Eiche, Holunder; Büsche, Steine, Graybox-Laternen) |

**Physik-Layer 4 `cliffs`:** Hexe, NPCs und Käfer prallen ab (`collision_mask` enthält Bit 8). Zauber und geworfene Tränke fliegen darüber, man kann also von oben hinunterzaubern (Entscheidung 16.10.2026).

## Grafiken der Klippen tauschen

- Atlanten: `assets/environment/cliffs/cliff_rock.png` (Fels) und `cliff_wall.png` (Mauer), je 8 × 8 Felder à 32 px, gleiches Raster. Welches Feld was ist: `cliff_layout.json`, als Bild mit Namen: `docs/art/cliff_generator/vorlage_raster.png`.
- Übermalen und unter demselben Namen speichern. Neu bauen ist nicht nötig, die Szenen zeigen auf die Felder.
- Nur wenn sich das Raster ändert (neue Felder): `docs/art/cliff_generator/cliffs.py` anpassen, dann `godot --headless --script res://tools/world_builder/make_cliff_tileset.gd` (baut `cliff_tileset.tres` mit Kollision) und die Orte neu bauen.
- Licht von oben links: obere Kante hell, rechte Kanten und Fuß dunkler. Wandfuß-Schatten und Abdunklung sind halbtransparent.
