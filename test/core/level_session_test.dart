import 'package:champion_anthology/core/level/level_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kalah di Step 1 = 0 bintang', () {
    final s = LevelSession()..loseStep();
    expect(s.stars, 0);
    expect(s.isFinished, isTrue);
  });

  test('menang Step 1, kalah Step 2 = 1 bintang', () {
    final s = LevelSession()
      ..winStep()
      ..loseStep();
    expect(s.stars, 1);
    expect(s.step, 2);
    expect(s.isFinished, isTrue);
  });

  test('menang Step 1-2, kalah Step 3 = 2 bintang', () {
    final s = LevelSession()
      ..winStep()
      ..winStep()
      ..loseStep();
    expect(s.stars, 2);
    expect(s.step, 3);
  });

  test('menang Step 3 = 3 bintang dan selesai', () {
    final s = LevelSession()
      ..winStep()
      ..winStep()
      ..winStep();
    expect(s.stars, 3);
    expect(s.isFinished, isTrue);
  });

  test('step tidak maju setelah selesai', () {
    final s = LevelSession()
      ..loseStep()
      ..winStep();
    expect(s.stars, 0);
  });

  test('pause menghentikan win/lose sampai resume', () {
    final s = LevelSession()..pause();
    s.winStep();
    expect(s.stepsWon, 0);
    s.resume();
    s.winStep();
    expect(s.stepsWon, 1);
  });
}
