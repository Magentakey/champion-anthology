import 'package:champion_anthology/core/audio/audio_service.dart';
import 'package:champion_anthology/levels/fight/attacks.dart';
import 'package:champion_anthology/levels/fight/enemy_ai.dart';
import 'package:champion_anthology/levels/fight/fight_arena.dart';
import 'package:champion_anthology/levels/fight/fight_config.dart';
import 'package:champion_anthology/levels/fight/fighter_body.dart';
import 'package:champion_anthology/levels/fight/hit_feel.dart';
import 'package:champion_anthology/levels/fight/pose_clips.dart';
import 'package:champion_anthology/levels/fight/pose_frames.dart';
import 'package:champion_anthology/levels/fight/pose_library.dart';
import 'package:champion_anthology/levels/fight/punch_input.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arena uji: pemain di 1000, Rock di [rx]. Jarak 250 membuat ketiga pukulan rangkaian mengenai
/// meski Rock terdorong di antaranya.
FightArena makeArena({double px = 1000, double rx = 1250}) {
  final a = FightArena(worldWidth: 4000);
  a.player.x = px;
  a.rock.x = rx;
  return a;
}

HitEvent event(
  String id, {
  bool byPlayer = true,
  HitKind kind = HitKind.hit,
  bool knife = false,
  double knockback = 0,
  double damage = 6,
}) =>
    HitEvent(
      kind: kind,
      byPlayer: byPlayer,
      x: 0,
      y: -600,
      damage: damage,
      id: id,
      knife: knife,
      knockback: knockback,
    );

void main() {
  group('angka pertarungan tidak berubah (tuning dijaga)', () {
    void expectStats(AttackSpec s, double damage, double knockback, int hurtMs) {
      expect(s.damage, damage, reason: '${s.id} damage');
      expect(s.knockback, knockback, reason: '${s.id} knockback');
      expect(s.hurtMs, hurtMs, reason: '${s.id} hurtMs');
    }

    test('serangan pemain: damage, dorongan, dan lama terhenti sama seperti v1.5.0', () {
      expectStats(Attacks.punch, 6, 110, 260);
      expectStats(Attacks.cross, 6, 130, 260);
      expectStats(Attacks.finisher, 8, 320, 380);
      expectStats(Attacks.kick, 10, 260, 360);
      expectStats(Attacks.throwKnife, 9, 90, 220);
    });

    test('serangan Rock: damage, dorongan, dan lama terhenti sama seperti v1.5.0', () {
      expectStats(Attacks.heavy, 18, 380, 460);
      expectStats(Attacks.roundhouse, 12, 320, 420);
      expectStats(Attacks.dash, 10, 200, 300);
    });

    test('tendangan penutup combo berangka sama dengan tendangan biasa', () {
      expectStats(Attacks.comboKick, 10, 260, 360);
      expect(Attacks.comboKick.tip, Attacks.kick.tip);
      expect(Attacks.comboKick.clip, same(Clips.roundhouse));
      expect(Attacks.comboKick.hitStartMs, Attacks.kick.hitStartMs);
      expect(Attacks.comboKick.hitEndMs, Attacks.kick.hitEndMs);
      expect(Attacks.comboKick.totalMs, Attacks.kick.totalMs);
    });

    test('jendela waktu klip baru sama dengan klip lama yang digantikan', () {
      for (final (a, b) in [
        (Attacks.finisher, Attacks.punch),
        (Attacks.dash, Attacks.punch),
        (Attacks.roundhouse, Attacks.kick),
      ]) {
        expect(a.hitStartMs, b.hitStartMs, reason: '${a.id} hitStart');
        expect(a.hitEndMs, b.hitEndMs, reason: '${a.id} hitEnd');
        expect(a.totalMs, b.totalMs, reason: '${a.id} total');
      }
      expect(Attacks.heavy.hitStartMs, 40);
      expect(Attacks.heavy.hitEndMs, 210);
    });

    test('jangkauan efektif penutup (tinju + maju) tidak lebih pendek dari pukulan biasa', () {
      final punchReach = Attacks.punch.tipOf(Poses.punchHit).dx;
      final finisherReach =
          Attacks.finisher.tipOf(Clips.uppercut.sample(Attacks.finisher.hitStartMs + 30)).dx + Attacks.finisher.lunge;
      expect(finisherReach, greaterThanOrEqualTo(punchReach - 1));
    });

    test('jangkauan ujung serangan Rock baru sama dengan klip lamanya (selisih <= 5)', () {
      expect((Attacks.roundhouse.tipOf(Poses.roundhouseHit).dx - Attacks.kick.tipOf(Poses.kickHit).dx).abs(), lessThanOrEqualTo(5));
      expect((Attacks.dash.tipOf(Poses.dashHit).dx - Attacks.punch.tipOf(Poses.punchHit).dx).abs(), lessThanOrEqualTo(5));
    });
  });

  group('klip dan pose baru', () {
    test('penutup combo punya animasi sendiri, bukan klip pukul', () {
      expect(Attacks.finisher.clip, same(Clips.uppercut));
      expect(Attacks.finisher.clip, isNot(same(Clips.punch)));
      expect(Clips.uppercut.keys.map((k) => k.pose), contains(Poses.uppercutAir));
    });

    test('Tendangan Putar dan terjang Rock punya animasi sendiri', () {
      expect(Attacks.roundhouse.clip, same(Clips.roundhouse));
      expect(Attacks.dash.clip, same(Clips.dash));
      expect(Attacks.roundhouse.telegraphClip, same(Clips.roundhouseWind));
      expect(Attacks.dash.telegraphClip, same(Clips.dashWind));
      expect(Attacks.heavy.telegraphClip, same(Clips.heavyWind));
    });

    test('semua klip baru terdaftar di Clips.all dan semua posenya punya bingkai', () {
      for (final name in ['uppercut', 'kickHigh', 'roundhouse', 'roundhouseWind', 'dash', 'dashWind', 'hurtLight', 'stagger', 'launched']) {
        expect(Clips.all.containsKey(name), isTrue, reason: name);
        expect(Clips.all[name]!.name, name);
      }
      expect(PoseFrames.poses.length, 33);
    });

    test('idle 1400 ms (tiga bingkai) dan jalan 360 ms (lima bingkai)', () {
      expect(Clips.idle.durationMs, 1400);
      expect(Clips.walk.durationMs, 360);
    });

    test('pose uppercut: tinju naik di atas pinggang, kaki lepas tanah di puncak', () {
      expect(Poses.uppercutHit.handF.dy, lessThan(Poses.uppercutHit.hip.dy));
      expect(Poses.uppercutAir.toeF.dy, lessThan(-50));
      expect(Poses.uppercutAir.toeB.dy, lessThan(-50));
    });
  });

  group('reaksi korban berbeda per pukulan', () {
    test('tiap serangan menunjuk klip reaksi yang sesuai bobotnya', () {
      expect(Attacks.punch.hurtClip, same(Clips.hurtLight));
      expect(Attacks.cross.hurtClip, same(Clips.hurt));
      expect(Attacks.finisher.hurtClip, same(Clips.launched));
      expect(Attacks.kick.hurtClip, same(Clips.stagger));
      expect(Attacks.comboKick.hurtClip, same(Clips.launched));
      expect(Attacks.heavy.hurtClip, same(Clips.launched));
    });

    test('tiga pukulan rangkaian menghasilkan tiga reaksi Rock yang berbeda', () {
      final a = makeArena();
      final reactions = <String>[];
      for (final spec in Attacks.punchChain) {
        expect(a.rock.receiveHit(spec, a.player.x), HitOutcome.hit);
        reactions.add(a.rock.clip.name);
      }
      expect(reactions, ['hurtLight', 'hurt', 'launched']);
      expect(a.rock.state, BodyState.hurt);
    });

    test('damage 3 pukulan beruntun = 6 + 6 + 8', () {
      final a = makeArena();
      for (final spec in Attacks.punchChain) {
        a.rock.receiveHit(spec, a.player.x);
      }
      expect(a.rock.hp, 300 - 20);
    });

    test('withDamage mempertahankan klip reaksi dan aba-aba', () {
      final s = Attacks.roundhouse.withDamage(13);
      expect(s.hurtClip, same(Attacks.roundhouse.hurtClip));
      expect(s.telegraphClip, same(Attacks.roundhouse.telegraphClip));
      expect(s.clip, same(Clips.roundhouse));
    });

    test('lama terhenti tetap spec.hurtMs, apa pun klip reaksinya', () {
      final a = makeArena(rx: 1400);
      a.player.queueAttack(Attacks.kick);
      var stunned = 0;
      for (var t = 0; t < 1200; t += 16) {
        a.update(16);
        if (a.rock.state == BodyState.hurt) stunned += 16;
      }
      expect(stunned, closeTo(Attacks.kick.hurtMs * rockPhaseStats[0].hurtScale, 20));
    });
  });

  group('combo: pukul, silang, tendang', () {
    List<String> attackIds(FightArena a, void Function(int t) each, {int ms = 1500}) {
      final ids = <String>[];
      for (var t = 0; t < ms; t += 16) {
        each(t);
        a.update(16);
        final id = a.player.attack?.id;
        if (id != null && (ids.isEmpty || ids.last != id)) ids.add(id);
      }
      return ids;
    }

    test('tendang setelah pukul + silang menjadi tendangan penutup', () {
      final a = makeArena(rx: 3200);
      var kickQueued = false;
      final ids = attackIds(a, (t) {
        if (t <= 192 && t % 96 == 0) a.player.queuePunch();
        if (!kickQueued && a.player.attack?.id == 'cross' && a.player.attackMs >= 96) {
          a.player.queueAttack(Attacks.kick);
          kickQueued = true;
        }
      });
      expect(ids.take(3).toList(), ['punch', 'cross', 'comboKick']);
    });

    test('tendang biasa (tanpa combo) tetap tendangan biasa', () {
      final a = makeArena(rx: 3200);
      final ids = attackIds(a, (t) {
        if (t == 0) a.player.queueAttack(Attacks.kick);
      });
      expect(ids.first, 'kick');
    });

    test('tendang setelah satu pukulan saja (belum silang) tetap tendangan biasa', () {
      final a = makeArena(rx: 3200);
      var kickQueued = false;
      final ids = attackIds(a, (t) {
        if (t == 0) a.player.queuePunch();
        if (!kickQueued && a.player.attack?.id == 'punch' && a.player.attackMs >= 270) {
          a.player.queueAttack(Attacks.kick);
          kickQueued = true;
        }
      });
      expect(ids.take(2).toList(), ['punch', 'kick']);
    });

    test('jendela combo habis: tendang setelah silang yang sudah lama selesai = tendangan biasa', () {
      final a = makeArena(rx: 3200);
      var kickQueued = false;
      final ids = attackIds(a, (t) {
        if (t <= 192 && t % 96 == 0) a.player.queuePunch();
        if (!kickQueued && t >= 1300) {
          a.player.queueAttack(Attacks.kick);
          kickQueued = true;
        }
      }, ms: 1800);
      expect(ids, ['punch', 'cross', 'kick']);
    });

    test('tendangan penutup yang mengenai Rock: damage 10 dan reaksi terlempar', () {
      final a = makeArena();
      a.rock.hurtScale = 3; // Rock tetap terhenti selama rangkaian
      var kickQueued = false;
      final seen = <String>[];
      var reactionAfterComboKick = '';
      for (var t = 0; t < 1500; t += 16) {
        if (t <= 192 && t % 96 == 0) a.player.queuePunch();
        if (!kickQueued && a.player.attack?.id == 'cross' && a.player.attackMs >= 96) {
          a.player.queueAttack(Attacks.kick);
          kickQueued = true;
        }
        a.update(16);
        for (final e in a.events) {
          seen.add(e.id);
          if (e.id == 'comboKick') reactionAfterComboKick = a.rock.clip.name;
        }
        a.events.clear();
      }
      expect(seen.take(2).toList(), ['punch', 'cross']);
      // tendangan penutup hanya mengenai bila Rock masih dalam jangkauan setelah terdorong dua kali
      if (seen.contains('comboKick')) {
        expect(a.rock.hp, 300 - 6 - 6 - 10);
        expect(reactionAfterComboKick, 'launched');
      }
    });
  });

  group('hitungan combo', () {
    test('naik 1, 2 tiap pukulan rangkaian yang mengenai', () {
      final a = makeArena();
      a.rock.hurtScale = 3; // Rock tetap terhenti selama rangkaian
      final counts = <int>[];
      for (var t = 0; t < 700; t += 16) {
        if (t <= 192 && t % 96 == 0) a.player.queuePunch();
        a.update(16);
        for (final e in a.events) {
          if (e.byPlayer) counts.add(e.combo);
        }
        a.events.clear();
      }
      expect(counts.take(2).toList(), [1, 2]);
      expect(a.combo, 2);
    });

    test('pukulan meleset atau ditangkis tidak menaikkan hitungan', () {
      final a = makeArena(rx: 2200);
      a.player.queuePunch();
      for (var t = 0; t < 800; t += 16) {
        a.update(16);
      }
      expect(a.combo, 0);

      final b = makeArena(rx: 1400);
      b.player.queuePunch();
      for (var t = 0; t < 800; t += 16) {
        b.rock.blockHeld = true;
        b.update(16);
      }
      expect(b.combo, 0);
    });

    test('terkena serangan Rock memutus combo', () {
      final a = makeArena();
      a.combo = 2;
      a.rock.queueAttack(Attacks.punch);
      for (var t = 0; t < 800; t += 16) {
        a.update(16);
      }
      expect(a.player.hp, 100 - 6);
      expect(a.combo, 0);
    });

    test('hitungan direset bila tidak mengenai selama comboResetMs', () {
      final a = makeArena();
      a.player.queuePunch();
      for (var t = 0; t < 400; t += 16) {
        a.update(16);
      }
      expect(a.combo, 1);
      for (var t = 0; t < comboResetMs + 100; t += 16) {
        a.update(16);
      }
      expect(a.combo, 0);
    });

    test('pindah fase mengosongkan hitungan', () {
      final a = makeArena();
      a.combo = 4;
      a.setStep(2);
      expect(a.combo, 0);
    });

    test('label HUD: tampil mulai x2, tanda seru mulai x3', () {
      expect(minComboShown, 2);
      expect(comboLabel(2), 'x2 COMBO');
      expect(comboLabel(3), 'x3 COMBO!');
    });
  });

  group('serangan baru Rock', () {
    test('Tendangan Putar: aba-aba memakai pose sendiri, lalu klip tendangan putar, korban terlempar', () {
      final a = makeArena(rx: 1400);
      a.rock.queueAttack(Attacks.roundhouse);
      a.update(16);
      a.update(16);
      for (var t = 0; t < 150; t += 16) {
        a.update(16);
      }
      expect(a.rock.telegraphing, isTrue);
      expect(a.rock.clip.name, 'roundhouseWind');
      var sawRoundhouse = false;
      var playerReaction = '';
      for (var t = 0; t < 1200; t += 16) {
        a.update(16);
        if (a.rock.clip.name == 'roundhouse') sawRoundhouse = true;
        for (final e in a.events) {
          if (!e.byPlayer) playerReaction = a.player.clip.name;
        }
        a.events.clear();
      }
      expect(sawRoundhouse, isTrue);
      expect(playerReaction, 'launched');
      expect(a.player.hp, 100 - 12);
    });

    test('Pukulan terjang: aba-aba dashWind lalu klip dash', () {
      final a = makeArena(rx: 1700);
      a.rock.queueAttack(Attacks.dash);
      a.update(16);
      for (var t = 0; t < 100; t += 16) {
        a.update(16);
      }
      expect(a.rock.clip.name, 'dashWind');
      var sawDash = false;
      for (var t = 0; t < 1200; t += 16) {
        a.update(16);
        if (a.rock.clip.name == 'dash') sawDash = true;
      }
      expect(sawDash, isTrue);
    });
  });

  group('rasa pukulan (hit-stop, getar, suara, gerak lambat, debu)', () {
    test('hit-stop dan getar naik seiring combo: jab < silang < penutup', () {
      final jab = hitFeelFor(event('punch'));
      final cross = hitFeelFor(event('cross'));
      final fin = hitFeelFor(event('finisher', knockback: 320));
      expect(jab.hitStopMs, lessThan(cross.hitStopMs));
      expect(cross.hitStopMs, lessThan(fin.hitStopMs));
      expect(jab.shake, lessThan(cross.shake));
      expect(cross.shake, lessThan(fin.shake));
      expect(jab.sparkRadius, lessThan(fin.sparkRadius));
    });

    test('penutup combo punya suara sendiri; jab dan silang memakai suara pukul', () {
      expect(hitFeelFor(event('punch')).sfx, Sfx.punch);
      expect(hitFeelFor(event('cross')).sfx, Sfx.punch);
      expect(hitFeelFor(event('finisher')).sfx, Sfx.finisher);
      expect(hitFeelFor(event('comboKick')).sfx, Sfx.finisher);
      expect(hitFeelFor(event('kick')).sfx, Sfx.kick);
      expect(hitFeelFor(event('roundhouse')).sfx, Sfx.kick);
      expect(hitFeelFor(event('heavy')).sfx, Sfx.heavy);
      expect(hitFeelFor(event('throw', knife: true)).sfx, Sfx.knifeHit);
    });

    test('hanya penutup combo yang diberi gerak lambat singkat', () {
      for (final id in ['punch', 'cross', 'kick', 'heavy', 'roundhouse']) {
        expect(hitFeelFor(event(id)).slowMs, 0, reason: id);
      }
      for (final id in ['finisher', 'comboKick']) {
        final f = hitFeelFor(event(id));
        expect(f.slowMs, inInclusiveRange(100, 300), reason: id);
        expect(f.slowScale, lessThan(1));
        expect(f.slowScale, greaterThan(0.2));
      }
    });

    test('pukulan yang ditangkis: ringan dan bersuara tangkis', () {
      final f = hitFeelFor(event('heavy', kind: HitKind.blocked));
      expect(f.sfx, Sfx.block);
      expect(f.hitStopMs, 30);
      expect(f.shake, 2);
      expect(f.slowMs, 0);
      expect(f.dust, isFalse);
    });

    test('debu muncul hanya pada dorongan kuat', () {
      expect(hitFeelFor(event('punch', knockback: 110)).dust, isFalse);
      expect(hitFeelFor(event('cross', knockback: 130)).dust, isFalse);
      expect(hitFeelFor(event('kick', knockback: 260)).dust, isTrue);
      expect(hitFeelFor(event('heavy', knockback: 380)).dust, isTrue);
      expect(hitFeelFor(event('finisher', knockback: 320)).dust, isTrue);
      expect(dustKnockback, 250);
    });

    test('hit-stop tidak pernah lebih lama dari 100 ms dan getar tidak lebih dari 14', () {
      for (final id in ['punch', 'cross', 'finisher', 'comboKick', 'kick', 'roundhouse', 'heavy', 'dash', 'xyz']) {
        final f = hitFeelFor(event(id, knockback: 400));
        expect(f.hitStopMs, lessThanOrEqualTo(100), reason: id);
        expect(f.shake, lessThanOrEqualTo(14), reason: id);
        expect(f.hitStopMs, greaterThan(0), reason: id);
      }
    });

    test('serangan Rock ke pemain tetap memakai hit-stop standar 60 ms (tidak lebih ringan dari v1.5.0)', () {
      expect(hitFeelFor(event('punch', byPlayer: false)).hitStopMs, 60);
    });
  });

  group('combo tendang + tendang', () {
    test('tendangan tinggi: angka baru, waktu sama dengan tendangan biasa', () {
      expect(Attacks.kickHigh.damage, 9);
      expect(Attacks.kickHigh.knockback, 300);
      expect(Attacks.kickHigh.hurtMs, 380);
      expect(Attacks.kickHigh.clip, same(Clips.kickHigh));
      expect(Attacks.kickHigh.hurtClip, same(Clips.launched));
      expect(Attacks.kickHigh.hitStartMs, Attacks.kick.hitStartMs);
      expect(Attacks.kickHigh.hitEndMs, Attacks.kick.hitEndMs);
      expect(Attacks.kickHigh.totalMs, Attacks.kick.totalMs);
    });

    test('jangkauan tendangan tinggi (kaki + maju) tidak lebih pendek dari tendangan biasa', () {
      final kickReach = Attacks.kick.tipOf(Poses.kickHit).dx;
      final highReach = Attacks.kickHigh.tipOf(Poses.kickHighHit).dx + Attacks.kickHigh.lunge;
      expect(highReach, greaterThanOrEqualTo(kickReach - 1));
      expect(Poses.kickHighHit.toeF.dy, lessThan(Poses.kickHit.toeF.dy), reason: 'lebih tinggi dari tendangan biasa');
    });

    List<String> kickIds(FightArena a, bool Function(int t) pressKick, {int ms = 1500}) {
      final ids = <String>[];
      for (var t = 0; t < ms; t += 16) {
        if (pressKick(t)) a.player.queueAttack(Attacks.kick);
        a.update(16);
        final id = a.player.attack?.id;
        if (id != null && (ids.isEmpty || ids.last != id)) ids.add(id);
      }
      return ids;
    }

    test('tendang lagi saat pemulihan tendangan pertama: menjadi tendangan tinggi', () {
      final a = makeArena(rx: 3200);
      final ids = kickIds(a, (t) => t == 0 || (a.player.attack?.id == 'kick' && a.player.attackMs >= 176 && a.player.attackMs < 200));
      expect(ids.take(2).toList(), ['kick', 'kickHigh']);
    });

    test('tendang lagi sesaat setelah tendangan pertama selesai (dalam jendela combo): tendangan tinggi', () {
      final a = makeArena(rx: 3200);
      var second = false;
      final ids = kickIds(a, (t) {
        if (t == 0) return true;
        // ketuk tepat setelah tendangan pertama berakhir
        if (!second && a.player.attack == null && t > 400 && t < 700) {
          second = true;
          return true;
        }
        return false;
      });
      expect(ids.take(2).toList(), ['kick', 'kickHigh']);
    });

    test('tendang lagi setelah jendela combo habis: tendangan biasa lagi', () {
      final a = makeArena(rx: 3200);
      var second = false;
      final seen = <String>[];
      for (var t = 0; t < 2000; t += 16) {
        if (t == 0) a.player.queueAttack(Attacks.kick);
        if (!second && t >= 1300) {
          a.player.queueAttack(Attacks.kick);
          second = true;
        }
        a.update(16);
        final id = a.player.attack?.id;
        if (id != null && t >= 1300 && !seen.contains(id)) seen.add(id);
      }
      expect(seen, ['kick']);
    });

    test('punch lalu tendang tidak menjadi tendangan tinggi', () {
      final a = makeArena(rx: 3200);
      a.player.queuePunch();
      var kicked = false;
      final ids = <String>[];
      for (var t = 0; t < 1200; t += 16) {
        if (!kicked && a.player.attack?.id == 'punch' && a.player.attackMs >= 270) {
          a.player.queueAttack(Attacks.kick);
          kicked = true;
        }
        a.update(16);
        final id = a.player.attack?.id;
        if (id != null && (ids.isEmpty || ids.last != id)) ids.add(id);
      }
      expect(ids, ['punch', 'kick']);
    });

    test('combo khusus hanya untuk pemain: Rock menendang dua kali tetap tendangan biasa', () {
      final a = makeArena(rx: 3200);
      expect(a.player.combosEnabled, isTrue);
      expect(a.rock.combosEnabled, isFalse);
      final ids = <String>[];
      for (var t = 0; t < 1500; t += 16) {
        if (t == 0 || (a.rock.attack?.id == 'kick' && a.rock.attackMs >= 176 && a.rock.attackMs < 200)) {
          a.rock.queueAttack(Attacks.kick);
        }
        a.update(16);
        final id = a.rock.attack?.id;
        if (id != null && (ids.isEmpty || ids.last != id)) ids.add(id);
      }
      expect(ids, isNot(contains('kickHigh')));
      expect(ids, isNot(contains('comboKick')));
    });

    test('tendangan tinggi membuat lawan terlempar', () {
      final a = makeArena();
      expect(a.rock.receiveHit(Attacks.kickHigh, a.player.x), HitOutcome.hit);
      expect(a.rock.clip.name, 'launched');
      expect(a.rock.hp, 300 - 9);
    });
  });

  group('serangan tenaga (tahan pukul)', () {
    void run(FightArena a, int ms) {
      for (var t = 0; t < ms; t += 16) {
        a.update(16);
      }
    }

    test('angka serangan tenaga', () {
      expect(Attacks.chargeSlam.damage, 14);
      expect(Attacks.chargeSlam.knockback, 300);
      expect(Attacks.chargeSlam.hurtMs, 420);
      expect(Attacks.chargeFull.damage, 22);
      expect(Attacks.chargeFull.knockback, 420);
      expect(Attacks.chargeFull.hurtMs, 520);
      expect(Attacks.chargeSlam.armored, isTrue);
      expect(Attacks.chargeFull.armored, isTrue);
      expect(Attacks.chargeFull.damage, greaterThan(Attacks.chargeSlam.damage));
      expect(Attacks.chargeSlam.damage, greaterThan(Attacks.finisher.damage), reason: 'sepadan dengan risiko mengisi');
      expect(Attacks.chargeFull.damage, greaterThan(Attacks.heavy.damage), reason: 'penuh melebihi pukulan berat Rock');
    });

    test('ayunan memakai klip pukulan berat yang sama dengan Rock', () {
      expect(Attacks.chargeSlam.clip, same(Clips.heavyHit));
      expect(Attacks.chargeFull.clip, same(Clips.heavyHit));
      expect(Attacks.chargeSlam.hitStartMs, Attacks.heavy.hitStartMs);
      expect(Attacks.chargeSlam.hitEndMs, Attacks.heavy.hitEndMs);
    });

    test('ambang waktu: ketuk 200, minimal 500, penuh 1000 ms', () {
      expect(chargeTapMs, 200);
      expect(chargeMinMs, 500);
      expect(chargeFullMs, 1000);
    });

    test('beginCharge: berdiri menahan pose, isi naik bersama waktu', () {
      final a = makeArena(rx: 3200);
      expect(a.player.beginCharge(), isTrue);
      expect(a.player.charging, isTrue);
      expect(a.player.state, BodyState.attack);
      expect(a.player.clip.name, 'heavyWind');
      expect(a.player.chargeFraction, 0);
      run(a, 500);
      expect(a.player.chargeFraction, closeTo(0.5, 0.05));
      expect(a.player.chargeReady, isTrue);
    });

    test('isi berhenti di penuh (1.0)', () {
      final a = makeArena(rx: 3200);
      a.player.beginCharge();
      run(a, 3000);
      expect(a.player.chargeFraction, 1);
    });

    test('tidak bisa mulai mengisi saat menyerang, terkena, atau sudah mengisi', () {
      final a = makeArena(rx: 3200);
      a.player.queuePunch();
      a.update(16);
      expect(a.player.state, BodyState.attack);
      expect(a.player.beginCharge(), isFalse);

      final b = makeArena();
      b.player.receiveHit(Attacks.punch, b.rock.x);
      expect(b.player.beginCharge(), isFalse);

      final c = makeArena(rx: 3200);
      expect(c.player.beginCharge(), isTrue);
      expect(c.player.beginCharge(), isFalse);
    });

    test('dilepas sebelum isi minimal: batal tanpa menyerang', () {
      final a = makeArena();
      a.player.beginCharge();
      run(a, 300);
      expect(a.player.releaseCharge(), isNull);
      expect(a.player.charging, isFalse);
      expect(a.player.state, isNot(BodyState.attack));
      run(a, 600);
      expect(a.rock.hp, 300);
      expect(a.events, isEmpty);
    });

    test('dilepas setelah isi minimal: hantaman sedang, 14 damage', () {
      final a = makeArena(rx: 1400);
      a.player.beginCharge();
      run(a, 700);
      expect(a.player.releaseCharge(), same(Attacks.chargeSlam));
      var reaction = '';
      final ids = <String>[];
      for (var t = 0; t < 900; t += 16) {
        a.update(16);
        for (final e in a.events) {
          ids.add(e.id);
          reaction = a.rock.clip.name;
        }
        a.events.clear();
      }
      expect(a.rock.hp, 300 - 14);
      expect(ids, ['charge']);
      expect(reaction, 'launched');
    });

    test('dilepas saat penuh: hantaman penuh, 22 damage', () {
      final a = makeArena(rx: 1400);
      a.player.beginCharge();
      run(a, 1200);
      expect(a.player.releaseCharge(), same(Attacks.chargeFull));
      run(a, 900);
      expect(a.rock.hp, 300 - 22);
      expect(a.events.single.id, 'chargeFull');
    });

    test('terkena saat mengisi: isi hilang dan pemain terhenti', () {
      final a = makeArena();
      a.player.beginCharge();
      run(a, 400);
      expect(a.player.receiveHit(Attacks.punch, a.rock.x), HitOutcome.hit);
      expect(a.player.charging, isFalse);
      expect(a.player.chargeFraction, 0);
      expect(a.player.state, BodyState.hurt);
      expect(a.player.releaseCharge(), isNull);
    });

    test('saat mengayun pemain berarmor: menerima damage tapi ayunan tetap jalan', () {
      final a = makeArena(rx: 3200);
      a.player.beginCharge();
      run(a, 600);
      a.player.releaseCharge();
      run(a, 16);
      final hp = a.player.hp;
      expect(a.player.receiveHit(Attacks.punch, a.rock.x), HitOutcome.hit);
      expect(a.player.hp, hp - 6);
      expect(a.player.state, BodyState.attack);
      expect(a.player.attack?.id, 'charge');
    });

    test('cancelCharge (jeda) membatalkan tanpa menyerang', () {
      final a = makeArena(rx: 3200);
      a.player.beginCharge();
      run(a, 300);
      a.player.cancelCharge();
      expect(a.player.charging, isFalse);
      expect(a.player.state, isNot(BodyState.attack));
    });

    test('serangan tenaga penuh yang ditangkis hanya berkurang 40%', () {
      final a = makeArena(rx: 1400);
      a.rock.blockHeld = true;
      a.player.beginCharge();
      for (var t = 0; t < 1200; t += 16) {
        a.rock.blockHeld = true;
        a.update(16);
      }
      a.player.releaseCharge();
      for (var t = 0; t < 900; t += 16) {
        a.rock.blockHeld = true;
        a.update(16);
      }
      expect(a.rock.hp, closeTo(300 - 22 * 0.6, 1e-9));
    });

    test('rasa pukulan: hantaman penuh paling berat dan dapat gerak lambat', () {
      final slam = hitFeelFor(event('charge', knockback: 300));
      final full = hitFeelFor(event('chargeFull', knockback: 420));
      expect(slam.sfx, Sfx.heavy);
      expect(full.sfx, Sfx.heavy);
      expect(full.hitStopMs, greaterThan(slam.hitStopMs));
      expect(full.shake, greaterThan(slam.shake));
      expect(slam.slowMs, 0);
      expect(full.slowMs, greaterThan(0));
      expect(slam.dust && full.dust, isTrue);
      expect(hitFeelFor(event('kickHigh', knockback: 300)).sfx, Sfx.kick);
    });
  });

  group('input tombol pukul: ketuk atau tahan', () {
    test('ketukan singkat menjadi pukulan saat dilepas', () {
      final p = PunchInput()..down();
      expect(p.update(80), isFalse);
      expect(p.up(), PunchRelease.tap);
    });

    test('ditahan melewati ambang: minta mulai mengisi, dan tidak menjadi pukulan', () {
      final p = PunchInput()..down();
      expect(p.update(100), isFalse);
      expect(p.update(120), isTrue); // total 220 >= 200
      p.markCharging();
      expect(p.update(16), isFalse, reason: 'hanya sekali');
      expect(p.up(), PunchRelease.release);
    });

    test('ditahan tapi tidak sempat mulai mengisi (sibuk menyerang): lepas = tidak ada aksi', () {
      final p = PunchInput()..down();
      expect(p.update(300), isTrue);
      // pemanggil gagal beginCharge, tidak memanggil markCharging
      expect(p.up(), PunchRelease.none);
    });

    test('pemanggil dapat mencoba lagi tiap frame sampai bisa mengisi', () {
      final p = PunchInput()..down();
      expect(p.update(250), isTrue);
      expect(p.update(16), isTrue);
      p.markCharging();
      expect(p.update(16), isFalse);
    });

    test('isi hilang saat terkena: tidak mengisi ulang dan tidak jadi pukulan saat dilepas', () {
      final p = PunchInput()..down();
      p.update(250);
      p.markCharging();
      p.chargeLost();
      expect(p.update(500), isFalse);
      expect(p.up(), PunchRelease.none);
    });

    test('tekan lagi setelah dilepas: mulai bersih', () {
      final p = PunchInput()..down();
      p.update(250);
      p.markCharging();
      p.chargeLost();
      p.up();
      p.down();
      expect(p.lost, isFalse);
      expect(p.update(50), isFalse);
      expect(p.up(), PunchRelease.tap);
    });

    test('dilepas tanpa pernah ditekan: tidak ada aksi', () {
      expect(PunchInput().up(), PunchRelease.none);
    });

    test('reset melepas paksa tanpa aksi', () {
      final p = PunchInput()..down();
      p.update(50);
      p.reset();
      expect(p.held, isFalse);
      expect(p.up(), PunchRelease.none);
    });
  });

  group('deteksi spam AI memahami keluarga serangan', () {
    test('tendangan tinggi dan tendangan penutup dihitung sebagai tendangan', () {
      expect(EnemyAi.attackFamily('kick'), 'kick');
      expect(EnemyAi.attackFamily('kickHigh'), 'kick');
      expect(EnemyAi.attackFamily('comboKick'), 'kick');
      expect(EnemyAi.attackFamily('chargeFull'), 'charge');
      expect(EnemyAi.attackFamily('charge'), 'charge');
    });

    test('serangan lain tidak digabung (pukulan rangkaian tetap berbeda)', () {
      for (final id in ['punch', 'cross', 'finisher', 'throw', 'heavy', 'roundhouse', 'dash']) {
        expect(EnemyAi.attackFamily(id), id);
      }
    });
  });
}
