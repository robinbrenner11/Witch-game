# Grafik-Auftrag: Aktions-Animationen der Hexe

Wir erstellen Aktions-Animationen für die Hauptfigur von **Bitterbloom** (2D-Pixel-Art-Life-Sim, Dark Cozy Witchcraft). Lies zuerst `CLAUDE.md` (Abschnitt Visuelle Identität, Charakterdesign, Hauptfigur in der Ideensammlung), `docs/ASSETS.md` (Abschnitt Hexe) und `docs/art/hexen_palette.gpl`. Schau dir die bestehenden Sprites genau an, die neuen Frames müssen nahtlos dazu passen:

- `assets/characters/witch_idle.png` (3 Frames: unten, oben, Seite)
- `assets/characters/witch_walk_down.png`, `witch_walk_up.png`, `witch_walk_side.png` (je 8 Frames)
- `docs/art/referenz/witch_concept.webp` (Designvorlage) und `docs/art/referenz/witch_base_32x64.png`

## Feste Regeln (wie bei allen Hexen-Sprites)

- Jeder Frame **32×64 px**, Frames **waagerecht nebeneinander** in einer PNG, transparenter Hintergrund.
- Füße in **jedem** Frame auf der untersten Pixelzeile (y = 63), mittig (x = 16). Die Figur darf sich bücken oder strecken, aber die Füße bleiben stehen.
- **Drei Richtungen:** unten (Vorderansicht), oben (Rückansicht), Seite (Blick nach **rechts**; links spiegelt das Spiel).
- Harte Pixel, kein Anti-Aliasing, keine weichen Verläufe, Licht von oben links, **Aubergine-Kontur** statt Schwarz.
- Palette aus `hexen_palette.gpl` (gelockert: Zwischentöne erlaubt, neue Töne bitte auflisten). Richtwert 8–12 Farben.
- Charakter: dunkelhäutig, ohne Hut, goldene Akzente auf der Haut, **komplett schwarze Finger**, Gold und Magenta als Akzente, schlanke Proportionen. Magie ist immer **Magenta**.
- Gleiche Silhouette, Kleidung und Proportionen wie in den Lauf-Animationen; nichts neu erfinden.

## Die Animationen

| Datei (pro Richtung `_down`, `_up`, `_side`) | Frames | Ablauf | Abspielen |
|---|---|---|---|
| `witch_pour_<richtung>.png` | 5 | Fläschchen heben (1), kippen (2–4, leicht nach vorn geneigt), zurück (5). Die Flasche selbst darf dunkel/neutral sein, **ohne** Flüssigkeit. | 8 FPS, einmal |
| `witch_harvest_<richtung>.png` | 4 | Bücken und nach unten greifen (1–2), herausziehen (3), kurz anheben, Hand vor dem Körper (4). Leere Hand, das Spiel legt das Item nicht in die Hand. | 8 FPS, einmal |
| `witch_drink_<richtung>.png` | 5 | Fläschchen zum Mund (1–2), Kopf leicht zurück (3), absetzen (4–5). Bei `_up` sieht man nur Rücken und angehobenen Arm. | 7 FPS, einmal |
| `witch_snap_<richtung>.png` | 4 | Hand mit den schwarzen Fingern heben (1), Schnippen (2, 2–3 Magenta-Funken an den Fingerspitzen), Funken verglühen (3), Hand senken (4). Für „Erde wecken“ (Beet anlegen) und später Zauber. | 10 FPS, einmal |

Dazu **ein Effekt-Sprite** für das Ausgießen:

| Datei | Größe | Inhalt |
|---|---|---|
| `assets/effects/pour_stream.png` | 3 Frames à 16×16 nebeneinander (48×16) | Fallender Flüssigkeitsstrahl mit kleinem Spritzer unten. **In hellen, fast weißen Grautönen** (Knochen und heller), damit das Spiel ihn per `modulate` in der Trankfarbe einfärben kann. Kontur nur dort, wo nötig, damit er beim Einfärben nicht schmutzig wirkt. |

## Arbeitsweise

- Wie bisher gern mit Python-Generator (Pillow) oder direkt im Pixeleditor. Wenn Generator: unter `docs/art/character_generator/` ablegen, Aufruf oben im Script.
- Zuerst **eine** Animation in **einer** Richtung zeigen (z. B. `witch_pour_down`) und auf Feedback warten, bevor die anderen entstehen.
- Für jede Animation eine Vorschau als **animiertes GIF in 4×** in `docs/art/vorschau/` (alle drei Richtungen nebeneinander), außerdem ein Standbild neben dem passenden Idle-Frame zum Größenvergleich.
- Prüfen: Füße auf y = 63, x = 16 in jedem Frame; keine Pixel außerhalb 32×64; Konturfarbe Aubergine.

## Zum Schluss

- Liste aller neuen Dateien mit Größe und Frame-Anzahl.
- Liste neu verwendeter Farben.
- Ein kurzer Abschnitt für `docs/ASSETS.md` (wie beim Abschnitt Hexe: Dateien, Frames, FPS, Abspielweise).
- Alles als Paket (ZIP) mit gleicher Ordnerstruktur wie das Projekt, wie beim Paket vom 07.10.2026.

Das Einbauen in Godot (SpriteFrames, Auslösen beim Ausgießen, Ernten, Trinken, Einfärben des Strahls) übernimmt danach Claude Code.
