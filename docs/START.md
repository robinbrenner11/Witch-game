# Bitterbloom – Einstieg

Stand: 15.11.2026. **Das hier zuerst lesen**, danach nur die Dokumente, die die Aufgabe braucht. Regeln für die Zusammenarbeit und die technischen Leitplanken stehen in `CLAUDE.md`.

## Stand in einem Absatz

Bitterbloom ist ein Cozy RPG, das nur nachts spielt (Godot 4.7, GDScript). Spielbar sind: Garten mit Wachstum über Nacht, Brauen am Kessel, Trinken und Werfen von Tränken, Sammeln mit Nachwachsen, Truhe, Grimoire mit Disziplinen und Hexenpfaden, Mondphasen (8 Nächte), Kampf mit Digitalis (Stab und Sichel) gegen befallene Käfer, Sonne ab 6 Uhr, Speichern beim Schlafen. Dazu der Dorf-Hub (Graybox) mit Nachtwächter, Dialogen und Gerüchten, Gesuche am Anschlagbrett, Tausch mit Mother Moss, Ugo und der Wanderin Wren (Halbmondmarkt), Gnarl mit Upgrades (Stab II, Sichel II, Kessel II), Turmruine mit Blütennebel und Blütenherz 1 (Boss, Platzhalter), Grimoire mit allen Kapiteln außer Bonding (Digitalis, People, Bestiary, Warding), Träume, versteckte Seiten im Mondlicht, die Eule mit Hinweisen, animiertes Wasser, Sperren (Gates) und Orte mit Höhen aus Bauplänen (Seewald, Wasserfall-Höhle, Sumpf). Seit der Zusammenführung am 15.11. außerdem (vom Autopilot): Name der Hexe im Intro, Titelbildschirm mit Stimmung, Nachtbuch beim Einschlafen (vor dem Traum), Rezept merken mit HUD-Anzeige, lange Schatten bei zunehmendem Mond, Hexenring als Schnellreise nach dem Blütenherz, Uhr warnt vor dem Morgen, reife Pflanzen funkeln, Hexenpfade Volatil/Nachhall/Bändigerin/Sucherin/Seitenfinderin wirken, robusteres Speichern und Laden, Tests und Screenshot-Werkzeug. Viele Grafiken sind Platzhalter. Die echten macht Robin selbst mit dem Plugin.

## Branches

| Branch | Inhalt |
|---|---|
| `main` | stabiler Stand (Kampf, Quality Overhaul) |
| `village-hub` | Dorf-Hub M1–M8 |
| `overworld` | Höhen, World-Builder, Sperren, Gesuche, neue Orte und NPCs (baut auf `village-hub` auf) |
| `robin/garten-neu` | Robins lokaler Stand vom 16.–18.10. (neuer Garten, Grafiken, Gnarl, Blütenherz, Wren, Träume …), am 15.11. gesichert |
| `claude/autopilot` | Autopilot-Läufe 03.–10.11., auf dem alten `overworld` gebaut (ohne Robins lokalen Stand) |
| `claude/zusammenfuehrung` | **aktuell**: Robins Stand als Basis plus alles vom Autopilot, was ihm fehlte. Nach Robins Test → `overworld` → `main` |

Nach `main` wird nur mit Robins Okay gemergt und gepusht.

## Nächste Schritte

Gepflegt in `docs/design/welt_und_items.md`, Abschnitt 10 („Nächste Schritte“). Akt 1 ist komplett als Graybox gebaut. Kurz:
1. **Robins Test von `claude/zusammenfuehrung`** (Liste in `docs/BACKLOG.md`), danach nach `overworld` und `main` mergen
2. Blütenherz-Kampf spielen und balancieren
3. Offene Entscheidungen (Liste in `welt_und_items.md`, Abschnitt 10), danach Höhen für Wald, Dorf und Garten

## Welches Dokument für welche Frage

| Frage | Dokument |
|---|---|
| Gesamtdesign, Kern-Loop, Mond, Kampf-Design, NPCs, Lore | `docs/design/game_design.md` |
| Welt, Orte, Sperren S1–S8, Items und Rezepte, Upgrades, Gesuche, **Umsetzungsstand** | `docs/design/welt_und_items.md` (neueste Quelle) |
| Höhen, Klippen, KI-Karte, Schritte W1–W7 | `docs/design/overworld_plan.md` |
| Orte aus Bauplänen bauen (Aseprite, Builder) | `tools/world_builder/LIESMICH.md` |
| Grimoire: Kapitel, Seiten, Disziplinen, Pfade | `docs/design/grimoire.md` |
| Aussehen der Bitterblüte und von Befallenem | `docs/design/bitterbloom.md` |
| Kampf-Technik: Nodes, Steuerung, Werte | `docs/COMBAT_SYSTEM.md` |
| Dorf, NPCs, Dialoge, Tagesabläufe, Tausch | `docs/VILLAGE_HUB.md` |
| Welche Grafik wofür, Größen, Frames | `docs/ASSETS.md` |
| Sound erzeugen | `docs/audio/sfx_generator/LIESMICH.md`, Musik: `docs/audio/garten_loop/LIESMICH.md` |

Gilt bei Widersprüchen: das neuere Dokument. `welt_und_items.md` (16.10.) vor `game_design.md` (08.10.) vor dem Archiv.

## Offene Aufträge (warten auf Robin)

- `docs/auftraege/auftrag_grimoire_umbau.md`: Grimoire mit echten Grafiken, wartet auf Robins Grafik-Paket
- `docs/auftraege/grafik_auftrag_bitterbloom.md`: große Welt-Sprites der Bitterblüte (macht Robin)

## Archiv

`docs/archiv/`: erledigte Aufträge und Prompts, die Checkliste der Basics, die Design-Entscheidungen vom 07.10. (Garten und Brauen im Detail), der Dorf-Hub-Plan (Robins Entscheidungen zum Dorf, Abschnitt 9), der Quality-Overhaul-Bericht vom 11.10. und die alte Ideensammlung (Hauptfigur, Sound, erste Wünsche). Nur lesen, wenn eine Frage genau dorthin führt.

## Weitere Ordner

- `docs/art/`: Palette `hexen_palette.gpl`, Grafik-Generatoren (Python), Referenzen und Vorschauen
- `tools/world_builder/`: Builder und Baupläne
- Debug-Tasten: F1 Samen und Tränke, F2 Spielstand löschen, F3–F5 Grimoire, F6 eine Stunde weiter, F7 Höhen-Test, N nächste Nacht
- `tools/qa/`: Screenshots ohne Bildschirm (`shot.sh`) und Dauerlauf durch alle Orte (`soak.gd`)
- `tests/`: Tests im Repo, headless mit `godot --headless --script res://tests/run_tests.gd`. In der Cloud vorher `bash tools/setup_godot.sh`.
