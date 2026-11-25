import '../../core/audio/audio_service.dart';
import 'fight_arena.dart';

/// "Rasa" satu pukulan: seberapa lama layar berhenti sejenak, seberapa kuat getarannya, ukuran
/// percikan, suara, dan apakah ada gerak lambat singkat. Murni data (tanpa Flame) agar bisa diuji.
///
/// Pukulan pemain makin terasa seiring combo: jab ringan, silang lebih berat, penutup
/// (uppercut atau tendangan penutup) paling berat dan diberi gerak lambat singkat.
class HitFeel {
  const HitFeel({
    required this.hitStopMs,
    required this.shake,
    required this.sparkRadius,
    required this.sfx,
    this.slowScale = 1,
    this.slowMs = 0,
    this.dust = false,
  });

  /// Layar berhenti sejenak (ms).
  final double hitStopMs;

  /// Kekuatan getar layar (piksel).
  final double shake;

  /// Jari-jari percikan (satuan ruang gambar).
  final double sparkRadius;
  final Sfx sfx;

  /// Gerak lambat singkat (skala waktu dan lamanya dalam ms waktu nyata); slowMs 0 = tidak ada.
  final double slowScale;
  final double slowMs;

  /// Debu di kaki lawan (dorongan kuat).
  final bool dust;
}

/// Pukulan dengan dorongan sekuat ini atau lebih menimbulkan debu.
const double dustKnockback = 250;

HitFeel hitFeelFor(HitEvent e) {
  if (e.kind == HitKind.blocked) {
    return const HitFeel(hitStopMs: 30, shake: 2, sparkRadius: 200, sfx: Sfx.block);
  }
  if (e.knife) {
    return HitFeel(hitStopMs: 60, shake: 5, sparkRadius: 300, sfx: Sfx.knifeHit, dust: e.knockback >= dustKnockback);
  }
  final dust = e.knockback >= dustKnockback;
  switch (e.id) {
    case 'punch':
      return HitFeel(hitStopMs: e.byPlayer ? 45 : 60, shake: 4, sparkRadius: 260, sfx: Sfx.punch, dust: dust);
    case 'cross':
      return const HitFeel(hitStopMs: 60, shake: 6, sparkRadius: 320, sfx: Sfx.punch);
    case 'finisher':
      return const HitFeel(
        hitStopMs: 90,
        shake: 10,
        sparkRadius: 420,
        sfx: Sfx.finisher,
        slowScale: 0.45,
        slowMs: 170,
        dust: true,
      );
    case 'comboKick':
      return const HitFeel(
        hitStopMs: 90,
        shake: 10,
        sparkRadius: 420,
        sfx: Sfx.finisher,
        slowScale: 0.45,
        slowMs: 170,
        dust: true,
      );
    case 'kickHigh':
      return HitFeel(hitStopMs: 80, shake: 9, sparkRadius: 380, sfx: Sfx.kick, dust: dust);
    case 'charge':
      return const HitFeel(hitStopMs: 85, shake: 11, sparkRadius: 400, sfx: Sfx.heavy, dust: true);
    case 'chargeFull':
      return const HitFeel(
        hitStopMs: 100,
        shake: 14,
        sparkRadius: 480,
        sfx: Sfx.heavy,
        slowScale: 0.4,
        slowMs: 220,
        dust: true,
      );
    case 'kick':
      return HitFeel(hitStopMs: 70, shake: 8, sparkRadius: 340, sfx: Sfx.kick, dust: dust);
    case 'roundhouse':
      return HitFeel(hitStopMs: 70, shake: 8, sparkRadius: 340, sfx: Sfx.kick, dust: dust);
    case 'heavy':
      return HitFeel(hitStopMs: 90, shake: 12, sparkRadius: 420, sfx: Sfx.heavy, dust: dust);
    default:
      return HitFeel(
        hitStopMs: 60,
        shake: e.damage >= 10 ? 8 : 5,
        sparkRadius: 300,
        sfx: Sfx.punch,
        dust: dust,
      );
  }
}
