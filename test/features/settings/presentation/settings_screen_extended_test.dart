import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:hive_flutter/hive_flutter.dart';
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
  int getTotalTokens() => 5000;

  @override
  double getTotalCost() => 0.025;

  @override
  Map<String, int> getTotalTokensPerFeature() => {'general': 3000, 'question_generation': 2000};
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
  bool useThrowingNotifier = false,
  TestNavigatorObserver? navigatorObserver,
}) {
  if (initialSettings != null) {
    fakeRepo._settings = initialSettings;
  }
  return ProviderScope(
    overrides: [
      if (useThrowingNotifier)
        settingsProvider.overrideWith((ref) => _ThrowingSettingsNotifier())
      else
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
  bool useThrowingNotifier = false,
  TestNavigatorObserver? navigatorObserver,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 3500);
  await tester.pumpWidget(buildSettingsScreen(
    initialSettings: initialSettings,
    apiKey: apiKey,
    selectedModel: selectedModel,
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
  setUp(() async {
    fakeRepo._settings = SettingsBox(
      themeMode: 0,
      fontSize: 16.0,
      totalSessionCount: 5,
      totalStudyTimeMs: 3600000,
      totalQuestions: 100,
      lastConnectionTestMs: 0,
      lastLlmError: '',
    );
    // Hive init needed for _FailedUploadsTile which creates SourceRepository
    try {
      final dir = Directory.systemTemp.createTempSync('settings_test_');
      Hive.init(dir.path);
      await Hive.openBox(HiveBoxNames.sources);
      addTearDown(() async {
        await Hive.close();
        try { dir.deleteSync(recursive: true); } catch (_) {}
      });
    } catch (_) {}
  });

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
}
