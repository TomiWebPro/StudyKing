import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    test('getDailyCapMinutes returns 0 when Hive is not open', () {
      // Hive is not initialized in unit tests, so it gracefully returns default
      expect(SettingsService.getDailyCapMinutes(), 0);
    });

    test('getMentorCheckinFrequency returns 1 when Hive is not open', () {
      expect(SettingsService.getMentorCheckinFrequency(), 1);
    });

    test('getScheduleDurationMinutes returns default when Hive is not open', () {
      final result = SettingsService.getScheduleDurationMinutes();
      expect(result, greaterThan(0));
      // defaultSessionDurationMinutes is typically 60
      expect(result, 60);
    });

    test('getTeachingDurationMinutes returns 45 when Hive is not open', () {
      expect(SettingsService.getTeachingDurationMinutes(), 45);
    });
  });
}
