# Backlog

Stand: 03.11.2026. Aufgabenliste für Sessions, die ohne Robin laufen (Regeln: `CLAUDE.md` Abschnitt 10 und 13).

- **Bereit**: darf ohne Rückfrage umgesetzt werden, von oben nach unten.
- **Wartet auf Robin**: erst anfangen, wenn Robin es nach „Bereit“ verschiebt.
- Eine Aufgabe pro Session. Branch `claude/<thema>`, PR gegen den Arbeitsbranch aus `docs/START.md` (gerade `overworld`).
- Erledigtes nach „Erledigt“ verschieben, mit Datum und PR.

## Bereit

1. **Schritt 7b: Upgrades bei Gnarl**
   Gnarl selbst steht (7a, siehe „Erledigt“). Wie in `docs/design/welt_und_items.md` Abschnitt 6 beschrieben: Upgrades als Tausch mit neuem `RewardData`-Typ `UPGRADE` (Stab II, Sichel II, Kessel 4 Plätze). Höhlenkristall und Blütenknospe bekommen damit ihre Verwendung. Dialoge im Stil der bestehenden NPCs (`docs/VILLAGE_HUB.md`). Wenn Gnarls Persönlichkeit oder Hintergrund nicht festgelegt ist: knapp und neutral schreiben, als „Von mir entschieden“ markieren. Bei Bedarf in kleine PRs teilen (erst Gnarl + Dialog, dann Upgrades).

2. **Wasser-Animation**
   Kachel-Animation im Wasser-TileSet (3–4 Frames) wie in `docs/design/overworld_plan.md` Abschnitt 3 beschrieben. Platzhalter-Frames per Generator in `docs/art/`, Robins echte Grafik ersetzt sie später. Der World-Builder muss die animierten Kacheln weiter richtig setzen.

3. **Kleinkram**
   - `BrewSlot` und `BrewWindow` verweisen gegenseitig aufeinander (`var window: BrewWindow` ↔ `preload(brew_slot.tscn)`). Beim Laden in ungünstiger Reihenfolge meldet Godot einen Parse-Fehler (im Testlauf sichtbar). Kreis auflösen, ohne das Verhalten zu ändern.
   - Erledigte Branches `combat-overhaul` und `quality-overhaul` sind vollständig in `main`. Löschen nur mit Robins Okay, hier nur notieren.

## Wartet auf Robin

- **Seewald v2 testen (F8).** Blockiert: Ausgänge auf `lakewood_v2.tscn` umstellen, alten Seewald entfernen (W5), danach Höhen für Wald, Dorf und Garten.
- **`overworld` nach `main` mergen.** `overworld` ist rund 30 Commits vor `main`. Nach Robins Test mergen, damit es wieder einen stabilen Stand gibt.
- **Schritt 8: Turmruine, Blütennebel S5, erstes Blütenherz.** Der Boss braucht erst einen Entwurf (Aussehen, Ablauf, Belohnung).
- ❓ **Garten und Seewald zusammenlegen?** (`overworld_plan.md`, offene Fragen)
- ❓ **Alte Spielstände beim Garten-Umbau** (`overworld_plan.md` Abschnitt 7)
- **Grimoire mit echten Grafiken** (`docs/auftraege/auftrag_grimoire_umbau.md`), wartet auf Robins Grafik-Paket.
- **Große Welt-Sprites der Bitterblüte** (`docs/auftraege/grafik_auftrag_bitterbloom.md`), macht Robin.

## Erledigt

- 03.11.2026: Schritt 7a, Gnarl: im tiefen Wald, Heiltrank als Gabe, Umzug in die Dorf-Werkstatt zur nächsten Nacht. Test `tests/test_gnarl.gd`. Branch `claude/gnarl-upgrades`.
- 03.11.2026: Herbarium-Einträge für Weidenrinde, Mondwasser, Höhlenkristall, Sumpflicht, Bitterblütenblatt und Blütenknospe (Mondmoos und Eulenfeder hatten schon einen), Test `tests/test_herbarium.gd`. PR #2 (`claude/herbarium-eintraege`).
- 03.11.2026: Tests im Repo (`tests/`), Godot-Setup für Cloud-Sessions (`tools/setup_godot.sh`), Regeln für Arbeit ohne Robin in `CLAUDE.md`, doppelte Text-Schlüssel `DIGITALIS_STAFF`/`DIGITALIS_SICKLE` entfernt.
