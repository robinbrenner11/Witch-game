# Pflanzen-Vorlagen umrechnen

Ablauf: Robin lässt ChatGPT eine Vorlage malen (4 Wachstumsstufen nebeneinander),
`convert_ref.py` rechnet sie auf Spiel-Frames um. Vorlagen liegen in `art_src/inspo/`,
Ergebnisse in `assets/plants/<pflanze>_stages.png`, Aseprite-Dateien in `art_src/plants/`.

## Was die Vorlage haben sollte (für den Prompt an ChatGPT)

- **Transparenter Hintergrund**, kein Leuchten/Schein um die Pflanze (das Leuchten macht das Spiel)
- **Kein Erdhügel**, oder nur ein flacher, der sauber unter der Pflanze liegt.
  Die Pflanze steht im Spiel schon im Beet. Blätter, die über der Erde liegen, lassen sich
  nicht von ihr trennen (die erste Alraunen-Vorlage scheiterte daran)
- 4 Stufen nebeneinander mit Abstand, nichts dazwischen (keine Funken zwischen den Stufen)
- Quadratische Pixel, harte Kanten, dunkle Kontur
- Gleiche Größe pro Vorlagen-Pixel in allen Stufen
- Grobe Proportion: Endstufe etwa so breit wie hoch (Busch) oder höchstens doppelt so hoch
  wie breit (Rose). Je kleiner das Verhältnis zur Zielgröße, desto mehr Details gehen verloren

## Aufruf

```
python docs/art/ref_converter/convert_ref.py art_src/inspo/<vorlage>.png assets/plants/<pflanze>_stages.png [Optionen]
```

| Option | Wofür |
|---|---|
| `--breite 40` | breite Büsche (Farn, Nachtschatten, Laternenbeere) |
| `--hoehe 64` | hohe, schmale Pflanzen (Blutrose) |
| `--soil 10,11,15,15` | Erdhügel abschneiden: Vorlagen-Pixelzeilen von unten, je Stufe |
| `--kontur` | außen 1 px Aubergine-Kontur, wenn sie beim Verkleinern verloren geht |
| `--quadrat` | Pixel in y gleich groß wie in x (wenn die Messung in y danebenliegt, Pflanze wirkt platt) |
| `--vorschau ordner` | speichert `native.png` (Vorlage im eigenen Raster) zum Prüfen |

Der Stielfuß liegt immer 11 px über der Frame-Unterkante, mittig. `plant.gd` erwartet das
und kommt mit jeder Frame-Größe klar. Danach in `data/plants/<pflanze>.tres` ggf.
`glow_offset` auf die neue Blüte setzen.

## Bisherige Einstellungen

| Pflanze | Frames | Optionen |
|---|---|---|
| Mondkelch | 32×48 | eigener Weg über 48×64 (siehe `art_src/plants/moon_chalice_48x64.png`) |
| Blutrose | 32×64 | `--hoehe 64` |
| Geisterfarn | 40×48 | `--breite 40 --kontur` |
| Nachtschatten | 40×48 | `--breite 40 --kontur --quadrat` |
| Laternenbeere | 40×48 | `--breite 40 --quadrat --soil 10,11,15,15` |
| Alraune | 40×48 | `--breite 40`, danach Augen und Gesichtsmitte von Hand aufgehellt |
