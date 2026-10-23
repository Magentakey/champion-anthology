#!/usr/bin/env python3
"""Generator art Champion Anthology (gaya stickman, lihat docs/ART_STYLE.md).

Jalankan dari root proyek:
    pip install pillow
    python tools/art/generate_art.py

Menulis ulang: assets/images/home, genius, story, dan assets/icon.
Ubah pose / wajah / warna di file ini lalu jalankan ulang; semua aset tetap seragam.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SS = 3  # supersampling agar garis halus

# ---------------- palet ----------------
BLACK = (20, 20, 24, 255)
WHITE = (255, 255, 255, 255)
RED = (214, 40, 40, 255)          # aksen pemain (ikat kepala)
BLUE = (30, 100, 200, 255)        # aksen Bob (dasi kupu-kupu)
BROWN = (141, 92, 46, 255)        # sepatu
GOLD = (255, 193, 7, 255)
GOLD_D = (214, 150, 0, 255)
GREEN = (102, 187, 106, 255)
OCEAN = (144, 202, 249, 255)
SKY_TOP = (41, 98, 180)
SKY_BOT = (144, 202, 249)
GROUND = (158, 158, 158)
PINK_BG = (255, 235, 238)
ORANGE = (251, 140, 0, 255)       # aksen Rock (sabuk)


# ---------------- kanvas ----------------
class Art:
    def __init__(self, w, h, bg=None):
        self.w, self.h = w, h
        self.img = Image.new('RGBA', (w * SS, h * SS), bg or (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def _p(self, pts):
        return [(x * SS, y * SS) for x, y in pts]

    def line(self, pts, width, color=BLACK):
        P = self._p(pts)
        w = max(1, int(round(width * SS)))
        self.d.line(P, fill=color, width=w, joint='curve')
        r = w / 2
        for (x, y) in (P[0], P[-1]):
            self.d.ellipse([x - r, y - r, x + r, y + r], fill=color)

    def circle(self, c, r, fill=None, outline=None, width=0):
        x, y = c
        self.d.ellipse([(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS],
                       fill=fill, outline=outline, width=max(0, int(round(width * SS))))

    def poly(self, pts, fill=None, outline=None, width=0):
        P = self._p(pts)
        if fill:
            self.d.polygon(P, fill=fill)
        if outline:
            self.d.line(P + [P[0]], fill=outline, width=max(1, int(round(width * SS))), joint='curve')

    def ellipse_rot(self, c, rx, ry, ang=0.0, fill=None, outline=None, width=0, n=48):
        pts = []
        for i in range(n):
            t = 2 * math.pi * i / n
            x, y = rx * math.cos(t), ry * math.sin(t)
            pts.append((c[0] + x * math.cos(ang) - y * math.sin(ang),
                        c[1] + x * math.sin(ang) + y * math.cos(ang)))
        self.poly(pts, fill, outline, width)

    def shadow(self, c, rx, ry, alpha=70):
        layer = Image.new('RGBA', self.img.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).ellipse([(c[0] - rx) * SS, (c[1] - ry) * SS,
                                       (c[0] + rx) * SS, (c[1] + ry) * SS], fill=(0, 0, 0, alpha))
        self.img.alpha_composite(layer)

    def vgradient(self, top, bottom, y0, y1):
        for y in range(int(y0 * SS), int(y1 * SS)):
            t = (y - y0 * SS) / max(1, (y1 - y0) * SS)
            col = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
            self.d.line([(0, y), (self.w * SS, y)], fill=col)

    def rect(self, x0, y0, x1, y1, fill=None, outline=None, width=0):
        self.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], fill, outline, width)

    def final(self, size=None):
        return self.img.resize(size or (self.w, self.h), Image.LANCZOS)

    def save(self, path, size=None, rgb=False):
        out = self.final(size)
        if rgb:
            out = out.convert('RGB')
        path.parent.mkdir(parents=True, exist_ok=True)
        out.save(path)
        print('ditulis', path.relative_to(ROOT))


def catmull(pts, n=10):
    P = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(n):
            t = k / n
            out.append(tuple(
                0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t
                       + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t * t
                       + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t ** 3)
                for j in (0, 1)))
    out.append(tuple(pts[-1]))
    return out


def ribbon(points, w0, w1):
    n = len(points)
    left, right = [], []
    for i, (x, y) in enumerate(points):
        if i == 0:
            dx, dy = points[1][0] - x, points[1][1] - y
        elif i == n - 1:
            dx, dy = x - points[i - 1][0], y - points[i - 1][1]
        else:
            dx, dy = points[i + 1][0] - points[i - 1][0], points[i + 1][1] - points[i - 1][1]
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        w = (w0 + (w1 - w0) * i / (n - 1)) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


# ---------------- pose (bingkai lokal 1000 x 1400, menghadap kanan) ----------------
def P(head, hip, arm_f, arm_b, leg_f, leg_b, **kw):
    return dict(head=head, hip=hip, arm_f=arm_f, arm_b=arm_b, leg_f=leg_f, leg_b=leg_b, **kw)


POSES = {
    # pose keren: tangan mengepal di depan, tangan lain di pinggang, kuda-kuda lebar
    'power': P((545, 330), (470, 860),
               [(532, 545), (690, 615), (735, 430)],
               [(525, 560), (360, 680), (462, 820)],
               [(470, 860), (640, 1020), (660, 1250), (740, 1262)],
               [(470, 860), (330, 1090), (180, 1200), (250, 1255)],
               fist_f=True),
    # pose menu utama: satu tangan menopang bola dunia, tangan lain di pinggang, kuda-kuda lebar
    'globe_hold': P((545, 330), (470, 860),
                    [(532, 545), (720, 620), (850, 520)],
                    [(525, 560), (360, 680), (462, 820)],
                    [(470, 860), (640, 1020), (660, 1250), (740, 1262)],
                    [(470, 860), (330, 1090), (180, 1200), (250, 1255)],
                    open_f=True),
    'stand': P((500, 320), (500, 850),
               [(500, 540), (580, 680), (590, 820)],
               [(500, 540), (420, 680), (410, 820)],
               [(500, 850), (540, 1050), (560, 1250), (620, 1262)],
               [(500, 850), (460, 1050), (440, 1250), (500, 1262)]),
    'fist_up': P((480, 330), (470, 860),
                 [(479, 545), (640, 440), (690, 250)],
                 [(478, 560), (390, 700), (400, 830)],
                 [(470, 860), (600, 1040), (650, 1250), (725, 1262)],
                 [(470, 860), (350, 1040), (300, 1250), (375, 1262)],
                 fist_f=True, fist_b=True),
    'hold_up': P((500, 330), (500, 860),
                 [(500, 545), (680, 380), (620, 60)],
                 [(500, 545), (320, 380), (380, 60)],
                 [(500, 860), (560, 1050), (570, 1250), (630, 1262)],
                 [(500, 860), (440, 1050), (430, 1250), (490, 1262)]),
    'shock': P((500, 330), (500, 860),
               [(500, 545), (650, 430), (730, 290)],
               [(500, 545), (350, 430), (270, 290)],
               [(500, 860), (580, 1040), (610, 1250), (675, 1262)],
               [(500, 860), (420, 1040), (390, 1250), (455, 1262)]),
    'laugh': P((450, 320), (500, 850),
               [(460, 545), (580, 650), (520, 770)],
               [(458, 550), (340, 640), (260, 590)],
               [(500, 850), (560, 1040), (570, 1250), (635, 1262)],
               [(500, 850), (430, 1050), (400, 1250), (465, 1262)]),
    'defeat': P((470, 400), (500, 900),
                [(475, 610), (520, 770), (535, 930)],
                [(473, 615), (415, 770), (400, 930)],
                [(500, 900), (545, 1080), (540, 1250), (605, 1262)],
                [(500, 900), (450, 1090), (430, 1250), (495, 1262)]),
    'cross': P((500, 320), (500, 850),
               [(500, 545), (590, 650), (445, 635)],
               [(500, 545), (410, 650), (555, 635)],
               [(500, 850), (540, 1050), (560, 1250), (620, 1262)],
               [(500, 850), (460, 1050), (440, 1250), (500, 1262)]),
    'reach': P((520, 340), (440, 860),
               [(505, 560), (690, 560), (880, 430)],
               [(503, 565), (390, 650), (320, 770)],
               [(440, 860), (600, 1040), (620, 1250), (695, 1262)],
               [(440, 860), (330, 1090), (205, 1215), (270, 1255)]),
}

# proporsi bos: kepala besar (r=190), badan dan kaki lebih pendek
BOSS_R = 190
POSES.update({
    'b_cross': P((500, 330), (500, 810),
                 [(500, 585), (595, 680), (440, 665)],
                 [(500, 585), (405, 680), (560, 665)],
                 [(500, 810), (540, 960), (555, 1105), (615, 1117)],
                 [(500, 810), (460, 960), (445, 1105), (505, 1117)], r=BOSS_R),
    'b_shock': P((500, 330), (500, 810),
                 [(500, 585), (660, 500), (760, 330)],
                 [(500, 585), (340, 500), (240, 330)],
                 [(500, 810), (575, 960), (605, 1105), (668, 1117)],
                 [(500, 810), (425, 960), (395, 1105), (458, 1117)], r=BOSS_R),
    'b_laugh': P((440, 325), (500, 810),
                 [(450, 585), (580, 680), (520, 770)],
                 [(448, 590), (330, 670), (250, 620)],
                 [(500, 810), (560, 960), (570, 1105), (633, 1117)],
                 [(500, 810), (430, 960), (400, 1105), (463, 1117)], r=BOSS_R),
    'b_defeat': P((470, 400), (500, 850),
                  [(475, 650), (520, 790), (535, 930)],
                  [(473, 655), (415, 790), (400, 930)],
                  [(500, 850), (545, 990), (540, 1105), (603, 1117)],
                  [(500, 850), (450, 995), (430, 1105), (493, 1117)], r=BOSS_R),
    'b_hold': P((500, 330), (500, 810),
                [(500, 585), (690, 380), (610, -60)],
                [(500, 585), (310, 380), (390, -60)],
                [(500, 810), (560, 960), (570, 1105), (630, 1117)],
                [(500, 810), (440, 960), (430, 1105), (490, 1117)], r=BOSS_R),
    'c_stand': P((500, 330), (500, 810),
                 [(500, 585), (575, 700), (585, 830)],
                 [(500, 585), (425, 700), (415, 830)],
                 [(500, 810), (540, 960), (555, 1105), (615, 1117)],
                 [(500, 810), (460, 960), (445, 1105), (505, 1117)], r=BOSS_R),
})

# ---------------- wajah (satuan = jari-jari kepala; u positif = arah hadap) ----------------
FACES = {
    'mc_smug': dict(eyes='smug', brows='smug', mouth='smirk'),
    # semangat ingin menang: mata berapi, alis tajam, senyum tipis percaya diri
    'mc_hype': dict(eyes='fire', brows='fierce', mouth='smile', extra='spark'),
    'mc_determined': dict(eyes='open', brows='angry', mouth='grin'),
    'mc_look': dict(eyes='open', brows='up_soft', mouth='flat'),
    'bob_idle': dict(eyes='smug', brows='smug', mouth='grin'),
    'bob_shock': dict(eyes='wide', brows='up', mouth='o', extra='sweat'),
    'bob_laugh': dict(eyes='happy', brows='up_soft', mouth='laugh', extra='tears'),
    'bob_defeat': dict(eyes='x', brows='sad', mouth='wavy', extra='stars', cracked=True),
    'rock_idle': dict(eyes='open', brows='angry', mouth='flat', scar=True),
    'rock_roar': dict(eyes='open', brows='fierce', mouth='shout', scar=True),
    'plain': dict(eyes='open', brows='none', mouth='smirk'),
    'cheer': dict(eyes='happy', brows='none', mouth='grin'),
}


def draw_eye(art, c, rp, kind, d, lw):
    rx, ry = 0.145 * rp, 0.205 * rp
    ow = lw * 0.32
    if kind == 'open':
        art.ellipse_rot(c, rx, ry, fill=WHITE, outline=BLACK, width=ow)
        art.circle((c[0] + d * 0.03 * rp, c[1] + 0.02 * rp), 0.065 * rp, fill=BLACK)
    elif kind == 'fire':   # mata besar menyala, pupil besar + kilau
        art.ellipse_rot(c, rx * 1.05, ry * 0.92, fill=WHITE, outline=BLACK, width=ow)
        pc = (c[0] + d * 0.035 * rp, c[1] + 0.02 * rp)
        art.circle(pc, 0.085 * rp, fill=BLACK)
        art.circle((pc[0] - 0.03 * rp, pc[1] - 0.04 * rp), 0.025 * rp, fill=WHITE)
    elif kind == 'wide':
        art.ellipse_rot(c, rx * 1.3, ry * 1.25, fill=WHITE, outline=BLACK, width=ow)
        art.circle(c, 0.04 * rp, fill=BLACK)
    elif kind == 'smug':   # setengah terpejam, pupil melirik
        pts = [(c[0] + rx * math.cos(t), c[1] + ry * math.sin(t))
               for t in [math.pi * i / 24 for i in range(25)]]
        art.poly(pts, fill=WHITE, outline=BLACK, width=ow)
        art.circle((c[0] + d * 0.04 * rp, c[1] + 0.09 * rp), 0.06 * rp, fill=BLACK)
        art.line([(c[0] - rx * 1.2, c[1]), (c[0] + rx * 1.2, c[1])], lw * 0.5)
    elif kind == 'happy':
        pts = [(c[0] + rx * 1.2 * math.cos(t), c[1] + 0.05 * rp - ry * 0.9 * math.sin(t))
               for t in [math.pi * (0.1 + 0.8 * i / 16) for i in range(17)]]
        art.line(pts, lw * 0.55)
    elif kind == 'x':
        k = 0.12 * rp
        art.line([(c[0] - k, c[1] - k), (c[0] + k, c[1] + k)], lw * 0.5)
        art.line([(c[0] + k, c[1] - k), (c[0] - k, c[1] + k)], lw * 0.5)


BROWS = {
    'smug': ([(0.06, -0.33), (0.38, -0.44)], [(0.50, -0.27), (0.82, -0.22)]),
    'up': ([(0.06, -0.40), (0.38, -0.47)], [(0.50, -0.47), (0.82, -0.40)]),
    'up_soft': ([(0.06, -0.36), (0.38, -0.40)], [(0.50, -0.40), (0.82, -0.36)]),
    'sad': ([(0.06, -0.28), (0.38, -0.40)], [(0.50, -0.40), (0.82, -0.28)]),
    'angry': ([(0.06, -0.42), (0.38, -0.27)], [(0.50, -0.27), (0.82, -0.42)]),
    'fierce': ([(-0.02, -0.26), (0.42, -0.06)], [(0.46, -0.06), (0.92, -0.28)]),
}


def draw_face(art, hc, rp, face, d, lw, view='3q'):
    def pt(u, v):
        return (hc[0] + d * u * rp, hc[1] + v * rp)

    if view == '3q':
        eyes_u = (0.22, 0.64)
        brow_shift = 0.0
        mouth_shift = 0.0
    else:  # depan: simetris di tengah kepala
        eyes_u = (-0.36, 0.36)
        brow_shift = -0.44
        mouth_shift = -0.5
    eye_c = [pt(u, 0.04) for u in eyes_u]
    for c in eye_c:
        draw_eye(art, c, rp, face['eyes'], d, lw)
    b = BROWS.get(face['brows'])
    if b:
        for seg in b:
            art.line([pt(u + brow_shift, v) for u, v in seg], lw * 0.5)

    m = face['mouth']
    ms = mouth_shift
    if m == 'smirk':
        pts = catmull([pt(0.18 + ms, 0.52), pt(0.50 + ms, 0.62), pt(0.82 + ms, 0.40)], 10)
        art.line(pts, lw * 0.5)
        art.line([pt(0.82 + ms, 0.40), pt(0.92 + ms, 0.33)], lw * 0.4)
    elif m == 'grin':
        art.line(catmull([pt(0.12 + ms, 0.48), pt(0.50 + ms, 0.76), pt(0.88 + ms, 0.44)], 10), lw * 0.5)
    elif m == 'smile':   # senyum tipis, mulut tertutup, sudut naik
        art.line(catmull([pt(0.22 + ms, 0.52), pt(0.52 + ms, 0.64), pt(0.84 + ms, 0.46)], 10), lw * 0.5)
        art.line([pt(0.84 + ms, 0.46), pt(0.92 + ms, 0.38)], lw * 0.4)
    elif m == 'flat':
        art.line([pt(0.25 + ms, 0.58), pt(0.75 + ms, 0.55)], lw * 0.5)
    elif m == 'o':
        art.ellipse_rot(pt(0.58 + ms, 0.58), 0.11 * rp, 0.16 * rp, fill=BLACK)
    elif m == 'laugh':
        c = pt(0.52 + ms, 0.40)
        pts = [(c[0] + 0.40 * rp * math.cos(t), c[1] + 0.40 * rp * math.sin(t))
               for t in [math.pi * i / 24 for i in range(25)]]
        art.poly(pts, fill=BLACK)
        art.ellipse_rot((c[0], c[1] + 0.28 * rp), 0.20 * rp, 0.10 * rp, fill=(239, 83, 80, 255))
    elif m == 'shout':   # mulut terbuka lebar, gigi atas, lidah
        c = pt(0.50 + ms, 0.42)
        rx_, ry_ = 0.42 * rp, 0.42 * rp
        pts = [(c[0] + rx_ * math.cos(t), c[1] + ry_ * math.sin(t))
               for t in [math.pi * i / 24 for i in range(25)]]
        art.poly(pts, fill=BLACK)
        art.poly([(c[0] - rx_ * 0.86, c[1] + 0.02 * rp), (c[0] + rx_ * 0.86, c[1] + 0.02 * rp),
                  (c[0] + rx_ * 0.72, c[1] + 0.12 * rp), (c[0] - rx_ * 0.72, c[1] + 0.12 * rp)], fill=WHITE)
        art.ellipse_rot((c[0], c[1] + 0.31 * rp), 0.20 * rp, 0.10 * rp, fill=(239, 83, 80, 255))
    elif m == 'wavy':
        pts = [pt(0.2 + ms + 0.64 * i / 20, 0.62 + 0.05 * math.sin(i * 0.9)) for i in range(21)]
        art.line(pts, lw * 0.5)

    if face.get('scar'):   # bekas luka di pipi
        art.line([pt(0.82, 0.18), pt(0.72, 0.48)], lw * 0.32)
        for (a_, b_) in (((0.74, 0.28), (0.90, 0.33)), ((0.72, 0.40), (0.88, 0.45))):
            art.line([pt(*a_), pt(*b_)], lw * 0.26)

    extra = face.get('extra')
    if extra == 'sweat':
        for (u, v, s) in [(-0.95, -0.30, 0.16), (-1.15, 0.05, 0.12)]:
            c = pt(u, v)
            art.circle((c[0], c[1] + s * rp * 0.4), s * rp * 0.55, fill=(120, 200, 255, 255), outline=BLACK, width=lw * 0.2)
            art.poly([(c[0], c[1] - s * rp * 0.9), (c[0] - s * rp * 0.45, c[1]), (c[0] + s * rp * 0.45, c[1])],
                     fill=(120, 200, 255, 255))
    elif extra == 'spark':   # garis semangat di atas kepala
        for ang in (-62, -90, -118):
            a_ = math.radians(ang)
            p0 = (hc[0] + math.cos(a_) * rp * 1.22, hc[1] + math.sin(a_) * rp * 1.22)
            p1 = (hc[0] + math.cos(a_) * rp * 1.52, hc[1] + math.sin(a_) * rp * 1.52)
            art.line([p0, p1], lw * 0.55)
    elif extra == 'tears':
        for c in eye_c:
            art.circle((c[0], c[1] + 0.32 * rp), 0.06 * rp, fill=(120, 200, 255, 255), outline=BLACK, width=lw * 0.15)
    elif extra == 'stars':
        for (u, v, s) in [(0.0, -1.35, 0.17), (0.6, -1.2, 0.13), (-0.6, -1.2, 0.13)]:
            c = pt(u, v)
            pts = []
            for i in range(10):
                rr = s * rp * (1.0 if i % 2 == 0 else 0.45)
                a = -math.pi / 2 + i * math.pi / 5
                pts.append((c[0] + rr * math.cos(a), c[1] + rr * math.sin(a)))
            art.poly(pts, fill=GOLD, outline=BLACK, width=lw * 0.2)
    return eye_c


def draw_headband(art, hc, rp, d, lw, tail=1.0):
    centre = [(-0.88, -0.62), (-0.45, -0.50), (0.0, -0.45), (0.45, -0.46), (0.88, -0.52)]
    pts = [(hc[0] + d * u * rp, hc[1] + v * rp) for u, v in catmull(centre, 8)]
    # ekor pita (di belakang kepala), melambai
    tails = [
        ([(-0.90, -0.62), (-1.40, -0.80), (-2.00, -0.65), (-2.53, -0.87), (-3.07, -0.72)], 0.20, 0.07),
        ([(-0.88, -0.56), (-1.47, -0.39), (-2.07, -0.50), (-2.67, -0.30), (-3.13, -0.41)], 0.18, 0.06),
    ]
    for tp, w0, w1 in tails:
        sm = [(hc[0] + d * (-0.9 + (u + 0.9) * tail) * rp, hc[1] + v * rp) for u, v in catmull(tp, 8)]
        art.poly(ribbon(sm, w0 * rp, w1 * rp), fill=RED, outline=BLACK, width=lw * 0.3)
    art.poly(ribbon(pts, 0.23 * rp, 0.23 * rp), fill=RED, outline=BLACK, width=lw * 0.3)
    art.circle((hc[0] - d * 0.90 * rp, hc[1] - 0.60 * rp), 0.12 * rp, fill=RED, outline=BLACK, width=lw * 0.3)


def draw_glasses(art, eye_c, rp, d, lw, cracked=False):
    R = 0.27 * rp
    for c in eye_c:
        art.circle(c, R, outline=BLACK, width=lw * 0.4)
    art.line([(eye_c[0][0] + d * R, eye_c[0][1]), (eye_c[1][0] - d * R, eye_c[1][1])], lw * 0.4)
    art.line([(eye_c[0][0] - d * R, eye_c[0][1]), (eye_c[0][0] - d * 0.62 * rp, eye_c[0][1] - 0.02 * rp)], lw * 0.4)
    if cracked:
        c = eye_c[1]
        art.line([(c[0] - R * 0.5, c[1] - R * 0.6), (c[0] + R * 0.1, c[1]), (c[0] + R * 0.5, c[1] + R * 0.7)], lw * 0.2)
        art.line([(c[0] + R * 0.1, c[1]), (c[0] - R * 0.4, c[1] + R * 0.5)], lw * 0.2)


def draw_spikes(art, hc, rp, lw):
    for ang, ln in [(-155, 1.35), (-130, 1.55), (-105, 1.45), (-80, 1.6), (-55, 1.45), (-30, 1.35)]:
        a = math.radians(ang)
        tip = (hc[0] + ln * rp * math.cos(a), hc[1] + ln * rp * math.sin(a))
        b1 = (hc[0] + 0.9 * rp * math.cos(a - 0.20), hc[1] + 0.9 * rp * math.sin(a - 0.20))
        b2 = (hc[0] + 0.9 * rp * math.cos(a + 0.20), hc[1] + 0.9 * rp * math.sin(a + 0.20))
        art.poly([b1, tip, b2], fill=BLACK, outline=BLACK, width=lw * 0.2)


def draw_rock_hair(art, hc, rp, d, lw):
    """Rambut kotak bergerigi seperti batu (menutup bagian atas kepala)."""
    uv = [(-0.87, -0.50), (-1.02, -0.80), (-0.78, -1.05), (-0.70, -1.30), (-0.30, -1.20), (-0.15, -1.42),
          (0.25, -1.25), (0.50, -1.38), (0.78, -1.08), (1.02, -0.78), (0.87, -0.50)]
    art.poly([(hc[0] + d * u * rp, hc[1] + v * rp) for u, v in uv], fill=BLACK, outline=BLACK, width=lw * 0.2)


def draw_rock_belt(art, neck, hip, lw):
    """Sabuk oranye di pinggul (tegak lurus badan)."""
    dx, dy = hip[0] - neck[0], hip[1] - neck[1]
    ln = math.hypot(dx, dy) or 1
    ux, uy = dx / ln, dy / ln
    px, py = -uy, ux
    c = (hip[0] - ux * lw * 0.9, hip[1] - uy * lw * 0.9)
    hl, ht = lw * 1.6, lw * 0.9
    pts = [(c[0] + px * hl + ux * ht, c[1] + py * hl + uy * ht), (c[0] - px * hl + ux * ht, c[1] - py * hl + uy * ht),
           (c[0] - px * hl - ux * ht, c[1] - py * hl - uy * ht), (c[0] + px * hl - ux * ht, c[1] + py * hl - uy * ht)]
    art.poly(pts, fill=ORANGE, outline=BLACK, width=lw * 0.18)


def draw_bowtie(art, c, rp, lw):
    k = 0.40 * rp
    art.poly([c, (c[0] - k, c[1] - 0.2 * k * 1.6), (c[0] - k, c[1] + 0.2 * k * 1.6)], fill=BLUE, outline=BLACK, width=lw * 0.25)
    art.poly([c, (c[0] + k, c[1] - 0.2 * k * 1.6), (c[0] + k, c[1] + 0.2 * k * 1.6)], fill=BLUE, outline=BLACK, width=lw * 0.25)
    art.circle(c, 0.09 * rp, fill=BLUE, outline=BLACK, width=lw * 0.25)


def draw_chef_hat(art, hc, rp, lw):
    for (u, v, r) in [(-0.55, -1.15, 0.45), (0.55, -1.15, 0.45), (0.0, -1.35, 0.5)]:
        art.circle((hc[0] + u * rp, hc[1] + v * rp), r * rp, fill=WHITE, outline=BLACK, width=lw * 0.5)
    art.rect(hc[0] - 0.78 * rp, hc[1] - 1.05 * rp, hc[0] + 0.78 * rp, hc[1] - 0.72 * rp,
             fill=WHITE, outline=BLACK, width=lw * 0.5)


def draw_shoe(art, ankle, toe, s):
    ang = math.atan2(toe[1] - ankle[1], toe[0] - ankle[0])
    length = math.hypot(toe[0] - ankle[0], toe[1] - ankle[1])
    c = ((ankle[0] + toe[0]) / 2, (ankle[1] + toe[1]) / 2 + 6 * s)
    art.ellipse_rot(c, length / 2 + 20 * s, 17 * s, ang, fill=BROWN, outline=BLACK, width=3 * s)


def draw_fist(art, c, rp, lw):
    r = 0.30 * rp
    art.circle(c, r, fill=WHITE, outline=BLACK, width=lw * 0.7)
    for k in (-0.35, 0.0, 0.35):
        art.line([(c[0] - r * 0.1, c[1] + r * k), (c[0] + r * 0.55, c[1] + r * k)], lw * 0.18)


def draw_open_hand(art, c, rp, lw, d=1):
    """Telapak terbuka menopang benda di atasnya: empat jari terpisah dan ibu jari."""
    u = 0.42 * rp
    pc = (c[0] + d * 0.05 * rp, c[1] + 0.10 * rp)
    fw = 0.115 * rp   # lebar jari

    def finger(base, tip, w):
        mid = ((base[0] + tip[0]) / 2 + d * 0.03 * rp, (base[1] + tip[1]) / 2)
        pts = catmull([base, mid, tip], 6)
        art.line(pts, w + lw * 0.5, BLACK)
        art.line(pts, w, WHITE)

    # ibu jari di sisi dekat badan
    finger((pc[0] - d * u * 0.85, pc[1] - 0.02 * rp), (pc[0] - d * u * 1.30, pc[1] - 0.30 * rp), fw * 1.1)
    # empat jari, sedikit melengkung mengikuti bola
    for k, ln in ((-0.62, 0.34), (-0.21, 0.40), (0.21, 0.40), (0.62, 0.34)):
        base = (pc[0] + d * k * u, pc[1] - 0.06 * rp)
        tip = (pc[0] + d * (k * 1.28 + 0.12) * u, pc[1] - (0.06 + ln) * rp)
        finger(base, tip, fw)
    art.ellipse_rot(pc, u * 0.95, 0.16 * rp, 0, fill=WHITE, outline=BLACK, width=lw * 0.5)


def draw_globe(art, c, r, ow=7):
    W, H = art.img.size
    cx, cy, R = c[0] * SS, c[1] * SS, r * SS
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.ellipse([cx - R, cy - R, cx + R, cy + R], fill=OCEAN)
    for (u, v, rx, ry, a) in [(-0.35, -0.25, 0.40, 0.27, 0.35), (0.32, 0.22, 0.32, 0.42, -0.3),
                              (-0.12, 0.58, 0.26, 0.17, 0.0), (0.58, -0.48, 0.22, 0.14, 0.5)]:
        pts = []
        for i in range(40):
            t = 2 * math.pi * i / 40
            x, y = rx * R * math.cos(t), ry * R * math.sin(t)
            pts.append((cx + u * R + x * math.cos(a) - y * math.sin(a),
                        cy + v * R + x * math.sin(a) + y * math.cos(a)))
        ld.polygon(pts, fill=GREEN)
    mask = Image.new('L', (W, H), 0)
    ImageDraw.Draw(mask).ellipse([cx - R, cy - R, cx + R, cy + R], fill=255)
    layer.putalpha(mask)
    art.img.alpha_composite(layer)
    art.circle(c, r, outline=BLACK, width=ow)
    art.line([(c[0] - r, c[1]), (c[0] + r, c[1])], ow * 0.35)
    pts = [(c[0] + r * 0.42 * math.cos(t), c[1] + r * math.sin(t)) for t in [2 * math.pi * i / 48 for i in range(49)]]
    art.line(pts, ow * 0.35)


def draw_trophy(art, c, s):
    x, y = c
    cup = [(x - 60 * s, y - 90 * s), (x + 60 * s, y - 90 * s), (x + 44 * s, y), (x - 44 * s, y)]
    art.arc_handle = None
    for sign in (-1, 1):
        pts = [(x + sign * 60 * s, y - 75 * s), (x + sign * 92 * s, y - 70 * s),
               (x + sign * 90 * s, y - 30 * s), (x + sign * 48 * s, y - 20 * s)]
        art.line(catmull(pts, 8), 9 * s, GOLD_D)
    art.poly(cup, fill=GOLD, outline=BLACK, width=5 * s)
    art.rect(x - 10 * s, y, x + 10 * s, y + 40 * s, fill=GOLD, outline=BLACK, width=5 * s)
    art.rect(x - 36 * s, y + 40 * s, x + 36 * s, y + 62 * s, fill=GOLD, outline=BLACK, width=5 * s)


def draw_maze_board(art, c, size, lw):
    x0, y0 = c[0] - size / 2, c[1] - size / 2
    art.rect(x0, y0, x0 + size, y0 + size, fill=WHITE, outline=BLACK, width=lw * 0.4)
    g = size / 5
    segs = [((0, 1), (3, 1)), ((2, 2), (2, 4)), ((1, 3), (4, 3)), ((3, 0), (3, 2)), ((4, 2), (4, 4)), ((0, 4), (2, 4))]
    for (a, b), (c2, d2) in segs:
        art.line([(x0 + a * g, y0 + b * g), (x0 + c2 * g, y0 + d2 * g)], lw * 0.22)


# ---------------- figur ----------------
def draw_figure(art, pose_name, face_name, ox, oy, s, flip=False, lw=18, acc=(), props=(),
                view='3q', tail=1.0):
    pose = POSES[pose_name]
    face = FACES[face_name]
    d = -1 if flip else 1

    def T(p):
        x, y = p
        if flip:
            x = 1000 - x
        return (ox + x * s, oy + y * s)

    W = lw * s
    r = pose.get('r', 150)
    hx, hy = pose['head']
    hc, rp = T((hx, hy)), r * s
    neck, hip = T(pose.get('neck', (hx, hy + r))), T(pose['hip'])

    art.line([T(p) for p in pose['arm_b']], W)
    art.line([T(p) for p in pose['leg_b'][:3]], W)
    art.line([neck, hip], W)
    art.line([T(p) for p in pose['leg_f'][:3]], W)
    if not pose.get('over'):
        art.line([T(p) for p in pose['arm_f']], W)
    for leg in (pose['leg_b'], pose['leg_f']):
        draw_shoe(art, T(leg[2]), T(leg[3]), s)

    for pr in props:   # properti di belakang kepala / di tangan
        if pr[0] == 'globe':
            draw_globe(art, T(pr[1]), pr[2] * s, ow=max(4, 12 * s))
        elif pr[0] == 'maze':
            draw_maze_board(art, T(pr[1]), pr[2] * s, W)

    if 'bob' in acc:
        draw_spikes(art, hc, rp, W)
    if 'rock' in acc:
        draw_rock_belt(art, neck, hip, W)
    art.circle(hc, rp, fill=WHITE, outline=BLACK, width=W * 0.9)
    if 'rock' in acc:
        draw_rock_hair(art, hc, rp, d, W)
    if 'chef' in acc:
        draw_chef_hat(art, hc, rp, W)
    eye_c = draw_face(art, hc, rp, face, d, W, view)
    if 'headband' in acc:
        draw_headband(art, hc, rp, d, W, tail=tail)
    if 'bob' in acc:
        draw_glasses(art, eye_c, rp, d, W, cracked=face.get('cracked', False))
        draw_bowtie(art, neck, rp, W)
    if pose.get('fist_b'):
        draw_fist(art, T(pose['arm_b'][-1]), rp, W)
    if pose.get('open_f'):
        draw_open_hand(art, T(pose['arm_f'][-1]), rp, W, -d)
    if pose.get('fist_f'):
        draw_fist(art, T(pose['arm_f'][-1]), rp, W)
    return hc, rp


# ================= aset =================
def home_figure():
    """Pemain setengah badan (sampai pinggang) menopang bola dunia; dipakai di menu dan ikon."""
    a = Art(1300, 1400)
    draw_figure(a, 'globe_hold', 'mc_hype', 150, 0, 1.0, flip=True, lw=22, acc=('headband',),
                props=[('globe', (880, 350), 175)])
    im = a.final()
    bb = im.getbbox()
    return im.crop((max(0, bb[0] - 20), max(0, bb[1] - 20), min(1300, bb[2] + 20), 790))


def gen_home():
    """Menu utama (potret): kepala di kanan atas, bola dunia di kiri, badan turun sampai tepi bawah layar."""
    W, H = 800, 1600
    a = Art(1300, 1500)
    draw_figure(a, 'globe_hold', 'mc_hype', 150, 0, 1.0, flip=True, lw=22, acc=('headband',),
                props=[('globe', (880, 350), 175)])
    im = a.final()
    bb = im.crop((0, 0, 1300, 900)).getbbox()        # tepi kiri = bola dunia
    f = 1.03                                         # dibesarkan; ekor ikat kepala boleh terpotong tepi kanan
    big = im.resize((int(im.width * f), int(im.height * f)), Image.LANCZOS)
    ox = int(0.015 * W - bb[0] * f)
    oy = int(0.34 * H - 330 * f)                     # pusat kepala di 35% tinggi
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    canvas.paste(big, (ox, oy), big)                 # bagian di luar kanvas (kaki, ekor) terpotong
    path = ROOT / 'assets/images/home/mc_home.png'
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(path)
    print('ditulis', path.relative_to(ROOT), canvas.size)


def gen_boss():
    sets = {
        'boss_idle.png': ('b_cross', 'bob_idle'),
        'boss_shock.png': ('b_shock', 'bob_shock'),
        'boss_laugh.png': ('b_laugh', 'bob_laugh'),
        'boss_defeat.png': ('b_defeat', 'bob_defeat'),
    }
    for fname, (pose, face) in sets.items():
        a = Art(512, 512)
        draw_figure(a, pose, face, 41, 3, 0.43, lw=22, acc=('bob',))
        a.save(ROOT / 'assets/images/genius' / fname)


def gen_icon():
    """Ikon = gambar menu utama (setengah badan), menempel di tepi bawah."""
    fig = home_figure()

    def place(canvas_bg, width_frac):
        size = 1024
        canvas = Image.new('RGBA', (size, size), canvas_bg)
        w = int(size * width_frac)
        h = int(fig.height * w / fig.width)
        f = fig.resize((w, h), Image.LANCZOS)
        canvas.alpha_composite(f, ((size - w) // 2, size - h))
        return canvas

    full = place((0, 0, 0, 0), 0.92)
    # sinar latar di belakang kepala agar bagian atas ikon tidak kosong
    rays = Image.new('RGBA', full.size, (0, 0, 0, 0))
    rd = ImageDraw.Draw(rays)
    cx, cy = 560, 560
    for i in range(0, 24, 2):
        a0, a1 = math.radians(i * 15), math.radians((i + 1) * 15)
        rd.polygon([(cx, cy), (cx + math.cos(a0) * 1500, cy + math.sin(a0) * 1500),
                    (cx + math.cos(a1) * 1500, cy + math.sin(a1) * 1500)], fill=(255, 205, 210, 255))
    bg = Image.new('RGBA', full.size, PINK_BG + (255,))
    bg.alpha_composite(rays)
    bg.alpha_composite(full)
    bg.convert('RGB').save(ROOT / 'assets/icon/app_icon.png')
    place((0, 0, 0, 0), 0.62).save(ROOT / 'assets/icon/app_icon_fg.png')   # zona aman ikon adaptif


def ground(a, y):
    a.rect(0, y, a.w, a.h, fill=GROUND + (255,))
    a.line([(0, y), (a.w, y)], 4)


def gen_story():
    # panel 1: Bob memegang dunia, pemain menatap
    a = Art(1000, 400)
    a.vgradient(SKY_TOP, SKY_BOT, 0, 300)
    ground(a, 300)
    s = 0.245
    a.shadow((610, 376), 120, 12)
    a.shadow((250, 376), 100, 10)
    draw_figure(a, 'power', 'mc_look', 130, 73, 0.24, lw=20, acc=('headband',))
    draw_figure(a, 'b_hold', 'bob_laugh', 487, 96, s, lw=22, acc=('bob',),
                props=[('globe', (500, -190), 170)])
    a.save(ROOT / 'assets/images/story/panel_1.png', rgb=True)

    # panel 2: tiap bidang punya master
    a = Art(600, 600)
    a.vgradient((255, 224, 178), (255, 245, 225), 0, 430)
    ground(a, 430)
    for cx, pose, face, acc, props in [
        (80, 'b_cross', 'bob_idle', ('bob',), ()),
        (200, 'c_stand', 'plain', (), [('maze', (610, 800), 200)]),
        (320, 'c_stand', 'cheer', ('chef',), ()),
    ]:
        a.shadow((cx + 5, 455), 55, 8)
        draw_figure(a, pose, face, cx - 120, 187, 0.24, lw=22, acc=acc, props=props)
    a.shadow((440, 566), 85, 10)
    draw_figure(a, 'stand', 'mc_hype', 325, 225, 0.27, flip=True, lw=20, acc=('headband',))
    a.save(ROOT / 'assets/images/story/panel_2.png', rgb=True)

    # panel 3: satu gelar juara utama
    a = Art(600, 600)
    a.vgradient((206, 190, 235), (237, 231, 246), 0, 540)
    ray = Image.new('RGBA', a.img.size, (0, 0, 0, 0))
    rd = ImageDraw.Draw(ray)
    for i in range(7):
        ang = math.radians(-150 + i * 20)
        x0, y0 = 400 * SS, 0
        rd.polygon([(x0, y0),
                    (x0 + math.cos(ang + 0.07) * 900 * SS, y0 - math.sin(ang + 0.07) * -900 * SS),
                    (x0 + math.cos(ang - 0.07) * 900 * SS, y0 - math.sin(ang - 0.07) * -900 * SS)],
                   fill=(255, 241, 118, 70))
    a.img.alpha_composite(ray)
    ground(a, 540)
    a.rect(320, 400, 480, 540, fill=(224, 224, 224, 255), outline=BLACK, width=5)
    draw_trophy(a, (400, 330), 1.0)
    try:
        font = ImageFont.truetype('DejaVuSans-Bold.ttf', 60 * SS)
        a.d.text((400 * SS, 470 * SS), '1', fill=BLACK, font=font, anchor='mm')
    except OSError:
        pass
    a.shadow((170, 556), 90, 10)
    draw_figure(a, 'reach', 'mc_determined', 20, 141, 0.30, lw=20, acc=('headband',))
    a.save(ROOT / 'assets/images/story/panel_3.png', rgb=True)

    # panel 4: tekad pemain
    a = Art(600, 900)
    a.vgradient((255, 204, 128), (255, 224, 178), 0, 900)
    cx, cy = 300, 420
    for i in range(16):
        if i % 2:
            continue
        a0, a1 = math.radians(i * 22.5), math.radians((i + 1) * 22.5)
        a.poly([(cx, cy), (cx + math.cos(a0) * 900, cy + math.sin(a0) * 900),
                (cx + math.cos(a1) * 900, cy + math.sin(a1) * 900)], fill=(255, 183, 77, 255))
    ground(a, 820)
    a.shadow((260, 836), 190, 16)
    draw_figure(a, 'fist_up', 'mc_determined', 10, 88, 0.58, lw=20, acc=('headband',))
    a.save(ROOT / 'assets/images/story/panel_4.png', rgb=True)


if __name__ == '__main__':
    gen_home()
    gen_boss()
    gen_icon()
    gen_story()
    import fight_art
    fight_art.gen_fight()
    print('selesai')
