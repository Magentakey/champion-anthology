"""SFX Level 6 (Mr. Lexi the Gambler), sintetis tanpa file eksternal.

Pakai:  python tools/audio/generate_gambler_audio.py   (butuh numpy)
Hasil di assets/audio/: card_flip, coin_toss, cup_slide, win_chime, lose_buzz. Hanya 5 file ini yang ditulis,
suara lain tidak berubah.
"""
import numpy as np

from generate_fight_audio import SR, t_axis, env_exp, noise, lowpass, highpass, sweep, normalize, save


def card_flip():
    """Kartu dibalik: desir kertas pendek lalu ketukan tipis di meja."""
    dur = 0.2
    n = int(dur * SR)
    t = t_axis(dur)
    swish = highpass(lowpass(noise(n), 7000), 1800) * env_exp(n, 22, attack=0.012)
    tap = np.sin(2 * np.pi * 320 * t) * env_exp(n, 70) * 0.35
    tap[:int(0.07 * SR)] *= 0.0
    return normalize(swish + np.roll(tap, int(0.06 * SR)), 0.6)


def coin_toss():
    """Koin dilempar: denting logam yang meluruh, naik sedikit, dengan getaran halus."""
    dur = 0.8
    n = int(dur * SR)
    t = t_axis(dur)
    ring = np.sin(2 * np.pi * 2093 * t) * env_exp(n, 5)
    ring2 = np.sin(2 * np.pi * 3136 * t) * env_exp(n, 7) * 0.5
    wobble = 0.7 + 0.3 * np.sin(2 * np.pi * 22 * t)
    ping = highpass(noise(n), 4000) * env_exp(n, 90) * 0.4
    return normalize((ring + ring2) * wobble + ping, 0.55)


def cup_slide():
    """Cangkir digeser di kain meja: gesekan rendah yang naik lalu turun."""
    dur = 0.34
    n = int(dur * SR)
    t = t_axis(dur)
    scrape = lowpass(noise(n), 1400) * np.sin(np.pi * t / dur) ** 1.5
    thump = np.sin(2 * np.pi * 140 * t) * env_exp(n, 40) * 0.5
    return normalize(scrape + thump * np.minimum(1.0, t / 0.01), 0.55)


def win_chime():
    """Menang: tiga nada naik (do, mi, sol) yang cerah."""
    dur = 0.85
    out = np.zeros(int(dur * SR))
    for i, f in enumerate((784, 988, 1175)):
        seg = int(0.5 * SR)
        t = np.arange(seg) / SR
        tone = (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t)) * env_exp(seg, 5.5)
        start = int(i * 0.12 * SR)
        out[start:start + seg] += tone[:len(out) - start]
    return normalize(out, 0.65)


def lose_buzz():
    """Kalah: dengung rendah yang turun, bergetar kasar."""
    dur = 0.6
    n = int(dur * SR)
    t = t_axis(dur)
    low = sweep(190, 95, dur, curve='lin')
    saw = (2 * ((t * 110) % 1.0) - 1) * 0.35
    rough = np.sign(np.sin(2 * np.pi * 36 * t)) * 0.25 + 0.75
    env = np.minimum(1.0, t / 0.02) * np.minimum(1.0, (dur - t) / 0.18)
    return normalize((low + saw) * rough * env, 0.55)


def main():
    for name, data in {'card_flip.wav': card_flip(), 'coin_toss.wav': coin_toss(), 'cup_slide.wav': cup_slide(),
                       'win_chime.wav': win_chime(), 'lose_buzz.wav': lose_buzz()}.items():
        save(name, data)


if __name__ == '__main__':
    main()
