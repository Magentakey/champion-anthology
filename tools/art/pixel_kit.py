"""Perangkat pixel art 48 px: kanvas, font 5x7, pembuat karakter, dan kanvas adegan.

Dipakai oleh pixel_scenes.py untuk membuat mockup home dan storyboard (hanya PNG, tanpa kode game).
"""
import math

from PIL import Image

import pixel_preview as pv

OUT, SKIN, HAIR = pv.OUT, pv.SKIN, pv.HAIR
RED, WHITE, NAVY, BROWN = pv.RED, pv.WHITE, pv.NAVY, pv.BROWN
EYE, PUPIL, MOUTH, TONGUE, BLUSH, SPARK = pv.EYE, pv.PUPIL, pv.MOUTH, pv.TONGUE, pv.BLUSH, pv.SPARK


def pal(base, hi=None, sh=None):
    def adj(c, f):
        return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)
    b = base + (255,) if len(base) == 3 else base
    return (b, hi or adj(b, 1.28), sh or adj(b, 0.68))


ORANGE = pal((240, 140, 30))
GREEN = pal((76, 160, 90))
BLUE = pal((40, 100, 200))
GREY = pal((120, 124, 140))
DGREY = pal((58, 60, 72))
BLACKP = pal((40, 40, 52))
KHAKI = pal((196, 168, 112))
BROWNH = pal((110, 70, 48))
GOLD = pal((255, 200, 40))
CREAM = pal((255, 244, 214))


# ---------------- kanvas karakter (koordinat karakter, dengan offset) ----------------
class Canvas:
    def __init__(self, s, ox, oy):
        self.s, self.ox, self.oy = s, ox, oy
        self.g = [[None] * s for _ in range(s)]

    def _xr(self):
        return range(-self.ox, self.s - self.ox)

    def _yr(self):
        return range(-self.oy, self.s - self.oy)

    def ell(self, cx, cy, rx, ry):
        return {(x, y) for y in self._yr() for x in self._xr()
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0}

    def rect(self, x0, y0, x1, y1):
        return {(x, y) for y in range(int(math.floor(y0)), int(math.floor(y1))) for x in range(int(math.floor(x0)), int(math.floor(x1)))}

    def poly(self, pts):
        def inside(px, py):
            c = False
            j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi + 1e-9) + xi:
                    c = not c
                j = i
            return c
        return {(x, y) for y in self._yr() for x in self._xr() if inside(x + 0.5, y + 0.5)}

    def tube(self, pts, w):
        out = set()
        r = w / 2
        segs = list(zip(pts, pts[1:]))
        for y in self._yr():
            for x in self._xr():
                px, py = x + 0.5, y + 0.5
                for (ax, ay), (bx, by) in segs:
                    dx, dy = bx - ax, by - ay
                    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy + 1e-9)))
                    if math.hypot(px - (ax + t * dx), py - (ay + t * dy)) <= r:
                        out.add((x, y))
                        break
        return out

    def put(self, x, y, c):
        X, Y = int(x) + self.ox, int(y) + self.oy
        if 0 <= X < self.s and 0 <= Y < self.s:
            self.g[Y][X] = c

    def paint(self, mask, pal_, shade=True, outline=True, depth=1):
        base, hi, sh = pal_
        big = len(mask) > 14
        for (x, y) in mask:
            c = base
            if shade and big:
                if (x, y - 1) not in mask or (x - 1, y) not in mask:
                    c = hi
                if any((x + i, y + j) not in mask for i in range(1, depth + 1) for j in range(0, depth + 1)) or \
                        any((x + j, y + i) not in mask for i in range(1, depth + 1) for j in range(0, depth + 1)):
                    c = sh
            self.put(x, y, c)
        if outline:
            for (x, y) in mask:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if (x + dx, y + dy) not in mask:
                        self.put(x + dx, y + dy, OUT)

    def line(self, p0, p1, c, th=1):
        n = int(max(abs(p1[0] - p0[0]), abs(p1[1] - p0[1]))) + 1
        for i in range(n + 1):
            t = i / max(1, n)
            x = round(p0[0] + (p1[0] - p0[0]) * t)
            y = round(p0[1] + (p1[1] - p0[1]) * t)
            for k in range(th):
                self.put(x, y + k, c)

    def stamp(self, x0, y0, rows, key):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch != '.':
                    self.put(x0 + i, y0 + j, key[ch])


KEY = {'O': OUT, 'e': EYE, 'p': PUPIL, 'y': SPARK, 'k': MOUTH, 'w': WHITE[0], 't': TONGUE, 'b': BLUSH,
       'l': (206, 232, 255, 255), 'd': PUPIL}

# ---------------- bola dunia (bagian dari sprite pose globe_up) ----------------
def canvas_globe(c, cx, cy, r):
    land = [(-0.35, -0.25, 0.32, 0.26), (0.35, 0.2, 0.3, 0.38), (-0.1, 0.5, 0.2, 0.18), (0.45, -0.45, 0.16, 0.14)]
    for y in range(int(cy - r) - 3, int(cy + r) + 4):
        for x in range(int(cx - r) - 3, int(cx + r) + 4):
            u, v = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
            d = u * u + v * v
            if d <= 1.0:
                col = (70, 150, 232, 255)
                if d > 0.62 and (u + v) > 0.35:
                    col = (44, 104, 190, 255)
                for lx, ly, rx, ry in land:
                    if ((u - lx) / rx) ** 2 + ((v - ly) / ry) ** 2 <= 1:
                        col = (76, 176, 96, 255) if (u + v) < 0.5 else (48, 130, 70, 255)
                if d < 0.12 or (u < -0.25 and v < -0.45 and d < 0.62):
                    col = (190, 224, 255, 255) if col[2] > 200 else col
                c.put(x, y, col)
            elif d <= (1 + 2.0 / r) ** 2:
                c.put(x, y, OUT)


# ---------------- pembuat karakter (S = 48) ----------------
S = 48
CX = 24.0


def f(v):
    return v * S


def build(spec):
    """Buat sprite karakter. spec: dict (lihat HERO/BOB/ASEP/CHEF/ROCK)."""
    c = Canvas(112, 32, 40)          # koordinat karakter x∈[-32,80), y∈[-40,72)
    hcy, hrx, hry = f(0.36), f(0.27), f(0.245)
    pose = spec.get('pose', 'stand_fist')
    torso_w = spec.get('torso_w', 0.125)

    # --- ekor ikat kepala (di belakang kepala) ---
    if spec.get('band'):
        by0, by1 = hcy - 0.58 * hry, hcy - 0.36 * hry
        for k, dy in enumerate((0.0, f(0.05))):
            yy = (by0 + by1) / 2 + dy
            pts = [(CX + hrx - 1, yy), (CX + hrx + f(0.07), yy + f(0.02) * (1 + k)), (CX + hrx + f(0.13), yy - f(0.02)),
                   (CX + hrx + f(0.19), yy + f(0.03) * (1 + k))]
            c.paint(c.tube(pts, max(2.2, f(0.06) - k)), spec['band'])

    # --- kaki ---
    lp = spec.get('legs', 'stand')
    shoe = spec.get('shoe', RED)
    skin = spec.get('skin', SKIN)
    pants = spec.get('bottom', NAVY)
    long_pants = spec.get('long_pants', False)
    legs = {
        'stand': [((-0.075, 0.74), (-0.075, 0.86), (-0.087, 0.895)), ((0.075, 0.74), (0.075, 0.86), (0.087, 0.895))],
        'stride': [((-0.075, 0.74), (-0.13, 0.82), (-0.18, 0.875)), ((0.075, 0.74), (0.13, 0.80), (0.21, 0.79))],
        'wide': [((-0.09, 0.74), (-0.13, 0.86), (-0.15, 0.895)), ((0.09, 0.74), (0.13, 0.86), (0.15, 0.895))],
    }[lp]
    for (hip, knee, foot) in legs:
        pts = [(CX + f(hip[0]), f(hip[1])), (CX + f(knee[0]), f(knee[1])), (CX + f(foot[0]), f(foot[1]) - 1)]
        c.paint(c.tube(pts, f(0.095) if long_pants else f(0.085)), pants if long_pants else skin)
        fx, fy = CX + f(foot[0]), f(foot[1])
        c.paint(c.ell(fx + (1 if foot[0] > 0 else -1), fy + 1.5, f(0.075), f(0.05)), shoe)
        c.paint(c.rect(fx - f(0.07) + (1 if foot[0] > 0 else -1), fy + 2.5, fx + f(0.07) + (1 if foot[0] > 0 else -1), fy + 4.5), WHITE, shade=False)

    # --- celana pendek dan badan ---
    # celana pendek atau blok pinggul celana panjang (lebih panjang, kaki yang terlihat tetap pendek)
    c.paint(c.rect(CX - f(0.145), f(0.66), CX + f(0.145), f(0.80) if long_pants else f(0.775)), pants)
    if long_pants:
        c.put(int(CX), int(f(0.80)) - 1, OUT)
    tw = f(torso_w)
    torso = c.rect(CX - tw, f(0.5), CX + tw, f(0.7))
    top = spec.get('top', WHITE)
    c.paint(torso, top)
    if spec.get('stripe'):
        for y in range(int(f(0.655)), int(f(0.655)) + max(1, round(f(0.025)))):
            for x in range(int(CX - tw), int(CX + tw)):
                if (x, y) in torso:
                    c.put(x, y, spec['stripe'][0])
    if spec.get('vest'):                       # rompi: dua panel gelap di kiri-kanan dada
        for sg in (-1, 1):
            m = c.rect(CX + (0 if sg > 0 else -tw), f(0.56), CX + (tw if sg > 0 else 0), f(0.7))
            m = {q for q in m if q in torso}
            side = {q for q in m if abs(q[0] + 0.5 - CX) > f(0.03)}
            for q in side:
                c.put(q[0], q[1], spec['vest'][0])
    if spec.get('apron'):
        ap = c.rect(CX - tw + 2, f(0.56), CX + tw - 2, f(0.72))
        c.paint(ap, spec['apron'], outline=True)
    if spec.get('belt'):
        for x in range(int(CX - tw), int(CX + tw)):
            for y in range(int(f(0.665)), int(f(0.665)) + 2):
                if (x, y) in torso or (x, y) in c.rect(CX - f(0.145), f(0.66), CX + f(0.145), f(0.775)):
                    c.put(x, y, spec['belt'][0])
    if spec.get('neck'):                        # dasi kupu-kupu / syal
        ny = f(0.585)
        col = spec['neck']
        if spec.get('neck_kind') == 'bow':
            c.paint(c.poly([(CX - 1, ny + 1), (CX - 7, ny - 2), (CX - 7, ny + 4)]), col)
            c.paint(c.poly([(CX + 1, ny + 1), (CX + 7, ny - 2), (CX + 7, ny + 4)]), col)
            c.paint(c.rect(CX - 1.5, ny - 0.5, CX + 1.5, ny + 2.5), col, shade=False)
        else:
            c.paint(c.rect(CX - 7, ny - 1, CX + 7, ny + 3), col)
            c.paint(c.rect(CX - 1, ny + 2, CX + 4, ny + 8), col)

    # --- lengan ---
    aw = max(3, f(0.066))
    hand_pal = spec.get('hand', skin)
    poses = {
        'stand_fist': dict(l=[(-.12, .54), (-.24, .58), (-.29, .5), (-.30, .45)], lh=(-.30, .40, 'fist'),
                           r=[(.12, .54), (.215, .6), (.165, .675)], rh=(.165, .685, 'hand')),
        'stand': dict(l=[(-.12, .54), (-.19, .62), (-.17, .70)], lh=(-.17, .715, 'hand'),
                      r=[(.12, .54), (.19, .62), (.17, .70)], rh=(.17, .715, 'hand')),
        'cheer': dict(l=[(-.12, .54), (-.24, .58), (-.30, .46), (-.30, .40)], lh=(-.30, .35, 'fist'),
                      r=[(.12, .54), (.24, .58), (.30, .46), (.30, .40)], rh=(.30, .35, 'fist')),
        'run': dict(l=[(-.12, .54), (-.2, .63), (-.27, .58)], lh=(-.285, .555, 'fist'),
                    r=[(.12, .54), (.23, .5), (.29, .58)], rh=(.30, .6, 'fist')),
        'reach': dict(l=[(-.12, .54), (-.2, .64), (-.19, .70)], lh=(-.19, .715, 'hand'),
                      r=[(.12, .54), (.26, .52), (.38, .48)], rh=(.40, .47, 'hand')),
        'globe_up': dict(l=[(-.12, .54), (-.30, .40), (-.27, .12), (-.20, -.06)], lh=(-.20, -.06, 'hand'),
                         r=[(.12, .54), (.30, .40), (.27, .12), (.20, -.06)], rh=(.20, -.06, 'hand')),
        'cross': dict(l=[(-.12, .54), (-.02, .62), (.1, .64)], lh=(.115, .645, 'hand'),
                      r=[(.12, .54), (.02, .6), (-.1, .64)], rh=(-.115, .645, 'hand')),
        'fight': dict(l=[(-.13, .54), (-.24, .62), (-.2, .54)], lh=(-.18, .47, 'fist'),
                      r=[(.13, .54), (.24, .62), (.2, .54)], rh=(.18, .47, 'fist')),
        'board': dict(l=[(-.12, .54), (-.2, .63), (-.1, .66)], lh=(-.08, .665, 'hand'),
                      r=[(.12, .54), (.2, .63), (.1, .66)], rh=(.08, .665, 'hand')),
    }[pose]
    sleeve = spec.get('sleeve')

    def draw_hand(side):
        hx, hy, kind = poses[side + 'h']
        hx, hy = CX + f(hx), f(hy)
        if kind == 'fist':
            if spec.get('wrap'):
                c.paint(c.rect(hx - f(0.04), hy + f(0.04), hx + f(0.04), hy + f(0.04) + 3), spec['wrap'], shade=False)
            c.paint(c.ell(hx, hy, f(0.06), f(0.055)), hand_pal if not spec.get('wrap') else spec['wrap'])
            c.line((int(hx) - 1, int(hy) + 1), (int(hx) + 1, int(hy) + 1), skin[2])
        else:
            c.paint(c.ell(hx, hy, f(0.045), f(0.04)), hand_pal)

    for side in ('r', 'l'):
        pts = [(CX + f(x), f(y)) for x, y in poses[side]]
        c.paint(c.tube(pts, aw + (1 if spec.get('arm_thick') else 0)), skin)
        if sleeve:
            c.paint(c.tube(pts[:2], aw + 1), sleeve)
        draw_hand(side)

    # --- kepala ---
    head = c.ell(CX, hcy, hrx, hry)
    c.paint(head, skin, depth=1)

    # rambut
    hair = spec.get('hair')
    hp = spec.get('hair_pal', HAIR)
    hl = hcy - 0.58 * hry
    if hair:
        m = set()
        for y in range(-40, 20):
            for x in range(-32, 80):
                if ((x + 0.5 - CX) / (hrx + 1.0)) ** 2 + ((y + 0.5 - hcy) / (hry + 1.0)) ** 2 <= 1.0:
                    zig = (1 if (x // 2) % 2 else 0)
                    if y + 0.5 < hl + zig:
                        m.add((x, y))
        if hair == 'spiky':
            n_sp = spec.get('spikes', 5)
            pk = spec.get('peak', 1.42)
            for i in range(n_sp):
                ang = math.radians(205 + 130 * (i + 0.5) / n_sp)
                da = math.radians(130 / n_sp / 2 + 3)
                r1 = pk if i % 2 == 0 else pk - 0.12
                if i == n_sp // 2:
                    r1 += 0.2
                pts = [(CX + math.cos(ang - da) * (hrx + 0.5), hcy + math.sin(ang - da) * (hry + 0.5)),
                       (CX + math.cos(ang) * hrx * r1, hcy + math.sin(ang) * hry * r1),
                       (CX + math.cos(ang + da) * (hrx + 0.5), hcy + math.sin(ang + da) * (hry + 0.5))]
                m |= c.poly(pts)
        elif hair == 'swept':
            quiff = c.poly([(CX - hrx * 0.7, hcy - hry * 0.9), (CX + hrx * 0.1, hcy - hry * 1.55),
                            (CX + hrx * 1.25, hcy - hry * 1.35), (CX + hrx * 0.8, hcy - hry * 0.85)])
            m |= quiff
        elif hair == 'flat':
            m = {q for q in m if q[1] >= hcy - hry - 1}
            m |= c.rect(CX - hrx - 1, hcy - hry - 1, CX + hrx + 1, hl + 2)
            m = {q for q in m if ((q[0] + 0.5 - CX) / (hrx + 2.0)) ** 2 + ((q[1] + 0.5 - hcy) / (hry + 2.5)) ** 2 <= 1.2}
        c.paint(m, hp, depth=1)
    if spec.get('hat') == 'chef':
        hat = c.rect(CX - 10, hcy - hry - 2, CX + 10, hcy - hry + 4)
        pf = c.ell(CX - 7, hcy - hry - 6, 7, 6) | c.ell(CX + 7, hcy - hry - 6, 7, 6) | c.ell(CX, hcy - hry - 9, 8, 7)
        c.paint(pf | hat, WHITE, depth=1)
        for x in range(int(CX - 10), int(CX + 10)):
            c.put(x, int(hcy - hry + 1), WHITE[2])
    if spec.get('band'):
        by0, by1 = hcy - 0.58 * hry, hcy - 0.36 * hry
        band = set()
        for x in range(-32, 80):
            u = (x + 0.5 - CX) / hrx
            if abs(u) > 1.02:
                continue
            sh = round(1.3 * (1 - u * u))
            for y in range(int(by0 + sh), int(by1 + sh) + 1):
                if ((x + 0.5 - CX) / (hrx + 0.8)) ** 2 + ((y + 0.5 - hcy) / (hry + 0.8)) ** 2 <= 1.0:
                    band.add((x, y))
        c.paint(band, spec['band'], depth=1)

    # --- wajah ---
    face = spec.get('face', 'hype')
    ey, my = 16, 24
    if face == 'hype':
        eye = ["OOOOO.", "OyyeeO", "OyyeeO", "OeeeeO", "OeppeO", "OpppeO", ".OOOO."]
        for ex in (14, 28):
            c.stamp(ex, ey, eye, KEY)
        for ex, sgn in ((14, -1), (28, 1)):
            xo = ex - 1 if sgn < 0 else ex + 6
            c.put(xo, ey, OUT)
            c.put(xo, ey - 1, OUT)
        c.stamp(int(CX - 4.5), my, ["OOOOOOOOO", "OwwwwwwwO", "OkkkkkkkO", ".OktttkO.", "..OOOOO.."], KEY)
        blush = True
    elif face == 'smug':
        lens = [".OOOOOOO.", "OllllllllO"[:9], "OdddddddO", "OlwwwwwwO", "OlpplwwlO", "OlpplwwlO", "OllllllllO"[:9], ".OOOOOOO."]
        lens = [".OOOOOOO.", "OlllllllO", "OdddddddO", "OlwwwwwlO", "OlppwwwlO", "OlppwwwlO", "OlllllllO", ".OOOOOOO."]
        c.stamp(12, ey - 1, lens, KEY)
        c.stamp(27, ey - 1, lens, KEY)
        c.line((21, ey + 2), (26, ey + 2), OUT)
        c.stamp(int(CX - 3), my + 1, [".....OO", "OOOOO.."], KEY)
        blush = False
    elif face == 'cheer':
        arc = [".OOOO.", "O....O"]
        for ex in (14, 28):
            c.stamp(ex, ey + 1, arc, KEY)
        c.stamp(int(CX - 5.5), my - 1, ["OOOOOOOOOOO", "OwwwwwwwwwO", "OkkkkkkkkkO", ".OkkttkkkO.", "..OOOOOOO.."], KEY)
        blush = True
    elif face == 'calm':
        eye = ["OOOO", "OyeO", "OeeO", "OppO", ".OO."]
        for ex in (15, 29):
            c.stamp(ex, ey + 1, eye, KEY)
        c.stamp(int(CX - 3.5), my + 1, ["O.....O", ".OOOOO."], KEY)
        blush = True
    elif face == 'angry':
        eye = ["OOOOOO", "OwwppO", ".OOOO."]
        for ex in (14, 28):
            c.stamp(ex, ey + 2, eye, KEY)
        c.line((13, ey - 1), (20, ey + 2), OUT, th=2)
        c.line((34, ey - 1), (27, ey + 2), OUT, th=2)
        c.stamp(int(CX - 4.5), my + 1, ["OOOOOOOOO", "OwOwOwOwO", "OOOOOOOOO"], KEY)
        blush = False
    if blush and face != 'calm':
        for ex, sgn in ((14, -1), (28, 1)):
            c.put(ex - 1 if sgn < 0 else ex + 6, ey + 7, BLUSH)
            c.put(ex if sgn < 0 else ex + 5, ey + 7, BLUSH)
    if pose == 'globe_up':
        canvas_globe(c, CX, -4, 8)
        draw_hand('l')
        draw_hand('r')
    if spec.get('scar'):
        c.line((30, ey + 6), (33, ey + 9), RED[2])
    if spec.get('stache'):
        c.stamp(int(CX - 4), my - 2, ["OO.....OO"[:9] if False else "OOO...OOO"], KEY)
    return c


# ---------------- spesifikasi karakter ----------------
HERO = dict(hair='spiky', hair_pal=HAIR, band=RED, top=WHITE, stripe=RED, bottom=NAVY, shoe=RED, face='hype')
BOB = dict(hair='spiky', hair_pal=pal((28, 26, 36)), spikes=6, peak=1.5, top=WHITE, vest=pal((70, 78, 120)),
           neck=BLUE, neck_kind='bow', bottom=DGREY, long_pants=True, shoe=BLACKP, face='smug', pose='cross')
ASEP = dict(hair='swept', hair_pal=BROWNH, top=GREEN, bottom=KHAKI, shoe=BROWN, face='calm', pose='board')
CHEF = dict(hat='chef', top=WHITE, apron=pal((248, 248, 252)), neck=RED, neck_kind='scarf', bottom=pal((70, 70, 90)),
            long_pants=True, shoe=BLACKP, face='cheer', pose='stand', torso_w=0.15, arm_thick=True)
ROCK = dict(hair='flat', hair_pal=pal((90, 92, 104)), top=BLACKP, belt=ORANGE, bottom=BLACKP, shoe=BLACKP,
            face='angry', pose='fight', torso_w=0.16, arm_thick=True, wrap=WHITE, scar=True, legs='wide')


def with_pose(spec, **kw):
    d = dict(spec)
    d.update(kw)
    return d
