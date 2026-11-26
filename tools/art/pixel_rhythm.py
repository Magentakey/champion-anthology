"""Aset Level 7 (Rhea the Drummer) bergaya piksel: panggung konser malam, not, pad ketuk, dan garis ketuk.

    python tools/art/pixel_rhythm.py [folder_keluaran]
Menulis ke assets/images/rhythm/:
  stage.png (720x1278 = kisi 240x426 x3), note_0..3.png (kisi 20x12 x3 = 60x36),
  pad_0..3.png (120x96 = dua bingkai 20x32 x3 berdampingan: kiri normal, kanan menyala),
  hit_line.png (kisi 240x4 x3 = 720x12).
Bos Rhea (4 ekspresi) dibuat oleh pixel_bosses.py. Tanpa aset luar: semuanya digambar dari kode.
"""
import math
import random
import sys
from pathlib import Path

import pixel_scenes as ps

C = ps.C
OUT = ps.OUT
ROOT = ps.ROOT
SCALE = 3
W, H = 240, 426

# palet bersama
GOLD = C(255, 200, 40)
GOLD_L = C(255, 238, 140)
GOLD_D = C(200, 140, 20)
CREAM = C(255, 244, 214)
STEEL = C(110, 116, 140)
STEEL_D = C(64, 68, 92)
STEEL_L = C(168, 174, 196)

# warna tiap jalur: merah, biru, hijau, emas (sama dengan not dan pad)
LANE = [C(232, 64, 72), C(64, 140, 240), C(84, 200, 100), C(255, 200, 48)]
LANE_L = [C(255, 140, 140), C(150, 200, 255), C(170, 240, 170), C(255, 240, 150)]
LANE_D = [C(150, 30, 48), C(30, 80, 170), C(36, 120, 64), C(200, 140, 20)]
KEYS = ['D', 'F', 'J', 'K']


def outline(sc):
    """Garis tepi gelap 1 piksel di sekeliling bentuk (sprite harus punya sisa 1 piksel di tepi)."""
    filled = {(x, y) for y in range(sc.H) for x in range(sc.W) if sc.g[y][x]}
    for (x, y) in filled:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in filled:
                sc.set(x + dx, y + dy, OUT)
    return sc


def rounded(sc, x0, y0, x1, y1, col):
    """Persegi panjang dengan sudut dipotong 1 piksel."""
    sc.rect(x0, y0, x1, y1, col)
    for (cx, cy) in ((x0, y0), (x1 - 1, y0), (x0, y1 - 1), (x1 - 1, y1 - 1)):
        sc.g[cy][cx] = None


def blend(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3)) + (255,)


# ---------------- not ----------------
def note(lane):
    """Not jatuh: bantalan berbentuk permata pipih dengan kilau, warna sesuai jalur."""
    sc = ps.Scene(20, 12)
    rounded(sc, 1, 1, 19, 11, LANE[lane])
    sc.rect(2, 2, 18, 3, LANE_L[lane])          # kilau atas
    sc.rect(2, 9, 18, 10, LANE_D[lane])         # bayangan bawah
    sc.rect(2, 3, 3, 9, LANE_L[lane])           # kilau kiri
    sc.rect(17, 3, 18, 9, LANE_D[lane])         # bayangan kanan
    # lambang tengah: belah ketupat krem
    sc.poly([(10, 3.5), (13.5, 6), (10, 8.5), (6.5, 6)], CREAM)
    sc.poly([(10, 4.8), (12, 6), (10, 7.2), (8, 6)], LANE[lane])
    return outline(sc)


# ---------------- pad ketuk ----------------
def pad_frame(sc, ox, lane, lit):
    """Satu bingkai pad 20x32 di kolom [ox, ox + 20)."""
    base = LANE[lane]
    dark = C(34, 30, 52)
    rounded(sc, ox + 1, 1, ox + 19, 31, OUT)
    if lit:
        face = LANE_L[lane]
        rim = CREAM
        inner = base
    else:
        face = blend(base, dark, 0.55)
        rim = base
        inner = blend(base, dark, 0.78)
    rounded(sc, ox + 1, 2, ox + 19, 30, rim)
    rounded(sc, ox + 3, 4, ox + 17, 28, face)
    sc.rect(ox + 4, 5, ox + 16, 7, LANE_L[lane] if lit else blend(base, dark, 0.4))     # kilau atas
    sc.rect(ox + 4, 24, ox + 16, 27, inner)                                              # bayangan bawah
    # huruf papan ketik di tengah
    glyph = ps.GLYPH[KEYS[lane]]
    gx, gy = ox + 7, 12
    for j, row in enumerate(glyph):
        for i, c in enumerate(row):
            if c == '#':
                sc.set(gx + i, gy + j, C(40, 30, 60) if lit else LANE_L[lane])
    if lit:                                                                              # percikan di sudut
        for (x, y) in ((ox + 2, 1), (ox + 17, 1), (ox + 2, 30), (ox + 17, 30)):
            ps.star4(sc, x, y, CREAM)


def pad(lane):
    sc = ps.Scene(40, 32)
    pad_frame(sc, 0, lane, False)
    pad_frame(sc, 20, lane, True)
    return sc


# ---------------- garis ketuk ----------------
def hit_line():
    sc = ps.Scene(240, 4)
    for x in range(240):
        sc.set(x, 0, C(255, 214, 64) if False else (255, 214, 64, 150))
        sc.set(x, 1, CREAM)
        sc.set(x, 2, CREAM)
        sc.set(x, 3, (255, 214, 64, 150))
    for x in range(6, 240, 12):                     # titik terang berkala
        sc.set(x, 1, GOLD_L)
        sc.set(x, 2, GOLD_L)
    for x in range(0, 4):                           # ujung dibulatkan
        sc.set(x, 1, GOLD)
        sc.set(x, 2, GOLD)
        sc.set(239 - x, 1, GOLD)
        sc.set(239 - x, 2, GOLD)
    return sc


# ---------------- latar panggung ----------------
def beam(sc, x, y0, y1, w0, w1, col, strength=0.16):
    """Berkas lampu sorot: kerucut tipis yang sedikit mencerahkan latar (dengan dithering)."""
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0)
        half = (w0 + (w1 - w0) * t) / 2
        for xx in range(int(x - half), int(x + half) + 1):
            if 0 <= xx < sc.W and (xx + y) % 2 == 0 and sc.g[y][xx]:
                sc.set(xx, y, blend(sc.g[y][xx], col, strength * (1 - 0.5 * t)))


def speaker(sc, x0, y0, x1, y1):
    sc.rect(x0 - 1, y0 - 1, x1 + 1, y1 + 1, OUT)
    sc.rect(x0, y0, x1, y1, C(40, 38, 54))
    sc.rect(x0, y0, x1, y0 + 1, STEEL)
    w = x1 - x0
    for cy, r in ((y0 + (y1 - y0) * 0.3, w * 0.30), (y0 + (y1 - y0) * 0.72, w * 0.38)):
        cx = (x0 + x1) / 2
        sc.ell(cx, cy, r + 1, r + 1, OUT)
        sc.ell(cx, cy, r, r, C(70, 68, 92))
        sc.ell(cx, cy, r * 0.55, r * 0.55, C(30, 28, 44))
        sc.set(int(cx - r * 0.5), int(cy - r * 0.5), STEEL_L)


def drum_kit(sc, cx, base):
    """Satu set drum dari depan: tom, simbal, dan drum bas besar di tengah."""
    # kaki simbal dan simbal
    for (x, y, r) in ((cx - 26, base - 38, 11), (cx + 30, base - 44, 12)):
        sc.line((x, y), (x, base - 2), STEEL_D, 1)
        sc.ell(x, y, r + 1, 3, OUT)
        sc.ell(x, y, r, 2, GOLD)
        sc.rect(int(x - r / 2), int(y - 1), int(x + r / 2), int(y), GOLD_L)
    # tom
    for (x, y) in ((cx - 12, base - 32), (cx + 12, base - 32)):
        sc.ell(x, y, 11, 8, OUT)
        sc.ell(x, y, 10, 7, C(214, 52, 56))
        sc.ell(x, y - 2, 9, 4, C(250, 240, 214))
    # drum bas
    sc.ell(cx, base - 14, 17, 15, OUT)
    sc.ell(cx, base - 14, 16, 14, C(214, 52, 56))
    sc.ell(cx, base - 14, 12, 10, C(250, 240, 214))
    sc.ell(cx, base - 14, 5, 4, C(255, 200, 40))
    sc.rect(cx - 17, base - 1, cx + 17, base + 1, OUT)


def stage_bg():
    rnd = random.Random(33)
    sc = ps.Scene(W, H)

    # dinding belakang gelap dan lantai panggung
    sc.vgrad(0, 0, W, 124, [C(18, 14, 44), C(28, 20, 62), C(42, 26, 78), C(58, 34, 92)])
    sc.vgrad(0, 124, W, H, [C(30, 24, 56), C(24, 18, 46), C(20, 14, 38), C(16, 12, 32)])
    for _ in range(40):
        x, y = rnd.randint(30, W - 31), rnd.randint(30, 100)
        sc.set(x, y, C(255, 244, 200) if rnd.random() < 0.4 else C(150, 140, 200))

    # berkas lampu sorot (di bawah semua benda lain)
    beam_cols = [C(255, 90, 160), C(80, 210, 255), C(255, 214, 80), C(80, 210, 255), C(255, 90, 160)]
    for i, x in enumerate((34, 77, 120, 163, 206)):
        beam(sc, x, 24, 124, 6, 46, beam_cols[i], 0.22)

    # tirai beludru di kiri dan kanan
    for (x0, x1) in ((0, 20), (W - 20, W)):
        for x in range(x0, x1):
            fold = (x - x0) % 5
            col = C(150, 28, 52) if fold in (0, 1) else C(190, 40, 66) if fold in (2, 3) else C(120, 20, 42)
            for y in range(0, 124):
                sc.set(x, y, col)
    for (x0, x1) in ((0, 20), (W - 20, W)):
        sc.rect(x0, 0, x1, 8, C(120, 20, 42))
        for x in range(x0, x1, 3):
            sc.rect(x, 8, x + 2, 11, GOLD_D)

    # speaker menumpuk di kedua sisi
    speaker(sc, 24, 70, 42, 123)
    speaker(sc, W - 42, 70, W - 24, 123)

    # rangka lampu (truss) dan lampu sorot
    sc.rect(20, 17, W - 20, 25, OUT)
    sc.rect(20, 18, W - 20, 24, STEEL_D)
    for x in range(22, W - 20, 6):
        sc.line((x, 18), (x + 3, 23), STEEL, 1)
        sc.line((x + 3, 23), (x + 6, 18), STEEL, 1)
    sc.rect(20, 18, W - 20, 19, STEEL_L)
    for i, x in enumerate((34, 77, 120, 163, 206)):
        col = beam_cols[i]
        sc.rect(x - 4, 25, x + 4, 31, OUT)
        sc.rect(x - 3, 25, x + 3, 30, STEEL)
        sc.ell(x, 31, 4, 3, OUT)
        sc.ell(x, 31, 3, 2, col)
        sc.set(x - 1, 31, CREAM)

    # panggung kecil dan drum di kiri tengah (di belakang bos)
    sc.rect(26, 120, 124, 126, OUT)
    sc.rect(27, 121, 123, 125, C(90, 56, 70))
    sc.rect(27, 121, 123, 122, C(150, 100, 100))
    drum_kit(sc, 72, 120)

    # lantai panggung: papan melintang dan pantulan lampu
    for y in range(126, 324, 14):
        sc.rect(0, y, W, y + 1, C(14, 10, 28))
    for y in range(128, 324):
        for x in range(0, W):
            if (x // 24 + y // 14) % 2 == 0 and sc.g[y][x]:
                sc.set(x, y, blend(sc.g[y][x], C(60, 44, 100), 0.18))
    for (cy, ry) in ((170, 10), (240, 12), (300, 14)):
        for yy in range(cy - ry, cy + ry):
            for xx in range(0, W):
                u = ((xx - 120) / 118) ** 2 + ((yy - cy) / ry) ** 2
                if u <= 1 and (xx + yy) % 2 == 0 and sc.g[yy][xx]:
                    sc.set(xx, yy, blend(sc.g[yy][xx], C(120, 90, 200), 0.16))

    # tepi depan panggung dengan strip LED
    sc.rect(0, 324, W, 332, OUT)
    sc.rect(0, 325, W, 331, C(54, 40, 84))
    sc.rect(0, 325, W, 326, STEEL_L)
    led = [C(255, 90, 160), C(80, 210, 255), C(255, 214, 80), C(120, 240, 150)]
    for n, x in enumerate(range(3, W, 8)):
        sc.rect(x, 328, x + 3, 330, led[n % 4])

    # area bar semangat dan pad: lantai gelap dengan garis tipis
    for y in range(332, H):
        for x in range(W):
            sc.set(x, y, C(22, 16, 40) if (x // 20 + (y - 332) // 14) % 2 == 0 else C(26, 20, 46))
    for y in range(332, H, 14):
        sc.rect(0, y, W, y + 1, C(14, 10, 28))
    return sc


def save(sc, out, name, scale=SCALE, rgb=False):
    im = sc.image(scale)
    if rgb:
        im = im.convert('RGB')
    im.save(out / name, optimize=True)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/images/rhythm'
    out.mkdir(parents=True, exist_ok=True)
    save(stage_bg(), out, 'stage.png', rgb=True)
    for lane in range(4):
        save(note(lane), out, f'note_{lane}.png')
        save(pad(lane), out, f'pad_{lane}.png')
    save(hit_line(), out, 'hit_line.png')
    print('aset Level 7 ditulis ke', out)


if __name__ == '__main__':
    main()
