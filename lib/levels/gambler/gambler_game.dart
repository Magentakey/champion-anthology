import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart' show KeyboardEvents;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show BuildContext, KeyEventResult, Widget;
import 'package:flutter/services.dart' show HapticFeedback, KeyDownEvent, KeyEvent, LogicalKeyboardKey;

import '../../core/audio/audio_service.dart';
import '../../core/level/boss_sprite.dart';
import '../../core/level/cover_background.dart';
import '../../core/level/level_game.dart';
import '../../core/level/level_session.dart';
import '../../core/level/star_calculator.dart';
import 'gambler_config.dart';
import 'gambler_dialog.dart';
import 'gambler_hud.dart';
import 'gambler_table.dart';
import 'luck_round.dart';

LevelGame createGamblerGame(LevelSession session) => GamblerGame(session);

/// Tombol angka untuk memilih kartu atau cangkir saat uji di emulator.
const _digitKeys = <LogicalKeyboardKey>[
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
];

/// Tahap permainan yang dibaca HUD.
enum GamblerPhase { intro, prepare, choosing, reveal, result, done }

/// Level 6: Mr. Lexi the Gambler. Tiga permainan murni peluang bertema pasar malam: tebak kartu (75%),
/// lempar koin (50%), dan cangkir tebak bola (25%). Hasil ditentukan SEBELUM pemain memilih oleh
/// [GamblerRun]; animasi hanya hiasan. Menang tiga step berturut-turut = 3 bintang, kalah mengakhiri sesi.
class GamblerGame extends LevelGame with KeyboardEvents {
  GamblerGame(super.session, {Random? random})
      : _visual = Random(),
        _run = GamblerRun(session, random: random),
        bannerStep = ValueNotifier(session.step),
        shownStep = ValueNotifier(session.step);

  final GamblerRun _run;

  /// Pengacak khusus tampilan (acakan cangkir, pemilihan kalimat); tidak memengaruhi hasil.
  final Random _visual;

  // State yang dibaca HUD Flutter.
  final ValueNotifier<String?> bossSay = ValueNotifier(null);
  final ValueNotifier<GamblerPhase> phase = ValueNotifier(GamblerPhase.intro);
  final ValueNotifier<int?> selected = ValueNotifier(null);
  final ValueNotifier<int> chips = ValueNotifier(0);
  final ValueNotifier<bool> showBanner = ValueNotifier(false);

  /// Nomor ronde di bilah atas dan banner: berganti saat banner ronde baru muncul.
  final ValueNotifier<int> bannerStep;

  /// Ronde yang tampilannya (label peluang, tombol koin, panel) sedang dipakai di layar. Baru berganti
  /// SETELAH banner ronde baru hilang, supaya peluang dan tombol ronde berikutnya tidak muncul lebih dulu.
  final ValueNotifier<int> shownStep;

  /// Menampilkan UI ronde [step] (dipanggil saat banner selesai; juga dipakai tes).
  void showStepUi(int step) {
    bannerStep.value = step;
    shownStep.value = step;
  }

  late final CoverBackground _background;
  late final BossSprite _boss;
  late final GamblerTable _table;
  bool _ready = false;

  GamblerPhase _phase = GamblerPhase.done;
  double _t = 0;
  int _lastSwap = 0;
  int _sayToken = 0;
  String? _lastLine;
  String? _resultLine;

  /// Permainan pada step sesi saat ini (dari konfigurasi, tersedia sejak frame pertama).
  LuckGame get currentGame => gamblerGameOf(session.step);

  /// Pemain boleh memilih hanya saat tahap memilih.
  bool get canPick => _phase == GamblerPhase.choosing && session.isPlaying;

  /// Tombol konfirmasi aktif hanya setelah ada pilihan.
  bool get canConfirm => canPick && selected.value != null;

  @override
  List<String> get assetPaths => const [
        'gambler/boss_idle.png',
        'gambler/boss_shock.png',
        'gambler/boss_laugh.png',
        'gambler/boss_defeat.png',
        'gambler/table.png',
        'gambler/card_back.png',
        'gambler/card_safe.png',
        'gambler/card_bomb.png',
        'gambler/coin_head.png',
        'gambler/coin_tail.png',
        'gambler/coin_spin.png',
        'gambler/cup.png',
        'gambler/ball.png',
      ];

  @override
  Color backgroundColor() => const Color(0xFF161228);

  @override
  Widget buildHud(BuildContext context) => GamblerHud(game: this);

  @override
  String? resultMessage() => _resultLine;

  @override
  Future<void> onLoad() async {
    await loadAssets();
    Image img(String file) => levelImages.fromCache('gambler/$file.png');
    Sprite spriteOf(String file) => Sprite(img(file));
    _background = CoverBackground(img('table'), alignY: 1.0);
    _boss = BossSprite(
      sprites: {
        BossExpression.idle: spriteOf('boss_idle'),
        BossExpression.shock: spriteOf('boss_shock'),
        BossExpression.laugh: spriteOf('boss_laugh'),
        BossExpression.defeat: spriteOf('boss_defeat'),
      },
    );
    _table = GamblerTable(
      GamblerImages(
        cardBack: img('card_back'),
        cardSafe: img('card_safe'),
        cardBomb: img('card_bomb'),
        coinHead: img('coin_head'),
        coinTail: img('coin_tail'),
        coinSpin: img('coin_spin'),
        cup: img('cup'),
        ball: img('ball'),
      ),
    );
    await addAll([_background, _table, _boss]);
    _ready = true;
    _layout(size);
    startStep(session.step);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) _layout(size);
  }

  void _layout(Vector2 s) {
    _background.size = s;
    final side = min(s.x * 0.5, s.y * GamblerLayout.bossHeight);
    _boss.size = Vector2.all(side);
    _boss.position = Vector2(s.x * GamblerLayout.bossCenterX, s.y * GamblerLayout.bossCenterY);
    _table.size = Vector2(s.x - 2 * GamblerLayout.sideMargin, s.y * GamblerLayout.tableHeight);
    _table.position = Vector2(GamblerLayout.sideMargin, s.y * GamblerLayout.tableTop);
  }

  // ---------------- alur step ----------------
  @override
  void startStep(int step) {
    // Penempatan hasil ditentukan di sini, sebelum pemain memilih, dan tidak berubah lagi.
    final round = _run.beginStep(step);
    _t = 0;
    _lastSwap = 0;
    selected.value = null;
    bannerStep.value = step;
    showBanner.value = true;
    _setPhase(GamblerPhase.intro);

    _table
      ..game = round.game
      ..stage = TableStage.idle
      ..stageTime = 0
      ..selected = null
      ..placement = round.placement
      ..shuffle = round.game == LuckGame.cup
          ? CupShuffle.plan(_visual, finalSlot: round.placement)
          : null;

    _boss.setExpression(BossExpression.idle);
    _say(GamblerDialog.stepIntro[step - 1], seconds: 2.6);
  }

  void _setPhase(GamblerPhase p) {
    _phase = p;
    phase.value = p;
  }

  void _say(String line, {double seconds = 2.2}) {
    final token = ++_sayToken;
    bossSay.value = line;
    add(TimerComponent(
      period: seconds,
      removeOnFinish: true,
      onTick: () {
        if (token == _sayToken) bossSay.value = null;
      },
    ));
  }

  String _pick(List<String> lines) {
    if (lines.length == 1) return lines.first;
    String line;
    do {
      line = lines[_visual.nextInt(lines.length)];
    } while (line == _lastLine);
    _lastLine = line;
    return line;
  }

  void _beginPrepare() {
    _t = 0;
    _lastSwap = 0;
    _table
      ..stage = TableStage.prepare
      ..stageTime = 0;
    _setPhase(GamblerPhase.prepare);
  }

  void _beginChoosing() {
    _t = 0;
    _table
      ..stage = TableStage.choosing
      ..stageTime = 0;
    _setPhase(GamblerPhase.choosing);
  }

  // ---------------- input dari HUD ----------------
  /// Pemain memilih kartu, sisi koin, atau cangkir ke-[index]. Boleh diganti sebelum konfirmasi.
  void select(int index) {
    if (!canPick) return;
    final count = _run.round?.optionCount ?? 0;
    if (index < 0 || index >= count) return;
    selected.value = index;
    _table.selected = index;
    AudioService.instance.play(Sfx.tick);
    HapticFeedback.selectionClick();
  }

  /// Tombol BUKA atau LEMPAR: mengunci pilihan lalu memainkan animasi hasil.
  void confirm() {
    if (!canConfirm) return;
    final pick = selected.value!;
    _run.confirm(pick); // hasil dihitung dari penempatan yang sudah ada; pilihan tidak mengubahnya
    _t = 0;
    _table
      ..stage = TableStage.reveal
      ..stageTime = 0;
    _setPhase(GamblerPhase.reveal);
    switch (currentGame) {
      case LuckGame.card:
        AudioService.instance.play(Sfx.cardFlip);
      case LuckGame.coin:
        AudioService.instance.play(Sfx.coinToss);
      case LuckGame.cup:
        AudioService.instance.play(Sfx.cupSlide);
    }
  }

  /// Papan ketik untuk uji di emulator: angka 1 sampai 4 memilih, spasi atau Enter mengonfirmasi.
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final i = _digitKeys.indexOf(key);
    if (i >= 0) {
      select(i);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      confirm();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---------------- siklus frame ----------------
  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready || !session.isPlaying) return;

    switch (_phase) {
      case GamblerPhase.intro:
        _t += dt;
        if (_t * 1000 >= GamblerTuning.introMs) {
          showBanner.value = false;
          shownStep.value = session.step;
          if (currentGame == LuckGame.cup) {
            _beginPrepare();
          } else {
            _beginChoosing();
          }
        }
      case GamblerPhase.prepare:
        _t += dt;
        _table.stageTime = _t;
        _playShuffleSounds();
        if (_t * 1000 >= GamblerAnim.prepareMs(currentGame)) _beginChoosing();
      case GamblerPhase.choosing:
        _table.stageTime += dt;
      case GamblerPhase.reveal:
        _t += dt;
        _table.stageTime = _t;
        if (_t * 1000 >= GamblerAnim.revealMs(currentGame)) _showResult();
      case GamblerPhase.result:
        _t += dt;
        if (_t * 1000 >= GamblerTuning.resultMs) _commit();
      case GamblerPhase.done:
        break;
    }
  }

  /// Bunyi geser cangkir tiap kali satu tukar dimulai.
  void _playShuffleSounds() {
    final ms = _t * 1000 - GamblerTuning.cupShowMs - GamblerTuning.cupCoverMs;
    if (ms < 0) return;
    final swap = (ms / GamblerTuning.cupShuffleMs * GamblerTuning.shuffleSwaps).floor() + 1;
    if (swap > _lastSwap && swap <= GamblerTuning.shuffleSwaps) {
      _lastSwap = swap;
      AudioService.instance.play(Sfx.cupSlide);
    }
  }

  /// Animasi selesai: tampilkan hasil dan reaksi bos. Sesi belum diubah (itu di [_commit]).
  void _showResult() {
    final outcome = _run.outcome;
    if (outcome == null) return;
    _setPhase(GamblerPhase.result);
    _t = 0;
    final step = outcome.step;
    if (outcome.won) {
      chips.value = chips.value + 1;
      AudioService.instance.play(Sfx.winChime);
      HapticFeedback.mediumImpact();
      _boss.flinch();
      _boss.setExpression(BossExpression.shock, revertAfter: 1.0);
      _say(_pick(GamblerDialog.win[step - 1]), seconds: 1.4);
    } else {
      AudioService.instance.play(Sfx.loseBuzz);
      _boss.laugh();
      _boss.setExpression(BossExpression.laugh, revertAfter: 1.0);
      _say(_pick(GamblerDialog.lose[step - 1]), seconds: 1.4);
    }
  }

  /// Lapor ke sesi (winStep atau loseStep). Kalimat hasil harus siap SEBELUM sesi berubah,
  /// karena layar hasil membacanya saat sesi selesai.
  void _commit() {
    final outcome = _run.outcome;
    if (outcome == null || _phase == GamblerPhase.done) return;
    _setPhase(GamblerPhase.done);

    if (!outcome.won) {
      _resultLine = _pick(GamblerDialog.resultByStars[session.stepsWon]);
      _run.commit();
      return;
    }

    final last = session.step >= StarCalculator.totalSteps;
    if (last) {
      _resultLine = _pick(GamblerDialog.resultByStars[StarCalculator.totalSteps]);
      _boss.setExpression(BossExpression.defeat);
    }
    _run.commit();
    AudioService.instance.play(last ? Sfx.win : Sfx.stepUp);
    if (session.isPlaying) {
      add(TimerComponent(
        period: GamblerTuning.stepGapMs / 1000,
        removeOnFinish: true,
        onTick: () => startStep(session.step),
      ));
    }
  }
}
