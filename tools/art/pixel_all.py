"""Menjalankan semua generator aset piksel berurutan (butuh Pillow dan fonttools; audio terpisah).

    python tools/art/pixel_all.py
"""
import pixel_arena
import pixel_bosses
import pixel_cooking
import pixel_export
import pixel_fighters
import pixel_font
import pixel_icon
import pixel_scenes


def main():
    pixel_font.build(pixel_font.ROOT / 'assets/fonts/PixelChampion.ttf')
    for mod in (pixel_export, pixel_bosses, pixel_cooking, pixel_icon, pixel_fighters, pixel_arena):
        mod.main()
    print('semua aset piksel selesai')


if __name__ == '__main__':
    main()
