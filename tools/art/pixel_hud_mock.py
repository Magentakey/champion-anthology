"""Mockup perkiraan HUD Level 2, 3, 4 bergaya piksel (dari proporsi tata letak game; bukan tangkapan layar).

    python tools/art/pixel_hud_mock.py [folder_keluaran]
"""
import sys
from pathlib import Path

from PIL import Image

import pixel_scenes as ps
import pixel_ui_mock as m

C = ps.C
ROOT = ps.ROOT
W, H = 240, 426
PAPER, INK, CREAM, DARK, PANEL = m.PAPER, m.INK, m.CREAM, m.DARK, m.PANEL


def frac(v, total):
    return int(v * total)


def paste_img(sc, path, cx, cy, size, flip=False):
    pic = Image.open(path).convert('RGBA').resize((size, size), Image.NEAREST)
    for y in range(size):
        for x in range(size):
            px = pic.getpixel((x, y))
            if px[3]:
                sc.set(cx - size // 2 + x, cy - size // 2 + y, px[:3] + (255,))


def bubble(sc, text):
    x, y = frac(0.52, W), frac(0.10, H)
    lines = m.wrap(text, (W - 12 - x - 10) // 6)
    h = len(lines) * 9 + 10
    m.frame(sc, x, y, W - 12 - x, h, PAPER)
    for j, ln in enumerate(lines):
        sc.text(x + 6, y + 6 + j * 9, ln, color=INK)


def time_bar(sc, y, frac_left):
    x0, x1 = 16, W - 16
    sc.rect(x0, y, x1, y + 8, ps.OUT)
    sc.rect(x0 + 1, y + 1, x1 - 1, y + 7, C(80, 70, 110))
    n = 24
    bw = (x1 - x0 - 2 - (n - 1)) / n
    lit = int(frac_left * n + 0.999)
    col = C(60, 124, 224) if frac_left > 0.3 else C(224, 60, 60)
    for i in range(lit):
        a = x0 + 1 + int(i * (bw + 1))
        sc.rect(a, y + 1, a + int(bw), y + 7, col)


def top_bar(sc, step, extra):
    sc.text(16, 10, f'STEP {step}/3', color=CREAM)
    extra(sc)


def genius():
    sc = ps.menu_bg()
    top_bar(sc, 2, lambda s: [m.icon(s, 82 + i * 11, 8, ['.##.##.', '#######', '#######', '.#####.', '..###..', '...#...'],
                                      lambda _c, f=i < 2: C(226, 54, 54) if f else C(80, 70, 110)) for i in range(3)] or s.text(126, 10, '1/4', color=CREAM))
    paste_img(sc, ROOT / 'assets/images/genius/boss_idle.png', frac(0.30, W), frac(0.19, H), 94)
    bubble(sc, 'Hmph, soal mudah saja!')
    qy, qh = frac(0.33, H), frac(0.19, H)
    m.frame(sc, 16, qy, W - 32, qh, PAPER)
    sc.text(W // 2 - sc.text_w('MATEMATIKA', 1) // 2, qy + 8, 'MATEMATIKA', color=C(110, 90, 150))
    ql = m.wrap('Berapa hasil dari 12 x 7 dikurangi 9?', 34)
    for j, ln in enumerate(ql):
        m.text_c(sc, W // 2, qy + 22 + j * 10, ln, color=INK)
    time_bar(sc, frac(0.565, H), 0.62)
    ay, ab = frac(0.60, H), frac(0.95, H)
    gap = 6
    bw, bh = (W - 32 - gap) // 2, (ab - ay - gap) // 2
    opts = ['75', '84', '72', '91']
    for i, o in enumerate(opts):
        x = 16 + (i % 2) * (bw + gap)
        y = ay + (i // 2) * (bh + gap)
        fill = C(143, 212, 143) if i == 0 else PAPER
        m.frame(sc, x, y, bw, bh, fill)
        m.text_c(sc, x + bw // 2, y + bh // 2 - 4, o, scale=2, color=INK)
    return sc


def maze():
    sc = ps.menu_bg()
    sc.text(16, 10, 'STEP 2/3', color=CREAM)
    sc.text(96, 8, '47S', scale=2, color=CREAM, outline=ps.OUT)
    paste_img(sc, ROOT / 'assets/images/maze/boss_idle.png', frac(0.30, W), frac(0.19, H), 94)
    bubble(sc, 'Tik tok... tersesat, ya?')
    time_bar(sc, frac(0.335, H), 0.78)
    top, hh = frac(0.365, H), frac(0.36, H)
    cols, rows = 11, 9
    cell = min((W - 32 - 12) // cols, (hh - 12) // rows)
    bw, bh = cell * cols, cell * rows
    bx, by = (W - bw) // 2, top + (hh - bh) // 2
    m.frame(sc, bx - 6, by - 6, bw + 12, bh + 12, PAPER)
    sc.rect(bx, by, bx + cell, by + cell, C(200, 230, 201))
    sc.rect(bx + bw - cell, by + bh - cell, bx + bw, by + bh, C(255, 243, 196))
    import random
    r = random.Random(5)
    for i in range(cols + 1):
        sc.line((bx + i * cell, by), (bx + i * cell, by + bh), C(40, 30, 60)) if i in (0, cols) else None
    for j in (0, rows):
        sc.line((bx, by + j * cell), (bx + bw, by + j * cell), C(40, 30, 60))
    for _ in range(36):
        x, y = r.randint(1, cols - 1), r.randint(0, rows - 1)
        sc.line((bx + x * cell, by + y * cell), (bx + x * cell, by + y * cell + cell), C(40, 30, 60))
    for _ in range(30):
        x, y = r.randint(0, cols - 1), r.randint(1, rows - 1)
        sc.line((bx + x * cell, by + y * cell), (bx + x * cell + cell, by + y * cell), C(40, 30, 60))
    sc.text(bx + bw - cell + 2, by + bh - cell + 2, '*', color=C(255, 193, 7))
    sc.rect(bx + 2 * cell + 2, by + 2 * cell + 2, bx + 3 * cell - 2, by + 3 * cell - 2, C(255, 214, 170))
    sc.rect(bx + 2 * cell + 2, by + 2 * cell + 2, bx + 3 * cell - 2, by + 2 * cell + 4, C(226, 54, 54))
    pad_top, pad_bot = frac(0.745, H), frac(0.97, H)
    b = min((pad_bot - pad_top - 12) // 3, 60)
    cx = W // 2
    arrows = {'up': (cx - b // 2, pad_top), 'left': (cx - b // 2 - b - 6, pad_top + b + 6),
              'right': (cx - b // 2 + b + 6, pad_top + b + 6), 'down': (cx - b // 2, pad_top + 2 * (b + 6))}
    pats = {'up': ['...#...', '..###..', '.#####.', '#######', '..###..', '..###..', '..###..'],
            'down': ['..###..', '..###..', '..###..', '#######', '.#####.', '..###..', '...#...'],
            'left': ['...#...', '..##...', '.###...', '#######', '.###...', '..##...', '...#...'],
            'right': ['...#...', '...##..', '...###.', '#######', '...###.', '...##..', '...#...']}
    for name, (x, y) in arrows.items():
        m.frame(sc, x, y, b, b, PANEL if name != 'up' else C(138, 116, 192))
        m.icon(sc, x + b // 2 - 4, y + b // 2 - 4, pats[name], lambda _c: CREAM)
    return sc


def cooking():
    sc = ps.Scene(W, H)
    bg = Image.open(ROOT / 'assets/images/cooking/kitchen_bg.png').convert('RGB')
    bg = bg.resize((W, int(H * 1.0 * (1600 / 1600) * 1)), Image.NEAREST) if False else bg.resize((213, 426), Image.NEAREST)
    for y in range(H):
        for x in range(W):
            sx = min(212, max(0, x - 13))
            sc.set(x, y, bg.getpixel((sx, y)) + (255,))
    sc.text(16, 10, 'STEP 2/3', color=CREAM)
    sc.text(100, 8, '38S', scale=2, color=CREAM, outline=ps.OUT)
    paste_img(sc, ROOT / 'assets/images/cooking/boss_idle.png', frac(0.30, W), frac(0.19, H), 94)
    bubble(sc, 'Hmph, lumayan.')
    oy, oh = frac(0.31, H), frac(0.125, H)
    m.frame(sc, 16, oy, W - 32, oh, PAPER)
    sc.text(22, oy + 5, 'PESANAN: SOP SAYUR', color=INK)
    names = [('wortel', 'WORTEL', 'IRIS', C(165, 214, 167)), ('kentang', 'KENTANG', 'REBUS', C(144, 202, 249)),
             ('jagung', 'JAGUNG', 'REBUS', C(144, 202, 249)), ('bayam', 'BAYAM', 'REBUS', C(144, 202, 249))]
    for i, (f, n, v, col) in enumerate(names):
        x = 24 + i * 50
        pic = Image.open(ROOT / f'assets/images/cooking/ing_{f}.png').convert('RGBA').resize((20, 20), Image.NEAREST)
        for yy in range(20):
            for xx in range(20):
                px = pic.getpixel((xx, yy))
                if px[3]:
                    sc.set(x + xx + 4, oy + 16 + yy, px[:3] + (255,))
        sc.text(x, oy + 38, n[:6], color=INK)
        sc.rect(x, oy + 47, x + 6 * len(v) + 2, oy + 56, col)
        sc.text(x + 1, oy + 48, v, color=INK)
    time_bar(sc, frac(0.452, H), 0.6)
    sy, sh = frac(0.48, H), frac(0.265, H)
    sw = (W - 32 - 12) // 3
    for i, (n, v) in enumerate((('TALENAN', 'IRIS'), ('PANCI', 'REBUS'), ('WAJAN', 'GORENG'))):
        x = 16 + i * (sw + 6)
        m.frame(sc, x, sy, sw, sh, PAPER)
        pic = Image.open(ROOT / f'assets/images/cooking/station_{["chop", "boil", "fry"][i]}.png').convert('RGBA').resize((sw - 10, sw - 10), Image.NEAREST)
        for yy in range(pic.height):
            for xx in range(pic.width):
                px = pic.getpixel((xx, yy))
                if px[3]:
                    sc.set(x + 5 + xx, sy + 6 + yy, px[:3] + (255,))
        m.text_c(sc, x + sw // 2, sy + sh - 22, n, color=INK)
        m.text_c(sc, x + sw // 2, sy + sh - 12, f'({v})', color=C(110, 90, 150))
    ty = frac(0.765, H)
    m.frame(sc, 16, ty, W - 32, frac(0.97, H) - ty, PANEL)
    for i, f in enumerate(['tomat', 'mi', 'tempe', 'bawang', 'ikan', 'kentang']):
        x = 22 + (i % 4) * 52
        y = ty + 6 + (i // 4) * 38
        pic = Image.open(ROOT / f'assets/images/cooking/ing_{f}.png').convert('RGBA').resize((32, 32), Image.NEAREST)
        for yy in range(32):
            for xx in range(32):
                px = pic.getpixel((xx, yy))
                if px[3]:
                    sc.set(x + 8 + xx, y + yy, px[:3] + (255,))
    return sc


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'docs' / 'preview'
    out.mkdir(parents=True, exist_ok=True)
    imgs = [genius().image(3).convert('RGB'), maze().image(3).convert('RGB'), cooking().image(3).convert('RGB')]
    sheet = Image.new('RGB', (720 * 3 + 40, 1278), (30, 30, 30))
    for i, im in enumerate(imgs):
        sheet.paste(im, (i * 740, 0))
    sheet.save(out / 'hud_pixel.png')
    print('mockup HUD ditulis ke', out)


if __name__ == '__main__':
    main()
