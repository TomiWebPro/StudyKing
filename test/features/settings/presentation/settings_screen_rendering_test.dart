import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'settings_screen_test_helpers.dart';
import '../../../helpers/navigator_observer_helper.dart';

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

  group('SettingsScreen - Rendering', () {
    testWidgets('renders all sections with correct titles', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('AI Configuration'), findsOneWidget);
      expect(find.text('Study Preferences'), findsOneWidget);
      expect(find.text('Study Analytics'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('shows user management tile', (tester) async {
      await pumpWithSettings(tester);

      final currentUserTile = find.widgetWithText(ListTile, 'Current User');
      expect(currentUserTile, findsOneWidget);
      expect(find.text('Manage your profile'), findsOneWidget);
    });

    testWidgets('shows Quick Guide tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.widgetWithText(ListTile, 'Quick Guide'), findsOneWidget);
      expect(find.text('AI-powered study assistant'), findsOneWidget);
    });

    testWidgets('shows theme tile with correct label', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(themeMode: 0));

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('shows font size tile with correct label', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 13.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
    });

    testWidgets('font size label shows Medium for 14-16 range', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 15.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('font size label shows Large for 17-22 range', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 18.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('font size label shows Extra Large for >= 23', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(fontSize: 24.0));

      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Extra Large'), findsOneWidget);
    });

    testWidgets('shows API key status as Not configured when empty', (tester) async {
      await pumpWithSettings(tester, apiKey: '');

      expect(find.text('API Keys'), findsOneWidget);
      expect(find.text('Not configured'), findsOneWidget);
    });

    testWidgets('shows API key status as Configured when set', (tester) async {
      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      expect(find.text('API Keys'), findsOneWidget);
      expect(find.text('Configured'), findsOneWidget);
    });

    testWidgets('shows request timeout tile', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(requestTimeoutSeconds: 60));

      expect(find.text('Request Timeout'), findsOneWidget);
      expect(find.text('60 seconds'), findsOneWidget);
    });

    testWidgets('shows session duration tile', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(sessionDurationMinutes: 45));

      expect(find.text('Session Duration'), findsOneWidget);
      expect(find.text('45 minutes'), findsOneWidget);
    });

    testWidgets('shows notification toggle switches when enabled', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(studyRemindersEnabled: true));

      expect(find.widgetWithText(SwitchListTile, 'Enable Notifications'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Revision Reminders'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Lesson Notifications'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Overwork Alerts'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Plan Adjustment Alerts'), findsOneWidget);
    });

    testWidgets('hides notification sub-toggles when master is off', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(studyRemindersEnabled: false));

      expect(find.widgetWithText(SwitchListTile, 'Enable Notifications'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Revision Reminders'), findsNothing);
      expect(find.widgetWithText(SwitchListTile, 'Plan Adjustment Alerts'), findsNothing);
    });

    testWidgets('shows total study sessions tile', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(totalSessionCount: 10));

      expect(find.text('Total Study Sessions'), findsOneWidget);
      expect(find.text('10 sessions'), findsOneWidget);
    });

    testWidgets('shows total study time tile', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(totalStudyTimeMs: 7200000));

      expect(find.text('Total Study Time'), findsOneWidget);
      expect(find.text('2h 0m 0s'), findsOneWidget);
    });

    testWidgets('shows About StudyKing tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.widgetWithText(ListTile, 'About StudyKing'), findsOneWidget);
      expect(find.text('Version 0.1.0'), findsOneWidget);
    });

    testWidgets('shows Sign Out tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Sign Out'), findsWidgets);
    });

    testWidgets('AI model label shows default text when empty', (tester) async {
      await pumpWithSettings(tester, selectedModel: '');

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Select a model from API'), findsOneWidget);
    });

    testWidgets('AI model label parses model path correctly', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(selectedModel: 'anthropic/claude-3-haiku'));

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Claude 3 haiku'), findsOneWidget);
    });

    testWidgets('AI model label handles single word model', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(selectedModel: 'gpt-4'));

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Gpt 4'), findsOneWidget);
    });

    testWidgets('AI model label handles underscores', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(selectedModel: 'openai/gpt_4_turbo'));

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Gpt 4 turbo'), findsOneWidget);
    });

    testWidgets('AI model label handles model with trailing slash', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(selectedModel: 'provider/'));

      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Provider/'), findsOneWidget);
    });
  });

  group('SettingsScreen - Accessibility Switches', () {
    testWidgets('renders high contrast accessibility switch', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(highContrastEnabled: false));

      expect(find.widgetWithText(SwitchListTile, 'High Contrast Mode'), findsOneWidget);
    });

    testWidgets('renders large touch targets accessibility switch', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(largeTouchTargets: false));

      expect(find.widgetWithText(SwitchListTile, 'Large Touch Targets'), findsOneWidget);
    });

    testWidgets('renders reduce motion accessibility switch', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(reduceMotion: false));

      expect(find.widgetWithText(SwitchListTile, 'Reduce Motion'), findsOneWidget);
    });

    testWidgets('high contrast switch reflects state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(highContrastEnabled: true));

      final switchTile = find.widgetWithText(SwitchListTile, 'High Contrast Mode');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('large touch targets switch reflects state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(largeTouchTargets: true));

      final switchTile = find.widgetWithText(SwitchListTile, 'Large Touch Targets');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('reduce motion switch reflects state', (tester) async {
      await pumpWithSettings(tester, initialSettings: SettingsBox(reduceMotion: true));

      final switchTile = find.widgetWithText(SwitchListTile, 'Reduce Motion');
      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);
    });
  });

  group('SettingsScreen - Focus Mode', () {
    testWidgets('renders Focus Time tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Focus Time'), findsOneWidget);
      expect(find.text('Start a focused study session'), findsOneWidget);
    });

    testWidgets('renders Daily Study Cap tile', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Daily Study Cap'), findsOneWidget);
    });
  });

  group('SettingsScreen - Section Titles', () {
    testWidgets('renders Accessibility section', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Accessibility'), findsOneWidget);
    });

    testWidgets('renders Notification Preferences section', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Notification Preferences'), findsOneWidget);
    });

    testWidgets('renders Study Preferences section', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Study Preferences'), findsOneWidget);
    });

    testWidgets('renders Focus Mode section', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Focus Mode'), findsOneWidget);
    });

    testWidgets('renders Study Analytics section', (tester) async {
      await pumpWithSettings(tester);

      expect(find.text('Study Analytics'), findsOneWidget);
    });

    testWidgets('renders About section', (tester) async {
      await pumpWithSettings(tester);

      scrollToWidget(tester, find.text('About'));
      expect(find.text('About'), findsOneWidget);
    });
  });

  group('SettingsScreen - Navigation', () {
    testWidgets('tapping Current User navigates to profile route', (tester) async {
      final navigatorObserver = TestNavigatorObserver();
      await pumpWithSettings(tester, navigatorObserver: navigatorObserver);

      await tester.tap(find.widgetWithText(ListTile, 'Current User'));
      await tester.pumpAndSettle();

      expect(navigatorObserver.pushedRoutes, isNotEmpty);
    });
  });

  group('SettingsScreen - Keyboard accessibility', () {
    testWidgets('renders FocusTraversalGroup wrapping the settings list', (tester) async {
      await pumpWithSettings(tester);

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('renders interactive tiles that are keyboard-reachable', (tester) async {
      await pumpWithSettings(tester);

      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(1));
    });
  });
}
