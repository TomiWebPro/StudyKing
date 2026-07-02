import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/llm_providers.dart';
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
  SettingsBox settings = SettingsBox();
  bool _shouldThrow = false;

  void setThrowOnGetSettings(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<Result<SettingsBox>> getSettings() async {
    if (_shouldThrow) return Result.failure('Simulated error');
    return Result.success(settings);
  }

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    settings = SettingsBox(
      apiKey: update.apiKey ?? settings.apiKey,
      apiBaseUrl: update.apiBaseUrl ?? settings.apiBaseUrl,
      selectedModel: update.selectedModel ?? settings.selectedModel,
      themeMode: update.themeMode?.index ?? settings.themeMode,
      fontSize: update.fontSize ?? settings.fontSize,
      totalSessionCount: settings.totalSessionCount,
      totalStudyTimeMs: settings.totalStudyTimeMs,
      totalQuestions: settings.totalQuestions,
      studyRemindersEnabled: update.studyRemindersEnabled ?? settings.studyRemindersEnabled,
      requestTimeoutSeconds: update.requestTimeoutSeconds ?? settings.requestTimeoutSeconds,
      sessionDurationMinutes: update.sessionDurationMinutes ?? settings.sessionDurationMinutes,
      highContrastEnabled: update.highContrastEnabled ?? settings.highContrastEnabled,
      largeTouchTargets: update.largeTouchTargets ?? settings.largeTouchTargets,
      reduceMotion: update.reduceMotion ?? settings.reduceMotion,
      boldText: update.boldText ?? settings.boldText,
      revisionRemindersEnabled: update.revisionRemindersEnabled ?? settings.revisionRemindersEnabled,
      lessonNotificationsEnabled: update.lessonNotificationsEnabled ?? settings.lessonNotificationsEnabled,
      overworkAlertsEnabled: update.overworkAlertsEnabled ?? settings.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: update.planAdjustmentNotificationsEnabled ?? settings.planAdjustmentNotificationsEnabled,
      breakDurationSeconds: update.breakDurationSeconds ?? settings.breakDurationSeconds,
      dailyReminderHour: update.dailyReminderHour ?? settings.dailyReminderHour,
      dailyReminderMinute: update.dailyReminderMinute ?? settings.dailyReminderMinute,
      firstFocusVisit: update.firstFocusVisit ?? settings.firstFocusVisit,
      dailyReminderEnabled: update.dailyReminderEnabled ?? settings.dailyReminderEnabled,
      lastConnectionTestMs: update.lastConnectionTestMs ?? settings.lastConnectionTestMs,
      lastLlmError: update.lastLlmError ?? settings.lastLlmError,
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
  Future<Result<String?>> getApiKey({required String service}) async => Result.success(settings.apiKey);
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
    fakeRepo.settings = initialSettings;
  }
  final effectiveTaskManager = taskManager ?? FakeLlmTaskManager();
  final effectiveUsageMeter = usageMeter ?? FakeLlmUsageMeter();
  return ProviderScope(
    overrides: [
      if (useThrowingNotifier)
        settingsProvider.overrideWith((ref) => _ThrowingSettingsNotifier())
      else
        settingsProvider.overrideWith((ref) => _TestSettingsNotifier(fakeRepo.settings, fakeRepo)),
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

class FakeSettingsHttpOverride extends HttpOverrides {
  final int responseStatusCode;
  final String responseBody;

  FakeSettingsHttpOverride({
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

class TimeoutSettingsHttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
}
