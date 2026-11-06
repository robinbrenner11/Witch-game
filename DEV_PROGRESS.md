# DEV_PROGRESS – selbstständige Weiterentwicklung

Kompaktes Arbeitsprotokoll für die Iterationen ohne Robin. Verbindliche Regeln: `CLAUDE.md`. Aufgabenliste: `docs/BACKLOG.md`. Branch: `claude/autopilot` (baut auf PR #2 und #3 auf).

## Stand (05.11.2026)

**Spielbar:** Unterschlupf (Bett, Truhe, Lesepult/Grimoire), Garten (Beete, Wachstum über Nacht, Nachtschatten-Aura), Kessel (Brauen über Nacht, 5+ Rezepte), Tränke trinken/gießen/werfen, Sammeln mit Nachwachsen, Seewald (alt) + Seewald v2 (F8) mit Höhle, Insel, Sumpf, tiefer Wald mit Käfern (Kampf mit Stab und Sichel), Dorf mit Nachtwächter, Gesuchen, Ugo (Halbmond), Gnarl (Wald → Werkstatt, Upgrades), Mondphasen, Sonne ab 6 Uhr, Speichern beim Schlafen.

**Tragende Mechaniken:** Garten → Kessel → Tränke öffnen Wege (Gates) und helfen im Kampf; Grimoire als Fortschritt (Disziplinen, Herbarium, Rezepte, jetzt Digitalis); Nacht-Rhythmus mit Mond.

**Wie ich teste:**
- Logik: `godot --headless --script res://tests/run_tests.gd` (Exit-Code 0 = grün). `test_play_start` spielt die ersten Minuten mit simulierten Tasten.
- Bild: `bash tools/qa/shot.sh out=<png> level=… pos=x,y hour=… flags=… items=… book=…` rendert das echte Spiel unter Xvfb (OpenGL über llvmpipe) und speichert einen Screenshot. Kein Ton (Dummy-Audio), keine Eingaben – Spielgefühl und Steuerung kann ich nicht selbst prüfen.

## Abgeschlossene Änderungen

| # | Ziel | Ergebnis |
|---|---|---|
| 1 | Digitalis-Kapitel zeigt Formen, Stufe als Kerben und Gnarls Bedarf (Upgrades im Buch sichtbar) | ✅ `SpreadDigitalis`, Test `test_digitalis_chapter.gd` (6), Screenshot geprüft: Texte passen auf die Seite |
| 2 | Prüfwerkzeug: Screenshots ohne Bildschirm | ✅ `tools/qa/screenshot.gd` + `shot.sh` |
| 3 | Fehler: Kapelle statt Werkstatt leuchtete nach Gnarls Umzug (per Screenshot gefunden) | ✅ behoben, Test ergänzt, auch auf PR #3 übernommen |
| 4 | Gnarl im dunklen Wald lesbar machen | ✅ Wichtel-Silhouette (spitze Kappe, Augen, Bart, Messer) und Schnitzkerze mit warmem Licht; Screenshot vorher/nachher geprüft |
| 5 | Ugo und Mutter Moos unterscheidbar und nachts sichtbar | ✅ Ugo: breite Kröte mit Händlerhut, Glubschaugen, grüne Sumpflicht-Laterne. Mutter Moos: gebückt, Moos-Kapuze und -Büschel, Stock mit leuchtendem Mondpilz. Screenshots vorher/nachher geprüft |
| 6 | Werkzeug: `scene=` für Titel und andere Szenen, `lang=de` | ✅ |
| 7 | Einstieg: Ziele in spielbarer Reihenfolge (Wecken → Pflanzen → Brauen → Schlafen), Taste fürs Schnippen aus der Belegung statt fest „(R)“, Lesepult glimmt magenta mit aufsteigenden Funken, solange Vesperas Buch dort liegt | ✅ Test `test_onboarding.gd` (4, u. a. keine festen Tasten in Texten), Screenshot geprüft. Nebenbei: Buch-Hinweis im HUD nannte „B“ fest |
| 8 | Fehler: Grimoire-Seiten liefen über (Herbarium mit 4 Gruppen deutlich, Innendeckel, Wildkunde auf Deutsch) | ✅ Belohnung neben dem Gruppennamen, Erklärung der Hexenstärke als Tooltip, „Jäten“ statt „Wildgras räumen“. Neuer Test `test_book_layout.gd` schlägt jedes Kapitel auf Englisch und Deutsch auf und misst. Herbarium-Fix auch auf PR #2 übernommen |
| 10 | Kampf lohnt mehr: Dornkäfer lassen mit 30 % eine Blütenknospe fallen (bisher nur 1/Nacht bei Ugo, gebraucht für Sichel II und Reinigungsnebel) | ✅ Test `test_beetle_drops.gd`. Balancing-Annahme: 30 % bei 2–4 Dornkäfern pro Neumond-Flut ≈ 1 Knospe pro Flut; nicht gespielt |
| 11 | Erster Eindruck: Titelbildschirm mit Stimmung (Mondsichel, Hügelkante, Fingerhut, zwei flackernde Kerzen mit warmen Lichtinseln, aufsteigende magenta Funken), alles aus Palettenfarben gezeichnet | ✅ `TitleAmbience`, Screenshot geprüft (erste Fassung: Licht wirkte grau, nachgebessert) |
| 12 | Werkzeug: `garden=demo`, `brew=1` | ✅ Garten mit allen Pflanzen und Brau-Fenster per Screenshot geprüft, keine Auffälligkeiten |
| 13 | QA: Kern-Kreislauf als Durchspiel-Test (säen → Nächte → ernten → brauen → Trank abholen) mit Speichern/Laden über JSON; `SaveGame.collect()`, damit Tests nie die echte Spielstand-Datei überschreiben | ✅ `test_core_loop.gd` (3) |
| 14 | NPCs als Personen: People-Kapitel statt fünf ewiger „???“. Einträge für alle 4 NPCs, beim ersten Gespräch entdeckt, 3 Eindrücke in der Tinte der Spielerin (nach 3 und 6 Gesprächen), kleine Porträt-Platzhalter in Palettenfarben | ✅ Test `test_people.gd` (3), Layout-Test deckt das Kapitel mit ab, Screenshot (Deutsch) geprüft. Bewusst ohne Herzen/Geschenke (Freundschaftssystem fehlt noch) |
| 15 | QA mit echten Eingaben: die ersten Minuten über simulierte Tasten in `main.tscn` (zum Pult laufen, E, Buch-Taste, Tür, Gartentor, Schnippen, säen) | ✅ `test_play_start.gd`. Gefundene „Fehler“ lagen am Test (Blickrichtung, Zaun), nicht am Spiel |
| 16 | Entdeckung: Der Nachtwächter erzählt von einer Kerze tief im Wald, wo jemand schnitzt (solange man Gnarl nicht kennt), und bemerkt später das Licht in der Werkstatt | ✅ 2 Gespräche als Daten, Test in `test_gnarl.gd` |
| 17 | Wackeltest behoben: `test_first_minutes` scheiterte ca. 1×/6, wenn zufälliges Unkraut auf der gewählten Zelle stand | ✅ Zellwahl nutzt die Prüfung des Spiels; danach 10/10 Läufe grün |
| 18 | Reife auf Abstand erkennbar: Bisher leuchteten nur Laternenbeere und Mondkelch, wenn sie reif waren (4 von 6 Pflanzen ohne Signal). Jetzt funkelt über jeder reifen Pflanze ab und zu ein goldener Lichtpunkt (zufällige Pausen, unbeleuchtet) | ✅ Test `test_ripe_sparkle.gd`, Screenshots zu drei Zeitpunkten geprüft |
| 19 | UI auf Deutsch geprüft: Inventar, Pausemenü, Dialogbox | ✅ keine Überläufe, keine Änderung nötig. Werkzeug: `press=`, `say=` |
| 20 | Sonne als klare Gefahr: Ab der Morgenwarnung (5 Uhr) pulsiert die Uhr kerzenlichtwarm, am Tag schneller. Bisher nur eine einzelne Meldung um 5 Uhr, die man in einem offenen Fenster verpassen konnte | ✅ Test `test_clock.gd`, Screenshots zweier Pulsstufen geprüft |
| 21 | Gnarl als Person: nach jedem Upgrade eine eigene, kurze Reaktion direkt nach dem Tausch (Stab, Sichel, Kessel) | ✅ reine Daten (`sets_flag` + Gespräch), Test in `test_upgrades.gd`, Zeilenlänge über `test_gnarl.gd` geprüft |
| 22 | QA Kampf: Regressionstest für Treffer, Taumeln, Reinigung mit Beute und Grimoire-Meldung, keine doppelte Beute, Dornkäfer zäher, Schaden über Zeit ohne Taumeln, alle Angriffe (Stufe I und II) mit Schaden/Kosten/Abklingzeit, Unverwundbarkeit der Hexe | ✅ `test_combat.gd` (5), alles grün, kein Fehler gefunden |
| 23 | Fehler am Anschlagbrett (per Screenshot gefunden): Zettel-Text plus „Gesucht/Lohn“ brauchte 4 (en) bzw. 5 (de) Zeilen, die Box fasst 3 – der Lohn lief unten heraus. Jetzt zwei Seiten pro Zettel | ✅ `test_notice_board.gd` misst jede Seite in der echten Box; neuer `test_dialogue_fit.gd` prüft alle Gesprächszeilen aller NPCs (alle passen). Screenshot beider Seiten auf Deutsch geprüft |
| 24 | HUD verständlicher: Herz vor dem Lebensbalken, magenta Raute vor der Hexenkraft (vorher zwei Balken ohne Kennzeichnung) | ✅ Screenshot geprüft |
| 25 | Kampf im Bild (Werkzeug `spawn=`, `freeze=`): Käfer läuft an, trifft, Lebensbalken sinkt, Digitalis wird gezogen. Anlauf-Spur: „!“ über dem Käfer, erst schwache gestrichelte Spur zur Hexe, kurz vor dem Anlauf fest und hell | ✅ Screenshots beider Phasen geprüft, gut lesbar, keine Änderung nötig |
| 26 | Eigene Hexe: Die Spielerin gibt ihr im Intro einen Namen (✅ aus `game_design.md`, bisher nicht gebaut). Gespeichert im Grimoire, sie unterschreibt damit auf dem Innendeckel unter Vesperas „V.“ | ✅ `test_witch_name.gd` (3); Layout-Test mit dem längsten Namen (erste Fassung mit Satz lief auf Deutsch über, deshalb Unterschrift). Screenshots: Intro-Frage (erste Fassung: Inhalt zu hoch und graues Standardfeld, nachgebessert), Innendeckel |
| 28 | Die Welt kennt den Namen: Platzhalter `{witch}` in Gesprächen, zuerst nur beim Nachtwächter in der Dämmerung („Geh nach Hause, Nyx.“), ohne Namen wie bisher „Hexe“ | ✅ Test in `test_witch_name.gd`, `test_dialogue_fit.gd` misst mit dem längsten Namen, Screenshot geprüft. Bewusst sparsam |
| 29 | QA Dauerlauf (`tools/qa/soak.gd`): alle 8 Orte nacheinander, je einige Sekunden bei 4-facher Zeit, über den Sonnenaufgang, bei Halb- und Vollmond | ✅ keine einzige Fehlermeldung |
| 30 | Fortschritt spürbar: Stufenaufstieg einer Disziplin bekommt ein Glockenspiel (`ui/level_up`, neu im Generator) und aufsteigende goldene/magenta Funken um die Hexe (`ProgressFeedback`). Vorher nur eine Textzeile | ✅ Test `test_progress_feedback.gd`, Funken per Screenshot geprüft. **Klang nicht gehört** (keine Audioausgabe), nur Länge 1,6 s und Spitze −9 dBFS geprüft |
| 31 | Entdecken spürbar: neuer Eintrag im Herbarium oder bei den Leuten → Seitenrascheln (vorhandener Klang) und ein paar magenta Funken; neues Signal `Grimoire.entry_discovered` | ✅ Test in `test_progress_feedback.gd` |
| 32 | Fehler + Inhalt: Das Bestiarium konnte sich nie öffnen (Freischaltung „first_fight“ wurde nicht ausgewertet). Jetzt offen nach der ersten Reinigung, mit Einträgen für befallenen Käfer und Dornkäfer (Verhalten, Schwäche mit Spieltipp zur Anlauf-Spur, Beute), eigene Meldung und Bildchen | ✅ `test_bestiary.gd` (4), Layout-Test deckt das Kapitel ab, Screenshot auf Deutsch geprüft |
| 33 | Entscheidungen mit Gewicht: 4 Hexenpfade versprachen etwas, das nicht passierte. Jetzt wirken Volatil (Wurftränke platzen weiter, ×1,25), Nachhall (Dornennebel hält länger, ×1,5), Nachtschatten-Bändigerin (Kuppel hemmt eigene Pflanzen nicht), Sucherin (lose Seiten glimmen doppelt so weit) | ✅ `test_paths_effects.gd` (3). Werte sind Annahmen, nicht gespielt. Drei weitere Pfade brauchen neue Systeme → Frage im Backlog |
| 34 | Welt reagiert: Die Eule fliegt mit ihrer (bisher ungenutzten) Abflug-Animation davon, wenn die Hexe zu nah an ihren Baum kommt, und sitzt nach einer Weile wieder dort, wenn die Hexe weg ist. Suche nach ungenutzten Assets: alle Klänge werden benutzt; ungenutzt sind sonst nur die Katze (💡 später) und das Nachtschatten-Debuff-Symbol | ✅ `test_owl.gd`, Screenshot vor/während des Abflugs geprüft |
| 35 | Ungenutzte Rollentexte der NPCs (`NPC_*_ROLE`) stehen jetzt als Unterzeile unter dem Namen im People-Kapitel (neues Feld `EntryData.subtitle_key`). Dadurch doppelte Angaben in ersten Eindrücken gekürzt | ✅ Test in `test_people.gd`; neuer Layout-Test misst **jeden** Eintrag ganz aufgedeckt im echten Buch (fand Gnarl auf Deutsch 11 px zu lang, behoben). Screenshot geprüft |
| 27 | Inventar-Tafel und lange Meldungen auf Deutsch geprüft | ✅ passt, keine Änderung |
| 9 | Absturzmeldung: Buch-Hinweis griff auf ein gelöschtes Buch zu | ✅ räumt sich selbst auf |

## Durchgeführte Prüfungen

- 05.11.: alle Tests 88/88 grün (ca. 10 s), Testlauf ohne SCRIPT ERROR.
- 05.11.: Screenshots Unterschlupf, Garten, Wald, Dorf, Digitalis-Kapitel (vor/nach Upgrade-Flag), Titel, Seewald v2 (Mutter Moos), Sumpf (Ugo), Spielstart (Pult glimmt), Innendeckel und Herbarium auf Deutsch angesehen.

## Offene Probleme / Beobachtungen

- Dorf ist Graybox (Häuser als Farbflächen) – Grafik macht Robin.
- Nicht prüfbar: Ton, Steuerungsgefühl, Tempo.

## Nächste Schritte (priorisiert)

1. Robins Test von Seewald v2 (F8) abwarten: Erst danach sind Höhlenkristall und Weidenrinde im normalen Spiel erreichbar und damit Gnarls Upgrades.
2. Freundschaftssystem (Herzen, Geschenke) erst nach Robins Entscheidung zum Umfang; das People-Kapitel ist darauf vorbereitet.
