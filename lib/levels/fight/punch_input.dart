import 'fight_config.dart';

/// Yang terjadi saat tombol pukul dilepas.
enum PunchRelease {
  /// Tidak ada (tombol tidak sedang ditekan, atau ditahan tapi isi tidak sempat dimulai).
  none,

  /// Ketukan singkat: jalankan pukulan biasa.
  tap,

  /// Sudah mengisi: lepaskan serangan tenaga.
  release,
}

/// Membedakan ketukan (pukulan biasa) dari tahan (serangan tenaga) pada tombol pukul.
/// Murni logika tanpa Flame agar bisa diuji. Ketukan dijalankan saat tombol dilepas; ditahan
/// lebih dari [chargeTapMs] mulai mengisi.
class PunchInput {
  bool held = false;
  bool charged = false;

  /// Isi hilang selama tombol masih ditahan: tidak mengisi ulang dan tidak menjadi pukulan saat dilepas.
  bool lost = false;
  double heldMs = 0;

  void down() {
    if (held) return;
    held = true;
    charged = false;
    lost = false;
    heldMs = 0;
  }

  /// Dipanggil tiap frame. True sekali saja, saat sudah waktunya mulai mengisi; pemanggil lalu
  /// memanggil [markCharging] bila pemain benar-benar bisa mulai mengisi (tidak sedang menyerang).
  bool update(double ms) {
    if (!held) return false;
    heldMs += ms;
    return !charged && !lost && heldMs >= chargeTapMs;
  }

  void markCharging() => charged = true;

  /// Isi hilang (mis. pemain terkena): tombol yang masih ditahan tidak mengisi ulang sampai dilepas
  /// dan ditekan lagi.
  void chargeLost() {
    charged = false;
    lost = true;
  }

  PunchRelease up() {
    if (!held) return PunchRelease.none;
    held = false;
    final wasCharged = charged;
    charged = false;
    if (lost) return PunchRelease.none;
    if (wasCharged) return PunchRelease.release;
    return heldMs < chargeTapMs ? PunchRelease.tap : PunchRelease.none;
  }

  /// Lepas paksa tanpa aksi (jeda, kalah, hasil).
  void reset() {
    held = false;
    charged = false;
    lost = false;
    heldMs = 0;
  }
}
