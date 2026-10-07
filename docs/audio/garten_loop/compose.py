"""Garten-Loop „Mondgarten" – erzeugt MIDI-Layer + loopfähige OGG-Vorschau.
D-Moll / dorisch, 72 BPM, 16 Takte, Neo-Soul-Harmonik.
"""
import random, subprocess, os
import numpy as np
import mido
import tinysoundfont

OUT = os.path.dirname(os.path.abspath(__file__))
BPM, TPB, SR = 72, 480, 44100
BEAT = 60 / BPM
BARS = 16
random.seed(7)

# ---------- Harmonik (MIDI-Noten) ----------
CHORDS = {
    "Dm9":      dict(rh=[50, 57, 60, 64, 65], bass=38, pad=[62, 65, 69]),
    "Bbmaj9":   dict(rh=[46, 53, 57, 60, 62], bass=34, pad=[62, 65, 69]),
    "Bbmaj7#11":dict(rh=[46, 53, 57, 62, 64], bass=34, pad=[62, 64, 69]),
    "Gm9":      dict(rh=[43, 53, 57, 58, 62], bass=31, pad=[62, 65, 70]),
    "A7sus4":   dict(rh=[45, 52, 55, 57, 62], bass=33, pad=[62, 64, 67]),
    "A7b13":    dict(rh=[45, 55, 61, 65],     bass=33, pad=[61, 65, 67]),
    "Ebmaj7":   dict(rh=[39, 50, 55, 58, 62], bass=39, pad=[62, 67, 70]),
}
PROG = ["Dm9", "Bbmaj9", "Gm9", "A7sus4",
        "Dm9", "Bbmaj7#11", "Gm9", "A7b13",
        "Dm9", "Bbmaj9", "Gm9", "A7sus4",
        "Gm9", "Ebmaj7", "Bbmaj7#11", "A7b13"]

# ---------- Spieluhr-Melodie (Beat-Start, Note, Dauer) pro Takt ----------
MEL = [
    [(0.5, 76, 1), (1.5, 77, .5), (2, 81, 1.5), (3.5, 79, .5)],
    [(0, 77, 1), (1, 74, .5), (1.5, 69, 2.5)],
    [(0.5, 70, .5), (1, 74, .5), (1.5, 77, 1), (2.5, 81, 1.5)],
    [(0, 79, 1), (1, 76, 1), (2, 74, 2)],
    [(0, 76, 1.5), (2, 72, .5), (2.5, 74, 1.5)],
    [(0, 76, 2), (2, 77, .5), (2.5, 81, 1.5)],
    [(0, 82, 1), (1, 81, .5), (1.5, 77, .5), (2, 74, 2)],
    [(0, 73, 1.5), (1.5, 76, .5), (2, 77, 2)],
    [(0.5, 76, 1), (1.5, 77, .5), (2, 81, 1.5), (3.5, 84, .5)],
    [(0, 81, 1), (1, 77, .5), (1.5, 74, 2.5)],
    [(0.5, 70, .5), (1, 74, .5), (1.5, 77, 1), (2.5, 82, 1.5)],
    [(0, 81, 1), (1, 79, 1), (2, 76, 2)],
    [(0, 81, 1), (1, 82, .5), (1.5, 86, 2.5)],
    [(0, 82, 1), (1, 79, 1), (2, 74, 2)],
    [(0, 77, 1), (1, 81, 1), (2, 76, 2)],
    [(0, 74, 2), (2, 73, 2)],
]
HUM = [69, 69, 70, 69, 72, 69, 70, 73, 69, 69, 70, 69, 70, 70, 69, 73]

# layer: (Dateiname, Kanal, GM-Programm, Lautstärke)
LAYERS = {
    "1_rhodes":   (0, 4,  92),   # Electric Piano 1
    "2_pad":      (1, 89, 70),   # Warm Pad
    "3_bass":     (2, 33, 96),   # Fingered Bass
    "4_spieluhr": (3, 10, 78),   # Music Box
    "5_beat":     (9, 0,  80),   # Drums (Kanal 10)
    "6_summen":   (4, 53, 64),   # Voice Oohs  -> „Vollmond"-Ebene
}

def hum(t, amt=0.03):            # leichte Humanisierung
    return t + random.uniform(-amt, amt)

def notes_for(layer):
    n = []  # (start_beat, note, dur_beats, velocity)
    for bar, name in enumerate(PROG):
        b0 = bar * 4
        c = CHORDS[name]
        if layer == "1_rhodes":
            for i, p in enumerate(c["rh"]):          # leicht gebrochen gespielt
                n.append((hum(b0 + i * 0.02), p, 2.4, random.randint(48, 60)))
            for p in c["rh"][1:]:                     # Nachanschlag auf 3+
                n.append((hum(b0 + 2.5), p, 1.4, random.randint(34, 44)))
        elif layer == "2_pad":
            for p in c["pad"]:
                n.append((b0, p, 4.0, 50))
        elif layer == "3_bass":
            n.append((hum(b0, .02), c["bass"], 2.6, 72))
            nxt = CHORDS[PROG[(bar + 1) % BARS]]["bass"]
            n.append((hum(b0 + 3.5, .02), nxt + (2 if nxt < c["bass"] else -1), 0.45, 54))
        elif layer == "4_spieluhr":
            for s, p, d in MEL[bar]:
                n.append((hum(b0 + s, .02), p, d, random.randint(50, 66)))
        elif layer == "6_summen":
            n.append((b0 + 0.1, HUM[bar], 3.8, 46))
        elif layer == "5_beat":
            if bar < 4:          # die ersten 4 Takte ohne Beat – Einstieg
                continue
            n.append((b0, 36, .5, 58)); n.append((b0 + 2.5, 36, .5, 46))
            n.append((hum(b0 + 1, .015), 37, .3, 34)); n.append((hum(b0 + 3, .015), 37, .3, 38))
            for e in range(8):   # Shaker mit Swing
                s = b0 + e * 0.5 + (0.08 if e % 2 else 0)
                n.append((s, 70, .2, 22 if e % 2 else 30))
    return n

def write_midi(path, layers):
    mid = mido.MidiFile(ticks_per_beat=TPB)
    meta = mido.MidiTrack(); mid.tracks.append(meta)
    meta.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(BPM)))
    meta.append(mido.MetaMessage("time_signature", numerator=4, denominator=4))
    for L in layers:
        ch, prog, vol = LAYERS[L]
        tr = mido.MidiTrack(); mid.tracks.append(tr)
        tr.append(mido.MetaMessage("track_name", name=L))
        tr.append(mido.Message("program_change", channel=ch, program=prog))
        tr.append(mido.Message("control_change", channel=ch, control=7, value=vol))
        tr.append(mido.Message("control_change", channel=ch, control=91, value=70))  # Hall
        ev = []
        for s, p, d, v in notes_for(L):
            s = max(0, s)
            ev.append((int(s * TPB), 1, p, v)); ev.append((int((s + d) * TPB), 0, p, 0))
        ev.sort(key=lambda e: (e[0], e[1]))
        last = 0
        for t, on, p, v in ev:
            tr.append(mido.Message("note_on" if on else "note_off", channel=ch, note=p,
                                   velocity=v, time=t - last)); last = t
        tr.append(mido.MetaMessage("end_of_track", time=BARS * 4 * TPB - last if BARS * 4 * TPB > last else 0))
    mid.save(path)

def render(layers, wav_path, tail=4.0):
    synth = tinysoundfont.Synth(samplerate=SR, gain=-3)
    sf = synth.sfload("/usr/share/sounds/sf2/TimGM6mb.sf2")
    ev = []
    for L in layers:
        ch, prog, vol = LAYERS[L]
        synth.program_select(ch, sf, 0, prog, is_drums=(ch == 9))
        synth.control_change(ch, 7, vol)
        for s, p, d, v in notes_for(L):
            s = max(0, s)
            ev.append((s * BEAT, 1, ch, p, v)); ev.append(((s + d) * BEAT, 0, ch, p, 0))
    ev.sort(key=lambda e: (e[0], e[1]))
    loop_len = BARS * 4 * BEAT
    total = int((loop_len + tail) * SR)
    out = np.zeros((total, 2), dtype=np.float32)

    pos = 0
    def gen(n):
        nonlocal pos
        if n <= 0: return
        buf = np.frombuffer(synth.generate(n), dtype=np.float32).reshape(-1, 2)
        out[pos:pos + len(buf)] = buf; pos += len(buf)
    for t, on, ch, p, v in ev:
        gen(int(t * SR) - pos)
        synth.noteon(ch, p, v) if on else synth.noteoff(ch, p)
    gen(total - pos)
    # Ausklang an den Anfang falten -> nahtloser Loop
    L = int(loop_len * SR)
    loop = out[:L].copy(); loop[:total - L] += out[L:]
    loop /= max(1e-6, np.abs(loop).max()) / 0.8
    import wave
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((loop * 32767).astype(np.int16).tobytes())

def to_ogg(wav, ogg, lofi=True):
    af = "lowpass=f=6500,aecho=0.8:0.6:90|210:0.22|0.12,volume=2.4" if lofi else "anull"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af", af,
                    "-t", f"{BARS*4*BEAT:.4f}", "-c:a", "libvorbis", "-q:a", "6", ogg], check=True)
    os.remove(wav)

if __name__ == "__main__":
    for d in ("midi", "ogg"):
        os.makedirs(f"{OUT}/{d}", exist_ok=True)
    write_midi(f"{OUT}/midi/mondgarten_komplett.mid", list(LAYERS))
    for L in LAYERS:
        write_midi(f"{OUT}/midi/mondgarten_{L}.mid", [L])
    full = [l for l in LAYERS if l != "6_summen"]
    render(full, f"{OUT}/ogg/_tmp.wav"); to_ogg(f"{OUT}/ogg/_tmp.wav", f"{OUT}/ogg/mondgarten_vorschau.ogg")
    render(list(LAYERS), f"{OUT}/ogg/_tmp.wav"); to_ogg(f"{OUT}/ogg/_tmp.wav", f"{OUT}/ogg/mondgarten_vorschau_vollmond.ogg")
    print("fertig")
