#!/usr/bin/env python3
"""Pose petarung Level Fight: sumber tunggal untuk gambar (generate_art.py) dan game (Dart).

Bingkai lokal 1000 x 1400, menghadap KANAN, tanah di y = 1262 (sama seperti POSES di
generate_art.py). Jalankan dari root proyek:

    python tools/art/fight_poses.py            # tulis lib/levels/fight/pose_library.dart
    python tools/art/fight_poses.py --sheet    # tulis juga lembar pratinjau di /tmp/fight_poses.png

Format pose: head, hip, arm_f/arm_b = (siku, tangan), leg_f/leg_b = (lutut, pergelangan, ujung kaki).
Bahu dihitung otomatis (18% dari leher ke pinggul). `neck` opsional (default tepat di bawah
kepala), `over=True` menggambar lengan DI ATAS kepala (dipakai untuk tangkis).
"""
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
R = 150          # jari-jari kepala acuan (pemain)
GROUND = 1262
ROOT_X = 500


def pose(head, hip, arm_f, arm_b, leg_f, leg_b, neck=None, over=False, fist_f=True, fist_b=True):
    return dict(head=head, hip=hip, arm_f=arm_f, arm_b=arm_b, leg_f=leg_f, leg_b=leg_b,
                neck=neck or (head[0], head[1] + R), over=over, fist_f=fist_f, fist_b=fist_b)


FIGHT_POSES = {
    # --- diam (kuda-kuda petarung) ---
    'idle_a': pose((520, 330), (490, 860),
                   ((630, 655), (730, 555)), ((545, 685), (640, 595)),
                   ((600, 1040), (630, 1250), (705, 1262)), ((410, 1050), (340, 1250), (415, 1262))),
    'idle_b': pose((518, 342), (490, 876),
                   ((630, 672), (728, 572)), ((542, 700), (628, 610)),
                   ((612, 1050), (630, 1250), (705, 1262)), ((405, 1058), (340, 1250), (415, 1262))),
    # --- jalan (langkah geser petarung) ---
    'walk_a': pose((525, 330), (495, 855),
                   ((635, 655), (735, 555)), ((550, 685), (645, 595)),
                   ((640, 1000), (700, 1190), (775, 1200)), ((400, 1050), (335, 1250), (410, 1262))),
    'walk_b': pose((535, 332), (505, 865),
                   ((640, 660), (740, 560)), ((555, 690), (650, 600)),
                   ((630, 1040), (690, 1250), (765, 1262)), ((400, 1050), (310, 1240), (385, 1252))),
    'walk_c': pose((545, 332), (520, 862),
                   ((640, 660), (740, 560)), ((555, 690), (650, 600)),
                   ((650, 1040), (690, 1250), (765, 1262)), ((470, 1050), (430, 1250), (505, 1262))),
    # --- pukul (jab: tangan depan) ---
    'punch_wind': pose((505, 335), (485, 862),
                       ((590, 700), (585, 600)), ((545, 690), (650, 580)),
                       ((590, 1045), (625, 1250), (700, 1262)), ((405, 1050), (335, 1250), (410, 1262))),
    'punch_hit': pose((560, 328), (510, 858),
                      ((720, 585), (885, 555)), ((555, 690), (640, 585)),
                      ((650, 1035), (695, 1250), (770, 1262)), ((420, 1050), (345, 1250), (420, 1262))),
    # --- pukul 2 (cross: tangan belakang) ---
    'cross_wind': pose((500, 335), (480, 865),
                       ((630, 655), (720, 560)), ((505, 700), (525, 590)),
                       ((600, 1040), (630, 1250), (705, 1262)), ((410, 1050), (340, 1250), (415, 1262))),
    'cross_hit': pose((570, 330), (520, 860),
                      ((620, 665), (700, 580)), ((705, 590), (880, 560)),
                      ((640, 1040), (680, 1250), (755, 1262)), ((440, 1050), (390, 1250), (465, 1262))),
    # --- tendang ---
    'kick_wind': pose((470, 338), (450, 868),
                      ((560, 665), (640, 570)), ((500, 690), (580, 600)),
                      ((630, 950), (590, 1155), (665, 1165)), ((440, 1050), (420, 1250), (495, 1262))),
    'kick_hit': pose((400, 365), (430, 885),
                     ((500, 700), (420, 610)), ((520, 690), (600, 610)),
                     ((630, 900), (830, 870), (905, 850)), ((440, 1065), (420, 1250), (495, 1262))),
    # --- lempar pisau ---
    'throw_wind': pose((480, 335), (480, 860),
                       ((450, 440), (370, 240)), ((560, 680), (640, 590)),
                       ((600, 1040), (630, 1250), (705, 1262)), ((410, 1050), (340, 1250), (415, 1262))),
    'throw_hit': pose((530, 330), (490, 860),
                      ((680, 520), (845, 470)), ((560, 680), (630, 600)),
                      ((620, 1040), (665, 1250), (740, 1262)), ((410, 1050), (335, 1250), (410, 1262))),
    # --- tangkis (lengan di depan wajah) ---
    'block': pose((500, 355), (470, 885),
                  ((610, 640), (640, 450)), ((560, 655), (600, 450)),
                  ((590, 1050), (610, 1250), (685, 1262)), ((400, 1055), (350, 1250), (425, 1262)),
                  over=True),
    # --- terkena, jatuh, KO ---
    'hurt': pose((430, 352), (440, 880),
                 ((320, 650), (240, 760)), ((300, 600), (200, 540)),
                 ((540, 1050), (560, 1250), (635, 1262)), ((360, 1050), (310, 1250), (385, 1262))),
    'fall': pose((250, 700), (410, 940),
                 ((330, 720), (320, 570)), ((260, 720), (200, 590)),
                 ((560, 1000), (640, 1150), (715, 1150)), ((470, 1080), (530, 1220), (605, 1230))),
    'ko': pose((150, 1112), (650, 1225),
               ((480, 1150), (385, 1065)), ((470, 1240), (590, 1245)),
               ((810, 1190), (950, 1235), (1020, 1240)), ((830, 1235), (980, 1250), (1050, 1255)),
               neck=(290, 1170), fist_f=False, fist_b=False),
    # --- ekspresi ---
    'win': pose((480, 330), (470, 860),
                ((640, 455), (690, 260)), ((390, 700), (400, 830)),
                ((590, 1040), (650, 1250), (725, 1262)), ((350, 1040), (300, 1250), (375, 1262))),
    'taunt': pose((500, 312), (500, 860),
                  ((660, 540), (790, 430)), ((340, 540), (210, 430)),
                  ((600, 1040), (660, 1250), (735, 1262)), ((400, 1040), (340, 1250), (415, 1262))),
    # --- pukulan berat (aba-aba merah dan hantaman) ---
    'heavy_wind': pose((440, 380), (440, 930),
                       ((380, 720), (260, 650)), ((540, 740), (620, 650)),
                       ((620, 1070), (650, 1250), (725, 1262)), ((330, 1080), (260, 1250), (335, 1262))),
    'heavy_hit': pose((640, 370), (520, 900),
                      ((780, 640), (950, 600)), ((600, 740), (680, 660)),
                      ((680, 1050), (740, 1250), (815, 1262)), ((400, 1080), (290, 1230), (360, 1250))),
}


# ---------------- konversi ----------------
def shoulder(p):
    nx, ny = p['neck']
    hx, hy = p['hip']
    return (nx + (hx - nx) * 0.18, ny + (hy - ny) * 0.18)


def to_draw_format(p):
    """Format POSES milik generate_art.draw_figure (pratinjau dan aset gambar)."""
    sh = shoulder(p)
    hip = p['hip']
    return dict(
        head=p['head'], hip=hip, neck=p['neck'], over=p['over'],
        arm_f=[sh, *p['arm_f']], arm_b=[sh, *p['arm_b']],
        leg_f=[hip, *p['leg_f']], leg_b=[hip, *p['leg_b']],
        fist_f=p['fist_f'], fist_b=p['fist_b'],
    )


def check_limbs():
    """Peringatan jika panjang anggota badan menyimpang jauh (tanda salah ketik koordinat)."""
    bad = []
    for name, p in FIGHT_POSES.items():
        sh, hip = shoulder(p), p['hip']
        for side in ('f', 'b'):
            elbow, hand = p['arm_' + side]
            for label, a, b in (('lengan atas', sh, elbow), ('lengan bawah', elbow, hand)):
                d = math.dist(a, b)
                if not 100 <= d <= 230:
                    bad.append(f'{name}.arm_{side} {label}: {d:.0f}')
            knee, ankle, _ = p['leg_' + side]
            for label, a, b in (('paha', hip, knee), ('betis', knee, ankle)):
                d = math.dist(a, b)
                if not 140 <= d <= 260:
                    bad.append(f'{name}.leg_{side} {label}: {d:.0f}')
    return bad


# ---------------- keluaran Dart ----------------
def camel(name):
    head, *rest = name.split('_')
    return head + ''.join(w.capitalize() for w in rest)


def off(pt):
    return f'Offset({pt[0] - ROOT_X:.1f}, {pt[1] - GROUND:.1f})'


def emit_dart():
    lines = [
        '// GENERATED oleh tools/art/fight_poses.py - jangan diedit manual.',
        '// Ubah pose di skrip itu lalu jalankan: python tools/art/fight_poses.py',
        "import 'dart:ui' show Offset;",
        '',
        "import 'pose.dart';",
        '',
        '/// Koordinat relatif terhadap titik tanah di bawah pinggul (x ke depan, y ke bawah).',
        'abstract final class Poses {',
    ]
    for name, p in FIGHT_POSES.items():
        nx, ny = p['neck']
        hx, hy = p['head']
        dx, dy = hx - nx, hy - ny
        ln = math.hypot(dx, dy) or 1.0
        lines += [
            f'  static const {camel(name)} = Pose(',
            f'    neck: {off(p["neck"])},',
            f'    headDir: Offset({dx / ln:.4f}, {dy / ln:.4f}),',
            f'    hip: {off(p["hip"])},',
            f'    elbowF: {off(p["arm_f"][0])}, handF: {off(p["arm_f"][1])},',
            f'    elbowB: {off(p["arm_b"][0])}, handB: {off(p["arm_b"][1])},',
            f'    kneeF: {off(p["leg_f"][0])}, ankleF: {off(p["leg_f"][1])}, toeF: {off(p["leg_f"][2])},',
            f'    kneeB: {off(p["leg_b"][0])}, ankleB: {off(p["leg_b"][1])}, toeB: {off(p["leg_b"][2])},',
            f'    armsOver: {str(p["over"]).lower()},',
            f'    fistF: {str(p["fist_f"]).lower()},',
            f'    fistB: {str(p["fist_b"]).lower()},',
            '  );',
        ]
    lines += ['}', '']
    return '\n'.join(lines)


def write_dart():
    out = ROOT / 'lib/levels/fight/pose_library.dart'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(emit_dart(), encoding='utf-8')
    print('ditulis', out.relative_to(ROOT), f'({len(FIGHT_POSES)} pose)')


def write_sheet(path='/tmp/fight_poses.png'):
    sys.path.insert(0, str(Path(__file__).parent))
    import generate_art as ga
    from PIL import Image, ImageDraw
    names = list(FIGHT_POSES)
    cols = 6
    cw, ch = 330, 470
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new('RGBA', (cols * cw, rows * ch), (255, 235, 238, 255))
    for i, name in enumerate(names):
        ga.POSES['_f_' + name] = to_draw_format(FIGHT_POSES[name])
        a = ga.Art(cw, ch)
        scale = 0.30
        ga.draw_figure(a, '_f_' + name, 'mc_hype', 10, 10 + 8, scale, lw=22, acc=('headband',))
        # garis tanah
        a.line([(0, 10 + 1262 * scale + 10), (cw, 10 + 1262 * scale + 10)], 2, (120, 120, 120, 255))
        tile = a.final()
        ImageDraw.Draw(tile).text((8, 6), name, fill=(0, 0, 0, 255))
        sheet.alpha_composite(tile, ((i % cols) * cw, (i // cols) * ch))
    sheet.convert('RGB').save(path)
    print('ditulis', path)


if __name__ == '__main__':
    problems = check_limbs()
    for msg in problems:
        print('PERINGATAN panjang anggota badan:', msg)
    write_dart()
    if '--sheet' in sys.argv:
        write_sheet()
