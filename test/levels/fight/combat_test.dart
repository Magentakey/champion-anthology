import 'package:champion_anthology/levels/fight/attacks.dart';
import 'package:champion_anthology/levels/fight/fight_arena.dart';
import 'package:champion_anthology/levels/fight/fighter_body.dart';
import 'package:champion_anthology/levels/fight/pose_clips.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arena uji: lebar 4000, pemain di [px], Rock di [rx] (jarak 400 = dalam jangkauan pukul).
FightArena makeArena({double px = 1000, double rx = 1400}) {
  final a = FightArena(worldWidth: 4000);
  a.player.x = px;
  a.rock.x = rx;
  return a;
}

void run(FightArena a, int ms, {void Function(int t)? each}) {
  for (var t = 0; t < ms; t += 16) {
    each?.call(t);
    a.update(16);
  }
}

void main() {
  group('jendela serangan dari klip', () {
    test('pukul: mengenai di 100-200 ms, total 350 ms', () {
      expect(Attacks.punch.hitStartMs, 100);
      expect(Attacks.punch.hitEndMs, 200);
      expect(Attacks.punch.totalMs, 350);
    });

    test('tendang lebih lambat dari pukul; pukulan berat Rock paling panjang jangkauannya', () {
      expect(Attacks.kick.hitStartMs, greaterThan(Attacks.punch.hitStartMs));
      expect(Attacks.heavy.hitStartMs, 40);
      expect(Attacks.heavy.hitEndMs, 210);
    });

    test('damage pisau = 1,5x pukul', () {
      expect(Attacks.throwKnife.damage, Attacks.punch.damage * 1.5);
    });
  });

  group('pukulan dan tendangan', () {
    test('pukulan dalam jangkauan mengurangi HP Rock tepat sekali', () {
      final a = makeArena();
      a.player.queuePunch();
      run(a, 1200);
      expect(a.rock.hp, 300 - 6);
      expect(a.events.where((e) => e.kind == HitKind.hit && e.byPlayer).length, 1);
    });

    test('pukulan di luar jangkauan meleset', () {
      final a = makeArena(rx: 2200);
      a.player.queuePunch();
      run(a, 800);
      expect(a.rock.hp, 300);
      expect(a.events, isEmpty);
    });

    test('tendangan: damage 10 dan mendorong Rock menjauh', () {
      final a = makeArena();
      a.player.queueAttack(Attacks.kick);
      run(a, 800);
      expect(a.rock.hp, 290);
      expect(a.rock.x, greaterThan(1400));
    });

    test('Rock bisa melukai pemain', () {
      final a = makeArena();
      a.rock.queueAttack(Attacks.punch.withDamage(8));
      run(a, 800);
      expect(a.player.hp, 100 - 8);
      expect(a.events.single.byPlayer, isFalse);
    });

    test('lawan yang kebal mengabaikan pukulan', () {
      final a = makeArena();
      a.rock.invulnerable = true;
      a.player.queuePunch();
      run(a, 800);
      expect(a.rock.hp, 300);
      expect(a.events, isEmpty);
    });
  });

  group('tangkis', () {
    test('tangkis mengurangi damage 80%', () {
      final a = makeArena();
      a.player.queuePunch();
      run(a, 800, each: (_) => a.rock.blockHeld = true);
      expect(a.rock.hp, closeTo(300 - 6 * 0.2, 1e-9));
      expect(a.events.single.kind, HitKind.blocked);
      expect(a.rock.state, BodyState.block);
    });

    test('tangkis tidak membuat terhenti, hanya terdorong sedikit', () {
      final a = makeArena();
      a.player.queueAttack(Attacks.kick);
      run(a, 800, each: (_) => a.rock.blockHeld = true);
      expect(a.rock.hp, closeTo(300 - 2, 1e-9));
      expect(a.rock.x, greaterThan(1400));
      expect(a.rock.x, lessThan(1400 + Attacks.kick.knockback));
    });
  });

  group('rangkaian pukulan', () {
    test('menekan pukul beruntun: pukul -> silang -> penutup', () {
      final a = makeArena(rx: 3200); // jauh, tidak ada yang mengenai
      final ids = <String>[];
      run(a, 1000, each: (t) {
        if (t % 96 == 0) a.player.queuePunch();
        final id = a.player.attack?.id;
        if (id != null && (ids.isEmpty || ids.last != id)) ids.add(id);
      });
      expect(ids.take(3).toList(), ['punch', 'cross', 'finisher']);
    });

    test('pukulan penutup lebih kuat dan mendorong lebih jauh', () {
      expect(Attacks.finisher.damage, greaterThan(Attacks.punch.damage));
      expect(Attacks.finisher.knockback, greaterThan(Attacks.punch.knockback));
    });
  });

  group('pisau', () {
    test('pisau melesat, mengenai Rock (9 damage), lalu hilang', () {
      final a = makeArena(rx: 2000);
      expect(a.player.queueKnife(), isTrue);
      run(a, 1500);
      expect(a.rock.hp, 300 - 9);
      expect(a.knives, isEmpty);
      expect(a.events.any((e) => e.knife), isTrue);
    });

    test('pisau punya jeda 2 detik', () {
      final a = makeArena(rx: 2000);
      a.player.queueKnife();
      run(a, 100);
      expect(a.player.knifeCooldownMs, greaterThan(1800));
      expect(a.player.queueKnife(), isFalse);
      run(a, 2200);
      expect(a.player.queueKnife(), isTrue);
    });

    test('pisau ditangkis hanya memberi sedikit damage', () {
      final a = makeArena(rx: 2000);
      a.player.queueKnife();
      run(a, 1500, each: (_) => a.rock.blockHeld = true);
      expect(a.rock.hp, closeTo(300 - 9 * 0.2, 1e-9));
      expect(a.knives, isEmpty);
    });
  });

  group('batas HP fase dan KO', () {
    test('HP Rock berhenti di batas fase dan tidak mati', () {
      final a = makeArena();
      a.rock.hp = 201; // lantai fase 1 = 200
      a.player.queueAttack(Attacks.kick);
      run(a, 800);
      expect(a.rock.hp, 200);
      expect(a.rock.atFloor, isTrue);
      expect(a.rock.isDead, isFalse);
    });

    test('satu pukulan besar tidak melewati dua batas fase', () {
      final a = makeArena();
      a.rock.hp = 205;
      a.player.queueAttack(Attacks.kick.withDamage(500));
      run(a, 800);
      expect(a.rock.hp, 200);
    });

    test('fase 3: HP Rock bisa mencapai 0 dan KO', () {
      final a = makeArena();
      a.setStep(3);
      a.rock.hp = 5;
      a.player.queuePunch();
      run(a, 800);
      expect(a.rock.hp, 0);
      expect(a.rock.isDead, isTrue);
    });

    test('pemain KO saat HP habis', () {
      final a = makeArena();
      a.player.hp = 4;
      a.rock.queueAttack(Attacks.punch.withDamage(8));
      run(a, 800);
      expect(a.player.isDead, isTrue);
    });

    test('lantai HP dan sifat Rock mengikuti fase', () {
      final a = makeArena();
      a.setStep(2);
      expect(a.rock.hpFloor, closeTo(100, 1e-9));
      a.setStep(3);
      expect(a.rock.hpFloor, 0);
      expect(a.rock.hurtScale, lessThan(1));
    });
  });

  group('FighterBody', () {
    test('adegan skrip kembali ke diam setelah waktunya', () {
      final a = makeArena();
      a.rock.playScripted(Clips.taunt, holdMs: 500);
      expect(a.rock.state, BodyState.scripted);
      run(a, 700);
      expect(a.rock.state, BodyState.idle);
    });

    test('merayakan: pose menang, tidak bisa dipukul lagi', () {
      final a = makeArena();
      a.player.celebrate();
      expect(a.player.state, BodyState.win);
      a.rock.queueAttack(Attacks.punch.withDamage(8));
      run(a, 800);
      expect(a.player.hp, 100);
    });

    test('bergerak menuju lawan lebih cepat daripada mundur', () {
      final a = makeArena(px: 1000, rx: 3000);
      a.player.moveInput = 1;
      run(a, 500);
      final forward = a.player.x - 1000;
      final b = makeArena(px: 1500, rx: 3000);
      b.player.moveInput = -1;
      run(b, 500);
      final backward = 1500 - b.player.x;
      expect(forward, greaterThan(backward));
    });

    test('petarung tidak bisa menembus dinding arena', () {
      final a = makeArena(px: 400, rx: 3000);
      a.player.moveInput = -1;
      run(a, 3000);
      expect(a.player.x, greaterThanOrEqualTo(260));
    });
  });
}
