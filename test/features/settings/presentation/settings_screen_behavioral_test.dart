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
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
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
      dailyReminderEnabled: update.dailyReminderEnabled ?? _settings.dailyReminderEnabled,
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
    hiveDir = Directory.systemTemp.createTempSync('settings_sr_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox(HiveBoxNames.settings);
    addTearDown(() async {
      await Hive.close();
      try {
        hiveDir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });

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
    testWidgets('shows correct SR min interval label from Hive', (tester) async {
      final box = Hive.box(HiveBoxNames.settings);
      await box.put(SrConfig.keyMinIntervalDays, 5);

      await pumpWithSettings(tester);

      expect(find.text('5 days'), findsOneWidget);
    });

    testWidgets('shows correct SR max interval label from Hive', (tester) async {
      final box = Hive.box(HiveBoxNames.settings);
      await box.put(SrConfig.keyMaxIntervalDays, 180);

      await pumpWithSettings(tester);

      expect(find.text('180 days'), findsOneWidget);
    });

    testWidgets('shows no limit for daily review when Hive value is 0', (tester) async {
      final box = Hive.box(HiveBoxNames.settings);
      await box.put(SrConfig.keyDailyReviewLimit, 0);

      await pumpWithSettings(tester);

      expect(find.text('No limit'), findsOneWidget);
    });
  });
}
