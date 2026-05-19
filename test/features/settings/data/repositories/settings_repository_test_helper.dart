import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';

void sharedUninitializedTests() {
  group('SettingsRepository uninitialized', () {
    test('returns failure when calling getSettings before init', () async {
      final repo = SettingsRepository();
      final result = await repo.getSettings();
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling saveApiKey before init', () async {
      final repo = SettingsRepository();
      final result = await repo.saveApiKey(service: 'default', key: 'key');
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling getApiKey before init', () async {
      final repo = SettingsRepository();
      final result = await repo.getApiKey(service: 'default');
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling getProfileData before init', () async {
      final repo = SettingsRepository();
      final result = await repo.getProfileData();
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling saveProfileData before init', () async {
      final repo = SettingsRepository();
      final result = await repo.saveProfileData(UserProfile(id: '1', name: 't'));
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling updateSettings before init', () async {
      final repo = SettingsRepository();
      final result = await repo.updateSettings(SettingsUpdate());
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling updateStats before init', () async {
      final repo = SettingsRepository();
      final result = await repo.updateStats();
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling clearSettings before init', () async {
      final repo = SettingsRepository();
      final result = await repo.clearSettings();
      expect(result.isFailure, isTrue);
    });

    test('returns failure when calling clearProfile before init', () async {
      final repo = SettingsRepository();
      final result = await repo.clearProfile();
      expect(result.isFailure, isTrue);
    });
  });
}

void sharedSettingsRepositoryTests({
  required dynamic Function() createInitialized,
  required dynamic Function() createUninitialized,
  required String label,
}) {
  group('init', () {
    test('initializes without error', () async {
      final repo = createUninitialized();
      final result = await repo.init();
      expect(result.isSuccess, isTrue);
    });
  });

  group('saveApiKey', () {
    test('saves API key with default service', () async {
      final repo = createInitialized();
      await repo.saveApiKey(service: 'default', key: 'sk-test-key');
      final retrieved = await repo.getApiKey(service: 'default');
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data, equals('sk-test-key'));
    });

    test('saves API key with custom service name', () async {
      final repo = createInitialized();
      await repo.saveApiKey(service: 'openai', key: 'sk-openai-key');
      final retrieved = await repo.getApiKey(service: 'openai');
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data, equals('sk-openai-key'));
    });

    test('overwrites existing API key', () async {
      final repo = createInitialized();
      await repo.saveApiKey(service: 'default', key: 'sk-first');
      await repo.saveApiKey(service: 'default', key: 'sk-second');
      final retrieved = await repo.getApiKey(service: 'default');
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data, equals('sk-second'));
    });

    test('service key overwrites default key when both exist', () async {
      final repo = createInitialized();
      await repo.saveApiKey(service: 'default', key: 'sk-default');
      await repo.saveApiKey(service: 'ollama', key: 'sk-ollama');
      expect((await repo.getApiKey(service: 'default')).data, equals('sk-ollama'));
      expect((await repo.getApiKey(service: 'ollama')).data, equals('sk-ollama'));
    });
  });

  group('getApiKey', () {
    test('returns null for non-existent service', () async {
      final repo = createInitialized();
      final result = await repo.getApiKey(service: 'nonexistent');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });

  group('getSettings', () {
    test('returns default settings when box is empty', () async {
      final repo = createInitialized();
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.apiKey, equals(''));
      expect(settings.apiBaseUrl, equals('https://openrouter.ai/api/v1'));
      expect(settings.selectedModel, equals(''));
      expect(settings.themeMode, equals(0));
      expect(settings.fontSize, equals(16.0));
      expect(settings.totalSessionCount, equals(0));
      expect(settings.totalStudyTimeMs, equals(0));
      expect(settings.totalQuestions, equals(0));
      expect(settings.studyRemindersEnabled, isTrue);
      expect(settings.requestTimeoutSeconds, equals(120));
      expect(settings.sessionDurationMinutes, equals(30));
    });

    test('returns persisted settings after update', () async {
      final repo = createInitialized();
      await repo.updateSettings(SettingsUpdate(
        apiKey: 'sk-persisted-key',
        apiBaseUrl: 'https://custom.api.com',
        themeMode: ThemeMode.dark,
        fontSize: 20.0,
      ));
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.apiKey, equals('sk-persisted-key'));
      expect(settings.apiBaseUrl, equals('https://custom.api.com'));
      expect(settings.themeMode, equals(ThemeMode.dark.index));
      expect(settings.fontSize, equals(20.0));
    });

    test('returns default accessibility and notification values', () async {
      final repo = createInitialized();
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.highContrastEnabled, isFalse);
      expect(settings.largeTouchTargets, isFalse);
      expect(settings.reduceMotion, isFalse);
      expect(settings.revisionRemindersEnabled, isTrue);
      expect(settings.lessonNotificationsEnabled, isTrue);
      expect(settings.overworkAlertsEnabled, isTrue);
      expect(settings.planAdjustmentNotificationsEnabled, isTrue);
    });

    test('returns persisted accessibility and notification values', () async {
      final repo = createInitialized();
      await repo.updateSettings(
        highContrastEnabled: true,
        largeTouchTargets: true,
        reduceMotion: true,
        revisionRemindersEnabled: false,
        lessonNotificationsEnabled: false,
        overworkAlertsEnabled: false,
        planAdjustmentNotificationsEnabled: false,
      );
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.highContrastEnabled, isTrue);
      expect(settings.largeTouchTargets, isTrue);
      expect(settings.reduceMotion, isTrue);
      expect(settings.revisionRemindersEnabled, isFalse);
      expect(settings.lessonNotificationsEnabled, isFalse);
      expect(settings.overworkAlertsEnabled, isFalse);
      expect(settings.planAdjustmentNotificationsEnabled, isFalse);
    });
  });

  group('updateSettings', () {
    test('updates only specified fields, preserves others', () async {
      final repo = createInitialized();
      await repo.updateSettings(
        themeMode: ThemeMode.dark,
        fontSize: 20.0,
      );
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.themeMode, equals(ThemeMode.dark.index));
      expect(settings.fontSize, equals(20.0));
      expect(settings.apiKey, equals(''));
      expect(settings.selectedModel, equals(''));
    });

    test('updates theme mode correctly', () async {
      final repo = createInitialized();
      await repo.updateSettings(themeMode: ThemeMode.light);
      expect((await repo.getSettings()).data!.themeMode, equals(ThemeMode.light.index));

      await repo.updateSettings(themeMode: ThemeMode.dark);
      expect((await repo.getSettings()).data!.themeMode, equals(ThemeMode.dark.index));

      await repo.updateSettings(themeMode: ThemeMode.system);
      expect((await repo.getSettings()).data!.themeMode, equals(ThemeMode.system.index));
    });

    test('updates font size with bounds', () async {
      final repo = createInitialized();
      await repo.updateSettings(fontSize: 10.0);
      expect((await repo.getSettings()).data!.fontSize, equals(10.0));

      await repo.updateSettings(fontSize: 30.0);
      expect((await repo.getSettings()).data!.fontSize, equals(30.0));
    });

    test('updates request timeout within valid range', () async {
      final repo = createInitialized();
      await repo.updateSettings(requestTimeoutSeconds: 30);
      expect((await repo.getSettings()).data!.requestTimeoutSeconds, equals(30));

      await repo.updateSettings(requestTimeoutSeconds: 300);
      expect((await repo.getSettings()).data!.requestTimeoutSeconds, equals(300));
    });

    test('updates session duration', () async {
      final repo = createInitialized();
      await repo.updateSettings(sessionDurationMinutes: 15);
      expect((await repo.getSettings()).data!.sessionDurationMinutes, equals(15));

      await repo.updateSettings(sessionDurationMinutes: 90);
      expect((await repo.getSettings()).data!.sessionDurationMinutes, equals(90));
    });

    test('updates study reminders enabled flag', () async {
      final repo = createInitialized();
      await repo.updateSettings(studyRemindersEnabled: false);
      expect((await repo.getSettings()).data!.studyRemindersEnabled, isFalse);

      await repo.updateSettings(studyRemindersEnabled: true);
      expect((await repo.getSettings()).data!.studyRemindersEnabled, isTrue);
    });

    test('updates all settings at once', () async {
      final repo = createInitialized();
      await repo.updateSettings(
        apiKey: 'sk-all-at-once',
        apiBaseUrl: 'https://all.at.once.com',
        selectedModel: 'test-model',
        themeMode: ThemeMode.dark,
        fontSize: 18.0,
        studyRemindersEnabled: false,
        requestTimeoutSeconds: 60,
        sessionDurationMinutes: 45,
      );
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.apiKey, equals('sk-all-at-once'));
      expect(settings.apiBaseUrl, equals('https://all.at.once.com'));
      expect(settings.selectedModel, equals('test-model'));
      expect(settings.themeMode, equals(ThemeMode.dark.index));
      expect(settings.fontSize, equals(18.0));
      expect(settings.studyRemindersEnabled, isFalse);
      expect(settings.requestTimeoutSeconds, equals(60));
      expect(settings.sessionDurationMinutes, equals(45));
    });

    test('preserves statistics when updating other settings', () async {
      final repo = createInitialized();
      await repo.updateStats(
        sessionCount: 5,
        studyTimeMs: 3600000,
        questions: 100,
      );
      await repo.updateSettings(fontSize: 20.0);
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.totalSessionCount, equals(5));
      expect(settings.totalStudyTimeMs, equals(3600000));
      expect(settings.totalQuestions, equals(100));
    });

    test('updates highContrastEnabled', () async {
      final repo = createInitialized();
      await repo.updateSettings(highContrastEnabled: true);
      expect((await repo.getSettings()).data!.highContrastEnabled, isTrue);
      await repo.updateSettings(highContrastEnabled: false);
      expect((await repo.getSettings()).data!.highContrastEnabled, isFalse);
    });

    test('updates largeTouchTargets', () async {
      final repo = createInitialized();
      await repo.updateSettings(largeTouchTargets: true);
      expect((await repo.getSettings()).data!.largeTouchTargets, isTrue);
      await repo.updateSettings(largeTouchTargets: false);
      expect((await repo.getSettings()).data!.largeTouchTargets, isFalse);
    });

    test('updates reduceMotion', () async {
      final repo = createInitialized();
      await repo.updateSettings(reduceMotion: true);
      expect((await repo.getSettings()).data!.reduceMotion, isTrue);
      await repo.updateSettings(reduceMotion: false);
      expect((await repo.getSettings()).data!.reduceMotion, isFalse);
    });

    test('updates revisionRemindersEnabled', () async {
      final repo = createInitialized();
      await repo.updateSettings(revisionRemindersEnabled: false);
      expect((await repo.getSettings()).data!.revisionRemindersEnabled, isFalse);
      await repo.updateSettings(revisionRemindersEnabled: true);
      expect((await repo.getSettings()).data!.revisionRemindersEnabled, isTrue);
    });

    test('updates lessonNotificationsEnabled', () async {
      final repo = createInitialized();
      await repo.updateSettings(lessonNotificationsEnabled: false);
      expect((await repo.getSettings()).data!.lessonNotificationsEnabled, isFalse);
      await repo.updateSettings(lessonNotificationsEnabled: true);
      expect((await repo.getSettings()).data!.lessonNotificationsEnabled, isTrue);
    });

    test('updates overworkAlertsEnabled', () async {
      final repo = createInitialized();
      await repo.updateSettings(overworkAlertsEnabled: false);
      expect((await repo.getSettings()).data!.overworkAlertsEnabled, isFalse);
      await repo.updateSettings(overworkAlertsEnabled: true);
      expect((await repo.getSettings()).data!.overworkAlertsEnabled, isTrue);
    });

    test('updates planAdjustmentNotificationsEnabled', () async {
      final repo = createInitialized();
      await repo.updateSettings(planAdjustmentNotificationsEnabled: false);
      expect((await repo.getSettings()).data!.planAdjustmentNotificationsEnabled, isFalse);
      await repo.updateSettings(planAdjustmentNotificationsEnabled: true);
      expect((await repo.getSettings()).data!.planAdjustmentNotificationsEnabled, isTrue);
    });

    test('updates all accessibility and notification fields at once', () async {
      final repo = createInitialized();
      await repo.updateSettings(
        highContrastEnabled: true,
        largeTouchTargets: true,
        reduceMotion: true,
        revisionRemindersEnabled: false,
        lessonNotificationsEnabled: false,
        overworkAlertsEnabled: false,
        planAdjustmentNotificationsEnabled: false,
      );
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.highContrastEnabled, isTrue);
      expect(settings.largeTouchTargets, isTrue);
      expect(settings.reduceMotion, isTrue);
      expect(settings.revisionRemindersEnabled, isFalse);
      expect(settings.lessonNotificationsEnabled, isFalse);
      expect(settings.overworkAlertsEnabled, isFalse);
      expect(settings.planAdjustmentNotificationsEnabled, isFalse);
    });
  });

  group('updateStats', () {
    test('updates session count', () async {
      final repo = createInitialized();
      await repo.updateStats(sessionCount: 10);
      expect((await repo.getSettings()).data!.totalSessionCount, equals(10));
    });

    test('updates study time', () async {
      final repo = createInitialized();
      await repo.updateStats(studyTimeMs: 7200000);
      expect((await repo.getSettings()).data!.totalStudyTimeMs, equals(7200000));
    });

    test('updates questions count', () async {
      final repo = createInitialized();
      await repo.updateStats(questions: 50);
      expect((await repo.getSettings()).data!.totalQuestions, equals(50));
    });

    test('updates multiple stats at once', () async {
      final repo = createInitialized();
      await repo.updateStats(
        sessionCount: 20,
        studyTimeMs: 10800000,
        questions: 200,
      );
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.totalSessionCount, equals(20));
      expect(settings.totalStudyTimeMs, equals(10800000));
      expect(settings.totalQuestions, equals(200));
    });
  });

  group('saveProfileData', () {
    test('saves profile data successfully', () async {
      final repo = createInitialized();
      final profile = UserProfile(
        id: 'test-profile',
        name: 'Test User',
        studentId: '12345',
        learningGoal: 'Learn Flutter',
        preferredStudyTime: 'Morning',
      );
      await repo.saveProfileData(profile);

      final retrieved = await repo.getProfileData();
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data, isNotNull);
      expect(retrieved.data!.id, equals('test-profile'));
      expect(retrieved.data!.name, equals('Test User'));
      expect(retrieved.data!.studentId, equals('12345'));
      expect(retrieved.data!.learningGoal, equals('Learn Flutter'));
      expect(retrieved.data!.preferredStudyTime, equals('Morning'));
    });

    test('saves multiple profiles and tracks current', () async {
      final repo = createInitialized();
      final profile1 = UserProfile(id: 'profile-1', name: 'User 1');
      final profile2 = UserProfile(id: 'profile-2', name: 'User 2');

      await repo.saveProfileData(profile1);
      await repo.saveProfileData(profile2);

      final current = await repo.getProfileData();
      expect(current.isSuccess, isTrue);
      expect(current.data!.id, equals('profile-2'));
      expect(current.data!.name, equals('User 2'));
    });

    test('updates existing profile', () async {
      final repo = createInitialized();
      final original = UserProfile(
        id: 'update-test',
        name: 'Original Name',
        studentId: '111',
      );
      await repo.saveProfileData(original);

      final updated = UserProfile(
        id: 'update-test',
        name: 'Updated Name',
        studentId: '222',
      );
      await repo.saveProfileData(updated);

      final retrieved = await repo.getProfileData();
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data!.name, equals('Updated Name'));
      expect(retrieved.data!.studentId, equals('222'));
    });

    test('preserves profile avatar icon', () async {
      final repo = createInitialized();
      final profile = UserProfile(
        id: 'avatar-test',
        name: 'Avatar User',
        avatarIcon: 'Icons.school',
      );
      await repo.saveProfileData(profile);

      final retrieved = await repo.getProfileData();
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data!.avatarIcon, equals('Icons.school'));
    });

    test('preserves notifications and language settings', () async {
      final repo = createInitialized();
      final profile = UserProfile(
        id: 'settings-test',
        name: 'Settings User',
        notificationsEnabled: false,
        language: 'es',
      );
      await repo.saveProfileData(profile);

      final retrieved = await repo.getProfileData();
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data!.notificationsEnabled, isFalse);
      expect(retrieved.data!.language, equals('es'));
    });
  });

  group('clearSettings', () {
    test('clears all settings', () async {
      final repo = createInitialized();
      await repo.updateSettings(
        apiKey: 'sk-to-be-cleared',
        themeMode: ThemeMode.dark,
      );
      await repo.clearSettings();

      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.apiKey, equals(''));
      expect(settings.themeMode, equals(0));
    });

    test('resets statistics to zero', () async {
      final repo = createInitialized();
      await repo.updateStats(
        sessionCount: 100,
        studyTimeMs: 9999999,
        questions: 500,
      );
      await repo.clearSettings();

      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      final settings = result.data!;
      expect(settings.totalSessionCount, equals(0));
      expect(settings.totalStudyTimeMs, equals(0));
      expect(settings.totalQuestions, equals(0));
    });
  });

  group('clearProfile', () {
    test('clears profile data and returns default', () async {
      final repo = createInitialized();
      final profile = UserProfile(id: 'clear-test', name: 'Clear Test');
      await repo.saveProfileData(profile);
      await repo.clearProfile();

      final retrieved = await repo.getProfileData();
      expect(retrieved.isSuccess, isTrue);
      expect(retrieved.data, isNotNull);
      expect(retrieved.data!.id, equals('default_profile'));
      expect(retrieved.data!.name, equals(''));
    });
  });

  group('saveProvider', () {
    test('saves and retrieves openRouter provider', () async {
      final repo = createInitialized();
      await repo.saveProvider(LlmProvider.openRouter);
      expect((await repo.getProvider()).data, LlmProvider.openRouter);
    });

    test('saves and retrieves ollama provider', () async {
      final repo = createInitialized();
      await repo.saveProvider(LlmProvider.ollama);
      expect((await repo.getProvider()).data, LlmProvider.ollama);
    });

    test('saves and retrieves openAI provider', () async {
      final repo = createInitialized();
      await repo.saveProvider(LlmProvider.openAI);
      expect((await repo.getProvider()).data, LlmProvider.openAI);
    });

    test('overwrites existing provider', () async {
      final repo = createInitialized();
      await repo.saveProvider(LlmProvider.openRouter);
      await repo.saveProvider(LlmProvider.openAI);
      expect((await repo.getProvider()).data, LlmProvider.openAI);
    });
  });

  group('getProvider', () {
    test('defaults to openRouter when no provider saved', () async {
      final repo = createInitialized();
      final result = await repo.getProvider();
      expect(result.isSuccess, isTrue);
      expect(result.data, LlmProvider.openRouter);
    });
  });

  group('themeModeEnum getter', () {
    test('returns correct ThemeMode from index', () async {
      final repo = createInitialized();
      await repo.updateSettings(themeMode: ThemeMode.light);
      expect((await repo.getSettings()).data!.themeModeEnum, equals(ThemeMode.light));

      await repo.updateSettings(themeMode: ThemeMode.dark);
      expect((await repo.getSettings()).data!.themeModeEnum, equals(ThemeMode.dark));

      await repo.updateSettings(themeMode: ThemeMode.system);
      expect((await repo.getSettings()).data!.themeModeEnum, equals(ThemeMode.system));
    });

    test('defaults to system for index 0', () async {
      final repo = createInitialized();
      final result = await repo.getSettings();
      expect(result.isSuccess, isTrue);
      expect(result.data!.themeModeEnum, equals(ThemeMode.system));
    });
  });

  group('toString', () {
    test('returns correct string representation', () {
      expect(SettingsRepository().toString(), equals('SettingsRepository()'));
    });
  });

  group('api key isolation', () {
    test('different services have separate keys', () async {
      final repo = createInitialized();
      await repo.saveApiKey(service: 'openai', key: 'sk-openai');
      await repo.saveApiKey(service: 'ollama', key: 'sk-ollama');
      expect((await repo.getApiKey(service: 'openai')).data, equals('sk-openai'));
      expect((await repo.getApiKey(service: 'ollama')).data, equals('sk-ollama'));
      expect((await repo.getApiKey(service: 'default')).data, equals('sk-ollama'));
    });

    test('non-default service key does not appear in unrelated service', () async {
      final repo = createInitialized();
      await repo.saveApiKey(service: 'openai', key: 'sk-openai');
      final result = await repo.getApiKey(service: 'anthropic');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('default key alone does not create service keys', () async {
      final repo = createInitialized();
      await repo.saveApiKey(service: 'default', key: 'sk-default');
      expect((await repo.getApiKey(service: 'default')).data, equals('sk-default'));
      final result = await repo.getApiKey(service: 'some-service');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });
}
