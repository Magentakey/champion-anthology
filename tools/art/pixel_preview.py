"""Pratinjau gaya pixel art (arah B) untuk karakter pemain, 3 resolusi: 32, 48, 64 px.

Hanya membuat gambar pratinjau (tidak menyentuh aset game):
    python tools/art/pixel_preview.py [folder_keluaran]
Sprite digambar di kanvas kecil tanpa antialiasing lalu diperbesar tanpa memburamkan (nearest).
"""
import math
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BG = (255, 235, 238, 255)

OUT = (24, 18, 34, 255)
SKIN = ((255, 214, 170, 255), (255, 238, 208, 255), (222, 156, 118, 255))     # dasar, terang, gelap
HAIR = ((54, 46, 74, 255), (104, 96, 140, 255), (34, 28, 50, 255))
RED = ((226, 54, 54, 255), (255, 124, 104, 255), (150, 28, 44, 255))
WHITE = ((242, 246, 252, 255), (255, 255, 255, 255), (170, 184, 212, 255))
NAVY = ((56, 76, 148, 255), (92, 118, 190, 255), (34, 48, 100, 255))
BROWN = ((120, 78, 52, 255), (170, 118, 84, 255), (80, 50, 38, 255))
EYE = (92, 56, 40, 255)
PUPIL = (22, 14, 24, 255)
MOUTH = (128, 26, 44, 255)
TONGUE = (244, 118, 128, 255)
BLUSH = (255, 150, 140, 255)
SPARK = (255, 255, 255, 255)


class Px:
    def __init__(self, s):
        self.s = s
        self.g = [[None] * s for _ in range(s)]

    # ---- bentuk (himpunan piksel) ----
    def ell(self, cx, cy, rx, ry):
        return {(x, y) for y in range(self.s) for x in range(self.s)
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0}

    def rect(self, x0, y0, x1, y1):
        return {(x, y) for y in range(int(y0), int(y1)) for x in range(int(x0), int(x1))}

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
        return {(x, y) for y in range(self.s) for x in range(self.s) if inside(x + 0.5, y + 0.5)}

    def tube(self, pts, w):
        out = set()
        r = w / 2
        segs = list(zip(pts, pts[1:]))
        for y in range(self.s):
            for x in range(self.s):
                px, py = x + 0.5, y + 0.5
                for (ax, ay), (bx, by) in segs:
                    dx, dy = bx - ax, by - ay
                    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy + 1e-9)))
                    if math.hypot(px - (ax + t * dx), py - (ay + t * dy)) <= r:
                        out.add((x, y))
                        break
        return out

    # ---- cat ----
    def put(self, x, y, c):
        if 0 <= x < self.s and 0 <= y < self.s:
            self.g[y][x] = c

    def paint(self, mask, pal, shade=True, outline=True, depth=1):
        base, hi, sh = pal
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

    def image(self, scale):
        im = Image.new('RGBA', (self.s, self.s), (0, 0, 0, 0))
        for y in range(self.s):
            for x in range(self.s):
                if self.g[y][x]:
                    im.putpixel((x, y), self.g[y][x])
        return im.resize((self.s * scale, self.s * scale), Image.NEAREST)


def stamp(p, x0, y0, rows, key):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != '.':
                p.put(x0 + i, y0 + j, key[ch])


def player(S, hair='spiky'):
    p = Px(S)
    f = lambda v: v * S
    cx = S / 2
    hcy, hrx, hry = f(0.36), f(0.27), f(0.245)
    bandy0, bandy1 = hcy - 0.58 * hry, hcy - 0.36 * hry

    # ekor ikat kepala (di belakang kepala)
    for k, dy in enumerate((0.0, f(0.05))):
        yy = (bandy0 + bandy1) / 2 + dy
        pts = [(cx + hrx - 1, yy), (cx + hrx + f(0.07), yy + f(0.02) * (1 + k)), (cx + hrx + f(0.13), yy - f(0.02)),
               (cx + hrx + f(0.19), yy + f(0.03) * (1 + k))]
        p.paint(p.tube(pts, max(2.2, f(0.06) - k)), RED)

    # kaki, sepatu, celana
    legy0, legy1 = f(0.74), f(0.86)
    for sg in (-1, 1):
        lx = cx + sg * f(0.075)
        p.paint(p.rect(lx - f(0.04), legy0, lx + f(0.04), legy1), SKIN)
        p.paint(p.ell(lx + sg * f(0.012), f(0.895), f(0.075), f(0.05)), RED)
        p.paint(p.rect(lx - f(0.075) + sg * f(0.012), f(0.915), lx + f(0.075) + sg * f(0.012), f(0.945)), WHITE, shade=False)
    p.paint(p.rect(cx - f(0.145), f(0.66), cx + f(0.145), f(0.775)), NAVY)
    p.put(int(cx), int(f(0.775)) - 1, OUT)

    # badan (kaos putih + garis merah)
    torso = p.rect(cx - f(0.125), f(0.5), cx + f(0.125), f(0.7))
    p.paint(torso, WHITE)
    for y in range(int(f(0.655)), int(f(0.655)) + max(1, round(f(0.025)))):
        for x in range(int(cx - f(0.125)), int(cx + f(0.125))):
            if (x, y) in torso:
                p.put(x, y, RED[0])

    # lengan kanan di pinggang, lengan kiri mengepal ke atas
    aw = max(3, f(0.066))
    p.paint(p.tube([(cx + f(0.12), f(0.54)), (cx + f(0.215), f(0.6)), (cx + f(0.165), f(0.675))], aw), SKIN)
    p.paint(p.ell(cx + f(0.165), f(0.685), f(0.045), f(0.04)), SKIN)
    arm = [(cx - f(0.12), f(0.54)), (cx - f(0.24), f(0.58)), (cx - f(0.29), f(0.5)), (cx - f(0.30), f(0.45))]
    p.paint(p.tube(arm, aw), SKIN)
    fx, fy = cx - f(0.30), f(0.40)
    p.paint(p.rect(fx - f(0.04), f(0.435), fx + f(0.04), f(0.435) + max(2, f(0.035))), RED, shade=False)
    p.paint(p.ell(fx, fy, f(0.06), f(0.055)), SKIN)
    p.line((int(fx) - 1, int(fy) + 1), (int(fx) + 1, int(fy) + 1), SKIN[2])

    # kepala, rambut, ikat kepala
    head = p.ell(cx, hcy, hrx, hry)
    p.paint(head, SKIN, depth=1)

    n_sp = {32: 4, 48: 5, 64: 6}[S]
    hair_m = set()
    hl = hcy - 0.58 * hry
    for x in range(S):
        zig = (1 if (x // 2) % 2 else 0) * (1 if S >= 48 else 0)
        for y in range(S):
            if ((x + 0.5 - cx) / (hrx + 1.0)) ** 2 + ((y + 0.5 - hcy) / (hry + 1.0)) ** 2 <= 1.0 and y + 0.5 < hl + zig:
                hair_m.add((x, y))
    if hair == 'spiky':
        for i in range(n_sp):
            ang = math.radians(205 + 130 * (i + 0.5) / n_sp)
            da = math.radians(130 / n_sp / 2 + 3)
            r0, r1 = (1.0, 1.18 if i % 2 else 1.28) if S == 32 else (1.0, 1.3 if i % 2 else 1.42)
            pts = [(cx + math.cos(ang - da) * (hrx + 0.5), hcy + math.sin(ang - da) * (hry + 0.5)),
                   (cx + math.cos(ang) * hrx * r1, hcy + math.sin(ang) * hry * r1),
                   (cx + math.cos(ang + da) * (hrx + 0.5), hcy + math.sin(ang + da) * (hry + 0.5))]
            hair_m |= p.poly(pts)
    p.paint(hair_m, HAIR, depth=1)

    # ikat kepala
    band = set()
    for x in range(S):
        u = (x + 0.5 - cx) / hrx
        if abs(u) > 1.02:
            continue
        sh = round(1.3 * (1 - u * u)) if S >= 48 else 0
        for y in range(int(bandy0 + sh), int(bandy1 + sh) + 1):
            if (x, y) in head or abs(u) <= 1.02 and ((x + 0.5 - cx) / (hrx + 0.8)) ** 2 + ((y + 0.5 - hcy) / (hry + 0.8)) ** 2 <= 1.0:
                band.add((x, y))
    p.paint(band, RED, depth=1)

    # wajah digambar piksel demi piksel (pola teks). Kunci: O garis, e iris, p pupil, y kilau,
    # k dalam mulut, w gigi, t lidah, b pipi merona, . dilewati (kulit tetap)
    key = {'O': OUT, 'e': EYE, 'p': PUPIL, 'y': SPARK, 'k': MOUTH, 'w': WHITE[0], 't': TONGUE, 'b': BLUSH}
    if S == 48:
        eye_l = ["OOOOO.",
                 "OyyeeO",
                 "OyyeeO",
                 "OeeeeO",
                 "OeppeO",
                 "OpppeO",
                 ".OOOO."]
        mouth = ["OOOOOOOOO",
                 "OwwwwwwwO",
                 "OkkkkkkkO",
                 ".OktttkO.",
                 "..OOOOO.."]
        ey, ex_l, my = 16, 14, 24
    else:  # 32
        eye_l = ["OOOO",
                 "OyeO",
                 "OeeO",
                 "OppO",
                 ".OO."]
        mouth = ["OOOOOOO",
                 "OwwwwwO",
                 ".OkkkO.",
                 "..OOO.."]
        ey, ex_l, my = 11, 9, 16
    eye_r = [r[::-1] for r in eye_l]
    # kilau tetap di kiri atas pada mata kanan (cahaya dari kiri atas)
    eye_r = [r.replace('yy', 'yy') for r in eye_l]
    w_eye = len(eye_l[0])
    ex_r = S - ex_l - w_eye
    stamp(p, ex_l, ey, eye_l, key)
    stamp(p, ex_r, ey, eye_r, key)
    # sudut luar kelopak naik satu piksel (tatapan menukik penuh tekad)
    p.put(ex_l - 1, ey, OUT)
    p.put(ex_l - 1, ey - 1, OUT)
    p.put(ex_r + w_eye, ey, OUT)
    p.put(ex_r + w_eye, ey - 1, OUT)
    # pipi merona
    p.put(ex_l - 1, ey + len(eye_l) - 1, BLUSH)
    p.put(ex_l, ey + len(eye_l), BLUSH)
    p.put(ex_r + w_eye, ey + len(eye_l) - 1, BLUSH)
    p.put(ex_r + w_eye - 1, ey + len(eye_l), BLUSH)
    stamp(p, int(cx - len(mouth[0]) / 2 + 0.5), my, mouth, key)
    return p


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'docs' / 'preview'
    out.mkdir(parents=True, exist_ok=True)
    tiles = []
    old = ROOT / 'assets/images/home/mc_home.png'
    if old.exists():
        im = Image.open(old).convert('RGBA')
        im.thumbnail((512, 512))
        t = Image.new('RGBA', (512, 512), BG)
        t.alpha_composite(im, ((512 - im.width) // 2, (512 - im.height) // 2))
        tiles.append(t)
    for S, scale in ((32, 16), (48, 10)):
        sp = player(S)
        img = sp.image(scale)
        img.save(out / f'player_pixel_{S}.png')
        t = Image.new('RGBA', (512, 512), BG)
        t.alpha_composite(img, ((512 - img.width) // 2, (512 - img.height) // 2))
        tiles.append(t)
    sheet = Image.new('RGB', (512 * len(tiles), 512), BG[:3])
    for i, t in enumerate(tiles):
        sheet.paste(t.convert('RGB'), (i * 512, 0))
    sheet.save(out / 'player_pixel_compare.png')
    print('ditulis', out / 'player_pixel_compare.png')


if __name__ == '__main__':
    main()
