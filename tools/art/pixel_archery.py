"""Latar Level 5 (lapangan panahan) bergaya piksel: 720x1278 = kisi 240x426 x3.

    python tools/art/pixel_archery.py [folder_keluaran]
Boss Bima (4 ekspresi) dibuat oleh pixel_bosses.py.
"""
import math
import random
import sys
from pathlib import Path

import pixel_scenes as ps

C = ps.C
OUT = ps.OUT
ROOT = ps.ROOT
W, H = 240, 426


def tree(sc, x, base, size):
    """Pohon bulat: batang cokelat, tajuk hijau tiga lapis, garis tepi gelap."""
    th = int(size * 0.9)
    sc.rect(x - 2, base - th, x + 3, base, OUT)
    sc.rect(x - 1, base - th, x + 2, base, C(120, 78, 44))
    r = size * 0.55
    cy = base - th - r * 0.5
    for dx, dy, rr in ((-r * 0.5, 0.25 * r, r * 0.8), (r * 0.5, 0.25 * r, r * 0.8), (0, -0.2 * r, r)):
        sc.ell(x + dx, cy + dy, rr + 1, rr + 1, OUT)
    for dx, dy, rr in ((-r * 0.5, 0.25 * r, r * 0.8), (r * 0.5, 0.25 * r, r * 0.8), (0, -0.2 * r, r)):
        sc.ell(x + dx, cy + dy, rr, rr, C(60, 140, 70))
    sc.ell(x - r * 0.25, cy - r * 0.35, r * 0.55, r * 0.4, C(92, 172, 92))


def fence(sc, y, x0, x1):
    for x in range(x0, x1, 14):
        sc.rect(x - 1, y - 12, x + 4, y + 2, OUT)
        sc.rect(x, y - 11, x + 3, y + 1, C(160, 108, 60))
    for ry in (y - 8, y - 3):
        sc.rect(x0, ry - 1, x1, ry + 3, OUT)
        sc.rect(x0, ry, x1, ry + 2, C(186, 134, 80))


def build():
    rnd = random.Random(8)
    sc = ps.Scene(W, H)

    # langit
    sky = [C(96, 170, 240), C(128, 196, 246), C(166, 218, 250), C(204, 236, 252)]
    sc.vgrad(0, 0, W, 215, sky)
    # matahari dan awan
    sc.ell(204, 44, 16, 16, C(255, 244, 190))
    sc.ell(204, 44, 12, 12, C(255, 236, 140))
    ps.cloud(sc, 8, 60, 44)
    ps.cloud(sc, 150, 96, 54)
    ps.cloud(sc, 70, 128, 30)

    # bukit jauh dan dekat
    for x in range(W):
        y1 = 176 + int(9 * math.sin(x / 26.0) + 4 * math.sin(x / 9.0))
        for y in range(y1, 226):
            sc.set(x, y, C(96, 164, 104))
    for x in range(W):
        y2 = 192 + int(6 * math.sin(x / 19.0 + 2) + 3 * math.sin(x / 7.0))
        for y in range(y2, 232):
            sc.set(x, y, C(74, 140, 84))
    # deretan pohon kecil di cakrawala
    for x in range(6, W, 17):
        tree(sc, x + rnd.randint(-3, 3), 206, rnd.randint(9, 12))

    # padang rumput: jalur potong bergantian
    for y in range(206, H):
        lane = ((y - 206) // 14) % 2
        base = C(112, 192, 92) if lane == 0 else C(126, 206, 104)
        for x in range(W):
            sc.set(x, y, base)
    for _ in range(260):
        x, y = rnd.randint(0, W - 1), rnd.randint(210, H - 1)
        sc.set(x, y, C(96, 172, 80))
    for _ in range(40):
        x, y = rnd.randint(2, W - 3), rnd.randint(216, 380)
        col = rnd.choice([C(255, 240, 120), C(255, 255, 255), C(255, 150, 170)])
        ps.star4(sc, x, y, col)
    # pagar
    sc.rect(0, 212, W, 214, OUT)
    fence(sc, 222, 0, W)
    # pohon besar di tepi
    tree(sc, 16, 262, 26)
    tree(sc, 226, 270, 30)
    # tanah gelap di bawah untuk panel kontrol
    for y in range(352, H):
        for x in range(W):
            sc.set(x, y, C(88, 158, 76) if (x // 6 + y // 4) % 2 else C(80, 148, 70))
    sc.rect(0, 352, W, 353, OUT)
    return sc


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/images/archery'
    out.mkdir(parents=True, exist_ok=True)
    build().image(3).convert('RGB').save(out / 'archery_bg.png', optimize=True)
    print('latar panahan ditulis ke', out)


if __name__ == '__main__':
    main()
