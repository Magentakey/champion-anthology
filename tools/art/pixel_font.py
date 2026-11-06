"""Membuat font TTF piksel 5x7 dari tabel GLYPH di pixel_scenes.py (huruf besar saja).

    python tools/art/pixel_font.py            # menulis assets/fonts/PixelChampion.ttf (butuh fonttools)

Ukuran: unitsPerEm 1000, 1 piksel font = 100 unit, tinggi huruf = 7 piksel (700 unit), lebar maju = 6 piksel.
Di Flutter, fontSize = 10 * (dp per piksel) sehingga 1 piksel font jatuh tepat pada kelipatan layar.
Huruf kecil dipetakan ke bentuk huruf besar (teks "Main" tampil "MAIN").
"""
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

import pixel_scenes as ps

ROOT = Path(__file__).resolve().parents[2]
PX = 100

EXTRA = {
    ':': ".....|..##.|..##.|.....|..##.|..##.|.....",
    ';': ".....|..##.|..##.|.....|..##.|..#..|.#...",
    "'": "..#..|..#..|.#...|.....|.....|.....|.....",
    '(': "...#.|..#..|.#...|.#...|.#...|..#..|...#.",
    ')': ".#...|..#..|...#.|...#.|...#.|..#..|.#...",
    '/': "....#|....#|...#.|..#..|.#...|#....|#....",
    '+': ".....|..#..|..#..|#####|..#..|..#..|.....",
    '=': ".....|.....|#####|.....|#####|.....|.....",
    '%': "##..#|##..#|...#.|..#..|.#...|#..##|#..##",
    '<': "...#.|..#..|.#...|#....|.#...|..#..|...#.",
    '"': "#.#..|#.#..|.....|.....|.....|.....|.....",
    '*': ".....|#.#.#|.###.|#####|.###.|#.#.#|.....",
    '\u2026': ".....|.....|.....|.....|.....|.....|#.#.#",
}


def glyph_rows():
    rows = {ch: g for ch, g in ps.GLYPH.items() if ch not in ('V_',)}
    for ch, s in EXTRA.items():
        rows[ch] = s.split('|')
    return rows


def rects_for(rows):
    """Gabungkan piksel horizontal berurutan menjadi persegi panjang."""
    out = []
    for j, row in enumerate(rows):
        i = 0
        while i < len(row):
            if row[i] == '#':
                k = i
                while k < len(row) and row[k] == '#':
                    k += 1
                y1 = (7 - j) * PX
                out.append((i * PX, y1 - PX, k * PX, y1))
                i = k
            else:
                i += 1
    return out


def build(path):
    rows = glyph_rows()
    names = ['.notdef']
    cmap = {}
    glyphs = {}
    metrics = {}

    def add(name, rects):
        pen = TTGlyphPen(None)
        for (x0, y0, x1, y1) in rects:
            pen.moveTo((x0, y0))
            pen.lineTo((x0, y1))
            pen.lineTo((x1, y1))
            pen.lineTo((x1, y0))
            pen.closePath()
        glyphs[name] = pen.glyph()
        metrics[name] = (6 * PX, min([r[0] for r in rects], default=0))
        names.append(name)

    # .notdef: kotak kosong bergaris tepi tipis agar karakter tak dikenal terlihat
    notdef = [(0, 0, 500, 100), (0, 600, 500, 700), (0, 100, 100, 600), (400, 100, 500, 600)]
    pen = TTGlyphPen(None)
    for (x0, y0, x1, y1) in notdef:
        pen.moveTo((x0, y0))
        pen.lineTo((x0, y1))
        pen.lineTo((x1, y1))
        pen.lineTo((x1, y0))
        pen.closePath()
    glyphs['.notdef'] = pen.glyph()
    metrics['.notdef'] = (6 * PX, 0)

    for ch, grid in rows.items():
        name = 'uni%04X' % ord(ch)
        add(name, rects_for(grid))
        cmap[ord(ch)] = name
        if ch.isalpha() and ch.isupper():
            lower = ch.lower()
            cmap[ord(lower)] = name        # huruf kecil memakai bentuk huruf besar
    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder(names)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({'familyName': 'PixelChampion', 'styleName': 'Regular'})
    fb.setupOS2(sTypoAscender=800, sTypoDescender=-200, sTypoLineGap=0, usWinAscent=800, usWinDescent=200,
                sxHeight=700, sCapHeight=700, achVendID='CHMP')
    fb.setupPost()
    path.parent.mkdir(parents=True, exist_ok=True)
    fb.save(str(path))
    return len(rows)


if __name__ == '__main__':
    n = build(ROOT / 'assets/fonts/PixelChampion.ttf')
    print('font ditulis, glyph:', n)
