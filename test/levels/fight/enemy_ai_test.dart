import 'dart:math' as math;

import 'package:champion_anthology/levels/fight/attacks.dart';
import 'package:champion_anthology/levels/fight/enemy_ai.dart';
import 'package:champion_anthology/levels/fight/fight_arena.dart';
import 'package:champion_anthology/levels/fight/fight_config.dart';
import 'package:champion_anthology/levels/fight/fighter_body.dart';
import 'package:flutter_test/flutter_test.dart';

/// Menjalankan arena beserta AI selama [ms]. [each] dipanggil tiap frame sebelum update.
void simulate(
  FightArena a,
  EnemyAi ai,
  int ms, {
  void Function(int t)? each,
  bool immortalPlayer = true,
}) {
  // pemain kebal sungguhan: serangan Rock diabaikan sehingga pemain tidak terdorong ke dinding
  // (yang akan memicu mode anti-sudut dan memotong jeda serangan)
  a.player.invulnerable = immortalPlayer;
  for (var t = 0; t < ms; t += 16) {
    each?.call(t);
    ai.update(16, a.rock, a.player, rockPhaseStats[a.step - 1], a.step, a.worldWidth);
    a.update(16);
  }
}

FightArena makeArena(int step, {double px = 1500, double rx = 2400}) {
  final a = FightArena(worldWidth: 4000)
    ..player.x = px
    ..rock.x = rx;
  a.setStep(step);
  return a;
}

/// Awal tiap serangan Rock: (id, waktu ms). Instans serangan berbeda dihitung sebagai serangan baru,
/// jadi dua pukulan beruntun tercatat dua kali.
List<(String, int)> rockAttackStarts(FightArena a, EnemyAi ai, int ms) {
  final starts = <(String, int)>[];
  AttackSpec? last;
  // Pemain dikunci di tempatnya: terjerembab ke dinding akibat terdorong petarung lawan akan
  // memicu mode anti-sudut (jeda serangan dipotong) dan mengacaukan pengukuran jeda normal.
  final anchor = a.player.x;
  simulate(a, ai, ms, each: (t) {
    a.player.x = anchor;
    final cur = a.rock.attack;
    if (cur != null && !identical(cur, last)) starts.add((cur.id, t));
    last = cur;
  });
  return starts;
}

List<String> rockAttackIds(FightArena a, EnemyAi ai, int ms) =>
    [for (final s in rockAttackStarts(a, ai, ms)) s.$1];

void main() {
  group('gerak dan jarak', () {
    test('Rock mendekati pemain yang jauh', () {
      final a = makeArena(1, px: 600, rx: 3400);
      final ai = EnemyAi(random: math.Random(1));
      simulate(a, ai, 4000);
      expect((a.rock.x - a.player.x).abs(), lessThan(1200));
    });

    test('AI nonaktif: Rock diam', () {
      final a = makeArena(1);
      final ai = EnemyAi(random: math.Random(1))..enabled = false;
      simulate(a, ai, 2000);
      expect(a.rock.x, 2400);
      expect(a.rock.attack, isNull);
    });
  });

  group('perilaku per fase', () {
    test('fase 1: hanya pukulan dan tendangan tunggal, tanpa combo', () {
      final a = makeArena(1);
      final starts = rockAttackStarts(a, EnemyAi(random: math.Random(2)), 40000);
      expect(starts, isNotEmpty);
      expect(starts.map((e) => e.$1).toSet().difference({'punch', 'kick'}), isEmpty);
      for (var i = 0; i + 1 < starts.length; i++) {
        expect(starts[i + 1].$2 - starts[i].$2, greaterThan(800), reason: 'combo di fase 1');
      }
    });

    test('fase 2: ada Tendangan Putar, tidak ada Hantaman atau terjang', () {
      final a = makeArena(2);
      final ids = rockAttackIds(a, EnemyAi(random: math.Random(3)), 60000);
      expect(ids, contains('roundhouse'));
      expect(ids.contains('heavy') || ids.contains('dash'), isFalse);
    });

    test('fase 3: memakai Hantaman dan terjang', () {
      final a = makeArena(3);
      final ids = rockAttackIds(a, EnemyAi(random: math.Random(4)), 90000);
      expect(ids, contains('heavy'));
      expect(ids, contains('roundhouse'));
    });

    test('fase 3: combo 3 serangan beruntun (jeda antar serangan < 1,5 dtk) pernah terjadi', () {
      final a = makeArena(3);
      final starts = rockAttackStarts(a, EnemyAi(random: math.Random(5)), 120000);
      const normal = {'punch', 'kick'};
      var found = false;
      for (var i = 0; i + 2 < starts.length; i++) {
        if (normal.contains(starts[i].$1) &&
            normal.contains(starts[i + 1].$1) &&
            normal.contains(starts[i + 2].$1) &&
            starts[i + 2].$2 - starts[i].$2 < 1500) {
          found = true;
        }
      }
      expect(found, isTrue);
    });

    test('fase 2: combo 2 serangan terjadi, combo 3 tidak', () {
      final a = makeArena(2);
      final starts = rockAttackStarts(a, EnemyAi(random: math.Random(11)), 90000);
      var two = false;
      for (var i = 0; i + 1 < starts.length; i++) {
        if (starts[i + 1].$2 - starts[i].$2 < 800) two = true;
        if (i + 2 < starts.length) {
          expect(starts[i + 2].$2 - starts[i].$2, greaterThan(1100), reason: 'combo 3 di fase 2');
        }
      }
      expect(two, isTrue);
    });
  });

  group('Hantaman', () {
    test('beraba-aba dan tidak terhenti saat terkena (armor), tetap menerima damage', () {
      final a = makeArena(3);
      a.rock.queueAttack(Attacks.heavy);
      for (var i = 0; i < 6; i++) {
        a.update(16);
      }
      expect(a.rock.telegraphing, isTrue);
      final before = a.rock.hp;
      expect(a.rock.receiveHit(Attacks.punch, a.player.x), HitOutcome.hit);
      expect(a.rock.hp, lessThan(before));
      expect(a.rock.state, BodyState.attack);
      expect(a.rock.attack?.id, 'heavy');
    });

    test('aba-aba 500 ms: belum ada damage sebelum selesai', () {
      final a = makeArena(3, px: 2000, rx: 2300);
      a.rock.queueAttack(Attacks.heavy);
      for (var t = 0; t < 480; t += 16) {
        a.update(16);
      }
      expect(a.player.hp, 100);
      expect(a.rock.telegraphing, isTrue);
    });

    test('ditangkis: hanya berkurang 40% (tembus 60%)', () {
      final a = makeArena(3, px: 2000, rx: 2300);
      a.rock.queueAttack(Attacks.heavy);
      for (var t = 0; t < 2000; t += 16) {
        a.player.blockHeld = true;
        a.update(16);
      }
      expect(a.player.hp, closeTo(100 - 18 * 0.6, 1e-9));
    });

    test('pukulan biasa tetap menghentikan serangan Rock yang tidak berarmor', () {
      final a = makeArena(1);
      a.rock.queueAttack(Attacks.kick);
      for (var i = 0; i < 4; i++) {
        a.update(16);
      }
      a.rock.receiveHit(Attacks.punch, a.player.x);
      expect(a.rock.state, BodyState.hurt);
    });
  });

  group('adaptasi dan pertahanan', () {
    test('menyepam serangan yang sama terdeteksi setelah 3 kali', () {
      final a = makeArena(2, px: 1500, rx: 3300);
      final ai = EnemyAi(random: math.Random(6));
      simulate(a, ai, 4000, each: (_) {
        if (a.player.canAct) a.player.queueAttack(Attacks.kick);
      });
      expect(ai.isSpamming('kick'), isTrue);
      expect(ai.isSpamming('punch'), isFalse);
    });

    test('Rock kadang menangkis, tapi tidak selalu (fase 2)', () {
      final a = makeArena(2, px: 2100, rx: 2500);
      final ai = EnemyAi(random: math.Random(7));
      var blockFrames = 0;
      var frames = 0;
      simulate(a, ai, 60000, each: (_) {
        if (a.player.canAct) a.player.queuePunch();
        frames++;
        if (a.rock.state == BodyState.block) blockFrames++;
      });
      expect(blockFrames, greaterThan(0));
      expect(blockFrames / frames, lessThan(0.6));
    });

    test('pemain terjepit di dinding lebih dari 2 detik membuat Rock menekan', () {
      final a = makeArena(2, px: 300, rx: 1200);
      final ai = EnemyAi(random: math.Random(8));
      simulate(a, ai, 2600, each: (_) {
        a.player.moveInput = -1; // terus menekan ke dinding
      });
      expect(ai.pressuring, isTrue);
    });

    test('pemain di tengah arena tidak membuat Rock menekan', () {
      final a = makeArena(2);
      final ai = EnemyAi(random: math.Random(9));
      simulate(a, ai, 3000);
      expect(ai.pressuring, isFalse);
    });
  });

  group('kondisi akhir', () {
    test('Rock berhenti menyerang setelah pemain KO', () {
      final a = makeArena(1, px: 2300, rx: 2600);
      final ai = EnemyAi(random: math.Random(10));
      a.player.hp = 1;
      simulate(a, ai, 8000, immortalPlayer: false);
      expect(a.player.isDead, isTrue);
      expect(a.rock.moveInput, 0);
      expect(ai.hasPlan, isFalse);
    });
  });
}
