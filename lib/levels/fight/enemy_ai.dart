import 'dart:math' as math;

import 'attacks.dart';
import 'fight_config.dart';
import 'fighter_body.dart';

/// AI Rock. Rock tidak selalu menangkis atau menyerang: ia memilih lewat peluang per fase,
/// bereaksi dengan jeda reaksi, dan beradaptasi pada kebiasaan pemain.
///
/// - Fase 1: serangan tunggal, lambat, hampir tidak menangkis.
/// - Fase 2: combo 2 pukulan, Tendangan Putar, menangkis dan membalas, menghukum serangan meleset.
/// - Fase 3: combo 3 pukulan, Hantaman beraba-aba merah (berarmor), pukulan terjang, reaksi cepat.
/// - Anti-spam: serangan yang sama 3 kali beruntun lebih sering ditangkis.
/// - Anti-sudut: pemain yang terjepit di dinding lebih dari 2 detik ditekan combo beruntun.
class EnemyAi {
  EnemyAi({math.Random? random}) : _rnd = random ?? math.Random();

  final math.Random _rnd;
  bool enabled = true;

  final List<AttackSpec> _plan = [];
  bool _planStarted = false;

  double _cooldownMs = 1400;
  double _blockMs = 0;
  double _blockCooldownMs = 0;

  double _reactMs = -1;
  AttackSpec? _pendingThreat;
  bool _seenAttack = false;
  final List<String> _history = [];

  double _prevHp = -1;
  double _counterDelayMs = -1;

  bool _punishRolled = false;
  double _punishMs = -1;

  double _corneredMs = 0;
  bool? _dashPlanned;
  double _waitMs = 0;
  double _waitDir = 0;

  /// Pemain dianggap menyepam [id] bila 3 serangan terakhirnya sama.
  bool isSpamming(String id) {
    if (_history.length < 3) return false;
    final n = _history.length;
    return _history[n - 1] == id && _history[n - 2] == id && _history[n - 3] == id;
  }

  /// Pemain sudah terjepit di dinding cukup lama sehingga Rock menekan.
  bool get pressuring => _corneredMs >= 2000;

  bool get hasPlan => _plan.isNotEmpty;

  void update(
    double dtMs,
    FighterBody self,
    FighterBody target,
    RockPhaseStats stats,
    int phase,
    double worldWidth,
  ) {
    if (!enabled || self.isDead || target.isDead) {
      self.moveInput = 0;
      self.blockHeld = false;
      _plan.clear();
      return;
    }

    _cooldownMs -= dtMs;
    _blockCooldownMs -= dtMs;

    final dx = target.x - self.x;
    final dist = dx.abs();

    // pemain terjepit di sudut?
    final cornered = target.x < CombatGeometry.wallMargin + 320 ||
        target.x > worldWidth - CombatGeometry.wallMargin - 320;
    _corneredMs = cornered ? _corneredMs + dtMs : 0;

    // pukulan tertangkis terdeteksi dari HP yang turun saat sedang menangkis
    final tookChip = self.state == BodyState.block && _prevHp >= 0 && self.hp < _prevHp - 1e-9;
    _prevHp = self.hp;

    _perceive(dtMs, self, target, stats, dist);

    if (!self.canAct) {
      self.moveInput = 0;
      self.blockHeld = false;
      if (self.state != BodyState.attack) _plan.clear();
      if (self.state == BodyState.hurt) _blockMs = 0;
      return;
    }

    // ---- menangkis ----
    if (_blockMs > 0) {
      _blockMs -= dtMs;
      if (tookChip && _rnd.nextDouble() < stats.counterChance) {
        _blockMs = 0;
        _counterDelayMs = 90;
        _plan
          ..clear()
          ..add(Attacks.punch.withDamage(stats.punchDamage));
        _planStarted = false;
      }
    }
    if (_blockMs > 0) {
      self.blockHeld = true;
      self.moveInput = 0;
      return;
    }
    self.blockHeld = false;

    // ---- jeda singkat sebelum membalas ----
    if (_counterDelayMs >= 0) {
      _counterDelayMs -= dtMs;
      self.moveInput = 0;
      if (_counterDelayMs >= 0) return;
    }

    // ---- menghukum celah pemain ----
    if (_punishMs >= 0) {
      _punishMs -= dtMs;
      if (_punishMs < 0 && dist <= 600 && _plan.isEmpty) {
        _plan.addAll(_punishPlan(phase, stats));
        _planStarted = false;
      }
    }

    // ---- menjalankan rencana serangan ----
    if (_plan.isNotEmpty) {
      if (_planStarted && dist > 650) {
        _plan.clear();
      } else {
        self.moveInput = 0;
        final next = _plan.removeAt(0);
        self.queueAttack(next);
        _planStarted = true;
        if (_plan.isEmpty) _armCooldown(stats);
        return;
      }
    }

    // ---- memilih serangan baru ----
    if (_cooldownMs <= 0) {
      if (dist <= 470) {
        _plan.addAll(_choosePlan(phase, stats, dist));
        _planStarted = false;
        self.moveInput = 0;
        return;
      }
      // fase 3: kadang menerjang dari jauh (ditentukan sekali per giliran serang)
      _dashPlanned ??= phase >= 3 && _rnd.nextDouble() < 0.35;
      if (_dashPlanned == true && dist <= 820) {
        _plan.add(Attacks.dash);
        _planStarted = false;
        return;
      }
      self.moveInput = dx.sign;
      return;
    }

    // ---- menunggu: menjaga jarak dengan gerak maju-mundur ----
    _waitMs -= dtMs;
    if (_waitMs <= 0) {
      _waitMs = 500 + _rnd.nextDouble() * 700;
      final r = _rnd.nextDouble();
      _waitDir = r < 0.35 ? 1 : (r < 0.7 ? -1 : 0);
    }
    if (dist < 340) {
      self.moveInput = -dx.sign;
    } else if (dist > 560) {
      self.moveInput = dx.sign;
    } else {
      self.moveInput = _waitDir * dx.sign;
    }
  }

  // ---------------- persepsi ----------------
  void _perceive(
    double dtMs,
    FighterBody self,
    FighterBody target,
    RockPhaseStats stats,
    double dist,
  ) {
    final atk = target.state == BodyState.attack ? target.attack : null;
    if (atk == null) {
      _seenAttack = false;
      _punishRolled = false;
    } else {
      if (!_seenAttack) {
        _seenAttack = true;
        _history.add(atk.id);
        if (_history.length > 5) _history.removeAt(0);
        if (atk.projectile || dist <= 750) {
          _pendingThreat = atk;
          _reactMs = stats.reactionMs * (0.8 + 0.4 * _rnd.nextDouble());
        }
      }
      // serangan pemain meleset dan ia masih pulih: kesempatan menghukum
      if (!_punishRolled &&
          !atk.projectile &&
          target.attackMs >= atk.hitEndMs &&
          !target.hitDone &&
          dist <= 620) {
        _punishRolled = true;
        if (_rnd.nextDouble() < stats.punishChance) {
          _punishMs = stats.reactionMs * 0.6;
        }
      }
    }

    if (_reactMs >= 0) {
      _reactMs -= dtMs;
      if (_reactMs < 0) {
        _reactMs = -1;
        _react(self, target, stats, dist);
      }
    }
  }

  void _react(FighterBody self, FighterBody target, RockPhaseStats stats, double dist) {
    final threat = _pendingThreat;
    _pendingThreat = null;
    if (threat == null || !self.canAct || _blockCooldownMs > 0) return;
    final stillThreat = threat.projectile || (target.state == BodyState.attack && dist <= 800);
    if (!stillThreat) return;

    var chance = stats.blockChance;
    if (threat.projectile) chance *= 0.8;
    if (isSpamming(threat.id)) chance = math.min(0.9, chance + 0.3);
    if (_plan.isNotEmpty) chance *= 0.3;
    if (_rnd.nextDouble() < chance) {
      _blockMs = 450;
      _blockCooldownMs = 900;
      _plan.clear();
    }
  }

  // ---------------- pemilihan serangan ----------------
  void _armCooldown(RockPhaseStats stats) {
    var cd = stats.intervalMs * (0.8 + 0.4 * _rnd.nextDouble());
    if (pressuring) cd *= 0.45;
    _cooldownMs = cd;
    _dashPlanned = null;
  }

  AttackSpec _punch(RockPhaseStats s) => Attacks.punch.withDamage(s.punchDamage);
  AttackSpec _kick(RockPhaseStats s) => Attacks.kick.withDamage(s.kickDamage);

  List<AttackSpec> _punishPlan(int phase, RockPhaseStats s) =>
      phase >= 3 ? [_punch(s), _kick(s)] : [_punch(s)];

  List<AttackSpec> _choosePlan(int phase, RockPhaseStats s, double dist) {
    final r = _rnd.nextDouble();
    if (phase <= 1) {
      return (dist > 430 || r > 0.7) ? [_kick(s)] : [_punch(s)];
    }
    if (phase == 2) {
      if (pressuring && r < 0.5) return [_punch(s), _punch(s)];
      if (r < 0.35) return [_punch(s), _punch(s)];
      if (r < 0.55) return [_punch(s), _kick(s)];
      if (r < 0.70) return [_kick(s)];
      return [Attacks.roundhouse];
    }
    if (pressuring && r < 0.6) return [_punch(s), _punch(s), _kick(s)];
    if (r < 0.25) return [_punch(s), _punch(s), _kick(s)];
    if (r < 0.45) return [_punch(s), _punch(s), _punch(s)];
    if (r < 0.70) return [Attacks.heavy];
    if (r < 0.85) return [Attacks.roundhouse.withDamage(13)];
    return [_punch(s), _kick(s)];
  }
}
