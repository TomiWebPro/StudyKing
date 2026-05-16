import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_runtime_config.dart';

void main() {
  group('bottomSheetShape', () {
    test('has correct border radius', () {
      final border = bottomSheetShape;
      expect(border, isA<RoundedRectangleBorder>());
      expect(border.borderRadius, isA<BorderRadius>());
      final radius = border.borderRadius as BorderRadius;
      expect(radius.topLeft.x, equals(20));
      expect(radius.topRight.x, equals(20));
    });
  });

  group('UiConfig', () {
    test('has expected default values', () {
      expect(UiConfig.defaultThemeMode, ThemeMode.system);
      expect(UiConfig.defaultNotificationsEnabled, isTrue);
      expect(UiConfig.notificationReminderLeadTime, const Duration(minutes: 10));
      expect(UiConfig.notificationChannelId, 'study_reminders');
      expect(UiConfig.notificationChannelName, 'Study Reminders');
    });
  });
}
