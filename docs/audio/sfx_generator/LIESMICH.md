# Soundeffekte – Generator

`sfx.py` erzeugt alle Effekte aus `docs/prompts/sound_auftrag_effekte.md` per Synthese (Stand 10.10.2026: alle Listen des Auftrags plus `world/shelter_ambience_loop`).

```text
python docs/audio/sfx_generator/sfx.py              # alle Effekte neu
python docs/audio/sfx_generator/sfx.py harvest      # nur IDs, die "harvest" enthalten
python docs/audio/sfx_generator/sfx.py --preview    # alle + docs/audio/sfx_vorschau.ogg (braucht ffmpeg)
```

- Jeder Effekt hat einen festen Zufalls-Seed. Ein neuer Aufruf erzeugt also genau dieselben Dateien, solange der Code gleich bleibt.
- Lautheit: Alle Effekte stehen auf derselben Kurzzeit-Lautheit (lautestes 100-ms-Fenster, `TARGET_DB`), Spitze höchstens −3 dBFS. Der Wert `level` in der Liste unten im Script verschiebt einzelne bewusst (Hover und Aura-Loops leiser, Trank fertig und Mondlicht lauter).
- Klang ändern: die Funktion des Effekts anpassen (z. B. `harvest()`), Script mit der ID aufrufen, in Godot neu laden.
- Loops sind nahtlos: Rauschen, Filter und Hall werden dafür zirkulär berechnet. In Godot über `Sfx.get_loop("brewing/cauldron_loop")` holen, das stellt die WAV auf Wiederholen.
- Format: WAV, 44,1 kHz, 16 Bit, mono; die Atmos (`*_ambience_loop`) stereo.

## Im Spiel

- Effekte: `Sfx.play("ui/click")` (ohne Ort) oder `Sfx.play_at("garden/bed_wake", position)` (leiser mit Abstand). Varianten `_1`, `_2` … wählt `Sfx` selbst.
- Loops an Objekten: `add_child(Sfx.make_loop_player("brewing/cauldron_loop", -4.0, 260.0))` (Kessel, Hexenfeuer, Nachtschatten).
- Atmo je Ort: Export `ambience` am Level (Garten, Wald, Unterschlupf), `Sfx.set_ambience()` blendet beim Ortswechsel über.
- Hexe: `PlayerSounds` (an der Hexe) spielt Schritte je Boden (`Level.step_surface_at`), Schweben und die Aktions-Sounds passend zu den Animations-Frames.
- Knöpfe klicken und rascheln automatisch (`Sfx` hängt sich an jeden neuen `BaseButton`).
- „Geht nicht“-Meldungen über `Messages.deny()` statt `post()`: mit tiefem, weichem Ton.

## Dateien

| ID (`assets/audio/sfx/…`) | Länge | Loop | Kanäle |
|---|---|---|---|
| `player/float_loop` | 3.00 s | ja | mono |
| `player/float_start` | 0.90 s | – | mono |
| `player/snap` | 1.25 s | – | mono |
| `player/step_grass_1` | 0.26 s | – | mono |
| `player/step_grass_2` | 0.26 s | – | mono |
| `player/step_grass_3` | 0.26 s | – | mono |
| `player/step_grass_4` | 0.26 s | – | mono |
| `player/step_path_1` | 0.26 s | – | mono |
| `player/step_path_2` | 0.26 s | – | mono |
| `player/step_path_3` | 0.26 s | – | mono |
| `player/step_path_4` | 0.26 s | – | mono |
| `player/step_soil_1` | 0.26 s | – | mono |
| `player/step_soil_2` | 0.26 s | – | mono |
| `player/step_soil_3` | 0.26 s | – | mono |
| `player/step_soil_4` | 0.26 s | – | mono |
| `player/step_stone_1` | 0.39 s | – | mono |
| `player/step_stone_2` | 0.39 s | – | mono |
| `player/step_stone_3` | 0.39 s | – | mono |
| `player/step_stone_4` | 0.39 s | – | mono |
| `garden/bed_sleep` | 0.80 s | – | mono |
| `garden/bed_wake` | 1.30 s | – | mono |
| `garden/grow_magic` | 1.40 s | – | mono |
| `garden/harvest_1` | 0.50 s | – | mono |
| `garden/harvest_2` | 0.50 s | – | mono |
| `garden/harvest_3` | 0.50 s | – | mono |
| `garden/nightshade_loop` | 4.00 s | ja | mono |
| `garden/plant_seed` | 0.40 s | – | mono |
| `garden/pour` | 1.50 s | – | mono |
| `garden/pour_sludge` | 1.40 s | – | mono |
| `brewing/brew_start` | 1.90 s | – | mono |
| `brewing/cauldron_loop` | 5.00 s | ja | mono |
| `brewing/drink` | 1.00 s | – | mono |
| `brewing/endless_night` | 2.80 s | – | mono |
| `brewing/ingredient_drop` | 0.75 s | – | mono |
| `brewing/moonlight` | 2.30 s | – | mono |
| `brewing/potion_take` | 0.90 s | – | mono |
| `brewing/wisp_appear` | 1.60 s | – | mono |
| `ui/click` | 0.12 s | – | mono |
| `ui/close` | 0.45 s | – | mono |
| `ui/denied` | 0.30 s | – | mono |
| `ui/hover` | 0.08 s | – | mono |
| `ui/item_drop` | 0.15 s | – | mono |
| `ui/item_get` | 0.55 s | – | mono |
| `ui/item_pick` | 0.12 s | – | mono |
| `ui/open` | 0.45 s | – | mono |
| `ui/page_turn` | 0.40 s | – | mono |
| `world/book_pickup` | 2.20 s | – | mono |
| `world/campfire_loop` | 6.00 s | ja | mono |
| `world/fast_forward` | 1.25 s | – | mono |
| `world/forest_ambience_loop` | 32.00 s | ja | stereo |
| `world/night_ambience_loop` | 32.00 s | ja | stereo |
| `world/page_pickup` | 1.00 s | – | mono |
| `world/shelter_ambience_loop` | 24.00 s | ja | stereo |
| `world/sleep` | 2.49 s | – | mono |
| `world/travel` | 1.30 s | – | mono |
| `world/well_splash` | 1.40 s | – | mono |
