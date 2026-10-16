# Auftrag: Grimoire-Umbau mit neuen Grafiken (Stand 09.10.2026)

Lies zuerst `CLAUDE.md` und `docs/design/grimoire.md`, vor allem **Abschnitt 5c** (alle Entscheidungen vom 09.10.). Die Grafiken bekommst du von Robin als Paket; Ablage und Maße stehen in `assets/ui/grimoire/LIESMICH.md` (kommt mit dem Paket). Bitte nichts an den PNGs ändern; wenn etwas nicht passt, sag Bescheid, dann wird der Generator angepasst.

Arbeite die Schritte **einzeln** ab. Nach jedem Schritt: kurz erklären (Geändert / Warum / Zum Testen), Robin testet in Godot, dann Commit vorschlagen. **Nicht ohne Zustimmung pushen.** Vor jedem Schritt kurz den Plan nennen.

## Schritt 1: Vollbild und Grafiken für Einband und Papier
- `BookStyle`: neue Maße (Einband 640×360, Seiten 296×326 bei (14, 12) und (318, 12), Falz 8, Lederrand rechts 26, unten 22).
- Einband, Seitenblock (3 Dicken je nach gefundenen Seiten), Seiten links/rechts und Eckbeschläge als Texturen statt `_draw`. Eckbeschläge liegen **über** den Seiten.
- Bedienzeile in Gold unten auf dem Leder, links und rechts vom Buchrücken.
- **Überlauf-Fehler beheben:** alle Inhalte auf die Seitenfläche begrenzen (feste Breiten aus `BookStyle`, ggf. `clip_contents`), besonders die Pfadwahl. Jede Doppelseite mit langen Texten prüfen.

## Schritt 2: Tinten und Lesezeichen
- Neue Tintenfarben in `BookStyle` (Tabelle in 5c). Helles Magenta nur noch für Grafik.
- Lesezeichen als Texturen (normal / aktiv / versiegelt), 20 px hoch, auf dem Lederrand. Das aktive ragt über den Seitenrand ins Buch (liegt über der Seite).
- Kapitelname beim Drüberfahren; Leseband unten.
- Kapitelwechsel-Feedback (W/S): Lesezeichen gleiten, Name kurz in Gold einblenden. Schnelles Blättern und Sound erst, wenn die Umblätter-Animation existiert.

## Schritt 3: Eine Doppelseite pro Eintrag
- Erste Doppelseite eines Kapitels = Übersicht (Raster, Mond, „Forms 3/4“). Klick → Eintrag; Lesezeichen → zurück zur Übersicht.
- Eintrag: links Abbildung (ohne Kasten, Foto-Ecken), Name, Kurzinfos; rechts Details, Notizen in beiden Handschriften, Links zu verknüpften Einträgen.
- A/D blättert durch die Einträge des Kapitels (Unentdecktes überspringen), W/S wechselt das Kapitel.
- Datenmodell vorher kurz vorschlagen (z. B. Notizen und Abbildung pro Eintrag in den bestehenden Resources).

## Schritt 4: Seiten-Schmuck
- Überschriften-Linie aus Endstück, Kachel und Mittelstück.
- Raster-Plätze als Tuschekreise; **Unentdecktes als schraffierte Silhouette** des echten Icons (Kontur in Sepia dunkel, innen das Schraffur-Muster `hatch.png`; z. B. kleiner Shader oder einmal vorberechnete Textur).
- Markierungen (ready to brew, Gerücht, Pin, Häkchen), Mond in 8 Phasen, Erfahrungsranke (Stücke je Stufenzeile), Seitenzahl-Schnörkel, Fingerhut-Verzierung für wiederhergestellte Seiten.

## Schritt 5: Kapitel-Vorlagen und Decals
- Kleine Resource pro Kapitel (z. B. `ChapterTheme`): Decal-Pool (Tabelle in 5c). Ein optionales Feld für Eck-Skizzen links/rechts vorsehen, aber noch ohne Grafik (offen).
- Pro Seite 2–3 Decals aus dem Pool auf freie Flächen, **fester Seed aus der Eintrags-ID**. Nie über Text, Bilder oder Raster.

## Schritt 6: Hand der Hexenstärke
- Grafik liefert Robin selbst. `SpreadCover.HAND_STEPS` auf 6 Stufen erweitern (Vorschlag `[0, 5, 12, 20, 30, 45]`), bis dahin Platzhalter behalten.
