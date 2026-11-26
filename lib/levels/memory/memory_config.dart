/// Konfigurasi Level 8 (Mira the Memory Keeper): ingatan urutan pad, tiga step.
///
/// Berkas ini hanya memuat angka tetap: jumlah pad, panjang urutan, jumlah ronde, tempo tayang, nyawa, dan batas
/// waktu antar-ketukan. Tidak ada kesulitan dinamis; urutannya diacak baru tiap percobaan, tetapi aturan dan
/// angkanya selalu sama. Tes `memory_config_test.dart` memastikan satu-satunya angka pecahan di berkas ini
/// adalah porsi nyala pad (0,7). Ukuran tata letak ada di `memory_stage.dart`.
library;

/// Jumlah pad tiap step (indeks = step - 1): kisi 2x2, 3x2, dan 3x3.
const List<int> memoryPadCount = [4, 6, 9];

/// Panjang urutan pada ronde pertama tiap step.
const List<int> memoryStartLength = [3, 4, 5];

/// Jumlah ronde yang harus diselesaikan untuk memenangkan step.
const List<int> memoryRounds = [5, 6, 7];

/// Tempo tayang per simbol dalam milidetik (nyala + jeda).
const List<int> memoryShowMs = [600, 500, 420];

/// Nyawa awal tiap step. Tidak dipulihkan antar-ronde dan tidak dibawa ke step berikutnya.
const List<int> memoryLives = [3, 2, 2];

/// Batas waktu antar-ketukan dalam milidetik (5, 4, dan 3 detik).
const List<int> memoryInputTimeoutMs = [5000, 4000, 3000];

/// Kolom dan baris kisi pad tiap step (indeks = step - 1): 2x2, 3x2, dan 3x3.
const List<int> memoryGridColumns = [2, 3, 3];
const List<int> memoryGridRows = [2, 2, 3];

/// Batas angka yang sama berturut-turut pada urutan: dua boleh, tiga dilarang.
const int memoryMaxRepeat = 2;

/// Jumlah pad terbanyak (Step 3).
const int memoryMaxPads = 9;

/// Jumlah pad pada [step] (1..3); di luar rentang dipotong ke ujung.
int memoryPadsOf(int step) => memoryPadCount[_index(step)];

/// Panjang urutan ronde pertama pada [step].
int memoryStartLengthOf(int step) => memoryStartLength[_index(step)];

/// Jumlah ronde pada [step].
int memoryRoundsOf(int step) => memoryRounds[_index(step)];

/// Tempo tayang per simbol (ms) pada [step].
int memoryShowMsOf(int step) => memoryShowMs[_index(step)];

/// Nyawa awal pada [step].
int memoryLivesOf(int step) => memoryLives[_index(step)];

/// Batas waktu antar-ketukan (ms) pada [step].
int memoryTimeoutMsOf(int step) => memoryInputTimeoutMs[_index(step)];

/// Kolom dan baris kisi pad pada [step].
int memoryColumnsOf(int step) => memoryGridColumns[_index(step)];
int memoryRowsOf(int step) => memoryGridRows[_index(step)];

/// Panjang urutan pada ronde [round] (mulai 1) di [step]: panjang awal + ronde - 1.
int memoryLengthOf(int step, int round) => memoryStartLengthOf(step) + round.clamp(1, memoryRoundsOf(step)).toInt() - 1;

/// Panjang urutan pada ronde terakhir [step] (7, 9, 11).
int memoryFinalLengthOf(int step) => memoryLengthOf(step, memoryRoundsOf(step));

/// Jumlah semua simbol yang harus diingat sepanjang step (25, 39, 56).
int memoryTotalSymbolsOf(int step) {
  var total = 0;
  for (var round = 1; round <= memoryRoundsOf(step); round++) {
    total += memoryLengthOf(step, round);
  }
  return total;
}

/// Lama pad menyala (ms) per simbol pada [step]: porsi nyala x tempo.
int memoryLitMsOf(int step) => (memoryShowMsOf(step) * MemoryTuning.litFraction).round();

int _index(int step) => step.clamp(1, memoryPadCount.length).toInt() - 1;

/// Porsi nyala dan durasi tahap (milidetik). Semua nilai tetap.
class MemoryTuning {
  const MemoryTuning._();

  /// Pad menyala 70% dari tempo, sisanya jeda.
  static const double litFraction = 0.7;

  /// Jeda sebelum simbol pertama ditayangkan, banner ronde, dan jeda antar-tahap (ms).
  static const int showLeadMs = 600;
  static const int introMs = 2200;
  static const int roundClearMs = 1000;
  static const int retryMs = 1300;
  static const int resultMs = 1800;
  static const int stepGapMs = 800;

  /// Lama pad tetap menyala setelah diketuk benar (ms), dan lama pad yang benar berkedip setelah salah.
  static const int tapFlashMs = 220;
  static const int blinkMs = 700;

  /// Lama layar berkedip merah dan getaran pad saat salah (ms). Hanya satu kali, tidak berulang cepat.
  static const int wrongFlashMs = 350;

  /// Boss tertawa atau kaget selama sekian milidetik.
  static const int reactionMs = 1200;
}
