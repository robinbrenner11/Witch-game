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
| 6 | Werkzeug: `scene=` für Titel und andere Szenen | ✅ |

## Durchgeführte Prüfungen

- 05.11.: alle Tests 44/44 grün.
- 05.11.: Screenshots Unterschlupf, Garten, Wald, Dorf, Digitalis-Kapitel (vor/nach Upgrade-Flag), Titel, Seewald v2 (Mutter Moos), Sumpf (Ugo) angesehen.

## Offene Probleme / Beobachtungen

- Titelbildschirm ist sehr schlicht (nur Schrift und Knöpfe, keine Stimmung).
- Dorf ist Graybox (Häuser als Farbflächen) – Grafik macht Robin.
- Nicht prüfbar: Ton, Steuerungsgefühl, Tempo.

## Nächste Schritte (priorisiert)

1. Einstieg prüfen: Was sieht eine neue Spielerin in den ersten Minuten (Titel, Unterschlupf, Hinweise)?
2. Vorschlag 2 aus dem Backlog: Dornkäfer lassen manchmal eine Blütenknospe fallen.
