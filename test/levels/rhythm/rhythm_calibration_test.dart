import 'package:champion_anthology/levels/rhythm/rhythm_calibration.dart';
import 'package:champion_anthology/levels/rhythm/rhythm_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RhythmCalibration.normalize', () {
    test('dibulatkan ke kelipatan 10 ms', () {
      expect(RhythmCalibration.normalize(0), 0);
      expect(RhythmCalibration.normalize(14), 10);
      expect(RhythmCalibration.normalize(16), 20);
      expect(RhythmCalibration.normalize(-44), -40);
    });

    test('dipotong ke rentang -150..+150', () {
      expect(RhythmCalibration.normalize(999), RhythmTuning.maxOffsetMs);
      expect(RhythmCalibration.normalize(-999), RhythmTuning.minOffsetMs);
      expect(RhythmCalibration.normalize(150), 150);
      expect(RhythmCalibration.normalize(-150), -150);
    });
  });

  group('RhythmCalibration tersimpan', () {
    late RhythmCalibration cal;

    setUp(() {
      cal = RhythmCalibration.instance;
      SharedPreferences.setMockInitialValues({});
    });

    test('tanpa data tersimpan nilainya 0', () async {
      final prefs = await SharedPreferences.getInstance();
      cal.init(prefs);
      expect(cal.offsetMs.value, 0);
    });

    test('nilai tersimpan dimuat dan dinormalkan', () async {
      SharedPreferences.setMockInitialValues({RhythmCalibration.prefsKey: 77});
      final prefs = await SharedPreferences.getInstance();
      cal.init(prefs);
      expect(cal.offsetMs.value, 80);
    });

    test('nilai tersimpan di luar rentang dipotong', () async {
      SharedPreferences.setMockInitialValues({RhythmCalibration.prefsKey: -900});
      final prefs = await SharedPreferences.getInstance();
      cal.init(prefs);
      expect(cal.offsetMs.value, -150);
    });

    test('nudge menggeser 10 ms per langkah dan menulis ke penyimpanan', () async {
      final prefs = await SharedPreferences.getInstance();
      cal.init(prefs);
      await cal.nudge(1);
      await cal.nudge(1);
      expect(cal.offsetMs.value, 20);
      expect(prefs.getInt(RhythmCalibration.prefsKey), 20);
      await cal.nudge(-3);
      expect(cal.offsetMs.value, -10);
      expect(prefs.getInt(RhythmCalibration.prefsKey), -10);
    });

    test('nudge berhenti di batas', () async {
      final prefs = await SharedPreferences.getInstance();
      cal.init(prefs);
      await cal.setOffset(150);
      await cal.nudge(1);
      expect(cal.offsetMs.value, 150);
      await cal.setOffset(-150);
      await cal.nudge(-1);
      expect(cal.offsetMs.value, -150);
    });

    test('setelah init ulang dengan penyimpanan yang sama nilai kembali', () async {
      final prefs = await SharedPreferences.getInstance();
      cal.init(prefs);
      await cal.setOffset(60);
      cal.offsetMs.value = 0; // simulasi proses baru
      cal.init(prefs);
      expect(cal.offsetMs.value, 60);
    });

    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      cal.init(prefs);
      await cal.setOffset(0);
    });
  });
}
