"""Aset gambar Level Fight: arena Colosseum, gambar intro Rock, potret HUD.

Dipanggil dari generate_art.py (python tools/art/generate_art.py).
"""
import math
import random

from PIL import Image, ImageDraw, ImageFilter

import generate_art as ga
from generate_art import Art, BLACK, WHITE, ROOT

ARENA_W, ARENA_H = 1600, 720
FLOOR_Y = 560          # batas dinding dan pasir; kaki petarung di ~86% tinggi (y=619)
STONE = (222, 190, 140, 255)
STONE_D = (190, 155, 110, 255)
GLOW_TOP = (255, 232, 160, 255)
GLOW_BOT = (255, 196, 112, 255)


def _arch(x0, x1, y_top, y_bot, n=14):
    r = (x1 - x0) / 2
    cy = y_top + r
    pts = [(x0, y_bot), (x0, cy)]
    for i in range(n + 1):
        t = math.pi + math.pi * i / n
        pts.append(((x0 + x1) / 2 + r * math.cos(t), cy + r * math.sin(t)))
    pts += [(x1, cy), (x1, y_bot)]
    return pts


def _spectators(a, rnd, x0, x1, y_bot, size):
    """Siluet penonton hitam di balik lengkungan yang bercahaya."""
    n = rnd.choice((2, 3, 3, 4))
    for k in range(n):
        x = x0 + (x1 - x0) * (k + 0.5 + rnd.uniform(-0.2, 0.2)) / n
        r = size * rnd.uniform(0.85, 1.1)
        y = y_bot - r * rnd.uniform(2.6, 3.4)
        a.circle((x, y), r, fill=BLACK)
        a.ellipse_rot((x, y + r * 2.1), r * 1.7, r * 1.5, 0, fill=BLACK)
        if rnd.random() < 0.35:   # bersorak mengangkat tangan
            side = rnd.choice((-1, 1))
            a.line([(x + side * r * 1.2, y + r * 1.6), (x + side * r * 2.0, y - r * 1.2)], r * 0.55)


def _tier(a, rnd, y_top, y_bot, arch_w, pillar_w, glow, crowd_size, sill):
    a.rect(0, y_top, ARENA_W, y_bot, fill=STONE, outline=BLACK, width=3)
    step = arch_w + pillar_w
    x = pillar_w / 2 - 6
    while x < ARENA_W:
        x0, x1 = x, x + arch_w
        a.poly(_arch(x0, x1, y_top + 22, y_bot - sill), fill=glow, outline=BLACK, width=3)
        _spectators(a, rnd, x0 + 6, x1 - 6, y_bot - sill, crowd_size)
        # pilar: sisi gelap sebagai pemberi kedalaman
        a.rect(x1, y_top + 22, x1 + 7, y_bot - sill, fill=STONE_D)
        x += step
    a.rect(0, y_bot - sill, ARENA_W, y_bot, fill=STONE_D, outline=BLACK, width=3)


def _banner(a, x, y, h, color):
    a.line([(x, y), (x, y + 14)], 4)
    a.poly([(x - 20, y + 14), (x + 20, y + 14), (x + 20, y + 14 + h), (x, y + 14 + h - 22), (x - 20, y + 14 + h)],
           fill=color, outline=BLACK, width=3)


def gen_arena():
    rnd = random.Random(7)
    a = Art(ARENA_W, ARENA_H)
    # langit hangat dan cahaya matahari di balik tribun
    a.vgradient((255, 183, 77), (255, 236, 190), 0, FLOOR_Y)
    for r, alpha in ((420, 40), (320, 60), (220, 90)):
        a.circle((800, 250), r, fill=(255, 250, 220, alpha))
    for i in range(0, 24, 2):
        a0, a1 = math.radians(i * 15), math.radians((i + 1) * 15)
        a.poly([(800, 250), (800 + math.cos(a0) * 1700, 250 + math.sin(a0) * 1700),
                (800 + math.cos(a1) * 1700, 250 + math.sin(a1) * 1700)], fill=(255, 255, 255, 38))

    # loteng (attic) dengan jendela persegi
    a.rect(0, 40, ARENA_W, 124, fill=STONE_D, outline=BLACK, width=3)
    for x in range(30, ARENA_W, 78):
        a.rect(x, 62, x + 34, 100, fill=(98, 70, 55, 255), outline=BLACK, width=3)
    a.rect(0, 28, ARENA_W, 44, fill=STONE, outline=BLACK, width=3)

    # dua tingkat lengkungan dengan penonton siluet
    _tier(a, rnd, 124, 316, 78, 30, GLOW_TOP, 9, 22)
    _tier(a, rnd, 316, FLOOR_Y, 104, 36, GLOW_BOT, 12, 36)

    # spanduk
    for i, x in enumerate(range(150, ARENA_W, 300)):
        _banner(a, x, 316 + 4, 110, ga.RED if i % 2 == 0 else ga.ORANGE)

    # pasir arena
    a.vgradient((228, 198, 142), (194, 158, 106), FLOOR_Y, ARENA_H)
    a.line([(0, FLOOR_Y), (ARENA_W, FLOOR_Y)], 6)
    a.ellipse_rot((800, 690), 760, 52, 0, outline=(150, 115, 75, 255), width=4)
    for _ in range(46):
        x, y = rnd.uniform(20, ARENA_W - 20), rnd.uniform(FLOOR_Y + 22, ARENA_H - 12)
        rx = rnd.uniform(3, 9)
        a.ellipse_rot((x, y), rx, rx * 0.5, 0, fill=(170, 135, 90, 255))

    img = a.final().convert('RGB')
    # vinyet: sudut gelap agar fokus ke tengah
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).ellipse([-260, -150, ARENA_W + 260, ARENA_H + 150], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new('RGB', img.size, (40, 16, 8))
    img = Image.composite(img, Image.blend(img, dark, 0.55), mask)
    path = ROOT / 'assets/images/fight/arena.png'
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print('ditulis', path.relative_to(ROOT), img.size)


def gen_rock_boss():
    a = Art(512, 512)
    ga.draw_figure(a, 'b_cross', 'rock_idle', 41, 3, 0.43, lw=26, acc=('rock',))
    a.save(ROOT / 'assets/images/fight/boss_idle.png')


def _portrait(path, pose, face, acc, flip, ox, oy, s, lw):
    size = 512
    a = Art(size, size)
    a.circle((256, 256), 250, fill=(255, 224, 178, 255))
    ga.draw_figure(a, pose, face, ox, oy, s, flip=flip, lw=lw, acc=acc)
    img = a.final()
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).ellipse([6, 6, size - 6, size - 6], fill=255)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    ImageDraw.Draw(out).ellipse([6, 6, size - 6, size - 6], outline=BLACK, width=14)
    out = out.resize((256, 256), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    out.save(path)
    print('ditulis', path.relative_to(ROOT))


def gen_portraits():
    d = ROOT / 'assets/images/fight'
    # pemain menghadap kanan (HUD kiri), Rock menghadap kiri (HUD kanan)
    _portrait(d / 'portrait_player.png', 'stand', 'mc_hype', ('headband',), False, -244, -50, 1.0, 20)
    s = 0.88
    _portrait(d / 'portrait_rock.png', 'b_cross', 'rock_idle', ('rock',), True, 256 - 500 * s, 256 - 330 * s + 22, s, 24)


def gen_fight():
    gen_arena()
    gen_rock_boss()
    gen_portraits()
