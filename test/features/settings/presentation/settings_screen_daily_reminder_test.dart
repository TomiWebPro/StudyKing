import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/notification_ids.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'settings_screen_test_helpers.dart';

void main() {
  final List<MethodCall> notificationCalls = [];

  setUp(() {
    notificationCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getLocalTimezone') {
          return 'Europe/Berlin';
        }
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async {
        notificationCalls.add(methodCall);
        switch (methodCall.method) {
          case 'initialize':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      null,
    );
  });

  group('SettingsScreen - Daily Reminders', () {
    testWidgets(
      'confirming the reminder time schedules the daily alarm '
      'with the shared notification id',
      (tester) async {
        await pumpWithSettings(
          tester,
          initialSettings: SettingsBox(
            dailyReminderEnabled: true,
            dailyReminderHour: 9,
            dailyReminderMinute: 0,
          ),
        );

        final reminderTimeTile = find.text('Reminder Time');
        await scrollToWidget(tester, reminderTimeTile);
        await tester.pumpAndSettle();
        await tester.tap(reminderTimeTile);
        await tester.pumpAndSettle();

        // Confirm the picker with its default (9:00) value.
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));

        final zonedCalls =
            notificationCalls.where((c) => c.method == 'zonedSchedule').toList();
        expect(zonedCalls, hasLength(1));
        final args = zonedCalls.single.arguments as Map<Object?, Object?>;
        expect(args['id'], NotificationIds.dailyReminder);
        final scheduled = DateTime.parse(args['scheduledDateTime'] as String);
        expect(scheduled.hour, 9);
        expect(scheduled.minute, 0);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'the daily reminders toggle persists the setting',
      (tester) async {
        await pumpWithSettings(
          tester,
          initialSettings: SettingsBox(
            dailyReminderEnabled: false,
            dailyReminderHour: 9,
            dailyReminderMinute: 0,
          ),
        );

        final toggle = find.text('Daily Reminders');
        await scrollToWidget(tester, toggle);
        await tester.pumpAndSettle();

        // Tap the switch itself (tapping the tile title
        // does not trigger the toggle).
        final switchFinder = find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Daily Reminders'),
          matching: find.byType(Switch),
        );
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(tester.widget<Switch>(switchFinder).value, isTrue);
        // The toggle persisted through the settings repository.
        expect(fakeRepo.settings.dailyReminderEnabled, isTrue);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });
}
