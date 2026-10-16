# Bitterbloom – Einstieg

Stand: 16.10.2026. **Das hier zuerst lesen**, danach nur die Dokumente, die die Aufgabe braucht. Regeln für die Zusammenarbeit und die technischen Leitplanken stehen in `CLAUDE.md`.

## Stand in einem Absatz

Bitterbloom ist ein Cozy RPG, das nur nachts spielt (Godot 4.7, GDScript). Spielbar sind: Garten mit Wachstum über Nacht, Brauen am Kessel, Trinken und Werfen von Tränken, Sammeln mit Nachwachsen, Truhe, Grimoire mit Disziplinen und Hexenpfaden, Mondphasen (8 Nächte), Kampf mit Digitalis (Stab und Sichel) gegen befallene Käfer, Sonne ab 6 Uhr, Speichern beim Schlafen. Dazu der Dorf-Hub (Graybox) mit Nachtwächter, Dialogen und Gerüchten, Gesuche am Anschlagbrett, Tausch mit Mother Moss und Ugo, Sperren (Gates) und Orte mit Höhen aus Bauplänen (Seewald v2, Wasserfall-Höhle, Sumpf). Viele Grafiken sind Platzhalter. Die echten macht Robin selbst mit dem Plugin.

## Branches

| Branch | Inhalt |
|---|---|
| `main` | stabiler Stand (Kampf, Quality Overhaul) |
| `village-hub` | Dorf-Hub M1–M8 |
| `overworld` | **aktuell**: Höhen, World-Builder, Sperren, Gesuche, neue Orte und NPCs (baut auf `village-hub` auf) |

Nach `main` wird nur mit Robins Okay gemergt und gepusht.

## Nächste Schritte

Gepflegt in `docs/design/welt_und_items.md`, Abschnitt 10 („Nächste Schritte“). Kurz:
1. Schritt 7: Gnarl und Upgrades (neuer `RewardData`-Typ `UPGRADE`)
2. Schritt 8: Turmruine, Sperre S5, erstes Blütenherz (Boss braucht einen eigenen Entwurf)
3. Nach Robins Test von Seewald v2 (F8): Ausgänge umstellen, alten Seewald entfernen, Höhen für Wald, Dorf und Garten

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
- Debug-Tasten: F3–F5 Grimoire, F7 Höhen-Test, F8 Seewald v2
- Tests laufen headless (`godot --headless --script <pfad>`). Prüfskripte liegen nicht im Repo.
