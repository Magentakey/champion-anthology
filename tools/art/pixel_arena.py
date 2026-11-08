"""Latar arena Level 1 (Colosseum) bergaya piksel: 1600x720 = kisi 400x180 x4.

    python tools/art/pixel_arena.py [folder_keluaran]
Struktur harus sama dengan gambar lama karena ArenaComponent memotongnya di garis 560/720:
dinding dan penonton di atas (140 baris kisi), pasir di bawah (40 baris kisi).
"""
import random
import sys
from pathlib import Path

import pixel_scenes as ps

C = ps.C
OUT = ps.OUT
ROOT = ps.ROOT
W, H = 400, 180
WALL_H = 140          # = 560 / 4

STONE = C(230, 200, 150)
STONE_HI = C(246, 224, 180)
STONE_SH = C(190, 156, 110)
WARM_UP = C(255, 236, 170)
WARM_LO = C(255, 206, 140)
CROWD = C(52, 30, 66)
CROWD_HI = C(86, 56, 104)
SAND = C(216, 178, 122)


def arch(sc, x, y_top, w, y_bot, fill):
    """Bukaan lengkung: garis tepi gelap, isi hangat."""
    r = w / 2
    for pad, col in ((1, OUT), (0, fill)):
        sc.rect(x - pad, y_top + r, x + w + pad, y_bot, col)
        sc.ell(x + r, y_top + r, r + pad, r + pad, col)
    # bayangan sisi kanan bukaan
    sc.rect(x + w - 2, y_top + r, x + w, y_bot, C(240, 200, 130) if fill == WARM_UP else C(236, 176, 110))


def crowd(sc, x, y_floor, w, rnd):
    """Sekelompok penonton (siluet kepala dan bahu), kadang ada yang mengangkat tangan."""
    n = rnd.randint(2, 4)
    xs = sorted(rnd.sample(range(x + 3, x + w - 3), min(n, w - 6)))
    for cx in xs:
        h = rnd.randint(0, 2)
        base = y_floor - h
        sc.ell(cx, base - 9, 2.6, 2.6, CROWD)
        sc.rect(cx - 3, base - 6, cx + 4, base, CROWD)
        sc.set(cx - 1, base - 10, CROWD_HI)
        if rnd.random() < 0.28:
            sc.line((cx + 3, base - 6), (cx + 5, base - 13), CROWD)
            sc.set(cx + 5, base - 14, CROWD)


def banner(sc, x, y, col):
    sc.rect(x - 1, y, x + 8, y + 24, OUT)
    sc.poly([(x - 1, y + 23), (x + 8, y + 23), (x + 3.5, y + 29)], OUT)
    sc.rect(x, y + 1, x + 7, y + 24, col)
    sc.poly([(x, y + 24), (x + 7, y + 24), (x + 3.5, y + 28)], col)
    sc.rect(x + 3, y + 5, x + 4, y + 17, C(255, 240, 200))
    sc.rect(x - 2, y - 1, x + 9, y + 1, OUT)


def build():
    rnd = random.Random(11)
    sc = ps.Scene(W, H)

    # langit sempit di atas (sinar matahari)
    sc.vgrad(0, 0, W, 10, [C(255, 214, 140), C(255, 232, 176), C(255, 246, 214)])
    # dinding batu
    for y in range(8, WALL_H):
        for x in range(W):
            sc.set(x, y, STONE)
    # kornis atas dengan jendela kecil
    sc.rect(0, 8, W, 9, OUT)
    sc.rect(0, 9, W, 11, STONE_HI)
    for x in range(4, W, 12):
        sc.rect(x, 13, x + 5, 20, OUT)
        sc.rect(x + 1, 14, x + 4, 19, C(110, 60, 40))
    sc.rect(0, 22, W, 24, STONE_SH)
    sc.rect(0, 22, W, 23, OUT)

    period = 25
    n = W // period
    # tingkat atas
    t1_top, t1_bot = 28, 66
    for i in range(n + 1):
        x = i * period + 3
        arch(sc, x, t1_top, 18, t1_bot, WARM_UP)
        crowd(sc, x, t1_bot, 18, rnd)
    sc.rect(0, 66, W, 70, STONE_SH)
    sc.rect(0, 66, W, 67, OUT)
    sc.rect(0, 67, W, 68, STONE_HI)
    sc.rect(0, 70, W, 71, OUT)
    # tingkat bawah
    t2_top, t2_bot = 76, 130
    for i in range(n + 1):
        x = i * period + 2
        arch(sc, x, t2_top, 20, t2_bot, WARM_LO)
        crowd(sc, x, t2_bot, 20, rnd)
    for i in (1, 3, 5, 7, 9, 11, 13, 15):
        banner(sc, i * period + 8, 71, C(214, 40, 40) if (i // 2) % 2 == 0 else C(251, 140, 0))
    # tepi bawah dinding (pagar arena)
    sc.rect(0, 130, W, WALL_H, STONE_SH)
    sc.rect(0, 130, W, 131, OUT)
    sc.rect(0, 131, W, 133, STONE_HI)
    sc.rect(0, WALL_H - 1, W, WALL_H, OUT)

    # pasir
    for y in range(WALL_H, H):
        for x in range(W):
            sc.set(x, y, SAND)
    for _ in range(420):
        x, y = rnd.randint(0, W - 1), rnd.randint(WALL_H + 2, H - 1)
        sc.set(x, y, C(236, 204, 150) if rnd.random() < 0.5 else C(190, 150, 100))
    for x in range(0, W, 2):
        sc.set(x, WALL_H + 1, C(190, 150, 100))
    # garis oval arena
    import math
    cx, cy, rx, ry = W / 2, 164, 172, 12
    for a in range(0, 720):
        t = math.radians(a / 2)
        x, y = round(cx + rx * math.cos(t)), round(cy + ry * math.sin(t))
        sc.set(x, y, C(176, 134, 92))
    return sc


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/images/fight'
    out.mkdir(parents=True, exist_ok=True)
    build().image(4).convert('RGB').save(out / 'arena.png', optimize=True)
    print('arena piksel ditulis ke', out)


if __name__ == '__main__':
    main()
