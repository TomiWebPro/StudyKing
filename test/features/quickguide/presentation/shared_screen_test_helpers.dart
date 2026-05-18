import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FakeLlmService extends LlmService {
  bool shouldThrow = false;
  final List<String> chunks = [];
  bool streamConsumed = false;
  Duration chunkDelay = Duration.zero;
  String? capturedSystemPrompt;
  String? capturedModelId;
  ConversationMemory? capturedMemory;

  FakeLlmService({String apiKey = 'fake-key-for-testing'})
      : super(
          config: LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: apiKey,
          ),
        );

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    if (shouldThrow) throw Exception('Simulated LLM error');
    capturedSystemPrompt = systemPrompt;
    capturedModelId = modelId;
    capturedMemory = memory;
    for (final chunk in chunks) {
      await Future<void>.delayed(chunkDelay);
      yield chunk;
    }
    streamConsumed = true;
  }
}

class FakeSettingsRepository extends SettingsRepository {
  SettingsBox _box;

  FakeSettingsRepository(this._box);

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_box);

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
    final current = _box;
    _box = SettingsBox(
      apiKey: apiKey ?? current.apiKey,
      apiBaseUrl: apiBaseUrl ?? current.apiBaseUrl,
      selectedModel: selectedModel ?? current.selectedModel,
      themeMode: themeMode?.index ?? current.themeMode,
      fontSize: fontSize ?? current.fontSize,
      totalSessionCount: current.totalSessionCount,
      totalStudyTimeMs: current.totalStudyTimeMs,
      totalQuestions: current.totalQuestions,
      studyRemindersEnabled:
          studyRemindersEnabled ?? current.studyRemindersEnabled,
      requestTimeoutSeconds:
          requestTimeoutSeconds ?? current.requestTimeoutSeconds,
      sessionDurationMinutes:
          sessionDurationMinutes ?? current.sessionDurationMinutes,
      highContrastEnabled:
          highContrastEnabled ?? current.highContrastEnabled,
      largeTouchTargets: largeTouchTargets ?? current.largeTouchTargets,
      reduceMotion: reduceMotion ?? current.reduceMotion,
      revisionRemindersEnabled:
          revisionRemindersEnabled ?? current.revisionRemindersEnabled,
      lessonNotificationsEnabled:
          lessonNotificationsEnabled ?? current.lessonNotificationsEnabled,
      overworkAlertsEnabled:
          overworkAlertsEnabled ?? current.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled:
          planAdjustmentNotificationsEnabled ??
              current.planAdjustmentNotificationsEnabled,
      breakDurationSeconds:
          breakDurationSeconds ?? current.breakDurationSeconds,
      dailyReminderHour:
          dailyReminderHour ?? current.dailyReminderHour,
      dailyReminderMinute:
          dailyReminderMinute ?? current.dailyReminderMinute,
      firstFocusVisit:
          firstFocusVisit ?? current.firstFocusVisit,
      dailyReminderEnabled:
          dailyReminderEnabled ?? current.dailyReminderEnabled,
    );
    return Result.success(null);
  }
}

class FakeSettingsController extends SettingsController {
  FakeSettingsController(SettingsBox box)
      : super(FakeSettingsRepository(box)) {
    state = box;
  }
}

Widget buildTestApp({
  QuickGuideScreen? screen,
  NavigatorObserver? observer,
  LlmService? llmService,
  Locale? locale,
  SettingsBox? settingsBox,
}) {
  final overrides = <Override>[];
  if (llmService != null) {
    overrides.add(llmServiceProvider.overrideWith((ref) => llmService));
  }
  if (settingsBox != null) {
    overrides.add(
      settingsProvider.overrideWith((ref) => FakeSettingsController(settingsBox)),
    );
  }
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('en'),
      navigatorObservers: observer != null ? [observer] : [],
      routes: {
        '/tutor': (_) => const Scaffold(
              body: Center(child: Text('Tutor Screen')),
            ),
        '/mentor': (_) => const Scaffold(
              body: Center(child: Text('Mentor Screen')),
            ),
      },
      home: screen ?? const QuickGuideScreen(showModeNavigation: false),
    ),
  );
}

Widget buildTestAppWithProvider({
  required LlmService llmService,
  NavigatorObserver? observer,
  SettingsBox? settingsBox,
}) {
  final overrides = <Override>[
    llmServiceProvider.overrideWith((ref) => llmService),
  ];
  if (settingsBox != null) {
    overrides.add(
      settingsProvider.overrideWith((ref) => FakeSettingsController(settingsBox)),
    );
  }
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: observer != null ? [observer] : [],
      routes: {
        '/mentor': (_) => const Scaffold(
              body: Center(child: Text('Mentor Screen')),
            ),
      },
      home: const QuickGuideScreen(showModeNavigation: false),
    ),
  );
}
