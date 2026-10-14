import 'package:champion_anthology/levels/genius/genius_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dialog lengkap: 3 intro step dan 4 kelompok hasil (0-3 bintang)', () {
    expect(GeniusDialog.stepIntro.length, 3);
    expect(GeniusDialog.resultByStars.length, 4);
    for (final lines in GeniusDialog.resultByStars) {
      expect(lines, isNotEmpty);
    }
  });

  test('reaksi punya minimal 3 variasi dan tidak ada kalimat kosong', () {
    for (final pool in [
      GeniusDialog.correct,
      GeniusDialog.wrong,
      GeniusDialog.timeout,
    ]) {
      expect(pool.length, greaterThanOrEqualTo(3));
    }
    final all = [
      ...GeniusDialog.stepIntro,
      ...GeniusDialog.correct,
      ...GeniusDialog.wrong,
      ...GeniusDialog.timeout,
      for (final l in GeniusDialog.resultByStars) ...l,
    ];
    expect(all.every((s) => s.trim().isNotEmpty), isTrue);
  });
}
