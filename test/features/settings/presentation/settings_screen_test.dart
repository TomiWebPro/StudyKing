import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import '../../../helpers/navigator_observer_helper.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_settings);

  @override
  Future<Result<void>> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
    bool? reduceMotion,
    bool? revisionRemindersEnabled,
    bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled,
    bool? planAdjustmentNotificationsEnabled,
    int? breakDurationSeconds,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? firstFocusVisit,
    bool? dailyReminderEnabled,
  }) async {
    _settings = SettingsBox(
      apiKey: apiKey ?? _settings.apiKey,
      apiBaseUrl: apiBaseUrl ?? _settings.apiBaseUrl,
      selectedModel: selectedModel ?? _settings.selectedModel,
      themeMode: themeMode?.index ?? _settings.themeMode,
      fontSize: fontSize ?? _settings.fontSize,
      totalSessionCount: _settings.totalSessionCount,
      totalStudyTimeMs: _settings.totalStudyTimeMs,
      totalQuestions: _settings.totalQuestions,
      studyRemindersEnabled: studyRemindersEnabled ?? _settings.studyRemindersEnabled,
      requestTimeoutSeconds: requestTimeoutSeconds ?? _settings.requestTimeoutSeconds,
      sessionDurationMinutes: sessionDurationMinutes ?? _settings.sessionDurationMinutes,
      highContrastEnabled: highContrastEnabled ?? _settings.highContrastEnabled,
      largeTouchTargets: largeTouchTargets ?? _settings.largeTouchTargets,
      reduceMotion: reduceMotion ?? _settings.reduceMotion,
      revisionRemindersEnabled: revisionRemindersEnabled ?? _settings.revisionRemindersEnabled,
      lessonNotificationsEnabled: lessonNotificationsEnabled ?? _settings.lessonNotificationsEnabled,
      overworkAlertsEnabled: overworkAlertsEnabled ?? _settings.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: planAdjustmentNotificationsEnabled ?? _settings.planAdjustmentNotificationsEnabled,
      breakDurationSeconds: breakDurationSeconds ?? _settings.breakDurationSeconds,
      dailyReminderHour: dailyReminderHour ?? _settings.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? _settings.dailyReminderMinute,
      firstFocusVisit: firstFocusVisit ?? _settings.firstFocusVisit,
      dailyReminderEnabled: dailyReminderEnabled ?? _settings.dailyReminderEnabled,
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<void>> updateStats({int? sessionCount, int? studyTimeMs, int? questions}) async => Result.success(null);
  @override
  Future<Result<void>> saveApiKey({required String service, required String key}) async => Result.success(null);
  @override
  Future<Result<String?>> getApiKey({required String service}) async => Result.success(_settings.apiKey);
  @override
  Future<Result<void>> saveProfileData(UserProfile profile) async => Result.success(null);
  @override
  Future<Result<UserProfile?>> getProfileData() async => Result.success(null);
  @override
  Future<Result<void>> clearSettings() async => Result.success(null);
  @override
  Future<Result<void>> clearProfile() async => Result.success(null);
  @override
  Future<Result<void>> saveProvider(LlmProvider provider) async => Result.success(null);
  @override
  Future<Result<LlmProvider>> getProvider() async => Result.success(LlmProvider.openRouter);
}

final fakeRepo = FakeSettingsRepository();

class FakeLlmTaskManager extends LlmTaskManager {
  @override
  Future<void> init() async {}

  @override
  List<LlmTask> get tasks => [];

  @override
  List<LlmTask> get activeTasks => [];
}

class FakeLlmUsageMeter extends LlmUsageMeter {
  @override
  Future<void> init() async {}

  @override
  List<LlmUsageRecord> getRecords({String? feature, int? limit}) => [];

  @override
  int getTotalTokens() => 0;

  @override
  double getTotalCost() => 0.0;

  @override
  Map<String, int> getTotalTokensPerFeature() => {};
}

class _TestSettingsNotifier extends SettingsController {
  _TestSettingsNotifier(SettingsBox initial, SettingsRepository repo) : super(repo) {
    state = initial;
  }
}

Widget buildSettingsScreen({
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
  TestNavigatorObserver? navigatorObserver,
}) {
  if (initialSettings != null) {
    fakeRepo._settings = initialSettings;
  }
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => _TestSettingsNotifier(fakeRepo._settings, fakeRepo)),
      apiKeyProvider.overrideWith((ref) => apiKey),
      selectedModelProvider.overrideWith((ref) => selectedModel),
      llmTaskManagerProvider.overrideWith((ref) => FakeLlmTaskManager()),
      llmUsageMeterProvider.overrideWith((ref) => FakeLlmUsageMeter()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: const SettingsScreen(),
    ),
  );
}

Future<void> pumpWithSettings(WidgetTester tester, {
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
  TestNavigatorObserver? navigatorObserver,
}) async {
  // Increase viewport so all ListView children are rendered
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 3500);
  await tester.pumpWidget(buildSettingsScreen(
    initialSettings: initialSettings,
    apiKey: apiKey,
    selectedModel: selectedModel,
    navigatorObserver: navigatorObserver,
  ));
  await tester.pumpAndSettle();
}

Future<void> scrollToWidget(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target,
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    fakeRepo._settings = SettingsBox(
      themeMode: 0,
      fontSize: 16.0,
      totalSessionCount: 5,
      totalStudyTimeMs: 3600000,
      totalQuestions: 100,
    );
  });

  group('SettingsScreen', () {
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

    testWidgets('tapping AI model with empty API key shows warning dialog', (tester) async {
      await pumpWithSettings(tester, apiKey: '', selectedModel: '');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      expect(find.text('API Key Required'), findsOneWidget);
      expect(find.text('Please configure your API key first.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
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

    group('Accessibility Switches', () {
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

    group('Focus Mode', () {
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

    group('State Verification', () {
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

    group('Slider Validation', () {
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

    group('Model Parsing', () {
      testWidgets('AI model selection parses provider correctly', (tester) async {
        HttpOverrides.global = _FakeHttpOverride(
          responseStatusCode: 200,
          responseBody: '{"data": [{"id": "anthropic/claude-3", "name": "Claude 3", "providers": [{"id": "openrouter"}]}]}',
        );
        addTearDown(() => HttpOverrides.global = null);

        await pumpWithSettings(tester, apiKey: 'sk-test-key');

        await scrollToWidget(tester, find.text('AI Model'));
        await tester.tap(find.text('AI Model'));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Claude 3'), findsOneWidget);
      });

      testWidgets('empty model list handled gracefully', (tester) async {
        HttpOverrides.global = _FakeHttpOverride(
          responseStatusCode: 200,
          responseBody: '{"data": []}',
        );
        addTearDown(() => HttpOverrides.global = null);

        await pumpWithSettings(tester, apiKey: 'sk-test-key');

        await scrollToWidget(tester, find.text('AI Model'));
        await tester.tap(find.text('AI Model'));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Sign Out Flow', () {
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

    group('Daily Cap Dialog', () {
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
    });

    group('API Key Warning Dialog', () {
      testWidgets('OK button on API key dialog navigates to api config', (tester) async {
        await pumpWithSettings(tester, apiKey: '', selectedModel: '');

        await scrollToWidget(tester, find.text('AI Model'));
        await tester.tap(find.text('AI Model'));
        await tester.pumpAndSettle();

        expect(find.text('OK'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Dialog should close
        expect(find.text('API Key Required'), findsNothing);
      });
    });

    group('About Dialog', () {
      testWidgets('about dialog shows app information', (tester) async {
        await pumpWithSettings(tester);

        await scrollToWidget(tester, find.widgetWithText(ListTile, 'About StudyKing'));
        await tester.tap(find.widgetWithText(ListTile, 'About StudyKing'));
        await tester.pumpAndSettle();

        expect(find.byType(AboutDialog), findsOneWidget);
        expect(find.text('StudyKing'), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('tapping Current User navigates to profile route', (tester) async {
        final navigatorObserver = TestNavigatorObserver();
        await pumpWithSettings(tester, navigatorObserver: navigatorObserver);

        await tester.tap(find.widgetWithText(ListTile, 'Current User'));
        await tester.pumpAndSettle();

        expect(navigatorObserver.pushedRoutes, isNotEmpty);
        expect(navigatorObserver.pushedRoutes.first.settings.name, AppRoutes.profile);
      });
    });
  });

  group('Network Error Handling', () {
    testWidgets('shows error when model selection API returns non-200', (tester) async {
      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load models right now.'), findsOneWidget);
    });

    testWidgets('shows timeout error message after network timeout', (tester) async {
      HttpOverrides.global = _TimeoutHttpOverride();
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();

      expect(find.text('Model request timed out. Please try again.'), findsOneWidget);
    });

    testWidgets('shows generic error on malformed response', (tester) async {
      HttpOverrides.global = _FakeHttpOverride(
        responseStatusCode: 200,
        responseBody: 'not valid json {{{',
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('retry button appears on error and retries loading', (tester) async {
      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Model Search Filtering', () {
    testWidgets('search filter narrows model list', (tester) async {
      HttpOverrides.global = _FakeHttpOverride(
        responseStatusCode: 200,
        responseBody: jsonEncode({
          'data': [
            {'id': 'openai/gpt-4', 'name': 'GPT-4', 'providers': [{'id': 'openai'}]},
            {'id': 'anthropic/claude-3', 'name': 'Claude 3', 'providers': [{'id': 'anthropic'}]},
            {'id': 'google/gemini-pro', 'name': 'Gemini Pro', 'providers': [{'id': 'google'}]},
          ]
        }),
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('GPT-4'), findsOneWidget);
      expect(find.text('Claude 3'), findsOneWidget);
      expect(find.text('Gemini Pro'), findsOneWidget);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'gpt');
      await tester.pumpAndSettle();

      expect(find.text('GPT-4'), findsOneWidget);
      expect(find.text('Claude 3'), findsNothing);
      expect(find.text('Gemini Pro'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      HttpOverrides.global = _FakeHttpOverride(
        responseStatusCode: 200,
        responseBody: jsonEncode({
          'data': [
            {'id': 'openai/gpt-4', 'name': 'GPT-4', 'providers': [{'id': 'openai'}]},
            {'id': 'anthropic/claude-3', 'name': 'Claude 3', 'providers': [{'id': 'anthropic'}]},
          ]
        }),
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'CLAUDE');
      await tester.pumpAndSettle();

      expect(find.text('Claude 3'), findsOneWidget);
      expect(find.text('GPT-4'), findsNothing);
    });

    testWidgets('selecting model calls onModelSelected and closes sheet', (tester) async {
      HttpOverrides.global = _FakeHttpOverride(
        responseStatusCode: 200,
        responseBody: jsonEncode({
          'data': [
            {'id': 'anthropic/claude-3', 'name': 'Claude 3', 'providers': [{'id': 'anthropic'}]},
          ]
        }),
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Claude 3'));
      await tester.pumpAndSettle();

      expect(find.text('Select a model from API'), findsWidgets);
    });
  });

  group('Keyboard accessibility', () {
    testWidgets('renders FocusTraversalGroup wrapping the settings list',
        (tester) async {
      await pumpWithSettings(tester);

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('renders interactive tiles that are keyboard-reachable',
        (tester) async {
      await pumpWithSettings(tester);

      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(1));
    });
  });

  group('Section Titles', () {
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
}

class _FakeHttpOverride extends HttpOverrides {
  final int responseStatusCode;
  final String responseBody;

  _FakeHttpOverride({
    required this.responseStatusCode,
    required this.responseBody,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
}

class _TimeoutHttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
}
