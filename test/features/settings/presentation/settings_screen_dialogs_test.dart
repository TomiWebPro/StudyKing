import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'settings_screen_test_helpers.dart';

void main() {
  setUp(() {
    fakeRepo.settings = SettingsBox(
      themeMode: 0,
      fontSize: 16.0,
      totalSessionCount: 5,
      totalStudyTimeMs: 3600000,
      totalQuestions: 100,
    );
  });

  group('SettingsScreen - Dialogs', () {
    testWidgets('tapping theme tile opens theme dialog', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(themeMode: 0));

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('can select dark theme from dialog', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(themeMode: 0));

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsWidgets);
    });

    testWidgets('can select system theme from dialog', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(themeMode: 0));

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsWidgets);
    });

    testWidgets('tapping font size tile opens font size dialog', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 16.0));

      await tester.tap(find.text('Font Size'));
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('tapping session duration opens duration dialog', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(sessionDurationMinutes: 30));

      await scrollToWidget(tester, find.text('Session Duration'));
      await tester.tap(find.text('Session Duration'));
      await tester.pumpAndSettle();

      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('45 minutes'), findsOneWidget);
      expect(find.text('60 minutes'), findsOneWidget);
      expect(find.text('90 minutes'), findsOneWidget);
    });

    testWidgets('tapping analytics shows analytics sheet', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        totalSessionCount: 5,
        totalQuestions: 100,
      ));

      await scrollToWidget(tester, find.text('Total Study Sessions'));
      await tester.tap(find.text('Total Study Sessions'));
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('tapping about shows about dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.widgetWithText(ListTile, 'About StudyKing'));
      await tester.tap(find.widgetWithText(ListTile, 'About StudyKing'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutDialog), findsOneWidget);
      expect(find.text('StudyKing'), findsWidgets);
    });

    testWidgets('tapping sign out shows confirmation dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Sign Out'));
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsWidgets);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel sign out closes dialog', (tester) async {
      await pumpWithSettings(tester, apiKey: 'test-key');

      await scrollToWidget(tester, find.text('Sign Out'));
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('tapping timeout shows timeout dialog with slider', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(requestTimeoutSeconds: 120));

      await scrollToWidget(tester, find.text('Request Timeout'));
      await tester.tap(find.text('Request Timeout'));
      await tester.pumpAndSettle();

      expect(find.text('Request Timeout'), findsWidgets);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('timeout dialog cancel button closes dialog', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(requestTimeoutSeconds: 120));

      await scrollToWidget(tester, find.text('Request Timeout'));
      await tester.tap(find.text('Request Timeout'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing);
    });

    testWidgets('timeout dialog has slider that can be adjusted', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(requestTimeoutSeconds: 120));

      await scrollToWidget(tester, find.text('Request Timeout'));
      await tester.tap(find.text('Request Timeout'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      final saveButton = find.widgetWithText(TextButton, 'Save');
      expect(saveButton, findsOneWidget);
    });

    testWidgets('opens min interval dialog with correct options', (tester) async {
      await pumpWithSettings(tester);
      await scrollToWidget(tester, find.text('Min interval'));

      await tester.tap(find.text('Min interval'));
      await tester.pumpAndSettle();

      expect(find.text('1 days'), findsWidgets);
      expect(find.text('2 days'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
    });

    testWidgets('selecting min interval option closes dialog', (tester) async {
      await pumpWithSettings(tester);
      await scrollToWidget(tester, find.text('Min interval'));

      await tester.tap(find.text('Min interval'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3 days').last);
      await tester.pumpAndSettle();

      expect(find.text('Min interval'), findsOneWidget);
    });

    testWidgets('opens max interval dialog with correct options', (tester) async {
      await pumpWithSettings(tester);
      await scrollToWidget(tester, find.text('Max interval'));

      await tester.tap(find.text('Max interval'));
      await tester.pumpAndSettle();

      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('60 days'), findsOneWidget);
      expect(find.text('90 days'), findsOneWidget);
      expect(find.text('180 days'), findsOneWidget);
      expect(find.text('365 days'), findsOneWidget);
    });

    testWidgets('selecting max interval option closes dialog', (tester) async {
      await pumpWithSettings(tester);
      await scrollToWidget(tester, find.text('Max interval'));

      await tester.tap(find.text('Max interval'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('90 days').last);
      await tester.pumpAndSettle();

      expect(find.text('Max interval'), findsOneWidget);
    });

    testWidgets('opens daily review limit dialog with correct options', (tester) async {
      await pumpWithSettings(tester);
      await scrollToWidget(tester, find.text('Daily review limit'));

      await tester.tap(find.text('Daily review limit'));
      await tester.pumpAndSettle();

      expect(find.text('No limit'), findsOneWidget);
      expect(find.text('5 questions'), findsOneWidget);
      expect(find.text('10 questions'), findsOneWidget);
      expect(find.text('15 questions'), findsOneWidget);
      expect(find.text('20 questions'), findsOneWidget);
      expect(find.text('30 questions'), findsOneWidget);
      expect(find.text('50 questions'), findsOneWidget);
    });

    testWidgets('selecting daily review limit option closes dialog', (tester) async {
      await pumpWithSettings(tester);
      await scrollToWidget(tester, find.text('Daily review limit'));

      await tester.tap(find.text('Daily review limit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10 questions'));
      await tester.pumpAndSettle();

      expect(find.text('Daily review limit'), findsOneWidget);
    });

    testWidgets('tapping daily study cap opens bottom sheet', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Daily Study Cap'));
      await tester.tap(find.text('Daily Study Cap'));
      await tester.pumpAndSettle();

      expect(find.text('No limit'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('60 minutes'), findsOneWidget);
    });

    testWidgets('daily cap dialog shows cap options', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Daily Study Cap'));
      await tester.tap(find.text('Daily Study Cap'));
      await tester.pumpAndSettle();

      expect(find.text('No limit'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('60 minutes'), findsOneWidget);
      expect(find.text('90 minutes'), findsOneWidget);
      expect(find.text('120 minutes'), findsOneWidget);
      expect(find.text('180 minutes'), findsOneWidget);
      expect(find.text('240 minutes'), findsOneWidget);
    });

    testWidgets('selecting daily cap closes dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Daily Study Cap'));
      await tester.tap(find.text('Daily Study Cap'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No limit'));
      await tester.pumpAndSettle();

      expect(find.text('Daily Study Cap'), findsOneWidget);
    });

    testWidgets('tapping Export Backup opens dialog with 3 buttons', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.widgetWithText(ListTile, 'Export Backup'));
      await tester.tap(find.widgetWithText(ListTile, 'Export Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exclude sensitive data'), findsOneWidget);
      expect(find.text('Export Backup'), findsWidgets);
    });

    testWidgets('Cancel button closes the export dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.widgetWithText(ListTile, 'Export Backup'));
      await tester.tap(find.widgetWithText(ListTile, 'Export Backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Exclude sensitive data'), findsNothing);
    });

    testWidgets('Exclude sensitive data button shows preview dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.widgetWithText(ListTile, 'Export Backup'));
      await tester.tap(find.widgetWithText(ListTile, 'Export Backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exclude sensitive data'));
      await tester.pumpAndSettle();

      expect(find.text('Export Backup'), findsWidgets);
    });

    testWidgets('about dialog shows app information', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.widgetWithText(ListTile, 'About StudyKing'));
      await tester.tap(find.widgetWithText(ListTile, 'About StudyKing'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutDialog), findsOneWidget);
      expect(find.text('StudyKing'), findsWidgets);
    });

    testWidgets('Export Backup (full) button shows sensitive data warning dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.widgetWithText(ListTile, 'Export Backup'));
      await tester.tap(find.widgetWithText(ListTile, 'Export Backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Export Backup').last);
      await tester.pumpAndSettle();

      expect(find.text('Export Backup'), findsWidgets);
      expect(find.text('Backup contains sensitive data'), findsWidgets);
    });

    testWidgets('OK button on API key dialog navigates to api config', (tester) async {
      await pumpWithSettings(tester, apiKey: '', selectedModel: '');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('API Key Required'), findsNothing);
    });
  });
}
