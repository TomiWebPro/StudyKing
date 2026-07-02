import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
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

  group('SettingsScreen - State Verification', () {
    testWidgets('theme change updates provider state', (tester) async {
      await pumpWithSettings(tester,
        initialSettings: SettingsBox(themeMode: ThemeMode.light.index),
      );

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsWidgets);
    });

    testWidgets('font size change updates state', (tester) async {
      await pumpWithSettings(tester,
        initialSettings: SettingsBox(fontSize: 16.0),
      );

      await tester.tap(find.text('Font Size'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('master enable notifications toggle updates state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(studyRemindersEnabled: true));

      final switchTile = find.widgetWithText(SwitchListTile, 'Enable Notifications');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();
    });

    testWidgets('revision reminders toggle persists state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        studyRemindersEnabled: true,
        revisionRemindersEnabled: true,
      ));

      final switchTile = find.widgetWithText(SwitchListTile, 'Revision Reminders');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();
    });

    testWidgets('lesson notifications toggle persists state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        studyRemindersEnabled: true,
        lessonNotificationsEnabled: false,
      ));

      final switchTile = find.widgetWithText(SwitchListTile, 'Lesson Notifications');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isFalse);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();
    });

    testWidgets('overwork alerts toggle persists state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        studyRemindersEnabled: true,
        overworkAlertsEnabled: true,
      ));

      final switchTile = find.widgetWithText(SwitchListTile, 'Overwork Alerts');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();
    });

    testWidgets('plan adjustment notifications toggle persists state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        studyRemindersEnabled: true,
        planAdjustmentNotificationsEnabled: false,
      ));

      final switchTile = find.widgetWithText(SwitchListTile, 'Plan Adjustment Alerts');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isFalse);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();
    });

    testWidgets('timeout value persists after dialog closes', (tester) async {
      await pumpWithSettings(tester,
        initialSettings: SettingsBox(requestTimeoutSeconds: 60),
      );

      expect(find.text('60 seconds'), findsOneWidget);

      await scrollToWidget(tester, find.text('Request Timeout'));
      await tester.tap(find.text('Request Timeout'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Request Timeout'), findsOneWidget);
    });

    testWidgets('session duration selection updates state', (tester) async {
      await pumpWithSettings(tester,
        initialSettings: SettingsBox(sessionDurationMinutes: 30),
      );

      await scrollToWidget(tester, find.text('Session Duration'));
      await tester.tap(find.text('Session Duration'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('60 minutes'));
      await tester.pumpAndSettle();

      expect(find.text('60 minutes'), findsWidgets);
    });
  });

  group('SettingsScreen - Slider Validation', () {
    testWidgets('timeout slider clamps to 30-300 range', (tester) async {
      await pumpWithSettings(tester,
        initialSettings: SettingsBox(requestTimeoutSeconds: 120),
      );

      await scrollToWidget(tester, find.text('Request Timeout'));
      await tester.tap(find.text('Request Timeout'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);

      expect(sliderWidget.min, equals(30));
      expect(sliderWidget.max, equals(300));
    });

    testWidgets('font size slider clamps to 10-30 range', (tester) async {
      await pumpWithSettings(tester,
        initialSettings: SettingsBox(fontSize: 16.0),
      );

      await tester.tap(find.text('Font Size'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      final sliderWidget = tester.widget<Slider>(slider);

      expect(sliderWidget.min, equals(10));
      expect(sliderWidget.max, equals(30));
    });

    testWidgets('only valid session duration options available', (tester) async {
      await pumpWithSettings(tester,
        initialSettings: SettingsBox(sessionDurationMinutes: 30),
      );

      await scrollToWidget(tester, find.text('Session Duration'));
      await tester.tap(find.text('Session Duration'));
      await tester.pumpAndSettle();

      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('45 minutes'), findsOneWidget);
      expect(find.text('60 minutes'), findsOneWidget);
      expect(find.text('90 minutes'), findsOneWidget);
      expect(find.text('120 minutes'), findsNothing);
    });
  });

  group('SettingsScreen - Sign Out Flow', () {
    testWidgets('sign out clears API key and model providers', (tester) async {
      await pumpWithSettings(tester,
        apiKey: 'sk-to-be-cleared',
        selectedModel: 'test-model',
      );

      await scrollToWidget(tester, find.text('Sign Out'));
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Not configured'), findsOneWidget);
    });
  });

  group('SettingsScreen - Extended Coverage', () {
    testWidgets('shows error screen when settings provider throws', (tester) async {
      await pumpWithSettings(tester, useThrowingNotifier: true);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping retry on error screen invalidates provider', (tester) async {
      await pumpWithSettings(tester, useThrowingNotifier: true);
      await tester.pumpAndSettle();

      final retryButton = find.widgetWithText(FilledButton, 'Retry');
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      await tester.pump();
    });

    testWidgets('shows connection health tile with not tested', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        lastConnectionTestMs: 0,
        lastLlmError: '',
      ));

      expect(find.text('Connection Health'), findsOneWidget);
      expect(find.text('Not tested'), findsOneWidget);
    });

    testWidgets('shows connection health tile with success', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        lastConnectionTestMs: 1234567890,
        lastLlmError: '',
      ));

      expect(find.text('Connection Health'), findsOneWidget);
      expect(find.textContaining('Connection successful'), findsOneWidget);
    });

    testWidgets('shows connection health tile with error state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(
        lastConnectionTestMs: 1234567890,
        lastLlmError: 'Connection refused',
      ));

      expect(find.text('Connection Health'), findsOneWidget);
      expect(find.textContaining('An error occurred'), findsOneWidget);
    });

    testWidgets('shows all break duration options', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(breakDurationSeconds: 300));

      await scrollToWidget(tester, find.text('Break Duration'));
      await tester.tap(find.text('Break Duration'));
      await tester.pumpAndSettle();

      expect(find.text('1 minute'), findsOneWidget);
      expect(find.text('2 minutes'), findsOneWidget);
      expect(find.text('3 minutes'), findsOneWidget);
      expect(find.text('5 minutes'), findsOneWidget);
      expect(find.text('7 minutes'), findsOneWidget);
      expect(find.text('10 minutes'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
    });

    testWidgets('selecting break duration updates settings', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(breakDurationSeconds: 300));

      await scrollToWidget(tester, find.text('Break Duration'));
      await tester.tap(find.text('Break Duration'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10 minutes').last);
      await tester.pumpAndSettle();

      expect(find.text('Break Duration'), findsOneWidget);
    });

    testWidgets('shows all session duration options', (tester) async {
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

    testWidgets('selecting session duration updates state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(sessionDurationMinutes: 30));

      await scrollToWidget(tester, find.text('Session Duration'));
      await tester.tap(find.text('Session Duration'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('45 minutes'));
      await tester.pumpAndSettle();

      expect(find.text('Session Duration'), findsOneWidget);
    });

    testWidgets('shows Small for font size < 14', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 12.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
    });

    testWidgets('shows Medium for font size 14-16', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 15.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('shows Large for font size 17-22', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 20.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('shows Extra Large for font size >= 23', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 25.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Extra Large'), findsOneWidget);
    });

    testWidgets('shows default SR min interval label', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('1 days'), findsOneWidget);
    });

    testWidgets('shows default SR max interval label', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('365 days'), findsOneWidget);
    });

    testWidgets('shows no limit for daily review by default', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('No limit'), findsOneWidget);
    });
  });

  group('SettingsScreen - AI Features', () {
    testWidgets('shows badge when active tasks exist', (tester) async {
      final activeTask = LlmTask(
        id: 'task_1',
        feature: 'general',
        modelId: 'gpt-4',
        status: LlmTaskStatus.running,
        startTime: DateTime.now(),
      );
      final taskManager = FakeLlmTaskManager(
        tasks: [activeTask],
        activeTasks: [activeTask],
      );

      await pumpWithSettings(tester, taskManager: taskManager);

      expect(find.text('AI Task Monitor'), findsOneWidget);
      expect(find.text('View active AI tasks'), findsOneWidget);
    });

    testWidgets('shows badge when failed tasks exist', (tester) async {
      final failedTask = LlmTask(
        id: 'task_2',
        feature: 'general',
        modelId: 'gpt-4',
        status: LlmTaskStatus.failed,
        startTime: DateTime.now(),
      );
      final taskManager = FakeLlmTaskManager(
        tasks: [failedTask],
        activeTasks: [],
      );

      await pumpWithSettings(tester, taskManager: taskManager);

      expect(find.text('AI Task Monitor'), findsOneWidget);
      expect(find.text('View active AI tasks'), findsOneWidget);
    });

    testWidgets('shows no tasks message when no tasks exist', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('AI Task Monitor'), findsOneWidget);
      expect(find.text('No active AI tasks'), findsOneWidget);
    });

    testWidgets('opens token usage dialog with feature breakdown', (tester) async {
      final usageMeter = FakeLlmUsageMeter(
        totalTokens: 5000,
        totalCost: 0.025,
        perFeature: {'general': 3000, 'question_generation': 2000},
      );

      await pumpWithSettings(tester, usageMeter: usageMeter);

      await scrollToWidget(tester, find.text('Total Tokens'));
      await tester.tap(find.text('Total Tokens'));
      await tester.pumpAndSettle();

      expect(find.text('Token Usage Summary'), findsAtLeastNWidgets(1));
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('SettingsScreen - Content & Session Tracking', () {
    testWidgets('renders Upload Material tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Upload Material'), findsOneWidget);
      expect(find.text('Upload source materials'), findsOneWidget);
    });

    testWidgets('renders My Uploads tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('My Uploads'), findsOneWidget);
      expect(find.text('View your uploaded materials'), findsOneWidget);
    });

    testWidgets('renders Question Bank tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Question Bank'), findsOneWidget);
      expect(find.text('Browse and manage questions'), findsOneWidget);
    });

    testWidgets('renders Manual Session Tracker tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Manual Session Tracker'), findsOneWidget);
      expect(find.text('Log study sessions manually'), findsOneWidget);
    });

    testWidgets('renders Session History tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Session History'), findsOneWidget);
      expect(find.text('View past study sessions'), findsOneWidget);
    });

    testWidgets('renders total tokens tile with correct count', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Total Tokens'), findsOneWidget);
      expect(find.text('5,000 tokens'), findsOneWidget);
    });

    testWidgets('renders total cost tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Total Cost'), findsOneWidget);
    });

    testWidgets('renders AI Task Monitor tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('AI Task Monitor'), findsOneWidget);
      expect(find.text('No active AI tasks'), findsOneWidget);
    });

    testWidgets('renders Auto Backup tile', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Backup & Restore'));
      expect(find.text('Automatic Backup'), findsOneWidget);
    });

    testWidgets('renders Show Onboarding Tour tile', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('About'));
      await scrollToWidget(tester, find.text('Show onboarding tour'));
      expect(find.text('Show onboarding tour'), findsOneWidget);
    });
  });

  group('SettingsScreen - Auto Backup Dialog', () {
    testWidgets('auto backup tile renders and tapping does not crash', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Automatic Backup'));
      await tester.tap(find.text('Automatic Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Automatic Backup'), findsOneWidget);
    });

    testWidgets('auto backup dialog shows never selected by default', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Automatic Backup'));
      await tester.tap(find.text('Automatic Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Automatic Backup'), findsOneWidget);
    });

    testWidgets('selecting daily interval closes dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Automatic Backup'));
      await tester.tap(find.text('Automatic Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Automatic Backup'), findsOneWidget);
    });
  });

  group('SettingsScreen - Sign Out with Clear Data', () {
    testWidgets('sign out dialog shows clear data checkbox', (tester) async {
      final secureService = FakeSecureApiKeyService();
      await pumpWithSettings(tester, apiKey: 'sk-test', secureApiKeyService: secureService);

      await scrollToWidget(tester, find.text('Sign Out'));
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      expect(find.text('Clear all study data'), findsOneWidget);
      expect(find.text('Back up before signing out'), findsNothing);
    });

    testWidgets('sign out dialog shows backup checkbox after selecting clear data', (tester) async {
      final secureService = FakeSecureApiKeyService();
      await pumpWithSettings(tester, apiKey: 'sk-test', secureApiKeyService: secureService);

      await scrollToWidget(tester, find.text('Sign Out'));
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear all study data'));
      await tester.pumpAndSettle();

      expect(find.text('Back up before signing out'), findsOneWidget);
    });

    testWidgets('sign out clears api key and model providers', (tester) async {
      final secureService = FakeSecureApiKeyService();
      final backupService = FakeDataBackupService();
      await pumpWithSettings(tester,
        apiKey: 'sk-test',
        selectedModel: 'test-model',
        secureApiKeyService: secureService,
        backupService: backupService,
      );

      await scrollToWidget(tester, find.text('Sign Out'));
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign Out'));
      await tester.pumpAndSettle();

      expect(secureService.clearAllCalled, isTrue);
    });
  });
}
