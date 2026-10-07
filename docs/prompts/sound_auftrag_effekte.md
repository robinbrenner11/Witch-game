# Sound-Auftrag: Soundeffekte für Bitterbloom

Wir erstellen die Soundeffekte für **Bitterbloom**, eine 2D-Pixel-Art-Life-Sim über eine junge Hexe (Dark Cozy Witchcraft: mysteriös, leicht düster, aber gemütlich; gespielt wird nachts). Lies zuerst `CLAUDE.md` (Vision, Abschnitt Sound in der Ideensammlung) und `docs/audio/garten_loop/LIESMICH.md` (der Musik-Loop, zu dem alles passen muss).

## Klangsprache (verbindlich)

- **Stimmung wie die Musik:** dreamy, warm, leicht melancholisch, weich, nachts, sinnlich, mysteriös, etwas urban/modern. Referenz: SZA – *SOS Deluxe: LANA*.
- **Weich statt hart:** keine schrillen Höhen, keine harten Transienten, nichts Comichaftes (kein „Boing“, kein Retro-8-Bit-Piepsen). Höhen sanft absenken, leichter, kurzer Hall.
- **Magie klingt gläsern und warm:** Glöckchen, Celesta, Glas, gestrichenes Glas, sanfte Synth-Glitzer. **Tonale Effekte in D-Moll / D-dorisch** (Töne D, E, F, G, A, H, C), damit sie zum Loop passen.
- **Natur klingt nah und intim:** Erde, Blätter, Glas, Wasser, Stoff. Wie mit einem Mikrofon nah dran aufgenommen.
- Alle Effekte gleich laut wahrnehmbar. Nichts sticht heraus, außer es ist bewusst ein besonderer Moment (z. B. Trank fertig, Vollmond).

## Technik

- Format **WAV, 44,1 kHz, 16 Bit, mono** (Ausnahme: Atmosphären-Loops dürfen stereo sein).
- Spitzenpegel etwa **−3 dBFS**, kurze Effekte vorne ohne Stille (Start sofort beim ersten Sample).
- Loops (Endung `_loop`) **nahtlos**: Ende geht ohne Klick in den Anfang über.
- **Varianten** (`_1`, `_2`, `_3`): leicht unterschiedlich (Tonhöhe, Timing), damit Wiederholungen nicht nerven.
- Nur Material, das wir im Spiel verwenden dürfen: selbst erzeugt (z. B. Python/numpy-Synthese wie beim Musik-Loop) oder **CC0** (gemeinfrei). Jede fremde Quelle in `docs/audio/sfx_quellen.md` mit Link und Lizenz notieren.

## Liste der Effekte

Ablage: `assets/audio/sfx/<ordner>/<datei>.wav`

### Hexe – `player/`

| Datei | Länge | Beschreibung |
|---|---|---|
| `step_soil_1..4` | < 0,3 s | Schritt auf weicher Gartenerde, gedämpft |
| `step_grass_1..4` | < 0,3 s | Schritt im Gras, leises Rascheln |
| `step_path_1..4` | < 0,3 s | Schritt auf festgetretenem Weg, etwas Kies |
| `step_stone_1..4` | < 0,3 s | Schritt auf Steinplatten (Unterschlupf), leise, mit kurzem Raumklang |
| `float_start` | ~0,6 s | Abheben beim Schweben: weicher Luftzug mit kurzem Glitzern |
| `float_loop` | 2–4 s, Loop | leises magisches Summen/Schimmern, solange sie schwebt; sehr unaufdringlich |
| `snap` | ~0,8 s | Fingerschnippen mit den schwarzen Fingern, danach ein kurzer Magenta-Funke als gläserner Ton (D) |

### Garten – `garden/`

| Datei | Länge | Beschreibung |
|---|---|---|
| `bed_wake` | ~1 s | Erde wacht auf: Boden lockert sich, Krümel, tiefes warmes Brummen, Glitzer am Ende |
| `bed_sleep` | ~0,8 s | Beet legt sich schlafen: Erde setzt sich, leises Absinken |
| `plant_seed` | ~0,4 s | Samen in die Erde drücken, weich |
| `harvest_1..3` | ~0,5 s | Pflanze herausziehen: Wurzeln lösen sich, Blätter rascheln |
| `grow_magic` | ~1 s | Pflanze wächst sofort durch Magie: aufsteigendes Glitzern, organisches Knistern |
| `pour` | ~1,2 s | Trank aus einem Fläschchen auf Erde gießen, Glas + Flüssigkeit |
| `pour_sludge` | ~1,2 s | Hexenschlamm gießen: zäh, glucksend, ein bisschen eklig, aber nicht laut |
| `nightshade_loop` | 3–5 s, Loop | Nachtschatten-Aura: kühles, leises, unheimliches Wabern/Flüstern, sehr leise |

### Kessel und Tränke – `brewing/`

| Datei | Länge | Beschreibung |
|---|---|---|
| `cauldron_loop` | 4–6 s, Loop | Kessel blubbert ruhig vor sich hin (im Spiel leiser, je weiter man weg ist) |
| `ingredient_drop` | ~0,5 s | Zutat fällt in den Kessel: „Plopp“ in dicker Flüssigkeit |
| `brew_start` | ~1,5 s | Brauen beginnt: Sud zischt auf, magischer Schwall (Magenta), endet ruhig |
| `potion_take` | ~0,6 s | fertigen Trank abholen: Glas-Klirren, kleiner Glockenton (besonderer Moment) |
| `drink` | ~1 s | Trinken: Glas, zwei Schlucke |
| `wisp_appear` | ~1,2 s | Irrlicht erscheint: verspieltes, leicht unheimliches Glimmen (hoher gläserner Ton) |
| `moonlight` | ~1,5 s | Flüssiges Mondlicht: kühles, weites Aufleuchten, Chor-Hauch |
| `endless_night` | ~2 s | Ewige Nacht: tiefes, langsames Anschwellen, als würde die Zeit gedehnt |

### Welt – `world/`

| Datei | Länge | Beschreibung |
|---|---|---|
| `night_ambience_loop` | 20–40 s, Loop, stereo | Nachtatmosphäre im Garten: leiser Wind, Insekten, ab und zu ein fernes Käuzchen; dunkel, aber geborgen |
| `forest_ambience_loop` | 20–40 s, Loop, stereo | wie oben, dichter: Blätter, Äste, mehr Tiere, etwas unheimlicher |
| `campfire_loop` | 4–8 s, Loop | Hexenfeuer: knisternd, warm |
| `fast_forward` | ~1 s | Zeitraffer am Feuer beginnt: Uhr-artiges Rauschen, warm |
| `sleep` | ~2 s | Einschlafen im Bett: Stoff, Ausatmen, sanfter tiefer Ton |
| `well_splash` | ~0,8 s | etwas fällt in den Brunnen: tiefes Platschen, Echo von unten |
| `page_pickup` | ~0,8 s | lose Buchseite aufheben: Papierrascheln + leiser Glockenton |
| `book_pickup` | ~1 s | das Buch der alten Hexe nehmen: schweres Buch, Staub, ein geheimnisvoller Akkord |
| `travel` | ~1 s | Ortswechsel beim Abblenden: weicher Luftzug |

### Benutzeroberfläche – `ui/`

| Datei | Länge | Beschreibung |
|---|---|---|
| `click` | < 0,15 s | Knopf drücken: weich, holzig oder gläsern |
| `hover` | < 0,1 s | Maus über Knopf: kaum hörbar |
| `open` | ~0,3 s | Fenster öffnen (Inventar, Kessel, Buch) |
| `close` | ~0,3 s | Fenster schließen |
| `page_turn` | ~0,4 s | Buchseite umblättern |
| `item_pick` | ~0,15 s | Item im Inventar aufnehmen (Drag beginnt) |
| `item_drop` | ~0,15 s | Item ablegen |
| `item_get` | ~0,4 s | etwas ins Inventar bekommen (Ernte, Trank): kleiner, freundlicher Glockenton |
| `denied` | ~0,3 s | geht nicht (Inventar voll, Erde schläft zu tief): weich, tief, nicht nervig |

## Arbeitsweise

- Zuerst **eine kleine Probe** zeigen: `snap`, `step_soil_1` und `cauldron_loop`. Auf Feedback warten, bevor der Rest entsteht.
- Wenn generiert: das Script unter `docs/audio/sfx_generator/` ablegen, Aufruf oben im Script, damit Effekte später angepasst werden können.
- Am Ende eine Vorschau-Datei `docs/audio/sfx_vorschau.ogg`, in der alle Effekte nacheinander mit kurzer Pause zu hören sind.

## Zum Schluss

- Liste aller Dateien mit Länge und ob Loop.
- `docs/audio/sfx_quellen.md` mit allen fremden Quellen und Lizenzen (oder „alles selbst erzeugt“).
- Alles als Paket (ZIP) mit gleicher Ordnerstruktur wie das Projekt, wie bei den vorherigen Paketen.

Das Einbauen in Godot (Abspielen bei den Aktionen, Lautstärke nach Entfernung, Atmosphäre je Ort, eigener Lautstärkeregler für Effekte und Musik) übernimmt danach Claude Code.
