"""Ekspor aset gaya piksel ke folder aset game (home, tombol, panel cerita).

    python tools/art/pixel_export.py
Menulis: assets/images/home/home_bg.png, btn_(wide_)primary/secondary.png, assets/images/ui/bg_night.png,
         assets/images/story/panel_1..4.png  (semua diperbesar 3x, tanpa memburamkan).
Font: jalankan juga  python tools/art/pixel_font.py
"""
import pixel_scenes as ps

ROOT = ps.ROOT
SCALE = 3


def main():
    home_dir = ROOT / 'assets/images/home'
    story_dir = ROOT / 'assets/images/story'
    home_dir.mkdir(parents=True, exist_ok=True)
    story_dir.mkdir(parents=True, exist_ok=True)

    ps.home(ui=False).image(SCALE).convert('RGB').save(home_dir / 'home_bg.png', optimize=True)
    ps.button_image(ps.C(226, 64, 56), ps.C(255, 130, 108), ps.C(160, 30, 44)).image(SCALE).save(home_dir / 'btn_primary.png', optimize=True)
    ps.button_image(ps.C(60, 104, 204), ps.C(120, 164, 240), ps.C(34, 58, 140)).image(SCALE).save(home_dir / 'btn_secondary.png', optimize=True)
    ps.button_image(ps.C(226, 64, 56), ps.C(255, 130, 108), ps.C(160, 30, 44), w=160).image(SCALE).save(home_dir / 'btn_wide_primary.png', optimize=True)
    ps.button_image(ps.C(60, 104, 204), ps.C(120, 164, 240), ps.C(34, 58, 140), w=160).image(SCALE).save(home_dir / 'btn_wide_secondary.png', optimize=True)
    ui_dir = ROOT / 'assets/images/ui'
    ui_dir.mkdir(parents=True, exist_ok=True)
    ps.menu_bg().image(SCALE).convert('RGB').save(ui_dir / 'bg_night.png', optimize=True)
    for i, fn in enumerate((ps.panel1, ps.panel2, ps.panel3, ps.panel4), 1):
        fn().image(SCALE).convert('RGB').save(story_dir / f'panel_{i}.png', optimize=True)
    print('aset piksel ditulis ke assets/images/home dan assets/images/story')


if __name__ == '__main__':
    main()
