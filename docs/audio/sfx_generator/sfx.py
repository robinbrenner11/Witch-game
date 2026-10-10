"""Soundeffekte für Bitterbloom, komplett per Synthese erzeugt (numpy/scipy).

Aufruf (aus dem Projektordner):
    python docs/audio/sfx_generator/sfx.py              # alle Effekte
    python docs/audio/sfx_generator/sfx.py snap harvest # nur passende IDs
    python docs/audio/sfx_generator/sfx.py --preview    # alle + docs/audio/sfx_vorschau.ogg (braucht ffmpeg)

Regeln aus docs/prompts/sound_auftrag_effekte.md: weich, gläsern, nah,
tonale Effekte in D-dorisch (D E F G A H C), WAV 44,1 kHz / 16 Bit / mono
(Atmos stereo),
Spitze höchstens -3 dBFS, Loops nahtlos (Rauschen, Filter und Hall werden
dafür zirkulär berechnet).

Lautheit: Alle Effekte werden auf dieselbe Kurzzeit-Lautheit gebracht
(lautestes 100-ms-Fenster, TARGET_DB) und bei -3 dBFS Spitze begrenzt. Der
Wert `level` in EFFECTS verschiebt das bewusst (Hover und Aura-Loops leiser,
besondere Momente lauter). Jeder Effekt hat einen festen Zufalls-Seed, damit
ein erneuter Aufruf genau dieselben Dateien erzeugt.
"""
import subprocess
import sys
import zlib
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets" / "audio" / "sfx"
PREVIEW = ROOT / "docs" / "audio" / "sfx_vorschau.ogg"
TARGET_DB = -17.0

# D-dorisch, Frequenzen in Hz
D2, A2, D3, A3 = 73.42, 110.0, 146.83, 220.0
D4, E4, F4, A4 = 293.66, 329.63, 349.23, 440.0
D5, E5, F5, G5, A5, C6 = 587.33, 659.26, 698.46, 783.99, 880.0, 1046.5
D6, E6, F6, A6, C7, D7 = 1174.66, 1318.51, 1396.91, 1760.0, 2093.0, 2349.32


# ---------- Bausteine ----------
def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def lp(x, hz, order=2):
    return sosfilt(butter(order, hz, "low", fs=SR, output="sos"), x)


def hp(x, hz, order=2):
    return sosfilt(butter(order, hz, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], "band", fs=SR, output="sos"), x)


def lp_circular(x, hz, order=2):
    """Tiefpass für Loops: dreifach aneinanderhängen, Mitte nehmen -> keine Naht."""
    n = len(x)
    return lp(np.tile(x, 3), hz, order)[n:2 * n]


def periodic_noise(n, rng, tilt=0.0, lo=20, hi=16000):
    """Rauschen, das exakt n Samples lang periodisch ist (für nahtlose Loops).
    tilt: -1 = braun-ish, -0.5 = rosa-ish, 0 = weiß."""
    spec = rng.normal(size=n // 2 + 1) + 1j * rng.normal(size=n // 2 + 1)
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = 1
    spec *= f ** tilt
    spec[(f < lo) | (f > hi)] = 0
    x = np.fft.irfft(spec, n)
    return x / (np.max(np.abs(x)) + 1e-9)


def env_exp(n, tau, attack=0.002):
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-5), 0, 1)
    return a * np.exp(-t / tau)


def env_swell(n, rise, tau):
    """Weiches Anschwellen bis `rise` Sekunden, danach exponentielles Abklingen."""
    t = np.arange(n) / SR
    up = np.clip(t / rise, 0, 1) ** 2
    down = np.where(t > rise, np.exp(-(t - rise) / tau), 1.0)
    return up * down


def norm(x):
    return x / (np.max(np.abs(x)) + 1e-9)


def wobble(n, rng, rate_hz, depth=0.5):
    """Unregelmäßige, langsame Lautstärke-Schwankung (Gurgeln, Rascheln)."""
    m = norm(lp(np.abs(rng.normal(size=n)), rate_hz))
    return (1 - depth) + depth * m


def place(out, x, at_sec, gain=1.0):
    i = int(at_sec * SR)
    m = min(len(x), len(out) - i)
    if m > 0:
        out[i:i + m] += gain * x[:m]
    return out


def place_circular(out, x, at_sec, gain=1.0):
    idx = (int(at_sec * SR) + np.arange(len(x))) % len(out)
    np.add.at(out, idx, gain * x)
    return out


def osc(freq):
    """Sinus mit beliebigem Frequenzverlauf (Array) -> Glissandi ohne Knackser."""
    return np.sin(2 * np.pi * np.cumsum(freq) / SR)


def glide(f0, f1, sec, glide_sec=None):
    n = int(SR * sec)
    g = int(SR * (glide_sec or sec))
    f = np.full(n, float(f1))
    k = np.linspace(0, 1, min(g, n))
    f[: len(k)] = f0 * (f1 / f0) ** k
    return f


def chirp(f0, ratio, dur, tau_mul=0.35, attack=0.004):
    """Blase: Ton mit steigender Tonhöhe, wie eine echte Luftblase in Flüssigkeit."""
    m = int(SR * dur)
    tb = np.arange(m) / SR
    return osc(f0 * (1 + (ratio - 1) * tb / dur)) * env_exp(m, dur * tau_mul, attack)


def grains(n, rng, count, t0, t1, lo, hi, dur=(0.003, 0.008), amp=(0.1, 0.3)):
    """Viele winzige, gefilterte Rauschkörner: Krümel, Kies, Wurzelfasern."""
    out = np.zeros(n)
    for _ in range(count):
        m = int(SR * rng.uniform(*dur))
        g = bp(rng.normal(size=m + 64), lo, hi)[64:] * np.hanning(m)
        place(out, g, rng.uniform(t0, t1), rng.uniform(*amp))
    return out


def burst(n, rng, lo, hi, tau, attack=0.002):
    noise = rng.normal(size=n)
    noise = lp(noise, hi) if lo is None else bp(noise, lo, hi)
    return noise * env_exp(n, tau, attack)


def thump(f0, f1, sec, tau, attack=0.003):
    """Weicher, tiefer Druck mit fallender Tonhöhe (Schritte, Ablegen)."""
    n = int(SR * sec)
    return osc(glide(f0, f1, sec, glide_sec=tau * 1.5)) * env_exp(n, tau, attack)


def reverb_ir(sec, rng, decay, bright=4000):
    n = int(SR * sec)
    ir = rng.normal(size=n) * np.exp(-np.arange(n) / SR / decay)
    ir = lp(ir, bright)
    ir[0] = 0
    return ir / np.sqrt(np.sum(ir ** 2))


def add_reverb(x, rng, wet=0.18, sec=1.2, decay=0.35, bright=4000, circular=False):
    ir = reverb_ir(sec, rng, decay, bright)
    if circular:  # Loop: Hallfahne läuft in den Anfang zurück
        n = len(x)
        h = np.zeros(n)
        h[: min(n, len(ir))] = ir[:n]
        y = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(h), n)
    else:
        y = np.convolve(x, ir)[: len(x) + len(ir) // 2]
        x = np.pad(x, (0, len(y) - len(x)))
    return x * (1 - wet) + y * wet


def bell(freq, sec, rng, partials=((1, 1.0, 1.0), (2.0, 0.35, 0.45), (3.01, 0.15, 0.25), (4.17, 0.06, 0.15)),
         tau=0.5, detune=1.5):
    """Gläserner Glockenton: wenige Teiltöne, obere klingen schneller ab,
    zwei leicht verstimmte Stimmen für sanftes Schimmern."""
    t = t_axis(sec)
    out = np.zeros_like(t)
    for ratio, amp, tau_mul in partials:
        for d in (-detune, detune):
            ph = rng.uniform(0, 2 * np.pi)
            out += amp * np.sin(2 * np.pi * (freq * ratio + d) * t + ph) * np.exp(-t / (tau * tau_mul))
    return out * np.clip(t / 0.004, 0, 1)


GLASS = ((1, 1.0, 1.0), (1.58, 0.5, 0.6), (2.31, 0.3, 0.4), (3.07, 0.12, 0.3))


def glass_hit(freq, rng, tau=0.06, sec=0.3):
    """Zwei Glasfläschchen berühren sich: unharmonische, kurze Teiltöne."""
    return bell(freq, sec, rng, partials=GLASS, tau=tau, detune=4)


def pad(freqs, sec, rng, attack, tau, detune=0.8):
    t = t_axis(sec)
    out = np.zeros_like(t)
    for f in freqs:
        for d in (-detune, detune):
            out += np.sin(2 * np.pi * (f + d) * t + rng.uniform(0, 2 * np.pi))
    return out * env_swell(len(t), attack, tau) / len(freqs)


def choir(freq, sec, rng, attack, tau):
    """Wortloses „Ah“: obertonreicher Ton durch zwei Formant-Filter (ca. 700 und 1150 Hz)."""
    t = t_axis(sec)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t)
    phase = 2 * np.pi * np.cumsum(freq * vib) / SR
    saw = sum(np.sin(k * phase) / k for k in range(1, int(3500 / freq)))
    voice = bp(saw, 600, 850) + 0.6 * bp(saw, 1000, 1300) + 0.15 * lp(rng.normal(size=len(t)), 4000) * 0.05
    return voice * env_swell(len(t), attack, tau)


def short_term_rms(x, win=0.1):
    w = int(SR * win)
    if len(x) <= w:
        return np.sqrt(np.mean(x ** 2))
    c = np.cumsum(np.concatenate([[0], x ** 2]))
    return np.sqrt(np.max(c[w:] - c[:-w]) / w)


def finish(x, level=0.0, loop=False, max_sec=None, peak_db=-3.0, fade_ms=10):
    """Gleiche Lautheit für alle, Spitze begrenzen. x ist mono (n,) oder stereo (n, 2)."""
    x = x - np.mean(x, axis=0)
    mono = x if x.ndim == 1 else x.mean(axis=1)
    if not loop:
        # Start sofort beim ersten Sample (keine Stille vorne)
        idx = np.argmax(np.abs(mono) > 1e-4 * np.max(np.abs(mono)))
        x, mono = x[idx:], mono[idx:]
        if max_sec:
            x, mono = x[: int(max_sec * SR)], mono[: int(max_sec * SR)]
        f = int(SR * fade_ms / 1000)
        ramp = np.linspace(1, 0, f) ** 2
        x[-f:] *= ramp if x.ndim == 1 else ramp[:, None]
    gain_loud = 10 ** ((TARGET_DB + level) / 20) / (short_term_rms(mono) + 1e-9)
    gain_peak = 10 ** (peak_db / 20) / (np.max(np.abs(x)) + 1e-9)
    return x * min(gain_loud, gain_peak)


# ---------- Hexe: player/ ----------
def snap(rng):
    """Schnippen mit den schwarzen Fingern, danach ein Magenta-Funke auf D."""
    n = int(SR * 1.0)
    out = np.zeros(n)
    # Schnipp: kurzer, warmer Rausch-Knack (Bandpass statt hartem Klick)
    k = int(SR * 0.05)
    click = bp(rng.normal(size=k), 1200, 3200) * env_exp(k, 0.007, attack=0.0008)
    click += 0.4 * lp(rng.normal(size=k), 700) * env_exp(k, 0.012, attack=0.0008)
    out[:k] += 0.9 * click
    # Funke: D6 + A5 als gläserner Zweiklang, kurz nach dem Schnipp
    start = int(SR * 0.035)
    spark = bell(D6, 0.95, rng, tau=0.32) + 0.45 * bell(A5, 0.95, rng, tau=0.4)
    t = t_axis(0.95)
    shimmer = hp(rng.normal(size=len(t)), 5000) * np.exp(-t / 0.08) * 0.05
    spark = lp(spark + shimmer, 7000)
    out[start:start + len(spark)] += 0.55 * spark[: n - start]
    return add_reverb(out, rng, wet=0.22, sec=0.5, decay=0.25)


def step_soil(rng, variant=1):
    """Schritt auf weicher Gartenerde: dumpfer Druck + Krümel, nah und leise."""
    sec = 0.26
    n = int(SR * sec)
    t = t_axis(sec)
    pitch = 1 + 0.06 * (variant - 2.5) * rng.uniform(0.5, 1)
    f = (95 + 60 * np.exp(-t / 0.02)) * pitch
    thump_ = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, 0.035, attack=0.003)
    soil = lp(rng.normal(size=n), 900 * pitch, order=3)
    e = env_exp(n, 0.04, attack=0.004)
    roll = int(SR * rng.uniform(0.05, 0.07))
    e[roll:] += 0.55 * env_exp(n - roll, 0.035, attack=0.006)
    soil *= e
    crumbs = np.zeros(n)
    for _ in range(rng.integers(4, 8)):
        p = rng.integers(int(0.01 * SR), int(0.18 * SR))
        m = int(SR * 0.006)
        crumbs[p:p + m] += bp(rng.normal(size=m), 1500, 4000) * np.hanning(m) * rng.uniform(0.1, 0.3)
    out = 0.9 * thump_ + 0.8 * soil + crumbs
    return lp(out, 3500)


def _two_phase_env(n, rng, tau):
    """Ferse und Ballen: zwei kurze Phasen pro Schritt."""
    e = env_exp(n, tau, attack=0.004)
    roll = int(SR * rng.uniform(0.05, 0.075))
    e[roll:] += rng.uniform(0.45, 0.65) * env_exp(n - roll, tau * 0.9, attack=0.006)
    return e


def step_grass(rng, variant):
    """Schritt im Gras: leises Rascheln der Halme, kaum Druck."""
    sec, p = 0.26, [0.95, 1.0, 1.05, 0.98][variant - 1]
    n = int(SR * sec)
    rustle = lp(bp(rng.normal(size=n), 1800 * p, 7000), 6000) * _two_phase_env(n, rng, 0.05)
    rustle *= wobble(n, rng, 90, 0.6)
    blades = grains(n, rng, 10, 0.0, 0.15, 2500 * p, 7000, amp=(0.05, 0.15))
    body = thump(115 * p, 85 * p, sec, 0.03)
    return lp(0.75 * rustle + blades + 0.35 * body, 6500)


def step_path(rng, variant):
    """Schritt auf festgetretenem Weg: fester Druck, etwas Kies."""
    sec, p = 0.26, [0.96, 1.0, 1.04, 0.99][variant - 1]
    n = int(SR * sec)
    body = thump(190 * p, 115 * p, sec, 0.03)
    dirt = lp(rng.normal(size=n), 1500 * p) * _two_phase_env(n, rng, 0.03)
    gravel = grains(n, rng, 14, 0.005, 0.12, 1500 * p, 5000, dur=(0.002, 0.006), amp=(0.1, 0.35))
    return lp(0.7 * body + 0.5 * dirt + gravel, 4500)


def step_stone(rng, variant):
    """Schritt auf Steinplatten im Unterschlupf: leiser Absatz, kurzer Raumklang."""
    sec, p = 0.22, [0.97, 1.0, 1.03, 0.985][variant - 1]
    n = int(SR * sec)
    t = t_axis(sec)
    tap = (np.sin(2 * np.pi * 170 * p * t) + 0.3 * np.sin(2 * np.pi * 395 * p * t)) * env_exp(n, 0.02, 0.0015)
    click = burst(n, rng, 500, 2500, 0.012, attack=0.001)
    scuff = place(np.zeros(n), burst(int(SR * 0.08), rng, 1500, 5000, 0.03, attack=0.01), rng.uniform(0.045, 0.06))
    out = lp(0.7 * tap + 0.5 * click + 0.15 * scuff, 4000)
    return add_reverb(out, rng, wet=0.28, sec=0.35, decay=0.07, bright=3000)


def float_start(rng):
    """Abheben beim Schweben: weicher Luftzug, der hell wird, plus kurzes Glitzern."""
    sec = 0.6
    n = int(SR * sec)
    t = t_axis(sec)
    noise = rng.normal(size=n)
    env = env_swell(n, 0.18, 0.15)
    bright = np.clip(t / 0.25, 0, 1)
    whoosh = (lp(noise, 700) * (1 - 0.6 * bright) + 0.5 * bp(noise, 1500, 5000) * bright) * env
    out = 0.8 * whoosh
    for f, at in ((D6, 0.12), (F6, 0.2), (A6, 0.28)):
        place(out, bell(f, 0.4, rng, tau=0.15), at, 0.13)
    return add_reverb(lp(out, 7000), rng, wet=0.2, sec=0.6, decay=0.2)


def float_loop(rng):
    """Schweben hält an: leises magisches Schimmern. 3 s, nahtlos."""
    sec = 3.0
    n = int(SR * sec)
    t = np.arange(n) / SR
    per = lambda f: round(f * sec) / sec  # ganze Schwingungen pro Loop -> keine Naht
    out = np.zeros(n)
    for f, a, k in ((D4, 0.5, 1), (A4, 0.35, 2), (D5, 0.2, 3)):
        am = 1 + 0.3 * np.sin(2 * np.pi * k * t / sec + rng.uniform(0, 6))
        out += a * np.sin(2 * np.pi * per(f) * t) * am
    air = periodic_noise(n, rng, tilt=-0.3, lo=3000, hi=9000)
    out += 0.12 * air * (0.6 + 0.4 * np.sin(2 * np.pi * 2 * t / sec))
    for at in rng.uniform(0, sec, 6):
        place_circular(out, bell(rng.choice([D6, F6, A6, C7]), 0.4, rng, tau=0.12), at, 0.08)
    out = lp_circular(out, 6000)
    return add_reverb(out, rng, wet=0.25, sec=1.0, decay=0.35, circular=True)


# ---------- Garten: garden/ ----------
def bed_wake(rng):
    """Erde wacht auf: Boden lockert sich, Krümel, tiefes warmes Brummen, Glitzer am Ende."""
    sec = 1.0
    n = int(SR * sec)
    t = t_axis(sec)
    loosen = lp(rng.normal(size=n), 500) * env_swell(n, 0.45, 0.2)
    crumbs = np.zeros(n)
    for _ in range(40):  # Krümel werden dichter, je mehr die Erde aufbricht
        m = int(SR * rng.uniform(0.003, 0.008))
        g = bp(rng.normal(size=m + 64), 600, 2500)[64:] * np.hanning(m)
        place(crumbs, g, 0.6 * np.sqrt(rng.uniform()), rng.uniform(0.1, 0.3))
    hum_env = env_swell(n, 0.25, 0.35)
    hum = (np.sin(2 * np.pi * D2 * t) + 0.6 * np.sin(2 * np.pi * D3 * t) + 0.15 * np.sin(2 * np.pi * A3 * t)) * hum_env
    out = 0.6 * loosen + crumbs + 0.45 * lp(hum, 800)
    for f, at in ((D6, 0.62), (A6, 0.7), (D7, 0.78)):
        place(out, bell(f, 0.3, rng, tau=0.2), at, 0.12)
    return add_reverb(out, rng, wet=0.18, sec=0.8, decay=0.3)


def bed_sleep(rng):
    """Beet legt sich schlafen: Erde setzt sich, leises Absinken."""
    sec = 0.8
    n = int(SR * sec)
    settle = lp(rng.normal(size=n), 700) * env_exp(n, 0.2, attack=0.02)
    sink = osc(glide(A3, D3, sec, glide_sec=0.6)) * env_exp(n, 0.25, attack=0.05)
    crumbs = grains(n, rng, 8, 0.0, 0.3, 800, 2500, amp=(0.1, 0.2))
    return lp(0.6 * settle + 0.4 * sink + crumbs, 2500)


def plant_seed(rng):
    """Samen in die Erde drücken: weich, mit kleinem Nachklopfen."""
    sec = 0.4
    n = int(SR * sec)
    out = np.zeros(n)
    place(out, thump(130, 90, 0.2, 0.04), 0.0, 0.6)
    place(out, thump(150, 105, 0.15, 0.025), 0.12, 0.3)
    out += 0.5 * lp(rng.normal(size=n), 1000) * env_exp(n, 0.05, attack=0.004)
    out += grains(n, rng, 3, 0.0, 0.15, 1200, 3000, amp=(0.08, 0.15))
    return lp(out, 3000)


def harvest(rng, variant):
    """Pflanze herausziehen: Wurzeln lösen sich, Blätter rascheln."""
    sec = 0.5
    n = int(SR * sec)
    p = [0.95, 1.0, 1.06][variant - 1]
    leaves = lp(bp(rng.normal(size=n), 2000 * p, 6500), 6000) * env_exp(n, 0.18, attack=0.02)
    leaves *= wobble(n, rng, 60, 0.6)
    roots = grains(n, rng, 12, 0.05, 0.28, 600 * p, 2200 * p, amp=(0.2, 0.5))
    tug_at = 0.22 + rng.uniform(-0.03, 0.03)
    tug = np.zeros(n)
    place(tug, osc(glide(180 * p, 320 * p, 0.1, glide_sec=0.04)) * env_exp(int(SR * 0.1), 0.03), tug_at, 0.5)
    place(tug, burst(int(SR * 0.06), rng, None, 1200, 0.02), tug_at, 0.4)
    fall = grains(n, rng, 6, 0.3, 0.45, 900, 3000, amp=(0.06, 0.12))
    return lp(0.35 * leaves + roots + tug + fall, 5500)


def grow_magic(rng):
    """Pflanze wächst sofort durch Magie: aufsteigendes Glitzern, organisches Knistern."""
    sec = 1.0
    n = int(SR * sec)
    out = np.zeros(n)
    for i, f in enumerate((D5, F5, A5, C6, D6)):
        place(out, bell(f, 0.7, rng, tau=0.35), 0.08 * i, 0.22 + 0.04 * i)
    out += grains(n, rng, 18, 0.0, 0.5, 700, 2500, amp=(0.08, 0.2))
    out += 0.15 * pad((D4, A4), sec, rng, attack=0.4, tau=0.3)
    t = t_axis(sec)
    out += 0.03 * hp(rng.normal(size=n), 5000) * env_swell(n, 0.3, 0.2)
    return add_reverb(lp(out, 7000), rng, wet=0.25, sec=1.0, decay=0.35)


def pour(rng):
    """Trank auf Erde gießen: kurzes Glas, dann ein weicher, gurgelnder Strahl."""
    sec = 1.2
    n = int(SR * sec)
    out = np.zeros(n)
    place(out, glass_hit(2600, rng), 0.0, 0.25)
    m = int(SR * 0.85)
    stream = bp(rng.normal(size=m), 400, 2500) * wobble(m, rng, 25, 0.5)
    stream *= np.clip(np.arange(m) / (SR * 0.1), 0, 1) * np.clip((m - np.arange(m)) / (SR * 0.3), 0, 1)
    place(out, stream, 0.08, 0.45)
    for at in rng.uniform(0.12, 0.85, 10):
        place(out, chirp(rng.uniform(300, 800), 1.6, rng.uniform(0.03, 0.06)), at, rng.uniform(0.1, 0.25))
    place(out, burst(int(SR * 0.2), rng, None, 600, 0.06, attack=0.01), 0.85, 0.2)
    return add_reverb(lp(out, 5000), rng, wet=0.15, sec=0.6, decay=0.2)


def pour_sludge(rng):
    """Hexenschlamm gießen: zähes, langsames Glucksen, ein bisschen eklig, aber leise."""
    sec = 1.2
    n = int(SR * sec)
    out = np.zeros(n)
    for at in (0.05, 0.25, 0.45, 0.65, 0.85):
        dur = rng.uniform(0.12, 0.18)
        at += rng.uniform(-0.03, 0.03)
        place(out, chirp(rng.uniform(90, 150), 1.8, dur, tau_mul=0.4, attack=0.01), at, 0.6)
        place(out, burst(int(SR * dur), rng, None, 500, dur * 0.3, attack=0.01), at, 0.35)
    wet = lp(rng.normal(size=n), 600) * wobble(n, rng, 6, 0.6)
    wet *= np.clip(np.arange(n) / (SR * 0.05), 0, 1) * np.clip((n - np.arange(n)) / (SR * 0.3), 0, 1)
    out += 0.25 * wet
    return add_reverb(lp(out, 1800), rng, wet=0.12, sec=0.5, decay=0.15)


def nightshade_loop(rng):
    """Nachtschatten-Aura: kühles, leises Wabern mit Flüstern. 4 s, nahtlos."""
    sec = 4.0
    n = int(SR * sec)
    t = np.arange(n) / SR
    # Alle Frequenzen sind Vielfache von 0,25 Hz -> exakt periodisch in 4 s.
    # Je zwei Töne liegen 0,5 Hz auseinander und schweben dadurch langsam.
    out = np.zeros(n)
    for f, a in ((220.0, 0.5), (220.5, 0.5), (293.75, 0.35), (294.25, 0.35), (349.25, 0.12)):
        out += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6))
    out *= 1 + 0.25 * np.sin(2 * np.pi * 0.5 * t)
    whisper = bp(periodic_noise(n, rng, tilt=-0.5, lo=1200, hi=4500), 1200, 4500)
    whisper = np.roll(whisper, 0)  # Filter-Einschwingen ist durch lp_circular unten egal
    out += 0.25 * whisper * (0.5 + 0.5 * np.sin(2 * np.pi * t / sec + 1.0)) ** 2
    out = lp_circular(out, 5000)
    return add_reverb(out, rng, wet=0.3, sec=1.5, decay=0.5, bright=3000, circular=True)


# ---------- Kessel und Tränke: brewing/ ----------
def cauldron_loop(rng):
    """Kessel blubbert ruhig: tiefes Köcheln + einzelne zähe Blasen. 5 s, nahtlos."""
    sec = 5.0
    n = int(SR * sec)
    simmer = periodic_noise(n, rng, tilt=-1.0, lo=30, hi=400)
    breathe = 1 + 0.25 * np.sin(2 * np.pi * np.arange(n) / n * 2)
    out = 0.35 * simmer * breathe
    times = np.sort(rng.uniform(0, sec, 22))
    for tt in times:
        dur = rng.uniform(0.05, 0.12)
        m = int(SR * dur)
        tb = np.arange(m) / SR
        f0 = rng.uniform(140, 420)
        f = f0 * (1 + 1.4 * tb / dur)
        b = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(m, dur * 0.35, attack=0.004)
        b += 0.3 * lp(rng.normal(size=m), 600) * env_exp(m, dur * 0.2)
        idx = (int(tt * SR) + np.arange(m)) % n
        out[idx] += b * rng.uniform(0.25, 0.6)
    out = lp_circular(out, 2500)
    return add_reverb(out, rng, wet=0.2, sec=0.8, decay=0.25, bright=2500, circular=True)


def ingredient_drop(rng):
    """Zutat fällt in den Kessel: „Plopp“ in dicker Flüssigkeit, danach ein paar Blasen."""
    sec = 0.5
    n = int(SR * sec)
    out = np.zeros(n)
    place(out, burst(int(SR * 0.1), rng, None, 1800, 0.03), 0.0, 0.35)
    place(out, osc(glide(220, 700, 0.25, glide_sec=0.035)) * env_exp(int(SR * 0.25), 0.05, 0.003), 0.01, 0.8)
    for at in (0.12, 0.2, 0.3):
        place(out, chirp(rng.uniform(300, 500), 1.5, 0.04), at + rng.uniform(-0.02, 0.02), 0.25)
    return add_reverb(lp(out, 3000), rng, wet=0.15, sec=0.5, decay=0.15)


def brew_start(rng):
    """Brauen beginnt: Sud zischt auf, magischer Schwall, endet ruhig."""
    sec = 1.5
    n = int(SR * sec)
    t = t_axis(sec)
    out = 0.3 * lp(bp(rng.normal(size=n), 2000, 6000), 5000) * env_swell(n, 0.12, 0.35)
    out += 0.4 * lp(rng.normal(size=n), 900) * env_swell(n, 0.3, 0.35)
    for i, f in enumerate((D5, F5, A5, C6)):
        place(out, bell(f, 1.2, rng, tau=0.5), 0.1 + 0.06 * i, 0.28)
    trem = 1 + 0.3 * np.sin(2 * np.pi * 6 * t)
    out += 0.15 * pad((D4, A4), sec, rng, attack=0.3, tau=0.5) * trem
    for at in rng.uniform(0.0, 0.9, 14):
        place(out, chirp(rng.uniform(250, 700), 1.6, rng.uniform(0.03, 0.07)), at, rng.uniform(0.1, 0.25))
    return add_reverb(lp(out, 6000), rng, wet=0.22, sec=1.2, decay=0.4)


def potion_take(rng):
    """Fertigen Trank abholen: Glas-Klirren und ein kleiner Glockenton (besonderer Moment)."""
    sec = 0.6
    n = int(SR * sec)
    out = np.zeros(n)
    place(out, glass_hit(2900, rng, tau=0.05), 0.0, 0.4)
    place(out, glass_hit(3300, rng, tau=0.04), 0.06, 0.25)
    place(out, bell(D6, 0.6, rng, tau=0.35), 0.05, 0.4)
    place(out, bell(A6, 0.5, rng, tau=0.3), 0.12, 0.2)
    return add_reverb(lp(out, 7000), rng, wet=0.22, sec=0.8, decay=0.3)


def drink(rng):
    """Trinken: Glas an den Lippen, zwei weiche Schlucke."""
    sec = 1.0
    n = int(SR * sec)
    out = np.zeros(n)
    place(out, glass_hit(3100, rng, tau=0.03), 0.0, 0.15)
    place(out, burst(int(SR * 0.25), rng, 300, 1500, 0.08, attack=0.02), 0.1, 0.2)
    for at in (0.32, 0.62):
        at += rng.uniform(-0.02, 0.02)
        place(out, osc(glide(180, 110, 0.15, glide_sec=0.08)) * env_exp(int(SR * 0.15), 0.05, 0.006), at, 0.6)
        place(out, burst(int(SR * 0.12), rng, None, 700, 0.04, attack=0.005), at, 0.4)
        place(out, burst(int(SR * 0.08), rng, 400, 1200, 0.02), at + 0.01, 0.15)
    place(out, burst(int(SR * 0.2), rng, 500, 2500, 0.08, attack=0.03), 0.82, 0.08)
    return lp(out, 3500)


def wisp_appear(rng):
    """Irrlicht erscheint: verspieltes, leicht unheimliches Glimmen, hoher gläserner Ton."""
    sec = 1.2
    n = int(SR * sec)
    t = t_axis(sec)
    f = glide(D6, A6, sec, glide_sec=0.25) * (1 + 0.006 * np.sin(2 * np.pi * 6 * t))
    env = env_swell(n, 0.05, 0.45)
    tone = (osc(f) + 0.2 * osc(2 * f) + 0.5 * osc(f + 3) * (0.5 + 0.5 * np.sin(2 * np.pi * 4 * t))) * env
    out = 0.35 * tone
    for at in rng.uniform(0.1, 0.7, 6):
        place(out, bell(rng.choice([E6, F6, A6, C7]), 0.3, rng, tau=0.1), at, 0.1)
    out += 0.06 * np.sin(2 * np.pi * D4 * t) * env_swell(n, 0.4, 0.4)
    return add_reverb(lp(out, 7500), rng, wet=0.3, sec=1.2, decay=0.4)


def moonlight(rng):
    """Flüssiges Mondlicht: kühles, weites Aufleuchten mit einem Hauch Chor."""
    sec = 1.5
    n = int(SR * sec)
    out = 0.5 * pad((D4, A4, E5, F5), sec, rng, attack=0.35, tau=0.6)
    out += 0.12 * norm(choir(D4, sec, rng, 0.4, 0.6) + choir(A4, sec, rng, 0.45, 0.6))
    place(out, bell(D6, 1.2, rng, tau=0.6), 0.1, 0.2)
    out += 0.02 * hp(rng.normal(size=n), 5000) * env_swell(n, 0.4, 0.4)
    return add_reverb(lp(out, 7000), rng, wet=0.35, sec=2.0, decay=0.7, bright=5000)


def endless_night(rng):
    """Ewige Nacht: tiefes, langsames Anschwellen, als würde die Zeit gedehnt."""
    sec = 2.0
    n = int(SR * sec)
    t = t_axis(sec)
    drift = 1 - 0.015 * t / sec
    env = env_swell(n, 1.1, 0.35)
    out = (0.5 * osc(D2 * drift) + 0.3 * osc(A2 * drift) + 0.2 * osc(D3 * drift)) * env
    out += 0.2 * lp(rng.normal(size=n), 300) * env
    trem_rate = 3.0 * (0.8 / 3.0) ** (t / sec)  # Puls wird langsamer: Zeit dehnt sich
    out *= 1 - 0.2 * (0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(trem_rate) / SR))
    return add_reverb(out, rng, wet=0.3, sec=2.0, decay=0.8, bright=2000)


# ---------- Benutzeroberfläche: ui/ ----------
def ui_click(rng):
    sec = 0.12
    n = int(SR * sec)
    t = t_axis(sec)
    out = 0.6 * np.sin(2 * np.pi * D6 * t) * env_exp(n, 0.018, 0.001)
    out += 0.2 * np.sin(2 * np.pi * D6 * 2.4 * t) * env_exp(n, 0.008, 0.001)
    out += 0.3 * burst(n, rng, 1000, 3000, 0.004, attack=0.0008)
    return lp(out, 6000)


def ui_hover(rng):
    sec = 0.08
    n = int(SR * sec)
    t = t_axis(sec)
    out = 0.3 * np.sin(2 * np.pi * D7 * t) * env_exp(n, 0.008, 0.001)
    out += 0.1 * burst(n, rng, 3000, 6000, 0.003, attack=0.0008)
    return lp(out, 7000)


def _ui_window(rng, notes):
    sec = 0.3
    n = int(SR * sec)
    out = 0.3 * bp(rng.normal(size=n), 600, 3000) * env_swell(n, 0.06, 0.07)
    place(out, bell(notes[0], 0.25, rng, tau=0.15), 0.02, 0.25)
    place(out, bell(notes[1], 0.25, rng, tau=0.15), 0.09, 0.3)
    return add_reverb(lp(out, 6500), rng, wet=0.15, sec=0.4, decay=0.12)


def ui_open(rng):
    return _ui_window(rng, (D5, A5))


def ui_close(rng):
    return _ui_window(rng, (A5, D5))


def ui_page_turn(rng):
    """Buchseite umblättern: Papier-Wischen mit Knistern, unten ein weicher Flapp."""
    sec = 0.4
    n = int(SR * sec)
    paper = bp(rng.normal(size=n), 1200, 7000) * wobble(n, rng, 300, 0.8)
    out = 0.5 * paper * env_swell(n, 0.15, 0.08)
    place(out, burst(int(SR * 0.12), rng, None, 500, 0.03, attack=0.01), 0.2, 0.2)
    return lp(out, 7000)


def ui_item_pick(rng):
    sec = 0.12
    n = int(SR * sec)
    out = 0.5 * osc(glide(600, 900, sec, glide_sec=0.04)) * env_exp(n, 0.03, 0.002)
    out += 0.15 * burst(n, rng, 2000, 5000, 0.003, attack=0.0008)
    return lp(out, 6000)


def ui_item_drop(rng):
    sec = 0.15
    n = int(SR * sec)
    out = 0.6 * osc(glide(300, 200, sec, glide_sec=0.05)) * env_exp(n, 0.035, 0.002)
    out += 0.3 * burst(n, rng, None, 1200, 0.015)
    return lp(out, 4000)


def ui_item_get(rng):
    """Etwas ins Inventar bekommen: kleiner, freundlicher Zweiklang."""
    sec = 0.4
    n = int(SR * sec)
    out = np.zeros(n)
    place(out, bell(A5, 0.4, rng, tau=0.18), 0.0, 0.35)
    place(out, bell(D6, 0.35, rng, tau=0.25), 0.07, 0.4)
    return add_reverb(lp(out, 7000), rng, wet=0.18, sec=0.5, decay=0.15)


def ui_denied(rng):
    """Geht nicht: zwei weiche, tiefe Töne nach unten, nicht nervig."""
    sec = 0.3
    n = int(SR * sec)
    out = np.zeros(n)
    for f, at, tau in ((F4, 0.0, 0.08), (D4, 0.1, 0.12)):
        m = int(SR * 0.2)
        tb = np.arange(m) / SR
        note = (np.sin(2 * np.pi * f * tb) + 0.1 * np.sin(2 * np.pi * 3 * f * tb)) * env_exp(m, tau, 0.004)
        place(out, note, at, 0.5)
    return lp(out, 1500)


# ---------- Welt: world/ ----------
def grains_circular(n, rng, count, lo, hi, dur=(0.003, 0.008), amp=(0.1, 0.3)):
    """Wie grains(), aber über die Loop-Naht hinweg verteilt."""
    out = np.zeros(n)
    for _ in range(count):
        m = int(SR * rng.uniform(*dur))
        g = bp(rng.normal(size=m + 64), lo, hi)[64:] * np.hanning(m)
        place_circular(out, g, rng.uniform(0, n / SR), rng.uniform(*amp))
    return out


def pan(x, position):
    """Mono -> Stereo mit gleicher Lautstärke: -1 links, 0 Mitte, +1 rechts."""
    angle = (position + 1) * np.pi / 4
    return np.stack([x * np.cos(angle), x * np.sin(angle)], axis=1)


def stereo_bed(n, rng, tilt, lo, hi, width=0.5):
    """Breites, nahtloses Rauschen: ein gemeinsamer Anteil + je Seite ein eigener."""
    common = periodic_noise(n, rng, tilt, lo, hi)
    left = periodic_noise(n, rng, tilt, lo, hi)
    right = periodic_noise(n, rng, tilt, lo, hi)
    return np.stack([(1 - width) * common + width * left, (1 - width) * common + width * right], axis=1)


def gusts(n, rng, depth=0.6):
    """Langsame Windböen, exakt periodisch über die Loop-Länge."""
    t = np.arange(n) / n
    g = sum(rng.uniform(0.3, 1.0) * np.sin(2 * np.pi * k * t + rng.uniform(0, 6)) for k in (1, 2, 3, 5))
    g = (g - g.min()) / (g.max() - g.min())
    return (1 - depth) + depth * g


def cricket(n, rng, interval, carrier, pulses=3):
    """Grille: kurze Zirp-Gruppen in festem Takt, weich gefiltert (keine schrillen Höhen)."""
    out = np.zeros(n)
    m = int(SR * 0.018)
    tb = np.arange(m) / SR
    pulse = np.sin(2 * np.pi * carrier * tb) * np.hanning(m)
    phrase = np.zeros(int(SR * 0.03) * pulses + m)
    for k in range(pulses):
        phrase[int(SR * 0.03) * k:int(SR * 0.03) * k + m] += pulse
    for k in range(int(n / SR / interval)):
        place_circular(out, phrase, k * interval + rng.uniform(-0.03, 0.03), rng.uniform(0.6, 1.0))
    # Grillen machen Pausen: langsames, periodisches Ein- und Ausblenden
    t = np.arange(n) / n
    swell = np.clip(1.4 * (0.5 + 0.5 * np.sin(2 * np.pi * 2 * t + rng.uniform(0, 6))), 0, 1)
    return lp_circular(out * swell, 5500)


def owl_call(rng, pitch=1.0):
    """Ferner Waldkauz: „huu ... hu-huuu“, tief und weich."""
    out = np.zeros(int(SR * 2.0))
    for at, dur, f0 in ((0.0, 0.45, 410), (0.95, 0.12, 380), (1.15, 0.6, 400)):
        m = int(SR * dur)
        tb = np.arange(m) / SR
        f = f0 * pitch * (1 + 0.04 * np.sin(np.pi * tb / dur)) * (1 + 0.006 * np.sin(2 * np.pi * 6 * tb))
        note = osc(f) * np.sin(np.pi * np.clip(tb / dur, 0, 1)) ** 0.7
        place(out, note, at)
    return lp(out, 1200)


def creak(rng, dur):
    """Ast knarzt: langsamer werdende Pulsfolge, mittig gefiltert."""
    m = int(SR * dur)
    rate = np.linspace(rng.uniform(30, 45), rng.uniform(18, 26), m)
    phase = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(phase), prepend=0) > 0).astype(float)
    body = bp(pulses + 0.05 * rng.normal(size=m), 300, 1200)
    return body * np.sin(np.pi * np.arange(m) / m)


def night_ambience_loop(rng):
    """Nacht im Garten: leiser Wind, Grillen, ab und zu ein fernes Käuzchen. 32 s, stereo, nahtlos."""
    sec = 32.0
    n = int(SR * sec)
    out = 0.35 * stereo_bed(n, rng, -1.0, 60, 900) * gusts(n, rng)[:, None]
    for interval, carrier, side in ((1.1, 3900, -0.6), (0.85, 4300, 0.55), (1.35, 3700, 0.1)):
        out += 0.05 * pan(cricket(n, rng, interval, carrier), side)
    for at, side, pitch in ((9.0, -0.45, 1.0), (23.5, 0.5, 0.96)):
        call = np.zeros(n)
        place_circular(call, owl_call(rng, pitch), at)
        out += 0.12 * pan(call, side)
    for ch in range(2):
        out[:, ch] = add_reverb(lp_circular(out[:, ch], 6000), rng, wet=0.25, sec=1.5, decay=0.5,
                                bright=3000, circular=True)
    return out


def forest_ambience_loop(rng):
    """Nacht im Wald: dichter, Blätter, knarzende Äste, mehr Tiere, etwas unheimlicher. 32 s, stereo."""
    sec = 32.0
    n = int(SR * sec)
    g = gusts(n, rng, 0.75)[:, None]
    out = 0.3 * stereo_bed(n, rng, -1.0, 60, 800) * g
    out += 0.16 * stereo_bed(n, rng, -0.5, 900, 5000, width=0.8) * g ** 2
    out += 0.04 * pan(cricket(n, rng, 1.25, 3600), 0.4)
    for at, side, pitch in ((4.0, 0.6, 1.02), (15.5, -0.5, 0.95), (27.0, 0.2, 1.0)):
        call = np.zeros(n)
        place_circular(call, owl_call(rng, pitch), at)
        out += 0.1 * pan(call, side)
    for at in rng.uniform(0, sec, 3):
        c = np.zeros(n)
        place_circular(c, creak(rng, rng.uniform(0.4, 0.8)), at)
        out += 0.08 * pan(c, rng.uniform(-0.8, 0.8))
    for at in rng.uniform(0, sec, 6):  # kleine Tiere im Laub
        m = int(SR * rng.uniform(0.15, 0.4))
        r = bp(rng.normal(size=m), 2000, 6000) * wobble(m, rng, 40, 0.8) * np.hanning(m)
        c = np.zeros(n)
        place_circular(c, r, at)
        out += 0.08 * pan(c, rng.uniform(-0.9, 0.9))
    t = np.arange(n) / SR
    drone = (np.sin(2 * np.pi * round(D2 * sec) / sec * t) + 0.6 * np.sin(2 * np.pi * round(A2 * sec) / sec * t))
    drone *= 0.5 + 0.5 * np.sin(2 * np.pi * t / sec)
    out += 0.04 * pan(drone, 0.0)
    for ch in range(2):
        out[:, ch] = add_reverb(lp_circular(out[:, ch], 6000), rng, wet=0.3, sec=1.8, decay=0.6,
                                bright=3000, circular=True)
    return out


def shelter_ambience_loop(rng):
    """Im hohlen Baum: gedämpftes Ofen-Knistern, Raumklang, Wind draußen. 24 s, stereo."""
    sec = 24.0
    n = int(SR * sec)
    out = 0.22 * stereo_bed(n, rng, -1.0, 30, 250, width=0.3)
    out += 0.15 * stereo_bed(n, rng, -1.0, 60, 300) * gusts(n, rng, 0.8)[:, None]
    fire = 0.2 * periodic_noise(n, rng, -1.0, 40, 350) * norm(lp_circular(np.abs(rng.normal(size=n)), 6)) \
        + grains_circular(n, rng, int(sec * 3), 900, 3500, amp=(0.08, 0.22)) \
        + grains_circular(n, rng, 6, 300, 1500, dur=(0.01, 0.02), amp=(0.2, 0.35))
    out += pan(lp_circular(fire, 3000), -0.35)
    c = np.zeros(n)
    place_circular(c, creak(rng, 0.6), rng.uniform(0, sec))
    out += 0.06 * pan(c, 0.5)
    for ch in range(2):
        out[:, ch] = add_reverb(out[:, ch], rng, wet=0.2, sec=0.6, decay=0.15, bright=2500, circular=True)
    return out


def campfire_loop(rng):
    """Hexenfeuer: knisternd, warm. 6 s, mono, nahtlos."""
    sec = 6.0
    n = int(SR * sec)
    flicker = 0.5 + 0.5 * norm(lp_circular(np.abs(rng.normal(size=n)), 8))
    out = 0.5 * periodic_noise(n, rng, -1.0, 40, 350) * flicker
    out += grains_circular(n, rng, 30, 1000, 4500, amp=(0.1, 0.4))
    out += grains_circular(n, rng, 4, 300, 1800, dur=(0.012, 0.025), amp=(0.4, 0.6))
    return add_reverb(lp_circular(out, 6000), rng, wet=0.12, sec=0.4, decay=0.1, circular=True)


def fast_forward(rng):
    """Zeitraffer am Feuer beginnt: schneller werdendes Ticken in warmem Rauschen."""
    sec = 1.0
    n = int(SR * sec)
    out = 0.35 * bp(rng.normal(size=n), 300, 2000) * env_swell(n, 0.6, 0.25)
    at, rate = 0.0, 6.0
    while at < 0.85:
        m = int(SR * 0.03)
        tb = np.arange(m) / SR
        tick = np.sin(2 * np.pi * 1800 * tb) * np.exp(-tb / 0.004) + 0.3 * bp(rng.normal(size=m), 1500, 4000) * np.exp(-tb / 0.002)
        place(out, tick, at, 0.25 * min(1.0, 0.4 + at))
        at += 1 / rate
        rate *= 1.18
    out += 0.12 * osc(glide(D3, A3, sec, glide_sec=0.8)) * env_swell(n, 0.5, 0.3)
    return add_reverb(lp(out, 5000), rng, wet=0.15, sec=0.5, decay=0.15)


def sleep_sound(rng):
    """Einschlafen: Stoff raschelt, langes Ausatmen, sanfter tiefer Ton."""
    sec = 2.0
    n = int(SR * sec)
    out = 0.25 * bp(rng.normal(size=n), 800, 4000) * wobble(n, rng, 30, 0.6) * env_swell(n, 0.25, 0.25)
    m = int(SR * 1.2)
    place(out, bp(rng.normal(size=m), 300, 1800) * env_swell(m, 0.35, 0.45), 0.6, 0.3)
    m = int(SR * 1.6)
    place(out, pad((D3, A3), 1.6, rng, attack=0.8, tau=0.6), 0.4, 0.25)
    return add_reverb(lp(out, 4500), rng, wet=0.2, sec=1.0, decay=0.35)


def well_splash(rng):
    """Etwas fällt in den Brunnen: tiefes Platschen, Echo von unten."""
    sec = 1.2
    n = int(SR * sec)
    hit = np.zeros(n)
    place(hit, osc(glide(140, 420, 0.25, glide_sec=0.03)) * env_exp(int(SR * 0.25), 0.06, 0.003), 0.0, 0.7)
    place(hit, burst(int(SR * 0.15), rng, None, 1500, 0.04), 0.0, 0.5)
    out = hit.copy()
    for delay, gain in ((0.14, 0.35), (0.28, 0.15)):
        out += gain * np.roll(lp(hit, 900), int(SR * delay))
    return add_reverb(out, rng, wet=0.35, sec=1.0, decay=0.35, bright=1500)


def page_pickup(rng):
    """Lose Buchseite aufheben: Papierrascheln und ein leiser Glockenton."""
    sec = 0.8
    n = int(SR * sec)
    out = 0.4 * bp(rng.normal(size=n), 1200, 7000) * wobble(n, rng, 300, 0.8) * env_swell(n, 0.12, 0.1)
    place(out, bell(D6, 0.6, rng, tau=0.3), 0.15, 0.25)
    place(out, bell(A6, 0.5, rng, tau=0.25), 0.22, 0.1)
    return add_reverb(lp(out, 7000), rng, wet=0.2, sec=0.6, decay=0.2)


def book_pickup(rng):
    """Das Buch der alten Hexe nehmen: schweres Buch, Staub, ein geheimnisvoller Akkord."""
    sec = 1.6
    n = int(SR * sec)
    out = np.zeros(n)
    place(out, thump(90, 60, 0.3, 0.08), 0.0, 0.6)
    place(out, burst(int(SR * 0.2), rng, None, 400, 0.05), 0.0, 0.4)
    out += 0.04 * hp(rng.normal(size=n), 3000) * env_swell(n, 0.1, 0.3)
    out += 0.4 * pad((D4, F4, A4, 523.25, E5), sec, rng, attack=0.3, tau=0.6)
    place(out, bell(A5, 1.0, rng, tau=0.45), 0.25, 0.15)
    return add_reverb(lp(out, 6500), rng, wet=0.3, sec=1.5, decay=0.6)


def travel(rng):
    """Ortswechsel beim Abblenden: weicher Luftzug."""
    sec = 1.0
    n = int(SR * sec)
    t = t_axis(sec)
    noise = rng.normal(size=n)
    bright = np.sin(np.pi * np.clip(t / 0.8, 0, 1))
    out = (lp(noise, 500) + 0.4 * bp(noise, 800, 3000) * bright) * env_swell(n, 0.45, 0.25)
    return add_reverb(out, rng, wet=0.15, sec=0.6, decay=0.2)


# ID -> (Funktion, Loop?, Lautheit relativ in dB, max. Länge in s)
EFFECTS = {}


def _add(name, fn, loop=False, level=0.0, max_sec=None):
    EFFECTS[name] = (fn, loop, level, max_sec)


# Proben (feste Seeds aus der ersten Runde, damit sie gleich klingen)
SEEDS = {"player/snap": 1000, "player/step_soil_1": 1001, "brewing/cauldron_loop": 1002}

_add("player/snap", snap)
_add("player/step_soil_1", lambda r: step_soil(r, 1), level=-4)
for v in (2, 3, 4):
    _add(f"player/step_soil_{v}", lambda r, v=v: step_soil(r, v), level=-4)
for v in (1, 2, 3, 4):
    _add(f"player/step_grass_{v}", lambda r, v=v: step_grass(r, v), level=-5)
    _add(f"player/step_path_{v}", lambda r, v=v: step_path(r, v), level=-4)
    _add(f"player/step_stone_{v}", lambda r, v=v: step_stone(r, v), level=-5)
_add("player/float_start", float_start)
_add("player/float_loop", float_loop, loop=True, level=-10)

_add("garden/bed_wake", bed_wake, max_sec=1.3)
_add("garden/bed_sleep", bed_sleep, level=-2)
_add("garden/plant_seed", plant_seed, level=-2)
for v in (1, 2, 3):
    _add(f"garden/harvest_{v}", lambda r, v=v: harvest(r, v))
_add("garden/grow_magic", grow_magic, max_sec=1.4)
_add("garden/pour", pour, max_sec=1.5)
_add("garden/pour_sludge", pour_sludge, level=-1, max_sec=1.4)
_add("garden/nightshade_loop", nightshade_loop, loop=True, level=-10)

_add("brewing/cauldron_loop", cauldron_loop, loop=True, level=-4)
_add("brewing/ingredient_drop", ingredient_drop)
_add("brewing/brew_start", brew_start, max_sec=1.9)
_add("brewing/potion_take", potion_take, level=1, max_sec=0.9)
_add("brewing/drink", drink)
_add("brewing/wisp_appear", wisp_appear, max_sec=1.6)
_add("brewing/moonlight", moonlight, level=1, max_sec=2.3)
_add("brewing/endless_night", endless_night, level=1, max_sec=2.8)

_add("ui/click", ui_click, level=-5)
_add("ui/hover", ui_hover, level=-13)
_add("ui/open", ui_open, level=-4, max_sec=0.45)
_add("ui/close", ui_close, level=-6, max_sec=0.45)
_add("ui/page_turn", ui_page_turn, level=-4)
_add("ui/item_pick", ui_item_pick, level=-6)
_add("ui/item_drop", ui_item_drop, level=-6)
_add("ui/item_get", ui_item_get, level=-2, max_sec=0.55)
_add("ui/denied", ui_denied, level=-4)

_add("world/night_ambience_loop", night_ambience_loop, loop=True, level=-6)
_add("world/forest_ambience_loop", forest_ambience_loop, loop=True, level=-6)
_add("world/shelter_ambience_loop", shelter_ambience_loop, loop=True, level=-7)
_add("world/campfire_loop", campfire_loop, loop=True, level=-6)
_add("world/fast_forward", fast_forward, level=-2, max_sec=1.4)
_add("world/sleep", sleep_sound, max_sec=2.6)
_add("world/well_splash", well_splash, max_sec=1.4)
_add("world/page_pickup", page_pickup, max_sec=1.0)
_add("world/book_pickup", book_pickup, level=1, max_sec=2.2)
_add("world/travel", travel, level=-4, max_sec=1.3)


def build(name):
    fn, loop, level, max_sec = EFFECTS[name]
    seed = SEEDS.get(name, zlib.crc32(name.encode()))
    x = finish(fn(np.random.default_rng(seed)), level=level, loop=loop, max_sec=max_sec)
    path = OUT / f"{name}.wav"
    path.parent.mkdir(parents=True, exist_ok=True)
    wavfile.write(path, SR, (x * 32767).astype(np.int16))
    print(f"{name}.wav  {len(x) / SR:.2f} s{'  (Loop)' if loop else ''}")
    return x, loop


def write_preview(clips):
    """Alle Effekte nacheinander mit kurzer Pause. Kurze Loops laufen zweimal,
    lange Atmos nur 12 s lang (ausgeblendet). Die Vorschau ist stereo."""
    gap = np.zeros((int(SR * 0.45), 2))
    parts = []
    for x, loop in clips:
        x = np.stack([x, x], axis=1) if x.ndim == 1 else x
        if loop and len(x) < 8 * SR:
            x = np.concatenate([x, x])
        elif loop:
            x = x[: 12 * SR].copy()
            x[-SR:] *= np.linspace(1, 0, SR)[:, None]
        parts += [x, gap]
    tmp = PREVIEW.with_suffix(".wav")
    wavfile.write(tmp, SR, (np.concatenate(parts) * 32767).astype(np.int16))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", "5", str(PREVIEW)],
                   check=True)
    tmp.unlink()
    print(f"Vorschau: {PREVIEW.relative_to(ROOT)}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    clips = [build(name) for name in EFFECTS if not args or any(a in name for a in args)]
    if "--preview" in sys.argv:
        write_preview(clips)
