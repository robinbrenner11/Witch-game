# Soundeffekte – Generator

`sfx.py` erzeugt alle Effekte aus `docs/prompts/sound_auftrag_effekte.md` per Synthese (Stand 10.10.2026: Hexe, Garten, Kessel, UI; die Welt-Atmos folgen).

```text
python docs/audio/sfx_generator/sfx.py              # alle Effekte neu
python docs/audio/sfx_generator/sfx.py harvest      # nur IDs, die "harvest" enthalten
python docs/audio/sfx_generator/sfx.py --preview    # alle + docs/audio/sfx_vorschau.ogg (braucht ffmpeg)
```

- Jeder Effekt hat einen festen Zufalls-Seed. Ein neuer Aufruf erzeugt also genau dieselben Dateien, solange der Code gleich bleibt.
- Lautheit: Alle Effekte stehen auf derselben Kurzzeit-Lautheit (lautestes 100-ms-Fenster, `TARGET_DB`), Spitze höchstens −3 dBFS. Der Wert `level` in der Liste unten im Script verschiebt einzelne bewusst (Hover und Aura-Loops leiser, Trank fertig und Mondlicht lauter).
- Klang ändern: die Funktion des Effekts anpassen (z. B. `harvest()`), Script mit der ID aufrufen, in Godot neu laden.
- Loops sind nahtlos: Rauschen, Filter und Hall werden dafür zirkulär berechnet. In Godot über `Sfx.get_loop("brewing/cauldron_loop")` holen, das stellt die WAV auf Wiederholen.
- Format: WAV, 44,1 kHz, 16 Bit, mono.

## Dateien

| ID (`assets/audio/sfx/…`) | Länge | Loop |
|---|---|---|
| `player/float_loop` | 3.00 s | ja |
| `player/float_start` | 0.90 s | – |
| `player/snap` | 1.25 s | – |
| `player/step_grass_1` | 0.26 s | – |
| `player/step_grass_2` | 0.26 s | – |
| `player/step_grass_3` | 0.26 s | – |
| `player/step_grass_4` | 0.26 s | – |
| `player/step_path_1` | 0.26 s | – |
| `player/step_path_2` | 0.26 s | – |
| `player/step_path_3` | 0.26 s | – |
| `player/step_path_4` | 0.26 s | – |
| `player/step_soil_1` | 0.26 s | – |
| `player/step_soil_2` | 0.26 s | – |
| `player/step_soil_3` | 0.26 s | – |
| `player/step_soil_4` | 0.26 s | – |
| `player/step_stone_1` | 0.39 s | – |
| `player/step_stone_2` | 0.39 s | – |
| `player/step_stone_3` | 0.39 s | – |
| `player/step_stone_4` | 0.39 s | – |
| `garden/bed_sleep` | 0.80 s | – |
| `garden/bed_wake` | 1.30 s | – |
| `garden/grow_magic` | 1.40 s | – |
| `garden/harvest_1` | 0.50 s | – |
| `garden/harvest_2` | 0.50 s | – |
| `garden/harvest_3` | 0.50 s | – |
| `garden/nightshade_loop` | 4.00 s | ja |
| `garden/plant_seed` | 0.40 s | – |
| `garden/pour` | 1.50 s | – |
| `garden/pour_sludge` | 1.40 s | – |
| `brewing/brew_start` | 1.90 s | – |
| `brewing/cauldron_loop` | 5.00 s | ja |
| `brewing/drink` | 1.00 s | – |
| `brewing/endless_night` | 2.80 s | – |
| `brewing/ingredient_drop` | 0.75 s | – |
| `brewing/moonlight` | 2.30 s | – |
| `brewing/potion_take` | 0.90 s | – |
| `brewing/wisp_appear` | 1.60 s | – |
| `ui/click` | 0.12 s | – |
| `ui/close` | 0.45 s | – |
| `ui/denied` | 0.30 s | – |
| `ui/hover` | 0.08 s | – |
| `ui/item_drop` | 0.15 s | – |
| `ui/item_get` | 0.55 s | – |
| `ui/item_pick` | 0.12 s | – |
| `ui/open` | 0.45 s | – |
| `ui/page_turn` | 0.40 s | – |
