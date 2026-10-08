# Auftrag: Neue Grafiken einbauen (Stand 08.10.2026)

Lies zuerst `CLAUDE.md` und `docs/ASSETS.md`. Dort steht zu jeder neuen Grafik, wie sie gedacht ist: Größe, Frames, FPS, Fußpunkt, Kollision, Licht. Die Grafiken liegen schon im Projekt. Bitte nichts an den PNGs ändern; wenn etwas nicht passt, sag Bescheid, dann wird der Generator angepasst.

Arbeite die Schritte **einzeln** ab. Nach jedem Schritt: kurz erklären (Geändert / Warum / Zum Testen), ich teste in Godot, dann Commit vorschlagen. **Nicht ohne meine Zustimmung pushen.** Vor jedem Schritt kurz den Plan nennen.

## Schritt 1: Aktions-Animationen der Hexe

ASSETS.md → „Aktionen der Hexe“ und „Effekt Zauber-Ausgießen“.

- `witch_sprite_frames.tres` um `pour_*`, `harvest_*`, `drink_*`, `snap_*` (je down/up/side) ergänzen, **ohne Loop**, FPS laut Tabelle. Nach `animation_finished` zurück auf `idle_<richtung>`.
- Auslösen: Ausgießen (E auf Pflanze mit Trank) → `pour`, Ernten → `harvest`, Trinken (Q/Rechtsklick) → `drink`. `snap` erst mal nur vorbereiten (wird für „Erde wecken“ gebraucht, das kommt später).
- Während einer Aktion nicht laufen können, die Aktion ist kurz.
- Zauber-Ausgießen: In Frame 3 von `pour` startet `pour_orb` am Orb-Startpunkt (Offsets stehen in ASSETS.md), fliegt per Tween im Bogen zur Pflanze (ca. 0,3 s). Dort spielen `pour_rain` und `pour_sparks`. Orb und Regen per `modulate` in der Trankfarbe einfärben, die Funken nicht. Bei 3×3-Tränken auf allen 9 Feldern, leicht versetzt.
- Die Wirkung des Tranks soll erst nach dem Regen eintreten, nicht schon beim Tastendruck.

## Schritt 2: Neuer Boden für Garten und Wald

ASSETS.md → „Böden v2“. Entscheidung: Gras ist keine Fläche mehr.

- `ground_tileset.tres` um die neuen Fülltiles (`earth`, `forest_floor`, `meadow`, je 1–5) und die drei Übergangs-Atlanten erweitern, als Terrain-Sets mit **Match Corners** (wie die bestehenden Übergänge).
- `garden.tscn` neu bemalen: Grundfläche `earth`, die Beete bleiben, ein paar Grasinseln (`meadow` über `earth`) am Rand und außerhalb des Gartens.
- `forest.tscn` neu bemalen: Grundfläche `forest_floor`, der Pfad bleibt (Übergang `forest_floor_path`), Grasinseln nur auf Lichtungen, mit **einer Kachel Abstand zum Pfad**.
- Für Wege im Garten bzw. über Grasinseln gibt es `transition_earth_path` und `transition_meadow_path`. Ein schmaler Trampelpfad vom Unterschlupf zu den Beeten und zum Wald-Ausgang passt gut.
- Vorlage für die Wirkung: `docs/art/vorschau/vergleich_garten_2x.png` und `vergleich_wald_2x.png` (jeweils die untere Hälfte).
- Ausgänge, Startpunkte und Kameragrenzen müssen danach noch stimmen.

## Schritt 3: Bäume, Büsche, Deko und Zaun

ASSETS.md → „Flora und Fauna“.

- Wiederverwendbare Szenen statt jedes Objekt einzeln, z. B. eine Szene für Bäume (Textur/SpriteFrames und Kollisionsgröße als Export-Variablen) und eine für kleine Deko. Fußpunkt am Ursprung, Y-Sort, Kollision nur am Fuß.
- Animierte Objekte bekommen im `_ready()` einen **zufälligen Startframe**, sonst wiegen alle im Gleichtakt. Bäume haben 8 Frames bei 6 FPS.
- **Bodenschatten** (ASSETS.md → „Bodenschatten“): Jede Objekt-Szene bekommt ihren Schatten als Kind-Sprite (Größe und Versatz laut Tabelle, `modulate.a = 0.5`, unter den Objekten). Das gilt auch für die **Hexe**, die Pflanzen auf den Beeten, Kessel, Lagerfeuer, Bett und Rezeptpult.
- Zaun als eigene `TileMapLayer` mit `fence_atlas.png` (Autotile, Index-Regel steht in ASSETS.md) um den Garten. An den Durchgängen zum Wald und zum Unterschlupf steht ein **Gartentor** (`fence_gate_h`/`fence_gate_v`) als eigenes Objekt: Es öffnet sich, wenn die Hexe davorsteht oder E drückt (bitte kurz fragen, was dir lieber ist), und ist zu nur dann ein Hindernis.
- Wald: dicht am Rand (Tannen, Eichen), Weide und toter Baum als Blickfang, Büsche, Farne, Stumpf, Stamm, Steine. Garten: Holunder, Nachtlavendel, Blumenbüschel am Zaun. Vorlage: die Mockups aus Schritt 2.

## Schritt 4: Leuchtpilze, Hexenring, Glühwürmchen

- Pilze und leuchtende Blumen mit `_glow`-Ebene (zweites `AnimatedSprite2D` mit `CanvasItemMaterial`, `light_mode = Unshaded`, gleiche FPS und gleicher Startframe) und einem `PointLight2D` mit dem vorhandenen `NightLight`-Script. Licht-Werte stehen in ASSETS.md.
- Hexenring im Wald auf einer Lichtung, die Mitte ist begehbar. Er ist **nur Deko**, keine Funktion einbauen.
- Glühwürmchen-Szene laut ASSETS.md: schweben langsam, blinken, nur nachts sichtbar (`DayCycle.night_factor()`). Ein paar im Garten, mehr im Wald.

## Schritt 4b: Ambient-Fauna

ASSETS.md → „Ambient-Fauna“. Reine Atmosphäre, keine Spielmechanik.

- Motten kreisen um Lichtquellen (Lagerfeuer, Glutpilze), nur nachts.
- Fledermaus fliegt nachts ab und zu durchs Bild.
- Eule auf dem toten Baum im Wald (Position steht in ASSETS.md), blinzelt und dreht zufällig den Kopf, Augen leuchten (Glow-Ebene).
- Kröte im Garten: sitzt, atmet, quakt manchmal, hüpft ein Stück weg, wenn die Hexe nah kommt.
- Kleine, einfache Scripts, alles über Export-Variablen einstellbar (Häufigkeit, Radius).

## Schritt 4c: Unterschlupf als hohler Uraltbaum

ASSETS.md → „Unterschlupf: hohler Uraltbaum“. Entscheidung steht in `docs/design/design_entscheidungen_2026-10-07.md`.

- **Außen:** `hollow_tree` am Gartenrand aufstellen. Der Ausgang `ToShelter` liegt direkt vor der Tür, Kollision links und rechts der Tür, Lichter an Tür, Fenster und Laterne.
- **Innen:** `shelter.tscn` umbauen. Raumgrafik als Hintergrund, begehbarer Boden als Ellipse, Ausgang `ToGarden` an der Tür unten. Möbel als einzelne Objekte mit Y-Sort (Teppich flach darunter). Das vorhandene Rezeptpult und die lose Seite bleiben und bekommen die Positionen aus ASSETS.md.
- Lichter innen: Mondstrahl durchs Astloch, Ofen, Kerzen, Glühwürmchen-Gläser (mit Glow-Ebenen).
- Dazu Feuerholz, Besen und Fußmatte (flach, wie der Teppich). Die Gläser hängen am Deckenbalken, der in der Raumgrafik steckt. Die Positionen stehen in ASSETS.md. Möbel bekommen Bodenschatten wie draußen.
- Die Truhe hat schon einen Offen-Frame, wird aber vorerst **nur Deko**. Lager-Funktion erst nach Rückfrage.
- Wenn der Spawn beim Szenenwechsel nicht mehr passt, Startpunkte anpassen: Man soll vor bzw. hinter der Tür erscheinen.

## Schritt 5: Wildgras und Unkraut

- `wild_grass_1–3`, `weed_thistle`, `weed_dock` als Objekte auf Erde, Waldboden und Grasinseln verteilen.
- Sie sollen sich **wegräumen** lassen (Interaktion wie bei anderen Objekten, die Hexe nutzt dafür die `harvest`-Animation).
- Was beim Wegräumen herauskommt und ob Wildgras nachwächst, ist **noch nicht entschieden**. Bitte erst fragen und bis dahin nur entfernen.
- Der Zustand (was weggeräumt ist) muss gespeichert werden, über `get_save_data()` / `load_save_data()` wie bei den anderen Systemen.

## Schritt 6: Sammelobjekte im Wald

ASSETS.md → „Sammelobjekte Wald“. Pilz, Beerenstrauch, Feder und Mondmoos haben Weltgrafik (mit Glitzern), einen Zustand nach dem Pflücken und ein Inventar-Icon.

- **Namen, Verwendung und Nachwachsen** stehen in `docs/design/game_design.md`, Abschnitt 6 (Ember Morel, Dusk Berries, Owl Feather, Moonmoss). Damit als Items in `data/items/` anlegen. Wo genau sie im Wald liegen, bitte kurz mit mir abstimmen.
- Der Zustand (gepflückt, Nächte bis zum Nachwachsen) muss gespeichert werden.

## Nicht einbauen (nur bereitlegen)

- **Begleiterin Katze** (`assets/characters/familiar/`): kommt laut Reihenfolge später.
- **Dialog-UI** (`assets/ui/dialog_*`): kommt mit den NPCs. Die Portraitgröße ist noch offen, der Rahmen ist deshalb ein 9-Slice.
