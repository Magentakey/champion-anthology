import 'dart:math' as math;

import 'attacks.dart';
import 'fight_config.dart';
import 'fighter_body.dart';

/// Otak lawan sederhana untuk tahap M2 (menggantikan AI penuh di M3):
/// mendekat, menyerang dengan jeda tetap per fase, dan kadang menangkis.
class TrainingBrain {
  TrainingBrain({math.Random? random}) : _rnd = random ?? math.Random();

  final math.Random _rnd;
  bool enabled = true;

  double _cooldownMs = 1500;
  double _reactMs = -1;
  bool _willBlock = false;
  bool _seenAttack = false;
  double _blockMs = 0;

  void update(double dtMs, FighterBody self, FighterBody target, RockPhaseStats stats) {
    if (!enabled || target.isDead || self.isDead) {
      self.moveInput = 0;
      self.blockHeld = false;
      return;
    }
    if (!self.canAct) {
      self.moveInput = 0;
      self.blockHeld = false;
      return;
    }

    _cooldownMs -= dtMs;
    final dx = target.x - self.x;
    final dist = dx.abs();

    // bereaksi pada serangan pemain: setelah jeda reaksi, kadang menangkis
    if (target.state != BodyState.attack) {
      _seenAttack = false;
    } else if (!_seenAttack && dist <= 700) {
      _seenAttack = true;
      _reactMs = stats.reactionMs.toDouble();
      _willBlock = _rnd.nextDouble() < stats.blockChance;
    }
    if (_reactMs >= 0) {
      _reactMs -= dtMs;
      if (_reactMs < 0) {
        _reactMs = -1;
        if (_willBlock && target.state == BodyState.attack) _blockMs = 450;
      }
    }
    if (_blockMs > 0) {
      _blockMs -= dtMs;
      self.blockHeld = _blockMs > 0;
      self.moveInput = 0;
      return;
    }
    self.blockHeld = false;

    if (dist > 470) {
      self.moveInput = dx.sign;
      return;
    }
    self.moveInput = 0;

    if (_cooldownMs <= 0) {
      final useKick = dist > 430 || _rnd.nextDouble() < 0.3;
      self.queueAttack(
        useKick
            ? Attacks.kick.withDamage(stats.kickDamage)
            : Attacks.punch.withDamage(stats.punchDamage),
      );
      _cooldownMs = stats.intervalMs * (0.8 + 0.4 * _rnd.nextDouble());
    }
  }
}
