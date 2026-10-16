# Quality Overhaul – Bitterbloom

Stand: 11.10.2026 · Branch `quality-overhaul` (lokal, nicht gepusht) · Basis: `465349b Digitalis: uid-Datei nachgetragen`

**Kurzfassung:** Das Projekt war technisch schon solide. Der komplette Kern-Loop (pflanzen, schlafen, ernten, brauen, ausgießen, trinken, sammeln, kämpfen, verlieren, speichern) lief im automatischen Test ohne einen einzigen Laufzeitfehler. Die größten Schwächen lagen deshalb nicht im Code, sondern darin, **was die Spielerin sieht und versteht**: Sie erfuhr nirgends, was E an einem Objekt tut, welche Tasten es gibt, wie man einen Trank benutzt. Wichtige Meldungen überschrieben sich gegenseitig, lange Texte liefen aus dem Bild, und die Hexe selbst war nachts kaum zu erkennen. Dazu kam ein echtes Risiko: Ein Absturz beim Speichern hätte den einzigen Spielstand zerstört.

Vergleichsbilder: `docs/vorher_nachher/` (links vorher, rechts nachher).

---

## 1. Bestandsaufnahme

Legende: ✅ solide · 🟡 funktioniert, Prototyp oder Platzhalter · ⚪ vorbereitet, nicht eingebaut · ❌ fehlt

| System | Zustand | Was es gibt | Anmerkungen |
|---|---|---|---|
| Rahmen (Titel, Intro, Pause, Einstellungen) | ✅ | Neues Spiel / Fortsetzen, Intro, Pausemenü, Lautstärke, Vollbild, Sprache (en/de) | Jetzt mit Steuerungsübersicht |
| Übersetzung | ✅ | `data/translations/texts.csv`, alle Texte als Schlüssel | 39 neue Schlüssel ergänzt |
| Spielstand | ✅ | JSON, jedes System liefert `get_save_data()`/`load_save_data()` | Jetzt mit Zwischendatei und Backup |
| Zeit und Mond | ✅ | Nacht ≈ 12 Min., 8-Nächte-Mondzyklus, Nachtfärbung je Phase, Hexenfeuer als Zeitraffer | Verhalten bei Sonnenaufgang offen (siehe 7) |
| Hexe: Bewegung, Aktionen | ✅ | Laufen, Schweben, Ausgießen, Ernten, Trinken, Schnippen mit Animationen | |
| Interaktion | ✅ | Goldklammern um das Ziel | Jetzt mit Taste und Tätigkeit |
| Garten | ✅ | Beete wecken (R), 6 Pflanzen, 1 Stufe pro Nacht, Nachtschatten-Aura, Mondkelch nur bei Vollmond | Gießen nicht vorgesehen (Atlas hat schon „gegossene“ Spalten) |
| Brauen | ✅ | Kessel mit Brau-Fenster, 5 Rezepte, Fehlschlag = Hexenschlamm, braut über Nacht, Kapazität als Datenwert | Kessel-Upgrade hat noch keinen Weg ins Spiel |
| Tränke | ✅ | 3 zum Trinken, 3 zum Ausgießen | Wurftränke offen |
| Inventar | ✅ | 24 Plätze, Hotbar, Drag & Drop, Stapel teilen, Brunnen als Entsorgung | Truhe ist nur Deko |
| Grimoire | 🟡 | Kapitel, lose/befallene/zerrissene Seiten, 3 Disziplinen mit Stufen und Hexenpfaden, Herbarium | Umbau mit neuen Grafiken steht laut `docs/auftrag_grimoire_umbau.md` an |
| Welt | ✅ | Unterschlupf (hohler Uraltbaum), Garten, Wald; Deko-Bausteine, Bodenschatten, Lichtinseln | |
| Lebendigkeit | ✅ | Glühwürmchen, Motten, Fledermaus, Eule, Kröte, Leuchtpilze, Hexenring | |
| Sammeln | ✅ | Wildgras/Unkraut, Glutmorchel, Dämmerbeeren, Eulenfeder, Mondmoos mit eigenen Nachwachs-Regeln | |
| Kampf | 🟡 | Kampfmodus (F), Zauber per Maus, großer Zauber, Dash, Käfer, Reinigen, Niederlage | Zauber und Käfer noch Platzhalter-Zeichnungen |
| Audio | 🟡 | 56 Effekte, Atmo je Ort, Musik-Loop + Vollmond-Variante | Keine getrennten Lautstärken, eine Musik für alle Orte |
| NPCs, Dialog, Tausch | ⚪ | Dialog-Grafiken liegen in `assets/ui/dialog_*`, Ordner `scenes/npcs`, `data/npcs`, `data/dialogue` leer | |
| Begleiterin Katze | ⚪ | Grafiken in `assets/characters/familiar/` | Laut Plan später |
| Lager (Truhe) | ✅ | 16 Plätze, aufrüstbar bis 24 (seit 11.10.) | Weg zum Aufrüsten offen |

**Technische Qualität:** klare Szenen, kleine Scripts, Zustand in Autoloads, Inhalte als Daten (`data/`). Keine doppelten Implementierungen gefunden. Alle 263 Skripte, Szenen und Ressourcen laden ohne Fehler.

---

## 2. Durchgeführte Verbesserungen

Jede Gruppe ist ein eigener Commit auf `quality-overhaul`, also einzeln nachvollziehbar und einzeln rückgängig zu machen.

### A. Spielstand kann nicht mehr kaputtgehen (`7ba7741`)
**Problem:** `save_game()` schrieb direkt in `savegame.json`. Absturz oder volle Platte mitten im Schreiben = Spielstand weg. „Fortsetzen“ mit kaputtem Stand tat einfach nichts. Ein umbenanntes Item oder eine entfernte Pflanze hätte beim Laden leere Icons bzw. einen Absturz beim nächsten Nachtwechsel erzeugt.

**Lösung:**
- Schreiben in `savegame.json.tmp`, prüfen, dann umbenennen. Der vorige Stand bleibt als `savegame.json.bak`.
- Laden prüft die Datei komplett, **bevor** ein System etwas übernimmt. Ist der letzte Stand kaputt, wird der vorletzte geladen.
- Unbekannte Items, Pflanzen, Tränke im Kessel und Wildwuchs-Szenen werden beim Laden aussortiert (mit Warnung im Protokoll), Wachstumsstufen auf gültige Werte begrenzt.
- Titel: Ist gar kein Stand lesbar, steht auf dem Knopf „Spielstand nicht lesbar“ und der Fokus springt zu „Neues Spiel“.
- Nebenbei: Ein Spielstand ohne Brau-Teil übernahm bisher den Kessel der vorigen Sitzung; jetzt startet er leer. Die „Ewige Nacht“ blieb nach dem Laden hängen; jetzt nicht mehr.

Dateien: `scripts/systems/save_game.gd`, `inventory.gd`, `garden.gd`, `brewing.gd`, `day_cycle.gd`, `scripts/plants/plant_data.gd`, `scripts/world/wild_growth.gd`, `scripts/title.gd`

### B. Interaktions-Hinweis: Taste und Tätigkeit (`305257b`, `4decad0`)
**Problem:** Die Goldklammern zeigten, *womit* E interagiert, aber nicht, *was* passiert. Wer das Spiel zum ersten Mal startet, steht neben dem Bett, sieht es eingerahmt und legt sich womöglich schlafen, womit Nacht 1 vorbei ist. Dass man mit Samen in der Hand ein Beet bepflanzt, mit einem Trank ausgießt oder Unkraut ausreißen kann, musste man erraten.

**Lösung:** Über den Klammern steht eine kleine Plakette: **E Schlafen**, **E Ernten**, **E Ausgießen**, **E Pflanzen**, **E Brauen**, **E Nehmen**, **E Lesen**, **E Pflücken**, **E Ausreißen** … Die Tätigkeit hängt vom Zustand ab (Beet: pflanzen, ernten, ausgießen oder ansehen; Kessel: brauen oder Trank nehmen) und verspricht nie etwas anderes, als E dann tut. Schrift in normaler Pixelgröße wie im Grimoire, Taste in Gold wie in dessen Bedienzeile, dunkle Plakette für Lesbarkeit über Lichtinseln, sanftes Einblenden.

Dazu ein **Einmal-Hinweis**: Mit Samen in der Hand vor freier Gartenerde steht „R Erde wecken“, bis das erste Beet geweckt ist (Grimoire-Ziel `wake`). Danach bleibt der Garten ruhig.

Bei offenen Fenstern verschwinden Klammern und Plakette (vorher blieben die Klammern über dem Fenster stehen).

Dateien: `scripts/systems/interactable.gd` (`prompt_key()`), `scripts/player/interaction_hint.gd`, `interaction_prompt()` in `bed.gd`, `campfire.gd`, `cauldron.gd`, `well.gd`, `lectern.gd`, `loose_page.gd`, `farm_tile.gd`, `forage.gd`, `weed.gd`; `scripts/player/earth_magic.gd` (`can_wake_at()`)

### C. Meldungen gehen nicht mehr verloren (`305257b`)
**Problem:** Die Meldungszeile über der Hotbar zeigte immer nur die letzte Meldung. Ernte, Herbarium-Eintrag und Stufenaufstieg im selben Moment: Man sah nur das Letzte. Die Mondmeldung kam beim Schlafen, während das Bild schwarz war, und war vorbei, bevor man sie sehen konnte. Lange Texte (z. B. „A page, eaten by the Bitterbloom. Perhaps the lectern can help.“, auf Deutsch noch länger) liefen über den Bildschirmrand. Beute vom Käfer meldete sich doppelt.

**Lösung:**
- Warteschlange (max. 5): Meldungen erscheinen nacheinander, Lesezeit wächst mit der Textlänge, bei wartenden geht es zügiger.
- Gleiche Item-Gewinne werden zusammengezählt: „+1 Alraune“, „+1 Alraune“ → „+2 Alraune“.
- Die Zeit läuft nicht, solange das Bild schwarz ist oder ein Fenster die Hotbar verdeckt.
- Lange Texte brechen **ausgewogen** in zwei Zeilen um (kein einzelnes Wort allein in der zweiten Zeile).
- Item-Wechsel zeigt den Namen weiterhin sofort; eine gerade erschienene Meldung wird dabei nicht verschluckt, sondern kommt danach.
- Harter Pixel-Schatten unter Meldung, Uhr und Mondphase (`5f13618`), damit sie über hellen Stellen lesbar bleiben.

Dateien: `scripts/ui/hotbar.gd`, `scripts/ui/screen_fade.gd` (`is_covering()`), `scripts/world/dropped_item.gd`, `scenes/ui/hotbar.tscn`, `scenes/ui/clock.tscn`

### D. Wissen, was ein Item tut, und wie man das Spiel bedient (`305257b`, `aea771d`, `c150378`)
- **Trank auswählen:** Bei trinkbaren Tränken steht hinter dem Namen „· Q trinken“. (Ausgießen zeigt der Interaktions-Hinweis am Beet.)
- **Inventar (Tab):** Beim Überfahren erscheint eine Tafel mit Name, Beschreibung und in Gold, wofür das Item gut ist („Zum Ausgießen auf ein Beet · E“, „Eine Zutat für den Kessel.“, „In ein Beet pflanzen.“). Vorher stand dort nur der Name, frei schwebend über der Welt.
- **Steuerung:** Neue Seite in den Einstellungen (aus Titel und Pause erreichbar). Alle Tasten in zwei Spalten, links Alltag, rechts Buch, Menü und Kampf. Die Tasten werden **live aus der Tastenbelegung** gelesen (`InputHints`), stehen also nie doppelt im Text und stimmen auch, wenn die Belegung später einstellbar wird.
- **Kessel:** Doppelklick auf eine Zutat legt sie hinein (Ziehen geht weiter). Unpassendes gibt nur einen leisen Ton.

Dateien: `scripts/ui/input_hints.gd` (neu), `scripts/ui/controls_menu.gd` + `scenes/ui/controls_menu.tscn` (neu), `scripts/ui/settings_menu.gd` + Szene, `scripts/ui/inventory_window.gd` + Szene, `scripts/ui/inventory_slot.gd`, `scripts/ui/brew_window.gd`

### E. Sichtbare Qualität (`de320d3`, `aea771d`)
- **Die Hexe ist nachts lesbar.** Dunkles Kleid, dunkle Kontur, dunkler Boden: Bei Neumond war sie praktisch unsichtbar, auch bei Vollmond kaum abgesetzt. Neu ist ein schwaches, kühles Mondlicht von **oben links** (wie die Lichtregel), das **nur ihre Figur** trifft, nicht den Boden. Technisch: `SilhouetteLight` in `player.tscn` wirkt über `range_item_cull_mask = 2` nur auf Sprites mit `light_mask`-Bit 2 (die Hexe). Die Nacht bleibt so dunkel wie vorher, es gibt keinen Taschenlampen-Kegel. Abschalten: `base_energy = 0`. Vergleich: `docs/vorher_nachher/06_…` und `07_…`.
- **Intro:** Die Sätze füllten den ganzen Bildschirm, Absätze waren nicht von Zeilenumbrüchen zu unterscheiden, und auf Englisch hing „since.“ allein in der letzten Zeile. Jetzt: ausgewogene Zeilen (automatisch für jede Sprache), umgebrochene Zeilen eng, Absätze mit Abstand.
- **Pausemenü** wurde unter Hotbar und Uhr gezeichnet, die Abdunklung deckte sie nicht ab. Jetzt `z_index = 10` (Eingabe-Reihenfolge unverändert).

### F. Kleinere Fehler und Komfort
- Kessel „Brew this“: Bei voller Tasche verschwanden die zurückgelegten Zutaten. Jetzt bleiben sie im Kessel.
- Brunnen nimmt keine Werkzeuge an (Vorsorge für Digitalis-Formen als Items).
- Hinweis eine Stunde vor dem Morgengrauen: „Der Himmel wird blass. Dein Bett wartet.“ Was danach passiert, bleibt offen (siehe 7).
- Titel: Die Rückfrage „Wirklich neu beginnen?“ verfällt, sobald der Fokus den Knopf verlässt (`4decad0`).
- Veralteter Kommentar in `day_cycle.gd` (Mond in Nacht 4) und verirrter Tabulator in `garden.gd` korrigiert.
- Meine Änderungen erzeugen keine neuen Editor-Warnungen (`cf9a88d`).

### Neue Konzepte (für die Wartung)

| Konzept | Wo | Wie benutzen |
|---|---|---|
| Interaktions-Text | `Interactable.prompt_key()` | Die Szene mit dem Interactable bekommt `func interaction_prompt() -> String` und gibt einen Text-Schlüssel zurück (`"PROMPT_…"`, leer = nur Klammern). Ohne Methode gilt der Export `prompt`. |
| Tastennamen | `InputHints.key_for("aktion")` | Nie Tasten fest in Texte schreiben. Texte mit `%s` und die Taste einsetzen (siehe `HINT_USE_DRINK`). |
| Meldungen | `Messages.post()` / `deny()` | Unverändert benutzen. Die Hotbar reiht ein, fasst zusammen, wartet bei Schwarzblende. |
| Spielstand | `SaveGame` | Unverändert. Neue Systeme: `load_save_data()` mit `data.get(…, Standard)` schreiben und Unbekanntes aussortieren. |
| Licht nur für eine Figur | `range_item_cull_mask` / `light_mask` | Bit 2 ist „Silhouettenlicht“. Bekommt später z. B. die Katze, muss ihr Sprite `light_mask = 3` haben. |

---

## 3. Tests

Verwendet: Godot **4.7.1** (Linux, headless und unter Xvfb mit Mesa/llvmpipe, Renderer GL Compatibility wie im Projekt). Das Projekt ist auf 4.7 eingestellt; 4.7.1 ist ein Patch-Release derselben Reihe.

**Erfolgreich getestet (automatisiert, 34 Prüfungen, alle grün):**
- Projekt-Import ohne Fehler; alle 263 Skripte, Szenen und Ressourcen laden.
- Hauptszene läuft 900 Frames ohne Fehlermeldung.
- Kern-Loop: Grimoire am Pult nehmen → Ortswechsel → pflanzen → 4 Nächte → reif → ernten → Zutaten per Doppelklick in den Kessel (Samen werden abgelehnt) → brauen → Nacht → Trank abholen → Wachstumstrank ausgießen wirkt → Irrlicht trinken → Brunnen → Wald, Sammeln → Kampfmodus, beide Zauber → Speichern/Laden identisch → Niederlage: geheilt, im Unterschlupf.
- Spielstand: Backup entsteht; zerstörter letzter Stand → Backup wird geladen; Stand mit unbekanntem Item und unbekannter Pflanze lädt, beide aussortiert; Nachtwechsel danach ohne Absturz.
- Meldungen: gleichzeitige Meldungen warten, Duplikate werden zusammengefasst, Item-Gewinne addiert (+1, +2 → +3).

**Visuell geprüft (gerendert, Screenshots angesehen):** Titel, Intro (en, de), Unterschlupf, Garten, Wald, Kessel-Fenster, Inventar mit Item-Tafel (en, de), Einstellungen, Steuerung (en, de), Pausemenü, alle Interaktions-Hinweise (Bett, Pult, Beet, Erde wecken, Kessel, Unkraut, Pilz), Trank-Auswahl, lange Meldungen, Garten bei Neumond/Halbmond/Vollmond mit und ohne Silhouettenlicht.

**Nur statisch geprüft:** Hinweis vor dem Morgengrauen (Code-Pfad, nicht bis 5 Uhr durchgespielt); Lagerfeuer-Hinweis „Aufstehen“ während des Zeitraffers; Titel-Knopf bei unlesbarem Stand (Logik getestet über `load_game()`, Knopf nicht geklickt).

**Nicht testbar hier:** echte Tastatur- und Mauseingabe (Tests rufen die Funktionen direkt auf), Tastaturlayouts (AZERTY/QWERTZ-Anzeige), Ton, Windows-Export und Leistung auf deinem Rechner, Vollbild. **Bitte einmal in Godot unter Windows durchspielen.** Ich behaupte nicht, dass das Spiel fehlerfrei ist.

---

## 4. Bekannte Probleme (nicht behoben)

| Problem | Warum nicht behoben |
|---|---|
| Alte Editor-Warnungen: Ganzzahl-Divisionen (`moon.gd`, `vitals.gd`, `fence.gd` …), `Garden.cell_at()` statisch über das Autoload aufgerufen, Schatten-Variablen in `path_data.gd`, `book_style.gd`, `spread_cover.gd`, `brew_window.gd` (`ready`), `material`/`size` in einigen Effekt-Skripten | Harmlos und bewusst so geschrieben. Die Grimoire-Dateien baust du laut Auftrag gerade selbst um; da wollte ich nicht hineinfunken. |
| Was passiert, wenn die Hexe bei Sonnenaufgang draußen ist | Designentscheidung (siehe 7). Bisher wird es einfach Tag. |
| Seiten-Belohnungen vom Typ Item gehen bei voller Tasche verloren (`Grimoire._apply_reward`) | Tritt erst mit Item-Belohnungen auf Seiten auf (derzeit keine). Lösung wäre dieselbe „im Buch abholen“-Logik wie bei Disziplin-Stufen. |
| Zeit läuft im Titelmenü weiter | Ohne Folgen: Fortsetzen lädt den Stand, Neues Spiel setzt zurück. |
| Zahlentasten wechseln das Item auch bei offenem Grimoire | Harmlos, kein Fehler im Spielstand. |
| Neumond-Nächte sind für die Umgebung sehr dunkel | Bewusst so gestaltet („Neumond: die Nacht ist tiefer“). Die Hexe ist jetzt lesbar; ob Beete und Wege bei Neumond reichen, bitte selbst beurteilen. |
| Kampf-Zauber und Käfer sind Platzhalter-Zeichnungen | Grafik liegt bei dir. |
| `.tscn`-Dateien, die ich neu angelegt habe (`controls_menu.tscn`), haben noch keine UID | Godot ergänzt sie beim ersten Öffnen im Editor; danach bitte mit committen. |

---

## 5. Fehlende grundlegende Funktionen

Was das Spiel braucht, damit es als zusammenhängendes Erlebnis trägt (nicht nur als Sammlung guter Systeme):

1. **Ein Lager.** 24 Plätze, 6 Pflanzen mit Samen und Ernte, 6 Tränke, 5 Sammelobjekte, Blütenblätter: Die Tasche ist nach ein paar Nächten voll. Die Truhe steht schon im Unterschlupf (mit Offen-Frame) und ist laut `game_design.md` als Lager entschieden.
2. **Ein wiederholbarer Weg an seltene Samen.** Nachtschatten gibt es nur als Belohnung für Kräuterkunde Stufe 7 (630 EP). 3 der 5 Rezepte brauchen Nachtschatten. Mit 10 Beeten sind das grob geschätzt 40–50 Nächte. Geplant ist der Tausch bei NPCs; bis dahin gibt es keinen zweiten Weg.
3. **Eine Regel für den Sonnenaufgang.** Ohne sie kann man die Nacht einfach in den Tag hinein verlängern; der Tag-Nacht-Rhythmus, auf dem alles aufbaut, hat dann keine Grenze.
4. **Ein erster NPC mit Dialog.** Die Welt ist schön, aber leer an Personen. Dialog-UI-Grafiken liegen bereit. Ohne NPC fehlen Ziel, Tausch und die Hälfte der Erzählwege.
5. **Getrennte Lautstärken (Musik/Effekte)** und später **Tastenbelegung** (steht in der Checkliste als offen; die Steuerungsübersicht liest die Belegung schon live, Umbelegen würde sich also überall automatisch zeigen).

---

## 6. Feature-Vorschläge

### Notwendig

**N1 Truhe als Lager**
- *Problem/Mehrwert:* Die Tasche läuft voll; Sammeln und Experimentieren werden zur Platzverwaltung.
- *Gefühl:* E an der Truhe öffnet ein Fenster wie das Brau-Fenster: oben die Truhe, unten die Tasche, Drag & Drop und Doppelklick zum Umlegen. Deckel klappt auf (Frame ist da).
- *Betroffen:* neuer Autoload oder Erweiterung von `Inventory` um einen zweiten Bereich, `SaveGame`, neues Fenster mit `InventoryGrid`, `shelter_chest`.
- *Aufwand:* klein bis mittel (1 Sitzung). Abhängigkeiten: keine.
- *Empfehlung:* **jetzt**, vor weiteren Sammelobjekten.

**N2 Regel für den Sonnenaufgang**
- *Problem:* Siehe 5.3. Bisher wird es einfach hell.
- *Gefühl (Option aus deinem Dokument):* Ab 5 Uhr Hinweis (eingebaut), ab Morgengrauen wird die Hexe langsamer, das Bild verschwimmt leicht; schläft sie draußen ein, beginnt die nächste Nacht später und es wird nicht gespeichert.
- *Betroffen:* `DayCycle`, `Player` (Tempo), `NightTint` oder ein Bildschirm-Effekt, `main.gd` (Aufwachen wie bei der Niederlage, aber ohne Verlust).
- *Aufwand:* klein. *Empfehlung:* **jetzt entscheiden**, bauen ist schnell.

**N3 Zweiter Weg zu seltenen Samen**
- *Problem:* Siehe 5.2.
- *Gefühl:* Entweder der erste NPC (Mother Moss) tauscht Samen, oder seltene Samen fallen selten beim Unkraut-Ausreißen bzw. als Fund im Wald.
- *Betroffen:* `Weed`/`Forage` (Drop-Tabellen als Daten) oder NPC-System.
- *Aufwand:* Fund im Wald klein, NPC mittel. *Empfehlung:* **mit dem ersten NPC**; bis dahin evtl. die Stufe für Nachtschatten in `herbalism.tres` vorziehen (nur eine Zahl).

### Sinnvolle Verbesserung

**S1 Erster NPC: Mother Moss mit Samen-Tausch**
- *Mehrwert:* Erste Person, erster Tausch, Grund für den Waldweg, Erzählweg „NPC-Gespräch“.
- *Gefühl:* Ein moosbewachsenes Weiblein am Gartentor, E spricht sie an, Dialog im vorbereiteten Rahmen, sie will z. B. 3 Wildkraut gegen 1 Nachtschattensamen.
- *Betroffen:* Dialog-UI (neu), NPC-Szene (neu), Daten in `data/npcs`/`data/dialogue`, `Grimoire.report("talk")`, Kapitel „People“.
- *Aufwand:* mittel bis groß (2–3 Sitzungen). Abhängigkeiten: Portrait-Größe (offen), NPC-Grafik.
- *Empfehlung:* **nächster großer Schritt** laut eurer Reihenfolge (game_design.md 11.4).

**S2 Getrennte Lautstärken**
- *Mehrwert:* Musik leiser, Effekte laut – Standard-Erwartung.
- *Gefühl:* Zwei Zeilen „Musik“ und „Effekte“ in den Einstellungen.
- *Betroffen:* `Settings`, `default_bus_layout.tres` (Busse gibt es schon), `settings_menu.tscn`.
- *Aufwand:* klein. *Empfehlung:* **bald**.

**S3 Ernte fliegt in die Tasche**
- *Mehrwert:* Mehr Gewicht für den Kernmoment Ernten.
- *Gefühl:* Beim Herausziehen hüpft das Ernte-Icon kurz hoch und fliegt in die Hotbar, der Platz pulsiert einmal.
- *Betroffen:* `farm_tile.gd`, `forage.gd`, `hotbar.gd`.
- *Aufwand:* klein. *Empfehlung:* **später**, wenn die Grafiken final sind.

**S4 Hinweis-Häufigkeit einstellbar**
- *Mehrwert:* Erfahrene Spielerinnen wollen keine Plakette mehr.
- *Gefühl:* Einstellung „Hinweise: immer / nur Klammern“.
- *Betroffen:* `Settings`, `interaction_hint.gd` (eine Bedingung).
- *Aufwand:* sehr klein. *Empfehlung:* **wenn du die Plakette nach ein paar Stunden störend findest**.

### Optionale Ideen

- **O1 Kreuzblumen** (deine Idee vom 09.10.): erst sinnvoll mit mehr Pflanzenarten. Technisch passt es in `Garden._on_day_passed`, wo die Nachtschatten-Aura schon Nachbarn auswertet. *Später.*
- **O2 Mondphasen-Gefühl für Nächte 2–3 und 5–7:** z. B. bei zunehmendem Mond leuchten reife Pflanzen etwas heller, bei abnehmendem raschelt der Wald mehr. Rein atmosphärisch, ohne Spielwert-Änderung. *Optional.*
- **O3 Gießen** (die gegossenen Beet-Spalten im Atlas sind schon da): würde den Alltag strukturieren, macht ihn aber auch mühsamer. Passt eher nicht zu „Die Nacht arbeitet für dich“. *Eher nicht.*

---

## 7. Priorisierung

| # | Maßnahme | Nutzen | Aufwand | Risiko | Empfehlung |
|---|---|---|---|---|---|
| 1 | Sonnenaufgang entscheiden (N2) | hoch | klein | klein | jetzt |
| 2 | Truhe als Lager (N1) | hoch | klein–mittel | klein | jetzt |
| 3 | Nachtschatten früher oder zweite Quelle (N3) | hoch | sehr klein (Zahl) bis mittel | klein | jetzt (Zahl), später (Quelle) |
| 4 | Getrennte Lautstärken (S2) | mittel | klein | sehr klein | bald |
| 5 | Grimoire-Umbau mit neuen Grafiken | hoch | groß | mittel | wie geplant |
| 6 | Erster NPC + Dialog (S1) | sehr hoch | groß | mittel | danach |
| 7 | Ernte-Feedback (S3) | mittel | klein | klein | später |

---

## 8. Offene Designentscheidungen (für dich)

1. **Sonnenaufgang:** Was passiert, wenn die Hexe um 6 Uhr draußen ist? (Optionen in `design_entscheidungen_2026-10-07.md`; ein Hinweis um 5 Uhr ist jetzt eingebaut und ändert daran nichts.)
2. **Nachtschatten-Zugang:** Bleibt er Belohnung für Kräuterkunde 7, oder kommt er früher (Stufe 3?) bzw. über einen Fund/Tausch?
3. **Truhe:** Wie groß (z. B. 24 Plätze wie die Tasche), nur im Unterschlupf oder auch eine im Garten?
4. **Interaktions-Plakette:** Gefällt dir Stil und Größe? Soll sie dauerhaft bleiben oder später abschaltbar sein (S4)?
5. **Silhouettenlicht:** Stärke so passend? (`base_energy` an `SilhouetteLight` in `player.tscn`; 0 = aus, 1.0 = jetzt.)
6. **Tagsüber spielen:** Soll es überhaupt möglich sein, nach 6 Uhr weiterzulaufen? (Hängt mit 1 zusammen.)

---

### Rückmeldung von Robin (11.10.2026)

- ✅ **Nachtschatten bleibt Lategame** (passt dazu, dass man der Bitterblüte näher kommt). Die Rezepte werden ohnehin noch logisch überarbeitet; gewünscht sind weitere Rezepte, neue Pflanzen und Kreuzungen. N3 entfällt damit in dieser Form.
- ✅ **Plakette und Silhouettenlicht passen** so.
- ✅ **Sonnenaufgang (gebaut):** Ab 6 Uhr brennt die Sonne die Hexe draußen, 1 Schaden alle 12 Spielminuten, mit vollem Leben bricht sie um 8 Uhr zusammen. Im Unterschlupf (`Level.indoors`) ist sie sicher. Zusammenbruch: kein Itemverlust, sie wacht im Bett auf, die nächste Nacht beginnt erst um 20 Uhr, danach wird gespeichert. Um 5 Uhr warnt „Der Himmel wird blass. Bald brennt die Sonne.“, beim ersten Treffer „Die Sonne brennt. Schnell hinein.“ Der Zeitraffer am Hexenfeuer endet bei Sonnenaufgang. Dateien: `scripts/player/sun_exposure.gd` (neu), `main.gd`, `vitals.gd` (`last_damage_source`), `day_cycle.gd`, `level.gd`, `shelter.tscn`.
- ✅ **Truhe (gebaut):** Die Truhe im Unterschlupf ist das Lager (E Öffnen, Deckel klappt auf). Start mit 16 Plätzen, aufrüstbar bis 24 über `Inventory.upgrade_chest()`; *woher* die Upgrades kommen (Gnarl, Tausch, Belohnung), ist noch offen. Die Truhenplätze hängen hinter den 24 Taschenplätzen im `Inventory`, deshalb funktionieren Ziehen, Stapeln, Teilen und Speichern ohne eigenen Code; Rezepte, Kessel und Niederlage sehen nur die Tasche (die Truhe ist also bei einer Niederlage sicher). Doppelklick legt einen ganzen Stapel auf die andere Seite. Weitere Truhen könnten sich denselben Inhalt teilen. Dateien: `scripts/world/chest.gd`, `scripts/ui/chest_window.gd` + `scenes/ui/chest_window.tscn` (neu), `inventory.gd`, `inventory_grid.gd`, `inventory_slot.gd`, `main.tscn`, `shelter_chest.tscn`.

---

## 9. Woran du die Verbesserung in Godot erkennst

1. **Neues Spiel starten.** Das Intro ist ruhig gegliedert, keine einzelnen Wörter am Zeilenende.
2. **Im Unterschlupf stehen bleiben.** Über dem Bett steht „E Schlafen“. Die Hexe hebt sich deutlich vom Boden ab (Kleid, Gesicht, Goldakzente).
3. **Zum Pult gehen, E.** Erst „An old book…“, danach (nicht stattdessen) weitere Meldungen.
4. **Esc → Einstellungen → Steuerung.** Alle Tasten auf einen Blick. Das Pausemenü dunkelt jetzt auch Hotbar und Uhr ab.
5. **Garten, Samen in der Hand, vor freie Erde stellen.** „R Erde wecken“. Nach dem ersten Beet ist der Hinweis weg. Vor einem Beet: „E Pflanzen“.
6. **Tab, mit der Maus über einen Samen oder Trank.** Tafel mit Name, Beschreibung und Verwendung.
7. **Am Kessel eine Zutat doppelklicken.** Sie fällt hinein.
8. **Einen Trank in der Hotbar wählen.** „Irrlicht · Q trinken“.
9. **Spielstand testen:** Zweimal schlafen, Spiel schließen, `savegame.json` in `%APPDATA%\Godot\app_userdata\Bitterbloom\` mit Unsinn überschreiben, Fortsetzen: Der vorletzte Stand lädt.

Vorher/Nachher-Bilder: `docs/vorher_nachher/`.
