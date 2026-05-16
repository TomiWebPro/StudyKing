import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

class _MockSettingsRepository {
  final Map<String, dynamic> _settings = {
    'apiKey': '',
    'apiBaseUrl': 'https://default.com',
    'selectedModel': '',
    'themeMode': 0,
    'fontSize': 16.0,
    'studyRemindersEnabled': true,
    'requestTimeoutSeconds': 30,
    'sessionDurationMinutes': 60,
    'highContrastEnabled': false,
    'largeTouchTargets': false,
    'reduceMotion': false,
    'revisionRemindersEnabled': true,
    'lessonNotificationsEnabled': true,
    'overworkAlertsEnabled': true,
    'planAdjustmentNotificationsEnabled': true,
  };
  String? savedApiKey;
  bool updateSettingsCalled = false;
  bool saveProviderCalled = false;

  Future<void> updateSettings({
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
  }) async {
    updateSettingsCalled = true;
    if (apiKey != null) _settings['apiKey'] = apiKey;
    if (fontSize != null) _settings['fontSize'] = fontSize;
    if (selectedModel != null) _settings['selectedModel'] = selectedModel;
    if (themeMode != null) _settings['themeMode'] = themeMode.index;
    if (studyRemindersEnabled != null) _settings['studyRemindersEnabled'] = studyRemindersEnabled;
    if (requestTimeoutSeconds != null) _settings['requestTimeoutSeconds'] = requestTimeoutSeconds;
  }

  Future<void> saveApiKey({required String service, required String key}) async {
    savedApiKey = key;
  }

  Future<void> saveProvider(LlmProvider provider) async {
    saveProviderCalled = true;
  }

  Future<SettingsBox> getSettings() async {
    // We need to define SettingsBox the way it's actually used
    return SettingsBox(
      apiKey: _settings['apiKey'] as String,
      apiBaseUrl: _settings['apiBaseUrl'] as String,
      selectedModel: _settings['selectedModel'] as String,
      themeMode: (_settings['themeMode'] as num).toInt(),
      fontSize: _settings['fontSize'] as double,
      studyRemindersEnabled: _settings['studyRemindersEnabled'] as bool,
      requestTimeoutSeconds: _settings['requestTimeoutSeconds'] as int,
      sessionDurationMinutes: _settings['sessionDurationMinutes'] as int,
      highContrastEnabled: _settings['highContrastEnabled'] as bool,
      largeTouchTargets: _settings['largeTouchTargets'] as bool,
      reduceMotion: _settings['reduceMotion'] as bool,
      revisionRemindersEnabled: _settings['revisionRemindersEnabled'] as bool,
      lessonNotificationsEnabled: _settings['lessonNotificationsEnabled'] as bool,
      overworkAlertsEnabled: _settings['overworkAlertsEnabled'] as bool,
      planAdjustmentNotificationsEnabled: _settings['planAdjustmentNotificationsEnabled'] as bool,
    );
  }
}

void main() {
  group('SettingsController', () {
    late _MockSettingsRepository mockRepo;
    late SettingsController controller;

    setUp(() {
      mockRepo = _MockSettingsRepository();
      controller = SettingsController(mockRepo as dynamic);
    });

    test('initial state is default SettingsBox', () {
      expect(controller.currentState, isA<SettingsBox>());
    });

    group('updateSettings', () {
      test('updates apiKey', () async {
        await controller.updateSettings(apiKey: 'new-key');
        expect(mockRepo.updateSettingsCalled, isTrue);
      });

      test('updates fontSize', () async {
        await controller.updateSettings(fontSize: 20.0);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });

      test('updates selectedModel', () async {
        await controller.updateSettings(selectedModel: 'gpt-4');
        expect(mockRepo.updateSettingsCalled, isTrue);
      });

      test('updates themeMode', () async {
        await controller.updateSettings(themeMode: ThemeMode.dark);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });

      test('saves provider when llmProvider is specified', () async {
        await controller.updateSettings(llmProvider: LlmProvider.openAI);
        expect(mockRepo.saveProviderCalled, isTrue);
      });

      test('updates multiple fields at once', () async {
        await controller.updateSettings(
          apiKey: 'key',
          fontSize: 18.0,
          studyRemindersEnabled: false,
        );
        expect(mockRepo.updateSettingsCalled, isTrue);
      });

      test('handles error gracefully', () async {
        // Error should be caught without throwing
        await controller.updateSettings();
      });
    });

    group('saveApiKey', () {
      test('saves API key through repository', () async {
        await controller.saveApiKey('my-api-key');
        expect(mockRepo.savedApiKey, equals('my-api-key'));
      });
    });

    group('updateTheme', () {
      test('updates theme mode', () async {
        await controller.updateTheme(ThemeMode.dark);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateFontSize', () {
      test('updates font size', () async {
        await controller.updateFontSize(22.0);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateModel', () {
      test('updates selected model', () async {
        await controller.updateModel('claude-3');
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateStudyReminders', () {
      test('disables study reminders', () async {
        await controller.updateStudyReminders(false);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateRequestTimeout', () {
      test('updates timeout', () async {
        await controller.updateRequestTimeout(60);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateSessionDuration', () {
      test('updates session duration', () async {
        await controller.updateSessionDuration(90);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateStats', () {
      test('updates stats', () async {
        await controller.updateStats(sessionCount: 5, studyTimeMs: 3600000, questions: 50);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateHighContrast', () {
      test('enables high contrast', () async {
        await controller.updateHighContrast(true);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateLargeTouchTargets', () {
      test('enables large touch targets', () async {
        await controller.updateLargeTouchTargets(true);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateReduceMotion', () {
      test('enables reduce motion', () async {
        await controller.updateReduceMotion(true);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateRevisionReminders', () {
      test('disables revision reminders', () async {
        await controller.updateRevisionReminders(false);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateLessonNotifications', () {
      test('disables lesson notifications', () async {
        await controller.updateLessonNotifications(false);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updateOverworkAlerts', () {
      test('disables overwork alerts', () async {
        await controller.updateOverworkAlerts(false);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });

    group('updatePlanAdjustmentNotifications', () {
      test('disables plan adjustment notifications', () async {
        await controller.updatePlanAdjustmentNotifications(false);
        expect(mockRepo.updateSettingsCalled, isTrue);
      });
    });
  });

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
  });
}
