import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'settings_repository_test_helper.dart';

SettingsRepository _freshRepo(Directory dir) {
  Hive.init(dir.path);
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(UserProfileAdapter());
  }
  final repo = SettingsRepository();
  return repo;
}

void main() {
  sharedUninitializedTests();

  group('SettingsRepository (Hive)', () {
    late Directory dir;
    late SettingsRepository repo;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      dir = await Directory.systemTemp.createTemp('settings_hive_test_');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
      repo = SettingsRepository();
      await repo.init();
    });

    tearDown(() async {
      await repo.clearSettings();
      await repo.clearProfile();
    });

    sharedSettingsRepositoryTests(
      createInitialized: () => repo,
      createUninitialized: () {
        final d = Directory.systemTemp.createTempSync('settings_hive_test_uninit_');
        final r = _freshRepo(d);
        return r;
      },
      label: 'SettingsRepository (Hive)',
    );

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
        final profile = UserProfile(id: 'scanned', name: 'Found by scan');
        await box.put('scanned', profile);
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('scanned'));
        expect(result.name, equals('Found by scan'));
      });

      test('handles non-String current_profile key', () async {
        await repo.clearProfile();
        final box = Hive.box('profile');
        await box.put('current_profile', 123);
        final profile = UserProfile(id: 'fallback', name: 'Fallback');
        await box.put('fallback', profile);
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('fallback'));
      });

      test('returns null when box has keys but no UserProfile values', () async {
        await repo.clearProfile();
        final box = Hive.box('profile');
        await box.put('key1', 'string1');
        await box.put('key2', 42);
        await box.put('key3', true);
        final result = await repo.getProfileData();
        expect(result, isNull);
      });
    });

    group('settings persistence across operations', () {
      test('preserves all settings after multiple updates', () async {
        await repo.updateSettings(apiKey: 'key1', fontSize: 18.0);
        await repo.updateSettings(apiBaseUrl: 'https://url2.com', themeMode: ThemeMode.dark);
        await repo.updateSettings(selectedModel: 'model3', studyRemindersEnabled: false);
        final settings = await repo.getSettings();
        expect(settings.apiKey, equals('key1'));
        expect(settings.apiBaseUrl, equals('https://url2.com'));
        expect(settings.selectedModel, equals('model3'));
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.fontSize, equals(18.0));
        expect(settings.studyRemindersEnabled, isFalse);
      });

      test('stats persist after updateSettings call', () async {
        await repo.updateStats(sessionCount: 10, studyTimeMs: 5000, questions: 50);
        await repo.updateSettings(fontSize: 20.0);
        final settings = await repo.getSettings();
        expect(settings.totalSessionCount, equals(10));
        expect(settings.totalStudyTimeMs, equals(5000));
        expect(settings.totalQuestions, equals(50));
        expect(settings.fontSize, equals(20.0));
      });
    });

    group('clear operations idempotency', () {
      test('clearProfile on already empty box does not throw', () async {
        await repo.clearProfile();
        await repo.clearProfile();
        final result = await repo.getProfileData();
        expect(result, isNotNull);
      });

      test('clearSettings on already empty box does not throw', () async {
        await repo.clearSettings();
        await repo.clearSettings();
        final settings = await repo.getSettings();
        expect(settings.apiKey, equals(''));
        expect(settings.fontSize, equals(16.0));
      });
    });

    group('settings and profile box independence', () {
      test('clearing settings does not affect profile data', () async {
        await repo.saveApiKey(service: 'default', key: 'sk-settings-key');
        await repo.saveProfileData(UserProfile(id: 'prof1', name: 'Profile User'));

        final settings = await repo.getSettings();
        expect(settings.apiKey, equals('sk-settings-key'));

        final profile = await repo.getProfileData();
        expect(profile!.name, equals('Profile User'));

        await repo.clearSettings();

        final settingsAfterClear = await repo.getSettings();
        expect(settingsAfterClear.apiKey, equals(''));

        final profileAfterClear = await repo.getProfileData();
        expect(profileAfterClear!.name, equals('Profile User'));
      });

      test('clearing profile does not affect settings data', () async {
        await repo.updateSettings(apiKey: 'sk-profile-test', fontSize: 20.0);
        await repo.saveProfileData(UserProfile(id: 'prof2', name: 'Profile Two'));

        await repo.clearProfile();

        final settingsAfterClear = await repo.getSettings();
        expect(settingsAfterClear.apiKey, equals('sk-profile-test'));
        expect(settingsAfterClear.fontSize, equals(20.0));

        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('default_profile'));
      });
    });

    group('saveApiKey edge cases', () {
      test('saves and retrieves default key when only default was saved', () async {
        await repo.saveApiKey(service: 'default', key: 'sk-default-only');
        expect(await repo.getApiKey(service: 'default'), equals('sk-default-only'));
        expect(await repo.getApiKey(service: 'other'), isNull);
      });

      test('default key is updated when custom service key is saved', () async {
        await repo.saveApiKey(service: 'default', key: 'sk-default');
        await repo.saveApiKey(service: 'custom', key: 'sk-custom');
        expect(await repo.getApiKey(service: 'default'), equals('sk-custom'));
        expect(await repo.getApiKey(service: 'custom'), equals('sk-custom'));
      });

      test('empty string key can be saved', () async {
        await repo.saveApiKey(service: 'default', key: '');
        expect(await repo.getApiKey(service: 'default'), equals(''));
      });
    });

    group('updateStats with nulls', () {
      test('updateStats with all null preserves existing values', () async {
        await repo.updateStats(sessionCount: 10, studyTimeMs: 5000, questions: 50);
        await repo.updateStats();
        final settings = await repo.getSettings();
        expect(settings.totalSessionCount, equals(10));
        expect(settings.totalStudyTimeMs, equals(5000));
        expect(settings.totalQuestions, equals(50));
      });
    });

    group('updateSettings with nulls', () {
      test('updateSettings with all null preserves existing values', () async {
        await repo.updateSettings(
          apiKey: 'sk-existing',
          fontSize: 18.0,
          themeMode: ThemeMode.dark,
        );
        await repo.updateSettings();
        final settings = await repo.getSettings();
        expect(settings.apiKey, equals('sk-existing'));
        expect(settings.fontSize, equals(18.0));
        expect(settings.themeMode, equals(ThemeMode.dark.index));
      });
    });

    group('getProfileData: String currentId with non-UserProfile value', () {
      test('fallback scan when current_profile points to non-UserProfile value', () async {
        await repo.clearProfile();
        final box = Hive.box('profile');
        await box.put('current_profile', 'some_key');
        await box.put('some_key', 'not a profile');
        final profile = UserProfile(id: 'scanned', name: 'Found by scan');
        await box.put('scanned', profile);
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('scanned'));
        expect(result.name, equals('Found by scan'));
      });

      test('fallback scan when current_profile points to non-existent key', () async {
        await repo.clearProfile();
        final box = Hive.box('profile');
        await box.put('current_profile', 'nonexistent_key');
        final profile = UserProfile(id: 'scanned', name: 'Fallback');
        await box.put('scanned', profile);
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('scanned'));
      });
    });
  });
}
