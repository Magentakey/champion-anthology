"""SFX Level 5 (Bima the Shooter), sintetis tanpa file eksternal.

Pakai:  python tools/audio/generate_archery_audio.py   (butuh numpy)
Hasil di assets/audio/: bow_draw, arrow_shoot, arrow_hit, bullseye. Hanya 4 file ini yang ditulis.
"""
import numpy as np

from generate_fight_audio import SR, t_axis, env_exp, noise, lowpass, highpass, sweep, normalize, save

np.random.seed(23)   # hasil sama tiap dijalankan


def bow_draw():
    """Busur ditarik: derit kayu yang naik pelan dengan getaran."""
    dur = 0.9
    n = int(dur * SR)
    t = t_axis(dur)
    creak = sweep(110, 250, dur) * (0.75 + 0.25 * np.sin(2 * np.pi * 14 * t))
    grain = lowpass(noise(n), 900) * 0.35
    env = np.minimum(1.0, t / 0.12) * np.minimum(1.0, (dur - t) / 0.2)
    return normalize((creak + grain) * env, 0.5)


def arrow_shoot():
    """Anak panah dilepas: dentang tali pendek, lalu desing yang menjauh."""
    dur = 0.32
    n = int(dur * SR)
    t = t_axis(dur)
    twang = np.sin(2 * np.pi * 230 * t) * env_exp(n, 22) * 0.8
    whoosh = highpass(lowpass(noise(n), 5200), 900) * env_exp(n, 9) * (1 - 0.6 * t / dur)
    return normalize(twang + whoosh * 0.9, 0.7)


def arrow_hit():
    """Anak panah menancap di papan: bunyi tuk pendek."""
    dur = 0.2
    n = int(dur * SR)
    t = t_axis(dur)
    thunk = np.sin(2 * np.pi * 150 * t) * env_exp(n, 30)
    click = highpass(noise(n), 1800) * env_exp(n, 120) * 0.45
    return normalize(thunk + click, 0.75)


def bullseye():
    """Kena emas: denting cerah dua nada."""
    dur = 0.55
    n = int(dur * SR)
    t = t_axis(dur)
    a = np.sin(2 * np.pi * 1175 * t) * env_exp(n, 6)
    b = np.sin(2 * np.pi * 1760 * t) * env_exp(n, 8) * 0.6
    shimmer = np.sin(2 * np.pi * 2349 * t) * env_exp(n, 14) * 0.3
    return normalize(a + b + shimmer, 0.65)


def main():
    for name, data in {'bow_draw.wav': bow_draw(), 'arrow_shoot.wav': arrow_shoot(),
                       'arrow_hit.wav': arrow_hit(), 'bullseye.wav': bullseye()}.items():
        save(name, data)


if __name__ == '__main__':
    main()
