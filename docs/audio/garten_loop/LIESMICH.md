# Mondgarten – Garten-Loop (Entwurf 1)

**D-Moll (dorisch) · 72 BPM · 4/4 · 16 Takte · ca. 53 s, nahtlos loopbar**

## Akkordfolge

| Takte | Akkorde |
|---|---|
| 1–4   | Dm9 · B♭maj9 · Gm9 · A7sus4 |
| 5–8   | Dm9 · B♭maj7♯11 · Gm9 · A7♭13 |
| 9–12  | Dm9 · B♭maj9 · Gm9 · A7sus4 |
| 13–16 | Gm9 · **E♭maj7** · B♭maj7♯11 · A7♭13 → zurück zu Takt 1 |

Das E♭maj7 in Takt 14 ist der „magische" Moment (fremder Akkord, kurz schwebend). Das A7♭13 am Ende zieht melancholisch zurück zum Anfang.

## Ebenen (je eine MIDI-Datei)

| Datei | Instrument-Idee | Rolle im Spiel |
|---|---|---|
| `1_rhodes` | E-Piano / Rhodes | Herz des Tracks, immer an |
| `2_pad` | Warmes Pad | Grundteppich, immer an |
| `3_bass` | Weicher Bass / Sub | immer an |
| `4_spieluhr` | Spieluhr, Celesta oder Harfe | Melodie; z. B. leiser, wenn Dialog läuft |
| `5_beat` | Weiche Kick, Rimshot, Shaker (Swing) | startet erst ab Takt 5; z. B. aus im Unterschlupf |
| `6_summen` | Wortlose Frauenstimme (Oohs) | „Vollmond"-Ebene, nur in besonderen Nächten |

`mondgarten_komplett.mid` enthält alle Ebenen zusammen.

## Vorschau

Die beiden OGGs sind nur mit einem einfachen General-MIDI-Soundfont gerendert, also **Klang = Platzhalter**. Es geht um Harmonien, Melodie und Groove. Der echte Sound entsteht in der DAW.

## So machst du daraus den echten Track

1. **DAW installieren** (kostenlos): Cakewalk by BandLab oder Waveform Free.
2. **Instrumente** (kostenlos): Spitfire LABS (Soft Piano, Frozen Strings, Music Box, Choir) und Vital (Pads, Bass).
3. Jede MIDI-Datei auf eine eigene Spur ziehen, Tempo 72 BPM.
4. Sound-Bible anwenden: auf alles Hall, auf die Summe leichte Tape-Sättigung + etwas Vinyl-Knistern, Höhen sanft absenken.
5. **Jede Ebene einzeln exportieren** (gleiche Länge, 16 Takte) → OGG. Hallfahne vom Ende auf den Anfang legen, damit der Loop nicht abreißt.
6. In Godot (ab 4.3): `AudioStreamSynchronized` mit allen Stems; Lautstärke einzelner Ebenen per Code steuern (Vollmond → Summen hoch, Unterschlupf → Beat runter).
7. Beim OGG-Import in Godot **Loop** aktivieren.

## Ändern / neu erzeugen

`compose.py` erzeugt alles neu (`pip install mido tinysoundfont numpy`). Akkorde, Melodie, Tempo stehen oben im Script.
