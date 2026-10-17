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

    group('wellbeing reminders', () {
      test('returns empty list when Hive is not open', () {
        expect(SettingsService.getWellbeingReminders(), isEmpty);
      });

      test('saveWellbeingReminder returns false when Hive is not open', () async {
        final result = await SettingsService.saveWellbeingReminder({
          'reminderType': 'bedtime',
          'time': '22:00',
          'enabled': true,
        });
        expect(result, isFalse);
      });

      test('saves and retrieves a wellbeing reminder', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.delete('wellbeing_reminders');

        final saved = await SettingsService.saveWellbeingReminder({
          'reminderType': 'bedtime',
          'time': '22:00',
          'enabled': true,
        });
        expect(saved, isTrue);

        final reminders = SettingsService.getWellbeingReminders();
        expect(reminders, hasLength(1));
        expect(reminders.first['reminderType'], 'bedtime');
        expect(reminders.first['time'], '22:00');
        expect(reminders.first['enabled'], isTrue);

        await box.deleteFromDisk();
      });

      test('replaces an existing reminder of the same type', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.delete('wellbeing_reminders');

        await SettingsService.saveWellbeingReminder({
          'reminderType': 'bedtime',
          'time': '22:00',
          'enabled': true,
        });
        await SettingsService.saveWellbeingReminder({
          'reminderType': 'bedtime',
          'time': '23:00',
          'enabled': false,
        });

        final reminders = SettingsService.getWellbeingReminders();
        expect(reminders, hasLength(1));
        expect(reminders.first['time'], '23:00');
        expect(reminders.first['enabled'], isFalse);

        await box.deleteFromDisk();
      });

      test('stores multiple reminders of different types', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.delete('wellbeing_reminders');

        await SettingsService.saveWellbeingReminder({
          'reminderType': 'bedtime',
          'time': '22:00',
          'enabled': true,
        });
        await SettingsService.saveWellbeingReminder({
          'reminderType': 'break',
          'time': '15:30',
          'enabled': true,
        });
        await SettingsService.saveWellbeingReminder({
          'reminderType': 'pacing',
          'time': '00:30',
          'enabled': true,
        });

        final reminders = SettingsService.getWellbeingReminders();
        expect(reminders, hasLength(3));
        final types = reminders.map((r) => r['reminderType']).toSet();
        expect(types, containsAll(['bedtime', 'break', 'pacing']));

        await box.deleteFromDisk();
      });
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
