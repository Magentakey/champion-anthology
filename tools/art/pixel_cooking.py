"""Aset Level 4 (Cooking Champion) bergaya piksel: 16 ikon bahan, 3 stasiun, latar dapur.

    python tools/art/pixel_cooking.py [folder_keluaran]
Menimpa assets/images/cooking/ing_*.png (128x128 = kisi 32 x4), station_*.png (256x256 = kisi 64 x4)
dan kitchen_bg.png (800x1600 = kisi 200x400 x4). Gambar chef dibuat oleh pixel_bosses.py.
"""
import random
import sys
from pathlib import Path

from PIL import Image

import pixel_kit as k
import pixel_scenes as ps

ROOT = ps.ROOT
P = k.pal


def rgba(r, g, b):
    return (r, g, b, 255)


GREEN = P((90, 170, 90))
GREEN_D = P((46, 125, 50))
RED_T = P((229, 57, 53))
YELLOW = P((255, 213, 79))
CREAM = P((255, 248, 225))
WOOD = P((188, 143, 99))
BROWN_D = P((121, 85, 72))
GREY_M = P((176, 190, 197))
GREY_D = P((96, 108, 118))
ORANGE = P((251, 140, 0))
WHITE = P((244, 246, 252))


def cv(s=32):
    return k.Canvas(s, 0, 0)


# ---------------- ikon bahan (kisi 32) ----------------
def bawang():
    c = cv()
    c.paint(c.poly([(16, 3), (12.5, 11), (19.5, 11)]), GREEN)
    c.paint(c.ell(16, 19, 10, 9), P((171, 71, 188)))
    for dx in (-5, 0, 5):
        c.line((16 + dx // 2, 13), (16 + dx, 26), rgba(123, 31, 162))
    return c


def tomat():
    c = cv()
    c.paint(c.ell(16, 18, 11, 9.5), RED_T)
    c.paint(c.poly([(10, 11), (14, 9.5), (16, 6), (18, 9.5), (22, 11), (18, 12.5), (16, 15), (14, 12.5)]), GREEN)
    return c


def wortel():
    c = cv()
    for (x, y) in ((17, 5), (21, 6), (25, 8)):
        c.paint(c.ell(x, y, 2.2, 3.8), GREEN, shade=False)
    c.paint(c.poly([(13, 8), (27, 14), (5, 28)]), ORANGE)
    for p0, p1 in (((14, 12), (18, 14)), ((11, 17), (15, 19)), ((8, 22), (11, 23))):
        c.line(p0, p1, rgba(214, 100, 0))
    return c


def cabai():
    c = cv()
    c.paint(c.tube([(8, 8), (15, 11), (22, 17), (25, 26)], 7), RED_T)
    c.paint(c.ell(8, 8, 3, 3), GREEN)
    return c


def sawi():
    c = cv()
    c.paint(c.rect(14, 24, 18, 29), P((220, 237, 200)))
    for (x, y, rx, ry) in ((11, 17, 6, 10), (21, 17, 6, 10), (16, 14, 6.5, 11)):
        c.paint(c.ell(x, y, rx, ry), GREEN)
    c.line((16, 22), (16, 8), rgba(220, 237, 200))
    return c


def telur():
    c = cv()
    c.paint(c.ell(16, 17, 8.5, 10.5), CREAM)
    return c


def kentang():
    c = cv()
    c.paint(c.ell(16, 18, 12, 9), WOOD)
    for x, y in ((11, 16), (18, 13), (21, 20), (14, 21), (24, 16)):
        c.put(x, y, BROWN_D[0])
    return c


def mi():
    c = cv()
    c.paint(c.poly([(5, 21), (27, 21), (23, 29), (9, 29)]), P((60, 104, 204)))
    c.paint(c.ell(16, 18, 10.5, 7), P((255, 224, 130)))
    for x0, y0 in ((10, 15), (15, 13), (20, 16), (12, 19), (18, 19)):
        c.line((x0, y0), (x0 + 3, y0 + 1), rgba(214, 160, 40))
    return c


def jagung():
    c = cv()
    c.paint(c.poly([(16, 28), (7, 14), (12, 4), (16, 26)]), GREEN)
    c.paint(c.poly([(16, 28), (25, 14), (20, 4), (16, 26)]), GREEN)
    c.paint(c.ell(16, 15, 6.5, 11.5), YELLOW)
    for r in range(5):
        for q in range(3):
            c.put(13 + q * 3, 8 + r * 4, (255, 160, 0, 255))
    return c


def bayam():
    c = cv()
    c.line((16, 29), (16, 17), rgba(46, 125, 50), th=2)
    for (x, y, rx, ry) in ((10, 15, 5, 8.5), (22, 15, 5, 8.5), (16, 9, 5, 8)):
        c.paint(c.ell(x, y, rx, ry), GREEN_D)
    return c


def tempe():
    c = cv()
    c.paint(c.rect(3, 10, 29, 24), P((215, 190, 140)))
    c.paint(c.rect(3, 10, 29, 13), P((236, 220, 180)), outline=False)
    rnd = random.Random(7)
    for _ in range(14):
        c.put(rnd.randint(5, 27), rnd.randint(14, 22), (120, 100, 70, 255))
    return c


def tahu():
    c = cv()
    c.paint(c.poly([(5, 12), (16, 18), (16, 29), (5, 22)]), P((255, 245, 200)))
    c.paint(c.poly([(16, 18), (27, 12), (27, 22), (16, 29)]), P((255, 236, 170)))
    c.paint(c.poly([(5, 12), (16, 6), (27, 12), (16, 18)]), P((255, 252, 225)))
    return c


def ayam():
    c = cv()
    c.paint(c.tube([(14, 16), (6, 25)], 3.4), WHITE)
    c.paint(c.ell(4.5, 25, 2.8, 2.8), WHITE)
    c.paint(c.ell(7.5, 28, 2.8, 2.8), WHITE)
    c.paint(c.ell(19, 12, 10, 8), P((214, 128, 52)))
    return c


def ikan():
    c = cv()
    c.paint(c.poly([(22, 16), (30, 8), (28, 16), (30, 24)]), P((120, 144, 156)))
    c.paint(c.ell(14, 16, 11, 7), GREY_M)
    c.put(8, 14, (255, 255, 255, 255))
    c.put(7, 14, k.OUT)
    for x in (14, 18):
        c.line((x, 12), (x + 1, 20), rgba(120, 144, 156))
    return c


def pisang():
    c = cv()
    c.paint(c.tube([(6, 9), (9, 20), (18, 26), (27, 20)], 7), YELLOW)
    c.paint(c.rect(4, 3, 8, 8), BROWN_D)
    return c


def nasi():
    c = cv()
    c.paint(c.ell(16, 17, 11, 8), WHITE)
    for x, y in ((11, 15), (16, 12), (21, 16), (14, 20), (19, 19)):
        c.line((x - 1, y), (x + 1, y), rgba(190, 196, 214))
    c.paint(c.poly([(4, 21), (28, 21), (24, 29), (8, 29)]), RED_T)
    return c


INGREDIENTS = {
    'bawang': bawang, 'tomat': tomat, 'wortel': wortel, 'cabai': cabai, 'sawi': sawi, 'telur': telur,
    'kentang': kentang, 'mi': mi, 'jagung': jagung, 'bayam': bayam, 'tempe': tempe, 'tahu': tahu,
    'ayam': ayam, 'ikan': ikan, 'pisang': pisang, 'nasi': nasi,
}


# ---------------- stasiun (kisi 64) ----------------
SHADOW = rgba(176, 176, 190)


def floor_shadow(c, cx, cy, rx):
    for x in range(cx - rx, cx + rx + 1):
        c.put(x, cy, SHADOW)
        if abs(x - cx) < rx - 3:
            c.put(x, cy + 1, SHADOW)


def station_chop():
    c = cv(64)
    floor_shadow(c, 32, 56, 26)
    c.paint(c.poly([(8, 24), (52, 18), (56, 46), (12, 52)]), WOOD)
    c.paint(c.ell(51, 24, 2.5, 2.5), P((224, 224, 224)), shade=False)
    for x, y in ((20, 44), (30, 46), (42, 41)):
        c.put(x, y, BROWN_D[0])
        c.put(x + 1, y, BROWN_D[0])
    c.paint(c.poly([(16, 26), (40, 22), (41, 30), (17, 34)]), GREY_M)
    c.paint(c.poly([(40, 22), (52, 20), (53, 27), (41, 30)]), BROWN_D)
    return c


def station_boil():
    c = cv(64)
    floor_shadow(c, 32, 58, 26)
    for x in (22, 32, 42):
        for i, y in enumerate(range(8, 24, 3)):
            c.put(x + (1 if i % 2 else -1), y, rgba(200, 200, 214))
            c.put(x + (1 if i % 2 else -1), y + 1, rgba(200, 200, 214))
    c.paint(c.rect(10, 29, 54, 53), GREY_M)
    c.paint(c.ell(32, 29, 22, 5.5), P((144, 202, 249)))
    for x, y in ((24, 29), (34, 28), (43, 30)):
        c.paint(c.ell(x, y, 2.2, 2.2), WHITE, shade=False)
    c.paint(c.rect(4, 34, 10, 40), GREY_D)
    c.paint(c.rect(54, 34, 60, 40), GREY_D)
    return c


def station_fry():
    c = cv(64)
    floor_shadow(c, 30, 58, 28)
    for x in (18, 30, 42):
        c.paint(c.poly([(x - 4, 55), (x, 45), (x + 4, 55)]), ORANGE)
    c.paint(c.ell(30, 37, 24, 10), P((55, 62, 70)))
    c.paint(c.ell(30, 35, 19, 7), P((255, 193, 7)))
    c.paint(c.ell(24, 33, 5, 2), P((255, 236, 130)), shade=False, outline=False)
    c.paint(c.poly([(52, 37), (62, 32), (63, 37), (53, 42)]), BROWN_D)
    return c


# ---------------- latar dapur (kisi 200x400) ----------------
def kitchen():
    W, H = 200, 400
    sc = ps.Scene(W, H)
    for y in range(0, 185):
        for x in range(W):
            tile_edge = (x % 25 == 0) or (y % 25 == 0)
            if tile_edge:
                sc.set(x, y, ps.C(255, 214, 160))
            elif x % 25 == 1 or y % 25 == 1:
                sc.set(x, y, ps.C(255, 250, 238))
            else:
                sc.set(x, y, ps.C(255, 243, 224))
    # rel gantung dan alat dapur
    sc.rect(0, 29, W, 32, k.OUT)
    for x in range(0, W, 12):
        sc.set(x, 32, k.OUT)
    for x, kind in ((118, 'ladle'), (140, 'pan'), (162, 'whisk'), (183, 'pot')):
        sc.line((x, 32), (x, 36), k.OUT)
        if kind == 'ladle':
            sc.line((x, 36), (x, 56), k.BROWN[0], th=2)
            sc.ell(x + 1, 61, 5, 5, k.OUT)
            sc.ell(x + 1, 61, 4, 4, ps.C(176, 190, 197))
        elif kind == 'pan':
            sc.line((x, 36), (x, 47), k.BROWN[0], th=2)
            sc.ell(x + 1, 55, 9, 9, k.OUT)
            sc.ell(x + 1, 55, 8, 8, ps.C(55, 62, 70))
        elif kind == 'whisk':
            sc.line((x, 36), (x, 47), k.BROWN[0], th=2)
            sc.ell(x + 1, 56, 4, 9, k.OUT)
            sc.ell(x + 1, 56, 2.6, 7.6, ps.C(255, 243, 224))
        else:
            sc.rect(x - 7, 38, x + 8, 53, k.OUT)
            sc.rect(x - 6, 39, x + 7, 52, ps.C(176, 190, 197))
    # meja dan lemari
    top = 185
    sc.rect(0, top, W, top + 9, k.OUT)
    sc.rect(0, top + 1, W, top + 8, ps.C(224, 224, 224))
    sc.rect(0, top + 1, W, top + 2, ps.C(250, 250, 250))
    for y in range(top + 9, H):
        for x in range(W):
            sc.set(x, y, ps.C(188, 143, 99) if (y + x // 3) % 7 else ps.C(176, 132, 90))
    for i in range(4):
        x0 = i * 50 + 3
        sc.rect(x0, top + 17, x0 + 44, H - 5, k.OUT)
        sc.rect(x0 + 1, top + 18, x0 + 43, H - 6, ps.C(205, 163, 120))
        sc.rect(x0 + 1, top + 18, x0 + 43, top + 20, ps.C(226, 190, 150))
        sc.rect(x0 + 18, top + 24, x0 + 28, top + 27, k.OUT)
        sc.rect(x0 + 19, top + 25, x0 + 27, top + 26, ps.C(96, 108, 118))
    return sc


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/images/cooking'
    out.mkdir(parents=True, exist_ok=True)
    for name, fn in INGREDIENTS.items():
        canvas_to_image(fn(), 4).save(out / f'ing_{name}.png', optimize=True)
    for name, fn in (('chop', station_chop), ('boil', station_boil), ('fry', station_fry)):
        canvas_to_image(fn(), 4).save(out / f'station_{name}.png', optimize=True)
    kitchen().image(4).convert('RGB').save(out / 'kitchen_bg.png', optimize=True)
    print('aset Level 4 piksel ditulis ke', out)


def canvas_to_image(c, scale):
    im = Image.new('RGBA', (c.s, c.s), (0, 0, 0, 0))
    for y in range(c.s):
        for x in range(c.s):
            if c.g[y][x]:
                im.putpixel((x, y), c.g[y][x])
    return im.resize((c.s * scale, c.s * scale), Image.NEAREST)


if __name__ == '__main__':
    main()
