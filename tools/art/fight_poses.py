#!/usr/bin/env python3
"""Pose petarung Level Fight: sumber tunggal data pose untuk game (Dart).

Bingkai lokal 1000 x 1400, menghadap KANAN, tanah di y = 1262. Jalankan dari root proyek:

    python tools/art/fight_poses.py            # tulis lib/levels/fight/pose_library.dart

Sprite petarung dibuat dari data pose yang sama oleh tools/art/pixel_fighters.py (urutan pose di
pose_library.dart = urutan bingkai pada lembar sprite; jalankan pixel_fighters.py lagi setiap pose berubah).

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
    # --- v1.6.0: uppercut (penutup combo pemain) ---
    'uppercut_wind': pose((470, 395), (450, 925),
                          ((560, 800), (620, 940)), ((520, 740), (600, 640)),
                          ((600, 1060), (640, 1250), (715, 1262)), ((380, 1070), (320, 1250), (395, 1262)),
                          neck=(470, 545)),
    'uppercut_hit': pose((560, 320), (500, 850),
                         ((720, 640), (860, 480)), ((560, 680), (630, 590)),
                         ((660, 1030), (700, 1250), (775, 1262)), ((420, 1060), (350, 1240), (425, 1252)),
                         neck=(560, 470)),
    'uppercut_air': pose((580, 230), (510, 720),
                         ((720, 520), (840, 360)), ((560, 590), (640, 520)),
                         ((640, 900), (650, 1100), (725, 1115)), ((430, 900), (400, 1090), (475, 1100)),
                         neck=(580, 380)),
    # --- v1.6.0: reaksi terkena yang berbeda (ringan, terhuyung) ---
    'hurt_light': pose((480, 345), (470, 868),
                       ((560, 650), (630, 560)), ((520, 690), (590, 600)),
                       ((590, 1045), (620, 1250), (695, 1262)), ((400, 1055), (335, 1250), (410, 1262)),
                       neck=(480, 495)),
    'stagger': pose((380, 380), (460, 890),
                    ((340, 690), (290, 590)), ((420, 700), (450, 590)),
                    ((560, 1060), (600, 1250), (675, 1262)), ((380, 1060), (300, 1240), (375, 1252)),
                    neck=(380, 530)),
    # --- v1.6.0: Tendangan Putar dan pukulan terjang Rock ---
    'roundhouse_wind': pose((450, 340), (440, 870),
                            ((540, 650), (620, 570)), ((490, 680), (570, 600)),
                            ((640, 930), (600, 1100), (675, 1105)), ((430, 1060), (410, 1250), (485, 1262)),
                            neck=(450, 490)),
    'roundhouse_hit': pose((380, 380), (420, 890),
                           ((330, 690), (250, 620)), ((460, 700), (540, 640)),
                           ((640, 890), (830, 840), (905, 820)), ((430, 1070), (410, 1250), (485, 1262)),
                           neck=(380, 530)),
    'dash_wind': pose((560, 400), (470, 900),
                      ((500, 730), (440, 640)), ((560, 740), (640, 660)),
                      ((600, 1060), (640, 1250), (715, 1262)), ((380, 1050), (300, 1240), (375, 1252)),
                      neck=(560, 550)),
    'dash_hit': pose((680, 390), (540, 900),
                     ((780, 620), (890, 580)), ((640, 740), (720, 680)),
                     ((700, 1060), (760, 1250), (835, 1262)), ((420, 1080), (310, 1240), (385, 1252)),
                     neck=(680, 540)),
    # --- v1.6.0: napas diam dan langkah lebih halus ---
    'idle_c': pose((522, 322), (490, 848),
                   ((632, 650), (732, 550)), ((547, 680), (642, 590)),
                   ((598, 1032), (630, 1250), (705, 1262)), ((412, 1042), (340, 1250), (415, 1262))),
    # --- v1.7.0: tendangan tinggi (tendangan kedua pada combo tendang + tendang) ---
    'kick_high_hit': pose((390, 350), (430, 870),
                          ((330, 700), (240, 620)), ((470, 690), (570, 660)),
                          ((640, 720), (800, 600), (870, 590)), ((430, 1060), (410, 1250), (485, 1262)),
                          neck=(390, 500)),
    'walk_d': pose((535, 331), (510, 863),
                   ((640, 660), (740, 560)), ((555, 690), (650, 600)),
                   ((600, 1040), (620, 1250), (695, 1262)), ((450, 1045), (420, 1250), (495, 1262))),
}


# ---------------- konversi ----------------
def shoulder(p):
    nx, ny = p['neck']
    hx, hy = p['hip']
    return (nx + (hx - nx) * 0.18, ny + (hy - ny) * 0.18)


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


if __name__ == '__main__':
    problems = check_limbs()
    for msg in problems:
        print('PERINGATAN panjang anggota badan:', msg)
    write_dart()
