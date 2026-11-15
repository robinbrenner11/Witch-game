# Backlog

Stand: 15.11.2026. Aufgabenliste für Sessions, die ohne Robin laufen (Regeln: `CLAUDE.md` Abschnitt 10 und 13).

- **Bereit**: darf ohne Rückfrage umgesetzt werden, von oben nach unten.
- **Wartet auf Robin**: erst anfangen, wenn Robin es nach „Bereit“ verschiebt.
- Eine Aufgabe pro Session. Branch `claude/<thema>`, PR gegen den Arbeitsbranch aus `docs/START.md` (gerade `claude/zusammenfuehrung`, nach Robins Test `overworld`).
- Erledigtes nach „Erledigt“ verschieben, mit Datum und PR.

## Bereit

_(leer: erst Robins Test der Zusammenführung)_

## Wartet auf Robin

- **Zusammenführung testen** (`claude/zusammenfuehrung`, 15.11.): Robins lokaler Stand vom 18.10. plus alles vom Autopilot, was ihm fehlte. Danach nach `overworld` und `main` mergen. Zum Testen:
  - Neues Spiel (F2 löscht den Spielstand): Titelbildschirm, Intro mit Namensfrage, Einstieg am Lesepult
  - Garten: Südausgang führt jetzt in den Seewald (lag vorher unter der Kartenwand)
  - Seewald (früher v2, F9 entfällt): Ranken-Treppe und Mondsteg mit eigenen Grafiken, Tropfen am Höhlenspalt
  - Schlafen: erst die Nachtbilanz, dann ein Traum (falls einer ansteht). Nervt die Bilanz jede Nacht?
  - Rezept merken (Knopf auf der Rezeptseite), lange Schatten bei zunehmendem Mond, Uhr pulsiert ab 5 Uhr
  - Gnarl antwortet jetzt direkt nach Gabe und Upgrade; Nachtwächter erzählt von Gnarls Kerze und vom Nebel
  - Nach dem Blütenherz: Reaktionen von Nachtwächter, Mutter Moos und Gnarl; die Pilzringe in Garten und Wald werden zum Hexenring (Schnellreise)
- **Nicht übernommen vom Autopilot, weil Robins Fassung anders entschieden hat:** Eule fliegt bei Annäherung weg (bei Robin spricht man sie an), eigene Fassungen von Gnarl, Herbarium, Wasser-Animation, Digitalis-, People- und Bestiarium-Kapitel, Bannkunst (Autopilot: +2 Leben, Hexenklinge/Hexenwirkerin) und Blütenherz (Autopilot: Heilung des Waldes, Glühwürmchen in der Ruine, eigene Grafiken). Einzelnes davon nachholen? Alles liegt noch auf `claude/autopilot`.
- ❓ **Hexenpfade ohne Wirkung:** „Mondblut“ (`rare_variants`) und „Pfadfinderin“ (`pathfinder`) versprechen etwas, das es noch nicht gibt. Bauen oder den Kartentext vorerst ehrlich machen?
- **Blütenherz balancieren**, nachdem Robin es gespielt hat (Schwierigkeit, Lesbarkeit der Angriffe)
- **Alte Branches löschen?** `combat-overhaul`, `quality-overhaul`, `claude/agent-setup`, `claude/gnarl-upgrades`, `claude/herbarium-eintraege` sind überholt. Nur mit Robins Okay.
- ❓ **Garten und Seewald zusammenlegen?** (`overworld_plan.md`, offene Fragen)
- ❓ **Freundschaftssystem** (Herzen, Geschenke): Umfang klären
- **Grimoire mit echten Grafiken** (`docs/auftraege/auftrag_grimoire_umbau.md`), wartet auf Robins Grafik-Paket
- **Große Welt-Sprites der Bitterblüte** (`docs/auftraege/grafik_auftrag_bitterbloom.md`), macht Robin

## Vorschläge

Von Claude notiert, nicht gebaut. Robin entscheidet, ob sie nach „Bereit“ wandern.

- CI-Workflow, der die Tests bei jedem Push laufen lässt (aus der Code-Prüfung vom 06.11.)
- Robins Stand regelmäßig pushen, damit Autopilot-Läufe darauf aufbauen (sonst entstehen wieder zwei Fassungen)

## Erledigt

- 15.11.2026: **Zusammenführung** von `robin/garten-neu` und `claude/autopilot` auf `claude/zusammenfuehrung`. Fix: Südausgang im Garten war unerreichbar. Übernommen: Tests und QA-Werkzeuge, Titelbildschirm, Name der Hexe, Einstieg, Nachtbuch, Rezept merken, lange Schatten, Hexenring, Uhr-Warnung, Funkeln reifer Pflanzen, HUD-Symbole, Dornkäfer-Knospen, Hexenpfad-Wirkungen, Seewald v2 als Seewald, Gate-Grafiken, Höhlentropfen, NPC-Silhouetten, Hinweise und Reaktionen der NPCs, Speichern und Laden gehärtet. 100 Tests grün, Dauerlauf ohne Fehler.
- 03.–10.11.2026: Autopilot-Läufe auf `claude/autopilot` (Protokoll: `DEV_PROGRESS.md`)
