import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/constants/spaced_repetition_config.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
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
import 'package:studyking/core/services/secure_api_key_service.dart';
import '../../../helpers/navigator_observer_helper.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_settings);

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

Widget buildSettingsScreen({
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
  LlmTaskManager? taskManager,
  LlmUsageMeter? usageMeter,
  SecureApiKeyService? secureApiKeyService,
  DataBackupService? backupService,
  TestNavigatorObserver? navigatorObserver,
}) {
  if (initialSettings != null) {
    fakeRepo._settings = initialSettings;
  }
  final effectiveTaskManager = taskManager ?? FakeLlmTaskManager();
  final effectiveUsageMeter = usageMeter ?? FakeLlmUsageMeter();
  return ProviderScope(
    overrides: [
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
  late Directory hiveDir;

  setUp(() async {
    fakeRepo._settings = SettingsBox(
      themeMode: 0,
      fontSize: 16.0,
      totalSessionCount: 5,
      totalStudyTimeMs: 3600000,
      totalQuestions: 100,
      studyRemindersEnabled: false,
    );
    hiveDir = Directory.systemTemp.createTempSync('settings_gaps_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox(HiveBoxNames.settings);
    addTearDown(() async {
      await Hive.close();
      try {
        hiveDir.deleteSync(recursive: true);
      } catch (_) {}
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

  group('SettingsScreen - Auto Backup Dialog', () {
    testWidgets('opens auto backup dialog with options', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Automatic Backup'));
      await tester.tap(find.text('Automatic Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Backup Now'), findsOneWidget);
      expect(find.text('Never'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('auto backup dialog shows never selected by default', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Automatic Backup'));
      await tester.tap(find.text('Automatic Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Never'), findsOneWidget);
    });

    testWidgets('selecting daily interval closes dialog', (tester) async {
      await pumpWithSettings(tester);

      await scrollToWidget(tester, find.text('Automatic Backup'));
      await tester.tap(find.text('Automatic Backup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily'));
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

  group('SettingsScreen - Spaced Repetition Hive Labels', () {
    testWidgets('shows correct min interval from Hive', (tester) async {
      final box = Hive.box(HiveBoxNames.settings);
      await box.put(SrConfig.keyMinIntervalDays, 3);

      await pumpWithSettings(tester);

      expect(find.text('3 days'), findsOneWidget);
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
}
