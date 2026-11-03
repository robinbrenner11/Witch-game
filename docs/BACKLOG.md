# Backlog

Stand: 03.11.2026. Aufgabenliste für Sessions, die ohne Robin laufen (Regeln: `CLAUDE.md` Abschnitt 10 und 13).

- **Bereit**: darf ohne Rückfrage umgesetzt werden, von oben nach unten.
- **Wartet auf Robin**: erst anfangen, wenn Robin es nach „Bereit“ verschiebt.
- Eine Aufgabe pro Session. Branch `claude/<thema>`, PR gegen den Arbeitsbranch aus `docs/START.md` (gerade `overworld`).
- Erledigtes nach „Erledigt“ verschieben, mit Datum und PR.

## Bereit

1. **Kleinkram**
   - `BrewSlot` und `BrewWindow` verweisen gegenseitig aufeinander (`var window: BrewWindow` ↔ `preload(brew_slot.tscn)`). Beim Laden in ungünstiger Reihenfolge meldet Godot einen Parse-Fehler (im Testlauf sichtbar). Kreis auflösen, ohne das Verhalten zu ändern.
   - Erledigte Branches `combat-overhaul` und `quality-overhaul` sind vollständig in `main`. Löschen nur mit Robins Okay, hier nur notieren.

## Wartet auf Robin

- **Gnarl und Upgrades testen.** Die Upgrades sind gerade praktisch nur über F8 erreichbar, weil Weidenrinde und Höhlenkristall nur im Seewald v2 wachsen. Das Digitalis-Kapitel im Grimoire zeigt die Stufe noch nicht (Kerben, „Gnarl braucht …“, `grimoire.md` Abschnitt Digitalis); das wäre ein Folgeschritt, sobald das Kapitel mehr als Silhouetten zeigt.
- **Seewald v2 testen (F8).** Blockiert: Ausgänge auf `lakewood_v2.tscn` umstellen, alten Seewald entfernen (W5), danach Höhen für Wald, Dorf und Garten.
- **`overworld` nach `main` mergen.** `overworld` ist rund 30 Commits vor `main`. Nach Robins Test mergen, damit es wieder einen stabilen Stand gibt.
- **Schritt 8: Turmruine, Blütennebel S5, erstes Blütenherz.** Der Boss braucht erst einen Entwurf (Aussehen, Ablauf, Belohnung).
- ❓ **Garten und Seewald zusammenlegen?** (`overworld_plan.md`, offene Fragen)
- ❓ **Alte Spielstände beim Garten-Umbau** (`overworld_plan.md` Abschnitt 7)
- **Grimoire mit echten Grafiken** (`docs/auftraege/auftrag_grimoire_umbau.md`), wartet auf Robins Grafik-Paket.
- **Große Welt-Sprites der Bitterblüte** (`docs/auftraege/grafik_auftrag_bitterbloom.md`), macht Robin.

## Erledigt

- 03.11.2026: Wasser-Animation: 4 Frames pro Wasserfeld über die Kachel-Animation des TileSets, Platzhalter-Frames aus `water.py`, Builder unverändert (setzt Frame 0). Test `tests/test_water.gd`. Branch `claude/autopilot`.
- 03.11.2026: Schritt 7, Gnarl und Upgrades: Gnarl im tiefen Wald, Heiltrank als Gabe, Umzug in die Dorf-Werkstatt zur nächsten Nacht (7a); Stab II, Sichel II, Kessel mit 4 Plätzen als Tausch bei Gnarl (7b). Tests `tests/test_gnarl.gd`, `tests/test_upgrades.gd`. PR #3 (`claude/gnarl-upgrades`).
- 03.11.2026: Herbarium-Einträge für Weidenrinde, Mondwasser, Höhlenkristall, Sumpflicht, Bitterblütenblatt und Blütenknospe (Mondmoos und Eulenfeder hatten schon einen), Test `tests/test_herbarium.gd`. PR #2 (`claude/herbarium-eintraege`).
- 03.11.2026: Tests im Repo (`tests/`), Godot-Setup für Cloud-Sessions (`tools/setup_godot.sh`), Regeln für Arbeit ohne Robin in `CLAUDE.md`, doppelte Text-Schlüssel `DIGITALIS_STAFF`/`DIGITALIS_SICKLE` entfernt.
