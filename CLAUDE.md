# Hexen-Spiel – Projektleitfaden für Claude Code

## 1. Vision

2D-Pixel-Art-Life-Sim über den Alltag einer jungen Hexe. Die Spielerin lebt in einem kleinen Hexenhaus, pflegt einen magischen Garten, baut Pflanzen an, sammelt Ressourcen, braut Tränke und entdeckt nach und nach die magische Welt. Später kommt ein Social-System dazu (NPCs mit Persönlichkeit, Beziehungen, Geschichten, Tagesabläufen).

Zentrale Identität: **Dark Cozy Witchcraft**. Nicht einfach „cute", nicht einfach „dark". Die Welt soll mysteriös und leicht düster wirken, aber gemütlich. Sie soll **nicht** wie „Stardew Valley mit Hexenhüten" und auch nicht wie ein reines Gothic-Spiel aussehen.

Ziel ist nicht, möglichst viele Features zu bauen, sondern ein Spiel, das sich interessant, atmosphärisch und lebendig anfühlt. Bei mehreren möglichen Lösungen: die wählen, die langfristig zu einem interessanten, erweiterbaren und spielerisch befriedigenden Spiel führt.

## 2. Technischer Rahmen

- Engine: Godot (vermutlich 4.x, Version in `project.godot` prüfen), Sprache: GDScript
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
- ganzzahlige Skalierung, begrenzte Farbpalette
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

## 11. Aktueller Stand

- Godot-Projekt eingerichtet, noch kein Gameplay
- Nächster Meilenstein: Hexe als Platzhalter-Quadrat läuft per WASD über eine leere Karte, danach Kamera, dann Beet mit Pflanzenwachstum
- Echte Grafiken entstehen separat (ChatGPT/Gemini); bis dahin Platzhalter nutzen
