import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';

class _FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();
  bool shouldThrow = false;

  @override
  Future<void> init() async {}

  @override
  Future<SettingsBox> getSettings() async {
    if (shouldThrow) throw Exception('storage error');
    return _settings;
  }

  @override
  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    LlmProvider? llmProvider,
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
    if (shouldThrow) throw Exception('update error');
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
    );
  }

  @override
  Future<void> saveApiKey({required String service, required String key}) async {
    if (shouldThrow) throw Exception('api key save error');
    _settings = _settings.copyWith(apiKey: key);
  }

  @override
  Future<void> saveProvider(LlmProvider provider) async {}

  @override
  Future<LlmProvider> getProvider() async => LlmProvider.openRouter;

  @override
  Future<String?> getApiKey({required String service}) async => null;

  @override
  Future<void> saveProfileData(UserProfile profile) async {}

  @override
  Future<UserProfile?> getProfileData() async => null;

  @override
  Future<void> clearSettings() async {}

  @override
  Future<void> clearProfile() async {}

  @override
  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    if (shouldThrow) throw Exception('stats update error');
  }

  SettingsBox get currentSettings => _settings;
}

void main() {
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
        expect(controller.currentState.themeModeEnum, isNull);
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
        expect(controller.currentState.themeModeEnum, isNull);
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
