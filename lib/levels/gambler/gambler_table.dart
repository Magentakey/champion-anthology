import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'gambler_config.dart';
import 'luck_round.dart';

/// Posisi dan ukuran (pecahan layar) yang dipakai bersama oleh Flame dan HUD Flutter.
/// Bos dan gelembung sama dengan level lain.
class GamblerLayout {
  const GamblerLayout._();

  static const double bossCenterX = 0.30;
  static const double bossCenterY = 0.19;
  static const double bossHeight = 0.22;
  static const double bubbleTop = 0.10;
  static const double bubbleHeight = 0.15;
  static const double bubbleLeft = 0.52;

  /// Area meja (kain hijau): kartu, koin, atau cangkir digambar di sini.
  static const double tableTop = 0.365;
  static const double tableHeight = 0.33;

  /// Label peluang di antara meja dan panel kontrol.
  static const double oddsTop = 0.698;
  static const double oddsHeight = 0.052;

  static const double controlTop = 0.758;
  static const double controlBottom = 0.03;
  static const double sideMargin = 16;

  /// Kotak slot kartu atau cangkir ke-[index] di area meja berukuran [area].
  static Rect slotRect(LuckGame game, int index, Size area) {
    final w = area.width;
    final h = area.height;
    switch (game) {
      case LuckGame.card:
        final cardW = w * 0.20;
        final cardH = min(h * 0.80, cardW * 1.4);
        final gap = (w - GamblerTuning.cardCount * cardW) / (GamblerTuning.cardCount + 1);
        return Rect.fromLTWH(gap + index * (cardW + gap), (h - cardH) / 2, cardW, cardH);
      case LuckGame.cup:
        final cupW = w * 0.19;
        final cupH = cupW * 26 / 22;
        final gap = (w - GamblerTuning.cupCount * cupW) / (GamblerTuning.cupCount + 1);
        return Rect.fromLTWH(gap + index * (cupW + gap), h * 0.60 - cupH / 2, cupW, cupH);
      case LuckGame.coin:
        return coinChoiceRect(index, area);
    }
  }

  /// Koin di tengah meja.
  static Rect coinRect(Size area) {
    final side = min(area.width * 0.26, area.height * 0.36);
    return Rect.fromCenter(center: Offset(area.width / 2, area.height * 0.46), width: side, height: side);
  }

  /// Tombol pilihan KEPALA (0) dan EKOR (1) di bawah koin.
  static Rect coinChoiceRect(int side, Size area) {
    final w = area.width * 0.36;
    final h = area.height * 0.20;
    final cx = area.width * (side == 0 ? 0.27 : 0.73);
    return Rect.fromCenter(center: Offset(cx, area.height * 0.86), width: w, height: h);
  }
}

/// Fungsi animasi murni (hanya hiasan; tidak pernah mengubah hasil). Waktu dalam milidetik.
class GamblerAnim {
  const GamblerAnim._();

  static double _clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

  /// Kemajuan balik kartu ke-[index] (0 tertutup, 1 terbuka). Kartu terpilih terbalik dulu, tiga lainnya menyusul.
  static double cardFlip(int index, int picked, double ms) {
    if (index == picked) return _clamp01(ms / GamblerTuning.cardFlipMs);
    return _clamp01((ms - GamblerTuning.cardFlipMs) / GamblerTuning.cardRevealMs);
  }

  /// Skala lebar kartu saat membalik: 1 tertutup, 0 saat tegak lurus, 1 lagi saat terbuka.
  static double flipScale(double progress) => cos(pi * progress).abs();

  /// Kartu menampakkan muka (bukan punggung) setelah separuh jalan.
  static bool showsFace(double progress) => progress >= 0.5;

  /// Sisi koin yang terlihat pada kemajuan lempar [u] (0..1): sisi berganti saat koin tegak lurus
  /// dan pasti berakhir di [landed] (0 kepala, 1 ekor).
  static int coinFace(double u, int landed) {
    if (u >= 1) return landed;
    final m = (u * GamblerTuning.coinHalfTurns + 0.5).floor();
    return (landed + (GamblerTuning.coinHalfTurns - m)) % 2;
  }

  /// Skala tinggi koin yang berputar: 1 menghadap, mendekati 0 saat sisi tipis.
  static double coinScale(double u) => cos(pi * u * GamblerTuning.coinHalfTurns).abs();

  /// Tinggi koin (0..1) selama lemparan: parabola, 0 di awal dan akhir.
  static double coinLift(double u) => 4 * u * (1 - u);

  /// Cangkir terangkat (0..1) pada tahap persiapan: terangkat selama bola ditampilkan, lalu menutup.
  static double cupLiftPrepare(double ms) {
    if (ms < GamblerTuning.cupShowMs) return 1;
    return 1 - _clamp01((ms - GamblerTuning.cupShowMs) / GamblerTuning.cupCoverMs);
  }

  /// Kemajuan acakan cangkir (0..1).
  static double cupShuffleProgress(double ms) =>
      _clamp01((ms - GamblerTuning.cupShowMs - GamblerTuning.cupCoverMs) / GamblerTuning.cupShuffleMs);

  /// Tingkat penyatuan cangkir (0 terjajar, 1 menumpuk di tengah) setelah acakan selesai: menyatu,
  /// ditahan, lalu dijajarkan lagi. Saat 1, tidak ada cara membedakan cangkir mana yang mana.
  static double cupMerge(double ms) {
    final t = ms - GamblerTuning.cupShowMs - GamblerTuning.cupCoverMs - GamblerTuning.cupShuffleMs;
    if (t <= 0) return 0;
    double ease(double v) => v * v * (3 - 2 * v);
    if (t < GamblerTuning.cupGatherMs) return ease(_clamp01(t / GamblerTuning.cupGatherMs));
    final h = t - GamblerTuning.cupGatherMs;
    if (h < GamblerTuning.cupMergeHoldMs) return 1;
    return 1 - ease(_clamp01((h - GamblerTuning.cupMergeHoldMs) / GamblerTuning.cupSpreadMs));
  }

  /// Apakah cangkir sudah dalam tahap dijajarkan ulang (setelah ditahan menumpuk di tengah).
  static bool cupSpreading(double ms) {
    final t = ms - GamblerTuning.cupShowMs - GamblerTuning.cupCoverMs - GamblerTuning.cupShuffleMs;
    return t >= GamblerTuning.cupGatherMs + GamblerTuning.cupMergeHoldMs;
  }

  /// Cangkir di [slot] terangkat saat membuka hasil: yang dipilih dulu, lalu yang lain.
  static double cupLiftReveal(int slot, int picked, double ms) {
    if (slot == picked) return _clamp01(ms / GamblerTuning.cupLiftMs);
    return _clamp01((ms - GamblerTuning.cupLiftMs) / GamblerTuning.cupRevealMs);
  }

  /// Lama persiapan sebelum pemain boleh memilih (hanya cangkir yang punya persiapan).
  static int prepareMs(LuckGame game) => game == LuckGame.cup
      ? GamblerTuning.cupShowMs +
          GamblerTuning.cupCoverMs +
          GamblerTuning.cupShuffleMs +
          GamblerTuning.cupGatherMs +
          GamblerTuning.cupMergeHoldMs +
          GamblerTuning.cupSpreadMs
      : 0;

  /// Lama animasi membuka hasil setelah pemain menekan konfirmasi.
  static int revealMs(LuckGame game) => switch (game) {
        LuckGame.card => GamblerTuning.cardFlipMs + GamblerTuning.cardRevealMs,
        LuckGame.coin => GamblerTuning.coinTossMs + GamblerTuning.coinSettleMs,
        LuckGame.cup => GamblerTuning.cupLiftMs + GamblerTuning.cupRevealMs,
      };
}

enum TableStage { idle, prepare, choosing, reveal }

/// Gambar yang dibutuhkan meja.
class GamblerImages {
  const GamblerImages({
    required this.cardBack,
    required this.cardSafe,
    required this.cardBomb,
    required this.coinHead,
    required this.coinTail,
    required this.coinSpin,
    required this.cup,
    required this.ball,
  });

  final Image cardBack;
  final Image cardSafe;
  final Image cardBomb;
  final Image coinHead;
  final Image coinTail;
  final Image coinSpin;
  final Image cup;
  final Image ball;
}

/// Meja stan: menggambar kartu, koin, atau cangkir dari keadaan yang diberikan game (tahap, waktu, pilihan).
/// Hasil ([placement]) sudah ditentukan sebelum pemain memilih; kelas ini hanya menampilkannya.
class GamblerTable extends PositionComponent {
  GamblerTable(this.images);

  final GamblerImages images;

  LuckGame game = LuckGame.card;
  TableStage stage = TableStage.idle;

  /// Detik sejak tahap [stage] dimulai.
  double stageTime = 0;

  /// Slot yang dipilih pemain (null = belum memilih).
  int? selected;

  /// Penempatan hasil (kartu sial, sisi koin yang mendarat, atau cangkir berbola).
  int placement = 0;

  /// Rencana acakan cangkir (hanya untuk game cangkir).
  CupShuffle? shuffle;

  double _clock = 0;

  final Paint _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
  final Paint _frame = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFFFD640)
    ..isAntiAlias = false;

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
  }

  @override
  void render(Canvas canvas) {
    switch (game) {
      case LuckGame.card:
        _renderCards(canvas);
      case LuckGame.coin:
        _renderCoin(canvas);
      case LuckGame.cup:
        _renderCups(canvas);
    }
  }

  Size get _area => Size(size.x, size.y);

  void _draw(Canvas canvas, Image img, Rect dst) {
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), dst, _paint);
  }

  // ---------------- kartu ----------------
  void _renderCards(Canvas canvas) {
    final ms = stageTime * 1000;
    final picked = selected;
    for (var i = 0; i < GamblerTuning.cardCount; i++) {
      var rect = GamblerLayout.slotRect(LuckGame.card, i, _area);
      final chosen = stage == TableStage.choosing && picked == i;
      if (chosen) rect = rect.shift(Offset(0, -rect.height * 0.08));
      var progress = 0.0;
      if (stage == TableStage.reveal && picked != null) progress = GamblerAnim.cardFlip(i, picked, ms);
      final Image img;
      if (!GamblerAnim.showsFace(progress)) {
        img = images.cardBack;
      } else {
        img = i == placement ? images.cardBomb : images.cardSafe;
      }
      if (chosen) canvas.drawRect(rect.inflate(3), _frame);
      final w = max(2.0, rect.width * GamblerAnim.flipScale(progress));
      _draw(canvas, img, Rect.fromCenter(center: rect.center, width: w, height: rect.height));
    }
  }

  // ---------------- koin ----------------
  void _renderCoin(Canvas canvas) {
    final base = GamblerLayout.coinRect(_area);
    if (stage != TableStage.reveal) {
      final bob = sin(_clock * 3) * 2;
      _draw(canvas, images.coinHead, base.shift(Offset(0, bob)));
      return;
    }
    final u = (stageTime * 1000 / GamblerTuning.coinTossMs).clamp(0.0, 1.0).toDouble();
    final lift = GamblerAnim.coinLift(u) * _area.height * 0.26;
    final scale = GamblerAnim.coinScale(u);
    final center = base.center.translate(0, -lift);
    if (scale < 0.2 && u < 1) {
      _draw(canvas, images.coinSpin, Rect.fromCenter(center: center, width: base.width * 0.34, height: base.height));
      return;
    }
    final face = GamblerAnim.coinFace(u, placement) == 0 ? images.coinHead : images.coinTail;
    _draw(canvas, face, Rect.fromCenter(center: center, width: base.width, height: max(2.0, base.height * scale)));
  }

  // ---------------- cangkir ----------------
  void _renderCups(Canvas canvas) {
    final plan = shuffle;
    if (plan == null) return;
    final ms = stageTime * 1000;
    final base0 = GamblerLayout.slotRect(LuckGame.cup, 0, _area);
    final stepX = GamblerLayout.slotRect(LuckGame.cup, 1, _area).left - base0.left;
    final n = GamblerTuning.cupCount;
    final picked = selected;
    final ballSize = base0.width * 0.38;

    final slotX = List<double>.filled(n, 0);
    final arc = List<double>.filled(n, 0);
    final lift = List<double>.filled(n, 0);
    for (var c = 0; c < n; c++) {
      switch (stage) {
        case TableStage.idle:
          slotX[c] = c.toDouble();
          lift[c] = 1;
        case TableStage.prepare:
          final pos = plan.positionOf(c, GamblerAnim.cupShuffleProgress(ms));
          final merge = GamblerAnim.cupMerge(ms);
          final center = (n - 1) / 2;
          // sebelum penyatuan: susunan hasil tukar; setelah ditahan: dijajarkan ke slot akhir yang diacak
          final from = GamblerAnim.cupSpreading(ms) ? plan.spreadSlot(c).toDouble() : pos.slot;
          slotX[c] = from + (center - from) * merge;
          arc[c] = pos.arc;
          lift[c] = GamblerAnim.cupLiftPrepare(ms);
        case TableStage.choosing:
          slotX[c] = plan.spreadSlot(c).toDouble();
        case TableStage.reveal:
          final slot = plan.spreadSlot(c);
          slotX[c] = slot.toDouble();
          lift[c] = picked == null ? 0 : GamblerAnim.cupLiftReveal(slot, picked, ms);
      }
    }

    // bola ada di bawah cangkir berbola; tidak digambar saat diacak (cangkir yang naik tidak boleh membocorkannya)
    final ballCup = plan.startSlot;
    final showBall = stage == TableStage.idle ||
        stage == TableStage.reveal ||
        (stage == TableStage.prepare && ms < GamblerTuning.cupShowMs + GamblerTuning.cupCoverMs);
    if (showBall) {
      final bx = base0.left + slotX[ballCup] * stepX + base0.width / 2;
      final by = base0.bottom - ballSize * 0.55;
      _draw(canvas, images.ball, Rect.fromCenter(center: Offset(bx, by), width: ballSize, height: ballSize));
    }

    for (var c = 0; c < n; c++) {
      final chosen = stage == TableStage.choosing && picked != null && (slotX[c] - picked).abs() < 0.01;
      var dy = -lift[c] * base0.height * 0.65 - arc[c] * base0.height * 0.35;
      if (chosen) dy -= base0.height * 0.08;
      final rect = base0.shift(Offset(slotX[c] * stepX, dy));
      if (chosen) canvas.drawRect(rect.inflate(3), _frame);
      _draw(canvas, images.cup, rect);
    }
  }
}
