#!/usr/bin/env python3
"""Efek suara dan BGM Level Fight, disintesis dari nol (tanpa file eksternal).

Jalankan dari root proyek:

    pip install numpy
    python tools/audio/generate_fight_audio.py

Hasilnya ditulis ke assets/audio/ (WAV mono 16-bit). Ganti suara dengan menimpa file bernama sama.
"""
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/audio'
SR = 44100
RNG = np.random.default_rng(7)


# ---------------- alat bantu ----------------
def t_axis(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env_exp(n, decay, attack=0.002, sr=SR):
    """Amplop: naik cepat lalu meluruh eksponensial."""
    t = np.arange(n) / sr
    a = np.minimum(1.0, t / max(attack, 1e-4))
    return a * np.exp(-t * decay)


def noise(n):
    return RNG.uniform(-1, 1, n)


def lowpass(x, cutoff, sr=SR):
    """Low-pass satu kutub, cukup untuk membentuk warna suara."""
    rc = 1.0 / (2 * np.pi * cutoff)
    alpha = (1.0 / sr) / (rc + 1.0 / sr)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def highpass(x, cutoff, sr=SR):
    return x - lowpass(x, cutoff, sr)


def sweep(f0, f1, dur, sr=SR, curve='exp'):
    """Sinus dengan frekuensi meluncur dari f0 ke f1."""
    t = t_axis(dur, sr)
    if curve == 'exp':
        f = f0 * (f1 / f0) ** (t / dur)
    else:
        f = f0 + (f1 - f0) * t / dur
    phase = 2 * np.pi * np.cumsum(f) / sr
    return np.sin(phase)


def normalize(x, peak=0.8):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def pad(x, dur, sr=SR):
    out = np.zeros(int(dur * sr))
    out[:len(x)] = x[:len(out)]
    return out


def save(name, x, sr=SR, fade_ms=12):
    OUT.mkdir(parents=True, exist_ok=True)
    k = min(len(x), int(sr * fade_ms / 1000))
    if k > 0:   # ekor singkat menuju nol agar tidak ada bunyi "klik" di ujung
        x = x.copy()
        x[-k:] *= np.linspace(1, 0, k)
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(str(OUT / name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    print(f'ditulis {name}: {len(x) / sr:.2f} dtk')


# ---------------- efek suara ----------------
def punch():
    n = int(0.16 * SR)
    thump = sweep(150, 55, 0.16) * env_exp(n, 22)
    snap = lowpass(noise(n), 3500) * env_exp(n, 60)
    return normalize(thump * 0.9 + snap * 0.7, 0.85)


def kick():
    n = int(0.24 * SR)
    thump = sweep(120, 40, 0.24) * env_exp(n, 14)
    body = lowpass(noise(n), 1800) * env_exp(n, 25)
    snap = highpass(noise(n), 2500) * env_exp(n, 90) * 0.5
    return normalize(thump * 1.0 + body * 0.6 + snap, 0.9)


def heavy():
    n = int(0.55 * SR)
    boom = sweep(90, 28, 0.55) * env_exp(n, 7)
    crack = lowpass(noise(n), 2500) * env_exp(n, 30)
    rumble = lowpass(noise(n), 300) * env_exp(n, 6)
    return normalize(boom * 1.0 + crack * 0.7 + rumble * 0.6, 0.95)


def block():
    n = int(0.14 * SR)
    t = t_axis(0.14)
    clack = (np.sin(2 * np.pi * 900 * t) + 0.6 * np.sin(2 * np.pi * 1450 * t) + 0.4 * np.sin(2 * np.pi * 2300 * t))
    clack *= env_exp(n, 55)
    tick = highpass(noise(n), 3000) * env_exp(n, 140) * 0.7
    return normalize(clack * 0.6 + tick, 0.7)


def hurt():
    n = int(0.28 * SR)
    t = t_axis(0.28)
    f = 190 - 70 * t / 0.28 + 6 * np.sin(2 * np.pi * 28 * t)
    phase = 2 * np.pi * np.cumsum(f) / SR
    saw = 2 * ((phase / (2 * np.pi)) % 1.0) - 1
    voice = lowpass(saw, 1100) * env_exp(n, 9, attack=0.01)
    breath = lowpass(noise(n), 1800) * env_exp(n, 18) * 0.25
    return normalize(voice + breath, 0.7)


def ko():
    n = int(0.9 * SR)
    fall = sweep(320, 55, 0.9) * env_exp(n, 3.5, attack=0.01)
    thud_n = int(0.4 * SR)
    thud = np.zeros(n)
    start = int(0.45 * SR)
    seg = sweep(95, 30, 0.4) * env_exp(thud_n, 9) + lowpass(noise(thud_n), 500) * env_exp(thud_n, 14) * 0.6
    end = min(n, start + thud_n)
    thud[start:end] = seg[:end - start]
    return normalize(fall * 0.55 + thud * 1.0, 0.95)


def whoosh():
    n = int(0.34 * SR)
    t = np.arange(n) / SR
    base = noise(n)
    # pita lewat yang naik lalu turun: campuran dua low-pass berbeda
    lo = lowpass(base, 700)
    hi = lowpass(base, 4200) - lowpass(base, 1500)
    mix_up = np.sin(np.pi * np.clip(t / 0.34, 0, 1))
    return normalize((lo * (1 - mix_up) + hi * mix_up * 1.6) * np.sin(np.pi * t / 0.34) ** 0.8, 0.7)


def knife_hit():
    n = int(0.16 * SR)
    t = t_axis(0.16)
    ring = np.sin(2 * np.pi * 2400 * t) * env_exp(n, 38) * 0.4
    thunk = sweep(260, 120, 0.16) * env_exp(n, 40)
    tick = highpass(noise(n), 2500) * env_exp(n, 120) * 0.5
    return normalize(ring + thunk * 0.9 + tick, 0.8)


def bell():
    n = int(1.4 * SR)
    t = t_axis(1.4)
    out = np.zeros(n)
    for ratio, amp, dec in ((1.0, 1.0, 3.2), (2.76, 0.6, 4.5), (5.4, 0.35, 6.0), (8.93, 0.2, 8.0)):
        out += amp * np.sin(2 * np.pi * 660 * ratio * t) * np.exp(-t * dec)
    out *= np.minimum(1, t / 0.003)
    return normalize(out, 0.7)


def crowd():
    dur = 1.9
    n = int(dur * SR)
    t = t_axis(dur)
    base = noise(n)
    band = lowpass(base, 2600) - lowpass(base, 350)
    # gemuruh: modulasi lambat acak + amplop naik-turun
    wob = lowpass(noise(n), 12)
    wob = wob / (np.max(np.abs(wob)) or 1)
    swell = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.5
    return normalize(band * (0.6 + 0.4 * wob) * swell, 0.6)


def warning():
    dur = 0.5
    n = int(dur * SR)
    t = t_axis(dur)
    out = np.zeros(n)
    for start, f0, f1 in ((0.0, 420, 780), (0.25, 420, 780)):
        i0 = int(start * SR)
        m = int(0.22 * SR)
        seg = np.sign(sweep(f0, f1, 0.22, curve='lin')) * 0.5 + sweep(f0, f1, 0.22, curve='lin') * 0.5
        seg = lowpass(seg, 2500) * np.sin(np.pi * np.arange(m) / m) ** 0.5
        out[i0:i0 + m] += seg
    return normalize(out, 0.45)


# ---------------- BGM ----------------
BGM_SR = 22050
BPM = 128
BEAT = 60.0 / BPM


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def tone(freq, dur, kind='square', sr=BGM_SR, vol=1.0, rel=0.04):
    n = int(dur * sr)
    t = np.arange(n) / sr
    if kind == 'square':
        x = np.sign(np.sin(2 * np.pi * freq * t)) * 0.6 + np.sin(2 * np.pi * freq * t) * 0.4
    elif kind == 'saw':
        x = 2 * ((freq * t) % 1.0) - 1
    else:
        x = np.sin(2 * np.pi * freq * t)
    a = np.minimum(1, t / 0.005)
    r = np.minimum(1, (dur - t) / rel)
    return x * a * np.clip(r, 0, 1) * vol


def bgm():
    bars = 8
    total = bars * 4 * BEAT
    n = int(total * BGM_SR)
    mix = np.zeros(n)

    def put(x, at):
        i = int(at * BGM_SR)
        j = min(n, i + len(x))
        if i < n:
            mix[i:j] += x[:j - i]

    # drum: kick tiap ketuk, snare di ketukan 2 dan 4, hi-hat tiap 1/8
    kn = int(0.18 * BGM_SR)
    kick_s = sweep(120, 42, 0.18, sr=BGM_SR) * env_exp(kn, 18, sr=BGM_SR)
    sn = int(0.16 * BGM_SR)
    snare_s = (lowpass(noise(sn), 5000, BGM_SR) * env_exp(sn, 28, sr=BGM_SR) * 0.7 +
               sweep(210, 150, 0.16, sr=BGM_SR) * env_exp(sn, 30, sr=BGM_SR) * 0.4)
    hn = int(0.05 * BGM_SR)
    hat_s = highpass(noise(hn), 6000, BGM_SR) * env_exp(hn, 90, sr=BGM_SR) * 0.35
    for bar in range(bars):
        for beat in range(4):
            at = (bar * 4 + beat) * BEAT
            put(kick_s * 0.95, at)
            if beat in (1, 3):
                put(snare_s, at)
            put(hat_s, at)
            put(hat_s * 0.7, at + BEAT / 2)
            if bar % 2 == 1 and beat == 3:  # variasi: tendangan ganda di akhir frasa
                put(kick_s * 0.8, at + BEAT / 2)

    # bass: pola A minor (Am - F - G - Am), delapan-an
    roots = [33, 29, 31, 33]  # A1, F1, G1, A1
    for bar in range(bars):
        root = roots[(bar // 2) % 4]
        for step in range(8):
            at = (bar * 4 + step * 0.5) * BEAT
            note = root + (12 if step in (3, 6) else 0)
            put(tone(midi(note + 12), BEAT * 0.45, 'saw', vol=0.28), at)

    # melodi: arpeggio minor pentatonik, dua frasa bergantian
    scale = [57, 60, 62, 64, 67, 69, 72]  # A3 C4 D4 E4 G4 A4 C5
    phrase_a = [0, 2, 4, 2, 3, 2, 1, 2]
    phrase_b = [4, 5, 6, 5, 4, 3, 2, 1]
    for bar in range(bars):
        phrase = phrase_a if (bar // 2) % 2 == 0 else phrase_b
        for step in range(8):
            if bar % 4 == 3 and step >= 6:   # jeda napas di akhir tiap 4 bar
                continue
            at = (bar * 4 + step * 0.5) * BEAT
            put(tone(midi(scale[phrase[step]]), BEAT * 0.4, 'square', vol=0.12), at)

    mix = lowpass(mix, 7500, BGM_SR)
    return normalize(mix, 0.7)


def main():
    sfx = {
        'punch.wav': punch(), 'kick.wav': kick(), 'heavy.wav': heavy(), 'block.wav': block(),
        'hurt.wav': hurt(), 'ko.wav': ko(), 'whoosh.wav': whoosh(), 'knife_hit.wav': knife_hit(),
        'bell.wav': bell(), 'crowd.wav': crowd(), 'warning.wav': warning(),
    }
    for name, data in sfx.items():
        save(name, data)
    save('fight_bgm.wav', bgm(), sr=BGM_SR, fade_ms=0)   # BGM berulang: tanpa fade


if __name__ == '__main__':
    main()
