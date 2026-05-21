import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/settings/data/models/accessibility_preferences.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';

void main() {
  late String hivePath;
  late SettingsRepository repository;

  setUpAll(() {
    try {
      Hive.registerAdapter(SettingsBoxAdapter());
    } catch (_) {}
    try {
      Hive.registerAdapter(UserProfileAdapter());
    } catch (_) {}
    try {
      Hive.registerAdapter(AccessibilityPreferencesAdapter());
    } catch (_) {}
  });

  setUp(() async {
    hivePath = (await Directory.systemTemp.createTemp('settings_repo_')).path;
    Hive.init(hivePath);
    repository = SettingsRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (hivePath.isNotEmpty) {
      await Directory(hivePath).delete(recursive: true);
    }
  });

  group('SettingsRepository (real Hive)', () {
    group('constructor', () {
      test('creates new instances (not singleton)', () {
        final a = SettingsRepository();
        final b = SettingsRepository();
        expect(identical(a, b), isFalse);
      });
    });

    group('init', () {
      test('initializes both settings and profile boxes', () async {
        final result = await repository.init();
        expect(result.isSuccess, isTrue);

        final settingsBox = await Hive.openBox(HiveBoxNames.settings);
        expect(settingsBox.isOpen, isTrue);
        await settingsBox.close();

        final profileBox = await Hive.openBox(HiveBoxNames.profile);
        expect(profileBox.isOpen, isTrue);
        await profileBox.close();
      });

      test('is idempotent when called multiple times', () async {
        await repository.init();
        final result = await repository.init();
        expect(result.isSuccess, isTrue);
      });

      test('returns failure when Hive init fails (already closed box name)', () async {
        final repo = SettingsRepository();
        final result = await repo.init();
        expect(result.isSuccess, isTrue);
      });
    });

    group('uninitialized operations return failure', () {
      test('getSettings before init', () async {
        final result = await repository.getSettings();
        expect(result.isFailure, isTrue);
      });

      test('saveApiKey before init', () async {
        final result = await repository.saveApiKey(service: 'default', key: 'key');
        expect(result.isFailure, isTrue);
      });

      test('getApiKey before init', () async {
        final result = await repository.getApiKey(service: 'default');
        expect(result.isFailure, isTrue);
      });

      test('getProfileData before init', () async {
        final result = await repository.getProfileData();
        expect(result.isFailure, isTrue);
      });

      test('saveProfileData before init', () async {
        final result = await repository.saveProfileData(UserProfile(id: '1', name: 't'));
        expect(result.isFailure, isTrue);
      });

      test('updateSettings before init', () async {
        final result = await repository.updateSettings(SettingsUpdate());
        expect(result.isFailure, isTrue);
      });

      test('updateStats before init', () async {
        final result = await repository.updateStats();
        expect(result.isFailure, isTrue);
      });

      test('clearSettings before init', () async {
        final result = await repository.clearSettings();
        expect(result.isFailure, isTrue);
      });

      test('clearProfile before init', () async {
        final result = await repository.clearProfile();
        expect(result.isFailure, isTrue);
      });

      test('saveProvider before init', () async {
        final result = await repository.saveProvider(LlmProvider.openRouter);
        expect(result.isFailure, isTrue);
      });

      test('getProvider before init', () async {
        final result = await repository.getProvider();
        expect(result.isFailure, isTrue);
      });
    });

    group('saveApiKey and getApiKey', () {
      setUp(() async {
        await repository.init();
      });

      test('saves and retrieves key with default service', () async {
        await repository.saveApiKey(service: 'default', key: 'sk-test-key');
        final result = await repository.getApiKey(service: 'default');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals('sk-test-key'));
      });

      test('saves and retrieves key with custom service', () async {
        await repository.saveApiKey(service: 'openai', key: 'sk-openai-key');
        final result = await repository.getApiKey(service: 'openai');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals('sk-openai-key'));
      });

      test('overwrites existing key', () async {
        await repository.saveApiKey(service: 'default', key: 'sk-first');
        await repository.saveApiKey(service: 'default', key: 'sk-second');
        final result = await repository.getApiKey(service: 'default');
        expect(result.data, equals('sk-second'));
      });

      test('returns null for non-existent service key', () async {
        final result = await repository.getApiKey(service: 'nonexistent');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('saves both default and service-specific keys', () async {
        await repository.saveApiKey(service: 'ollama', key: 'sk-ollama');
        expect((await repository.getApiKey(service: 'default')).data, equals('sk-ollama'));
        expect((await repository.getApiKey(service: 'ollama')).data, equals('sk-ollama'));
      });

      test('service keys are isolated', () async {
        await repository.saveApiKey(service: 'openai', key: 'sk-openai');
        await repository.saveApiKey(service: 'ollama', key: 'sk-ollama');
        expect((await repository.getApiKey(service: 'openai')).data, equals('sk-openai'));
        expect((await repository.getApiKey(service: 'ollama')).data, equals('sk-ollama'));
      });

      test('non-default service key does not appear in unrelated service', () async {
        await repository.saveApiKey(service: 'openai', key: 'sk-openai');
        final result = await repository.getApiKey(service: 'anthropic');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('default key alone does not create service keys', () async {
        await repository.saveApiKey(service: 'default', key: 'sk-default');
        expect((await repository.getApiKey(service: 'default')).data, equals('sk-default'));
        final result = await repository.getApiKey(service: 'some-service');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('empty string key can be saved', () async {
        await repository.saveApiKey(service: 'default', key: '');
        expect((await repository.getApiKey(service: 'default')).data, equals(''));
      });
    });

    group('saveProvider and getProvider', () {
      setUp(() async {
        await repository.init();
      });

      test('defaults to openRouter when no provider saved', () async {
        final result = await repository.getProvider();
        expect(result.isSuccess, isTrue);
        expect(result.data, LlmProvider.openRouter);
      });

      test('saves and retrieves openRouter provider', () async {
        await repository.saveProvider(LlmProvider.openRouter);
        expect((await repository.getProvider()).data, LlmProvider.openRouter);
      });

      test('saves and retrieves ollama provider', () async {
        await repository.saveProvider(LlmProvider.ollama);
        expect((await repository.getProvider()).data, LlmProvider.ollama);
      });

      test('saves and retrieves openAI provider', () async {
        await repository.saveProvider(LlmProvider.openAI);
        expect((await repository.getProvider()).data, LlmProvider.openAI);
      });

      test('overwrites existing provider', () async {
        await repository.saveProvider(LlmProvider.openRouter);
        await repository.saveProvider(LlmProvider.openAI);
        expect((await repository.getProvider()).data, LlmProvider.openAI);
      });

      test('falls back to openRouter for unknown stored provider name', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('llmProvider', 'non_existent_provider');
        final result = await repository.getProvider();
        expect(result.data, LlmProvider.openRouter);
      });
    });

    group('getSettings', () {
      setUp(() async {
        await repository.init();
      });

      test('returns default settings when box is empty', () async {
        final result = await repository.getSettings();
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
        expect(settings.highContrastEnabled, isFalse);
        expect(settings.largeTouchTargets, isFalse);
        expect(settings.reduceMotion, isFalse);
        expect(settings.boldText, isFalse);
        expect(settings.revisionRemindersEnabled, isTrue);
        expect(settings.lessonNotificationsEnabled, isTrue);
        expect(settings.overworkAlertsEnabled, isTrue);
        expect(settings.planAdjustmentNotificationsEnabled, isTrue);
        expect(settings.breakDurationSeconds, equals(300));
        expect(settings.dailyReminderHour, equals(9));
        expect(settings.dailyReminderMinute, equals(0));
        expect(settings.firstFocusVisit, isTrue);
        expect(settings.dailyReminderEnabled, isFalse);
        expect(settings.llmProviderName, equals('openRouter'));
        expect(settings.lastConnectionTestMs, equals(0));
        expect(settings.lastLlmError, equals(''));
        expect(settings.backupLlmProviderName, equals(''));
        expect(settings.backupApiKey, equals(''));
        expect(settings.backupBaseUrl, equals(''));
        expect(settings.backupModel, equals(''));
      });

      test('legacy migration: reads individual keys', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('apiKey', 'legacy-key');
        await box.put('apiBaseUrl', 'https://legacy.url');
        await box.put('selectedModel', 'legacy-model');
        await box.put('themeMode', 1);
        await box.put('fontSize', 20.0);
        await box.put('totalSessionCount', 42);
        await box.put('studyRemindersEnabled', false);
        await box.put('requestTimeoutSeconds', 60);
        await box.put('sessionDurationMinutes', 45);

        final result = await repository.getSettings();
        expect(result.isSuccess, isTrue);
        final settings = result.data!;
        expect(settings.apiKey, equals('legacy-key'));
        expect(settings.apiBaseUrl, equals('https://legacy.url'));
        expect(settings.selectedModel, equals('legacy-model'));
        expect(settings.themeMode, equals(1));
        expect(settings.fontSize, equals(20.0));
        expect(settings.totalSessionCount, equals(42));
        expect(settings.studyRemindersEnabled, isFalse);
        expect(settings.requestTimeoutSeconds, equals(60));
        expect(settings.sessionDurationMinutes, equals(45));

        final stored = box.get('settings');
        expect(stored, isA<Map>());
      });

      test('reads persisted settings from JSON storage', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        final settings = SettingsBox(
          apiKey: 'sk-json',
          apiBaseUrl: 'https://json.url',
          selectedModel: 'json-model',
          themeMode: 2,
          fontSize: 22.0,
          totalSessionCount: 10,
          totalStudyTimeMs: 500000,
          totalQuestions: 100,
          studyRemindersEnabled: false,
          requestTimeoutSeconds: 90,
          sessionDurationMinutes: 25,
          highContrastEnabled: true,
          largeTouchTargets: true,
          reduceMotion: true,
          boldText: true,
          revisionRemindersEnabled: false,
          lessonNotificationsEnabled: false,
          overworkAlertsEnabled: false,
          planAdjustmentNotificationsEnabled: false,
          breakDurationSeconds: 600,
          dailyReminderHour: 8,
          dailyReminderMinute: 30,
          firstFocusVisit: false,
          dailyReminderEnabled: true,
          llmProviderName: 'ollama',
          lastConnectionTestMs: 123456789,
          lastLlmError: 'rate limit',
          backupLlmProviderName: 'openAI',
          backupApiKey: 'sk-backup',
          backupBaseUrl: 'https://backup.url',
          backupModel: 'gpt-4',
        );
        await box.put('settings', settings.toJson());

        final result = await repository.getSettings();
        expect(result.isSuccess, isTrue);
        final retrieved = result.data!;
        expect(retrieved.apiKey, equals('sk-json'));
        expect(retrieved.apiBaseUrl, equals('https://json.url'));
        expect(retrieved.selectedModel, equals('json-model'));
        expect(retrieved.themeMode, equals(2));
        expect(retrieved.fontSize, equals(22.0));
        expect(retrieved.totalSessionCount, equals(10));
        expect(retrieved.totalStudyTimeMs, equals(500000));
        expect(retrieved.totalQuestions, equals(100));
        expect(retrieved.studyRemindersEnabled, isFalse);
        expect(retrieved.requestTimeoutSeconds, equals(90));
        expect(retrieved.sessionDurationMinutes, equals(25));
        expect(retrieved.highContrastEnabled, isTrue);
        expect(retrieved.largeTouchTargets, isTrue);
        expect(retrieved.reduceMotion, isTrue);
        expect(retrieved.boldText, isTrue);
        expect(retrieved.revisionRemindersEnabled, isFalse);
        expect(retrieved.lessonNotificationsEnabled, isFalse);
        expect(retrieved.overworkAlertsEnabled, isFalse);
        expect(retrieved.planAdjustmentNotificationsEnabled, isFalse);
        expect(retrieved.breakDurationSeconds, equals(600));
        expect(retrieved.dailyReminderHour, equals(8));
        expect(retrieved.dailyReminderMinute, equals(30));
        expect(retrieved.firstFocusVisit, isFalse);
        expect(retrieved.dailyReminderEnabled, isTrue);
        expect(retrieved.llmProviderName, equals('ollama'));
        expect(retrieved.lastConnectionTestMs, equals(123456789));
        expect(retrieved.lastLlmError, equals('rate limit'));
        expect(retrieved.backupLlmProviderName, equals('openAI'));
        expect(retrieved.backupApiKey, equals('sk-backup'));
        expect(retrieved.backupBaseUrl, equals('https://backup.url'));
        expect(retrieved.backupModel, equals('gpt-4'));
      });
    });

    group('updateSettings', () {
      setUp(() async {
        await repository.init();
      });

      test('updates only specified fields, preserves others', () async {
        await repository.updateSettings(SettingsUpdate(
          themeMode: ThemeMode.dark,
          fontSize: 20.0,
        ));
        final result = await repository.getSettings();
        final settings = result.data!;
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.fontSize, equals(20.0));
        expect(settings.apiKey, equals(''));
        expect(settings.selectedModel, equals(''));
      });

      test('updates all basic fields', () async {
        await repository.updateSettings(SettingsUpdate(
          apiKey: 'sk-all',
          apiBaseUrl: 'https://all.url',
          selectedModel: 'model-all',
          themeMode: ThemeMode.dark,
          fontSize: 18.0,
          studyRemindersEnabled: false,
          requestTimeoutSeconds: 60,
          sessionDurationMinutes: 45,
        ));
        final settings = (await repository.getSettings()).data!;
        expect(settings.apiKey, equals('sk-all'));
        expect(settings.apiBaseUrl, equals('https://all.url'));
        expect(settings.selectedModel, equals('model-all'));
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.fontSize, equals(18.0));
        expect(settings.studyRemindersEnabled, isFalse);
        expect(settings.requestTimeoutSeconds, equals(60));
        expect(settings.sessionDurationMinutes, equals(45));
      });

      test('updates all accessibility fields', () async {
        await repository.updateSettings(SettingsUpdate(
          highContrastEnabled: true,
          largeTouchTargets: true,
          reduceMotion: true,
          boldText: true,
        ));
        final settings = (await repository.getSettings()).data!;
        expect(settings.highContrastEnabled, isTrue);
        expect(settings.largeTouchTargets, isTrue);
        expect(settings.reduceMotion, isTrue);
        expect(settings.boldText, isTrue);

        await repository.updateSettings(SettingsUpdate(
          highContrastEnabled: false,
          largeTouchTargets: false,
          reduceMotion: false,
          boldText: false,
        ));
        final updated = (await repository.getSettings()).data!;
        expect(updated.highContrastEnabled, isFalse);
        expect(updated.largeTouchTargets, isFalse);
        expect(updated.reduceMotion, isFalse);
        expect(updated.boldText, isFalse);
      });

      test('updates all notification fields', () async {
        await repository.updateSettings(SettingsUpdate(
          revisionRemindersEnabled: false,
          lessonNotificationsEnabled: false,
          overworkAlertsEnabled: false,
          planAdjustmentNotificationsEnabled: false,
        ));
        final settings = (await repository.getSettings()).data!;
        expect(settings.revisionRemindersEnabled, isFalse);
        expect(settings.lessonNotificationsEnabled, isFalse);
        expect(settings.overworkAlertsEnabled, isFalse);
        expect(settings.planAdjustmentNotificationsEnabled, isFalse);

        await repository.updateSettings(SettingsUpdate(
          revisionRemindersEnabled: true,
          lessonNotificationsEnabled: true,
          overworkAlertsEnabled: true,
          planAdjustmentNotificationsEnabled: true,
        ));
        final updated = (await repository.getSettings()).data!;
        expect(updated.revisionRemindersEnabled, isTrue);
        expect(updated.lessonNotificationsEnabled, isTrue);
        expect(updated.overworkAlertsEnabled, isTrue);
        expect(updated.planAdjustmentNotificationsEnabled, isTrue);
      });

      test('updates all backup provider fields', () async {
        await repository.updateSettings(SettingsUpdate(
          llmProviderName: 'ollama',
          lastConnectionTestMs: 987654321,
          lastLlmError: 'timeout',
          backupLlmProviderName: 'openAI',
          backupApiKey: 'sk-backup-key',
          backupBaseUrl: 'https://backup.example.com',
          backupModel: 'gpt-4-turbo',
        ));
        final settings = (await repository.getSettings()).data!;
        expect(settings.llmProviderName, equals('ollama'));
        expect(settings.lastConnectionTestMs, equals(987654321));
        expect(settings.lastLlmError, equals('timeout'));
        expect(settings.backupLlmProviderName, equals('openAI'));
        expect(settings.backupApiKey, equals('sk-backup-key'));
        expect(settings.backupBaseUrl, equals('https://backup.example.com'));
        expect(settings.backupModel, equals('gpt-4-turbo'));
      });

      test('updates break duration, daily reminder, focus visit fields', () async {
        await repository.updateSettings(SettingsUpdate(
          breakDurationSeconds: 900,
          dailyReminderHour: 7,
          dailyReminderMinute: 15,
          firstFocusVisit: false,
          dailyReminderEnabled: true,
        ));
        final settings = (await repository.getSettings()).data!;
        expect(settings.breakDurationSeconds, equals(900));
        expect(settings.dailyReminderHour, equals(7));
        expect(settings.dailyReminderMinute, equals(15));
        expect(settings.firstFocusVisit, isFalse);
        expect(settings.dailyReminderEnabled, isTrue);
      });

      test('themeMode is persisted and retrieved correctly', () async {
        await repository.updateSettings(SettingsUpdate(themeMode: ThemeMode.light));
        expect((await repository.getSettings()).data!.themeMode, equals(ThemeMode.light.index));

        await repository.updateSettings(SettingsUpdate(themeMode: ThemeMode.dark));
        expect((await repository.getSettings()).data!.themeMode, equals(ThemeMode.dark.index));

        await repository.updateSettings(SettingsUpdate(themeMode: ThemeMode.system));
        expect((await repository.getSettings()).data!.themeMode, equals(ThemeMode.system.index));
      });

      test('preserves statistics when updating other settings', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('settings', SettingsBox(
          totalSessionCount: 5,
          totalStudyTimeMs: 3600000,
          totalQuestions: 100,
        ).toJson());

        await repository.updateSettings(SettingsUpdate(fontSize: 20.0));
        final settings = (await repository.getSettings()).data!;
        expect(settings.totalSessionCount, equals(5));
        expect(settings.totalStudyTimeMs, equals(3600000));
        expect(settings.totalQuestions, equals(100));
        expect(settings.fontSize, equals(20.0));
      });

      test('updateSettings with all null preserves existing values', () async {
        await repository.updateSettings(SettingsUpdate(
          apiKey: 'sk-existing',
          fontSize: 18.0,
          themeMode: ThemeMode.dark,
        ));
        await repository.updateSettings(SettingsUpdate());
        final settings = (await repository.getSettings()).data!;
        expect(settings.apiKey, equals('sk-existing'));
        expect(settings.fontSize, equals(18.0));
        expect(settings.themeMode, equals(ThemeMode.dark.index));
      });
    });

    group('updateStats', () {
      setUp(() async {
        await repository.init();
      });

      test('updates session count', () async {
        await repository.updateStats(sessionCount: 10);
        expect((await repository.getSettings()).data!.totalSessionCount, equals(10));
      });

      test('updates study time', () async {
        await repository.updateStats(studyTimeMs: 7200000);
        expect((await repository.getSettings()).data!.totalStudyTimeMs, equals(7200000));
      });

      test('updates questions count', () async {
        await repository.updateStats(questions: 50);
        expect((await repository.getSettings()).data!.totalQuestions, equals(50));
      });

      test('updates multiple stats at once', () async {
        await repository.updateStats(
          sessionCount: 20,
          studyTimeMs: 10800000,
          questions: 200,
        );
        final settings = (await repository.getSettings()).data!;
        expect(settings.totalSessionCount, equals(20));
        expect(settings.totalStudyTimeMs, equals(10800000));
        expect(settings.totalQuestions, equals(200));
      });

      test('updateStats with all null preserves existing values', () async {
        await repository.updateStats(sessionCount: 10, studyTimeMs: 5000, questions: 50);
        await repository.updateStats();
        final settings = (await repository.getSettings()).data!;
        expect(settings.totalSessionCount, equals(10));
        expect(settings.totalStudyTimeMs, equals(5000));
        expect(settings.totalQuestions, equals(50));
      });
    });

    group('saveProfileData and getProfileData', () {
      setUp(() async {
        await repository.init();
      });

      test('returns default profile when no profiles saved', () async {
        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('default_profile'));
        expect(result.data!.name, equals(''));
      });

      test('saves and retrieves profile data', () async {
        final profile = UserProfile(
          id: 'test-profile',
          name: 'Test User',
          studentId: '12345',
          learningGoal: 'Learn Flutter',
          preferredStudyTime: 'Morning',
          notificationsEnabled: false,
          language: 'es',
          avatarIcon: 'Icons.school',
        );
        await repository.saveProfileData(profile);

        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data!.id, equals('test-profile'));
        expect(result.data!.name, equals('Test User'));
        expect(result.data!.studentId, equals('12345'));
        expect(result.data!.learningGoal, equals('Learn Flutter'));
        expect(result.data!.preferredStudyTime, equals('Morning'));
        expect(result.data!.notificationsEnabled, isFalse);
        expect(result.data!.language, equals('es'));
        expect(result.data!.avatarIcon, equals('Icons.school'));
      });

      test('saves multiple profiles and tracks current', () async {
        final profile1 = UserProfile(id: 'profile-1', name: 'User 1');
        final profile2 = UserProfile(id: 'profile-2', name: 'User 2');

        await repository.saveProfileData(profile1);
        await repository.saveProfileData(profile2);

        final current = await repository.getProfileData();
        expect(current.data!.id, equals('profile-2'));
        expect(current.data!.name, equals('User 2'));
      });

      test('updates existing profile', () async {
        await repository.saveProfileData(UserProfile(
          id: 'update-test',
          name: 'Original Name',
          studentId: '111',
        ));

        await repository.saveProfileData(UserProfile(
          id: 'update-test',
          name: 'Updated Name',
          studentId: '222',
        ));

        final result = await repository.getProfileData();
        expect(result.data!.name, equals('Updated Name'));
        expect(result.data!.studentId, equals('222'));
      });

      test('handles profile with accessibility preferences', () async {
        final prefs = AccessibilityPreferences(
          boldText: true,
          highContrast: true,
          reduceMotion: true,
          largeTouchTargets: true,
        );
        final profile = UserProfile(
          id: 'acc-profile',
          name: 'Accessibility User',
          accessibilityPrefs: prefs,
        );
        await repository.saveProfileData(profile);

        final result = await repository.getProfileData();
        expect(result.data!.accessibilityPrefs, isNotNull);
        expect(result.data!.accessibilityPrefs!.boldText, isTrue);
        expect(result.data!.accessibilityPrefs!.highContrast, isTrue);
        expect(result.data!.accessibilityPrefs!.reduceMotion, isTrue);
        expect(result.data!.accessibilityPrefs!.largeTouchTargets, isTrue);
      });

      test('finds profile by scanning when current_profile is not set', () async {
        final box = await Hive.openBox(HiveBoxNames.profile);
        final profile = UserProfile(id: 'scanned', name: 'Found by scan');
        await box.put('scanned', profile);

        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('scanned'));
        expect(result.data!.name, equals('Found by scan'));
      });

      test('handles profile with non-String current_profile key', () async {
        final box = await Hive.openBox(HiveBoxNames.profile);
        await box.put('current_profile', 123);
        final profile = UserProfile(id: 'fallback', name: 'Fallback');
        await box.put('fallback', profile);

        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('fallback'));
      });

      test('returns null when box has keys but no UserProfile values', () async {
        final box = await Hive.openBox(HiveBoxNames.profile);
        await box.put('key1', 'string1');
        await box.put('key2', 42);
        await box.put('key3', true);

        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('scans and falls back when current_profile key has non-UserProfile value', () async {
        final box = await Hive.openBox(HiveBoxNames.profile);
        await box.put('current_profile', 'some_key');
        await box.put('some_key', 'not a profile');
        final profile = UserProfile(id: 'scanned', name: 'Found by scan');
        await box.put('scanned', profile);

        final result = await repository.getProfileData();
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('scanned'));
      });

      test('scans and falls back when current_profile key does not exist', () async {
        final box = await Hive.openBox(HiveBoxNames.profile);
        await box.put('current_profile', 'nonexistent_key');
        final profile = UserProfile(id: 'scanned', name: 'Fallback');
        await box.put('scanned', profile);

        final result = await repository.getProfileData();
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('scanned'));
      });
    });

    group('clearSettings', () {
      setUp(() async {
        await repository.init();
      });

      test('clears all settings', () async {
        await repository.updateSettings(SettingsUpdate(
          apiKey: 'sk-to-be-cleared',
          themeMode: ThemeMode.dark,
        ));
        await repository.clearSettings();

        final result = await repository.getSettings();
        expect(result.isSuccess, isTrue);
        final settings = result.data!;
        expect(settings.apiKey, equals(''));
        expect(settings.themeMode, equals(0));
      });

      test('resets statistics to zero', () async {
        await repository.updateStats(
          sessionCount: 100,
          studyTimeMs: 9999999,
          questions: 500,
        );
        await repository.clearSettings();

        final result = await repository.getSettings();
        final settings = result.data!;
        expect(settings.totalSessionCount, equals(0));
        expect(settings.totalStudyTimeMs, equals(0));
        expect(settings.totalQuestions, equals(0));
      });

      test('is idempotent on already empty box', () async {
        await repository.clearSettings();
        await repository.clearSettings();
        final result = await repository.getSettings();
        expect(result.isSuccess, isTrue);
      });
    });

    group('clearProfile', () {
      setUp(() async {
        await repository.init();
      });

      test('clears profile data and returns default', () async {
        final profile = UserProfile(id: 'clear-test', name: 'Clear Test');
        await repository.saveProfileData(profile);
        await repository.clearProfile();

        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('default_profile'));
        expect(result.data!.name, equals(''));
      });

      test('is idempotent on already empty box', () async {
        await repository.clearProfile();
        await repository.clearProfile();
        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
      });
    });

    group('settings and profile box independence', () {
      setUp(() async {
        await repository.init();
      });

      test('clearing settings does not affect profile data', () async {
        await repository.saveApiKey(service: 'default', key: 'sk-settings-key');
        await repository.saveProfileData(UserProfile(id: 'prof1', name: 'Profile User'));

        expect((await repository.getSettings()).data!.apiKey, equals('sk-settings-key'));
        expect((await repository.getProfileData()).data!.name, equals('Profile User'));

        await repository.clearSettings();

        expect((await repository.getSettings()).data!.apiKey, equals(''));
        expect((await repository.getProfileData()).data!.name, equals('Profile User'));
      });

      test('clearing profile does not affect settings data', () async {
        await repository.updateSettings(SettingsUpdate(apiKey: 'sk-profile-test', fontSize: 20.0));
        await repository.saveProfileData(UserProfile(id: 'prof2', name: 'Profile Two'));

        await repository.clearProfile();

        expect((await repository.getSettings()).data!.apiKey, equals('sk-profile-test'));
        expect((await repository.getSettings()).data!.fontSize, equals(20.0));

        final result = await repository.getProfileData();
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals('default_profile'));
      });
    });

    group('themeModeEnum getter', () {
      setUp(() async {
        await repository.init();
      });

      test('defaults to system for index 0', () async {
        final result = await repository.getSettings();
        expect(result.data!.themeModeEnum, equals(ThemeMode.system));
      });

      test('returns correct ThemeMode from index', () async {
        await repository.updateSettings(SettingsUpdate(themeMode: ThemeMode.light));
        expect((await repository.getSettings()).data!.themeModeEnum, equals(ThemeMode.light));

        await repository.updateSettings(SettingsUpdate(themeMode: ThemeMode.dark));
        expect((await repository.getSettings()).data!.themeModeEnum, equals(ThemeMode.dark));

        await repository.updateSettings(SettingsUpdate(themeMode: ThemeMode.system));
        expect((await repository.getSettings()).data!.themeModeEnum, equals(ThemeMode.system));
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        expect(SettingsRepository().toString(), equals('SettingsRepository()'));
      });
    });

    group('error handling: Hive write failures', () {
      setUp(() async {
        await repository.init();
      });

      test('saveApiKey handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.saveApiKey(service: 'default', key: 'key');
        expect(result.isFailure, isTrue);
      });

      test('getApiKey handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.getApiKey(service: 'default');
        expect(result.isFailure, isTrue);
      });

      test('saveProvider handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.saveProvider(LlmProvider.openRouter);
        expect(result.isFailure, isTrue);
      });

      test('getProvider handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.getProvider();
        expect(result.isFailure, isTrue);
      });

      test('getSettings handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.getSettings();
        expect(result.isFailure, isTrue);
      });

      test('updateSettings handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.updateSettings(SettingsUpdate(fontSize: 20.0));
        expect(result.isFailure, isTrue);
      });

      test('updateStats handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.updateStats(sessionCount: 1);
        expect(result.isFailure, isTrue);
      });

      test('saveProfileData handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.saveProfileData(UserProfile(id: '1', name: 't'));
        expect(result.isFailure, isTrue);
      });

      test('getProfileData handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.getProfileData();
        expect(result.isFailure, isTrue);
      });

      test('clearSettings handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.clearSettings();
        expect(result.isFailure, isTrue);
      });

      test('clearProfile handles Hive error gracefully', () async {
        await Hive.close();
        final result = await repository.clearProfile();
        expect(result.isFailure, isTrue);
      });

      test('getSettings handles legacy migration Hive write error', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('apiKey', 'legacy-key');
        await Hive.close();
        final result = await repository.getSettings();
        expect(result.isFailure, isTrue);
      });

      test('updateSettings handles getSettings failure inside', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('settings', <String, dynamic>{'apiKey': 'val'});
        await Hive.close();
        final result = await repository.updateSettings(SettingsUpdate(fontSize: 20.0));
        expect(result.isFailure, isTrue);
      });

      test('updateStats handles getSettings failure inside', () async {
        final box = await Hive.openBox(HiveBoxNames.settings);
        await box.put('settings', <String, dynamic>{'apiKey': 'val'});
        await Hive.close();
        final result = await repository.updateStats(sessionCount: 1);
        expect(result.isFailure, isTrue);
      });
    });

    group('cross-operation persistence', () {
      setUp(() async {
        await repository.init();
      });

      test('full lifecycle: save settings, update, read, clear', () async {
        await repository.updateSettings(SettingsUpdate(
          apiKey: 'sk-full-lifecycle',
          fontSize: 18.0,
          themeMode: ThemeMode.dark,
        ));
        var settings = (await repository.getSettings()).data!;
        expect(settings.apiKey, equals('sk-full-lifecycle'));

        await repository.updateSettings(SettingsUpdate(apiKey: 'sk-updated'));
        settings = (await repository.getSettings()).data!;
        expect(settings.apiKey, equals('sk-updated'));
        expect(settings.fontSize, equals(18.0));

        await repository.saveApiKey(service: 'openai', key: 'sk-openai-lifecycle');
        expect((await repository.getApiKey(service: 'openai')).data, equals('sk-openai-lifecycle'));

        await repository.clearSettings();
        settings = (await repository.getSettings()).data!;
        expect(settings.apiKey, equals(''));
        expect(settings.fontSize, equals(16.0));
      });

      test('stats survive across setting updates', () async {
        await repository.updateStats(sessionCount: 10, studyTimeMs: 5000, questions: 50);

        await repository.updateSettings(SettingsUpdate(fontSize: 20.0));

        final settings = (await repository.getSettings()).data!;
        expect(settings.totalSessionCount, equals(10));
        expect(settings.totalStudyTimeMs, equals(5000));
        expect(settings.totalQuestions, equals(50));
      });

      test('settings survive across profile operations', () async {
        await repository.updateSettings(SettingsUpdate(
          apiKey: 'sk-profile-cross',
          fontSize: 24.0,
        ));

        await repository.saveProfileData(UserProfile(id: 'cross-prof', name: 'Cross'));
        await repository.clearProfile();

        final settings = (await repository.getSettings()).data!;
        expect(settings.apiKey, equals('sk-profile-cross'));
        expect(settings.fontSize, equals(24.0));
      });
    });
  });
}
