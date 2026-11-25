"""Aset Level 6 (Mr. Lexi the Gambler) bergaya piksel: latar stan pasar malam dan sprite kartu, koin, cangkir, bola, chip.

    python tools/art/pixel_gambler.py [folder_keluaran]
Menulis ke assets/images/gambler/:
  table.png (720x1278 = kisi 240x426 x3), card_back/card_safe/card_bomb.png (kisi 20x28 x3),
  coin_head/coin_tail.png (kisi 24x24 x3), coin_spin.png (kisi 8x24 x3), cup.png (kisi 22x26 x3),
  ball.png (kisi 10x10 x3), chip.png (kisi 12x12 x3).
Bos Mr. Lexi (4 ekspresi) dibuat oleh pixel_bosses.py. Tanpa aset luar: semuanya digambar dari kode.
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
CREAM = C(250, 240, 214)
GOLD = C(255, 200, 40)
GOLD_L = C(255, 238, 140)
GOLD_D = C(200, 140, 20)
RED = C(214, 52, 56)
RED_L = C(244, 110, 104)
RED_D = C(150, 30, 44)
GREEN = C(76, 176, 96)
GREEN_D = C(36, 112, 64)


def outline(sc):
    """Garis tepi gelap 1 piksel di sekeliling bentuk (sprite harus punya sisa 1 piksel di tepi)."""
    filled = {(x, y) for y in range(sc.H) for x in range(sc.W) if sc.g[y][x]}
    for (x, y) in filled:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in filled:
                sc.set(x + dx, y + dy, OUT)
    return sc


def star_points(cx, cy, r_out, r_in, rot=-math.pi / 2):
    pts = []
    for i in range(10):
        r = r_out if i % 2 == 0 else r_in
        a = rot + i * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def rounded(sc, x0, y0, x1, y1, col):
    """Persegi panjang dengan sudut dipotong 1 piksel."""
    sc.rect(x0, y0, x1, y1, col)
    for (cx, cy) in ((x0, y0), (x1 - 1, y0), (x0, y1 - 1), (x1 - 1, y1 - 1)):
        sc.g[cy][cx] = None


# ---------------- kartu ----------------
def card_base(face):
    sc = ps.Scene(20, 28)
    rounded(sc, 1, 1, 19, 27, CREAM if face else RED_D)
    return sc


def card_back():
    sc = ps.Scene(20, 28)
    rounded(sc, 1, 1, 19, 27, CREAM)
    rounded(sc, 3, 3, 17, 25, RED)
    for y in range(3, 25):
        for x in range(3, 17):
            if sc.g[y][x] and (x + y) % 4 == 0:
                sc.set(x, y, RED_L)
            elif sc.g[y][x] and (x - y) % 4 == 0:
                sc.set(x, y, RED_D)
    # belah ketupat emas di tengah
    sc.poly([(10, 8), (14.5, 14), (10, 20), (5.5, 14)], GOLD_D)
    sc.poly([(10, 9.5), (13, 14), (10, 18.5), (7, 14)], GOLD)
    sc.set(9, 12, GOLD_L)
    return outline(sc)


def card_safe():
    sc = card_base(True)
    sc.poly(star_points(10, 14.5, 7.2, 3.0), GREEN_D)
    sc.poly(star_points(10, 14.5, 5.6, 2.3), GREEN)
    sc.set(9, 12, C(170, 230, 170))
    for (x, y) in ((4, 4), (15, 4), (4, 23), (15, 23)):
        ps.star4(sc, x, y, GREEN)
    return outline(sc)


def card_bomb():
    sc = card_base(True)
    # bom hitam dengan sumbu
    sc.ell(10, 16, 6, 6, C(30, 28, 40))
    sc.ell(10, 16, 5, 5, C(52, 50, 66))
    sc.set(8, 14, C(190, 190, 214))
    sc.set(9, 13, C(190, 190, 214))
    sc.rect(9, 8, 12, 11, C(70, 66, 84))
    sc.line((11, 8), (13, 6), C(150, 100, 50), 1)
    ps.star4(sc, 14, 5, GOLD)
    sc.set(14, 5, C(255, 120, 40))
    for (x, y) in ((4, 4), (15, 4), (4, 23), (15, 23)):
        sc.set(x, y, RED)
        sc.set(x + 1, y, RED)
        sc.set(x, y + 1, RED)
        sc.set(x + 1, y + 1, RED)
    return outline(sc)


# ---------------- koin ----------------
def coin_base():
    sc = ps.Scene(24, 24)
    sc.ell(12, 12, 11, 11, GOLD_D)
    sc.ell(12, 12, 9.4, 9.4, GOLD)
    # kilau di kiri atas dan lingkaran dalam
    for (x, y) in ((6, 7), (7, 6), (8, 5), (5, 8), (5, 9)):
        sc.set(x, y, GOLD_L)
    return sc


def coin_head():
    sc = coin_base()
    # lambang topi tinggi Mr. Lexi
    sc.rect(8, 6, 16, 13, C(40, 36, 52))
    sc.rect(8, 11, 16, 13, RED)
    sc.rect(5, 13, 19, 16, C(40, 36, 52))
    sc.rect(9, 7, 11, 10, C(86, 80, 108))
    return outline(sc)


def coin_tail():
    sc = coin_base()
    sc.poly(star_points(12, 12.5, 7.4, 3.2), GOLD_D)
    sc.poly(star_points(12, 12.5, 5.6, 2.4), C(255, 224, 90))
    return outline(sc)


def coin_spin():
    sc = ps.Scene(8, 24)
    sc.ell(4, 12, 3, 11, GOLD_D)
    sc.ell(4, 12, 1.6, 10, GOLD)
    sc.set(3, 8, GOLD_L)
    sc.set(3, 9, GOLD_L)
    return outline(sc)


# ---------------- cangkir dan bola ----------------
def cup():
    """Cangkir terbalik: mulut lebar di bawah, belang merah dan krem."""
    sc = ps.Scene(22, 26)
    for y in range(2, 23):
        t = (y - 2) / 20
        half = 4.5 + 5.5 * t
        for x in range(22):
            if abs(x + 0.5 - 11) <= half:
                sc.set(x, y, RED if ((x - 1) // 3) % 2 == 0 else CREAM)
    # bagian atas membulat
    for x in range(22):
        if sc.g[2][x] and abs(x + 0.5 - 11) > 3.4:
            sc.g[2][x] = None
    # bibir bawah
    sc.rect(1, 22, 21, 25, RED_D)
    sc.rect(1, 22, 21, 23, RED_L)
    # kilau
    for y in range(5, 15):
        sc.set(5 + (y - 5) // 4, y, C(255, 255, 255))
    return outline(sc)


def ball():
    sc = ps.Scene(10, 10)
    sc.ell(5, 5, 4, 4, RED_D)
    sc.ell(5, 5, 3.2, 3.2, RED)
    sc.set(4, 3, RED_L)
    sc.set(3, 4, RED_L)
    return outline(sc)


def chip():
    sc = ps.Scene(12, 12)
    sc.ell(6, 6, 5, 5, RED_D)
    sc.ell(6, 6, 4.2, 4.2, RED)
    for (x, y) in ((5, 1), (6, 1), (5, 10), (6, 10), (1, 5), (1, 6), (10, 5), (10, 6)):
        sc.set(x, y, CREAM)
    sc.ell(6, 6, 2.6, 2.6, RED_L)
    sc.ell(6, 6, 1.6, 1.6, RED_D)
    return outline(sc)


# ---------------- latar stan pasar malam ----------------
def table_bg():
    rnd = random.Random(21)
    sc = ps.Scene(W, H)

    # langit malam dan bintang
    sc.vgrad(0, 0, W, H, [C(18, 14, 44), C(30, 22, 66), C(46, 30, 86), C(66, 40, 98)])
    for _ in range(46):
        x, y = rnd.randint(2, W - 3), rnd.randint(30, 110)
        sc.set(x, y, C(255, 244, 200) if rnd.random() < 0.5 else C(190, 180, 230))

    # dinding belakang stan: papan kayu tegak
    top, bottom = 40, 147
    for x in range(W):
        plank = (x // 12) % 2
        col = C(92, 58, 48) if plank == 0 else C(104, 66, 52)
        for y in range(top, bottom):
            sc.set(x, y, col)
        if x % 12 == 0:
            for y in range(top, bottom):
                sc.set(x, y, C(60, 36, 34))
    for _ in range(90):
        x, y = rnd.randint(1, W - 2), rnd.randint(top + 2, bottom - 3)
        sc.set(x, y, C(76, 46, 40))

    # kanopi belang merah-krem dengan tepi bergerigi
    for i in range(0, W, 16):
        col = RED if (i // 16) % 2 == 0 else CREAM
        shade = RED_D if (i // 16) % 2 == 0 else C(214, 200, 168)
        sc.rect(i, 0, i + 16, 26, col)
        sc.rect(i, 22, i + 16, 26, shade)
        sc.ell(i + 8, 26, 8, 6, col)
        sc.rect(i, 26, i + 16, 27, col)
    for x in range(W):
        for y in range(18, 36):
            c = sc.g[y][x]
            below = sc.g[y + 1][x] if y + 1 < H else None
            if c in (RED, CREAM, RED_D, C(214, 200, 168)) and below not in (RED, CREAM, RED_D, C(214, 200, 168)):
                sc.set(x, y + 1, OUT)

    # untaian lampu
    colors = [C(255, 214, 80), C(255, 120, 110), C(120, 220, 255), C(170, 255, 150)]
    prev = None
    for x in range(0, W, 2):
        y = 40 + int(5 * math.sin(x / 240 * 6 * math.pi) ** 2)
        sc.set(x, y, C(30, 24, 44))
        prev = (x, y)
    for n, x in enumerate(range(10, W, 20)):
        y = 40 + int(5 * math.sin(x / 240 * 6 * math.pi) ** 2)
        col = colors[n % 4]
        sc.rect(x - 2, y + 1, x + 3, y + 6, C(30, 24, 44))
        sc.rect(x - 1, y + 2, x + 2, y + 5, col)
        sc.set(x - 1, y + 2, C(255, 255, 255))

    # papan nama stan di kanan, di bawah gelembung ucapan bos
    # (digeser ke kiri supaya tidak terpotong tepi layar pada HP yang sempit)
    sc.rect(104, 104, 220, 142, OUT)
    sc.rect(106, 106, 218, 140, C(60, 36, 34))
    sc.rect(107, 107, 217, 139, CREAM)
    ps.Scene.text(sc, 114, 112, "MR. LEXI", 2, RED_D)
    ps.Scene.text(sc, 128, 129, "LUCKY STALL", 1, C(60, 36, 34))

    # tepi meja kayu
    sc.rect(0, 143, W, 151, OUT)
    sc.rect(0, 144, W, 150, C(160, 106, 58))
    sc.rect(0, 144, W, 146, C(206, 152, 92))
    sc.rect(0, 148, W, 150, C(112, 70, 44))

    # kain hijau meja dengan pola belah ketupat halus dan list emas
    fx0, fx1, fy0, fy1 = 8, 232, 151, 300
    sc.rect(0, 151, W, 304, C(112, 70, 44))
    for y in range(fy0, fy1):
        for x in range(fx0, fx1):
            d = ((x // 8) + (y // 8)) % 2
            sc.set(x, y, C(26, 118, 76) if d == 0 else C(29, 124, 79))
    sc.rect(fx0, fy0, fx1, fy0 + 1, OUT)
    sc.rect(fx0, fy1 - 1, fx1, fy1, OUT)
    sc.rect(fx0, fy0, fx0 + 1, fy1, OUT)
    sc.rect(fx1 - 1, fy0, fx1, fy1, OUT)
    sc.rect(fx0 + 3, fy0 + 3, fx1 - 3, fy0 + 4, GOLD_D)
    sc.rect(fx0 + 3, fy1 - 4, fx1 - 3, fy1 - 3, GOLD_D)
    sc.rect(fx0 + 3, fy0 + 3, fx0 + 4, fy1 - 3, GOLD_D)
    sc.rect(fx1 - 4, fy0 + 3, fx1 - 3, fy1 - 3, GOLD_D)
    for (x, y) in ((fx0 + 3, fy0 + 3), (fx1 - 4, fy0 + 3), (fx0 + 3, fy1 - 4), (fx1 - 4, fy1 - 4)):
        ps.star4(sc, x, y, GOLD)

    # sisi depan meja dan lantai papan di bawah (tempat panel kontrol)
    sc.rect(0, 304, W, 308, OUT)
    sc.rect(0, 305, W, 307, C(206, 152, 92))
    for y in range(308, H):
        for x in range(W):
            sc.set(x, y, C(52, 36, 44) if (x // 20 + (y - 308) // 14) % 2 == 0 else C(60, 42, 50))
    for y in range(308, H, 14):
        sc.rect(0, y, W, y + 1, C(34, 24, 32))
    return sc


def save(sc, out, name, scale=SCALE, rgb=False):
    im = sc.image(scale)
    if rgb:
        im = im.convert('RGB')
    im.save(out / name, optimize=True)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/images/gambler'
    out.mkdir(parents=True, exist_ok=True)
    save(table_bg(), out, 'table.png', rgb=True)
    for name, fn in (('card_back', card_back), ('card_safe', card_safe), ('card_bomb', card_bomb),
                     ('coin_head', coin_head), ('coin_tail', coin_tail), ('coin_spin', coin_spin),
                     ('cup', cup), ('ball', ball), ('chip', chip)):
        save(fn(), out, name + '.png')
    print('aset Level 6 ditulis ke', out)


if __name__ == '__main__':
    main()
