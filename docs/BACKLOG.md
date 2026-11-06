# Backlog

Stand: 03.11.2026. Aufgabenliste für Sessions, die ohne Robin laufen (Regeln: `CLAUDE.md` Abschnitt 10 und 13).

- **Bereit**: darf ohne Rückfrage umgesetzt werden, von oben nach unten.
- **Wartet auf Robin**: erst anfangen, wenn Robin es nach „Bereit“ verschiebt.
- Eine Aufgabe pro Session. Branch `claude/<thema>`, PR gegen den Arbeitsbranch aus `docs/START.md` (gerade `overworld`).
- Erledigtes nach „Erledigt“ verschieben, mit Datum und PR.

## Bereit

_(leer, siehe „Vorschläge“)_

## Wartet auf Robin

- ❓ **Hexenpfade ohne Wirkung:** „Mondblut“ (`rare_variants`, seltene Varianten), „Pfadfinderin“ (`pathfinder`, Abkürzungen) und „Seitenfinderin“ (`pagefinder`, Karte) versprechen etwas, das es noch nicht gibt. Bauen (eigene Systeme) oder den Kartentext vorerst ehrlich machen („… sobald es … gibt“, wie bei Potenz und Qualität)?
- ❓ **Warding (Bannkunst) als Disziplin freischalten?** Das Kapitel ist versiegelt (`unlock = "combat"` wird nicht ausgewertet), weil es die Disziplin noch nicht gibt. Fehlt dafür: Pfade bei Stufe 5/10 (`grimoire.md`: Hexblade / Hexcaster, ❓ nach Kampf-Prototyp), Belohnungen je Stufe, wofür es Erfahrung gibt (Reinigen? neue Wesen im Bestiarium?). Das Bestiarium ist seit 05.11. offen und wäre die Grundlage.
- **Alte Branches löschen?** `combat-overhaul` und `quality-overhaul` sind vollständig in `main`. Löschen nur mit deinem Okay.
- **Gnarl und Upgrades testen.** Seit 06.11. ist Seewald v2 der echte Seewald, Weidenrinde und Höhlenkristall sind also im normalen Spiel erreichbar.
- **`overworld` nach `main` mergen.** `overworld` ist rund 30 Commits vor `main`. Nach Robins Test mergen, damit es wieder einen stabilen Stand gibt.
- **Schritt 8: Turmruine, Blütennebel S5, erstes Blütenherz.** Der Boss braucht erst einen Entwurf (Aussehen, Ablauf, Belohnung).
- ❓ **Garten und Seewald zusammenlegen?** (`overworld_plan.md`, offene Fragen)
- ❓ **Alte Spielstände beim Garten-Umbau** (`overworld_plan.md` Abschnitt 7)
- **Grimoire mit echten Grafiken** (`docs/auftraege/auftrag_grimoire_umbau.md`), wartet auf Robins Grafik-Paket.
- **Große Welt-Sprites der Bitterblüte** (`docs/auftraege/grafik_auftrag_bitterbloom.md`), macht Robin.

## Vorschläge

Von Claude notiert, nicht gebaut. Robin entscheidet, ob sie nach „Bereit“ wandern.

_(alle umgesetzt, siehe „Erledigt“ und `DEV_PROGRESS.md`)_

## Erledigt

- 05.11.2026: Bestiarium öffnet sich nach der ersten Reinigung (Freischaltung wurde nie ausgewertet), Einträge für beide Käferarten. Name der Hexe im Intro. Fortschritt und Entdecken mit Klang und Funken. Anschlagbrett-Seiten passen in die Dialogbox. PR #4.
- 05.11.2026: People-Kapitel mit Einträgen für Nachtwächter, Mutter Moos, Ugo, Gnarl (entdeckt durch Gespräche, Eindrücke wachsen mit), Titelbildschirm mit Stimmung, Durchspiel-Test des Kern-Kreislaufs. Tests `test_people.gd`, `test_core_loop.gd`. PR #4.
- 05.11.2026: Dornkäfer lassen mit 30 % eine Blütenknospe fallen (`rare_drop_item`/`rare_drop_chance`). Einstieg (Zielreihenfolge, glimmendes Pult, Tasten aus der Belegung), Grimoire-Seiten laufen nicht mehr über, NPC-Silhouetten. Tests `test_beetle_drops.gd`, `test_onboarding.gd`, `test_book_layout.gd`. PR #4.
- 05.11.2026: Digitalis-Kapitel im Grimoire (Formen, Stufe als Kerben, Gnarls Bedarf), Screenshot-Werkzeug `tools/qa/`, Gnarl lesbarer (Silhouette, Schnitzkerze), Fix Werkstatt-Licht. Test `test_digitalis_chapter.gd`. Protokoll: `DEV_PROGRESS.md`. PR #4.
- 03.11.2026: Kleinkram: Ladekreis `BrewSlot` ↔ `BrewWindow` aufgelöst (`load()` statt `preload()`), der Parse-Fehler im Testlauf ist weg. Test `tests/test_brew_ui.gd` (startet Godot einmal frisch, prüft auch Platz für 4 Zutaten). PR #4 (`claude/autopilot`).
- 03.11.2026: Wasser-Animation: 4 Frames pro Wasserfeld über die Kachel-Animation des TileSets, Platzhalter-Frames aus `water.py`, Builder unverändert (setzt Frame 0). Test `tests/test_water.gd`. PR #4 (`claude/autopilot`).
- 03.11.2026: Schritt 7, Gnarl und Upgrades: Gnarl im tiefen Wald, Heiltrank als Gabe, Umzug in die Dorf-Werkstatt zur nächsten Nacht (7a); Stab II, Sichel II, Kessel mit 4 Plätzen als Tausch bei Gnarl (7b). Tests `tests/test_gnarl.gd`, `tests/test_upgrades.gd`. PR #3 (`claude/gnarl-upgrades`).
- 03.11.2026: Herbarium-Einträge für Weidenrinde, Mondwasser, Höhlenkristall, Sumpflicht, Bitterblütenblatt und Blütenknospe (Mondmoos und Eulenfeder hatten schon einen), Test `tests/test_herbarium.gd`. PR #2 (`claude/herbarium-eintraege`).
- 03.11.2026: Tests im Repo (`tests/`), Godot-Setup für Cloud-Sessions (`tools/setup_godot.sh`), Regeln für Arbeit ohne Robin in `CLAUDE.md`, doppelte Text-Schlüssel `DIGITALIS_STAFF`/`DIGITALIS_SICKLE` entfernt.
