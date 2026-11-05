# DEV_PROGRESS – selbstständige Weiterentwicklung

Kompaktes Arbeitsprotokoll für die Iterationen ohne Robin. Verbindliche Regeln: `CLAUDE.md`. Aufgabenliste: `docs/BACKLOG.md`. Branch: `claude/autopilot` (baut auf PR #2 und #3 auf).

## Stand (05.11.2026)

**Spielbar:** Unterschlupf (Bett, Truhe, Lesepult/Grimoire), Garten (Beete, Wachstum über Nacht, Nachtschatten-Aura), Kessel (Brauen über Nacht, 5+ Rezepte), Tränke trinken/gießen/werfen, Sammeln mit Nachwachsen, Seewald (alt) + Seewald v2 (F8) mit Höhle, Insel, Sumpf, tiefer Wald mit Käfern (Kampf mit Stab und Sichel), Dorf mit Nachtwächter, Gesuchen, Ugo (Halbmond), Gnarl (Wald → Werkstatt, Upgrades), Mondphasen, Sonne ab 6 Uhr, Speichern beim Schlafen.

**Tragende Mechaniken:** Garten → Kessel → Tränke öffnen Wege (Gates) und helfen im Kampf; Grimoire als Fortschritt (Disziplinen, Herbarium, Rezepte, jetzt Digitalis); Nacht-Rhythmus mit Mond.

**Wie ich teste:**
- Logik: `godot --headless --script res://tests/run_tests.gd` (Exit-Code 0 = grün).
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
| 9 | Absturzmeldung: Buch-Hinweis griff auf ein gelöschtes Buch zu | ✅ räumt sich selbst auf |

## Durchgeführte Prüfungen

- 05.11.: alle Tests 51/51 grün, Testlauf ohne SCRIPT ERROR.
- 05.11.: Screenshots Unterschlupf, Garten, Wald, Dorf, Digitalis-Kapitel (vor/nach Upgrade-Flag), Titel, Seewald v2 (Mutter Moos), Sumpf (Ugo), Spielstart (Pult glimmt), Innendeckel und Herbarium auf Deutsch angesehen.

## Offene Probleme / Beobachtungen

- Titelbildschirm ist sehr schlicht (nur Schrift und Knöpfe, keine Stimmung).
- Dorf ist Graybox (Häuser als Farbflächen) – Grafik macht Robin.
- Nicht prüfbar: Ton, Steuerungsgefühl, Tempo.

## Nächste Schritte (priorisiert)

1. Titelbildschirm mit etwas Stimmung (z. B. Kerzenlicht, Funken), ohne neue Grafik von Robin vorwegzunehmen.
2. Weitere Orte auf Lesbarkeit und Hinweise prüfen (Garten mit Beeten, Kessel-Fenster).
