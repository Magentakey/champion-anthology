"""Sprite petarung Level 1 (pemain dan Rock) bergaya chibi piksel, satu gambar per pose.

Membaca data pose yang sama dengan game (lib/levels/fight/pose_library.dart), memetakan sendi stickman
ke badan chibi (kaki dan badan dipendekkan, kepala besar), lalu menggambar tiap pose dengan perangkat piksel.
Pose menghadap kanan; game membalik gambar saat menghadap kiri.

    python tools/art/pixel_fighters.py [folder_keluaran]
Menulis assets/images/fight/player_sheet.png dan rock_sheet.png (urutan bingkai = urutan pose di pose_library.dart).
"""
import math
import re
import sys
from pathlib import Path

from PIL import Image

import pixel_kit as k
import pixel_scenes as ps

ROOT = Path(__file__).resolve().parents[2]
U = 18.0              # satuan ruang pose per piksel sprite
FRAME = 96            # bingkai 96 x 96 piksel
OX, OY = 40, 68       # titik tanah di bawah pinggul (x, y) pada bingkai
LEG = 0.60            # pemendekan kaki
TORSO = 0.50          # pemendekan badan
ARM = 1.0
HEAD_RISE = 10.5      # pusat kepala di atas leher (piksel)

SPRITE_FACE = {       # pose -> keadaan wajah
    'idleA': 'idle', 'idleB': 'idle', 'walkA': 'idle', 'walkB': 'idle', 'walkC': 'idle',
    'punchWind': 'attack', 'punchHit': 'attack', 'crossWind': 'attack', 'crossHit': 'attack',
    'kickWind': 'attack', 'kickHit': 'attack', 'throwWind': 'attack', 'throwHit': 'attack',
    'block': 'block', 'hurt': 'hurt', 'fall': 'ko', 'ko': 'ko', 'win': 'win', 'taunt': 'taunt',
    'heavyWind': 'attack', 'heavyHit': 'attack',
}


def load_poses():
    s = (ROOT / 'lib/levels/fight/pose_library.dart').read_text()
    order, poses = [], {}
    for m in re.finditer(r"static const (\w+) = Pose\((.*?)\n  \);", s, re.S):
        d = {}
        for f in re.finditer(r"(\w+): Offset\((-?[\d.]+), (-?[\d.]+)\)", m.group(2)):
            d[f.group(1)] = (float(f.group(2)), float(f.group(3)))
        for f in re.finditer(r"(armsOver|fistF|fistB): (true|false)", m.group(2)):
            d[f.group(1)] = f.group(2) == 'true'
        order.append(m.group(1))
        poses[m.group(1)] = d
    return order, poses


# ---------------- karakter ----------------
PLAYER = dict(
    spec=k.HERO, torso=k.WHITE, stripe=k.RED, shorts=k.NAVY, shoe=k.RED, skin=k.SKIN,
    sleeve=None, limb=4.0, torso_w=12.0, fist=None, pants=None,
    faces={'idle': 'fighter', 'block': 'fighter', 'attack': 'hype', 'taunt': 'hype',
           'hurt': 'shock', 'ko': 'defeat', 'win': 'laugh'},
)
ROCK_SKIN = k.pal((214, 160, 118))
ROCK = dict(
    spec=dict(k.ROCK, skin=ROCK_SKIN, long_pants=True, bottom=k.DGREY), torso=k.BLACKP, stripe=None, shorts=k.DGREY, shoe=k.BLACKP, skin=ROCK_SKIN,
    sleeve=None, limb=5.0, torso_w=15.0, fist=k.WHITE, pants=k.DGREY,
    faces={'idle': 'angry', 'block': 'angry', 'attack': 'angry_shout', 'taunt': 'angry_shout',
           'hurt': 'shock', 'ko': 'defeat', 'win': 'laugh'},
    belt=k.ORANGE,
)


def head_pixels(ch, face_state, direction):
    """Piksel kepala (koordinat karakter relatif pusat kepala), dicerminkan dan diputar bila perlu."""
    spec = k.with_pose(ch['spec'], head_only=True, face=ch['faces'][face_state], pose='stand')
    c = k.build(spec)
    pts = []
    for y in range(c.s):
        for x in range(c.s):
            col = c.g[y][x]
            if col:
                pts.append((x - c.ox, y - c.oy, col))
    cx, cy = 24.0, 17.3
    out = []
    for x, y, col in pts:
        dx, dy = (47 - x) - cx, y - cy                      # cermin: ekor ikat kepala di belakang
        out.append((dx, dy, col))
    ang = math.degrees(math.atan2(direction[0], -direction[1]))
    if abs(ang) > 45:                                        # kepala rebah (KO): putar 90 derajat
        quarter = 1 if ang > 0 else -1
        rot = []
        for dx, dy, col in out:
            rot.append((-dy, dx, col) if quarter > 0 else (dy, -dx, col))
        out = rot
    return out


def ell_pts(cx, cy, rx, ry, ang, n=28):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x, y = rx * math.cos(t), ry * math.sin(t)
        pts.append((cx + x * math.cos(ang) - y * math.sin(ang), cy + x * math.sin(ang) + y * math.cos(ang)))
    return pts


def render_pose(name, pose, ch):
    c = k.Canvas(FRAME, OX, OY)
    P = pose

    def sv(a, b):                      # selisih a - b dalam ruang pose
        return (a[0] - b[0], a[1] - b[1])

    hip_px = (P['hip'][0] / U, P['hip'][1] * LEG / U)
    neck_px = (hip_px[0] + (P['neck'][0] - P['hip'][0]) * TORSO / U, hip_px[1] + (P['neck'][1] - P['hip'][1]) * TORSO / U)
    sh_pose = (P['neck'][0] + (P['hip'][0] - P['neck'][0]) * 0.18, P['neck'][1] + (P['hip'][1] - P['neck'][1]) * 0.18)
    sh_px = (neck_px[0] + (hip_px[0] - neck_px[0]) * 0.18, neck_px[1] + (hip_px[1] - neck_px[1]) * 0.18)

    def leg_pt(j):
        v = sv(P[j], P['hip'])
        return (hip_px[0] + v[0] * LEG / U, hip_px[1] + v[1] * LEG / U)

    def arm_pt(j):
        v = sv(P[j], sh_pose)
        return (sh_px[0] + v[0] * ARM / U, sh_px[1] + v[1] * ARM / U)

    skin = ch['skin']
    limb = ch['limb']

    def arm(side):
        e, h = arm_pt('elbow' + side), arm_pt('hand' + side)
        pts = [sh_px, e, h]
        c.paint(c.tube(pts, limb), skin)
        if ch['sleeve']:
            mid = (sh_px[0] + (e[0] - sh_px[0]) * 0.85, sh_px[1] + (e[1] - sh_px[1]) * 0.85)
            c.paint(c.tube([sh_px, mid], limb + 1.2), ch['sleeve'])
        fist = P['fist' + side]
        if fist:
            col = ch['fist'] or skin
            c.paint(c.ell(h[0], h[1], 2.9 if not ch['fist'] else 3.5, 2.7 if not ch['fist'] else 3.3), col, depth=1)
        else:
            c.paint(c.ell(h[0], h[1], 2.4, 2.3), skin, depth=1)

    def leg(side):
        kn, an, toe = leg_pt('knee' + side), leg_pt('ankle' + side), leg_pt('toe' + side)
        c.paint(c.tube([hip_px, kn, an], limb + 0.4), ch['pants'] or skin)
        fv = (P['toe' + side][0] - P['ankle' + side][0], P['toe' + side][1] - P['ankle' + side][1])
        ang = math.atan2(fv[1], fv[0]) if (abs(fv[0]) + abs(fv[1])) > 1 else 0.0
        flen = math.hypot(fv[0], fv[1]) / U + 3.2
        fc = (an[0] + math.cos(ang) * flen * 0.35, an[1] + math.sin(ang) * flen * 0.35 + 0.8)
        c.paint(c.poly(ell_pts(fc[0], fc[1], max(3.4, flen * 0.55), 2.5, ang)), ch['shoe'], depth=1)

    def torso_shape():
        tw = ch['torso_w']
        c.paint(c.tube([(hip_px[0], hip_px[1] - 0.5), (neck_px[0], neck_px[1] + 1.5)], tw), ch['torso'])
        if ch['stripe']:
            mx, my = (hip_px[0] + neck_px[0]) / 2, (hip_px[1] + neck_px[1]) / 2
            c.line((round(mx - tw / 2 + 1), round(my)), (round(mx + tw / 2 - 1), round(my)), ch['stripe'][0])
        # celana pendek / pinggul
        c.paint(c.tube([(hip_px[0] - 0.5, hip_px[1] - 0.2), (hip_px[0] + 0.5, hip_px[1] + 2.2)], tw - 1.0), ch['shorts'])
        if ch.get('belt'):
            c.line((round(hip_px[0] - tw / 2 + 1), round(hip_px[1])), (round(hip_px[0] + tw / 2 - 1), round(hip_px[1])), ch['belt'][0], th=2)

    arms_over = P['armsOver']
    # urutan gambar: lengan belakang, kaki belakang, badan, kaki depan, kepala, lengan depan
    if not arms_over:
        arm('B')
    leg('B')
    torso_shape()
    leg('F')
    # kepala
    hc = (neck_px[0] + P['headDir'][0] * HEAD_RISE, neck_px[1] + P['headDir'][1] * HEAD_RISE)
    for dx, dy, col in head_pixels(ch, SPRITE_FACE[name], P['headDir']):
        c.put(round(hc[0] + dx), round(hc[1] + dy), col)
    if arms_over:
        arm('B')
    arm('F')
    return c


def canvas_image(c):
    im = Image.new('RGBA', (c.s, c.s), (0, 0, 0, 0))
    for y in range(c.s):
        for x in range(c.s):
            if c.g[y][x]:
                im.putpixel((x, y), c.g[y][x])
    return im


def sheet(order, poses, ch):
    sh = Image.new('RGBA', (FRAME * len(order), FRAME), (0, 0, 0, 0))
    for i, n in enumerate(order):
        sh.paste(canvas_image(render_pose(n, poses[n], ch)), (i * FRAME, 0))
    return sh


def portrait(ch, face):
    """Potret kepala 256x256 untuk HUD: kepala tanpa ekor ikat kepala, diperbesar 8x."""
    spec = k.with_pose(ch['spec'], head_only=True, no_tails=True, face=face, pose='stand')
    c = k.build(spec)
    pts = [(x, y, c.g[y][x]) for y in range(c.s) for x in range(c.s) if c.g[y][x]]
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    cx, cy = (min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2
    im = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
    for x, y, col in pts:
        px = round(128 + (x - cx) * 8)
        py = round(132 + (y - cy) * 8)
        im.paste(Image.new('RGBA', (8, 8), col), (px, py))
    return im


def rock_intro():
    """Potret Rock untuk intro boss (512x512), berdiri siap tarung."""
    sc = ps.Scene(512, 512)
    sc.blit(k.build(k.with_pose(ROCK['spec'], pose='fight', face='angry')), 256, 492, scale=8)
    return sc.image(1)


def main():
    order, poses = load_poses()
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/images/fight'
    out.mkdir(parents=True, exist_ok=True)
    sheet(order, poses, PLAYER).save(out / 'player_sheet.png', optimize=True)
    sheet(order, poses, ROCK).save(out / 'rock_sheet.png', optimize=True)
    portrait(PLAYER, 'fighter').save(out / 'portrait_player.png', optimize=True)
    portrait(ROCK, 'angry').save(out / 'portrait_rock.png', optimize=True)
    rock_intro().save(out / 'boss_idle.png', optimize=True)
    print('sprite petarung, potret, dan boss Rock ditulis ke', out, '| bingkai:', len(order))


if __name__ == '__main__':
    main()
