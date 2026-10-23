import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'settings_screen_test_helpers.dart';

void main() {
  group('SettingsScreen - Weekly Digest', () {
    testWidgets(
      'shows the weekly digest notification toggle in notification settings',
      (tester) async {
        await pumpWithSettings(
          tester,
          initialSettings: SettingsBox(
            studyRemindersEnabled: true,
            weeklyDigestEnabled: true,
          ),
        );

        final toggle = find.text('Weekly digest');
        await scrollToWidget(tester, toggle);
        await tester.pumpAndSettle();

        expect(toggle, findsOneWidget);
        expect(find.text('A weekly summary of your study time, accuracy, weak areas, and badges.'),
            findsOneWidget);
      },
    );

    testWidgets(
      'the weekly digest toggle persists the setting',
      (tester) async {
        await pumpWithSettings(
          tester,
          initialSettings: SettingsBox(
            studyRemindersEnabled: true,
            weeklyDigestEnabled: true,
          ),
        );

        final toggle = find.text('Weekly digest');
        await scrollToWidget(tester, toggle);
        await tester.pumpAndSettle();

        final switchFinder = find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Weekly digest'),
          matching: find.byType(Switch),
        );
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(tester.widget<Switch>(switchFinder).value, isFalse);
        // The toggle persisted through the settings repository.
        expect(fakeRepo.settings.weeklyDigestEnabled, isFalse);
      },
    );

    testWidgets(
      'weekly digest toggle is hidden while study notifications are disabled',
      (tester) async {
        await pumpWithSettings(
          tester,
          initialSettings: SettingsBox(
            studyRemindersEnabled: false,
            weeklyDigestEnabled: true,
          ),
        );

        expect(find.text('Weekly digest'), findsNothing);
      },
    );
  });
}
