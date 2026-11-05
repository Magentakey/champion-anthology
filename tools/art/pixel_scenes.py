"""Mockup pixel art 48 px: halaman home dan storyboard (hanya PNG, tidak menyentuh aset game).

    python tools/art/pixel_scenes.py [folder_keluaran]
Keluaran: home_pixel.png, storyboard_pixel.png, dan panel_1..4_pixel.png.
Semua digambar pada kisi kecil lalu diperbesar tanpa memburamkan (nearest).
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image

import pixel_kit as k

ROOT = Path(__file__).resolve().parents[2]
OUT = k.OUT

# ---------------- font 5x7 ----------------
G = {
    'A': ".###.|#...#|#...#|#####|#...#|#...#|#...#", 'B': "####.|#...#|#...#|####.|#...#|#...#|####.",
    'C': ".###.|#...#|#....|#....|#....|#...#|.###.", 'D': "####.|#...#|#...#|#...#|#...#|#...#|####.",
    'E': "#####|#....|#....|####.|#....|#....|#####", 'F': "#####|#....|#....|####.|#....|#....|#....",
    'G': ".###.|#...#|#....|#.###|#...#|#...#|.###.", 'H': "#...#|#...#|#...#|#####|#...#|#...#|#...#",
    'I': ".###.|..#..|..#..|..#..|..#..|..#..|.###.", 'J': "..###|...#.|...#.|...#.|...#.|#..#.|.##..",
    'K': "#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#", 'L': "#....|#....|#....|#....|#....|#....|#####",
    'M': "#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#", 'N': "#...#|##..#|#.#.#|#..##|#...#|#...#|#...#",
    'O': ".###.|#...#|#...#|#...#|#...#|#...#|.###.", 'P': "####.|#...#|#...#|####.|#....|#....|#....",
    'Q': ".###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#", 'R': "####.|#...#|#...#|####.|#.#..|#..#.|#...#",
    'S': ".####|#....|#....|.###.|....#|....#|####.", 'T': "#####|..#..|..#..|..#..|..#..|..#..|..#..",
    'U': "#...#|#...#|#...#|#...#|#...#|#...#|.###.", 'V': "#...#|#...#|#...#|#...#|#...#|.#.#.|..#..",
    'W': "#...#|#...#|#...#|#.#.#|#.#.#|##.##|#...#", 'X': "#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#",
    'Y': "#...#|#...#|.#.#.|..#..|..#..|..#..|..#..", 'Z': "#####|....#|...#.|..#..|.#...|#....|#####",
    '!': "..#..|..#..|..#..|..#..|..#..|.....|..#..", '.': ".....|.....|.....|.....|.....|..##.|..##.",
    ',': ".....|.....|.....|.....|..##.|..#..|.#...", '-': ".....|.....|.....|#####|.....|.....|.....",
    '0': ".###.|#..##|#.#.#|##..#|#...#|#...#|.###.", '1': "..#..|.##..|..#..|..#..|..#..|..#..|.###.",
    '2': ".###.|#...#|....#|...#.|..#..|.#...|#####", '3': "####.|....#|....#|.###.|....#|....#|####.",
    '4': "...#.|..##.|.#.#.|#..#.|#####|...#.|...#.", '5': "#####|#....|####.|....#|....#|#...#|.###.",
    '6': ".###.|#....|#....|####.|#...#|#...#|.###.", '7': "#####|....#|...#.|..#..|.#...|.#...|.#...",
    '8': ".###.|#...#|#...#|.###.|#...#|#...#|.###.", '9': ".###.|#...#|#...#|.####|....#|....#|.###.",
    '>': "#....|.#...|..#..|...#.|..#..|.#...|#....", '?': ".###.|#...#|....#|...#.|..#..|.....|..#..",
    ' ': ".....|.....|.....|.....|.....|.....|.....", 'V_': "",
}
GLYPH = {ch: [row for row in v.split('|')] for ch, v in G.items() if v}


class Scene:
    def __init__(self, w, h):
        self.W, self.H = w, h
        self.g = [[None] * w for _ in range(h)]

    def set(self, x, y, c):
        if 0 <= x < self.W and 0 <= y < self.H:
            self.g[int(y)][int(x)] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1)):
            for x in range(int(x0), int(x1)):
                self.set(x, y, c)

    def ell(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, c)

    def poly(self, pts, c):
        ys = [p[1] for p in pts]
        xs = [p[0] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            for x in range(int(min(xs)), int(max(xs)) + 1):
                ins, j = False, len(pts) - 1
                for i in range(len(pts)):
                    xi, yi = pts[i]
                    xj, yj = pts[j]
                    if (yi > y + 0.5) != (yj > y + 0.5) and x + 0.5 < (xj - xi) * (y + 0.5 - yi) / (yj - yi + 1e-9) + xi:
                        ins = not ins
                    j = i
                if ins:
                    self.set(x, y, c)

    def line(self, p0, p1, c, th=1):
        n = int(max(abs(p1[0] - p0[0]), abs(p1[1] - p0[1]))) + 1
        for i in range(n + 1):
            t = i / max(1, n)
            for kx in range(th):
                for ky in range(th):
                    self.set(round(p0[0] + (p1[0] - p0[0]) * t) + kx, round(p0[1] + (p1[1] - p0[1]) * t) + ky, c)

    def vgrad(self, x0, y0, x1, y1, colors):
        """Pita warna vertikal; batas antar pita diberi dithering 2 baris."""
        n = len(colors)
        h = y1 - y0
        for y in range(y0, y1):
            t = (y - y0) / h * n
            i = min(n - 1, int(t))
            frac = t - i
            col = colors[i]
            if i + 1 < n and frac > 0.82 and (y % 2 == 0):
                for x in range(x0, x1):
                    if (x + y) % 2 == 0:
                        self.set(x, y, colors[i + 1])
                    else:
                        self.set(x, y, col)
                continue
            if i > 0 and frac < 0.18 and (y % 2 == 1):
                for x in range(x0, x1):
                    self.set(x, y, colors[i - 1] if (x + y) % 2 == 0 else col)
                continue
            for x in range(x0, x1):
                self.set(x, y, col)

    def blit(self, canvas, x, y, scale=1, flip=False, tint=None):
        """Tempel sprite karakter dengan titik tumpu di sela kaki (x, y) pada kanvas karakter."""
        ax, ay = k.CX + canvas.ox, 47 + canvas.oy
        for sy in range(canvas.s):
            for sx in range(canvas.s):
                col = canvas.g[sy][sx]
                if not col:
                    continue
                dx = (sx - ax) if not flip else -(sx - ax) - 1
                dy = sy - ay
                if tint:
                    col = tint
                for kx in range(scale):
                    for ky in range(scale):
                        self.set(round(x + dx * scale + kx), round(y + dy * scale + ky), col)

    def paste(self, other, x0, y0):
        for y in range(other.H):
            for x in range(other.W):
                if other.g[y][x]:
                    self.set(x0 + x, y0 + y, other.g[y][x])

    # ---- teks ----
    @staticmethod
    def text_w(s, scale=1):
        return len(s) * 6 * scale - scale

    def text(self, x, y, s, scale=1, color=(255, 255, 255, 255), outline=None, shadow=None):
        def draw(ox, oy, col):
            cx = x + ox
            for ch in s:
                g = GLYPH.get(ch.upper(), GLYPH['?'])
                for j, row in enumerate(g):
                    for i, c in enumerate(row):
                        if c == '#':
                            self.rect(cx + i * scale, y + oy + j * scale, cx + (i + 1) * scale, y + oy + (j + 1) * scale, col)
                cx += 6 * scale
        if shadow:
            draw(scale, scale * 2 if scale > 1 else 1, shadow)
        if outline:
            for dx in (-scale, 0, scale):
                for dy in (-scale, 0, scale):
                    if dx or dy:
                        draw(dx, dy, outline)
        draw(0, 0, color)

    def image(self, scale, bg=None):
        im = Image.new('RGBA', (self.W, self.H), bg or (0, 0, 0, 0))
        for y in range(self.H):
            for x in range(self.W):
                if self.g[y][x]:
                    im.putpixel((x, y), self.g[y][x])
        return im.resize((self.W * scale, self.H * scale), Image.NEAREST)


def C(r, g, b):
    return (r, g, b, 255)


CREAM = C(255, 244, 214)
DARK = C(26, 20, 44)


# ---------------- dekor ----------------
def cloud(sc, x, y, w, col=C(255, 255, 255), shade=C(190, 214, 240)):
    for dx, dy, rx, ry in ((0, 0, w * .30, w * .18), (w * .28, -w * .08, w * .26, w * .20), (w * .55, 0, w * .30, w * .17),
                           (w * .27, w * .06, w * .45, w * .13)):
        sc.ell(x + dx, y + dy, rx, ry, col)
    for xx in range(int(x - w * .2), int(x + w * .9)):
        for yy in range(int(y + w * .08), int(y + w * .18)):
            if sc.g[yy][xx] if 0 <= yy < sc.H and 0 <= xx < sc.W else False:
                if sc.g[yy][xx] == col and yy > y + w * .12:
                    sc.set(xx, yy, shade)


def globe(sc, cx, cy, r):
    land = [(-0.35, -0.25, 0.32, 0.26), (0.35, 0.2, 0.3, 0.38), (-0.1, 0.5, 0.2, 0.18), (0.45, -0.45, 0.16, 0.14)]
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            u, v = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
            if u * u + v * v > 1:
                continue
            col = C(70, 150, 232)
            if u * u + v * v > 0.62 and (u + v) > 0.35:
                col = C(44, 104, 190)
            for lx, ly, rx, ry in land:
                if ((u - lx) / rx) ** 2 + ((v - ly) / ry) ** 2 <= 1:
                    col = C(76, 176, 96) if (u + v) < 0.5 else C(48, 130, 70)
            if u * u + v * v < 0.12 or (u < -0.25 and v < -0.45 and u * u + v * v < 0.62):
                col = C(190, 224, 255) if col[2] > 200 else col
            sc.set(x, y, col)
    for y in range(int(cy - r) - 2, int(cy + r) + 3):
        for x in range(int(cx - r) - 2, int(cx + r) + 3):
            u, v = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
            d = u * u + v * v
            if 1.0 < d <= (1 + 2.0 / r) ** 2:
                sc.set(x, y, OUT)


def star4(sc, x, y, col=C(255, 255, 255)):
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
        sc.set(x + dx, y + dy, col)


def trophy(sc, cx, base, s=1.0):
    gold, gl, gd = C(255, 200, 40), C(255, 238, 140), C(200, 140, 20)
    def px(x, y, c):
        sc.set(round(cx + x * s), round(base + y * s), c)
    for y in range(-18, -8):
        w = 8 - (0 if y < -13 else (y + 13) // 2)
        for x in range(-w, w + 1):
            px(x, y, gold if x > -w + 1 else gl)
    for y in range(-8, -4):
        for x in range(-2, 3):
            px(x, y, gd)
    for y in range(-4, 0):
        for x in range(-6, 7):
            px(x, y, gold if y < -2 else gd)
    for y in range(-17, -12):
        px(-10, y, gd)
        px(10, y, gd)
        px(-9 if y in (-17, -13) else -10, y, gd)
    sc.line((cx - 10, base - 17), (cx - 8, base - 17), gd)
    sc.line((cx + 8, base - 17), (cx + 10, base - 17), gd)
    # garis tepi
    for y in range(int(base - 20), int(base + 2)):
        for x in range(int(cx - 14), int(cx + 15)):
            if sc.g[y][x] in (gold, gl, gd):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if sc.g[y + dy][x + dx] not in (gold, gl, gd) and sc.g[y + dy][x + dx] != OUT:
                        sc.g[y + dy][x + dx] = OUT


def board(sc, cx, cy):
    """Papan labirin kecil yang dipegang Asep."""
    sc.rect(cx - 8, cy - 7, cx + 8, cy + 7, OUT)
    sc.rect(cx - 7, cy - 6, cx + 7, cy + 6, C(250, 250, 250))
    for (x0, y0, x1, y1) in ((-5, -4, 3, -4), (3, -4, 3, 0), (-5, -4, -5, 4), (-5, 2, 1, 2), (1, 0, 5, 0), (1, 0, 1, 2), (5, 0, 5, 4)):
        sc.line((cx + x0, cy + y0), (cx + x1, cy + y1), C(60, 60, 90))
    sc.set(cx - 6, cy - 5, C(76, 176, 96))
    sc.set(cx + 5, cy + 5, C(222, 54, 54))


def shadow(sc, x, y, w, col):
    for dx in range(-w, w + 1):
        if abs(dx) < w - 1:
            sc.set(x + dx, y, col)
        if abs(dx) < w - 4:
            sc.set(x + dx, y + 1, col)


def hero(pose, **kw):
    return k.build(k.with_pose(k.HERO, pose=pose, **kw))


# ---------------- panel cerita ----------------
SKY = [C(38, 92, 176), C(62, 122, 204), C(98, 158, 226), C(140, 192, 244), C(184, 222, 250)]


def panel1(w=216, h=87):
    sc = Scene(w, h)
    sc.vgrad(0, 0, w, 66, SKY)
    cloud(sc, 24, 20, 34)
    cloud(sc, 150, 14, 40)
    cloud(sc, 96, 34, 24)
    gy = 66
    sc.rect(0, gy, w, h, C(150, 152, 164))
    sc.rect(0, gy, w, gy + 1, OUT)
    sc.rect(0, gy + 1, w, gy + 2, C(190, 192, 204))
    for x in range(0, w, 16):
        sc.rect(x, gy + 10, x + 8, gy + 11, C(214, 216, 226))
    for yy, ln in ((42, 22), (51, 30), (59, 18)):
        sc.line((8, yy), (8 + ln, yy), C(255, 255, 255))
    shadow(sc, 56, gy + 3, 18, C(110, 112, 128))
    sc.blit(hero('run', legs='stride'), 58, gy, flip=True)
    shadow(sc, 164, gy + 3, 18, C(110, 112, 128))
    sc.blit(k.build(k.with_pose(k.BOB, pose='globe_up')), 164, gy)
    star4(sc, 190, 24, C(255, 248, 190))
    star4(sc, 130, 10, C(255, 248, 190))
    return sc


def panel2(w=216, h=100):
    """Barisan para master (Rock, Bob, Asep, Chef) dan pemain di ujung kanan."""
    sc = Scene(w, h)
    sc.vgrad(0, 0, w, 62, [C(255, 232, 196), C(255, 220, 176), C(255, 206, 160)])
    for x in range(0, w, 16):
        sc.rect(x, 0, x + 1, 62, C(240, 196, 150))
    sc.rect(0, 60, w, 62, OUT)
    for y in range(62, h):
        for x in range(w):
            sc.set(x, y, C(214, 170, 120) if ((x // 8) + ((y - 62) // 4)) % 2 == 0 else C(194, 150, 102))
    fy = 70
    for x, sp in ((26, k.ROCK), (68, k.with_pose(k.BOB, pose='cross')), (110, k.ASEP), (152, k.CHEF)):
        shadow(sc, x, fy + 2, 12, C(160, 120, 80))
        sc.blit(k.build(sp), x, fy)
    board(sc, 110, fy - 19)
    shadow(sc, 192, fy + 4, 12, C(160, 120, 80))
    sc.blit(hero('stand_fist'), 192, fy + 2)
    return sc


def panel3(w=106, h=137):
    sc = Scene(w, h)
    sc.vgrad(0, 0, w, 94, [C(196, 176, 232), C(212, 196, 240), C(228, 216, 246), C(240, 232, 250)])
    rnd = random.Random(4)
    for _ in range(16):
        star4(sc, rnd.randint(4, w - 5), rnd.randint(4, 60), C(255, 255, 255))
    gy = 94
    sc.rect(0, gy, w, h, C(160, 150, 190))
    sc.rect(0, gy, w, gy + 1, OUT)
    px0, px1, py = 60, 100, 66
    sc.rect(px0, py, px1, gy, OUT)
    sc.rect(px0 + 1, py + 1, px1 - 1, gy, C(226, 226, 236))
    sc.rect(px0 + 1, py + 1, px1 - 1, py + 3, C(250, 250, 255))
    sc.rect(px1 - 4, py + 3, px1 - 1, gy, C(176, 176, 196))
    sc.text(px0 + 12, py + 9, '1', scale=3, color=C(60, 60, 84))
    trophy(sc, 80, py, 1.0)
    shadow(sc, 30, gy + 3, 14, C(120, 110, 150))
    sc.blit(hero('reach', legs='stride'), 32, gy + 2, flip=True)
    return sc


def panel4(w=106, h=137):
    """Close-up pemain (2x) dengan sinar matahari di belakangnya."""
    sc = Scene(w, h)
    cx, cy = 52, 62
    cols = (C(255, 170, 56), C(255, 202, 104))
    for y in range(h):
        for x in range(w):
            ang = math.atan2(y - cy, x - cx)
            sc.set(x, y, cols[int((ang + math.pi) / (2 * math.pi) * 18) % 2])
    rnd = random.Random(9)
    for _ in range(9):
        star4(sc, rnd.randint(6, w - 7), rnd.randint(6, 40), C(255, 250, 210))
    sc.blit(hero('stand_fist'), 60, 128, scale=2)
    return sc


# ---------------- halaman home ----------------
def home(w=240, h=426):
    sc = Scene(w, h)
    sky = [C(30, 28, 86), C(52, 40, 112), C(88, 54, 134), C(140, 68, 140), C(204, 90, 128), C(244, 126, 112), C(255, 176, 108)]
    sc.vgrad(0, 0, w, 346, sky)
    rnd = random.Random(12)
    for _ in range(34):
        x, y = rnd.randint(2, w - 3), rnd.randint(2, 150)
        if rnd.random() < 0.25:
            star4(sc, x, y, C(255, 244, 214))
        else:
            sc.set(x, y, C(255, 244, 214) if rnd.random() < 0.6 else C(190, 170, 230))
    sc.ell(120, 336, 62, 62, C(255, 214, 130))
    sc.ell(120, 336, 52, 52, C(255, 232, 150))
    sc.ell(120, 336, 40, 40, C(255, 246, 190))
    cloud(sc, 14, 230, 56, C(255, 190, 170), C(226, 140, 140))
    cloud(sc, 150, 206, 64, C(255, 190, 170), C(226, 140, 140))
    cloud(sc, 100, 282, 36, C(255, 200, 170), C(230, 150, 140))
    for x in range(w):
        y1 = 340 + int(8 * math.sin(x / 22.0) + 4 * math.sin(x / 7.0))
        for y in range(y1, 380):
            sc.set(x, y, C(96, 52, 120))
    for x in range(w):
        y2 = 358 + int(5 * math.sin(x / 15.0 + 1))
        for y in range(y2, h):
            sc.set(x, y, C(52, 34, 94))
    sc.rect(0, 370, w, h, C(40, 28, 78))
    for x in range(0, w, 12):
        sc.rect(x, 378, x + 6, 379, C(66, 48, 112))
    sc.ell(120, 370, 52, 8, OUT)
    sc.ell(120, 369, 50, 7, C(214, 200, 230))
    sc.ell(120, 368, 44, 5, C(236, 226, 248))
    shadow(sc, 120, 370, 26, C(150, 130, 180))
    fy = 370
    gcy = fy - 51 * 2
    sc.blit(hero('globe_up', legs='stand'), 124, fy, scale=2)
    for dx, dy in ((-36, -12), (38, -6), (-26, 14), (32, 16)):
        star4(sc, 124 + dx, int(gcy) + dy, C(255, 250, 200))
    sc.text((w - sc.text_w('THE WORLD IN', 2)) // 2, 26, 'THE WORLD IN', scale=2, color=CREAM, outline=DARK, shadow=C(90, 40, 110))
    sc.text((w - sc.text_w('MY HANDS!', 3)) // 2, 52, 'MY HANDS!', scale=3, color=C(255, 214, 64), outline=C(150, 30, 50), shadow=C(40, 10, 40))

    def button(y, label, base, hi, lo):
        x0, x1 = 68, 172
        sc.rect(x0 + 2, y + 2, x1 + 2, y + 28, C(24, 16, 44))
        sc.rect(x0, y, x1, y + 26, OUT)
        sc.rect(x0 + 1, y + 1, x1 - 1, y + 25, base)
        sc.rect(x0 + 1, y + 1, x1 - 1, y + 3, hi)
        sc.rect(x0 + 1, y + 22, x1 - 1, y + 25, lo)
        tw = sc.text_w(label, 2)
        sc.text(x0 + (x1 - x0 - tw) // 2, y + 6, label, scale=2, color=CREAM, outline=OUT)
    button(112, 'MAIN', C(226, 64, 56), C(255, 130, 108), C(160, 30, 44))
    button(148, 'KELUAR', C(60, 104, 204), C(120, 164, 240), C(34, 58, 140))
    sc.text((w - sc.text_w('VERSI 1.3.0', 1)) // 2, h - 12, 'VERSI 1.3.0', scale=1, color=C(150, 130, 200))
    return sc


# ---------------- mockup layar storyboard ----------------
def wrap(s, n):
    words, lines, cur = s.split(), [], ''
    for wd in words:
        if len((cur + ' ' + wd).strip()) <= n:
            cur = (cur + ' ' + wd).strip()
        else:
            lines.append(cur)
            cur = wd
    return lines + [cur]


def storyboard(w=240, h=426):
    sc = Scene(w, h)
    sc.rect(0, 0, w, h, C(22, 18, 40))
    for y in range(0, h, 4):
        sc.rect(0, y, w, y + 1, C(28, 22, 48))
    panels = [
        (panel1(), 12, 30, 'DUNIA ADA DI TANGAN PARA JUARA...'),
        (panel2(), 12, 121, 'TIAP BIDANG PUNYA MASTERNYA SENDIRI.'),
        (panel3(), 12, 225, 'TAPI HANYA SATU YANG JADI JUARA UTAMA.'),
        (panel4(), 122, 225, 'AKU AKAN MENGALAHKAN MEREKA SEMUA!'),
    ]
    for pn, x, y, cap in panels:
        sc.rect(x - 2, y - 2, x + pn.W + 2, y + pn.H + 2, CREAM)
        sc.rect(x - 1, y - 1, x + pn.W + 1, y + pn.H + 1, DARK)
        sc.paste(pn, x, y)
        lines = wrap(cap, (pn.W - 8) // 6)
        bh = len(lines) * 9 + 5
        sc.rect(x + 2, y + pn.H - bh - 2, x + pn.W - 2, y + pn.H - 2, C(26, 20, 44))
        sc.rect(x + 3, y + pn.H - bh - 1, x + pn.W - 3, y + pn.H - 3, C(250, 240, 214))
        for i, ln in enumerate(lines):
            sc.text(x + 6, y + pn.H - bh + 1 + i * 9, ln, scale=1, color=C(40, 30, 60))
    sc.text(w - 12 - sc.text_w('LEWATI >>', 1), 10, 'LEWATI >>', scale=1, color=C(190, 180, 220))
    sc.text((w - sc.text_w('KETUK UNTUK LANJUT', 1)) // 2, 380, 'KETUK UNTUK LANJUT', scale=1, color=CREAM)
    for i in range(4):
        sc.rect(100 + i * 12, 398, 108 + i * 12, 404, CREAM if i == 0 else C(80, 70, 110))
    return sc


def characters():
    names = (('PEMAIN', k.with_pose(k.HERO, pose='stand_fist')), ('BOB', k.BOB), ('ASEP', k.ASEP), ('CHEF', k.CHEF), ('ROCK', k.ROCK))
    sc = Scene(5 * 60 + 10, 76)
    sc.rect(0, 0, sc.W, sc.H, C(255, 235, 238))
    for i, (n, sp) in enumerate(names):
        x = 35 + i * 60
        shadow(sc, x, 61, 12, C(220, 190, 200))
        sc.blit(k.build(sp), x, 59)
        sc.text(x - sc.text_w(n, 1) // 2, 67, n, scale=1, color=C(70, 40, 70))
    return sc


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'docs' / 'preview'
    out.mkdir(parents=True, exist_ok=True)
    home().image(3).convert('RGB').save(out / 'home_pixel.png')
    storyboard().image(3).convert('RGB').save(out / 'storyboard_pixel.png')
    for i, fn in enumerate((panel1, panel2, panel3, panel4), 1):
        fn().image(3).convert('RGB').save(out / f'panel_{i}_pixel.png')
    characters().image(4).convert('RGB').save(out / 'characters_pixel.png')
    print('selesai ->', out)


if __name__ == '__main__':
    main()
