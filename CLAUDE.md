# Bitterbloom – Projektleitfaden für Claude Code

## 1. Vision

**Bitterbloom** ist eine 2D-Pixel-Art-Life-Sim über den Alltag einer jungen Hexe. Die Spielerin lebt in einem kleinen Hexenhaus, pflegt einen magischen Garten, baut Pflanzen an, sammelt Ressourcen, braut Tränke und entdeckt nach und nach die magische Welt. Später kommt ein Social-System dazu (NPCs mit Persönlichkeit, Beziehungen, Geschichten, Tagesabläufen).

Zentrale Identität: **Dark Cozy Witchcraft**. Nicht einfach „cute", nicht einfach „dark". Die Welt soll mysteriös und leicht düster wirken, aber gemütlich. Sie soll **nicht** wie „Stardew Valley mit Hexenhüten" und auch nicht wie ein reines Gothic-Spiel aussehen.

Ziel ist nicht, möglichst viele Features zu bauen, sondern ein Spiel, das sich interessant, atmosphärisch und lebendig anfühlt. Bei mehreren möglichen Lösungen: die wählen, die langfristig zu einem interessanten, erweiterbaren und spielerisch befriedigenden Spiel führt.

## 2. Technischer Rahmen

- Engine: Godot 4.7, Sprache: GDScript
- 2D, Top-down, Pixel-Art, **32×32-Tiles/Sprites**
- Betriebssystem: Windows, Projektordner `C:\dev\Witch Game`
- Git-Repo ist angelegt; Remote auf GitHub (privat)

Soll-Einstellungen in Godot (bei Abweichung kurz Bescheid sagen):
- Default Texture Filter: **Nearest**
- Viewport 640×360, Stretch Mode `canvas_items`, Aspect `keep`
- Snap 2D Transforms to Pixel: an

Grundlegende technische Entscheidungen nicht stillschweigend ändern. Bei größeren Architekturentscheidungen kurz erklären: (1) Was ist das Problem? (2) Welche Lösung schlägst du vor? (3) Warum passt sie zu diesem Spiel?

## 3. Über mich (wichtig für deine Erklärungen)

- Ich kenne Python aus dem Studium, aber **kaum/keine Erfahrung mit Godot und GDScript**.
- Ich will Godot und GDScript wirklich lernen, nicht nur fertigen Code bekommen.
- Neue Godot-Konzepte (Nodes, Szenen, Signale, Groups, Resources usw.) beim ersten Auftreten kurz und verständlich erklären und sagen, warum wir sie brauchen.
- Nicht jede offensichtliche Codezeile erklären. Erklärungen kurz halten.
- Keine unnötig komplizierte Architektur.

## 4. Visuelle Identität (verbindlich)

Unveränderliche Grundregeln:
- 2D Pixel-Art, Top-down, **keine Isometrie**
- harte Pixelkanten, kein Anti-Aliasing, keine Gradienten
- ganzzahlige Skalierung
- Die Palette ist die Basis und bestimmt die Farbsemantik. Zwischentöne und passende Ergänzungen sind erlaubt, wenn sie Verläufe natürlicher machen (Schatten Richtung Blau/Violett, Lichter Richtung Warm). Keine weichen Gradienten. Richtwert 8–12 Farben pro Grafik. Neue Töne in `docs/art/hexen_palette.gpl` nachtragen.
- Licht grundsätzlich von **oben links**
- dunkle Aubergine-Outlines statt reinem Schwarz
- Lesbarkeit im Gameplay vor Detailreichtum, klare Charakter-Silhouetten

Palette:

| Farbe | Hex | Bedeutung |
|---|---|---|
| Tiefschwarz | `#0E0A14` | tiefster Hintergrund |
| Aubergine | `#2B1633` | Outlines, Schatten, Dorf |
| Nachtblau | `#141B3A` | Nacht, Kälte, Außenwelt |
| Bordeaux | `#6E1830` | bestimmte Charaktere, Stoffe, Vampirästhetik |
| Magenta | `#C2307A` | Magie |
| Gold | `#D9A441` | Wertigkeit, Dekoration, UI |
| Kerzenlicht | `#FFB566` | Wärme |
| Giftgrün | `#3F7D5A` | Pflanzen, Tränke |
| Knochen | `#EADFCB` | Text, helle Akzente |

Die Farbsemantik nicht ohne guten Grund ändern.

Licht: Die Welt ist dunkel, aber nicht flach. Warme kleine Lichtinseln (Kerzen, Laternen, Kessel, Fenster, magische Pflanzen, später Pilze/Kristalle). Cozyness entsteht durch den **Kontrast zwischen Dunkelheit und Wärme**, nicht dadurch, dass alles hell wird.

Orte teilen dieselbe visuelle Sprache und unterscheiden sich über Farbgewichtung, Licht, Deko und Atmosphäre:
- Garten: warm + dunkel + grün + magische Pflanzen
- Dorf: mehr Kerzenlicht, Aubergine, Gold
- Friedhof: mehr Nachtblau, weniger Wärme, Magenta als Gefahr/Magie

## 5. Entwicklungsphilosophie

Klein bauen, aber mit Zukunft:
- kleine Szenen, kleine Scripts, klare Verantwortlichkeiten
- einfache Datenstrukturen, wiederverwendbare Systeme, wenige Abhängigkeiten
- keine riesige Architektur, bevor Gameplay existiert
- keine „God Scripts"; wenn ein Script zu viel macht, Aufteilung vorschlagen
- Eine Szene = eine klare Aufgabe (Player, NPC, Plant, FarmTile, Item, Door, Chest, DialogueBox …)

Für den Prototyp ist eine einfache Lösung okay. Wenn eine Entscheidung aber sehr wahrscheinlich später zu einem Rewrite führt, weise mich darauf hin.

## 6. Ordnerstruktur

```text
assets/        characters, environment, plants, items, ui, effects
scenes/        player, world, buildings, npcs, plants, items, ui
scripts/       player, world, systems, npcs, plants, ui
data/          items, plants, npcs, dialogue
project.godot
```

Struktur darf wachsen, aber nicht für jede Kleinigkeit neue Ordner oder Abstraktionen anlegen.

## 7. Code-Regeln

- Idiomatisches, gut lesbares GDScript. Verständlich vor clever.
- Keine Design Patterns nur um Patterns zu haben.
- **Kommentare auf Deutsch**: erklären das *Warum*, ungewöhnliche Entscheidungen, wichtige Zusammenhänge. Keine Kommentare für Offensichtliches.
- Code-Namen auf **Englisch** nach Godot-Konvention (`player_position`, `growth_stage`, `interact()`, `harvest()`), keine künstlich deutschen Variablennamen.
- Erfinde keine Godot-Funktionen, APIs oder Dateien. Bei Unsicherheit: sagen, dass du unsicher bist, und die relevante Alternative nennen.

## 8. Game-Design-Prinzipien

Bei Gameplay und neuen Systemen nicht nur technisch denken. Frage dich: *Macht das das Spiel interessanter?* Wichtig sind:
- **Atmosphäre**: lebendig und geheimnisvoll
- **Discovery**: Dinge entdecken statt alles erklärt zu bekommen
- **Progression**: Neues schaltet sich sinnvoll frei
- **Entscheidungen**: nicht jede Aktion komplex, aber wichtige Entscheidungen haben Gewicht
- **Charaktere**: NPCs fühlen sich wie Personen an, nicht wie Händler mit Dialogbox
- **Interaktion**: oft das Gefühl „Oh, was passiert wohl, wenn ich das mache?"

### Farming (Kern des Spiels)
Pflanzen haben mehrere Wachstumsphasen: Samen → Keimling → wachsende Pflanze → erntereif (mindestens 3–4 visuell erkennbare Stufen). Pflanzen sind nicht nur Deko; sie dienen später für Tränke, Quests, Magie, Handel, Geschenke, Crafting und besondere Ereignisse.

### NPCs und Social-System (später)
NPCs nicht hart an einzelne Systeme koppeln. Denkbar: Freundschaften, Rivalitäten, Romanzen, Geschenke, persönliche Quests, Tagesabläufe, Beziehungen zwischen NPCs, Geheimnisse, individuelle Vorlieben. NPCs sollen sich nicht nur durch Name und Sprite unterscheiden, sondern auch durch Silhouette, Kleidung, Farbgebung, Animation, Sprache und Verhalten.

### Charakterdesign
Stylisch, selbstbewusst, leicht mysteriös, cozy, individuell. Jeder wichtige Charakter hat eine eigene Silhouette. Farbregel: **maximal 2 Hauptfarben + 1 Akzentfarbe**. Gameplay-Sprites dürfen stark vereinfacht sein; Dialogportraits detaillierter und emotionaler, aber in derselben Formensprache.

## 9. Kreative Vorschläge und Scope

- Du darfst und sollst gute Ideen einbringen (interessanter, atmosphärischer, intuitiver, schöner, technisch sauberer).
- Trenne klar zwischen **„notwendig"** und **„Vorschlag"**. Keine großen Gameplay-Entscheidungen eigenmächtig treffen.
- Bei neuen Ideen von mir kurz prüfen: Passt sie zum aktuellen Stand? Technisch einfach oder komplex? Echter Gameplay-Mehrwert? Kann sie später kommen? Blockiert sie aktuelle Arbeit? Wenn etwas besser später gebaut wird, sag es.
- Ich darf mich umentscheiden. Systeme möglichst so bauen, dass sie sich später ändern lassen.

## 10. Arbeitsweise bei Änderungen

1. Erst verstehen, was schon existiert.
2. Nur die nötigen Dateien ändern, keine unnötigen Refactorings.
3. Änderung testen, soweit möglich, und auf offensichtliche Fehler prüfen.
4. Danach kurz erklären:

```text
Geändert:
- (Dateien/Funktionen, kurz)

Warum:
(ein, zwei Sätze, was der Spieler/die Spielerin dadurch jetzt kann)

Zum Testen:
(was ich in Godot tun soll, um es auszuprobieren)
```

5. Nach jedem funktionierenden Schritt einen Git-Commit vorschlagen (kurze deutsche Commit-Message). **Nicht ohne meine Zustimmung pushen.**

Größere Vorhaben immer in kleine, einzeln spielbare Schritte teilen und vorher kurz den Plan nennen.

## 11. Wo was steht

**Zuerst `docs/START.md` lesen.** Dort steht der aktuelle Stand, welcher Branch gerade dran ist, die nächsten Schritte und welches Dokument welche Frage beantwortet. Nur die Dokumente lesen, die die Aufgabe wirklich braucht. `docs/archiv/` nur bei Bedarf (erledigte Aufträge, überholte Pläne, alte Ideensammlung).

Legende in den Design-Dokumenten: ✅ entschieden · 💡 Idee von Robin, später · 🔮 Vorschlag von Claude, nicht entschieden · ❓ offen · ❌ verworfen. Nichts aus 💡/🔮 eigenmächtig bauen.

## 12. Technische Leitplanken, damit später kein Rewrite nötig wird

- **Items als Datendateien** (Godot-Resources in `data/items/`) statt fest im Code – Samen, Tränke, Zauberstäbe, Hüte sind dann nur neue Einträge
- **Begleiter und Waffen als Datendateien**, in denen pro Stufe steht, was sich ändert – Balancing = Zahlen anpassen
- **Spielwerte nicht fest verstecken** (Wachstumszeit, Schaden, Geschwindigkeit, Sympathie), sodass Boni von außen darauf wirken können
- **`player.gd` klein halten** – Zaubern, Lebenspunkte usw. später in eigene Nodes/Scripts
- Buff- und Stat-System **noch nicht bauen**, nur im Hinterkopf behalten
- **Spielstand**: Jedes System liefert `get_save_data()` / `load_save_data()`, `SaveGame` sammelt nur ein. Neue Systeme mit Zustand (NPCs, Truhen …) genauso anbinden
- **Zustand, der Szenen überdauert, gehört in ein Autoload** (`Garden`, `Brewing`, `Inventory`, `DayCycle`); Szenen-Nodes zeigen ihn nur an
- **Orte**: Jeder Ort ist eine Level-Szene in `scenes/world/` (Ground, Objects, Exits; Wände und Kameragrenzen ergeben sich aus der bemalten Fläche). `scenes/main.tscn` hält Hexe, UI und Nachtfärbung und tauscht den Ort aus; Ausgänge (`scenes/world/exit.tscn`) verbinden die Orte
- **UI**: neue Grafiken in 1× speichern, Fenster mit `scale = 2` anzeigen (wie das Brau-Fenster); Inventar-Plätze über den Baustein `InventoryGrid`
- **Texte**: Spieltexte nie direkt, sondern als Schlüssel in `data/translations/texts.csv` (en/de). In Labels/Buttons steht der Schlüssel, im Code `tr("SCHLÜSSEL")`. Item-Namen sind Schlüssel (`ITEM_<ID>`)
- **Fortschritt**: Systeme melden Ereignisse mit `Grimoire.report("aktion", {"id": …})`; Boni fragen sie mit `Grimoire.get_stat()` ab. Nichts direkt in Disziplinen eintragen
- **Mond**: Mondphasen nur über den Autoload `Moon` abfragen (`Moon.is_full()`, `Moon.phase()`, Signal `phase_changed`), nie selbst aus der Nacht ausrechnen
- **Sound**: Effekte nur über den Autoload `Sfx` (`Sfx.play(id)`, `Sfx.play_at(id, position)`, Loops an Objekten mit `Sfx.make_loop_player(id)`). IDs sind Pfade unter `assets/audio/sfx/` ohne Endung, Varianten `_1.._n` wählt `Sfx` selbst. Atmo je Ort über den Export `ambience` am Level. Meldungen, bei denen etwas nicht geht, über `Messages.deny()`. Neue Effekte im Generator `docs/audio/sfx_generator/sfx.py` anlegen
- **Umgebung**: Deko als `Decor`-Szenen in `scenes/world/decor/` (Fußpunkt = Ursprung, Schatten, Kollision, Licht als Export-Werte); Sammelbares über `WildGrowth` + Autoload `Wilds`
- **Interaktion**: Was E an einem Objekt tut, liefert die Szene selbst über `func interaction_prompt() -> String` (Schlüssel `PROMPT_…`, leer = nur Klammern); der Interaktions-Hinweis zeigt es als „E Ernten“ an. Neue Interactables bekommen diese Methode. Siehe `docs/archiv/QUALITY_OVERHAUL.md`
- **Tasten in Texten**: nie fest hineinschreiben, sondern `%s` im Text und `InputHints.key_for("aktion")` einsetzen (stimmt dann auch nach Umbelegen)
- **Truhe**: Truhenplätze liegen im `Inventory` hinter der Tasche (`CHEST_START`, `chest_capacity`). `add`/`remove`/`count`/`has_room_for` sehen nur die Tasche; zwischen beiden Bereichen bewegt `move()` bzw. `transfer()`
- **Sonne**: draußen ab 6 Uhr Schaden (`SunExposure`), drinnen sicher über `Level.indoors`. Neue Innenräume brauchen `indoors = true`
- **Spielstand robust laden**: `load_save_data()` liest mit `data.get(…, Standard)` und sortiert Unbekanntes aus (umbenannte Items, entfernte Pflanzen). `SaveGame` schreibt über eine Zwischendatei und hält den vorletzten Stand als `.bak`
- **Kampf**: Digitalis-Formen und ihre Angriffe sind Daten (`data/digitalis/<form>.tres`, `DigitalisForm` + `AttackData`); eine neue Form ist eine neue Datei plus `Grimoire.learn_form()`. Kampftränke sind Items mit `use = THROW` oder `heal > 0`. Gegner gehören in die Gruppe `blighted` und haben `take_hit(damage, knockback, stagger)`; Angriffe kündigen sich sichtbar an (Telegraph). Neumond-Stärke nur über `Moon.blight_surges()`. Treffer an der Hexe über `Vitals.take_damage()`, die Rückmeldung macht `VitalsFeedback`. Details: `docs/COMBAT_SYSTEM.md`
- **Welt-Merker**: Was einmal passiert ist und so bleibt (Pforte offen, NPC kennengelernt), ist ein Flag im Autoload `WorldState` (`set_flag()`, `has_flag()`, Signal `flag_changed`; gespeichert). Für „höchstens einmal pro Nacht“ gibt es `mark_tonight()`/`did_tonight()` (nicht gespeichert). Freischaltungen nie fest verdrahten, sondern über Flags
- **NPCs und Dialoge**: NPC = Daten (`data/npcs/<id>.tres`, `NpcData` mit `ScheduleEntry`-Routine) + geerbte Szene von `scenes/npcs/npc.tscn`; Spots sind `Marker2D` unter `Spots` im Level. Gespräche sind Dateien in `data/dialogue/<npc>/` (`DialogueData`: Priorität, Bedingungen, Folgen). Zeit nur über `DayCycle.minutes`. Dialoge zeigt die `DialogueBox` (Gruppe `dialogue_box`, `await box.show_lines(name_key, lines)`), höchstens 3 Zeilen pro Seite; Auswahl mit `await box.choose(name_key, options)` (Index, -1 bei Esc). Tausch: Angebote als Daten in `data/trades/<npc>/` (`TradeOffer`), der NPC bietet sie nach jedem Gespräch an. Details: `docs/VILLAGE_HUB.md`
- **Gesperrte Wege**: `Exit` und `GardenGate` haben `required_flag`; ohne das Flag bleiben sie zu und melden `locked_message`
- **Sperren**: Wege, die man erst später öffnen kann, sind ein `Gate` (`scripts/world/gate.gd`): offen bei Flag, Mondphase, aktiver Trankwirkung (`PotionEffects.is_active("wisp")`) oder wenn der passende Trank daraufgegossen (E) bzw. geworfen wird (Gruppe `potion_target`, Methode `on_potion(item)`). Mit einem Trank geöffnet bleibt es über `required_flag` für immer offen. Vor einem `Exit` platziert, sperrt es einen Ortswechsel. Dunkle Orte über `Level.darkness`
- **Gesuche**: Zettel am Anschlagbrett sind Daten (`data/requests/<id>.tres`, `RequestData`: Absender, Item, Menge, Belohnungen als `RewardData`, Mondphasen, Flags für Ketten). Der Autoload `Requests` hängt sie auf und speichert sie; neue Gesuche brauchen keinen Code, nur Datei und Texte (`REQ_<ID>`, `REQ_<ID>_THANKS`, höchstens 3 Zeilen inklusive Status). Belohnungen von außerhalb des Buchs über `Grimoire.grant(reward)`
- **Höhen und Baupläne**: Höhe ist nur gemalt (wie Stardew): Wände, Ränder und Treppen liegen im TileMapLayer `Cliffs` mit Kollision auf Physik-Layer 4 `cliffs` (Bit 8). Alles, was laufen soll (Hexe, NPCs, Gegner), braucht dieses Bit in `collision_mask`; Zauber und Würfe bewusst nicht. Orte mit Höhen entstehen aus Bauplänen (`tools/world_builder/plans/<ort>/`, 1 Pixel = 1 Kachel) über den World-Builder; er überschreibt nur `Ground`, `Water`, `Depth`, `Cliffs` und `Objects/Generated`, Handarbeit gehört woandershin. Klippen-Grafiken haben ein festes Raster (`assets/environment/cliffs/cliff_layout.json`). Details: `tools/world_builder/LIESMICH.md`
