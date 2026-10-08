# Bitterbloom – Grimoire (Vesperas Buch)

Stand: 08.10.2026. Ergebnis der eigenen Grimoire-Session. Ergänzt `docs/design/game_design.md` (Abschnitt 3 „Das Grimoire“, offene Frage 3). Wo sich beide widersprechen, gilt **dieses Dokument**.

Legende: ✅ entschieden · 💡 Idee, gefällt, noch nicht fest · 🔮 später · ❓ offen · ❌ verworfen

Schriftregeln für Spieltexte gelten weiter: keine Gedankenstriche, keine typografischen Anführungszeichen, keine Auslassungspunkte. Alle Spieltexte auf Englisch, über `tr()`.

---

## 0. Ausgangslage im Repo

Bereits vorhanden und wird **ersetzt bzw. umgebaut**:
- `scripts/systems/journal.gd` (Autoload `Journal`): Buch gefunden, lose Seiten, erste Ziele. → wird zum Autoload `Grimoire` (siehe 5).
- `scripts/ui/recipe_book.gd` + `scenes/ui/recipe_book.tscn`: Seite 1 = Vesperas Notiz mit durchgestrichenen Zielen, danach je Rezept eine Seite. → wird durch das neue Buch ersetzt.
- `scripts/world/loose_page.gd`: lose Seite mit `recipe_result_id`. → bekommt eine `page_id` und verweist auf `PageData`.
- `scripts/world/lectern.gd`: Lesepult im Unterschlupf, Buch liegt darauf. → bleibt, bekommt Opfer-Ritual und Pfadwechsel.
- Taste `book` (B) öffnet das Buch, Spiel pausiert. ✅ bleibt.

Behalten aus dem alten Buch:
- ✅ Vesperas Notiz („Wer das hier liest ...“) mit den ersten Zielen, durchgestrichen wenn erledigt. Wird der **Innendeckel**.
- ✅ Unbekannte Rezepte zeigen so viele `brew_unknown`-Icons wie Zutaten.

---

## 1. Aufbau und Navigation

### Grundprinzip
- ✅ Jede Ansicht ist eine **aufgeschlagene Doppelseite**: links Übersicht, rechts Detail.
- ✅ Bei Sammel-Kapiteln (Recipes, Digitalis, People, Herbarium, Bestiary): links ein Raster, der angeklickte Eintrag rechts groß.

### Kapitel (Lesezeichen am rechten Buchrand, 11 Stück in 3 Gruppen)

| Gruppe | Kapitel | Inhalt links | Inhalt rechts | Ab wann |
|---|---|---|---|---|
| (Innendeckel) | Vesperas Notiz | Notiz mit ersten Zielen | Hand mit Fingerspitzen (Hexenstärke), später Name der Spielerin als neue Besitzerin | Buch gefunden |
| Werkzeug | **Recipes** | Raster mit Filtern | Rezept-Detail | Buch gefunden |
| Werkzeug | **Digitalis** | Raster der Formen | Form-Detail, Upgrades | Buch gefunden (Staff) |
| Disziplinen | **Herbalism** | Stufe, Ranke, Stufenliste | Hexenpfade | Buch gefunden |
| Disziplinen | **Brewing** | wie oben | wie oben | Buch gefunden |
| Disziplinen | **Wildcraft** | wie oben | wie oben | Buch gefunden |
| Disziplinen | **Warding** | wie oben | wie oben | 🔒 versiegelt bis Kampfmodus |
| Disziplinen | **Bonding** | wie oben | wie oben, Porträt der Katze | 🔒 versiegelt bis Katze |
| Welt | **Journal** | Eintrag | Eintrag / Fortsetzung | erste Journal-Seite |
| Welt | **People** | Porträt-Raster | Person-Detail | Buch gefunden |
| Welt | **Herbarium** | Raster | Eintrag | Buch gefunden |
| Welt | **Bestiary** | Raster | Eintrag | erster Kampf |

- ✅ **Recipes ist ein eigenes Kapitel**, nicht Teil von Brewing.
- ✅ **Vespera's Journal ist kein Levelsystem.** Fortschritt = gefundene Seiten; große Freischaltungen hängen an bestimmten Seiten. Damit gibt es **5 Disziplinen** (Herbalism, Brewing, Wildcraft, Warding, Bonding).
- ✅ **Digitalis** bekommt ein eigenes Kapitel (Waffenformen).
- ✅ **People** kommt rein, mit kurzer Beschreibung und Freundschaftsstufe.
- ✅ **Träume** bekommen kein eigenes Kapitel. Sie stehen als kurzer Eintrag im Journal, mit kleinem Mond-Symbol.
- ✅ **Gesperrte Kapitel** sind als Lesezeichen sichtbar, aber versiegelt: von der Bitterblüte überwuchert.

### Recipes (Bedienung)
- ✅ Filter oben links: `All` · `Pour` · `Drink` · `Throw` · `Gift`, 🔮 später `Craft`.
- ✅ Feste Plätze im Raster, Lücken bleiben sichtbar (gepunktete leere Plätze).
- ✅ Drei Zustände pro Rezept:
  - **unknown**: `?`-Icons, Anzahl = Zutaten;
  - **hinted**: durch NPC-Gerücht ist mindestens eine Zutat bekannt, das Gerücht steht als Notiz dabei, Icon als Silhouette mit `~`;
  - **known**: vollständig.
- ✅ Markierung **„ready to brew“** (kleines goldenes Quadrat), wenn alle Zutaten in Inventar oder Truhe liegen.
- ✅ Rechte Seite: Zutaten mit Bestand (`2/1`, fehlende rot), Ergebnis, Trankart, Wirkung, „Brewed 2x“, beste Qualität (Sterne), Vesperas Randnotiz.
- ✅ **Klick auf eine Zutat springt zum Herbarium-Eintrag** (Fundort). Fehlende Zutat wird als Link angezeigt („Missing: Nightshade >“).
- ✅ Im **Brau-Fenster** öffnet ein Knopf das Rezeptbuch; **„Brew this“** legt die Zutaten automatisch in den Kessel. Experimentieren von Hand bleibt möglich.
- 💡 **Rezept merken (Pin):** zeigt klein im HUD, welche Zutaten fehlen.

### Digitalis
- ✅ Links Raster der Formen (Staff, Sickle, Thornwhip, Rootmaul). Unbekannte Formen als Silhouette mit Hinweis (z. B. „Gnarl knows more.“).
- ✅ Rechts: Form groß, Linksklick, Rechtsklick, Overworld-Nutzen, Upgrade-Stufe als Kerben, was Gnarl für die nächste Stufe braucht.

### People
- ✅ Links Porträts im Dialog-Porträtrahmen; Unbekannte als vorhandene `?`-Silhouette.
- ✅ Rechts:
  - Name und wo man sie findet;
  - kurzer Eindruck **in der Handschrift der Spielerin**, wächst mit der Freundschaft;
  - **Freundschaft: 5 Herzen**, jedes Herz bringt eine kleine Szene oder Freischaltung;
  - Vorlieben, die erst durch Geschenke aufgedeckt werden;
  - Tausch-Schwerpunkt;
  - später: Verbindung zur Blüte.

### Herbarium und Bestiary
- ✅ Einträge mit Fakten, die nach und nach aufgedeckt werden (Fundort, Mondphase, beste Qualität; bei Wesen: befallen/gereinigt, Schwächen, Beute).
- ✅ Belohnung für volle Seiten (z. B. seltene Samen, Wurftrank-Rezept).

### Journal
- ✅ Feste Plätze in Vesperas Zeitfolge. Fehlende Seiten sind **ausgerissene Stummel** mit halbem Wort oder kleiner Skizze als Hinweis auf den Fundort.

### Zwei Handschriften
- ✅ Was von Vesperas Seiten stammt, steht in **ihrer Tinte** (Bordeaux tief / Bordeaux für Überschriften).
- ✅ Was die Spielerin selbst entdeckt (Rezept durch Experiment, Pflanze, Wesen, Eindrücke von Personen), steht in **ihrer Tinte: Magenta**.
- 💡 Wie es im Spiel wirkt, wird getestet. Technisch reicht zunächst die Farbe (gleiche Schrift).

### Navigation
- ✅ **B** öffnen/schließen, **Esc** schließen, Spiel pausiert.
- ✅ Öffnet dort, wo es etwas Neues gibt (mit kurzer Animation). Am Kessel direkt bei Recipes. Sonst auf der zuletzt gelesenen Seite.
- ✅ **A/D oder ←/→** blättern, **W/S oder ↑/↓** Kapitel wechseln.
- ✅ Maus: Lesezeichen klicken, Eintrag links klicken, Mausrad blättert.
- ✅ Neues glimmt leicht magenta (Lesezeichen und Eintrag), bis es einmal angesehen wurde.

---

## 2. Seiten finden und wiederherstellen

### Seitenzustände
- ✅ **Lose Seite:** aufheben, sofort im Buch (wie bisher).
- ✅ **Befallene Seite:** von der Bitterblüte überwuchert, unleserlich. Wird am **Lesepult** mit einem **Opfer** wiederhergestellt.
- ✅ **Fragmente:** wichtige Journal-Seiten sind in 2–3 Teile zerrissen; erst wenn alle da sind, ist die Seite ganz.

### Fundorte
- ✅ Versteckt in der Welt (Hütten, unter Wurzeln, bei Inschriften); glimmen nachts magenta.
- ✅ **Liquid Moonlight** macht versteckte Seiten sichtbar.
- ✅ Befallene Seiten liegen nur in befallenen Gebieten; bei Neumond treibt die Blüte manchmal neue heraus.
- ✅ Jedes **Blütenherz** lässt eine große Schlüsselseite fallen.
- ✅ NPCs: die Eule deutet Hinweise, Ugo tauscht heimlich befallene Seiten, manche Herz-Stufen schenken eine Seite.
- ✅ Stummel im Journal geben Hinweise auf den Fundort.
- 💡 Weitere kreative Fundorte, z. B. eine Seite, die im Garten wächst, oder die die Katze findet.
- 🔮 **Angeln** als neues Feature: Seite an der Angel oder von einem angelnden NPC (Teaser).

### Opfer am Lesepult
- ✅ Gleiche Bedienung wie das Brau-Fenster (Opfer-Felder per Drag & Drop).
- ✅ Verlangt werden: einfache Zutaten (z. B. 3 Owl Feather), **verdorbene Zutaten** für wichtige Seiten, manchmal ein Trank, der über die Seite gegossen wird.
- ✅ **Mondbedingungen** bei manchen Opfern (z. B. „only beneath a full moon“).
- ✅ Man kann nicht scheitern; fehlt etwas, wird genau angezeigt, was.
- ✅ Animation: Ranken welken, Vesperas Tinte kommt Zeile für Zeile zurück.

### Belohnungen
- ✅ **Jede Seite hat einen Lore-Schnipsel und genau eine Hauptbelohnung.** Ersetzt „Jede Seite bringt Rezept, Lore und Freischaltung“ aus dem Game-Design-Dokument. Mögliche Hauptbelohnungen:
  - Rezept;
  - neue Digitalis-Form oder Bauplan (Kessel- oder Garten-Upgrade);
  - Hinweis auf einen Ort (neues Gebiet, Versteck);
  - Traum in der nächsten Nacht (nur Journal-Seiten);
  - Erfahrungspunkte-Schub für eine Disziplin.
- ✅ Belohnungen für volle Seiten in Herbarium und Bestiary.

### Umfang Akt 1 (💡)
- Ungefähr **12 Seiten**: 4 Rezepte, 5 Journal, 1 Digitalis, 2 Hinweise.
- Davon 2–3 befallen, eine ist die Schlüsselseite vom ersten Blütenherz.

---

## 3. Disziplinen

### Stufen
- ✅ **Höchststufe 10** zu Beginn; in den Daten festgelegt, später auf 15/20 erweiterbar ohne Codeänderung.
- 💡 Zielwerte Ende Akt 1 (ca. 24 Nächte): Herbalism und Brewing ca. 5, Wildcraft ca. 4, Warding 3–4, Bonding 1–2. Erfahrungskurve danach austarieren.
- ✅ **Jede Stufe bringt etwas Sichtbares** (Samen, Rezept, Qualitätschance, Zutatenplatz ...), keine reine Zahl.
- ✅ **Stufe 5 und 10 sind Meilensteine** mit Hexenpfad-Wahl.

### Erfahrungspunkte
- ✅ Entdecken schlägt Wiederholen: große Erfahrungspunkte beim ersten Mal.

| Disziplin | kleine Erfahrungspunkte | große Erfahrungspunkte (erstes Mal) |
|---|---|---|
| Herbalism | pflanzen, ernten | neue Pflanze, erste perfekte Qualität |
| Brewing | brauen | neues Rezept, besonders durch eigenes Experiment |
| Wildcraft | sammeln | neuer Ort, Seite gefunden, neuer Herbarium-Eintrag |
| Warding | Wesen reinigen, zaubern | neues Wesen im Bestiary, Blütenherz |
| Bonding | Zeit mit der Katze, füttern, streicheln | neue Fähigkeit benutzt |

- ✅ **Abschwächung bei Wiederholung:** pro Nacht ein Zähler je Aktion; ab einer Schwelle 50 %, später 25 %; Reset beim Schlafen. (Schwellen als Daten.)

### Hexenpfade
- ✅ **Baum mit Abhängigkeit:** Stufe 5 wählt A oder B; die zwei Optionen auf Stufe 10 hängen von der Wahl auf Stufe 5 ab (4 Endzustände je Disziplin).
- ✅ **Wahl änderbar** am Lesepult, kostet aber **seltene Items**.
- ✅ Keine Popup-Pflicht: Das Lesezeichen glimmt, gewählt wird in Ruhe im Buch.
- 💡 Erste Pfad-Ideen (Namen und Effekte vorläufig, Robin ergänzt evtl. eigene):

| Disziplin | Stufe 5 | Stufe 10 nach A | Stufe 10 nach B |
|---|---|---|---|
| Herbalism | A **Wildheart** (mehr Ertrag) · B **Rootwise** (mehr Qualität) | Overgrowth (Wachstum breitet sich aus) / Seedkeeper (mehr Samen) | Moonblood (seltene Varianten) / Nightshade Tamer (keine Strafe unter der Kuppel, Nachtschatten nützlich) |
| Brewing | A **Twin Brew** (2 Tränke pro Brauen) · B **Potent** (stärkere Wirkung) | Cauldron Chorus (3 auf einmal) / Patient Fire (Chance auf Bonus-Trank über Nacht) | Lingering (längere Dauer) / Volatile (größere Wurftränke) |
| Wildcraft | A **Forager** (mehr Funde, schneller nachwachsen) · B **Seeker** (Seiten/Verstecke glimmen weiter) | Bountiful / Moonpicker (Mondmoos auch außerhalb Vollmond) | Pathfinder (Abkürzungen) / Pagefinder (Fragmente auf der Karte) |
| Warding | A **Hexblade** (Nahkampfformen) · B **Hexcaster** (Fernzauber, Hexenkraft) | ❓ nach Kampf-Prototyp | ❓ nach Kampf-Prototyp |
| Bonding | ❓ hängt von den Fähigkeiten der Katze ab | | |

### Hexenstärke
- ✅ **Summe aller Disziplin-Stufen.** Bringt mehr maximale Hexenkraft und ist Bedingung für große Dinge (z. B. „Dieses Blütenherz verlangt Hexenstärke 15“).
- ✅ Wird auf dem Innendeckel als **gezeichnete Hand mit dunkler werdenden Fingerspitzen** gezeigt (5 Stufen).

---

## 4. Optik

Bezug: Mockups `grimoire_mockup_A_2x.png` (Pergament, gewählt) und `grimoire_mockup_B_2x.png` (dunkle Seiten, verworfen). Bei Bedarf nach `docs/art/vorschau/` legen.

### Grundstil
- ✅ **Pergament** (Version A). ❌ Dunkle Seiten (B).
- ✅ Einband: Bordeaux-Leder (Bordeaux tief / Bordeaux dunkel) mit Tiefschwarz-Kontur und **Gold-Ecken** wie beim Dialograhmen.
- ✅ Papier: Knochen als Grundton, zum Falz hin Laken Schatten / Laken Schatten tief; Seitenkanten als Stapel unten und außen.
- ✅ Farben nur aus `docs/art/hexen_palette.gpl` (inkl. gelockerter Zwischentöne).
- ✅ Tinten:
  - Fließtext: Aubergine;
  - Vespera: Bordeaux tief (Text), Bordeaux (Überschriften);
  - Spielerin: **Magenta**;
  - Nebeninfos: Laken Schatten tief;
  - Akzente/Linien: Gold dunkel.
- ✅ Hintergrund des Spiels wird beim Öffnen zu ca. 70 % mit Tiefschwarz abgedunkelt.

### Maße (1×, Viewport 640×360, Fenster 2× skaliert)
- ✅ Einband 500×312 (x 70–570, y 26–338).
- ✅ Zwei Seiten je ca. 234×296, Falz 8 px.
- ✅ Lesezeichen 13 px breit, aktives 18 px, Höhe 18 px, Gruppen mit 6 px Abstand.
- ✅ Raster-Plätze 24×24, Item-Icons 16×16.
- ✅ Zeilenabstand 11 px, ca. 34 Zeichen pro Zeile.

### Schrift
- ✅ **Überschriften in derselben Schrift wie der Fließtext** (eine Schrift fürs ganze Buch). Überschriften nur über Farbe und Goldlinie abgesetzt. ❌ Eigene Fraktur-Überschriften (Jacquarda Bastarda 9 / Jacquard 12 getestet).
- ❓ **Welche Schrift:** m5x7 erinnert Robin an Minecraft. Kandidaten zum Vergleich im Mockup:
  - **Alkhemikal** (jeti, CC BY 4.0, Nennung im Abspann): Alchemie-/Fantasy-Charakter;
  - **Silver** (Poppy Works, CC BY 4.0, Nennung; Lizenz nötig ab 100.000 $ Umsatz): weich, für Spiele, viele Sprachen.
  - Bis zur Entscheidung bleibt m5x7. Die Schrift muss im Theme zentral austauschbar sein.

### Lesezeichen
- ✅ Vorerst farbige Bänder (je Kapitel eigene Farbe). 🔮 Icons später.

### Fortschrittsanzeige
1. ✅ **Mond als Vollständigkeit** je Kapitel oben rechts (Neumond bis Vollmond, 8 Phasen) plus Zahl (`5/15`).
2. ✅ **Erfahrungsranke** bei Disziplinen: wächst am Seitenrand, jede Stufe ein Blatt, Meilensteine als Knospen, die nach der Pfadwahl aufblühen.
3. ✅ **Hand auf dem Innendeckel** mit dunkler werdenden Fingerspitzen (Hexenstärke).
4. ✅ **Zwei Handschriften:** mit der Zeit mehr Magenta im Buch.
5. ✅ **Versiegelte Kapitel und befallene Seiten** mit welken Ranken (Laub dunkel, Welk oliv) und Magenta-Knospen, wie die Bitterblüte in der Welt.
6. ✅ **Wiederhergestellte Seiten** behalten eine kleine Fingerhut-Verzierung am Rand.
7. ✅ **Lücken:** ausgerissene Stummel (Journal), gepunktete leere Plätze (Raster).
8. ✅ **Buchblock wird dicker** mit mehr Seiten; zweites Lesepult-Sprite mit weniger überwuchertem Buch.

### Animationen
- ✅ Umblättern 3–4 Frames.
- ✅ Neue Einträge schreiben sich Wort für Wort hinein, Tintenklecks am Ende.
- ✅ Ranken welken beim Wiederherstellen (ca. 6 Frames), danach Magenta-Glimmen.
- ✅ Neues glimmt pulsierend wie die losen Seiten in der Welt.

---

## 5. Technik (Godot)

### Prinzip
- ✅ **Datengetrieben wie `RecipeData`:** jeder Eintrag eine `.tres` in einem Ordner unter `data/`, automatisch geladen über `ResourceLoader.list_directory()`. Neuer Inhalt = neue Datei, kein Code.
- ✅ Alle Texte als `tr()`-Schlüssel (englische CSV).

### Datenklassen (Vorschlag für Ordner und Felder)

| Klasse | Ordner | Wichtige Felder |
|---|---|---|
| `ChapterData` | `data/grimoire/chapters/` | `id`, `group` (tool/discipline/world), `order`, `tab_color`, `tab_icon` (🔮), `template` (index_detail / discipline / journal), `unlock` (Bedingung) |
| `DisciplineData` | `data/grimoire/disciplines/` | `id`, `max_level`, `xp_curve: Array[int]`, `xp_sources: Dictionary` (Aktion → klein/groß), `repeat_thresholds`, `level_rewards: Array[RewardData]`, `milestone_levels: [5, 10]` |
| `PathData` | `data/grimoire/paths/` | `id`, `discipline_id`, `level`, `requires_path_id` (für Stufe 10), `effects: Array[RewardData]`, `respec_cost: Array` (seltene Items) |
| `PageData` | `data/grimoire/pages/` | `id`, `kind` (recipe/journal/digitalis/hint), `state` (loose/blighted/fragments), `fragment_count`, `offering: Array` (Item-ID + Anzahl), `moon_condition`, `reward: RewardData`, `lore_key`, `journal_order`, `dream_id` |
| `EntryData` | `data/grimoire/entries/` | `id`, `chapter` (herbarium/bestiary/people), `page_group`, `facts: Array[String]` (Schlüssel, einzeln aufdeckbar), `page_reward: RewardData` |
| `RewardData` | eingebettet | `type` (recipe, item, digitalis_form, location, xp, stat), `target_id`, `value` |

- People liest Grunddaten aus `NpcData` (`data/npcs/`), Freundschaft aus dem Beziehungssystem.
- Rezepte bleiben in `data/recipes/`; `RecipeData` bekommt optional `category` (pour/drink/throw/gift/craft) und `margin_note_key`.

### Autoload `Grimoire` (ersetzt `Journal`)
- ✅ Hält nur den Spielstand:
  - Buch gefunden, erledigte erste Ziele;
  - Seiten: gefunden / Fragmente / wiederhergestellt;
  - XP und Stufe je Disziplin, gewählte Pfade;
  - aufgedeckte Einträge und Fakten, Rezept-Zustände (unknown/hinted/known);
  - „schon gesehen“-Markierungen (für das Glimmen);
  - wer etwas geschrieben hat (Vespera oder Spielerin);
  - Wiederholungszähler der aktuellen Nacht.
- ✅ `get_save_data()` / `load_save_data()` wie bisher; **alte Spielstände übernehmen** (`has_book`, `pages`, `goals` aus `Journal`).
- ✅ Signale: `changed`, `level_up(discipline, level)`, `page_found(page_id)`, `entry_discovered(entry_id)`, `milestone_ready(discipline, level)`.

### Ereignisse statt fester Verdrahtung
- ✅ Andere Systeme melden nur: `Grimoire.report("harvest", {"plant": "mandrake", "quality": 2})`.
- ✅ Das Grimoire rechnet XP, Abschwächung, Erstes-Mal-Bonus, Stufen, Glimmen.
- ✅ Effekte werden abgefragt, nicht eingebaut: z. B. `Grimoire.get_stat("brew_count")`, `Grimoire.get_stat("harvest_bonus")`.

### UI
- ✅ Eine Buch-Szene (Einband, Lesezeichen, Doppelseite) + drei Seitenvorlagen: `IndexDetailSpread`, `DisciplineSpread`, `JournalSpread`.
- ✅ Lesepult: Opfer-Ansicht (wiederverwendet Brau-Fenster-Slots) und Pfadwechsel.
- ✅ Brau-Fenster: Knopf zum Rezeptbuch und „Brew this“.

### Umsetzungsreihenfolge
1. `Grimoire`-Autoload, Datenklassen, Speichern inkl. Übernahme alter Spielstände.
2. Buch-Hülle mit Lesezeichen + Kapitel Recipes (ersetzt `recipe_book`).
3. Disziplinen mit `report()`, zuerst Herbalism und Brewing.
4. Seitenzustände (lose, befallen, Fragmente) und Opfer am Lesepult.
5. Journal, People, Herbarium, Bestiary, Digitalis, jeweils wenn das zugehörige Spielsystem existiert.
6. Debug-Befehle: XP geben, Seiten geben, Stufe setzen.

---

## 6. Grafiken (🔮 später generieren, Liste merken)

- Einband als 9-Slice (Bordeaux-Leder, Gold-Ecken)
- Papier links und rechts, Falz-Schatten, Seitenstapel-Kanten (mehrere Dicken)
- 11 Lesezeichen-Bänder (🔮 mit Icons)
- Raster-Platz-Rahmen in drei Zuständen (normal, ausgewählt, leer)
- Markierung „ready to brew“, Gerücht-`~`, Pin
- Mond-Anzeige in 8 Phasen
- Erfahrungsranke: Stängel, Blatt, Knospe, Blüte
- Ranken-Überwucherung (Lesezeichen und ganze Seite)
- Fingerhut-Verzierung
- ausgerissener Stummel (Journal)
- Hand mit 5 Stufen dunkler Fingerspitzen
- Lesepult mit Buch: weitere Stufe(n), weniger überwuchert
- Animations-Frames: Umblättern (3–4), Ranken welken (ca. 6), Tintenklecks, Glimmen

Arbeitsweise: Robin sammelt die Assets und gibt sie Claude Code zum Einbauen; beim Generieren Zwischenstände zeigen.

---

## 7. Offene Fragen (❓)

1. Schrift fürs ganze Spiel: Alkhemikal, Silver oder m5x7 behalten (Vergleich im Mockup steht aus).
2. Pfade für Warding (Stufe 10) nach dem Kampf-Prototyp; Pfade für Bonding nach Klärung der Katzen-Fähigkeiten.
3. Erfahrungskurve und Wiederholungs-Schwellen: Werte beim Testen austarieren.
4. Konkreter Inhalt der ca. 12 Seiten in Akt 1 (welche Rezepte, welche Lore, wo sie liegen).
5. Konkrete Opfer und Mondbedingungen je befallener Seite.
6. Was jedes Freundschafts-Herz pro NPC bringt.
7. Wie die zwei Handschriften im Spiel wirken (Test; evtl. zweite Schrift oder kleine Tintenkleckse).

---

## 8. Anpassungen an bestehenden Dokumenten

- `docs/design/game_design.md`, Abschnitt 3:
  - Tabelle „Kapitel = Disziplinen“: Vespera's Journal ist **kein** Levelsystem; Anhang Herbarium und Bestiarium sind eigene Kapitel; neu: Recipes, Digitalis, People.
  - „Jede Seite bringt Rezept, Lore und Freischaltung“ → „Jede Seite bringt einen Lore-Schnipsel und eine Hauptbelohnung“.
  - 💡 „Opfer“ → ✅ (siehe Abschnitt 2 hier).
  - „Inhalt und Design des Buchs werden in einer eigenen Session überarbeitet“ → erledigt, Verweis auf dieses Dokument.
- Offene Frage 3 im Game-Design-Dokument → erledigt.
- `CLAUDE.md` unter „Neuere Entscheidungen“: dieses Dokument als neueste Quelle zum Grimoire eintragen.
