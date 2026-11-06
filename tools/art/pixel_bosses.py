"""Gambar boss bergaya piksel: Bob, Asep, Chef (4 ekspresi, 512x512, latar transparan).

    python tools/art/pixel_bosses.py
Menimpa assets/images/{genius,maze,cooking}/boss_{idle,shock,laugh,defeat}.png.
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
    return sc


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
