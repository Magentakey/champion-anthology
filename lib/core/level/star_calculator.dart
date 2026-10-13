/// Aturan bintang: bintang = jumlah step yang berhasil dimenangkan.
///  - Kalah di Step 1 -> 0 bintang
///  - Menang Step 1, kalah di Step 2 -> 1 bintang
///  - Menang Step 2, kalah di Step 3 -> 2 bintang
///  - Menang Step 3 -> 3 bintang (Perfect Clear)
class StarCalculator {
  const StarCalculator._();

  static const int totalSteps = 3;

  static int fromStepsWon(int stepsWon) =>
      stepsWon.clamp(0, totalSteps).toInt();
}
