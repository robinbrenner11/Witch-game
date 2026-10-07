Wir passen heute den Garten- und Brau-Piloten an neue Design-Entscheidungen an. Lies zuerst CLAUDE.md, dann `docs/design/design_entscheidungen_2026-10-07.md` (alle Entscheidungen von heute), `docs/design/checkliste_basics.md` und `docs/art/neue_assets.md` (neue Grafiken). Verschaff dir einen Überblick über scripts/, data/ und scenes/.

Arbeite die Schritte unten der Reihe nach ab. Nach jedem Schritt: kurz zusammenfassen, was du geändert hast, sagen, wie ich es im Spiel teste, einen Commit vorschlagen und auf mein OK warten, bevor du weitermachst. Wenn etwas unklar ist oder mit dem bestehenden Code kollidiert, frag nach statt zu raten. Nicht ohne meine Zustimmung pushen.

Begriffe: Der Fehlschlag-Trank heißt weiterhin "Hexenschlamm" (`potion_sludge`).

## Schritt 0: Neue Dateien einordnen
- Ich habe neue Grafiken, Generatoren und Vorschauen ins Projekt kopiert (siehe `LIESMICH.md` im Projektordner). Prüf kurz, ob Godot alles importiert hat.
- `docs/art/neue_farben.md` listet die neuen Zwischentöne. Zeig mir die Liste kurz; wenn ich zustimme: ergänze `docs/art/hexen_palette.gpl` (Vorlage: `docs/art/hexen_palette_erweitert.gpl`) und passe in CLAUDE.md die Regel "begrenzte Farbpalette" an die gelockerte Regel an (siehe Design-Entscheidungen, Abschnitt 6).
- Ergänze `docs/ASSETS.md` um die neuen Grafiken (Angaben in `docs/art/neue_assets.md`).
- Ergänze die Ideensammlung in CLAUDE.md um einen kurzen Verweis auf `docs/design/design_entscheidungen_2026-10-07.md` und `docs/design/checkliste_basics.md`, damit du beides in künftigen Sessions kennst.

## Schritt 1: Startsamen, Ernte, Leuchten (Daten + kleine Code-Änderungen)
- Startsamen in `inventory.gd`: Alraune, Geisterfarn, Laternenbeere (je 3). Nachtschatten, Mondkelch und Blutrose soll man später finden. Zum Testen eine Debug-Taste, die alle 6 Samensorten ins Inventar legt (analog zu `debug_next_day`).
- Ernte gibt vorerst zusätzlich 1 Samen derselben Sorte zurück. Bitte als Wert in `PlantData` (z. B. `seeds_on_harvest`), damit es später leicht wieder raus oder anders geht.
- Leuchten: Laternenbeere leuchtet (wie bisher). Mondkelch leuchtet schwächer und mit kleinerem Radius. Alraune und Geisterfarn leuchten nicht mehr.

## Schritt 2: Gartendaten in ein Autoload + Bett + Speichern
Hintergrund: Garten, Unterschlupf und Wald werden später eigene Szenen. Pflanzen dürfen ihren Zustand nicht nur im Szenen-Node halten.
- Neues Autoload (z. B. `Garden`), das pro Beet speichert, was wächst und in welcher Stufe. Beete/Pflanzen lesen ihren Zustand beim Laden daraus und schreiben Änderungen zurück. Wachstum über Nacht läuft weiter über `DayCycle.day_passed`.
- **Bett**: Grafiken `assets/environment/props/bed.png` (leer) und `bed_sleeping.png` (Hexe schläft), je 32×64 = 1×2 Tiles. Interaktion per E über den bestehenden Interactable-Baustein. Schlafen: Hexe ausblenden, `bed_sleeping.png` zeigen, schwarz überblenden, Zeit springt auf den Beginn der nächsten Nacht (18:00), `day_passed` wird ausgelöst, wieder einblenden, Hexe steht neben dem Bett.
- Das **Hexenfeuer bleibt** wie es ist (Zeitraffer). Bett = Tag überspringen und speichern.
- **Speichern beim Schlafen**: Nacht, Uhrzeit, Inventar (inkl. Plätze), Gartenzustand und Kesselzustand in eine Datei unter `user://`. Beim Start laden, falls vorhanden. Debug-Taste zum Löschen des Spielstands.

## Schritt 3: Wachstumsregeln + Nachtschatten-Kuppel
- **Hexenschlamm als Dünger**: Mit Hexenschlamm in der Hand per E auf eine Pflanze wächst diese eine Pflanze sofort 1 Stufe. Der Schlamm wird verbraucht.
- **Wachstumstrank** (`potion_growth`): alle Pflanzen im 3×3-Bereich um das Beet, auf das man ihn anwendet, wachsen sofort 1 Stufe.
- **Nachtschatten-Hemmung**: Pflanzen auf den 8 umliegenden Feldern (auch diagonal) wachsen über Nacht nicht, außer es sind selbst Nachtschatten. Erst ab Stufe 2 des Nachtschattens. Bitte allgemein bauen: `PlantData` bekommt Aura-Felder (Reichweite + Wirkung), damit später auch positive Auren möglich sind. Die Prüfung gehört in `can_grow_tonight()`.
- Regel: Natürliches Wachstum kann blockiert sein, Magie (Hexenschlamm, Wachstumstrank) setzt sich darüber hinweg.
- **Gehemmte Pflanzen welken sichtbar**: per `modulate` entsättigt und kühl-dunkel einfärben (Richtwert: etwa Color(0.55, 0.62, 0.85) auf eine Graustufen-Version – schlag vor, wie das in Godot am saubersten geht, z. B. kleiner Shader oder nur modulate).
- **Kuppel** (siehe `docs/art/vorschau/vorschau_kuppeln_verschmolzen_3x.gif`): Über jedem hemmenden Nachtschatten liegt eine geisterhaft blaue, halbtransparente Kuppel über dem 3×3-Bereich, die leicht pocht. **Mehrere Kuppeln verschmelzen** zu einer gemeinsamen Glocke statt sich zu überschneiden. Deshalb bitte als **Shader** auf einer Fläche über dem Garten (über den Pflanzen), der die Positionen aller aktiven Nachtschatten bekommt. Die exakte Rechnung steht in `docs/art/plant_generators/nightshade_aura.py` (Funktionen `field`, `smin`, `render_domes`) – bitte daraus übernehmen:
  - Mittelpunkt je Kuppel = Mitte des Beet-Tiles (Wurzelpunkt − 5 px).
  - Pro Kuppel Ellipsenwert `d = ((x-cx)/49)² + ((y-cy)/ry)²` mit `ry = 60` oberhalb von `cy` und `ry = 47` unterhalb.
  - Alle Werte per weichem Minimum verschmelzen: `smin(a, b, k=0.35)`. Innen = Wert ≤ 1.
  - Rand 1 px: oben links Eisblau `#CED6F4`, sonst Geisterblau `#788CB9`. Füllung: Nachtblau hell `#344678` mit niedriger Deckkraft, am Rand (Wert > 0.72) im Schachbrett dichter. Glanzbogen und Stern oben links je Kuppel, Bodenring vorne – nur dort, wo keine Nachbarkuppel ist.
  - Pochen: Intensität 0 → 0.5 → 1 → 0.5, Dauer 0.7 s / 0.18 s / 0.26 s / 0.18 s. Füllung-Alpha 28→54 (von 255), Rand-Alpha 150→240.
  - Pixelgenau: in ganzen Welt-Pixeln rechnen (Koordinaten abrunden), kein Anti-Aliasing.
  - Falls der Shader zu aufwendig wird: erst mit dem Einzel-Sprite `assets/effects/nightshade_dome.png` (4 Frames à 120×120, Wurzelpunkt bei (60, 69)) bauen und den Shader als eigenen Schritt danach.
- **Debuff für die Hexe**: noch **nicht** bauen (kommt später, Icon liegt schon unter `assets/ui/debuff_nightshade.png`).

## Schritt 4: Kessel mit Brau-Fenster und neuen Rezepten
Mockup: `docs/art/vorschau/vorschau_braufenster_v2_2x.png` (vier Zustände). Alle Teile liegen als `assets/ui/brew_*.png` in **1×**; das Fenster wird in Godot **doppelt so groß** angezeigt (z. B. `scale = 2` am Fenster-Root). Die Hotbar-Slot-Grafik ist 2× vorskaliert – im Brau-Fenster daher auf 20×20 anzeigen (exakte Halbierung, bleibt pixelscharf). Positionen (in 1×) stehen in `docs/art/ui_generator/brew_window.py`, Funktion `window_v2`.
- Per E am Kessel öffnet sich das Fenster. Zeit und Spiel pausieren, solange es offen ist.
- **Mitwachsende Felder im Bogen über dem Kessel**: Anfangs ein leeres Feld. Ist es belegt, erscheint daneben das nächste leere Feld – bis die Kapazität des Kessels erreicht ist. Felder im flachen Bogen anordnen (`slot_positions` im Generator).
- **Kessel-Kapazität** als Datenwert (Start: 3, später durch Upgrade mehr). **Kapazitäts-Rauten** unter dem Kessel: `brew_pip.png` belegt, `brew_pip_empty.png` frei.
- Darunter das Inventar (24 Plätze). Items per **Drag & Drop** aus dem Inventar in die Felder ziehen und wieder zurück. Schließen per E oder Esc legt nicht verbrauchte Zutaten zurück ins Inventar.
- Ab 2 Zutaten: `brew_cauldron_ready.png` statt `brew_cauldron.png`, `brew_arrow_active.png` statt `brew_arrow.png`, Knopf `brew_button.png` statt `brew_button_disabled.png` (gedrückt: `brew_button_pressed.png`). Knopf-Text "Brauen" mit der Schrift m5x7.
- **Ergebnis-Feld**: bekanntes Rezept → Trank-Icon + Name unter dem Kessel; unbekannt → `brew_unknown.png` + "???". (Falls dir das spielerisch komisch vorkommt, sag Bescheid.)
- **Brauen über Nacht**: Der Trank ist nach dem nächsten Schlafen bzw. `day_passed` fertig und wird am Kessel abgeholt. 1 Trank pro Vorgang. Kesselzustand mit speichern (Schritt 2).
- `RecipeData` umbauen auf eine **Zutatenliste** (2 bis Kapazität, Reihenfolge egal: beim Vergleich sortieren). Alles, was kein Rezept ist (auch doppelte Zutaten), ergibt Hexenschlamm.
- Das bestehende Rezept (Alraune + Mondkelch) entfällt. Neue Rezepte als Dateien in `data/recipes/`, neue Tränke als Dateien in `data/items/` (Icons liegen schon in `assets/items/`):

| Zutaten | Item-ID | Name | Wirkung (vorerst) | Nutzung |
|---|---|---|---|---|
| crop_mandrake + crop_ghost_fern | potion_growth | Wachstumstrank | siehe Schritt 3 | ausgießen |
| crop_lantern_berry + crop_nightshade | potion_will_o_wisp | Irrlicht | ein kleines Licht folgt der Hexe für den Rest der Nacht | trinken |
| crop_mandrake + crop_ghost_fern + crop_moon_chalice | potion_moon_harvest | Mondernte | alle Pflanzen im 3×3 sofort erntereif (Mondkelch ausgenommen) | ausgießen |
| crop_lantern_berry + crop_nightshade + crop_moon_chalice | potion_liquid_moonlight | Flüssiges Mondlicht | großes Licht um die Hexe für den Rest der Nacht (verborgene Items kommen später) | trinken |
| crop_blood_rose + crop_nightshade + crop_mandrake | potion_endless_night | Ewige Nacht | die aktuelle Nacht dauert 50 % länger | trinken |

- In `ItemData` festhalten, ob ein Trank getrunken oder ausgegossen wird, plus Beschreibungstext (Texte in den Design-Entscheidungen, Abschnitt 5). Getrunken z. B. per Rechtsklick oder eigener Taste, ausgegossen per E auf ein Beet. Schlag vor, was sich mit der bestehenden Steuerung am besten verträgt.
- Wenn Schritt 4 zu groß für einen Durchgang ist, teile ihn auf (erst Rezepte + Fenster, dann Über-Nacht-Brauen und Trinken).

## Zum Schluss
- CLAUDE.md / Ideensammlung mit dem umgesetzten Stand aktualisieren (✅ für Umgesetztes).
- In `docs/design/checkliste_basics.md` erledigte Punkte abhaken.
- Liste, was fehlt oder als Nächstes sinnvoll ist (aus der Checkliste).
