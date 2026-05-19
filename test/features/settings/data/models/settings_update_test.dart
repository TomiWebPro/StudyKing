import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';

void main() {
  group('SettingsUpdate', () {
    test('creates with default null values', () {
      final update = const SettingsUpdate();
      expect(update.apiKey, isNull);
      expect(update.apiBaseUrl, isNull);
      expect(update.selectedModel, isNull);
      expect(update.themeMode, isNull);
      expect(update.fontSize, isNull);
      expect(update.studyRemindersEnabled, isNull);
      expect(update.requestTimeoutSeconds, isNull);
      expect(update.sessionDurationMinutes, isNull);
      expect(update.highContrastEnabled, isNull);
      expect(update.largeTouchTargets, isNull);
      expect(update.reduceMotion, isNull);
      expect(update.revisionRemindersEnabled, isNull);
      expect(update.lessonNotificationsEnabled, isNull);
      expect(update.overworkAlertsEnabled, isNull);
      expect(update.planAdjustmentNotificationsEnabled, isNull);
      expect(update.breakDurationSeconds, isNull);
      expect(update.dailyReminderHour, isNull);
      expect(update.dailyReminderMinute, isNull);
      expect(update.firstFocusVisit, isNull);
      expect(update.dailyReminderEnabled, isNull);
    });

    test('creates with all values set', () {
      final update = const SettingsUpdate(
        apiKey: 'test-key',
        apiBaseUrl: 'https://test.com',
        selectedModel: 'gpt-4',
        themeMode: ThemeMode.dark,
        fontSize: 18.0,
        studyRemindersEnabled: true,
        requestTimeoutSeconds: 60,
        sessionDurationMinutes: 30,
        highContrastEnabled: true,
        largeTouchTargets: true,
        reduceMotion: true,
        revisionRemindersEnabled: true,
        lessonNotificationsEnabled: true,
        overworkAlertsEnabled: true,
        planAdjustmentNotificationsEnabled: true,
        breakDurationSeconds: 300,
        dailyReminderHour: 9,
        dailyReminderMinute: 0,
        firstFocusVisit: true,
        dailyReminderEnabled: true,
      );
      expect(update.apiKey, 'test-key');
      expect(update.apiBaseUrl, 'https://test.com');
      expect(update.selectedModel, 'gpt-4');
      expect(update.themeMode, ThemeMode.dark);
      expect(update.fontSize, 18.0);
      expect(update.studyRemindersEnabled, isTrue);
      expect(update.requestTimeoutSeconds, 60);
      expect(update.sessionDurationMinutes, 30);
      expect(update.highContrastEnabled, isTrue);
      expect(update.largeTouchTargets, isTrue);
      expect(update.reduceMotion, isTrue);
      expect(update.revisionRemindersEnabled, isTrue);
      expect(update.lessonNotificationsEnabled, isTrue);
      expect(update.overworkAlertsEnabled, isTrue);
      expect(update.planAdjustmentNotificationsEnabled, isTrue);
      expect(update.breakDurationSeconds, 300);
      expect(update.dailyReminderHour, 9);
      expect(update.dailyReminderMinute, 0);
      expect(update.firstFocusVisit, isTrue);
      expect(update.dailyReminderEnabled, isTrue);
    });

    test('creates with partial values', () {
      final update = const SettingsUpdate(
        apiKey: 'partial-key',
        fontSize: 16.0,
        studyRemindersEnabled: false,
      );
      expect(update.apiKey, 'partial-key');
      expect(update.fontSize, 16.0);
      expect(update.studyRemindersEnabled, isFalse);
      expect(update.themeMode, isNull);
      expect(update.selectedModel, isNull);
    });
  });
}
