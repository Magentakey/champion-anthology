"""Aset Level 8 (Mira the Memory Keeper) bergaya piksel: perpustakaan malam, sembilan pad bentuk, dan ikon nyawa.

    python tools/art/pixel_memory.py [folder_keluaran]
Menulis ke assets/images/memory/:
  stage.png (720x1278 = kisi 240x426 x3),
  pad_0..8.png (120x60 = dua bingkai 20x20 x3 berdampingan: kiri redup, kanan menyala),
  heart_on.png dan heart_off.png (kisi 8x8 x3 = 24x24).
Bos Mira (4 ekspresi) dibuat oleh pixel_bosses.py. Tanpa aset luar: semuanya digambar dari kode.
Bentuk, warna, dan nada tiap pad sama dengan tabel di docs/PANDUAN_PENGEMBANGAN.md (Level 8).
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

CREAM = C(255, 244, 214)
GOLD = C(255, 200, 40)
GOLD_L = C(255, 238, 140)
GOLD_D = C(200, 140, 20)
DARK = C(24, 18, 44)

# warna tiap pad (indeks 0..8): merah, biru, hijau, emas, ungu, merah muda, teal, oranye, krem
PAD = [C(232, 64, 72), C(64, 140, 240), C(84, 200, 100), C(255, 200, 48), C(152, 88, 224),
       C(240, 120, 184), C(48, 192, 176), C(240, 138, 48), C(255, 240, 208)]


def blend(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3)) + (255,)


def lighter(c, t=0.45):
    return blend(c, (255, 255, 255, 255), t)


def rounded(sc, x0, y0, x1, y1, col):
    """Persegi panjang dengan sudut dipotong 1 piksel."""
    sc.rect(x0, y0, x1, y1, col)
    for (cx, cy) in ((x0, y0), (x1 - 1, y0), (x0, y1 - 1), (x1 - 1, y1 - 1)):
        sc.g[cy][cx] = None


# ---------------- bentuk pad ----------------
CX, CY = 13, 12          # pusat bentuk di dalam bingkai 20x20 (sisi kiri atas dipakai nomor papan ketik)


def star_points(cx, cy, r_out, r_in):
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    return pts


def draw_shape(sc, idx, col, carve=None):
    """Menggambar bentuk ke-[idx] (0..8) berwarna [col] pada Scene [sc] di pusat (CX, CY)."""
    if idx == 0:        # lingkaran
        sc.ell(CX, CY, 5, 5, col)
    elif idx == 1:      # segitiga
        sc.poly([(CX, CY - 5.5), (CX + 6, CY + 4.5), (CX - 6, CY + 4.5)], col)
    elif idx == 2:      # persegi
        sc.rect(CX - 4.5, CY - 4.5, CX + 4.5, CY + 4.5, col)
    elif idx == 3:      # berlian
        sc.poly([(CX, CY - 6), (CX + 5, CY), (CX, CY + 6), (CX - 5, CY)], col)
    elif idx == 4:      # bintang
        sc.poly(star_points(CX, CY + 0.7, 6.9, 2.5), col)
    elif idx == 5:      # hati
        sc.ell(CX - 2.5, CY - 1.8, 3.1, 3.1, col)
        sc.ell(CX + 2.5, CY - 1.8, 3.1, 3.1, col)
        sc.poly([(CX - 5.4, CY - 0.4), (CX + 5.4, CY - 0.4), (CX, CY + 5.4)], col)
    elif idx == 6:      # salib
        sc.rect(CX - 1.8, CY - 5.5, CX + 1.8, CY + 5.5, col)
        sc.rect(CX - 5.5, CY - 1.8, CX + 5.5, CY + 1.8, col)
    elif idx == 7:      # bulan sabit
        sc.ell(CX, CY, 5.5, 5.5, col)
        sc.ell(CX + 2.8, CY - 1.4, 4.6, 4.6, carve)
    elif idx == 8:      # segi enam
        sc.poly([(CX + math.cos(math.radians(a)) * 5.7, CY + math.sin(math.radians(a)) * 5.7)
                 for a in range(0, 360, 60)], col)


def shape_pixels(idx):
    """Himpunan piksel bentuk (tanpa garis tepi) pada kisi 20x20."""
    mask = ps.Scene(20, 20)
    marker = C(1, 2, 3)
    if idx == 7:
        # bulan sabit: gambar penuh lalu buang bagian yang dipotong
        full = ps.Scene(20, 20)
        full.ell(CX, CY, 5.5, 5.5, marker)
        cut = ps.Scene(20, 20)
        cut.ell(CX + 2.8, CY - 1.4, 4.6, 4.6, marker)
        return {(x, y) for y in range(20) for x in range(20) if full.g[y][x] and not cut.g[y][x]}
    draw_shape(mask, idx, marker)
    return {(x, y) for y in range(20) for x in range(20) if mask.g[y][x]}


def pad_frame(sc, ox, idx, lit):
    """Satu bingkai pad 20x20 di kolom [ox, ox + 20)."""
    base = PAD[idx]
    if lit:
        rim, face, fill, spark = CREAM, blend(base, DARK, 0.45), base, True
    else:
        rim, face, fill, spark = blend(base, DARK, 0.5), blend(base, DARK, 0.86), blend(base, DARK, 0.6), False
    rounded(sc, ox + 0, 0, ox + 20, 20, OUT)
    rounded(sc, ox + 1, 1, ox + 19, 19, rim)
    rounded(sc, ox + 2, 2, ox + 18, 18, face)

    pixels = shape_pixels(idx)
    outline = set()
    for (x, y) in pixels:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in pixels:
                outline.add((x + dx, y + dy))
    for (x, y) in outline:
        sc.set(ox + x, y, OUT)
    for (x, y) in pixels:
        shade = fill
        if (x - 1, y - 1) not in pixels or (x, y - 1) not in pixels and (x - 1, y) not in pixels:
            shade = lighter(fill, 0.4) if lit else blend(fill, (255, 255, 255, 255), 0.12)
        sc.set(ox + x, y, shade)

    # nomor papan ketik di sudut kiri atas
    glyph = ps.GLYPH[str(idx + 1)]
    gcol = C(40, 30, 60) if lit else blend(base, DARK, 0.25)
    for j, row in enumerate(glyph):
        for i, c in enumerate(row):
            if c == '#':
                sc.set(ox + 2 + i, 2 + j, gcol)
    if spark:                                           # percikan di sudut
        for (x, y) in ((2, 1), (17, 1), (2, 18), (17, 18)):
            sc.set(ox + x, y, CREAM)


def pad(idx):
    sc = ps.Scene(40, 20)
    pad_frame(sc, 0, idx, False)
    pad_frame(sc, 20, idx, True)
    return sc


# ---------------- ikon nyawa ----------------
HEART = [".#..#.", "######", "######", ".####.", "..##.."]


def heart(on):
    sc = ps.Scene(8, 8)
    body = C(232, 56, 72) if on else C(70, 62, 92)
    light = C(255, 150, 160) if on else C(96, 88, 120)
    for j, row in enumerate(HEART):
        for i, c in enumerate(row):
            if c == '#':
                sc.set(1 + i, 1 + j, body)
    sc.set(2, 2, light)
    if on:
        sc.set(3, 2, light)
    filled = {(x, y) for y in range(sc.H) for x in range(sc.W) if sc.g[y][x]}
    for (x, y) in filled:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in filled:
                sc.set(x + dx, y + dy, OUT)
    return sc


# ---------------- latar perpustakaan ----------------
BOOKS = [C(140, 40, 60), C(48, 90, 150), C(60, 130, 90), C(190, 140, 40), C(110, 62, 168),
         C(180, 90, 60), C(40, 130, 130), C(200, 190, 150)]


def shelf(sc, rnd, y_top, y_bottom):
    """Satu rak buku: papan di bawah, punggung buku berwarna dengan tinggi acak (bersemai)."""
    sc.rect(0, y_bottom, W, y_bottom + 3, OUT)
    sc.rect(0, y_bottom + 1, W, y_bottom + 3, C(96, 60, 44))
    sc.rect(0, y_bottom + 1, W, y_bottom + 2, C(150, 100, 70))
    x = 2
    while x < W - 2:
        w = rnd.choice((3, 4, 4, 5, 6))
        h = rnd.randint(y_bottom - y_top - 9, y_bottom - y_top - 1)
        col = rnd.choice(BOOKS)
        top = y_bottom - h
        sc.rect(x, top, x + w, y_bottom, OUT)
        sc.rect(x + 1, top + 1, x + w, y_bottom, blend(col, DARK, 0.35))      # gelap, supaya boss menonjol
        sc.rect(x + 1, top + 1, x + 2, y_bottom, blend(col, DARK, 0.15))
        if w >= 5:
            sc.rect(x + 1, top + 4, x + w, top + 5, blend(GOLD, DARK, 0.4))   # pita emas pada punggung
        x += w + 1


def candle(sc, x, y):
    """Lilin pendek di tempat lilin dengan nyala dan cahaya hangat (dithering)."""
    sc.rect(x - 4, y + 12, x + 5, y + 14, OUT)
    sc.rect(x - 3, y + 12, x + 4, y + 13, GOLD_D)
    sc.rect(x - 2, y, x + 3, y + 12, OUT)
    sc.rect(x - 1, y + 1, x + 2, y + 12, CREAM)
    sc.rect(x, y + 1, x + 2, y + 12, C(232, 218, 184))
    sc.poly([(x + 0.5, y - 6), (x + 2.5, y - 2), (x + 0.5, y), (x - 1.5, y - 2)], C(255, 168, 48))
    sc.poly([(x + 0.5, y - 4.5), (x + 1.6, y - 2), (x + 0.5, y - 0.5), (x - 0.6, y - 2)], GOLD_L)
    for yy in range(y - 20, y + 14):
        for xx in range(x - 14, x + 15):
            d = ((xx - x) / 14) ** 2 + ((yy - (y - 3)) / 17) ** 2
            if d <= 1 and (xx + yy) % 2 == 0 and 0 <= xx < W and 0 <= yy < H and sc.g[yy][xx]:
                sc.set(xx, yy, blend(sc.g[yy][xx], (255, 190, 90, 255), 0.18 * (1 - d)))


def panel(sc, x0, y0, x1, y1):
    """Panel "kunci memori" di tengah: pelat gelap berbingkai emas dan teal, lambang cincin di tengah."""
    sc.rect(x0 - 2, y0 - 2, x1 + 2, y1 + 2, OUT)
    sc.rect(x0 - 1, y0 - 1, x1 + 1, y1 + 1, GOLD_D)
    sc.rect(x0, y0, x1, y1, GOLD)
    sc.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, OUT)
    sc.rect(x0 + 2, y0 + 2, x1 - 2, y1 - 2, C(30, 70, 84))
    sc.rect(x0 + 3, y0 + 3, x1 - 3, y1 - 3, C(20, 14, 40))
    # lambang cincin dan garis silang tipis di tengah (dithering)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    for yy in range(y0 + 4, y1 - 3):
        for xx in range(x0 + 4, x1 - 3):
            d = math.hypot(xx - cx, (yy - cy) * 0.78)
            ring = abs(d - 86) < 1.2 or abs(d - 58) < 1.0
            cross = (abs(xx - cx) < 1 or abs(yy - cy) < 1) and d < 86
            if (ring or cross) and (xx + yy) % 2 == 0:
                sc.set(xx, yy, C(34, 40, 72))
    for (x, y) in ((x0 + 6, y0 + 6), (x1 - 7, y0 + 6), (x0 + 6, y1 - 7), (x1 - 7, y1 - 7)):
        ps.star4(sc, x, y, GOLD)
        sc.set(x, y, CREAM)


def stage_bg():
    rnd = random.Random(88)
    sc = ps.Scene(W, H)

    # dinding belakang gelap dan lantai karpet
    sc.vgrad(0, 0, W, 132, [C(22, 14, 40), C(30, 20, 52), C(38, 24, 62), C(46, 30, 70)])
    sc.vgrad(0, 132, W, H, [C(34, 22, 56), C(28, 18, 48), C(22, 14, 40), C(18, 12, 34)])

    # dua baris rak buku di belakang
    shelf(sc, rnd, 6, 54)
    shelf(sc, rnd, 56, 104)

    # jendela bulan kecil di kanan atas (di belakang gelembung ucapan)
    sc.rect(176, 8, 214, 48, OUT)
    sc.rect(178, 10, 212, 46, C(16, 20, 54))
    sc.rect(178, 10, 212, 46, C(18, 24, 64))
    sc.ell(200, 26, 7, 7, C(255, 240, 200))
    sc.ell(203, 24, 6, 6, C(18, 24, 64))
    for _ in range(12):
        x, y = rnd.randint(180, 210), rnd.randint(12, 44)
        if sc.g[y][x] == C(18, 24, 64):
            sc.set(x, y, CREAM)
    sc.rect(194, 10, 196, 46, OUT)
    sc.rect(178, 28, 212, 30, OUT)

    # meja perpustakaan memanjang dan lilin di kedua sisi
    sc.rect(0, 104, W, 108, OUT)
    sc.rect(0, 108, W, 130, OUT)
    sc.rect(0, 109, W, 129, C(104, 64, 48))
    sc.rect(0, 109, W, 111, C(160, 108, 80))
    sc.rect(0, 126, W, 129, C(70, 42, 36))
    for x in range(20, W, 40):
        sc.rect(x, 114, x + 1, 124, C(84, 50, 40))
    candle(sc, 14, 84)
    candle(sc, W - 15, 84)

    # karpet dengan pinggiran bermotif
    for y in range(132, H):
        for x in range(W):
            sc.set(x, y, C(36, 22, 58) if (x // 12 + (y - 132) // 12) % 2 == 0 else C(32, 20, 52))
    sc.rect(0, 132, W, 135, OUT)
    sc.rect(0, 133, W, 135, C(70, 44, 96))

    # panel "kunci memori" di area pad (0,40 sampai 0,92 tinggi layar)
    panel(sc, 8, 164, W - 8, 396)

    # margin bawah: pinggiran lantai
    sc.rect(0, 402, W, 406, OUT)
    sc.rect(0, 403, W, 405, C(70, 44, 96))
    for x in range(4, W, 10):
        sc.rect(x, 410, x + 4, 413, C(60, 38, 84))
    return sc


def save(sc, out, name, scale=SCALE, rgb=False):
    im = sc.image(scale)
    if rgb:
        im = im.convert('RGB')
    im.save(out / name, optimize=True)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/images/memory'
    out.mkdir(parents=True, exist_ok=True)
    save(stage_bg(), out, 'stage.png', rgb=True)
    for idx in range(9):
        save(pad(idx), out, f'pad_{idx}.png')
    save(heart(True), out, 'heart_on.png')
    save(heart(False), out, 'heart_off.png')
    print('aset Level 8 ditulis ke', out)


if __name__ == '__main__':
    main()
