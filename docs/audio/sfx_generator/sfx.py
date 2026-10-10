"""Soundeffekte für Bitterbloom, komplett per Synthese erzeugt (numpy/scipy).

Aufruf (aus dem Projektordner):
    python docs/audio/sfx_generator/sfx.py            # alle Effekte
    python docs/audio/sfx_generator/sfx.py snap       # nur einzelne

Regeln aus docs/prompts/sound_auftrag_effekte.md: weich, gläsern, nah,
tonale Effekte in D-dorisch, WAV 44,1 kHz / 16 Bit / mono, Spitze -3 dBFS,
Loops nahtlos (Rauschen und Hall werden zirkulär berechnet).
"""
import sys
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt, sosfiltfilt

SR = 44100
ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets" / "audio" / "sfx"
D4, D5, A5, D6 = 293.66, 587.33, 880.0, 1174.66


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


def finish(x, peak_db=-3.0, fade_ms=8, loop=False):
    x = x - np.mean(x)
    if not loop:
        f = int(SR * fade_ms / 1000)
        x[-f:] *= np.linspace(1, 0, f) ** 2
        # Start sofort beim ersten Sample (keine Stille vorne)
        idx = np.argmax(np.abs(x) > 1e-4)
        x = x[idx:]
    x = x / (np.max(np.abs(x)) + 1e-9) * 10 ** (peak_db / 20)
    return x


def save(rel, x, loop=False):
    path = OUT / f"{rel}.wav"
    path.parent.mkdir(parents=True, exist_ok=True)
    wavfile.write(path, SR, (finish(x, loop=loop) * 32767).astype(np.int16))
    print(f"{rel}.wav  {len(x) / SR:.2f} s{'  (Loop)' if loop else ''}")


# ---------- Effekte ----------
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
    # leichtes Glitzern: winzige hohe Körner, schnell weg
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
    # Ferse: tiefer, kurzer Druck mit fallender Tonhöhe
    f = (95 + 60 * np.exp(-t / 0.02)) * pitch
    thump = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, 0.035, attack=0.003)
    # Erde: gedämpftes Rauschen, zwei kleine Phasen (Ferse, Ballen)
    soil = lp(rng.normal(size=n), 900 * pitch, order=3)
    e = env_exp(n, 0.04, attack=0.004)
    roll = int(SR * rng.uniform(0.05, 0.07))
    e[roll:] += 0.55 * env_exp(n - roll, 0.035, attack=0.006)
    soil *= e
    # Krümel: ein paar winzige, weiche Knackser
    crumbs = np.zeros(n)
    for _ in range(rng.integers(4, 8)):
        p = rng.integers(int(0.01 * SR), int(0.18 * SR))
        m = int(SR * 0.006)
        crumbs[p:p + m] += bp(rng.normal(size=m), 1500, 4000) * np.hanning(m) * rng.uniform(0.1, 0.3)
    out = 0.9 * thump + 0.8 * soil + crumbs
    return lp(out, 3500)


def cauldron_loop(rng):
    """Kessel blubbert ruhig: tiefes Köcheln + einzelne zähe Blasen. 5 s, nahtlos."""
    sec = 5.0
    n = int(SR * sec)
    # Köcheln: tiefes, periodisches Rauschen mit langsamem Atmen
    simmer = periodic_noise(n, rng, tilt=-1.0, lo=30, hi=400)
    breathe = 1 + 0.25 * np.sin(2 * np.pi * np.arange(n) / n * 2)  # 2 Atemzüge pro Loop
    out = 0.35 * simmer * breathe
    # Blasen: Ton mit steigender Tonhöhe (wie echte Blasen), zirkulär platziert
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


EFFECTS = {
    "player/snap": (snap, False),
    "player/step_soil_1": (lambda r: step_soil(r, 1), False),
    "brewing/cauldron_loop": (cauldron_loop, True),
}


if __name__ == "__main__":
    wanted = sys.argv[1:]
    for i, (name, (fn, loop)) in enumerate(EFFECTS.items()):
        if wanted and not any(w in name for w in wanted):
            continue
        save(name, fn(np.random.default_rng(1000 + i)), loop=loop)
