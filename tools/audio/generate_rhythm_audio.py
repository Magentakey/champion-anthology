"""Musik dan SFX Level 7 (Rhea the Drummer), sintetis tanpa file eksternal, tanpa sampel atau lagu luar.

Pakai:  python tools/audio/generate_rhythm_audio.py   (butuh numpy)
Hasil di assets/audio/:
  rhythm_step1.wav, rhythm_step2.wav, rhythm_step3.wav  lagu pengiring (drum dan bas, tanpa melodi supaya ketukan
                                                         pemain terdengar jelas), mono 22,05 kHz 16-bit
  rhythm_hit_perfect.wav, rhythm_hit_good.wav            bunyi ketukan pendek (nada naik untuk PERFECT)
  rhythm_miss.wav                                        dengung pendek saat MISS
  rhythm_count.wav                                       bunyi hitung mundur
Panjang tiap lagu persis bar x 4 ketukan pada tempo step itu, dan ketukan pertama tepat di sampel pertama,
jadi musik selaras dengan jam permainan yang dimulai bersamaan.
Hanya 7 file ini yang ditulis, suara lain tidak berubah.
"""
import numpy as np

import generate_fight_audio as fa
from generate_fight_audio import env_exp, normalize, save

SR = 22050
RNG = np.random.default_rng(77)

# tempo dan panjang lagu: harus sama dengan lib/levels/rhythm/rhythm_config.dart
SONGS = [(90, 16), (110, 20), (128, 24)]


def t_axis(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def noise(n):
    return RNG.uniform(-1, 1, n)


def lowpass(x, cutoff, sr=SR):
    return fa.lowpass(x, cutoff, sr)


def highpass(x, cutoff, sr=SR):
    return fa.highpass(x, cutoff, sr)


def sweep(f0, f1, dur, sr=SR):
    return fa.sweep(f0, f1, dur, sr=sr)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ---------------- alat drum ----------------
def kick():
    n = int(0.22 * SR)
    return sweep(130, 44, 0.22) * env_exp(n, 16, sr=SR) * 1.0


def snare():
    n = int(0.18 * SR)
    body = sweep(220, 160, 0.18) * env_exp(n, 30, sr=SR) * 0.45
    rattle = lowpass(noise(n), 6000) * env_exp(n, 24, sr=SR) * 0.7
    return body + rattle


def hat(open_=False):
    dur = 0.18 if open_ else 0.05
    n = int(dur * SR)
    return highpass(noise(n), 6000) * env_exp(n, 22 if open_ else 90, sr=SR) * 0.32


def crash():
    n = int(0.9 * SR)
    return highpass(noise(n), 4500) * env_exp(n, 4.5, sr=SR) * 0.4


def bass_note(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * 2 * freq * t)
    a = np.minimum(1, t / 0.004)
    r = np.clip((dur - t) / 0.03, 0, 1)
    return x * a * r * 0.5


class Track:
    """Kanvas lagu: menempatkan bunyi pada waktu tertentu (detik) dan memotong di akhir lagu."""

    def __init__(self, seconds):
        self.n = int(round(seconds * SR))
        self.mix = np.zeros(self.n)

    def put(self, x, at):
        i = int(round(at * SR))
        if i >= self.n:
            return
        j = min(self.n, i + len(x))
        self.mix[i:j] += x[:j - i]


def song(step, bpm, bars):
    beat = 60.0 / bpm
    seconds = bars * 4 * beat
    tr = Track(seconds)
    k, s, h, ho = kick(), snare(), hat(), hat(True)
    roots = [33, 29, 31, 33]  # A1, F1, G1, A1

    for bar in range(bars):
        b0 = bar * 4 * beat
        phrase_end = bar % 4 == 3
        for beat_i in range(4):
            at = b0 + beat_i * beat
            if step == 1:
                # groove sederhana: kick tiap ketuk, snare ketukan 2 dan 4, hi-hat delapan-an
                tr.put(k * 0.95, at)
                if beat_i in (1, 3):
                    tr.put(s, at)
                tr.put(h, at)
                tr.put(h * 0.7, at + beat / 2)
            elif step == 2:
                # beat jalanan: kick bersinkopasi, snare 2 dan 4 dengan not hantu, hi-hat terbuka di off-beat
                if beat_i in (0, 2):
                    tr.put(k * 0.95, at)
                if beat_i == 1:
                    tr.put(k * 0.8, at + beat / 2)
                if beat_i == 3 and bar % 2 == 1:
                    tr.put(k * 0.8, at + beat / 2)
                if beat_i in (1, 3):
                    tr.put(s, at)
                else:
                    tr.put(s * 0.18, at + beat * 0.75)
                tr.put(h, at)
                tr.put(ho * 0.8 if beat_i % 2 == 1 else h * 0.7, at + beat / 2)
            else:
                # lagu penutup: kick tiap ketuk, snare 2 dan 4, hi-hat enam belasan, dentuman tom di akhir frasa
                tr.put(k, at)
                if beat_i in (1, 3):
                    tr.put(s * 1.05, at)
                for q in range(4):
                    tr.put(h * (0.9 if q == 0 else 0.55), at + q * beat / 4)
                if phrase_end and beat_i == 3:
                    for q in range(4):
                        tr.put(s * 0.7, at + q * beat / 4)

        # bass: pola A minor (Am - F - G - Am), berubah tiap dua bar
        root = roots[(bar // 2) % 4]
        if step == 1:
            for beat_i in range(4):
                tr.put(bass_note(midi(root + 12), beat * 0.8), b0 + beat_i * beat)
        elif step == 2:
            for q in range(8):
                note = root + 12 + (7 if q in (3, 6) else 0)
                tr.put(bass_note(midi(note), beat * 0.42), b0 + q * beat / 2)
        else:
            for q in range(16):
                if q % 4 == 3:
                    continue
                note = root + 12 + (12 if q % 8 == 6 else 0)
                tr.put(bass_note(midi(note), beat * 0.2), b0 + q * beat / 4)

    # pembuka dan penutup lagu: simbal di ketukan pertama dan di awal tiap 8 bar
    for bar in range(0, bars, 8):
        tr.put(crash(), bar * 4 * beat)
    tr.put(crash() * 0.8, (bars - 1) * 4 * beat + 3 * beat)

    out = tr.mix
    out = lowpass(out, 9000)
    return normalize(out, 0.7)


# ---------------- SFX ----------------
def hit_perfect():
    dur = 0.16
    n = int(dur * 44100)
    t = fa.t_axis(dur)
    a = np.sin(2 * np.pi * 988 * t) * env_exp(n, 22)
    b = np.sin(2 * np.pi * 1480 * t) * env_exp(n, 30) * 0.5
    tick = highpass(noise(n), 5000, 44100) * env_exp(n, 160) * 0.3
    return normalize(a + b + tick, 0.6)


def hit_good():
    dur = 0.12
    n = int(dur * 44100)
    t = fa.t_axis(dur)
    a = np.sin(2 * np.pi * 523 * t) * env_exp(n, 26)
    tick = highpass(noise(n), 3000, 44100) * env_exp(n, 140) * 0.25
    return normalize(a + tick, 0.5)


def miss():
    dur = 0.2
    n = int(dur * 44100)
    t = fa.t_axis(dur)
    low = fa.sweep(160, 90, dur) * np.minimum(1, t / 0.005)
    rough = np.sign(np.sin(2 * np.pi * 40 * t)) * 0.25 + 0.75
    env = np.minimum(1.0, t / 0.01) * np.clip((dur - t) / 0.08, 0, 1)
    return normalize(low * rough * env, 0.45)


def count():
    dur = 0.1
    n = int(dur * 44100)
    t = fa.t_axis(dur)
    wood = np.sin(2 * np.pi * 880 * t) * env_exp(n, 38, attack=0.001)
    click = highpass(noise(n), 2500, 44100) * env_exp(n, 220) * 0.3
    return normalize(wood + click, 0.55)


def main():
    for i, (bpm, bars) in enumerate(SONGS, start=1):
        save(f'rhythm_step{i}.wav', song(i, bpm, bars), sr=SR, fade_ms=0)
    save('rhythm_hit_perfect.wav', hit_perfect())
    save('rhythm_hit_good.wav', hit_good())
    save('rhythm_miss.wav', miss())
    save('rhythm_count.wav', count())


if __name__ == '__main__':
    main()
