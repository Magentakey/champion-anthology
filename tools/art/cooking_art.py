"""Aset gambar Level 4 (Cooking Champion): chef, ikon bahan, stasiun masak, latar dapur.

Dipanggil dari generate_art.py (python tools/art/generate_art.py), atau sendiri:
    python tools/art/cooking_art.py
"""
import math
import random

from PIL import Image, ImageDraw

import generate_art as ga
from generate_art import Art, BLACK, WHITE, ROOT, catmull, ribbon

OUT = ROOT / 'assets/images/cooking'

RED_T = (214, 40, 40, 255)
ORANGE_C = (251, 140, 0, 255)
GREEN_L = (102, 187, 106, 255)
GREEN_D = (46, 125, 50, 255)
YELLOW = (255, 213, 79, 255)
CREAM = (255, 248, 225, 255)
BROWN_L = (188, 143, 99, 255)
BROWN_D = (121, 85, 72, 255)
GREY_M = (176, 190, 197, 255)
GREY_D = (96, 108, 118, 255)
PURPLE = (171, 71, 188, 255)


# ---------------- chef ----------------
ga.FACES.update({
    'chef_idle': dict(eyes='open', brows='up_soft', mouth='grin'),
    'chef_shock': dict(eyes='wide', brows='up', mouth='o', extra='sweat'),
    'chef_laugh': dict(eyes='happy', brows='up_soft', mouth='laugh', extra='tears'),
    'chef_defeat': dict(eyes='x', brows='sad', mouth='wavy', extra='stars'),
})


def draw_ladle(a, hand, s):
    """Sendok sayur dipegang tangan depan: gagang miring ke atas, mangkuk di ujung."""
    x, y = hand
    tip = (x + 70 * s, y - 250 * s)
    a.line([(x, y), tip], 14 * s, BROWN_D)
    a.circle((tip[0] + 8 * s, tip[1] - 8 * s), 46 * s, fill=GREY_M, outline=BLACK, width=7 * s)
    a.circle((tip[0] + 8 * s, tip[1] - 8 * s), 26 * s, fill=GREY_D)


def gen_chef():
    sets = {
        'boss_idle.png': ('c_stand', 'chef_idle', True),
        'boss_shock.png': ('b_shock', 'chef_shock', False),
        'boss_laugh.png': ('b_laugh', 'chef_laugh', False),
        'boss_defeat.png': ('b_defeat', 'chef_defeat', False),
    }
    for fname, (pose, face, ladle) in sets.items():
        a = Art(512, 512)
        s, ox, oy = 0.40, 51, 40       # topi koki menambah tinggi: sedikit lebih kecil dan turun
        draw_figure_chef(a, pose, face, ox, oy, s)
        if ladle:
            hand = ga.POSES[pose]['arm_f'][-1]
            draw_ladle(a, (ox + hand[0] * s, oy + hand[1] * s), s)
        a.save(OUT / fname)


def draw_figure_chef(a, pose, face, ox, oy, s):
    ga.draw_figure(a, pose, face, ox, oy, s, lw=22, acc=('chef',))


# ---------------- ikon bahan (128 x 128, garis hitam, warna datar) ----------------
W = 128
LW = 5


def icon():
    return Art(W, W)


def outline(a, pts, fill):
    a.poly(pts, fill=fill, outline=BLACK, width=LW)


def ing_bawang():
    a = icon()
    a.poly([(64, 14), (50, 40), (78, 40)], fill=GREEN_L, outline=BLACK, width=LW)
    a.ellipse_rot((64, 76), 42, 42, fill=PURPLE, outline=BLACK, width=LW)
    for dx in (-18, 0, 18):
        a.line(catmull([(64 + dx * 0.4, 38), (64 + dx * 1.1, 76), (64 + dx * 0.5, 114)], 8), 3, (123, 31, 162, 255))
    return a


def ing_tomat():
    a = icon()
    a.ellipse_rot((64, 72), 46, 40, fill=(229, 57, 53, 255), outline=BLACK, width=LW)
    star = []
    for i in range(10):
        r = 20 if i % 2 == 0 else 8
        ang = -math.pi / 2 + i * math.pi / 5
        star.append((64 + r * math.cos(ang), 38 + r * 0.7 * math.sin(ang)))
    outline(a, star, GREEN_L)
    return a


def ing_wortel():
    a = icon()
    for dx in (-14, 0, 14):
        a.ellipse_rot((78 + dx * 0.6, 22), 8, 18, ang=0.5 + dx * 0.03, fill=GREEN_L, outline=BLACK, width=3)
    outline(a, [(40, 34), (98, 54), (20, 112)], ORANGE_C)
    for p0, p1 in [((52, 56), (64, 60)), ((42, 74), (56, 80)), ((32, 92), (44, 98))]:
        a.line([p0, p1], 3, (230, 81, 0, 255))
    return a


def ing_cabai():
    a = icon()
    pts = catmull([(34, 34), (62, 44), (92, 66), (100, 96), (90, 114)], 10)
    outline(a, ribbon(pts, 34, 6), (229, 57, 53, 255))
    a.line([(34, 34), (24, 18)], 8, GREEN_D)
    a.circle((34, 34), 11, fill=GREEN_L, outline=BLACK, width=4)
    return a


def ing_sawi():
    a = icon()
    for cx, cy, ang in [(46, 70, 0.5), (82, 70, -0.5), (64, 56, 0)]:
        a.ellipse_rot((cx, cy), 24, 42, ang=ang, fill=GREEN_L, outline=BLACK, width=LW)
        a.line([(cx - 10 * math.sin(ang), cy + 30), (cx + 14 * math.sin(ang), cy - 28)], 3, (220, 237, 200, 255))
    a.rect(54, 100, 74, 116, fill=(220, 237, 200, 255), outline=BLACK, width=4)
    return a


def ing_telur():
    a = icon()
    a.ellipse_rot((64, 70), 34, 44, fill=CREAM, outline=BLACK, width=LW)
    a.ellipse_rot((52, 54), 8, 14, ang=0.4, fill=WHITE)
    return a


def ing_kentang():
    a = icon()
    a.ellipse_rot((64, 72), 50, 36, ang=-0.3, fill=BROWN_L, outline=BLACK, width=LW)
    for x, y in [(44, 66), (70, 52), (84, 84), (58, 88), (96, 66)]:
        a.circle((x, y), 4, fill=BROWN_D)
    return a


def ing_mi():
    a = icon()
    a.ellipse_rot((64, 98), 46, 14, fill=(255, 224, 130, 255), outline=BLACK, width=LW)
    for i, x0 in enumerate((24, 40, 56, 72, 88)):
        pts = catmull([(x0, 98), (x0 + 12, 70), (x0 - 6, 46), (x0 + 12, 22)], 8)
        a.line(pts, 7, BLACK)
        a.line(pts, 3.5, YELLOW)
    return a


def ing_jagung():
    a = icon()
    for sgn in (-1, 1):
        outline(a, [(64, 120), (64 + sgn * 40, 60), (64 + sgn * 14, 14), (64, 110)], GREEN_L)
    a.ellipse_rot((64, 62), 22, 48, fill=YELLOW, outline=BLACK, width=LW)
    for r in range(5):
        for c in range(3):
            a.circle((52 + c * 12, 32 + r * 17), 3.5, fill=(255, 160, 0, 255))
    return a


def ing_bayam():
    a = icon()
    a.line([(64, 120), (64, 60)], 5, GREEN_D)
    for cx, cy, ang in [(40, 62, 0.9), (88, 62, -0.9), (64, 34, 0)]:
        a.ellipse_rot((cx, cy), 20, 34, ang=ang, fill=GREEN_D, outline=BLACK, width=LW)
    return a


def ing_tempe():
    a = icon()
    a.rect(14, 38, 114, 96, fill=(215, 190, 140, 255), outline=BLACK, width=LW)
    a.rect(14, 38, 114, 50, fill=(236, 220, 180, 255), outline=BLACK, width=LW)
    rnd = random.Random(7)
    for _ in range(18):
        a.circle((rnd.randint(22, 106), rnd.randint(56, 90)), 3, fill=(120, 100, 70, 255))
    return a


def ing_tahu():
    a = icon()
    top = [(24, 56), (64, 36), (110, 56), (70, 78)]
    left = [(24, 56), (70, 78), (70, 116), (24, 94)]
    right = [(70, 78), (110, 56), (110, 94), (70, 116)]
    outline(a, left, (255, 245, 200, 255))
    outline(a, right, (255, 236, 170, 255))
    outline(a, top, (255, 252, 225, 255))
    return a


def ing_ayam():
    a = icon()
    a.ellipse_rot((78, 54), 40, 32, ang=0.7, fill=(214, 128, 52, 255), outline=BLACK, width=LW)
    a.line([(52, 78), (28, 104)], 13, BLACK)
    a.line([(52, 78), (28, 104)], 8, WHITE)
    a.circle((20, 104), 9, fill=WHITE, outline=BLACK, width=4)
    a.circle((30, 114), 9, fill=WHITE, outline=BLACK, width=4)
    a.line(catmull([(58, 46), (74, 40), (88, 48)], 6), 3, (160, 90, 30, 255))
    return a


def ing_ikan():
    a = icon()
    outline(a, [(92, 64), (122, 36), (118, 64), (122, 92)], (120, 144, 156, 255))
    a.ellipse_rot((56, 64), 42, 28, fill=GREY_M, outline=BLACK, width=LW)
    a.circle((36, 58), 6, fill=WHITE, outline=BLACK, width=3)
    a.circle((35, 58), 2.5, fill=BLACK)
    for x in (56, 68, 80):
        a.line(catmull([(x, 50), (x + 6, 64), (x, 78)], 6), 3, (120, 144, 156, 255))
    return a


def ing_pisang():
    a = icon()
    pts = catmull([(24, 40), (44, 90), (84, 108), (112, 88)], 12)
    outline(a, ribbon(pts, 40, 26), YELLOW)
    a.line([(24, 40), (20, 24)], 10, BROWN_D)
    a.line(catmull([(40, 46), (56, 84), (84, 98)], 8), 3, (230, 180, 40, 255))
    return a


def ing_nasi():
    a = icon()
    a.ellipse_rot((64, 62), 44, 36, fill=WHITE, outline=BLACK, width=LW)
    for x, y in [(48, 54), (66, 44), (82, 58), (58, 68), (74, 72)]:
        a.line([(x - 5, y), (x + 5, y + 3)], 3, (200, 200, 200, 255))
    outline(a, [(18, 78), (110, 78), (96, 114), (32, 114)], (229, 57, 53, 255))
    return a


INGREDIENTS = {
    'bawang': ing_bawang, 'tomat': ing_tomat, 'wortel': ing_wortel, 'cabai': ing_cabai,
    'sawi': ing_sawi, 'telur': ing_telur, 'kentang': ing_kentang, 'mi': ing_mi,
    'jagung': ing_jagung, 'bayam': ing_bayam, 'tempe': ing_tempe, 'tahu': ing_tahu,
    'ayam': ing_ayam, 'ikan': ing_ikan, 'pisang': ing_pisang, 'nasi': ing_nasi,
}


def gen_ingredients():
    for name, fn in INGREDIENTS.items():
        fn().save(OUT / f'ing_{name}.png')


# ---------------- stasiun (256 x 256) ----------------
def gen_stations():
    # talenan + pisau
    a = Art(256, 256)
    a.shadow((128, 214), 100, 12)
    a.poly(ga.ribbon([(36, 150), (220, 130)], 110, 110), fill=BROWN_L, outline=BLACK, width=7)
    a.circle((214, 138), 10, fill=(255, 235, 238, 255), outline=BLACK, width=5)
    a.poly([(60, 118), (170, 100), (176, 134), (60, 146)], fill=GREY_M, outline=BLACK, width=6)
    a.poly([(170, 100), (214, 96), (216, 118), (176, 134)], fill=BROWN_D, outline=BLACK, width=6)
    for x, y in [(80, 176), (130, 184), (176, 170)]:
        a.circle((x, y), 5, fill=BROWN_D)
    a.save(OUT / 'station_chop.png')

    # panci berisi air mendidih + uap
    a = Art(256, 256)
    a.shadow((128, 222), 96, 12)
    for x in (92, 128, 164):
        a.line(catmull([(x, 70), (x - 12, 52), (x + 12, 34), (x, 16)], 8), 6, (200, 200, 210, 255))
    a.rect(40, 100, 216, 200, fill=GREY_M, outline=BLACK, width=7)
    a.ellipse_rot((128, 100), 88, 22, fill=(144, 202, 249, 255), outline=BLACK, width=7)
    for x, y in [(98, 100), (140, 96), (170, 104)]:
        a.circle((x, y), 7, fill=WHITE, outline=BLACK, width=3)
    a.rect(18, 120, 40, 138, fill=GREY_D, outline=BLACK, width=6)
    a.rect(216, 120, 238, 138, fill=GREY_D, outline=BLACK, width=6)
    a.save(OUT / 'station_boil.png')

    # wajan + minyak + api
    a = Art(256, 256)
    a.shadow((120, 222), 104, 12)
    for x in (80, 116, 152):
        a.poly([(x - 14, 214), (x, 176), (x + 14, 214)], fill=ORANGE_C, outline=BLACK, width=4)
    a.ellipse_rot((120, 150), 96, 40, fill=(55, 62, 70, 255), outline=BLACK, width=7)
    a.ellipse_rot((120, 142), 78, 28, fill=(255, 193, 7, 255), outline=BLACK, width=5)
    a.ellipse_rot((100, 136), 18, 7, fill=(255, 236, 130, 255))
    a.poly(ga.ribbon([(210, 150), (250, 128)], 16, 16), fill=BROWN_D, outline=BLACK, width=5)
    a.save(OUT / 'station_fry.png')


# ---------------- latar dapur (potret 800 x 1600) ----------------
def gen_kitchen():
    Wd, Ht = 800, 1600
    a = Art(Wd, Ht)
    a.vgradient((255, 243, 224), (255, 236, 205), 0, 740)
    # ubin dinding
    for x in range(0, Wd + 1, 100):
        a.line([(x, 0), (x, 740)], 3, (255, 214, 160, 255))
    for y in range(0, 741, 100):
        a.line([(0, y), (Wd, y)], 3, (255, 214, 160, 255))
    # rel gantung + alat dapur
    a.line([(0, 118), (Wd, 118)], 8, BLACK)
    for x, kind in [(470, 'ladle'), (560, 'pan'), (650, 'whisk'), (730, 'pot')]:
        a.line([(x, 118), (x, 140)], 5, BLACK)
        if kind == 'ladle':
            a.line([(x, 140), (x, 230)], 8, BROWN_D)
            a.circle((x, 246), 22, fill=GREY_M, outline=BLACK, width=5)
        elif kind == 'pan':
            a.line([(x, 140), (x, 190)], 8, BROWN_D)
            a.circle((x, 222), 34, fill=(55, 62, 70, 255), outline=BLACK, width=5)
        elif kind == 'whisk':
            a.line([(x, 140), (x, 190)], 8, BROWN_D)
            a.ellipse_rot((x, 224), 14, 34, fill=None, outline=BLACK, width=4)
        else:
            a.rect(x - 28, 150, x + 28, 206, fill=GREY_M, outline=BLACK, width=5)
    # meja dapur
    top = 740
    a.rect(0, top, Wd, top + 36, fill=(224, 224, 224, 255), outline=BLACK, width=6)
    a.rect(0, top + 36, Wd, Ht, fill=(188, 143, 99, 255))
    for x in range(0, Wd, 200):
        a.rect(x + 12, top + 70, x + 188, Ht - 20, fill=(205, 163, 120, 255), outline=BLACK, width=5)
        a.rect(x + 80, top + 96, x + 120, top + 108, fill=GREY_D, outline=BLACK, width=3)
    a.final().convert('RGB').save(OUT / 'kitchen_bg.png')
    print('ditulis', (OUT / 'kitchen_bg.png').relative_to(ROOT))


def gen_cooking():
    OUT.mkdir(parents=True, exist_ok=True)
    gen_chef()
    gen_ingredients()
    gen_stations()
    gen_kitchen()


if __name__ == '__main__':
    gen_cooking()
