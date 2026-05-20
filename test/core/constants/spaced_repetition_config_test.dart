import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/spaced_repetition_config.dart';

void main() {
  group('SrConfig', () {
    test('defaultMinEaseFactor equals 1.3', () {
      expect(SrConfig.defaultMinEaseFactor, 1.3);
    });

    test('defaultMaxEaseFactor equals 5.0', () {
      expect(SrConfig.defaultMaxEaseFactor, 5.0);
    });

    test('defaultEaseFactor equals 2.5', () {
      expect(SrConfig.defaultEaseFactor, 2.5);
    });

    test('defaultInitialIntervalDays equals 1', () {
      expect(SrConfig.defaultInitialIntervalDays, 1);
    });

    test('defaultSecondIntervalDays equals 6', () {
      expect(SrConfig.defaultSecondIntervalDays, 6);
    });

    test('defaultMinIntervalDays equals 1', () {
      expect(SrConfig.defaultMinIntervalDays, 1);
    });

    test('defaultMaxIntervalDays equals 365', () {
      expect(SrConfig.defaultMaxIntervalDays, 365);
    });

    test('defaultDailyReviewLimit equals 0', () {
      expect(SrConfig.defaultDailyReviewLimit, 0);
    });

    test('key constants are non-empty strings', () {
      expect(SrConfig.keyMinIntervalDays, isNotEmpty);
      expect(SrConfig.keyMaxIntervalDays, isNotEmpty);
      expect(SrConfig.keyDailyReviewLimit, isNotEmpty);
      expect(SrConfig.keyMinEaseFactor, isNotEmpty);
    });
  });
}
