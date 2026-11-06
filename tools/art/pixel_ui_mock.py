"""Mockup layar pilih level dan intro boss (perkiraan tampilan Flutter, hanya untuk dilihat).

    python tools/art/pixel_ui_mock.py [folder_keluaran]
"""
import sys
from pathlib import Path

from PIL import Image

import pixel_kit as k
import pixel_scenes as ps

C = ps.C
ROOT = ps.ROOT
CREAM, DARK, PAPER, INK, PANEL = C(255, 244, 214), C(26, 20, 44), C(250, 240, 214), C(40, 30, 60), C(58, 48, 80)
GOLD, GOLD_OUT = C(255, 214, 64), C(150, 30, 50)

STAR = ['...#...', '..###..', '#######', '.#####.', '..###..', '.##.##.', '.#...#.']
LOCK = ['..####..', '.##..##.', '.#....#.', '########', '########', '###kk###', '###kk###', '########', '########']


def icon(sc, x, y, rows, color_of):
    def filled(i, j):
        return 0 <= j < len(rows) and 0 <= i < len(rows[0]) and rows[j][i] != '.'
    for j in range(-1, len(rows) + 1):
        for i in range(-1, len(rows[0]) + 1):
            if filled(i, j):
                sc.set(x + i, y + j, color_of(rows[j][i]))
            elif filled(i - 1, j) or filled(i + 1, j) or filled(i, j - 1) or filled(i, j + 1):
                sc.set(x + i, y + j, ps.OUT)


def frame(sc, x, y, w, h, fill):
    sc.rect(x, y, x + w, y + h, CREAM)
    sc.rect(x + 1, y + 1, x + w - 1, y + h - 1, DARK)
    sc.rect(x + 2, y + 2, x + w - 2, y + h - 2, fill)


def text_c(sc, cx, y, s, **kw):
    sc.text(cx - sc.text_w(s, kw.get('scale', 1)) // 2, y, s, **kw)


def wrap(s, n):
    out = []
    for para in s.split('\n'):
        cur = ''
        for wd in para.split():
            if len((cur + ' ' + wd).strip()) <= n:
                cur = (cur + ' ' + wd).strip()
            else:
                out.append(cur)
                cur = wd
        out.append(cur)
    return out


def level_select(stars, unlocked):
    sc = ps.menu_bg()
    sc.text(6, 8, '< KEMBALI', color=C(190, 180, 220))
    text_c(sc, 120, 32, 'KALAHKAN MEREKA!', scale=2, color=GOLD, outline=GOLD_OUT, shadow=DARK)
    for i in range(9):
        x, y = 12 + (i % 3) * 76, 80 + (i // 3) * 90
        n = stars.get(i, 0)
        for s in range(3):
            icon(sc, x + 18 + s * 11, y, STAR, lambda _c, f=s < n: C(255, 214, 64) if f else C(80, 70, 110))
        ty = y + 12
        is_open = i in unlocked
        frame(sc, x, ty, 64, 64, PAPER if is_open else PANEL)
        if is_open:
            text_c(sc, x + 32, ty + 22, str(i + 1), scale=3, color=INK)
        elif i < 4:
            icon(sc, x + 28, ty + 25, LOCK, lambda c: DARK if c == 'k' else C(168, 160, 200))
    return sc


def boss_intro(name, dialog, tip, img):
    sc = ps.menu_bg()
    sc.text(6, 8, '< KEMBALI', color=C(190, 180, 220))
    frame(sc, 12, 30, 216, 24, DARK)
    scale = 2 if len(name) * 12 <= 200 else 1
    text_c(sc, 120, 38 if scale == 2 else 41, name.upper(), scale=scale, color=GOLD, outline=GOLD_OUT)
    pic = Image.open(img).convert('RGBA').resize((120, 120), Image.NEAREST)
    for y in range(120):
        for x in range(120):
            px = pic.getpixel((x, y))
            if px[3]:
                sc.set(60 + x, 72 + y, px[:3] + (255,))
    lines = wrap(dialog, 32)
    frame(sc, 12, 198, 216, len(lines) * 9 + 12, PAPER)
    for j, ln in enumerate(lines):
        text_c(sc, 120, 204 + j * 9, ln, color=INK)
    tl = wrap(tip, 32)
    frame(sc, 12, 262, 216, len(tl) * 9 + 12, DARK)
    for j, ln in enumerate(tl):
        text_c(sc, 120, 268 + j * 9, ln, color=CREAM)
    bx = 67
    sc.rect(bx + 2, 366 + 2, bx + 106, 366 + 28, C(24, 16, 44))
    sc.rect(bx, 366, bx + 104, 392, ps.OUT)
    sc.rect(bx + 1, 367, bx + 103, 391, C(226, 64, 56))
    sc.rect(bx + 1, 367, bx + 103, 369, C(255, 130, 108))
    sc.rect(bx + 1, 388, bx + 103, 391, C(160, 30, 44))
    text_c(sc, bx + 52, 372, 'MULAI', scale=2, color=CREAM, outline=ps.OUT)
    return sc


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'docs' / 'preview'
    out.mkdir(parents=True, exist_ok=True)
    level_select({0: 1, 1: 2}, {0, 1}).image(3).convert('RGB').save(out / 'level_select_pixel.png')
    boss_intro('Asep the Mazelogist', 'Selamat datang...\nIngin merebut gelarku?\nIkuti aku...',
               'Tahan tombol arah untuk jalan terus, ketuk untuk satu langkah. Capai bintang emas sebelum waktu habis!',
               ROOT / 'assets/images/maze/boss_idle.png').image(3).convert('RGB').save(out / 'boss_intro_pixel.png')
    print('mockup ditulis ke', out)


if __name__ == '__main__':
    main()
