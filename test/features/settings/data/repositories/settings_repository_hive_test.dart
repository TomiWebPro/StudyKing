import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';

void main() {
  group('SettingsRepository uninitialized', () {
    test('throws StateError when calling getSettings before init', () async {
      final repo = SettingsRepository();
      await expectLater(
        repo.getSettings(),
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'SettingsRepository not initialized')),
      );
    });

    test('throws StateError when calling saveApiKey before init', () async {
      final repo = SettingsRepository();
      await expectLater(
        repo.saveApiKey(service: 'default', key: 'key'),
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'SettingsRepository not initialized')),
      );
    });

    test('throws StateError when calling getProfileData before init', () async {
      final repo = SettingsRepository();
      await expectLater(
        repo.getProfileData(),
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'SettingsRepository not initialized')),
      );
    });
  });

  group('SettingsRepository (Hive)', () {
    late Directory dir;
    late SettingsRepository repo;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      dir = await Directory.systemTemp.createTemp('settings_hive_test_');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ProfileDataAdapter());
      }
      repo = SettingsRepository();
      await repo.init();
    });

    tearDown(() async {
      await repo.clearSettings();
      await repo.clearProfile();
    });

    group('init', () {
      test('initializes without error', () async {
        final r = SettingsRepository();
        await r.init();
        await r.clearSettings();
        await r.clearProfile();
      });
    });

    group('saveApiKey', () {
      test('saves API key with default service', () async {
        await repo.saveApiKey(service: 'default', key: 'sk-test-key');
        final retrieved = await repo.getApiKey(service: 'default');
        expect(retrieved, equals('sk-test-key'));
      });

      test('saves API key with custom service name', () async {
        await repo.saveApiKey(service: 'openai', key: 'sk-openai-key');
        final retrieved = await repo.getApiKey(service: 'openai');
        expect(retrieved, equals('sk-openai-key'));
      });

      test('default service apiKey is also saved', () async {
        await repo.saveApiKey(service: 'openai', key: 'sk-openai-key');
        final defaultKey = await repo.getApiKey(service: 'default');
        final customKey = await repo.getApiKey(service: 'openai');
        expect(defaultKey, equals('sk-openai-key'));
        expect(customKey, equals('sk-openai-key'));
      });

      test('overwrites existing API key', () async {
        await repo.saveApiKey(service: 'default', key: 'sk-first');
        await repo.saveApiKey(service: 'default', key: 'sk-second');
        final retrieved = await repo.getApiKey(service: 'default');
        expect(retrieved, equals('sk-second'));
      });

      test('service key overwrites default key when both exist', () async {
        await repo.saveApiKey(service: 'default', key: 'sk-default');
        await repo.saveApiKey(service: 'ollama', key: 'sk-ollama');
        expect(await repo.getApiKey(service: 'default'), equals('sk-ollama'));
        expect(await repo.getApiKey(service: 'ollama'), equals('sk-ollama'));
      });
    });

    group('getApiKey', () {
      test('returns null for non-existent service', () async {
        final result = await repo.getApiKey(service: 'nonexistent');
        expect(result, isNull);
      });
    });

    group('getSettings', () {
      test('returns default settings when box is empty', () async {
        await repo.clearSettings();
        final settings = await repo.getSettings();
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
        await repo.updateSettings(
          apiKey: 'sk-persisted-key',
          apiBaseUrl: 'https://custom.api.com',
          themeMode: ThemeMode.dark,
          fontSize: 20.0,
        );
        final settings = await repo.getSettings();
        expect(settings.apiKey, equals('sk-persisted-key'));
        expect(settings.apiBaseUrl, equals('https://custom.api.com'));
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.fontSize, equals(20.0));
      });
    });

    group('updateSettings', () {
      test('updates only specified fields, preserves others', () async {
        await repo.updateSettings(
          themeMode: ThemeMode.dark,
          fontSize: 20.0,
        );
        final settings = await repo.getSettings();
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.fontSize, equals(20.0));
        expect(settings.apiKey, equals(''));
        expect(settings.selectedModel, equals(''));
      });

      test('updates theme mode correctly', () async {
        await repo.updateSettings(themeMode: ThemeMode.light);
        expect((await repo.getSettings()).themeMode, equals(ThemeMode.light.index));

        await repo.updateSettings(themeMode: ThemeMode.dark);
        expect((await repo.getSettings()).themeMode, equals(ThemeMode.dark.index));

        await repo.updateSettings(themeMode: ThemeMode.system);
        expect((await repo.getSettings()).themeMode, equals(ThemeMode.system.index));
      });

      test('updates font size with bounds', () async {
        await repo.updateSettings(fontSize: 10.0);
        expect((await repo.getSettings()).fontSize, equals(10.0));

        await repo.updateSettings(fontSize: 30.0);
        expect((await repo.getSettings()).fontSize, equals(30.0));
      });

      test('updates request timeout within valid range', () async {
        await repo.updateSettings(requestTimeoutSeconds: 30);
        expect((await repo.getSettings()).requestTimeoutSeconds, equals(30));

        await repo.updateSettings(requestTimeoutSeconds: 300);
        expect((await repo.getSettings()).requestTimeoutSeconds, equals(300));
      });

      test('updates session duration', () async {
        await repo.updateSettings(sessionDurationMinutes: 15);
        expect((await repo.getSettings()).sessionDurationMinutes, equals(15));

        await repo.updateSettings(sessionDurationMinutes: 90);
        expect((await repo.getSettings()).sessionDurationMinutes, equals(90));
      });

      test('updates study reminders enabled flag', () async {
        await repo.updateSettings(studyRemindersEnabled: false);
        expect((await repo.getSettings()).studyRemindersEnabled, isFalse);

        await repo.updateSettings(studyRemindersEnabled: true);
        expect((await repo.getSettings()).studyRemindersEnabled, isTrue);
      });

      test('updates all settings at once', () async {
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
        final settings = await repo.getSettings();
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
        await repo.clearSettings();
        await repo.updateStats(
          sessionCount: 5,
          studyTimeMs: 3600000,
          questions: 100,
        );
        await repo.updateSettings(fontSize: 20.0);
        final settings = await repo.getSettings();
        expect(settings.totalSessionCount, equals(5));
        expect(settings.totalStudyTimeMs, equals(3600000));
        expect(settings.totalQuestions, equals(100));
      });
    });

    group('updateStats', () {
      test('updates session count', () async {
        await repo.updateStats(sessionCount: 10);
        expect((await repo.getSettings()).totalSessionCount, equals(10));
      });

      test('updates study time', () async {
        await repo.updateStats(studyTimeMs: 7200000);
        expect((await repo.getSettings()).totalStudyTimeMs, equals(7200000));
      });

      test('updates questions count', () async {
        await repo.updateStats(questions: 50);
        expect((await repo.getSettings()).totalQuestions, equals(50));
      });

      test('updates multiple stats at once', () async {
        await repo.updateStats(
          sessionCount: 20,
          studyTimeMs: 10800000,
          questions: 200,
        );
        final settings = await repo.getSettings();
        expect(settings.totalSessionCount, equals(20));
        expect(settings.totalStudyTimeMs, equals(10800000));
        expect(settings.totalQuestions, equals(200));
      });

      test('preserves non-stats fields when updating stats', () async {
        await repo.updateSettings(
          apiKey: 'sk-stats-test',
          fontSize: 22.0,
        );
        await repo.updateStats(sessionCount: 7);
        final settings = await repo.getSettings();
        expect(settings.apiKey, equals('sk-stats-test'));
        expect(settings.fontSize, equals(22.0));
        expect(settings.totalSessionCount, equals(7));
      });
    });

    group('saveProfileData', () {
      test('saves profile data successfully', () async {
        final profile = ProfileData(
          id: 'test-profile',
          name: 'Test User',
          studentId: '12345',
          learningGoal: 'Learn Flutter',
          preferredStudyTime: 'Morning',
        );
        await repo.saveProfileData(profile);

        final retrieved = await repo.getProfileData();
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('test-profile'));
        expect(retrieved.name, equals('Test User'));
        expect(retrieved.studentId, equals('12345'));
        expect(retrieved.learningGoal, equals('Learn Flutter'));
        expect(retrieved.preferredStudyTime, equals('Morning'));
      });

      test('saves multiple profiles and tracks current', () async {
        final profile1 = ProfileData(id: 'profile-1', name: 'User 1');
        final profile2 = ProfileData(id: 'profile-2', name: 'User 2');

        await repo.saveProfileData(profile1);
        await repo.saveProfileData(profile2);

        final current = await repo.getProfileData();
        expect(current!.id, equals('profile-2'));
        expect(current.name, equals('User 2'));
      });

      test('updates existing profile', () async {
        final original = ProfileData(
          id: 'update-test',
          name: 'Original Name',
          studentId: '111',
        );
        await repo.saveProfileData(original);

        final updated = ProfileData(
          id: 'update-test',
          name: 'Updated Name',
          studentId: '222',
        );
        await repo.saveProfileData(updated);

        final retrieved = await repo.getProfileData();
        expect(retrieved!.name, equals('Updated Name'));
        expect(retrieved.studentId, equals('222'));
      });

      test('preserves profile avatar icon', () async {
        final profile = ProfileData(
          id: 'avatar-test',
          name: 'Avatar User',
          avatarIcon: 'Icons.school',
        );
        await repo.saveProfileData(profile);

        final retrieved = await repo.getProfileData();
        expect(retrieved!.avatarIcon, equals('Icons.school'));
      });

      test('preserves notifications and language settings', () async {
        final profile = ProfileData(
          id: 'settings-test',
          name: 'Settings User',
          notificationsEnabled: false,
          language: 'es',
        );
        await repo.saveProfileData(profile);

        final retrieved = await repo.getProfileData();
        expect(retrieved!.notificationsEnabled, isFalse);
        expect(retrieved.language, equals('es'));
      });
    });

    group('clearSettings', () {
      test('clears all settings', () async {
        await repo.updateSettings(
          apiKey: 'sk-to-be-cleared',
          themeMode: ThemeMode.dark,
        );
        await repo.clearSettings();

        final settings = await repo.getSettings();
        expect(settings.apiKey, equals(''));
        expect(settings.themeMode, equals(0));
      });

      test('resets statistics to zero', () async {
        await repo.updateStats(
          sessionCount: 100,
          studyTimeMs: 9999999,
          questions: 500,
        );
        await repo.clearSettings();

        final settings = await repo.getSettings();
        expect(settings.totalSessionCount, equals(0));
        expect(settings.totalStudyTimeMs, equals(0));
        expect(settings.totalQuestions, equals(0));
      });
    });

    group('clearProfile', () {
      test('clears profile data and returns default', () async {
        final profile = ProfileData(id: 'clear-test', name: 'Clear Test');
        await repo.saveProfileData(profile);
        await repo.clearProfile();

        final retrieved = await repo.getProfileData();
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('default_profile'));
        expect(retrieved.name, equals(''));
      });
    });

    group('getProfileData edge cases', () {
      test('returns default profile when no profiles saved', () async {
        await repo.clearProfile();
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('default_profile'));
        expect(result.name, equals(''));
      });

      test('returns null when only non-profile keys exist', () async {
        await repo.clearProfile();
        final box = Hive.box('profile');
        await box.put('some_key', 'some_value');
        final result = await repo.getProfileData();
        expect(result, isNull);
      });

      test('finds profile by scanning when current_profile is not set', () async {
        await repo.clearProfile();
        final box = Hive.box('profile');
        final profile = ProfileData(id: 'scanned', name: 'Found by scan');
        await box.put('scanned', profile);
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('scanned'));
        expect(result.name, equals('Found by scan'));
      });
    });

    group('themeModeEnum getter', () {
      test('returns correct ThemeMode from index', () async {
        await repo.updateSettings(themeMode: ThemeMode.light);
        expect((await repo.getSettings()).themeModeEnum, equals(ThemeMode.light));

        await repo.updateSettings(themeMode: ThemeMode.dark);
        expect((await repo.getSettings()).themeModeEnum, equals(ThemeMode.dark));

        await repo.updateSettings(themeMode: ThemeMode.system);
        expect((await repo.getSettings()).themeModeEnum, equals(ThemeMode.system));
      });

      test('defaults to system for index 0', () async {
        final settings = await repo.getSettings();
        expect(settings.themeModeEnum, equals(ThemeMode.system));
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        expect(repo.toString(), equals('SettingsRepository()'));
      });
    });
  });
}
