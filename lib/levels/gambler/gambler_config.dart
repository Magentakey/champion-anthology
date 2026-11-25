/// Konfigurasi Level 6 (Mr. Lexi the Gambler): tiga permainan peluang bertema pasar malam.
///
/// Berkas ini hanya memuat angka peluang dan jumlah/durasi. Peluang menang ADALAH konstanta tetap:
/// tidak ada bonus setelah kalah, tidak ada kesulitan dinamis, dan tidak ada riwayat yang dibaca.
/// Tes `gambler_test.dart` memastikan tiga angka peluang di bawah ini satu-satunya angka pecahan di berkas ini
/// (ukuran tata letak ada di `gambler_table.dart`).
library;

/// Tiga permainan, satu per step.
enum LuckGame { card, coin, cup }

/// Peluang menang tiap step (indeks = step - 1): 75% (3 dari 4 kartu aman), 50% (1 dari 2 sisi),
/// 25% (1 dari 4 cangkir).
const List<double> gamblerWinChance = [0.75, 0.5, 0.25];

/// Permainan tiap step (indeks = step - 1).
const List<LuckGame> gamblerGames = [LuckGame.card, LuckGame.coin, LuckGame.cup];

/// Nama permainan yang tampil di banner step (indeks = step - 1).
const List<String> gamblerStepLabels = ['Tebak Kartu', 'Lempar Koin', 'Cangkir Tebak Bola'];

/// Peluang menang pada [step] (1..3); di luar rentang dipotong ke ujung.
double gamblerChanceOf(int step) => gamblerWinChance[_index(step)];

/// Permainan pada [step] (1..3); di luar rentang dipotong ke ujung.
LuckGame gamblerGameOf(int step) => gamblerGames[_index(step)];

/// Peluang menang dalam persen bulat (75, 50, atau 25), dipakai untuk label di layar.
int gamblerChancePercent(int step) => (gamblerChanceOf(step) * 100).round();

int _index(int step) => step.clamp(1, gamblerWinChance.length).toInt() - 1;

/// Jumlah kartu, cangkir, dan durasi animasi (milidetik). Animasi hanya hiasan: hasil sudah ditentukan
/// sebelum pemain memilih.
class GamblerTuning {
  const GamblerTuning._();

  /// Step 1: 4 kartu tertutup, 1 di antaranya kartu sial.
  static const int cardCount = 4;
  static const int bombCount = 1;

  /// Step 2: dua sisi koin (kepala, ekor).
  static const int coinSides = 2;

  /// Step 3: 4 cangkir, 1 berbola, diacak 5 kali.
  static const int cupCount = 4;
  static const int shuffleSwaps = 5;

  /// Banner step sebelum permainan mulai.
  static const int introMs = 1600;

  /// Kartu: kartu terpilih terbalik, lalu tiga kartu lain ikut terbuka.
  static const int cardFlipMs = 600;
  static const int cardRevealMs = 500;

  /// Koin: terlempar dan berputar sampai mendarat.
  static const int coinTossMs = 1500;
  static const int coinSettleMs = 400;

  /// Cangkir: bola ditampilkan, cangkir menutup, diacak, lalu cangkir terpilih terangkat.
  static const int cupShowMs = 900;
  static const int cupCoverMs = 400;
  static const int cupShuffleMs = 2500;

  /// Akhir acakan: keempat cangkir menyatu jadi satu tumpukan di tengah (identitas cangkir hilang),
  /// ditahan sebentar, lalu dijajarkan lagi.
  static const int cupGatherMs = 700;
  static const int cupMergeHoldMs = 400;
  static const int cupSpreadMs = 700;
  static const int cupLiftMs = 600;
  static const int cupRevealMs = 500;

  /// Jeda memperlihatkan hasil sebelum dilaporkan ke sesi, dan jeda antar step.
  static const int resultMs = 1500;
  static const int stepGapMs = 1000;

  /// Jumlah setengah putaran koin selama dilempar.
  static const int coinHalfTurns = 7;
}
