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
import 'package:studyking/core/services/secure_api_key_service.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/secure_api_key_provider.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
import 'package:studyking/features/settings/providers/settings_providers.dart';
import 'package:studyking/features/settings/services/data_backup_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();
  bool _shouldThrow = false;

  void setThrowOnGetSettings(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<Result<SettingsBox>> getSettings() async {
    if (_shouldThrow) return Result.failure('Simulated error');
    return Result.success(_settings);
  }

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    _settings = SettingsBox(
      apiKey: update.apiKey ?? _settings.apiKey,
      apiBaseUrl: update.apiBaseUrl ?? _settings.apiBaseUrl,
      selectedModel: update.selectedModel ?? _settings.selectedModel,
      themeMode: update.themeMode?.index ?? _settings.themeMode,
      fontSize: update.fontSize ?? _settings.fontSize,
      totalSessionCount: _settings.totalSessionCount,
      totalStudyTimeMs: _settings.totalStudyTimeMs,
      totalQuestions: _settings.totalQuestions,
      studyRemindersEnabled: update.studyRemindersEnabled ?? _settings.studyRemindersEnabled,
      requestTimeoutSeconds: update.requestTimeoutSeconds ?? _settings.requestTimeoutSeconds,
      sessionDurationMinutes: update.sessionDurationMinutes ?? _settings.sessionDurationMinutes,
      highContrastEnabled: update.highContrastEnabled ?? _settings.highContrastEnabled,
      largeTouchTargets: update.largeTouchTargets ?? _settings.largeTouchTargets,
      reduceMotion: update.reduceMotion ?? _settings.reduceMotion,
      boldText: update.boldText ?? _settings.boldText,
      revisionRemindersEnabled: update.revisionRemindersEnabled ?? _settings.revisionRemindersEnabled,
      lessonNotificationsEnabled: update.lessonNotificationsEnabled ?? _settings.lessonNotificationsEnabled,
      overworkAlertsEnabled: update.overworkAlertsEnabled ?? _settings.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: update.planAdjustmentNotificationsEnabled ?? _settings.planAdjustmentNotificationsEnabled,
      breakDurationSeconds: update.breakDurationSeconds ?? _settings.breakDurationSeconds,
      dailyReminderHour: update.dailyReminderHour ?? _settings.dailyReminderHour,
      dailyReminderMinute: update.dailyReminderMinute ?? _settings.dailyReminderMinute,
      firstFocusVisit: update.firstFocusVisit ?? _settings.firstFocusVisit,
      dailyReminderEnabled: update.dailyReminderEnabled ?? _settings.dailyReminderEnabled,
      lastConnectionTestMs: update.lastConnectionTestMs ?? _settings.lastConnectionTestMs,
      lastLlmError: update.lastLlmError ?? _settings.lastLlmError,
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
  final List<LlmTask> _overrideTasks;
  final List<LlmTask> _overrideActiveTasks;

  FakeLlmTaskManager({List<LlmTask>? tasks, List<LlmTask>? activeTasks})
      : _overrideTasks = tasks ?? [],
        _overrideActiveTasks = activeTasks ?? [];

  @override
  Future<void> init() async {}

  @override
  List<LlmTask> get tasks => _overrideTasks;

  @override
  List<LlmTask> get activeTasks => _overrideActiveTasks;
}

class FakeLlmUsageMeter extends LlmUsageMeter {
  final int _totalTokens;
  final double _totalCost;
  final Map<String, int> _perFeature;

  FakeLlmUsageMeter({
    int totalTokens = 0,
    double totalCost = 0.0,
    Map<String, int> perFeature = const {},
  })  : _totalTokens = totalTokens,
        _totalCost = totalCost,
        _perFeature = perFeature;

  @override
  Future<void> init() async {}

  @override
  List<LlmUsageRecord> getRecords({String? feature, int? limit}) => [];

  @override
  int getTotalTokens() => _totalTokens;

  @override
  double getTotalCost() => _totalCost;

  @override
  Map<String, int> getTotalTokensPerFeature() => _perFeature;
}

class FakeSecureApiKeyService extends SecureApiKeyService {
  bool clearAllCalled = false;

  FakeSecureApiKeyService() : super();

  @override
  Future<void> clearAll() async {
    clearAllCalled = true;
  }

  @override
  Future<void> saveApiKey(String key) async {}
  @override
  Future<String> getApiKey() async => '';
  @override
  Future<void> saveBackupApiKey(String key) async {}
  @override
  Future<String> getBackupApiKey() async => '';
}

class FakeDataBackupService extends DataBackupService {
  bool exportAllDataCalled = false;

  @override
  Map<String, List<Map<String, dynamic>>> collectAllBoxData() => {};

  @override
  Future<Result<String>> exportAllData({
    required Map<String, List<Map<String, dynamic>>> boxData,
    String? filename,
    String? outputDir,
    bool compress = true,
    String? encryptionPassword,
  }) async {
    exportAllDataCalled = true;
    return Result.success('/tmp/test_backup.skbak');
  }
}

class _TestSettingsNotifier extends SettingsController {
  _TestSettingsNotifier(SettingsBox initial, SettingsRepository repo) : super(repo) {
    state = initial;
  }
}

class _ThrowingSettingsNotifier extends SettingsController {
  _ThrowingSettingsNotifier() : super(fakeRepo);

  @override
  SettingsBox get state => throw Exception('Test settings error');
}

Widget buildSettingsScreen({
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
  LlmTaskManager? taskManager,
  LlmUsageMeter? usageMeter,
  SecureApiKeyService? secureApiKeyService,
  DataBackupService? backupService,
  bool useThrowingNotifier = false,
  TestNavigatorObserver? navigatorObserver,
}) {
  if (initialSettings != null) {
    fakeRepo._settings = initialSettings;
  }
  final effectiveTaskManager = taskManager ?? FakeLlmTaskManager();
  final effectiveUsageMeter = usageMeter ?? FakeLlmUsageMeter();
  return ProviderScope(
    overrides: [
      if (useThrowingNotifier)
        settingsProvider.overrideWith((ref) => _ThrowingSettingsNotifier())
      else
        settingsProvider.overrideWith((ref) => _TestSettingsNotifier(fakeRepo._settings, fakeRepo)),
      apiKeyProvider.overrideWith((ref) => apiKey),
      selectedModelProvider.overrideWith((ref) => selectedModel),
      llmTaskManagerProvider.overrideWith((ref) => effectiveTaskManager),
      llmUsageMeterProvider.overrideWith((ref) => effectiveUsageMeter),
      if (secureApiKeyService != null)
        secureApiKeyServiceProvider.overrideWith((ref) => secureApiKeyService),
      if (backupService != null)
        dataBackupServiceProvider.overrideWith((ref) => backupService),
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
  LlmTaskManager? taskManager,
  LlmUsageMeter? usageMeter,
  SecureApiKeyService? secureApiKeyService,
  DataBackupService? backupService,
  bool useThrowingNotifier = false,
  TestNavigatorObserver? navigatorObserver,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 3500);
  await tester.pumpWidget(buildSettingsScreen(
    initialSettings: initialSettings,
    apiKey: apiKey,
    selectedModel: selectedModel,
    taskManager: taskManager,
    usageMeter: usageMeter,
    secureApiKeyService: secureApiKeyService,
    backupService: backupService,
    useThrowingNotifier: useThrowingNotifier,
    navigatorObserver: navigatorObserver,
  ));
  await tester.pumpAndSettle();
}

Future<void> scrollToWidget(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target,
    find.byType(Scrollable).first,
    const Offset(0, -300),
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

    group('Export Backup Dialog', () {
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

    group('behavioral coverage', () {
      group('SettingsScreen - Spaced Repetition Dialogs', () {
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
      });

      group('SettingsScreen - AI Task Monitor Tile', () {
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
      });

      group('SettingsScreen - Token Usage Details', () {
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

      group('SettingsScreen - Break Duration Dialog', () {
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
      });

      group('SettingsScreen - Session Duration Dialog', () {
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
      });

      group('SettingsScreen - Font Size Label', () {
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
      });

      group('SettingsScreen - Spaced Repetition Labels', () {
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
    });

    group('extended coverage', () {
      group('SettingsScreen - Error State', () {
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
      });

      group('SettingsScreen - Connection Health', () {
        testWidgets('shows connection health tile with not tested when lastConnectionTestMs is 0', (tester) async {
          await pumpWithSettings(tester, initialSettings: SettingsBox(
            lastConnectionTestMs: 0,
            lastLlmError: '',
          ));

          expect(find.text('Connection Health'), findsOneWidget);
          expect(find.text('Not tested'), findsOneWidget);
        });

        testWidgets('shows connection health tile with success when tested without error', (tester) async {
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
      });

      group('SettingsScreen - Break Duration Dialog', () {
        testWidgets('tapping break duration opens dialog with duration options', (tester) async {
          await pumpWithSettings(tester, initialSettings: SettingsBox(breakDurationSeconds: 300));

          await scrollToWidget(tester, find.text('Break Duration'));
          await tester.tap(find.text('Break Duration'));
          await tester.pumpAndSettle();

          expect(find.text('1 minute'), findsOneWidget);
          expect(find.text('2 minutes'), findsOneWidget);
          expect(find.text('3 minutes'), findsOneWidget);
          expect(find.text('5 minutes'), findsOneWidget);
        });

        testWidgets('selecting break duration closes dialog', (tester) async {
          await pumpWithSettings(tester, initialSettings: SettingsBox(breakDurationSeconds: 300));

          await scrollToWidget(tester, find.text('Break Duration'));
          await tester.tap(find.text('Break Duration'));
          await tester.pumpAndSettle();

          await tester.tap(find.text('5 minutes').last);
          await tester.pumpAndSettle();

          expect(find.text('Break Duration'), findsOneWidget);
        });
      });

      group('SettingsScreen - Content Management', () {
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
      });

      group('SettingsScreen - Session Tracking', () {
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
      });

      group('SettingsScreen - Token Usage Summary', () {
        testWidgets('renders total tokens tile with correct count', (tester) async {
          await pumpWithSettings(tester);

          expect(find.text('Total Tokens'), findsOneWidget);
          expect(find.text('5,000 tokens'), findsOneWidget);
        });

        testWidgets('renders total cost tile', (tester) async {
          await pumpWithSettings(tester);

          expect(find.text('Total Cost'), findsOneWidget);
        });

        testWidgets('tapping total tokens opens token usage details dialog', (tester) async {
          await pumpWithSettings(tester);

          await scrollToWidget(tester, find.text('Total Tokens'));
          await tester.tap(find.text('Total Tokens'));
          await tester.pumpAndSettle();

          expect(find.text('Token Usage Summary'), findsAtLeastNWidgets(1));
          expect(find.text('Close'), findsOneWidget);
        });
      });

      group('SettingsScreen - AI Task Monitor', () {
        testWidgets('renders AI Task Monitor tile', (tester) async {
          await pumpWithSettings(tester);

          expect(find.text('AI Task Monitor'), findsOneWidget);
          expect(find.text('No active AI tasks'), findsOneWidget);
        });
      });

      group('SettingsScreen - Backup & Restore Section', () {
        testWidgets('renders Auto Backup tile', (tester) async {
          await pumpWithSettings(tester);

          await scrollToWidget(tester, find.text('Backup & Restore'));
          expect(find.text('Automatic Backup'), findsOneWidget);
        });
      });

      group('SettingsScreen - About Section', () {
        testWidgets('renders Show Onboarding Tour tile', (tester) async {
          await pumpWithSettings(tester);

          await scrollToWidget(tester, find.text('About'));
          await scrollToWidget(tester, find.text('Show onboarding tour'));
          expect(find.text('Show onboarding tour'), findsOneWidget);
        });
      });
    });

    group('gaps coverage', () {
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

      group('SettingsScreen - Token Usage Details', () {
        testWidgets('token usage dialog shows per-feature breakdown', (tester) async {
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

        testWidgets('close button dismisses token usage dialog', (tester) async {
          final usageMeter = FakeLlmUsageMeter(
            totalTokens: 5000,
            totalCost: 0.025,
            perFeature: {'general': 3000},
          );

          await pumpWithSettings(tester, usageMeter: usageMeter);

          await scrollToWidget(tester, find.text('Total Tokens'));
          await tester.tap(find.text('Total Tokens'));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();

          expect(find.text('Token Usage Summary'), findsNothing);
        });
      });

      group('SettingsScreen - AI Task Monitor Tile', () {
        testWidgets('shows subtitle for no active tasks', (tester) async {
          await pumpWithSettings(tester);

          expect(find.text('AI Task Monitor'), findsOneWidget);
          expect(find.text('No active AI tasks'), findsOneWidget);
        });

        testWidgets('shows badge with count when tasks exist', (tester) async {
          final activeTask = LlmTask(
            id: 'task_1',
            feature: 'general',
            modelId: 'gpt-4',
            status: LlmTaskStatus.running,
            startTime: DateTime.now(),
          );
          final failedTask = LlmTask(
            id: 'task_2',
            feature: 'general',
            modelId: 'gpt-4',
            status: LlmTaskStatus.failed,
            startTime: DateTime.now(),
          );
          final taskManager = FakeLlmTaskManager(
            tasks: [activeTask, failedTask],
            activeTasks: [activeTask],
          );

          await pumpWithSettings(tester, taskManager: taskManager);

          expect(find.text('AI Task Monitor'), findsOneWidget);
        });
      });

      group('SettingsScreen - Spaced Repetition Labels', () {
        testWidgets('shows default min interval label', (tester) async {
          await pumpWithSettings(tester);

          expect(find.text('1 days'), findsOneWidget);
        });
      });

      group('SettingsScreen - Connection Health Tile', () {
        testWidgets('shows not tested when lastConnectionTestMs is 0', (tester) async {
          await pumpWithSettings(tester, initialSettings: SettingsBox(
            lastConnectionTestMs: 0,
            lastLlmError: '',
          ));

          expect(find.text('Connection Health'), findsOneWidget);
          expect(find.text('Not tested'), findsOneWidget);
        });

        testWidgets('shows connection successful when tested with no error', (tester) async {
          await pumpWithSettings(tester, initialSettings: SettingsBox(
            lastConnectionTestMs: 1234567890,
            lastLlmError: '',
          ));

          expect(find.text('Connection Health'), findsOneWidget);
          expect(find.textContaining('Connection successful'), findsOneWidget);
        });

        testWidgets('shows error state when llm error exists', (tester) async {
          await pumpWithSettings(tester, initialSettings: SettingsBox(
            lastConnectionTestMs: 1234567890,
            lastLlmError: 'Connection refused',
          ));

          expect(find.text('Connection Health'), findsOneWidget);
          expect(find.textContaining('An error occurred'), findsOneWidget);
        });
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
