# Grafik-Auftrag vom 07.10.2026 – ERLEDIGT

Nur zur Info. Alle Grafiken sind im Chat entstanden und liegen in diesem Paket.
Abweichungen vom ursprünglichen Auftrag (nach Robins Feedback):

- Irrlicht: Variante mit zwei herausschwebenden Funken.
- Bett: ohne Falten; schlafende Hexe mit Decke bis über die Nase (Arm und Zierkissen entfernt).
- Brau-Fenster: statt fester 3 Felder mitwachsende Felder im Bogen über einem Kessel, Kessel aufrüstbar, Kapazitäts-Rauten, "?"-Icon, deaktivierter Knopf. UI in 1× gespeichert.
- Nachtschatten: statt kriechender Ranken eine geisterhaft blaue, pochende Kuppel über dem 3×3-Bereich; mehrere Kuppeln verschmelzen. Dazu ein Debuff-Icon.

---

Wir erstellen heute neue Pixel-Art-Grafiken für den Garten- und Brau-Piloten. Lies zuerst CLAUDE.md (Abschnitt Visuelle Identität), docs/art/hexen_palette.gpl und die bestehenden Generatoren in docs/art/ (vor allem plant_generators/pix.py, plant_generators/icons.py, ui_generator/hotbar.py, world_generator/props.py). Schau dir auch die bestehenden Grafiken an, damit die neuen dazu passen: assets/items/potion_growth.png, assets/items/potion_sludge.png, assets/environment/props/cauldron.png und die Hotbar-Grafiken in assets/ui/.

Arbeite wie bisher mit Python-Generatoren (Pillow), damit ich Grafiken später leicht anpassen kann. Lege für jede Grafik eine 4x-Vorschau in docs/art/vorschau/ an.

## Wichtig: Palette lockern
Bisher hast du ausschließlich die Farben aus hexen_palette.gpl benutzt. Das wirkt teilweise zu hart. Ab jetzt gilt:
- Die Palette bleibt die Basis und die Farbsemantik bleibt (Magenta = Magie, Gold = Wertigkeit/UI, Giftgrün = Pflanzen/Tränke usw.).
- Du darfst zusätzliche Zwischentöne und passende Farben verwenden, damit Verläufe natürlicher wirken, z. B. 1-2 Abstufungen zwischen zwei Palettenfarben oder einen etwas helleren Glanzpunkt.
- Gute Pixel-Art-Farbrampen: Schatten leicht Richtung Blau/Violett verschieben, Lichter leicht Richtung Gelb/Warm, statt nur dunkler/heller zu machen.
- Weiterhin: harte Pixelkanten, kein Anti-Aliasing, keine weichen Gradienten, Licht von oben links, Aubergine-Outlines statt Schwarz.
- Pro Grafik trotzdem sparsam bleiben (Richtwert: höchstens 8-12 Farben).
- Alle neu verwendeten Farben sammelst du am Ende in einer Liste. Wenn ich zustimme, ergänzt du sie in hexen_palette.gpl und passt die Palettenregel in CLAUDE.md an.

## Arbeitsweise
Ich möchte zwischendurch Zwischenstände sehen statt nur das fertige Ergebnis. Zeig mir zuerst eine erste Grafik (den ersten Trank) als Vorschau und warte auf mein Feedback, bevor du den Stil auf die anderen überträgst. Danach jede Gruppe (Tränke, Bett, Brau-Fenster, Aura) einzeln zeigen und auf mein OK warten. Wenn du für eine Grafik zwei Varianten siehst, zeig beide.

## 1. Vier Trank-Icons (16x16, wie potion_growth.png)
Alle vier sollen klar als Tränke einer Familie erkennbar sein, aber sich in Flaschenform und Farbe unterscheiden, damit man sie in der Hotbar sofort auseinanderhält.
- potion_will_o_wisp.png (Irrlicht): kleines Fläschchen, Inhalt leuchtend und flackernd, kaltes Geisterblau/Flieder, ein einzelner heller Lichtpunkt im Inneren. Stimmung: verführerisch, ein bisschen unheimlich.
- potion_moon_harvest.png (Mondernte): bauchige Flasche, Inhalt Giftgrün mit silbrig-hellen Mondlicht-Akzenten, evtl. kleine Mondsichel als Etikett oder Verschluss. Stimmung: Fülle, Ernte.
- potion_liquid_moonlight.png (Flüssiges Mondlicht): schlanke, edle Flasche, Inhalt hell schimmernd (Knochen/Flieder/helles Blau), Gold am Verschluss. Wertvollster Trank, darf am meisten leuchten.
- potion_endless_night.png (Ewige Nacht): dunkle, kantige Flasche, Inhalt fast schwarz (Tiefschwarz/Indigo) mit einzelnen Sternpunkten, Bordeaux-Akzent. Stimmung: schwer, mächtig, verboten.

## 2. Bett (assets/environment/props/bed.png)
- Top-down, 32 Pixel breit, Größe nach Bedarf (vermutlich 32x64, also 1x2 Tiles). Schlag die passende Größe vor.
- Passt zu einer modernen, divenhaften Hexe: kein Bauernbett. Eher dunkles Holz oder schwarzes Metall, Bettwäsche in Bordeaux oder Aubergine mit Gold- oder Magenta-Akzent, evtl. ein paar Kissen.
- Der Unterschlupf steht noch nicht fest (Hütte oder alte Kirche), also neutral genug für beides.

## 3. Brau-Fenster (UI)
Ein Fenster, das sich am Kessel öffnet, ähnlich dem Crafting in Minecraft: 3 Zutaten-Felder, ein Ergebnis-Feld, ein Brauen-Knopf, dazwischen ein Pfeil oder ein magisches Symbol. Das Inventar wird darunter angezeigt (dafür können vermutlich die bestehenden Slot-Grafiken wiederverwendet werden).
- Stil passend zur Hotbar (Rahmen, Gold, dunkler Hintergrund).
- Die einzelnen Teile als eigene Grafiken (Fensterrahmen als 9-Slice, Zutaten-Feld, Ergebnis-Feld, Knopf normal/gedrückt), damit Godot sie zusammensetzen kann.
- In CLAUDE.md steht die Idee, UI-Grafiken künftig in 1x zu speichern (die Hotbar ist noch 2x vorskaliert). Sag mir, was du für das Brau-Fenster empfiehlst, bevor du loslegst.
- Zeig mir am Ende eine Mockup-Vorschau des zusammengesetzten Fensters (mit ein paar Trank- und Pflanzen-Icons in den Feldern).

## 4. Nachtschatten-Aura
Nachtschatten hemmt das Wachstum der 8 Pflanzen um sich herum (auch diagonal), außer es sind selbst Nachtschatten. Die Spielerin soll das am Aussehen erkennen und selbst darauf kommen.
- Ein Effekt-Sprite in assets/effects/, das über bzw. unter der Pflanze liegt: dunkel-violetter, unheimlicher Schimmer (Indigo, Aubergine, etwas Magenta), der über den Rand des eigenen Tiles leicht in die Nachbarfelder hineinreicht.
- Animiert, 3-4 Frames, langsam wabernd (z. B. kleine dunkle Partikel, die nach außen kriechen).
- Muss nachts auf dunklem Boden noch sichtbar sein, darf aber die Pflanze selbst nicht verdecken.
- Optional zweite Variante: ein dezenter Effekt auf den gehemmten Nachbarpflanzen (z. B. leicht verwelkte Blätter oder ein Schatten darüber). Zeig mir beide Ideen.

## Zum Schluss
- Liste aller neuen Dateien mit Größe und Frame-Anzahl.
- Liste der neu verwendeten Farben (siehe oben).
- docs/ASSETS.md um die neuen Grafiken ergänzen.
- Committen, wenn ich zufrieden bin.