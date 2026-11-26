"""Gambar boss bergaya piksel: Bob, Asep, Chef, Bima, Lexi, Rhea (4 ekspresi, 512x512, latar transparan).

    python tools/art/pixel_bosses.py
Menimpa assets/images/{genius,maze,cooking,archery,gambler,rhythm}/boss_{idle,shock,laugh,defeat}.png.
Sprite 48 px diperbesar 8x (kelipatan bulat) dan berdiri di dasar kanvas, titik tumpu di tengah.
"""
import sys
from pathlib import Path

from PIL import Image

import pixel_kit as k
import pixel_scenes as ps

ROOT = ps.ROOT
STATES = ('idle', 'shock', 'laugh', 'defeat')
SCALE = 8
FEET = (256, 492)

BOSSES = {
    'genius': k.BOB,
    'maze': k.ASEP,
    'cooking': k.CHEF,
    'archery': k.BIMA,
    'gambler': k.LEXI,
    'rhythm': k.RHEA,
}


def render(name, spec, state):
    sc = ps.Scene(512, 512)
    sp = k.with_expression(spec, state)
    sc.blit(k.build(sp), FEET[0], FEET[1], scale=SCALE)
    if name == 'maze':
        # papan labirin: dipegang saat idle, tergeletak di lantai saat bereaksi
        if state == 'idle':
            board_at = (256, FEET[1] - 12 * SCALE)
        else:
            board_at = (256 + 104, FEET[1] - 8 * SCALE)
        board_big(sc, *board_at, SCALE)
    if name == 'archery':
        if state == 'idle':
            bow_big(sc, 256 + 18 * SCALE, FEET[1] - 18 * SCALE, SCALE, lying=False)
        else:
            bow_big(sc, 256 + 12 * SCALE, FEET[1] - 7 * SCALE, SCALE, lying=True)
    return sc


def bow_big(sc, cx, cy, scale, lying):
    """Busur kayu (garis tepi gelap, tali krem, genggaman merah). lying=True: tergeletak mendatar."""
    import math
    g = ps.Scene(14, 28)
    pts = []
    for i in range(0, 61):
        t = i / 60
        pts.append((round(3 + 7 * math.sin(math.pi * t)), round(1 + 25 * t)))
    for x, y in pts:
        g.set(x, y, ps.C(141, 92, 46))
        g.set(x + 1, y, ps.C(141, 92, 46))
    for y in range(1, 27):
        g.set(3, y, ps.C(236, 236, 236))
    for y in range(11, 17):
        g.set(10, y, ps.C(214, 40, 40))
        g.set(11, y, ps.C(214, 40, 40))
    filled = {(x, y) for y in range(g.H) for x in range(g.W) if g.g[y][x]}
    for (x, y) in list(filled):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in filled:
                g.set(x + dx, y + dy, ps.OUT)
    for y in range(g.H):
        for x in range(g.W):
            col = g.g[y][x]
            if not col:
                continue
            px, py = (y, x) if lying else (x, y)
            w, h = (g.H, g.W) if lying else (g.W, g.H)
            for ky in range(scale):
                for kx in range(scale):
                    sc.set(cx + (px - w // 2) * scale + kx, cy + (py - h // 2) * scale + ky, col)


def board_big(sc, cx, cy, scale):
    tmp = ps.Scene(20, 20)
    ps.board(tmp, 10, 10)
    for y in range(tmp.H):
        for x in range(tmp.W):
            col = tmp.g[y][x]
            if col:
                for ky in range(scale):
                    for kx in range(scale):
                        sc.set(cx + (x - 10) * scale + kx, cy + (y - 10) * scale + ky, col)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    for name, spec in BOSSES.items():
        for state in STATES:
            sc = render(name, spec, state)
            path = (out or ROOT / 'assets/images' / name)
            path.mkdir(parents=True, exist_ok=True)
            sc.image(1).save(path / f'boss_{state}.png', optimize=True)
    print('boss piksel ditulis')


if __name__ == '__main__':
    main()
