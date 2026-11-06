"""Ikon aplikasi bergaya piksel: wajah pemain di depan sinar matahari.

    python tools/art/pixel_icon.py [folder_keluaran]
Menimpa assets/icon/app_icon.png (1024 RGB, kisi 128 x8) dan app_icon_fg.png (1024 RGBA, latar transparan,
wajah lebih kecil agar muat di zona aman ikon adaptif Android). Latar adaptif: lihat adaptive_icon_background di pubspec.yaml.
Setelah mengganti: dart run flutter_launcher_icons
"""
import math
import sys
from pathlib import Path

import pixel_kit as k
import pixel_scenes as ps

ROOT = ps.ROOT
RAYS = (ps.C(255, 170, 56), ps.C(255, 202, 104))
G = 128


def head_only(tails=True):
    c = k.build(k.with_pose(k.HERO, pose='stand', face='hype', no_tails=not tails, head_only=True))
    xs, ys = [], []
    for y in range(c.s):
        for x in range(c.s):
            if c.g[y][x]:
                xs.append(x - c.ox)
                ys.append(y - c.oy)
    return c, ((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2)


def draw(scale, center, with_bg, tails=True):
    sc = ps.Scene(G, G)
    if with_bg:
        cx, cy = G / 2, G / 2 + 2
        for y in range(G):
            for x in range(G):
                ang = math.atan2(y - cy, x - cx)
                sc.set(x, y, RAYS[int((ang + math.pi) / (2 * math.pi) * 16) % 2])
    c, (hx, hy) = head_only(tails)
    # titik tengah kepala dipusatkan di kanvas
    bx = center[0] - (hx - k.CX) * scale
    by = center[1] - (hy - 47) * scale
    sc.blit(c, round(bx), round(by), scale=scale)
    return sc


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/icon'
    out.mkdir(parents=True, exist_ok=True)
    draw(3, (G / 2, G / 2), True, tails=False).image(8).convert('RGB').save(out / 'app_icon.png', optimize=True)
    draw(2, (G / 2, G / 2), False).image(8).save(out / 'app_icon_fg.png', optimize=True)
    print('ikon piksel ditulis ke', out)


if __name__ == '__main__':
    main()
