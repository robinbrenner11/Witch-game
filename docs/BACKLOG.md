# Backlog

Stand: 03.11.2026. Aufgabenliste für Sessions, die ohne Robin laufen (Regeln: `CLAUDE.md` Abschnitt 10 und 13).

- **Bereit**: darf ohne Rückfrage umgesetzt werden, von oben nach unten.
- **Wartet auf Robin**: erst anfangen, wenn Robin es nach „Bereit“ verschiebt.
- Eine Aufgabe pro Session. Branch `claude/<thema>`, PR gegen den Arbeitsbranch aus `docs/START.md` (gerade `overworld`).
- Erledigtes nach „Erledigt“ verschieben, mit Datum und PR.

## Bereit

1. **Herbarium-Einträge für die neuen Items**
   Höhlenkristall, Weidenrinde, Mondwasser, Sumpflicht, Blütenknospe, Mondmoos, Eulenfeder (alle, denen noch ein Eintrag fehlt). Erst nachsehen, wie `scripts/ui/grimoire/spread_herbarium.gd` seine Einträge bildet, und dem bestehenden Muster folgen. Fundorte stehen in `docs/design/welt_und_items.md`. Texte en/de in `texts.csv`. Fertig, wenn jeder Herbarium-fähige Gegenstand einen Eintrag hat und ein Test das prüft.

2. **Schritt 7: Gnarl und Upgrades**
   Wie in `docs/design/welt_und_items.md` Abschnitt 6 beschrieben: Gnarl im tiefen Wald, zieht nach Hilfe in die Dorf-Werkstatt; Upgrades als Tausch mit neuem `RewardData`-Typ `UPGRADE` (Stab II, Sichel II, Kessel 4 Plätze). Höhlenkristall und Blütenknospe bekommen damit ihre Verwendung. Dialoge im Stil der bestehenden NPCs (`docs/VILLAGE_HUB.md`). Wenn Gnarls Persönlichkeit oder Hintergrund nicht festgelegt ist: knapp und neutral schreiben, als „Von mir entschieden“ markieren. Bei Bedarf in kleine PRs teilen (erst Gnarl + Dialog, dann Upgrades).

3. **Wasser-Animation**
   Kachel-Animation im Wasser-TileSet (3–4 Frames) wie in `docs/design/overworld_plan.md` Abschnitt 3 beschrieben. Platzhalter-Frames per Generator in `docs/art/`, Robins echte Grafik ersetzt sie später. Der World-Builder muss die animierten Kacheln weiter richtig setzen.

4. **Kleinkram**
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

- 03.11.2026: Tests im Repo (`tests/`), Godot-Setup für Cloud-Sessions (`tools/setup_godot.sh`), Regeln für Arbeit ohne Robin in `CLAUDE.md`, doppelte Text-Schlüssel `DIGITALIS_STAFF`/`DIGITALIS_SICKLE` entfernt.
