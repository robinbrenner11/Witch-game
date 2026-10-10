# Bitterbloom – Projektleitfaden für Claude Code

## 1. Vision

**Bitterbloom** ist eine 2D-Pixel-Art-Life-Sim über den Alltag einer jungen Hexe. Die Spielerin lebt in einem kleinen Hexenhaus, pflegt einen magischen Garten, baut Pflanzen an, sammelt Ressourcen, braut Tränke und entdeckt nach und nach die magische Welt. Später kommt ein Social-System dazu (NPCs mit Persönlichkeit, Beziehungen, Geschichten, Tagesabläufen).

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




# Hexen-Spiel – Ideensammlung

Sammlung aller bisherigen Ideen zum Spiel. Ergänzt `CLAUDE.md` (dort stehen die verbindlichen Regeln).

**Legende**
- ✅ **Entschieden** – gilt verbindlich
- 💡 **Idee** – von Robin gewünscht, Umsetzung später
- 🔮 **Vorschlag** – von Claude ergänzt, noch nicht entschieden

**Wichtig für Claude:** Nichts aus dem Bereich 💡/🔮 eigenmächtig bauen. Die Ideen dienen dazu, heutige Entscheidungen so zu treffen, dass diese Features später ohne Rewrite möglich sind.

**Neuere Entscheidungen** stehen in eigenen Dateien und gehen dieser Sammlung bei Widersprüchen vor:
- `docs/design/grimoire.md` (08.10.2026) – **neueste Quelle zum Grimoire**: Kapitel, Seiten, Opfer, Disziplinen, Hexenpfade, Optik, Technik
- `docs/design/game_design.md` (08.10.2026) – **neueste Quelle zum Gesamtdesign**: Kern-Loop, Mondphasen, Fortschritt, Digitalis, Kampf, NPCs, Lore, Umsetzungsreihenfolge. Überholt in dieser Sammlung u. a. Hexenpfade, Nahkampf, Altar und die Reihenfolge in Abschnitt 9
- `docs/auftrag_einbau_grafiken.md` (08.10.2026) – laufender Einbau der neuen Grafiken in Schritten
- `docs/design/design_entscheidungen_2026-10-07.md` – Tagesrhythmus, Bett, Garten, Nachtschatten, Hexenschlamm, Brauen, 5 Rezepte, Grafikregeln
- `docs/design/checkliste_basics.md` – was vor den großen Erweiterungen noch fehlt (abhaken, wenn erledigt)

---

## 1. Identität und Stil

✅ **Dark Cozy Witchcraft**: mysteriös, leicht düster, aber gemütlich. Nicht „Stardew mit Hexenhüten", nicht reines Gothic.
✅ 2D-Pixel-Art, Top-down, keine Isometrie, 32×32-Tiles
✅ Dunkle Welt mit warmen Lichtinseln; Cozyness durch den Kontrast zwischen Dunkelheit und Wärme
✅ Stimmung: mysteriös-sexy, aber cozy
✅ Figurenproportionen schlank
✅ Kamerazoom mittel (nicht ganz nah, aber nicht zu viel Welt)
✅ Palette und Farbsemantik: siehe `CLAUDE.md`

### Hauptfigur
✅ Stylische, selbstbewusste, dunkelhäutige moderne Hexe, **ohne Hut**
✅ Goldene Akzente auf der Haut, **komplett schwarze Finger** (als wäre sie von der Dunkelheit verschlungen)
✅ Akzentfarben Gold und Magenta, insgesamt sehr dunkel und divenhaft
✅ Konzeptskizze (ChatGPT) und erster Pixel-Sprite (Gemini) existieren

### Sound
✅ Dreamy, warm, leicht melancholisch, feminin/magisch, nachts, sinnlich, mysteriös, soft, etwas urban/modern
✅ Stimmungsreferenz: SZA – *SOS Deluxe: LANA*

---

## 2. Umgebung und Atmosphäre

💡 **Kristalle** – leuchtend, als Lichtquellen
💡 **Kerzen** – überall verteilt
💡 **Ranken** – an Gebäuden und in der Welt
💡 Insgesamt hexiger Look der Umgebung

🔮 Ausbau-Vorschläge:
- Kristalle in Magenta als magische Lichtinseln; in Dungeons/Höhlen häufiger; evtl. sammelbar als Zutat
- Kerzen auf Fensterbänken, Grabsteinen, Treppen; heruntergebrannt mit Wachsspuren; nachts eigene Lichtquelle
- Ranken an Hauswänden, Zäunen, Ruinen; magische Ranken, die mit dem Spielfortschritt mitwachsen oder Wege freigeben
- Weitere Deko: Pilzringe (leuchtend), Glühwürmchen, Bodennebel, Kräuterbündel unter Dächern, Knochen-Windspiele, Kessel mit Dampf
- Orte unterscheiden sich über Farbgewichtung (siehe `CLAUDE.md`): Garten grün-warm, Dorf Kerzenlicht/Gold, Friedhof Nachtblau/Magenta

---

## 3. Farming und Tränke (Kern des Spiels)

✅ Pflanzen mit mehreren sichtbaren Wachstumsphasen (Samen → Keimling → wachsend → erntereif)
✅ Mehrere Pflanzenarten
✅ Pflanzen dienen später für Tränke, Quests, Magie, Handel, Geschenke, Crafting, Ereignisse

**Umgesetzt (Stand 07.10.2026)** – Details in `docs/design/design_entscheidungen_2026-10-07.md`:
✅ Garten-Zustand im Autoload `Garden` (wächst auch ohne geladene Szene), Wachstum 1 Stufe pro Nacht, Ernte gibt 1 Samen zurück
✅ Nachtschatten-Aura: hemmt die 8 Nachbarn ab der Blüte, Nachbarn welken (Shader), neblige blaue Aura, mehrere verschmelzen
✅ Hexenschlamm = Dünger (1 Pflanze), Wachstumstrank 3×3, Mondernte 3×3 sofort reif; Magie macht den Mondkelch nicht reif
✅ Brau-Fenster am Kessel: mitwachsende Felder, Kapazität 3 als Datenwert, 5 Rezepte, bekannte Mischungen mit Namen, sonst ???
✅ Brauen über Nacht, Abholen am Kessel; Trinken mit Q/Rechtsklick (Irrlicht, Flüssiges Mondlicht, Ewige Nacht)
✅ Bett: Schlafen überspringt den Tag bis 18:00 und speichert (Nacht, Inventar, Garten, Kessel)
✅ Inventar-Fenster (Tab) mit Drag & Drop, Spiel pausiert bei offenen Fenstern

🔮 Leitgedanke: **Kampf und Fortschritt entstehen aus dem Garten.** Pflanzen → Tränke → Zauber/Buffs. Dungeon-Beute (seltene Samen, Rezepte, Kristalle) fließt zurück in den Garten.

---

## 4. Welt, NPCs und Social-System

✅ Größere Nachbarschaft wie ein kleines Dorf mit vielen verschiedenen Figuren
💡 Vampir-Nachbar (noch nicht ausgearbeitet)
✅ NPCs sollen sich wie Personen anfühlen: Persönlichkeit, Beziehungen, Tagesabläufe, Geheimnisse, Vorlieben (siehe `CLAUDE.md`)

### Sidequests
💡 NPC-Sidequests
🔮 Quests mit Atmosphäre und Charakter, z. B. „Bring mir eine Pflanze, die nur bei Vollmond blüht", oder Quests, die ein Geheimnis eines NPCs aufdecken
🔮 Zeitpunkt: nach dem Dialogsystem

---

## 5. Dungeons

💡 Dungeons mit coolen Belohnungen und Waffen
🔮 Hexige Orte: Gruften unter dem Friedhof, überwucherte Ruinen, Höhle mit leuchtenden Pilzen und Kristallen
🔮 Beute statt klassischer Waffen: Zauberstäbe, Grimoire-Seiten (neue Zauber), Hexenhüte/Umhänge mit Effekten, seltene Samen, Kristalle als Trankzutaten

---

## 6. Kampf und Magie

💡 Kampfsystem mit Magie (Hexe als Magierin)
🔮 Einstieg mit 2–3 Zaubern (z. B. Projektil, Flächenzauber, Schild); Mana oder Tränke als Ressource
🔮 Reiz durch Kombinationen (z. B. Giftzauber + Feuertrank → neuer Effekt) – passt zum Prinzip „Was passiert wohl, wenn ich das mache?"
🔮 Keine Schwerter/Nahkampf als Hauptsystem

---

## 7. Begleiter (Tiere und Wesen)

💡 Tiere oder magische Wesen als Begleiter, die Buffs geben
🔮 Als **Vertraute (Familiars)**: Katze, Rabe, Kröte, Fledermaus, später magische Wesen
🔮 Buffs nicht nur im Kampf, auch im Alltag:
- Kröte: Pflanzen wachsen schneller
- Rabe: findet seltene Items
- Katze: sieht versteckte Dinge in der Nacht
🔮 Eigene Persönlichkeit; Freischalten durch Füttern, Vertrauen, Quests
🔮 Gut geeignet als frühes, kleines cozy Feature (Tier folgt der Hexe + ein Gartenbonus)

---

## 8. Progression

### Begleiter leveln
💡 Begleiter können leveln
🔮 Höhere Stufen schalten **neue Fähigkeiten** frei statt nur höherer Zahlen (z. B. Kröte gießt erst ein Feld, später einen Bereich)
🔮 Leveln durch gemeinsame Zeit, Füttern mit Lieblingspflanzen aus dem Garten, Dungeon-Erfolge
🔮 Sichtbare Veränderung bei höherer Stufe (leuchtende Augen, Accessoire)

### Waffen leveln
💡 Waffen können leveln
🔮 Statt Waffen-XP lieber **Verzaubern/Aufwerten** an Arbeitstisch oder Altar mit Zutaten aus Garten und Dungeon (z. B. Kristall in Zauberstab einsetzen, Grimoire um Seiten erweitern)
🔮 Erzeugt Entscheidungen (Feuer- oder Giftkristall?)

### Hexenpfade / Skillbaum
💡 Start-„Zauber" wie ein Skillbaum, am Anfang wählbar – z. B. schnelleres Pflanzenwachstum, mehr Schaden oder mehr Sympathiepunkte bei NPCs
🔮 Drei Pfade/Zirkel, je mit Farbe aus der Palette:
- **Kräuterhexe** (Giftgrün): schnelleres Wachstum, mehr Ernte, bessere Tränke
- **Schattenhexe** (Magenta): mehr Zauberschaden, stärker in Dungeons
- **Herzhexe** (Bordeaux): mehr Sympathie, bessere Preise, Zugang zu Geheimnissen
🔮 Aufbau:
1. Start: Pfad wählen mit kleinem Bonus
2. Im Spiel: Skillpunkte über Level, Rituale oder Grimoire-Seiten
3. Fähigkeiten anderer Pfade lernbar, eigener Pfad nur günstiger
4. Optional: Ritual zum Pfadwechsel
🔮 Regeln: Keine Wahl sperrt Spielinhalte komplett; Pfade verschieben nur den Schwerpunkt

---

## 9. Vorgeschlagene Reihenfolge (🔮)

1. ✅ Beet und Pflanzenwachstum
2. ✅ Inventar, Ernte, Tränke brauen (Grundversion; Basics siehe `docs/design/checkliste_basics.md`)
3. Erster Begleiter: folgt der Hexe, gibt Gartenbonus
4. Dialog, NPCs, Sidequests
5. Startwahl Hexenpfad (sobald mind. Garten + NPCs existieren)
6. Kleiner Dungeon mit 2–3 Zaubern und einfachen Gegnern
7. Leveln der Begleiter, Verzaubern von Waffen, Skillbaum

---

## 10. Technische Leitplanken, damit später kein Rewrite nötig wird

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

---

## 11. Komfort und Einstellungen

💡 Größe der UI einstellbar (sehr viel später)
🔮 Nur ganzzahlige Stufen (1×, 2×, 3×), damit die Pixel scharf bleiben
🔮 Technisch: UI-Grafiken dafür in 1× speichern und die UI als Ganzes skalieren – die Hotbar-Grafiken sind aktuell noch in 2× vorskaliert und müssten dann einmal neu exportiert werden (Generator: `docs/art/ui_generator/hotbar.py`)
