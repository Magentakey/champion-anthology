import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'rhythm_chart.dart';
import 'rhythm_config.dart';
import 'rhythm_judge.dart';

/// Warna tiap jalur (sama dengan not dan pad): merah, biru, hijau, emas.
const List<Color> rhythmLaneColors = [
  Color(0xFFE84048),
  Color(0xFF408CF0),
  Color(0xFF54C864),
  Color(0xFFFFC830),
];

/// Posisi dan ukuran (pecahan layar) yang dipakai bersama oleh Flame dan HUD Flutter.
/// Bos dan gelembung sama dengan level lain.
class RhythmLayout {
  const RhythmLayout._();

  static const double bossCenterX = 0.30;
  static const double bossCenterY = 0.19;
  static const double bossHeight = 0.22;
  static const double bubbleTop = 0.09;
  static const double bubbleHeight = 0.16;
  static const double bubbleLeft = 0.52;

  /// Jalur not: dari 0,29 sampai 0,76 tinggi layar.
  static const double laneTop = 0.29;
  static const double laneBottom = 0.76;

  /// Garis ketuk di dasar jalur.
  static const double hitLine = 0.72;

  /// Bar semangat (akurasi dan garis ambang) dan hitungan combo.
  static const double barTop = 0.76;
  static const double barBottom = 0.81;

  /// Pad ketuk (multi-sentuh) di bawah layar.
  static const double padTop = 0.81;
  static const double padBottom = 0.97;

  /// Jarak jalur dan pad dari tepi layar, dan celah antar pad (dp).
  static const double sideMargin = 16;
  static const double padGap = 6;

  static double laneWidth(double width) => (width - 2 * sideMargin) / rhythmLaneCount;

  static double laneCenterX(int lane, double width) => sideMargin + laneWidth(width) * (lane + 0.5);

  static double hitY(double height) => hitLine * height;

  /// Kotak jalur ke-[lane] di layar berukuran [size].
  static Rect laneRect(int lane, Size size) {
    final w = laneWidth(size.width);
    return Rect.fromLTWH(sideMargin + w * lane, laneTop * size.height, w, (laneBottom - laneTop) * size.height);
  }

  /// Kotak pad ke-[lane] di layar berukuran [size].
  static Rect padRect(int lane, Size size) {
    final w = laneWidth(size.width);
    return Rect.fromLTRB(
      sideMargin + w * lane + padGap / 2,
      padTop * size.height,
      sideMargin + w * (lane + 1) - padGap / 2,
      padBottom * size.height,
    );
  }

  /// Ukuran gambar not (rasio 60:36) di layar selebar [width].
  static Size noteSize(double width) {
    final w = laneWidth(width) * 0.84;
    return Size(w, w * 0.6);
  }

  /// Pusat vertikal not yang tiba di garis ketuk dalam [secondsUntilHit] detik. Not muncul tepat di atas jalur
  /// [RhythmTuning.fallMs] sebelum waktunya dan jatuh dengan kecepatan tetap melewati garis ketuk.
  static double noteCenterY(double secondsUntilHit, Size size) {
    final start = laneTop * size.height - noteSize(size.width).height / 2;
    final hit = hitY(size.height);
    final fall = RhythmTuning.fallMs / 1000;
    return hit - secondsUntilHit / fall * (hit - start);
  }
}

/// Gambar yang dipakai panggung.
class RhythmImages {
  const RhythmImages({required this.notes, required this.hitLine});

  /// Gambar not tiap jalur.
  final List<Image> notes;
  final Image hitLine;
}

class _Spark {
  _Spark(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size) : maxLife = life;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final Color color;
  final double size;
}

/// Jalur, not yang jatuh, garis ketuk, dan percikan. Semua posisi dihitung dari jam permainan [clock] dan
/// jadwal not di penilai, jadi tampilan selalu sama dengan penilaian. Tidak ada logika nilai di sini.
class RhythmStage extends PositionComponent {
  RhythmStage(this.images, {Random? random}) : _random = random ?? Random();

  final RhythmImages images;
  final Random _random;

  /// Jam permainan (detik); negatif selama hitung mundur awal.
  double clock = 0;

  RhythmChart? chart;
  RhythmJudge? judge;

  final List<double> _laneGlow = List<double>.filled(rhythmLaneCount, 0);
  final List<_Spark> _sparks = [];

  final Paint _plain = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
  final Paint _faded = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false
    ..color = const Color(0x66FFFFFF);
  final Paint _fill = Paint()..isAntiAlias = false;

  /// Jumlah percikan yang sedang hidup (untuk tes).
  int get sparkCount => _sparks.length;

  /// Kecerahan sorot jalur ke-[lane] (1 saat baru diketuk, meluruh ke 0).
  double laneGlow(int lane) => _laneGlow[lane];

  /// Jalur menyala sebentar saat diketuk.
  void flashLane(int lane) {
    if (lane >= 0 && lane < rhythmLaneCount) _laneGlow[lane] = 1;
  }

  /// Hapus semua efek (awal step baru).
  void reset() {
    _sparks.clear();
    for (var i = 0; i < _laneGlow.length; i++) {
      _laneGlow[i] = 0;
    }
  }

  /// Percikan kecil di garis ketuk saat not [judgment] pada [lane] pecah. MISS tidak punya percikan.
  void burst(int lane, Judgment judgment) {
    if (judgment == Judgment.miss) return;
    final perfect = judgment == Judgment.perfect;
    final count = perfect ? 12 : 7;
    final unit = size.x / 240;
    final cx = RhythmLayout.laneCenterX(lane, size.x);
    final cy = RhythmLayout.hitY(size.y);
    final color = perfect ? const Color(0xFFFFD640) : const Color(0xFFFFF4D6);
    for (var i = 0; i < count; i++) {
      final angle = -pi * (0.1 + 0.8 * _random.nextDouble());
      final speed = (perfect ? 150 : 100) * (0.5 + _random.nextDouble()) * unit;
      _sparks.add(_Spark(
        cx + (_random.nextDouble() - 0.5) * 20 * unit,
        cy,
        cos(angle) * speed,
        sin(angle) * speed,
        0.35 + 0.25 * _random.nextDouble(),
        i.isEven ? color : rhythmLaneColors[lane],
        (2 + _random.nextInt(2)) * unit,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (var i = 0; i < _laneGlow.length; i++) {
      if (_laneGlow[i] > 0) _laneGlow[i] = max(0.0, _laneGlow[i] - dt / 0.18);
    }
    for (final s in _sparks) {
      s.life -= dt;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 520 * (size.x / 240) * dt;
    }
    _sparks.removeWhere((s) => s.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    final area = Size(size.x, size.y);
    _renderLanes(canvas, area);
    _renderHitLine(canvas, area);
    _renderNotes(canvas, area);
    _renderSparks(canvas);
  }

  void _renderLanes(Canvas canvas, Size area) {
    for (var lane = 0; lane < rhythmLaneCount; lane++) {
      final r = RhythmLayout.laneRect(lane, area);
      _fill.color = lane.isEven ? const Color(0x99120E26) : const Color(0x80241A44);
      canvas.drawRect(r, _fill);
      final glow = _laneGlow[lane];
      if (glow > 0) {
        _fill.color = rhythmLaneColors[lane].withAlpha((110 * glow).round());
        canvas.drawRect(r, _fill);
      }
      _fill.color = const Color(0x40FFF4D6);
      canvas.drawRect(Rect.fromLTWH(r.left, r.top, max(1.0, area.width / 240), r.height), _fill);
    }
    final last = RhythmLayout.laneRect(rhythmLaneCount - 1, area);
    canvas.drawRect(Rect.fromLTWH(last.right, last.top, max(1.0, area.width / 240), last.height), _fill);
  }

  void _renderHitLine(Canvas canvas, Size area) {
    final img = images.hitLine;
    final lineH = area.width / 720 * img.height;
    final hitY = RhythmLayout.hitY(area.height);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(0, hitY - lineH / 2, area.width, lineH),
      _plain,
    );
    final c = chart;
    if (c != null && clock >= -c.beatSeconds * RhythmTuning.countdownBeats) {
      // denyut halus di tiap ketukan, hanya hiasan
      final phase = (clock / c.beatSeconds) % 1; // Dart: sisa bagi selalu tidak negatif
      final pulse = pow(1 - phase, 3).toDouble();
      _fill.color = const Color(0xFFFFFFFF).withAlpha((70 * pulse).round());
      canvas.drawRect(Rect.fromLTWH(0, hitY - lineH / 2, area.width, lineH), _fill);
    }
  }

  void _renderNotes(Canvas canvas, Size area) {
    final j = judge;
    final c = chart;
    if (j == null || c == null) return;
    final lanes = RhythmLayout.laneRect(0, area);
    final clip = Rect.fromLTRB(lanes.left, lanes.top, RhythmLayout.laneRect(rhythmLaneCount - 1, area).right, lanes.bottom);
    final noteSize = RhythmLayout.noteSize(area.width);
    final fall = RhythmTuning.fallMs / 1000;
    canvas.save();
    canvas.clipRect(clip);
    for (var i = 0; i < c.notes.length; i++) {
      final result = j.resultOf(i);
      if (result == Judgment.perfect || result == Judgment.good) continue; // sudah pecah jadi percikan
      final until = j.timeOf(i) - clock;
      if (until > fall) break; // not berikutnya lebih jauh lagi (urut menurut waktu)
      final y = RhythmLayout.noteCenterY(until, area);
      if (y - noteSize.height / 2 > clip.bottom) continue;
      final lane = c.notes[i].lane;
      final img = images.notes[lane];
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: Offset(RhythmLayout.laneCenterX(lane, area.width), y), width: noteSize.width, height: noteSize.height),
        result == Judgment.miss ? _faded : _plain,
      );
    }
    canvas.restore();
  }

  void _renderSparks(Canvas canvas) {
    for (final s in _sparks) {
      final alpha = (255 * (s.life / s.maxLife)).clamp(0, 255).round();
      _fill.color = s.color.withAlpha(alpha);
      canvas.drawRect(Rect.fromLTWH(s.x, s.y, s.size, s.size), _fill);
    }
  }
}
