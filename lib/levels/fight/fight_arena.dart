import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'attacks.dart';
import 'fight_config.dart';
import 'fighter_body.dart';

/// Pisau lempar yang sedang melayang.
class Knife {
  Knife({
    required this.x,
    required this.y,
    required this.dir,
    required this.fromPlayer,
    required this.spec,
  });

  double x;
  final double y;
  final int dir;
  final bool fromPlayer;
  final AttackSpec spec;
  double ageMs = 0;
  bool alive = true;
}

enum HitKind { hit, blocked }

/// Kejadian pukulan untuk efek (percikan, getar layar, suara).
class HitEvent {
  const HitEvent({
    required this.kind,
    required this.byPlayer,
    required this.x,
    required this.y,
    required this.damage,
    this.knife = false,
  });

  final HitKind kind;
  final bool byPlayer;

  /// Titik kena dalam satuan ruang gambar (y relatif terhadap tanah).
  final double x;
  final double y;
  final double damage;
  final bool knife;
}

/// Dunia pertarungan (tanpa Flame): dua petarung, pisau, dan penyelesaian hit.
/// Serangan pemain diproses lebih dulu dalam satu frame.
class FightArena {
  FightArena({required this.worldWidth})
      : player = FighterBody(maxHp: FightStats.playerMaxHp, x: 0, facing: 1),
        rock = FighterBody(
          maxHp: FightStats.rockMaxHp,
          x: 0,
          facing: -1,
          walkSpeed: 600,
          backSpeed: 450,
        ) {
    placeFighters();
    setStep(1);
  }

  /// Lebar arena dalam satuan ruang gambar.
  double worldWidth;
  final FighterBody player;
  final FighterBody rock;
  final List<Knife> knives = [];

  /// Diisi tiap [update]; pemanggil membacanya lalu mengosongkan.
  final List<HitEvent> events = [];

  int step = 1;

  void placeFighters() {
    player.x = worldWidth * ArenaLayout.playerX;
    rock.x = worldWidth * ArenaLayout.rockX;
  }

  /// Menerapkan fase [step] (1..3): batas HP dan sifat Rock.
  void setStep(int step) {
    this.step = step;
    final stats = rockPhaseStats[step - 1];
    rock.hpFloor = FightStats.rockFloorHp(step);
    rock.speedScale = stats.speedScale;
    rock.hurtScale = stats.hurtScale;
  }

  void clearKnives() => knives.clear();

  void update(double dtMs) {
    player.update(dtMs, rock.x);
    rock.update(dtMs, player.x);
    _resolveMelee(player, rock, byPlayer: true);
    _resolveMelee(rock, player, byPlayer: false);
    _updateKnives(dtMs);
    _separateAndClamp();
  }

  // ---------------- hit ----------------
  bool _inHurtBox(FighterBody target, Offset p) =>
      (p.dx - target.x).abs() <= CombatGeometry.hurtHalfWidth &&
      p.dy >= CombatGeometry.hurtTop &&
      p.dy <= CombatGeometry.hurtBottom;

  void _resolveMelee(FighterBody a, FighterBody d, {required bool byPlayer}) {
    final spec = a.attack;
    if (a.state != BodyState.attack || spec == null) return;
    final t = a.attackMs;
    final local = spec.tipOf(spec.clip.sample(t.round()));

    if (spec.projectile) {
      if (!a.projectileSpawned && t >= spec.hitStartMs) {
        a.projectileSpawned = true;
        knives.add(Knife(
          x: a.x + a.facing * local.dx,
          y: local.dy,
          dir: a.facing,
          fromPlayer: byPlayer,
          spec: spec,
        ));
      }
      return;
    }

    if (a.hitDone || t < spec.hitStartMs || t > spec.hitEndMs) return;
    final tip = Offset(a.x + a.facing * local.dx, local.dy);
    if (!_inHurtBox(d, tip)) return;
    a.hitDone = true;
    _deliver(a.x, d, spec, tip, byPlayer: byPlayer);
  }

  /// Mengirim serangan ke [d]. Mengembalikan false jika diabaikan (kebal).
  bool _deliver(
    double attackerX,
    FighterBody d,
    AttackSpec spec,
    Offset at, {
    required bool byPlayer,
    bool knife = false,
  }) {
    final result = d.receiveHit(spec, attackerX);
    if (result == HitOutcome.ignored) return false;
    final blocked = result == HitOutcome.blocked;
    events.add(HitEvent(
      kind: blocked ? HitKind.blocked : HitKind.hit,
      byPlayer: byPlayer,
      x: at.dx,
      y: at.dy,
      damage: spec.damage * (blocked ? blockedDamageFactor : 1),
      knife: knife,
    ));
    return true;
  }

  void _updateKnives(double dtMs) {
    for (final k in knives) {
      if (!k.alive) continue;
      k.ageMs += dtMs;
      k.x += k.dir * CombatGeometry.knifeSpeed * dtMs / 1000;
      final target = k.fromPlayer ? rock : player;
      final inBox = (k.x - target.x).abs() <= CombatGeometry.hurtHalfWidth + 40 &&
          k.y >= CombatGeometry.hurtTop &&
          k.y <= CombatGeometry.hurtBottom;
      if (inBox) {
        final attackerX = k.fromPlayer ? player.x : rock.x;
        if (_deliver(attackerX, target, k.spec, Offset(k.x, k.y),
            byPlayer: k.fromPlayer, knife: true)) {
          k.alive = false;
        }
      }
      if (k.x < -400 || k.x > worldWidth + 400) k.alive = false;
    }
    knives.removeWhere((k) => !k.alive);
  }

  // ---------------- posisi ----------------
  void _separateAndClamp() {
    final minX = CombatGeometry.wallMargin;
    final maxX = math.max(minX, worldWidth - CombatGeometry.wallMargin);
    player.x = player.x.clamp(minX, maxX).toDouble();
    rock.x = rock.x.clamp(minX, maxX).toDouble();
    if (player.isDead || rock.isDead) return;

    final gap = (rock.x - player.x).abs();
    if (gap >= CombatGeometry.minSeparation) return;
    final dir = rock.x >= player.x ? 1 : -1;
    final push = (CombatGeometry.minSeparation - gap) / 2;
    player.x -= dir * push;
    rock.x += dir * push;
    // jika salah satu terdorong ke dinding, sisanya dibebankan ke yang lain
    if (player.x < minX) {
      rock.x += minX - player.x;
      player.x = minX;
    } else if (player.x > maxX) {
      rock.x -= player.x - maxX;
      player.x = maxX;
    }
    if (rock.x < minX) {
      player.x += minX - rock.x;
      rock.x = minX;
    } else if (rock.x > maxX) {
      player.x -= rock.x - maxX;
      rock.x = maxX;
    }
  }
}
