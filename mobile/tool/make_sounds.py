"""Synthesises the game's sound effects into assets/sounds/*.wav.

The web version builds these live with Web Audio; the app ships them as small
WAV files made by this script with the same recipes. Re-run it after changing
a recipe:  python3 tool/make_sounds.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
random.seed(42)


def blank(seconds):
    return [0.0] * int(RATE * seconds)


def add(buf, samples, at):
    start = int(at * RATE)
    for i, s in enumerate(samples):
        if start + i < len(buf):
            buf[start + i] += s


def exp_env(n, start, end=0.001):
    return [start * (end / start) ** (i / max(1, n - 1)) for i in range(n)]


def bandpass(samples, freq, q):
    # RBJ biquad band-pass, as used by Web Audio's BiquadFilterNode.
    w0 = 2 * math.pi * freq / RATE
    alpha = math.sin(w0) / (2 * q)
    b0, b1, b2 = alpha, 0, -alpha
    a0, a1, a2 = 1 + alpha, -2 * math.cos(w0), 1 - alpha
    return biquad(samples, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)


def lowpass(samples, freq, q=0.707):
    w0 = 2 * math.pi * freq / RATE
    alpha = math.sin(w0) / (2 * q)
    c = math.cos(w0)
    b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
    a0, a1, a2 = 1 + alpha, -2 * c, 1 - alpha
    return biquad(samples, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)


def biquad(x, b0, b1, b2, a1, a2):
    y, x1, x2, y1, y2 = [], 0.0, 0.0, 0.0, 0.0
    for s in x:
        o = b0 * s + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, s, y1, o
        y.append(o)
    return y


def noise(seconds):
    return [random.uniform(-1, 1) for _ in range(int(RATE * seconds))]


def osc(freqs, kind="sine"):
    out, phase = [], 0.0
    for f in freqs:
        phase += f / RATE
        p = phase % 1
        if kind == "sine":
            out.append(math.sin(2 * math.pi * p))
        elif kind == "triangle":
            out.append(4 * abs(p - 0.5) - 1)
        elif kind == "sawtooth":
            out.append(2 * p - 1)
    return out


def clack(pitch=1.0):
    n = bandpass(noise(0.06), 1500 * pitch, 4)
    n = [s * e for s, e in zip(n, exp_env(len(n), 0.5))]
    o = osc([820 * pitch] * int(RATE * 0.06))
    env = exp_env(int(RATE * 0.05), 0.18) + [0.0] * int(RATE * 0.01)
    o = [s * e for s, e in zip(o, env)]
    buf = blank(0.07)
    add(buf, n, 0)
    add(buf, o, 0)
    return buf


def rummage():
    buf = blank(0.6)
    for i in range(6):
        add(buf, clack(random.uniform(0.8, 1.25)), i * 0.07 + random.random() * 0.04)
    return buf


def dab():
    n_len = int(RATE * 0.13)
    freqs = [170 * (55 / 170) ** min(1, i / (RATE * 0.09)) for i in range(n_len)]
    o = osc(freqs)
    o = [s * e for s, e in zip(o, exp_env(n_len, 0.45))]
    nz = lowpass(noise(0.05), 900)
    nz = [s * e for s, e in zip(nz, exp_env(len(nz), 0.25))]
    buf = blank(0.14)
    add(buf, o, 0)
    add(buf, nz, 0)
    return buf


def tones(notes, kind="triangle", vol=0.2):
    total = max(at + dur for _, at, dur in notes) + 0.06
    buf = blank(total)
    for freq, at, dur in notes:
        n = int(RATE * (dur + 0.05))
        s = osc([freq] * n, kind)
        attack = int(RATE * 0.02)
        env = [vol * i / attack for i in range(attack)] + exp_env(n - attack, vol)
        add(buf, [a * b for a, b in zip(s, env)], at)
    return buf


SOUNDS = {
    "rummage": rummage,
    "clack": lambda: clack(0.9),
    "dab": dab,
    "win": lambda: tones([[523, 0, 0.3], [659, 0.12, 0.3], [784, 0.24, 0.3], [1047, 0.36, 0.7]]),
    "lose": lambda: tones([[392, 0, 0.25], [330, 0.15, 0.4]], "sine", 0.15),
    "bogey": lambda: tones([[140, 0, 0.5], [110, 0.05, 0.55]], "sawtooth", 0.12),
}


def write(name, samples):
    peak = max(1.0, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(s / peak * 32000)) for s in samples)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        write(name, make())
        print("wrote", name)
