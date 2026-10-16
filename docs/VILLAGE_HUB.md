# Dorf-Hub

Stand: 12.10.2026, Branch `village-hub` (Meilensteine M1 bis M7, danach Umbau nach Robins Feedback: Seewald, organisches Dorf).
Plan und Entscheidungen: `docs/design/dorf_hub_plan.md`.

Kurz: Ins Dorf (Graybox) kommt man nur über den **Seewald**, einen friedlichen, offenen Wald mit See zwischen Garten und tiefem Wald. Im Dorf geht der **Nachtwächter** jede Nacht seine Runde. Wer ihn zum ersten Mal anspricht, bekommt die **Hexenpforte** geöffnet, eine Abkürzung oben am See (nahe beim Garten) ins Dorf. Danach erzählt er Gerüchte, die im Grimoire eine Zutat verraten.

## 0. Welt (Entscheidung 12.10.2026)

```text
        [Unterschlupf]
              |
          [Garten]
              | Süd
        [Seewald] --Pforte (NO, verriegelt bis zum Kennenlernen)--> [Dorf] von Westen, oben
         See, friedlich --Waldweg (SO, offen)---------------------> [Dorf] von Westen, unten
              | Süd
        [Tiefer Wald]  Befall, Käfer
```

- **Seewald** (`scenes/world/lakewood.tscn`, Node `Lakewood`): offener Wald, Wiese, See als Graybox (`Lake`, Pixelblöcke, Mondspiegelung je nach Mondphase), Trauerweiden, Kröten, Glühwürmchen. Keine Gegner, keine NPCs (vorerst).
- **Dorf**: unregelmäßiger Waldrand, geschwungene Pflasterstraße vom Waldweg zum unregelmäßigen Platz, Gassen aus Trampelpfad, gemauerter Markt im Osten, Häuser versetzt. Beide Eingänge im Westen, passend zur Richtung, aus der man kommt.
- Erzeugt wurden Boden und Deko beider Orte mit einem Hilfsskript (nicht im Repo). Von Hand weiterbauen im Editor geht ganz normal.

---

## 1. Bausteine

```text
WorldState (Autoload)      Flags, die bleiben (gespeichert) + Merker für heute Nacht (nicht gespeichert)
NpcData      data/npcs/<id>.tres            Name, Routine (ScheduleEntry), Tempo, appears_flag
ScheduleEntry  in NpcData eingebettet       ab Uhrzeit: Ort, Spot oder Streife, Gesprächsthema
DialogueData data/dialogue/<npc>/<id>.tres  Zeilen + Bedingungen + Folgen
Npc          scenes/npcs/npc.tscn           zeigt einen NPC an, läuft, spricht
DialogueBox  scenes/ui/dialogue_box.tscn    Fenster unten, pausiert das Spiel
Exit / GardenGate                           neu: required_flag (gesperrt, bis das Flag gesetzt ist)
GrayboxBuilding scripts/world/graybox_building.gd  Platzhalter-Haus aus Farbflächen
```

- **Zeit:** NPCs lesen nur `DayCycle.minutes`, es gibt kein zweites Zeitsystem. Gerechnet wird in „Minuten seit 18 Uhr“, damit 23:00 bis 2:00 kein Sonderfall ist. Ab 6 Uhr ist kein Block aktiv, der NPC ist weg.
- **Spots** sind `Marker2D` unter `Spots` im Level. Der NPC läuft in gerader Linie dazwischen, ohne Navigationsnetz. Spots so setzen, dass die Wege frei sind. Hängt er trotzdem 3 Sekunden fest, steht er einfach am Ziel (Warnung im Protokoll).
- **Gespräch wählen:** Von allen Gesprächen, deren Bedingungen passen, gewinnt die höchste `priority`, bei Gleichstand zufällig. Ein Rückfall mit Priorität 0 ohne Bedingungen sorgt dafür, dass er nie stumm ist.
- **Folgen eines Gesprächs** (`Npc._after_talk`): `once` merkt sich das Gespräch als Flag `dlg_<npc>_<id>`, `once_per_night` im Nacht-Merker, `sets_flag` setzt ein Flag, `hint_recipe`/`hint_ingredient` ruft `Grimoire.hint_ingredient()` auf, `after_message` zeigt eine Meldung. Immer: Flag `met_<npc>` und `Grimoire.report("talk", {"id": npc})`.

## 2. So geht …

**ein neuer NPC:** `data/npcs/<id>.tres` (NpcData mit Routine) anlegen. Eine geerbte Szene von `scenes/npcs/npc.tscn` erstellen (Farben, Laterne o. Ä.) und `data` setzen. Die Szene in den Ort unter `Objects` setzen; die Position ist egal, er stellt sich selbst an seinen Spot. Fehlende Spots im Ort anlegen. Name als Schlüssel in `texts.csv`.

**ein neues Gespräch:** neue `.tres` in `data/dialogue/<npc>/` mit Zeilen (Text-Schlüssel) und Bedingungen. Kein Code nötig. Höchstens 3 Zeilen Text pro Seite der Dialogbox (auf Deutsch prüfen, das ist länger).

**einen gesperrten Weg:** am `Exit` (und ggf. am `GardenGate`) `required_flag` eintragen. Solange das Flag fehlt, bleibt das Tor zu, und der Ausgang meldet `locked_message`. Freischalten: irgendein System ruft `WorldState.set_flag("…")` auf, z. B. ein Gespräch über `sets_flag`.

**Tausch bei einem NPC (16.10.):** pro Angebot eine `.tres` in `data/trades/<npc>/` (`TradeOffer`: will Item und Menge, gibt Item und Menge, optional `per_night`, Mondphasen, Flags). Kein Code nötig: Nach jedem Gespräch zeigt der NPC die Angebote in der Antwort-Auswahl der Dialogbox, nach einem Tausch erneut, bis „Gerade nichts“ oder Esc. Erster Händler: Mutter Moos im Seewald v2.

**einen NPC erst später auftauchen lassen:** `appears_flag` in seinen Daten. Laut Design erscheinen neue NPCs nur durch eine Aktion der Spielerin.

## 3. Der Nachtwächter

| Ab | Spot | Thema |
|---|---|---|
| 18:00 | Wachstube | – |
| 20:00 | Brunnen | `rumor` |
| 23:00 | Streife Brunnen → Markt → Kapelle | – |
| 02:00 | Waldtor | `forest_gate` |
| 05:00 | Wachstube | `dawn` |
| 05:40 | drinnen | – |

| Gespräch | Priorität | Bedingung | Folge |
|---|---|---|---|
| `first_meeting` | 100 | einmalig | Flag `witch_gate_open`, Meldung „Pforte offen“ |
| `rumor_mending`, `rumor_ember`, `rumor_growth` | 20 | Thema `rumor`, je einmal, eins pro Nacht, nur wenn das Rezept unbekannt ist | Zutat im Grimoire (Geisterfarn → Heiltrank, Glutmorchel → Glutbombe, Alraune → Wachstumstrank) |
| `forest_gate_brother` | 15 | Thema `forest_gate`, einmalig | – |
| `dawn` | 15 | Thema `dawn` | – |
| `moon_new`, `moon_full` | 10 | Neu- bzw. Vollmond, einmal pro Nacht | – |
| `smalltalk_1..3` | 0 | immer | – |

## 4. Steuerung und Debug

- **E** spricht an bzw. blättert weiter (auch Leertaste oder Klick). Tippt die Zeile noch, wird sie erst ganz gezeigt. **Esc** schließt die Dialogbox.
- **F6** (nur Editor/Debug-Build): eine Stunde vor. Morgen, Warnung und neue Nacht lösen dabei aus wie sonst.

## 5. Tests (12.10.2026)

Godot 4.7.1, headless und unter Xvfb. Die Prüfskripte liegen nicht im Repo.

| Meilenstein | Ergebnis |
|---|---|
| M1 Dorf, Wege, Kamera, Kollision | 20 / 20 |
| M2 Flags und Spielstand (auch alter Stand ohne `world`) | 12 / 12 |
| M3 Dialogbox (Tasten, Klick, Esc, Pause, Deutsch) | 17 / 17 |
| M4 Routine-Blöcke, Ansprechen, tagsüber weg, appears_flag | 27 / 27 |
| M5 alle 8 Wege frei, Tempo, Hexe im Weg, Streife, Ansprechen beim Laufen | 21 / 21 |
| M6 Gesprächsauswahl, Gerüchte, alle Texte übersetzt und ≤ 3 Zeilen | 20 / 20 |
| M7 Pforte zu, Kennenlernen öffnet, Durchgang in beide Richtungen, Spielstand | 17 / 17 |

Alle 310 Szenen, Scripts und Ressourcen laden ohne Fehler; die neuen Scripts erzeugen keine Editor-Warnungen. Nicht geprüft: echtes Spielgefühl, Ton, Windows.

## 6. Platzhalter und bekannte Grenzen

- **Graybox:** Häuser, Laternen, Anschlagbrett und der Wächter selbst sind Farbflächen. Eine Grafik kann jeweils an dieselbe Stelle treten (Häuser als `Decor`-Szene, der Wächter als `AnimatedSprite2D` in `watchman.tscn` statt `Figure`).
- **Hexenpforte im Seewald:** Die senkrechte Zaungrafik ist von oben sehr schmal; als Pforte ist sie nur über die Glutlaternen daneben zu erkennen. Eine eigene Torgrafik würde helfen.
- **See:** Platzhalter aus Farbflächen, bis es Wasser-Tiles gibt.
- Der Wächter dreht sich nicht zur Hexe und hat außer einem Wippen keine Laufanimation.
- Lädt man mitten in einer Streife, beginnt sie am ersten Spot.
- Der Nacht-Merker wird nicht gespeichert: Speichert man mitten in der Nacht über das Pausemenü und lädt, kann eine Mond-Zeile einmal doppelt kommen.
- Ein Gerücht verrät eine Zutat, auch wenn das Grimoire noch nicht gefunden ist (es steht dann später darin).

## 7. Nächste mögliche Schritte (nicht gebaut)

- **M8 (optional, laut Plan):** Baustein `Unlockable` für Gebäude/Dienste, Marktstände bei Halbmond, Motten an den Dorflaternen.
- Kapitel **People** im Grimoire mit dem Wächter füllen (`NpcData.role_key` ist dafür schon da).
- Zweiter NPC mit Tausch und Antwort-Auswahl in der Dialogbox (Grafiken `dialog_choice_bg`, `dialog_cursor` liegen bereit).
- 💡 Dorf später erst über eine Quest erreichbar: `required_flag` am Ausgang `ToVillage` im Seewald.
- Seewald beleben: Mother Moss (Samen-Tausch) und Ugo bei Halbmond wären Kandidaten aus dem Game Design (noch nicht entschieden).
