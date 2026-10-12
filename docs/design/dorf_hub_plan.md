# Dorf-Hub – Phase 1: Analyse und Plan

Stand: 12.10.2026 · Basis: `main` (`7da1e42`, seit 12.10. mit `combat-overhaul` und `quality-overhaul`) · Umsetzung auf Branch `village-hub` · Entscheidungen von Robin in Abschnitt 9

Legende: ✅ vorhanden (im Code geprüft) · ❌ fehlt · 📐 abgeleitet aus den Design-Dokumenten · 🔮 neuer Vorschlag (nicht entschieden) · ❓ offen

---

## 1. Vorhandener Projektstand

### 1.1 Was es gibt (✅)

| Bereich | Stand | Bedeutung fürs Dorf |
|---|---|---|
| Technik | Godot 4.7, GL Compatibility, Viewport 640×360 (`canvas_items`), Nearest, Pixel-Snap, Tiles 32×32 | Sichtfeld ca. 20 × 11 Kacheln |
| Welt | `main.tscn` hält Hexe, UI und `NightTint` und tauscht genau einen `Level`. Orte: Unterschlupf (innen, 640×360), Garten 28 × 30 Kacheln, Wald 34 × 26 Kacheln. Unterschlupf ↔ Garten (Nordausgang) ↔ Wald (Südausgang) | Dorf = vierter `Level` nach demselben Muster |
| Übergänge | `Exit` (Area2D) mit `target_scene`, `target_exit`, `spawn_offset`; Überblendung in `Main.travel()`. **Keine Sperrbedingung** | Gesperrte Wege brauchen eine Bedingung am `Exit` |
| Kamera, Ränder | `Camera2D` an der Hexe (kein Zoom). Kameragrenzen und Wände ergeben sich aus der bemalten Fläche, `hud_margin_bottom` = 64 px in Garten und Wald | Dorfgröße frei malbar, unten 2 Kacheln HUD-Rand |
| Bewegung, Kollision | Laufen 80 px/s, Schweben ×2,5. Physik-Layer `world`, `interactable`, `enemies`. `Decor` mit Kollision, Schatten und Licht als Exporte | Graybox-Häuser sind Kollisionskästen |
| Interaktion | `Interactable` (Area2D, Layer 2, Signal `interacted`). Die Hexe nimmt das nächste in ihrer `InteractionArea`. Text über `interaction_prompt()` → `PROMPT_…` („E Lesen“). Im Kampfmodus aus | NPC und Schild bekommen je ein `Interactable` |
| Spielzeit | `DayCycle`: Minuten seit Mitternacht, Nacht ab 18:00, neues Spiel 20:00, 1 Spielminute pro Sekunde, Warnung 5:00, Morgen 6:00, Zeitraffer am Hexenfeuer, Trank „Ewige Nacht“. Signal nur `day_passed` | Routinen lesen `DayCycle.minutes`. **Kein zweites Zeitsystem** |
| Mond | `Moon`: 8 Nächte, `phase()`, `is_half()`, `is_full()`, `nights_until()`, Signal `phase_changed`, `blight_surges()` | Dialoge und später der Markt hängen an der Phase |
| Sonne | `SunExposure`: draußen ab 6:00 Schaden, sicher nur bei `Level.indoors` | Das Dorf ist draußen, der Heimweg zählt |
| Spielstand | `SaveGame` sammelt `get_save_data()` / `load_save_data()` von DayCycle, Inventory, Garden, Brewing, Grimoire, Wilds. Zwischendatei und `.bak`. Gespeichert beim Schlafen und im Pausemenü. Der Ort wird nicht gespeichert, man wacht immer im Unterschlupf auf | Neuer Teil `world` mit je einer Zeile in drei Funktionen |
| Fortschritt | `Grimoire`: `report(aktion, {id})` → Erfahrung und Zählstände (`count_of`), Seiten, Ziele, Formen. `hint_ingredient()` für Gerüchte ist da, **wird aber noch nirgends aufgerufen**. `RewardData.LOCATION` existiert als Typ, wird nicht angewendet. `visit` gibt beim ersten Besuch eines Orts Wildcraft-Erfahrung | NPC-Gespräche melden `report("talk")`, Gerüchte nutzen `hint_ingredient()`, ein neuer Ort zählt automatisch |
| Inventar | 24 Plätze plus Truhe, `add`, `remove`, `count`, `has_room_for`, Items als Daten | Für späteren Tausch nutzbar |
| Fenster | UI-Fenster unter `main.tscn/UI` mit `process_mode = Always`. Öffnen setzt `get_tree().paused` (stoppt auch die Uhr), gefunden werden sie über Gruppen (z. B. `chest_window`). Das Pausemenü geht nicht auf, solange pausiert ist | Dialogbox nach genau diesem Muster |
| Texte | Alle Spieltexte als Schlüssel in `data/translations/texts.csv` (en/de) | Dialogzeilen sind Schlüssel |
| Atmosphäre | `NightLight` (nur nachts, Flackern), Lichttexturen `light_round_32/64/128`, Glühwürmchen, Motten, Fledermaus, Kröte. Böden `cobble` (laut ASSETS.md „Dorf“), `slab`, `path`, `meadow`, Übergang Pflaster ↔ Weg. Zaun-Tileset, `garden_gate.tscn`. Atmo-Loops `night`, `forest`, `shelter`. Eine Musik für alle Orte | Dorf-Graybox komplett ohne neue Grafik möglich |
| Dialog-Grafiken | `assets/ui/dialog_*`: Panel (9-Slice), Ornament, Namensschild, Portraitrahmen und -grund, Weiter-Pfeil (4 Frames), Cursor, Auswahlfeld | Dialogbox braucht keine neuen Grafiken |

### 1.2 Was fehlt oder unklar ist (❌)

- **NPC-System:** nichts. `scenes/npcs`, `scripts/npcs`, `data/npcs`, `data/dialogue` enthalten nur `.gitkeep`.
- **Dialogsystem:** nur die Grafiken, keine Szene, kein Script. Portraits fehlen, ihre Größe ist offen.
- **Quests:** keine. Es gibt nur die vier ersten Ziele im Grimoire (`GOALS`).
- **Freischaltungen** von Orten, Gebäuden oder NPCs: keine. Keine allgemeinen Welt-Merker (Flags).
- **Tausch und Halbmondmarkt:** nicht gebaut, `Moon` meldet nur die Phase.
- **Dorf:** keine Szene, keine Gebäudegrafiken.
- **Grimoire-Kapitel People:** nur Platzhalter-Silhouetten (`SpreadSilhouettes`).
- **Automatische Tests:** keine im Repo, die Tests der beiden Overhauls liefen einmalig.
- **Branch-Stand:** `combat-overhaul` und `quality-overhaul` sind nicht in `main` gemergt (138 geänderte Dateien).

### 1.3 Abgeleitete Anforderungen (📐)

1. **Nur nachts** (game_design 1–2): Das Dorf lebt zwischen 18 und 6 Uhr. Ab 6 Uhr brennt draußen die Sonne, also gehen NPCs gegen 5 Uhr heim, und der Weg nach Hause muss kurz sein.
2. **Wenige Menschen** (game_design 8): ein kleines Menschendorf am Rand, nur ein paar sind nachts wach; das Nachtvolk lebt im Wald. Lebendigkeit entsteht also über Licht, Geräusche und Spuren von Leben, nicht über viele Figuren.
3. **Passender erster Bewohner:** der Nachtwächter, „einziger Mensch, der nachts durchs Dorf geht“, Funktion Gerüchte und Ankündigungen, ab Anfang da.
4. **Halbmondmarkt** bringt Dorf und Nachtvolk zusammen (✅). Der Ort ist nicht festgelegt.
5. **Neue NPCs nur durch eine Aktion der Spielerin** (✅), nie einfach nach Zeit.
6. **Tausch statt Geld**, Schwerpunkt auf verteilten NPCs mit wechselnden Gesuchen (✅).
7. **Große Freischaltungen** bringen eine neue Aktion oder einen neuen Ort (✅).
8. **Gerüchte** sind einer der drei Wege zu Rezepten (✅) → `Grimoire.hint_ingredient()`.
9. **Dorf-Optik:** mehr Kerzenlicht, Aubergine, Gold, warme Lichtinseln (CLAUDE.md 4).
10. **Spannung zum Auftrag:** Die Akt-Struktur (💡) legt das Dorf in Akt 2 und „Weg ins Dorf“ in Zyklus 1–2. Der Auftrag will ein grundsätzlich zugängliches Dorf als Hub → Entscheidung 9.2.
11. **Überholt:** „Menschendorf am Tag“ (design_entscheidungen 07.10.). Es gilt game_design 08.10.: Das Dorf lebt nachts.

---

## 2. Dorf-Layout (🔮)

**Größe:** 36 × 26 Kacheln = 1152 × 832 px, etwa 1,8 × 2,3 Bildschirme (Wald 34 × 26, Garten 28 × 30). Einmal quer durch ca. 14 Sekunden. Die untersten 2 Zeilen sind HUD-Rand (`hud_margin_bottom = 64` wie in Garten und Wald). Ein Zeichen = eine Kachel.

```text
     0         1         2         3     
     012345678901234567890123456789012345
  0  TT..TTTTTTTTTTTTTTTTTTTTTTTTTTTT..TT
  1  TTH|TTTTTTTTTTTTTTTTTTTTTTTTTTTTFFTT
  2  TT..,,,,,,,,,,,,,,,,,,,,,,,#####..TT
  3  TT..,,,,,,,#####,,,,,#####,#KA##..TT
  4  TT..,,,,,,,#H1##,,,,,#H2##,#####..TT
  5  TT..,#####,#####,,,,,#####,#####..TT
  6  TT..,#WA##,#####,,,,,#####,#####..TT
  7  TT..,#####,#wDw#,,,,,#wDw#,#####..TT
  8  TT..,#####,,,.,,o,,,,,,.,,,##D##..TT
  9  TT..,#wDw#,,,.========,.,,,,,.,,..TT
 10  TT..,,,.,,o,,.=======N,.o,,,,3,,..TT
 11  TT..o,,1,,,,,.========,.,,,,,.,,..TT
 12  <================BB================L
 13  <================BB================L
 14  TT4.,,,,,,,,,.========,,,,,5,,,o,,TT
 15  TT,.,,,,,,,,,.===2====,mmmmmmmm,,,TT
 16  TT,.#####,o,,.========,mmmmmmmm,,,TT
 17  TT,.#WS##,,||.||o,,....mmmmmmmm,,,TT
 18  TT,.#####,,|***|,,,,,,,mmmmmmmm,,,TT
 19  TT,.#####,,|***|,,,,,,,mmmmmmmm,,,TT
 20  TT,.##D##,,|||||,,,,,,,,,,,,,,,,,,TT
 21  TT,....,,,,,,,,,,,,,,,,,,,,,,,,,,,TT
 22  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 23  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 24  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 25  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

**Boden und Objekte:** `T` Waldrand (vorhandene Baum-Deko) · `,` Wiese · `.` Trampelpfad · `=` Pflaster (`cobble`) · `#` Gebäude (Graybox) · `D` Tür · `w` Fenster mit Licht · `o` Laterne (`NightLight`) · `B` Brunnen · `N` Anschlagbrett · `m` Marktfläche · `|` Zaun · `*` Kräutergärtchen · `~` HUD-Rand
**Gebäude:** `WA` Wachstube · `H1`, `H2` Wohnhäuser · `KA` Kapelle · `WS` Werkstatt
**Ausgänge:** `<` Waldtor → Wald (offen) · `H` Hexenpforte → Garten (🔒 erste Freischaltung) · `F` Nordpfad → Kapelle/Friedhof (🔒 Erweiterung) · `L` Landstraße (🔒 Erweiterung)
**Spots des Nachtwächters:** `1` Wachstube · `2` Brunnen · `3` Kapellenweg · `4` Waldtor · `5` Markt. Die geraden Wege zwischen den Spots seiner Routine kreuzen kein Gebäude, keine Laterne und keinen Brunnen (per Skript gegen die Skizze geprüft).

**Lage in der Welt:**

```text
   [Unterschlupf]
         |
     [Garten] ---- Hexenpforte (🔒) ----+
         |                              |
      [Wald] ------ Ostrand (offen) -- [Dorf] -- Landstraße (🔒)
                                        +-- Nordpfad (🔒, Kapelle/Friedhof)
```

**Anbindung, im Code geprüft:**
- **Wald (gebaut in M1, geändert gegenüber dem ersten Entwurf):** Ein Trampelpfad zweigt im oberen Drittel vom Hauptweg nach Osten ab (Höhe ca. y 208) und endet am Ausgang `ToVillage` (1072, 208). Der erste Entwurf lag bei y ≈ 600; dort hätte der Weg durch den Käferbereich (`BlightPatch` 400–720 / 560–730) geführt. Drei Deko-Objekte sind dafür ein Stück gerückt (`BushBerries1`, `Bush12`, `TreeFir16`), die Mondwiese rechts ist um eine Ecke kleiner.
- **Garten:** Der Zaun umschließt die Kacheln x 15–35 / y 5–19. Östlich davon (x 36–39) liegt ein freier Streifen, der vom Vorplatz des Uraltbaums aus erreichbar ist. Dort am Ostrand, ca. (1264, 200), kommt der Ausgang zur Hexenpforte hin, **ohne Umbau des Zauns**. Ob Deko den Weg versperrt, prüfe ich beim Bau im Editor.

**Graybox (verbindliches Budget):** Gebäude = `StaticBody2D` mit Kollisionskasten und einer Farbfläche in Aubergine/Bordeaux. Fenster = kleine Farbfläche in Kerzenlicht plus vorhandenes `NightLight` mit `light_round_64.png`. Laternen = kleiner Pfosten plus `NightLight`. Boden, Bäume, Zaun und Tor aus vorhandenen Tiles und Szenen. **Keine neue PNG-Datei.**

---

## 3. Orte und ihre Funktionen

| Ort | Funktion | Herkunft | Zustand zu Beginn | Später |
|---|---|---|---|---|
| Waldtor `<` | Eingang vom Wald, Spot 4 (der Wächter schaut in den Wald, wo sein Bruder verschwand) | 📐 | offen | – |
| Hauptstraße mit Laternen | Orientierung, warme Lichtinseln | 📐 Optik | offen | Laternen gehen abends nacheinander an 🔮 |
| Wachstube `WA` | Zuhause des Nachtwächters, Spot 1 | 📐 | von außen, kein Innenraum | Innenraum 🔮 |
| Dorfplatz mit Brunnen `B` | Treffpunkt, Herz des Hubs, Spot 2 | 🔮 | offen | – |
| Anschlagbrett `N` | Zuerst ein Aushang zum Lesen (Testobjekt für die Dialogbox in M3) | 🔮 | Text | Gesuche wie im Tausch-Konzept B: jede Nacht ein kleines Ziel 🔮 |
| Wohnhäuser `H1`, `H2` | Fensterlichter, die zu festen Uhrzeiten an- und ausgehen: Leben ohne weitere Figuren | 🔮 | verschlossen | Bewohner, wenn eine Aktion sie bringt |
| Kapelle `KA`, Nordpfad `F` | Spot 3 am Kapellenweg. Der Pfad führt später zu Kapelle oder Friedhof (in CLAUDE.md erwähnt, laut game_design nicht verworfen, aber nicht eingeplant) | 🔮 | Pfad gesperrt | Erweiterungsgebiet |
| Marktfläche `m` | Ort für den Halbmondmarkt (✅ entschieden, Ort bisher offen), Spot 5 | 📐 / 🔮 | leere Fläche | Stände erscheinen bei Halbmond, Ugo und Wanderer |
| Werkstatt `WS` | leerstehend, Platz für Gnarls Digitalis-Upgrades | 🔮 | verschlossen | Freischaltbarer Dienst |
| Kräutergärtchen `*` | Sammelstelle über das vorhandene `WildGrowth` / `Wilds` mit vorhandenen Wildpflanzen | 🔮 | später | eigene Dorf-Ressource |
| Hexenpforte `H` | Abkürzung in den Garten, vor zehn Jahren von den Dorfbewohnern verriegelt | 🔮 | 🔒 | **erste Freischaltung** |
| Landstraße `L` | Von hier kommen Händler und Wanderer zum Markt (erzählerisch) | 🔮 | 🔒 | Erweiterung |

**Warum man wiederkommt:** jede Nacht ein Gerücht beim Wächter (Rezept-Hinweis oder Ankündigung), die Abkürzung als schnellster Weg zwischen Garten und Dorf, später alle 8 Nächte der Halbmondmarkt, Gesuche am Anschlagbrett und Gnarls Werkstatt.

---

## 4. Erster NPC: der Nachtwächter

**Wer (📐):** einziger Mensch, der nachts durchs Dorf geht. Funktion: Gerüchte, Ankündigungen. Lore: Sein Bruder ging vor zehn Jahren in den Wald und kam nie zurück. Ab Anfang da.

**Darstellung (🔮, Graybox):** schmale Farbfläche ca. 16 × 40 px in Bordeaux mit Aubergine-Kontur, dazu eine Laterne als vorhandenes `NightLight` (warm `#FFB566`, `light_round_64.png`). Man erkennt ihn nachts als wandernde Lichtinsel. Ohne Portrait.

**Tagesroutine (🔮, feste Zeitblöcke):**

| Ab | Ort | Tätigkeit | Dialog-Thema |
|---|---|---|---|
| 18:00 | Spot 1 Wachstube | beginnt die Schicht | – |
| 20:00 | Spot 2 Brunnen | Pause, Gerüchte | `rumor` |
| 23:00 | Rundgang 2 → 5 → 3 → 2 | Streife über Markt und Kapellenweg | – |
| 02:00 | Spot 4 Waldtor | Wache, schaut in den Wald | `forest_gate` |
| 05:00 | Spot 1 Wachstube | Schichtende, geht hinein | `dawn` |
| 06:00–18:00 | nicht da | schläft | – |

**Gespräche (🔮, Inhalt der ersten Fassung):**

| Gespräch | Bedingung | Inhalt | Wirkung |
|---|---|---|---|
| `first_meeting` | einmalig, höchste Priorität | misstrauisch („Das Mädchen aus Mother Blights Garten?“), dann pragmatisch: Er schiebt den Riegel der alten Pforte zurück | Flag `witch_gate_open` |
| `rumor_*` (2–3 Stück) | nach dem Kennenlernen, je einmalig, höchstens eins pro Nacht | Gerücht über eine Zutat eines unbekannten Rezepts | `Grimoire.hint_ingredient()` |
| `moon_new`, `moon_full` | Mondphase | Neumond: „Heute Nacht ist es dunkler als sonst.“ Vollmond: „Der Ring im Wald leuchtet.“ Beides gibt es im Spiel schon | – |
| `forest_gate` | Zeitblock Waldtor | Andeutung zum Bruder | – |
| `dawn` | Zeitblock 5–6 Uhr | „Geh heim, bevor die Sonne kommt.“ | – |
| `smalltalk` | immer, Rückfall | 2–3 Alltagszeilen, zufällig | – |

**Was er testet:** Ansprechen, Dialog, Funktion und Standort, Routine mit Zeitblöcken, Dialog abhängig von Fortschritt (Flag), Mond und Uhrzeit, eine Freischaltung.

---

## 5. Minimaler technischer Aufbau (🔮)

### 5.1 Überblick

```text
Vorhanden, nur abfragen/aufrufen      Neu
---------------------------------     ----------------------------------------------
DayCycle.minutes, Moon.phase()        WorldState (Autoload): Flags + Spielstand
Grimoire.report(), hint_ingredient()  NpcData, ScheduleEntry, DialogueData (Resources)
SaveGame (+ Teil "world")             Npc (Szene + Script), DialogueBox (UI)
Exit, GardenGate (+ required_flag)    Village (Level) mit Spots (Marker2D)

data/npcs/watchman.tres               Name, Rolle, Routine
data/dialogue/watchman/*.tres         ein Gespräch pro Datei (neuer Inhalt = neue Datei)

Village (Level)
├─ Ground, Objects (Y-Sortierung)
│   └─ Watchman (npc.tscn): Körper, Interactable, Laterne
├─ Spots: WatchHouse, Well, Chapel, ForestGate, Market   (Marker2D)
└─ Exits: ToForest (offen), ToGarden (required_flag)
```

### 5.2 `WorldState` – Welt-Merker (neues Autoload, ca. 40 Zeilen)

- `set_flag(id)`, `has_flag(id)`, Signal `flag_changed(id)`, `reset()`, `get_save_data()`, `load_save_data()` (mit `data.get(…, Standard)` wie die anderen).
- In `SaveGame` je eine Zeile in `new_game()`, `save_game()` und `_apply()`. Alte Spielstände ohne `world` laden weiter, kein Versionswechsel nötig.
- **Warum nicht ins Grimoire?** Das Grimoire ist der Spielstand des Buchs und hat schon 565 Zeilen (CLAUDE.md: keine God Scripts). Flags sind Weltzustand. Bedingungen dürfen aber Grimoire-Werte lesen (`count_of`, `is_page_found`), wenn eine Freischaltung später an eine Seite gebunden wird.
- Namen: kurze englische IDs, z. B. `witch_gate_open`, `met_watchman`, `dlg_watchman_first_meeting`.

### 5.3 NPC und Tagesroutine

- **`NpcData`** (`data/npcs/<id>.tres`): `id`, `name_key`, `role_key`, `appears_flag` (leer = von Anfang an, sonst erst nach einer Spieleraktion), `schedule: Array[ScheduleEntry]`, `walk_speed` (ca. 40 px/s), `portrait` (optional).
- **`ScheduleEntry`** (eingebettet): `start_hour`, `level` (z. B. `"Village"`), `spot`, `patrol: Array[String]` (optional, wird im Kreis gelaufen), `topic` (optional, Dialog-Thema).
- **Aktueller Block:** Die Uhrzeit wird in „Minuten seit 18 Uhr“ umgerechnet. So ist 23:00 bis 02:00 kein Sonderfall über Mitternacht. Ab 6 Uhr gibt es keinen Block, der NPC ist weg.
- **Beim Laden des Orts** steht der NPC sofort am Spot seines aktuellen Blocks (kein Nachsimulieren des Wegs). Gehört der Block zu einem anderen Ort, ist er hier unsichtbar. Das macht spätere Ortswechsel von NPCs ohne Umbau möglich.
- **Solange man zusieht** prüft der NPC regelmäßig den Block. Wechselt er, läuft der NPC in geraden Linien von Spot zu Spot. Spots werden so gesetzt, dass die Linien frei sind, sonst kommt ein Zwischenspot dazu. **Kein Navigationsnetz**; `NavigationAgent2D` wäre der Ausbau, falls die Wege komplizierter werden.
- **Körper:** `CharacterBody2D` auf Layer `world`, damit die Hexe nicht durchläuft. Steht sie im Weg, wartet er kurz. Ausgänge und Tore reagieren weiter nur auf die Hexe (`body is Player`).
- **Ansprechen:** `Interactable` als Kind, `interaction_prompt()` liefert `PROMPT_TALK`. Während des Gesprächs bleibt er stehen, durch die Pause sowieso.
- **Zeitsprung zum Testen:** Debug-Taste F6 (frei, F1–F5 sind belegt) springt eine Stunde weiter, nur in Debug-Builds wie N und F1–F5.

### 5.4 Dialog

- **`DialogueData`** (`data/dialogue/<npc>/<id>.tres`, geladen über das vorhandene `DataFolder.load_all()`): `id`, `lines: Array[String]` (Text-Schlüssel), `priority`, `once`, `requires_flags`, `blocked_by_flags`, `moon_phase` (−1 = egal), `topic`, `sets_flag`, `hint_recipe` und `hint_ingredient`.
- **Auswahl:** alle Gespräche, deren Bedingungen gerade passen, das mit der höchsten Priorität gewinnt. Einmalige merken sich über ein Flag, dass sie gesagt sind; „höchstens ein Gerücht pro Nacht“ ist ein Flag mit der Nachtnummer. `smalltalk` ist der Rückfall, also gibt es nie „nichts zu sagen“. Die Auswahl steckt in `DialogueData`, damit `npc.gd` klein bleibt.
- **Wirkung nach dem Gespräch:** `sets_flag` setzen, Gerücht an `Grimoire.hint_ingredient()`, `Grimoire.report("talk", {"id": npc_id})` (gibt vorerst keine Erfahrung, wird aber gezählt und dient später dem Kapitel People), Flag `met_<npc>`.
- **`DialogueBox`** (`scenes/ui/dialogue_box.tscn`): unter `main.tscn/UI`, Gruppe `dialogue_box`, `process_mode = Always`, pausiert wie die Truhe und blendet die Uhr aus. Panel 9-Slice aus `dialog_panel.png`, Namensschild, wippender Weiter-Pfeil. Grafiken in 1×, Anzeige mit `scale = 2` wie das Brau-Fenster (Mockup 304 × 70). E, Leertaste oder Klick: nächste Zeile; Esc schließt. Portraitrahmen nur, wenn ein Portrait da ist. Antwort-Auswahl (Grafiken liegen bereit) kommt erst mit dem Tausch.

### 5.5 Freischaltungen

| Art | Umsetzung | Baustein |
|---|---|---|
| Dorf grundsätzlich zugänglich | `Exit` Wald ↔ Dorf ohne Bedingung | vorhanden |
| Gebiete | `Exit.required_flag` + Meldung, solange zu (kein Ortswechsel). `GardenGate.required_flag`: bleibt zu und meldet „verriegelt“ | 2 kleine Exporte |
| Gebäude, Dienste | später ein kleiner Baustein `Unlockable`, der sein Elternobjekt erst zeigt bzw. benutzbar macht, wenn ein Flag oder eine Mondphase passt (Marktstände, Anschlagbrett-Gesuche, Werkstatt) | erst M8 |
| NPC-Interaktionen | `DialogueData.requires_flags`, `NpcData.appears_flag` | Teil von M4/M6 |

Flags setzt vorerst nur ein Gespräch (`sets_flag`). Später können Grimoire-Seiten (`RewardData.LOCATION` gibt es schon als Typ) oder ein gereinigtes Blütenherz dasselbe tun.

**Erster Anwendungsfall: die Hexenpforte**
1. Am Anfang ist das Dorf über den Wald erreichbar. Die Hexenpforte im Dorf ist ein vorhandenes `GardenGate` mit `required_flag = "witch_gate_open"`: Es bleibt zu, beim Nähern kommt „Verriegelt.“. Der Garten-Ausgang dorthin hat dasselbe Flag und meldet „Der Pfad endet an einer verriegelten Pforte.“
2. Das erste Gespräch mit dem Wächter setzt `witch_gate_open`.
3. `WorldState.flag_changed`: Das Tor öffnet sich ab sofort beim Nähern, beide Richtungen funktionieren.
4. Ab jetzt hat der Wächter auch Gerüchte (`requires_flags = ["met_watchman"]`).
5. Gespeichert wird wie alles beim nächsten Schlafen.

Damit sind eine Gebiets-Freischaltung und eine NPC-Interaktion abgedeckt, beide aus derselben Aktion, und die Abkürzung bringt echten Nutzen gegen die Sonne.

---

## 6. Reihenfolge der Umsetzung

Jeder Meilenstein ist einzeln spielbar und ein eigener Commit. Vorher ein eigener Branch `village-hub`.

| # | Meilenstein | Ergebnis | Umfang |
|---|---|---|---|
| M0 | Basis | `combat-overhaul` in `main`, Branch `village-hub` | Entscheidung 9.1 |
| M1 | Dorf-Graybox | Dorf als `Level`, Ausgang am Waldrand, Laternen, Fensterlichter | mittel |
| M2 | `WorldState` | Flags mit Spielstand | klein |
| M3 | Dialogbox | Aushang am Anschlagbrett lesbar | mittel |
| M4 | NPC-Grundgerüst | Wächter steht je nach Uhrzeit am richtigen Spot und spricht | mittel |
| M5 | Tagesroutine | Laufen zwischen Spots, Streife, Heimgehen, F6 | mittel |
| M6 | Gesprächsauswahl | Kennenlernen, Mond, Uhrzeit, Gerüchte | klein–mittel |
| M7 | Hexenpforte | erste Freischaltung, Abkürzung Garten ↔ Dorf | klein |
| M8 | optional, eigene Freigabe | `Unlockable`, Marktfläche bei Halbmond, Motten an Laternen | klein–mittel |

Nach M7 ergänze ich die Doku: Leitplanken in `CLAUDE.md`, Umsetzungsstand in `game_design.md`, ein kurzes `docs/VILLAGE_HUB.md` (wie `COMBAT_SYSTEM.md`).

---

## 7. Betroffene Dateien

**Neu**

| Datei | Meilenstein |
|---|---|
| `scenes/world/village.tscn` | M1 |
| `scripts/systems/world_state.gd` | M2 |
| `scenes/ui/dialogue_box.tscn`, `scripts/ui/dialogue_box.gd` | M3 |
| `scripts/world/notice_board.gd` (Aushang, ruft die Dialogbox) | M3 |
| `scripts/npcs/npc_data.gd`, `schedule_entry.gd`, `dialogue_data.gd` | M4 |
| `scripts/npcs/npc.gd`, `scenes/npcs/npc.tscn`, `scenes/npcs/watchman.tscn` (mit Laterne) | M4 |
| `data/npcs/watchman.tres`, `data/dialogue/watchman/*.tres` | M4, M6 |
| `scripts/world/unlockable.gd` | M8 |

**Geändert**

| Datei | Änderung | Meilenstein |
|---|---|---|
| `scenes/world/forest.tscn` | Ausgang `ToVillage` am Ostrand, Pfad, evtl. ein Baum versetzt | M1 |
| `scripts/systems/save_game.gd` | Teil `world` (3 Zeilen) | M2 |
| `project.godot` | Autoload `WorldState` vor `SaveGame`; Debug-Aktion F6 | M2, M5 |
| `scenes/main.tscn` | `DialogueBox` unter `UI` | M3 |
| `scripts/systems/day_cycle.gd` | F6: eine Stunde vor (nur Debug) | M5 |
| `scripts/world/exit.gd` | `required_flag`, `locked_message` | M7 |
| `scripts/world/garden_gate.gd` | `required_flag`, bleibt sonst zu | M7 |
| `scenes/world/garden.tscn` | Ausgang `ToVillage` am Ostrand außerhalb des Zauns | M7 |
| `data/translations/texts.csv` (+ von Godot erzeugte `.translation`) | Ortsname, `PROMPT_TALK`, Meldungen, Dialogzeilen en/de | M1–M7 |
| `CLAUDE.md`, `docs/design/game_design.md` | Leitplanken, Umsetzungsstand | nach M7 |

Nicht angefasst: `player.gd`, `grimoire.gd`, `combat.gd`, Inventar, Garten-Logik.

---

## 8. Tests und Akzeptanzkriterien

**Automatisch (von mir, Godot headless):** Projekt lädt ohne neue Fehler oder Warnungen, alle Szenen laden, kleine Prüfskripte für die Logik. Die Skripte checke ich nur ein, wenn du einen `tests/`-Ordner willst. **Manuell (du in Godot unter Windows):** Spielgefühl, Lesbarkeit, Tastatur.

| # | Akzeptanzkriterien |
|---|---|
| M1 | Wald → Dorf → Wald, die Hexe kommt jeweils am richtigen Ausgang heraus, ohne zurückzuspringen · Kamera endet an den Rändern, HUD-Rand nicht begehbar · Häuser und Bäume blockieren, Y-Sortierung stimmt · Laternen und Fenster leuchten nur nachts · Atmo läuft · Digitalis bleibt weggesteckt (falls sichere Zone) · ab 6 Uhr Sonnenschaden · erster Besuch gibt Wildcraft-Erfahrung |
| M2 | Flag setzen (Debug), schlafen, Titel, Fortsetzen: Flag ist da · Neues Spiel: keine Flags · alter Spielstand ohne `world` lädt fehlerfrei · Prüfskript: Speichern und Laden ergeben dieselben Flags |
| M3 | „E Lesen“ am Anschlagbrett · Box öffnet, Spiel und Uhr stehen, Plakette weg · E, Leertaste, Klick blättern, letzte Zeile schließt, Esc schließt, Pausemenü geht dabei nicht auf · das E, das öffnet, blättert nicht gleich weiter · lange Zeilen brechen um, nichts ragt aus dem Rahmen (en und de) |
| M4 | 20:00 am Brunnen, 02:00 am Waldtor (mit F6 prüfen) · tagsüber nicht da · „E Sprechen“, Namensschild stimmt · man läuft nicht durch ihn · Ort verlassen und zurück: er steht am richtigen Spot · Prüfskript: richtiger Block für 17:59, 18:00, 23:30, 01:00, 05:59, 06:00 |
| M5 | Blockwechsel vor Augen: Er läuft mit etwa halbem Hexentempo zum nächsten Spot, nicht durch Häuser · Streife läuft im Kreis bis 02:00 · beim Laufen angesprochen: bleibt stehen, geht danach weiter · steht die Hexe im Weg, wartet er ohne Zittern · nach Schlafen, Laden oder Zeitraffer sofort am richtigen Spot |
| M6 | Das erste Gespräch kommt genau einmal · Neumond und Vollmond haben ihre Zeile · Gerücht: Im Grimoire erscheint die Zutat als Hinweis, höchstens ein Gerücht pro Nacht · Waldtor-Block: Bruder-Zeile · danach immer eine Alltagszeile, nie leer · keine sichtbaren Text-Schlüssel (en und de) |
| M7 | Vor dem Gespräch: Pforte im Dorf zu, Meldung; Garten-Ausgang meldet „verriegelt“, kein Ortswechsel · nach dem Gespräch: Tor öffnet sich, Durchgang in beide Richtungen · bleibt nach Speichern und Laden offen · Neues Spiel: wieder zu |

---

## Umsetzungsstand (12.10.2026)

| # | Stand | Abweichung vom Plan |
|---|---|---|
| M0 | ✅ `combat-overhaul` in `main`, Branch `village-hub` | – |
| M1 | ✅ Dorf-Graybox, Waldweg | Waldweg zweigt oben ab (y ≈ 208), nicht bei y ≈ 600 (dort Käferbereich) |
| M2 | ✅ `WorldState` mit Spielstand | zusätzlich Nacht-Merker (`mark_tonight`), nicht gespeichert |
| M3 | ✅ Dialogbox, Anschlagbrett | – |
| M4 | ✅ NPC-Grundgerüst, Wächter, F6 | Wächter geht schon um 5:40 hinein (sonst stünde er bei Sonnenaufgang draußen) |
| M5 | ✅ Laufen, Streife, Warten | – |
| M6 | ✅ Gesprächsauswahl, Gerüchte | Gerüchte nur, solange das Rezept unbekannt ist |
| M7 | ✅ Hexenpforte | Das Tor steht im Garten (Ostrand, senkrechter Zaun mit Glutlaternen), im Dorf endet der Pfad oben am gesperrten Ausgang |
| M8 | offen (optional) | – |

**Umbau nach Robins erstem Test (12.10.):** Seewald zwischen Garten und tiefem Wald, Dorf nur über den Seewald (Waldweg SO, Pforte NO), Dorf organisch statt Rechteck, Digitalis auch in Garten und Dorf. Das Layout in Abschnitt 2 ist damit überholt; aktuell gilt `docs/VILLAGE_HUB.md`, Abschnitt 0.

Systembeschreibung und Tests: `docs/VILLAGE_HUB.md`.

## 9. Entscheidungen (Robin, 12.10.2026)

1. ✅ **Basis:** `combat-overhaul` ist in `main` (Fast-Forward, 12.10.), `village-hub` zweigt davon ab.
2. ✅ **Erreichbar:** vorerst ab Nacht 1 über den Wald. 💡 Später vielleicht erst über eine Quest; dann bekommt der Waldausgang ein `required_flag`.
3. ✅ **Lage:** Dorf am Ostrand des Waldes, Hexenpforte vom Garten-Ostrand aus.
4. ✅ **Erster NPC:** Nachtwächter mit Routine und Gerüchten, ohne Tausch. Tausch kommt mit dem zweiten NPC, zusammen mit der Antwort-Auswahl in der Dialogbox.
5. ✅ **Sichere Zone:** Das Dorf ist kampffrei wie Garten und Unterschlupf (`safe_zone = true`).

Nicht blockierend, kann später kommen: Name des Dorfs, Portraitgröße, Gebäudegrafiken, ob die Pforte erst nach dem zweiten Gespräch aufgeht (nur ein Datenwert), Freundschaftsherzen.

**Bewusst nicht in dieser Phase:** Beziehungs-Simulation, Tausch, Quest-Struktur, Innenräume, Portraits, finale Grafiken, eigene Dorf-Musik.
