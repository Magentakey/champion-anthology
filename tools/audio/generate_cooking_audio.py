"""SFX Level 4 (Cooking Champion), sintetis tanpa file eksternal.

Pakai:  python tools/audio/generate_cooking_audio.py   (butuh numpy)
Hasil di assets/audio/: chop, sizzle, bubble, burn. Hanya 4 file ini yang ditulis,
suara lain tidak berubah. Atur level volume lewat normalize(..., peak).
"""
import numpy as np

import generate_fight_audio as g
from generate_fight_audio import SR, t_axis, env_exp, noise, lowpass, highpass, sweep, normalize, save

np.random.seed(11)   # hasil sama tiap dijalankan


def chop():
    """Ketukan pisau di talenan kayu: benturan kayu pendek + sedikit desis."""
    n = int(0.13 * SR)
    t = t_axis(0.13)
    knock = np.sin(2 * np.pi * 190 * t) * env_exp(n, 55)
    wood = (lowpass(noise(n), 3200) - lowpass(noise(n), 900)) * env_exp(n, 90)
    tick = highpass(noise(n), 3500) * env_exp(n, 160) * 0.35
    return normalize(knock * 0.9 + wood * 1.3 + tick, 0.75)


def sizzle():
    """Desis minyak: derau frekuensi tinggi dengan letupan acak, mengecil perlahan."""
    dur = 0.9
    n = int(dur * SR)
    t = t_axis(dur)
    hiss = highpass(lowpass(noise(n), 9000), 2500) * env_exp(n, 2.2, attack=0.01)
    pops = np.zeros(n)
    for _ in range(26):
        i = np.random.randint(0, int(n * 0.85))
        k = int(0.012 * SR)
        pops[i:i + k] += np.random.uniform(0.4, 1.0) * np.sin(2 * np.pi * np.random.uniform(1800, 4200) * t_axis(0.012)[:k]) \
            * np.exp(-np.linspace(0, 7, k))
    return normalize(hiss * 0.8 + pops * 0.9, 0.7)


def bubble():
    """Air mendidih: beberapa gelembung (sinus naik cepat) bertumpuk."""
    dur = 0.7
    n = int(dur * SR)
    out = np.zeros(n)
    for _ in range(9):
        f0 = np.random.uniform(250, 520)
        d = np.random.uniform(0.05, 0.11)
        k = int(d * SR)
        i = np.random.randint(0, n - k)
        out[i:i + k] += sweep(f0, f0 * 2.1, d) * env_exp(k, 22) * np.random.uniform(0.5, 1.0)
    out += lowpass(noise(n), 500) * 0.25 * env_exp(n, 3)
    return normalize(out, 0.7)


def burn():
    """Gagal/gosong: nada turun sedih + desis singkat."""
    dur = 0.6
    n = int(dur * SR)
    t = t_axis(dur)
    down = sweep(420, 130, dur) * env_exp(n, 3.2)
    wob = np.sin(2 * np.pi * 7 * t) * 0.25 + 0.75
    hiss = highpass(noise(n), 3000) * env_exp(n, 7) * 0.35
    return normalize(down * wob + hiss, 0.75)


def main():
    for name, data in {'chop.wav': chop(), 'sizzle.wav': sizzle(), 'bubble.wav': bubble(), 'burn.wav': burn()}.items():
        save(name, data)


if __name__ == '__main__':
    main()
