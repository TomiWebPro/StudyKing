import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';

void main() {
  group('defaultModelForProvider', () {
    test('returns correct default models', () {
      expect(defaultModelForProvider(LlmProvider.openRouter), equals('gemini-2.0-flash'));
      expect(defaultModelForProvider(LlmProvider.ollama), equals('llama3'));
      expect(defaultModelForProvider(LlmProvider.openAI), equals('gpt-4o-mini'));
    });
  });

  group('app providers', () {
    test('settingsLoadingProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(settingsLoadingProvider), isFalse);
    });

    test('themeModeProvider defaults to light', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('fontSizeProvider defaults to 16', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(fontSizeProvider), equals(16.0));
    });

    test('apiKeyProvider defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(apiKeyProvider), equals(''));
    });

    test('selectedModelProvider defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(selectedModelProvider), equals(''));
    });

    test('llmProviderProvider defaults to openRouter', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(llmProviderProvider), equals(LlmProvider.openRouter));
    });

    test('apiBaseUrlProvider defaults to openRouter base URL', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      expect(container.read(apiBaseUrlProvider), isNotEmpty);
    });

    test('override wiring reads back overridden value', () {
      final container = ProviderContainer(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.dark),
        ],
      );
      addTearDown(() => container.dispose());
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });

    test('override wiring does not affect other providers', () {
      final container = ProviderContainer(
        overrides: [
          fontSizeProvider.overrideWith((ref) => 20.0),
        ],
      );
      addTearDown(() => container.dispose());
      expect(container.read(fontSizeProvider), equals(20.0));
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('StateProvider returns same instance from same container', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final theme1 = container.read(themeModeProvider);
      final theme2 = container.read(themeModeProvider);
      expect(theme1, theme2);
    });

    test('localeProvider falls back to en for unsupported locale', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final locale = container.read(localeProvider);
      expect(locale.languageCode, anyOf('en', 'en_US', 'en_GB'));
    });
  });

  group('SettingsController', () {
    late _FakeSettingsRepository fakeRepo;
    late SettingsController controller;

    setUp(() {
      fakeRepo = _FakeSettingsRepository();
      controller = SettingsController(fakeRepo);
    });

    group('initial state', () {
      test('starts with default SettingsBox', () {
        expect(controller.currentState, isA<SettingsBox>());
        expect(controller.currentState.apiKey, isEmpty);
        expect(controller.currentState.themeModeEnum, equals(ThemeMode.system));
      });
    });

    group('updateSettings', () {
      test('updates api key', () async {
        await controller.updateSettings(apiKey: 'new-key');
        expect(controller.currentState.apiKey, equals('new-key'));
      });

      test('updates theme mode', () async {
        await controller.updateSettings(themeMode: ThemeMode.dark);
        expect(controller.currentState.themeModeEnum, equals(ThemeMode.dark));
      });

      test('updates font size', () async {
        await controller.updateSettings(fontSize: 18.0);
        expect(controller.currentState.fontSize, equals(18.0));
      });

      test('updates multiple fields at once', () async {
        await controller.updateSettings(
          apiKey: 'key',
          fontSize: 20.0,
          studyRemindersEnabled: true,
        );
        expect(controller.currentState.apiKey, equals('key'));
        expect(controller.currentState.fontSize, equals(20.0));
        expect(controller.currentState.studyRemindersEnabled, isTrue);
      });

      test('handles errors gracefully', () async {
        fakeRepo.shouldThrow = true;
        await controller.updateSettings(apiKey: 'key');
        expect(controller.currentState.apiKey, isEmpty);
      });
    });

    group('saveApiKey', () {
      test('saves and loads api key', () async {
        await controller.saveApiKey('test-key');
        expect(controller.currentState.apiKey, equals('test-key'));
      });

      test('handles errors gracefully', () async {
        fakeRepo.shouldThrow = true;
        await controller.saveApiKey('key');
        expect(controller.currentState.apiKey, isEmpty);
      });
    });

    group('updateTheme', () {
      test('updates theme mode', () async {
        await controller.updateTheme(ThemeMode.dark);
        expect(controller.currentState.themeModeEnum, equals(ThemeMode.dark));
      });

      test('handles errors gracefully', () async {
        fakeRepo.shouldThrow = true;
        await controller.updateTheme(ThemeMode.dark);
        expect(controller.currentState.themeModeEnum, equals(ThemeMode.system));
      });
    });

    group('updateFontSize', () {
      test('updates font size', () async {
        await controller.updateFontSize(22.0);
        expect(controller.currentState.fontSize, equals(22.0));
      });
    });

    group('updateModel', () {
      test('updates selected model', () async {
        await controller.updateModel('gpt-4');
        expect(controller.currentState.selectedModel, equals('gpt-4'));
      });
    });

    group('updateStudyReminders', () {
      test('enables study reminders', () async {
        await controller.updateStudyReminders(true);
        expect(controller.currentState.studyRemindersEnabled, isTrue);
      });

      test('disables study reminders', () async {
        await controller.updateStudyReminders(false);
        expect(controller.currentState.studyRemindersEnabled, isFalse);
      });
    });

    group('updateRequestTimeout', () {
      test('updates timeout seconds', () async {
        await controller.updateRequestTimeout(60);
        expect(controller.currentState.requestTimeoutSeconds, equals(60));
      });
    });

    group('updateSessionDuration', () {
      test('updates session duration', () async {
        await controller.updateSessionDuration(45);
        expect(controller.currentState.sessionDurationMinutes, equals(45));
      });
    });

    group('updateStats', () {
      test('updates session count', () async {
        await controller.updateStats(sessionCount: 10);
      });

      test('updates study time', () async {
        await controller.updateStats(studyTimeMs: 3600000);
      });

      test('updates questions count', () async {
        await controller.updateStats(questions: 50);
      });
    });

    group('updateHighContrast', () {
      test('enables high contrast', () async {
        await controller.updateHighContrast(true);
        expect(controller.currentState.highContrastEnabled, isTrue);
      });
    });

    group('updateLargeTouchTargets', () {
      test('enables large touch targets', () async {
        await controller.updateLargeTouchTargets(true);
        expect(controller.currentState.largeTouchTargets, isTrue);
      });
    });

    group('updateReduceMotion', () {
      test('enables reduce motion', () async {
        await controller.updateReduceMotion(true);
        expect(controller.currentState.reduceMotion, isTrue);
      });
    });

    group('updateRevisionReminders', () {
      test('enables revision reminders', () async {
        await controller.updateRevisionReminders(true);
        expect(controller.currentState.revisionRemindersEnabled, isTrue);
      });
    });

    group('updateLessonNotifications', () {
      test('enables lesson notifications', () async {
        await controller.updateLessonNotifications(true);
        expect(controller.currentState.lessonNotificationsEnabled, isTrue);
      });
    });

    group('updateOverworkAlerts', () {
      test('enables overwork alerts', () async {
        await controller.updateOverworkAlerts(true);
        expect(controller.currentState.overworkAlertsEnabled, isTrue);
      });
    });

    group('updatePlanAdjustmentNotifications', () {
      test('enables plan adjustment notifications', () async {
        await controller.updatePlanAdjustmentNotifications(true);
        expect(controller.currentState.planAdjustmentNotificationsEnabled, isTrue);
      });
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();
  bool shouldThrow = false;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<SettingsBox>> getSettings() async {
    if (shouldThrow) return Result.failure('storage error');
    return Result.success(_settings);
  }

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
    if (shouldThrow) return Result.failure('update error');
    _settings = _settings.copyWith(
      apiKey: apiKey,
      apiBaseUrl: apiBaseUrl,
      selectedModel: selectedModel,
      themeModeEnum: themeMode,
      fontSize: fontSize,
      studyRemindersEnabled: studyRemindersEnabled,
      requestTimeoutSeconds: requestTimeoutSeconds,
      sessionDurationMinutes: sessionDurationMinutes,
      highContrastEnabled: highContrastEnabled,
      largeTouchTargets: largeTouchTargets,
      reduceMotion: reduceMotion,
      revisionRemindersEnabled: revisionRemindersEnabled,
      lessonNotificationsEnabled: lessonNotificationsEnabled,
      overworkAlertsEnabled: overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: planAdjustmentNotificationsEnabled,
      breakDurationSeconds: breakDurationSeconds,
      dailyReminderHour: dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute,
      firstFocusVisit: firstFocusVisit,
      dailyReminderEnabled: dailyReminderEnabled,
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> saveApiKey({required String service, required String key}) async {
    if (shouldThrow) return Result.failure('api key save error');
    _settings = _settings.copyWith(apiKey: key);
    return Result.success(null);
  }

  @override
  Future<Result<void>> saveProvider(LlmProvider provider) async => Result.success(null);

  @override
  Future<Result<LlmProvider>> getProvider() async => Result.success(LlmProvider.openRouter);

  @override
  Future<Result<String?>> getApiKey({required String service}) async => Result.success(null);

  @override
  Future<Result<void>> saveProfileData(UserProfile profile) async => Result.success(null);

  @override
  Future<Result<UserProfile?>> getProfileData() async => Result.success(null);

  @override
  Future<Result<void>> clearSettings() async => Result.success(null);

  @override
  Future<Result<void>> clearProfile() async => Result.success(null);

  @override
  Future<Result<void>> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    if (shouldThrow) return Result.failure('stats update error');
    return Result.success(null);
  }

  SettingsBox get currentSettings => _settings;
}
