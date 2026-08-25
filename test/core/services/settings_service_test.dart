import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/settings_service.dart';

List<String> _capturedLogs = [];
void _installLogCapture() {
  _capturedLogs.clear();
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) _capturedLogs.add(message);
  };
}

void _uninstallLogCapture() {
  debugPrint = debugPrintThrottled;
}

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('settings_test_').path);
  });

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
      // defaultSessionDurationMinutes is 30
      expect(result, 30);
    });

    test('getTeachingDurationMinutes returns 45 when Hive is not open', () {
      expect(SettingsService.getTeachingDurationMinutes(), 45);
    });

    group('failure logging and graceful defaults', () {
      test('logs and defaults when stored values fail to cast', () async {
        _installLogCapture();
        addTearDown(_uninstallLogCapture);

        final cases = <(String, int Function(), int, String)>[
          ('dailyCapMinutes', SettingsService.getDailyCapMinutes, 0, 'getDailyCapMinutes'),
          ('mentorCheckinFrequencyDays', SettingsService.getMentorCheckinFrequency, 1, 'getMentorCheckinFrequency'),
          ('defaultScheduleDuration', SettingsService.getScheduleDurationMinutes, 30, 'getScheduleDurationMinutes'),
          ('defaultTeachingDuration', SettingsService.getTeachingDurationMinutes, 45, 'getTeachingDurationMinutes'),
        ];

        for (final (key, getter, expected, logSubstring) in cases) {
          _capturedLogs.clear();
          final box = await Hive.openBox(HiveBoxNames.settings);
          await box.put(key, 'not-an-int');

          expect(getter(), expected, reason: 'expected default for $key');

          expect(
            _capturedLogs.any((l) => l.contains('[W]') && l.contains(logSubstring)),
            isTrue,
            reason: 'expected warning log containing $logSubstring',
          );

          await box.deleteFromDisk();
        }
      });
    });
  });
}
