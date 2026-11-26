"""SFX Level 8 (Mira the Memory Keeper), sintetis tanpa file eksternal, tanpa sampel atau lagu luar.

Pakai:  python tools/audio/generate_memory_audio.py   (butuh numpy)
Hasil di assets/audio/:
  memory_note_0.wav .. memory_note_8.wav  sembilan nada pad (pentatonik C: C4 D4 E4 G4 A4 C5 D5 E5 G5), 0,35 dtk,
                                           sinus dengan sedikit harmoni dan fade out
  memory_wrong.wav                        dengung turun saat salah atau waktu habis
  memory_clear.wav                        arpeggio naik pendek saat satu ronde selesai
  memory_win.wav, memory_lose.wav         penutup saat step menang atau gagal
Tidak ada musik latar di level ini supaya nada pad tidak terganggu.
Frekuensi harus sama dengan `memoryPadFrequencies` di lib/levels/memory/memory_stage.dart.
Hanya 13 file ini yang ditulis, suara lain tidak berubah.
"""
import numpy as np

import generate_fight_audio as fa
from generate_fight_audio import env_exp, normalize, save

SR = 22050

# frekuensi tiap pad (Hz); sama dengan memoryPadFrequencies di Dart
PAD_FREQS = [262, 294, 330, 392, 440, 523, 587, 659, 784]


def t_axis(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def tone(freq, dur, decay=6.0, harmonics=(1.0, 0.25, 0.08)):
    """Satu nada: sinus dan harmoninya dengan amplop meluruh."""
    n = int(dur * SR)
    t = t_axis(dur)
    wave = np.zeros(n)
    for k, amp in enumerate(harmonics, start=1):
        wave += amp * np.sin(2 * np.pi * freq * k * t)
    return wave * env_exp(n, decay, attack=0.004, sr=SR)


def pad_note(index):
    """Nada pad ke-[index]: 0,35 dtk, fade out halus."""
    x = tone(PAD_FREQS[index], 0.35, decay=7.0)
    return normalize(x, 0.7)


def wrong():
    """Salah: dengung rendah yang turun, sedikit kasar."""
    dur = 0.45
    n = int(dur * SR)
    t = t_axis(dur)
    low = fa.sweep(220, 110, dur, sr=SR, curve='lin')
    saw = (2 * ((t * 130) % 1.0) - 1) * 0.3
    rough = np.sign(np.sin(2 * np.pi * 30 * t)) * 0.2 + 0.8
    env = np.minimum(1.0, t / 0.01) * np.minimum(1.0, (dur - t) / 0.15)
    return normalize((low + saw) * rough * env, 0.55)


def clear():
    """Ronde bersih: arpeggio naik pendek (empat nada)."""
    dur = 0.6
    out = np.zeros(int(dur * SR))
    for i, f in enumerate((523, 659, 784, 1047)):
        x = tone(f, 0.32, decay=7.5)
        start = int(i * 0.1 * SR)
        out[start:start + len(x)] += x[:len(out) - start]
    return normalize(out, 0.6)


def win():
    """Step menang: arpeggio naik lalu akord panjang."""
    dur = 1.1
    out = np.zeros(int(dur * SR))
    for i, f in enumerate((523, 659, 784, 1047)):
        x = tone(f, 0.4, decay=6.0)
        start = int(i * 0.11 * SR)
        out[start:start + len(x)] += x[:len(out) - start]
    chord_start = int(0.5 * SR)
    for f in (523, 659, 784, 1047):
        x = tone(f, 0.6, decay=3.5) * 0.5
        out[chord_start:chord_start + len(x)] += x[:len(out) - chord_start]
    return normalize(out, 0.65)


def lose():
    """Step gagal: tiga nada turun yang suram."""
    dur = 0.95
    out = np.zeros(int(dur * SR))
    for i, f in enumerate((392, 330, 262)):
        x = tone(f, 0.5, decay=4.5, harmonics=(1.0, 0.4, 0.2))
        start = int(i * 0.2 * SR)
        out[start:start + len(x)] += x[:len(out) - start]
    return normalize(out, 0.6)


def main():
    for i in range(9):
        save(f'memory_note_{i}.wav', pad_note(i), sr=SR)
    save('memory_wrong.wav', wrong(), sr=SR)
    save('memory_clear.wav', clear(), sr=SR)
    save('memory_win.wav', win(), sr=SR)
    save('memory_lose.wav', lose(), sr=SR)


if __name__ == '__main__':
    main()
