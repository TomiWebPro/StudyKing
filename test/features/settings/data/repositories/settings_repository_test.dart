import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'settings_repository_test_helper.dart';

abstract class MockSettingsRepository {
  Future<void> init();
  Future<SettingsBox> getSettings();
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
  });
  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  });
  Future<void> saveApiKey({required String service, required String key});
  Future<String?> getApiKey({required String service});
  Future<void> saveProfileData(UserProfile profile);
  Future<UserProfile?> getProfileData();
  Future<void> clearSettings();
  Future<void> clearProfile();
}

class InMemorySettingsRepository implements MockSettingsRepository {
  final Map<String, dynamic> _settings = {};
  final Map<String, dynamic> _profile = {};
  bool _initialized = false;

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SettingsRepository not initialized');
    }
  }

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<SettingsBox> getSettings() async {
    _ensureInitialized();
    return SettingsBox(
      apiKey: _settings['apiKey'] ?? '',
      apiBaseUrl: _settings['apiBaseUrl'] ?? 'https://openrouter.ai/api/v1',
      selectedModel: _settings['selectedModel'] ?? '',
      themeMode: _settings['themeMode'] ?? 0,
      fontSize: (_settings['fontSize'] as double?) ?? 16.0,
      totalSessionCount: _settings['totalSessionCount'] ?? 0,
      totalStudyTimeMs: _settings['totalStudyTimeMs'] ?? 0,
      totalQuestions: _settings['totalQuestions'] ?? 0,
      studyRemindersEnabled: _settings['studyRemindersEnabled'] ?? true,
      requestTimeoutSeconds: _settings['requestTimeoutSeconds'] ?? 120,
      sessionDurationMinutes: _settings['sessionDurationMinutes'] ?? 30,
      highContrastEnabled: _settings['highContrastEnabled'] ?? false,
      largeTouchTargets: _settings['largeTouchTargets'] ?? false,
      reduceMotion: _settings['reduceMotion'] ?? false,
      revisionRemindersEnabled: _settings['revisionRemindersEnabled'] ?? true,
      lessonNotificationsEnabled: _settings['lessonNotificationsEnabled'] ?? true,
      overworkAlertsEnabled: _settings['overworkAlertsEnabled'] ?? true,
      planAdjustmentNotificationsEnabled: _settings['planAdjustmentNotificationsEnabled'] ?? true,
    );
  }

  @override
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
    _ensureInitialized();
    final current = await getSettings();

    _settings['apiKey'] = apiKey ?? current.apiKey;
    _settings['apiBaseUrl'] = apiBaseUrl ?? current.apiBaseUrl;
    _settings['selectedModel'] = selectedModel ?? current.selectedModel;
    _settings['themeMode'] = themeMode?.index ?? current.themeMode;
    _settings['fontSize'] = fontSize ?? current.fontSize;
    _settings['studyRemindersEnabled'] =
        studyRemindersEnabled ?? current.studyRemindersEnabled;
    _settings['requestTimeoutSeconds'] =
        requestTimeoutSeconds ?? current.requestTimeoutSeconds;
    _settings['sessionDurationMinutes'] =
        sessionDurationMinutes ?? current.sessionDurationMinutes;
    _settings['highContrastEnabled'] =
        highContrastEnabled ?? current.highContrastEnabled;
    _settings['largeTouchTargets'] =
        largeTouchTargets ?? current.largeTouchTargets;
    _settings['reduceMotion'] =
        reduceMotion ?? current.reduceMotion;
    _settings['revisionRemindersEnabled'] =
        revisionRemindersEnabled ?? current.revisionRemindersEnabled;
    _settings['lessonNotificationsEnabled'] =
        lessonNotificationsEnabled ?? current.lessonNotificationsEnabled;
    _settings['overworkAlertsEnabled'] =
        overworkAlertsEnabled ?? current.overworkAlertsEnabled;
    _settings['planAdjustmentNotificationsEnabled'] =
        planAdjustmentNotificationsEnabled ?? current.planAdjustmentNotificationsEnabled;
  }

  @override
  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    _ensureInitialized();
    final current = await getSettings();
    _settings['totalSessionCount'] = sessionCount ?? current.totalSessionCount;
    _settings['totalStudyTimeMs'] = studyTimeMs ?? current.totalStudyTimeMs;
    _settings['totalQuestions'] = questions ?? current.totalQuestions;
  }

  @override
  Future<void> saveApiKey({
    required String service,
    required String key,
  }) async {
    _ensureInitialized();
    _settings['apiKey'] = key;
    if (service != 'default') {
      _settings['apiKey_$service'] = key;
    }
  }

  @override
  Future<String?> getApiKey({required String service}) async {
    _ensureInitialized();
    if (service == 'default') {
      return _settings['apiKey'];
    } else {
      return _settings['apiKey_$service'];
    }
  }

  @override
  Future<void> saveProfileData(UserProfile profile) async {
    _ensureInitialized();
    _profile[profile.id] = profile;
    _profile['current_profile'] = profile.id;
  }

  @override
  Future<UserProfile?> getProfileData() async {
    _ensureInitialized();
    final currentId = _profile['current_profile'];
    if (currentId is String) {
      final profile = _profile[currentId];
      if (profile is UserProfile) return profile;
    }

    if (_profile.isEmpty) {
      return UserProfile(id: 'default_profile', name: '');
    }

    for (final key in _profile.keys) {
      final value = _profile[key];
      if (value is UserProfile) {
        _profile['current_profile'] = value.id;
        return value;
      }
    }

    return null;
  }

  @override
  Future<void> clearSettings() async {
    _ensureInitialized();
    _settings.clear();
  }

  @override
  Future<void> clearProfile() async {
    _ensureInitialized();
    _profile.clear();
  }
}

void main() {
  sharedUninitializedTests();

  group('SettingsRepository construction', () {
    test('constructor creates new instances (singleton removed)', () {
      final a = SettingsRepository();
      final b = SettingsRepository();
      expect(identical(a, b), isFalse);
    });
  });

  group('InMemorySettingsRepository', () {
    late InMemorySettingsRepository repository;

    setUp(() async {
      repository = InMemorySettingsRepository();
      await repository.init();
    });

    sharedSettingsRepositoryTests(
      createInitialized: () => repository,
      createUninitialized: () => InMemorySettingsRepository(),
      label: 'InMemorySettingsRepository',
    );

    group('getProfileData edge cases', () {
      test('returns default profile when no profiles saved', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('default_profile'));
        expect(result.name, equals(''));
      });

      test('returns null when only non-profile keys exist', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        repo._profile['some_key'] = 'some_value';
        final result = await repo.getProfileData();
        expect(result, isNull);
      });

      test('finds profile by scanning when current_profile is not set', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        final profile = UserProfile(id: 'scanned', name: 'Found by scan');
        repo._profile['scanned'] = profile;
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('scanned'));
        expect(result.name, equals('Found by scan'));
      });

      test('handles profile with non-String current_profile key', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        repo._profile['current_profile'] = 123;
        final profile = UserProfile(id: 'fallback', name: 'Fallback');
        repo._profile['fallback'] = profile;
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('fallback'));
      });

      test('returns null when box has keys but no UserProfile values', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        repo._profile['key1'] = 'string1';
        repo._profile['key2'] = 42;
        repo._profile['key3'] = true;
        final result = await repo.getProfileData();
        expect(result, isNull);
      });

      test('fallback profile when current_profile key has non-UserProfile value', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        repo._profile['current_profile'] = 'some_key';
        repo._profile['some_key'] = 'not a profile';
        final profile = UserProfile(id: 'scanned', name: 'Found by scan');
        repo._profile['scanned'] = profile;
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('scanned'));
      });

      test('fallback profile when current_profile key does not exist', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        repo._profile['current_profile'] = 'nonexistent_key';
        final profile = UserProfile(id: 'scanned', name: 'Fallback');
        repo._profile['scanned'] = profile;
        final result = await repo.getProfileData();
        expect(result, isNotNull);
        expect(result!.id, equals('scanned'));
      });
    });

    group('settings persistence across operations', () {
      test('preserves all settings after multiple updates', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
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
        final repo = InMemorySettingsRepository();
        await repo.init();
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
        final repo = InMemorySettingsRepository();
        await repo.init();
        await repo.clearProfile();
        await repo.clearProfile();
        final result = await repo.getProfileData();
        expect(result, isNotNull);
      });

      test('clearSettings on already empty box does not throw', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        await repo.clearSettings();
        await repo.clearSettings();
        final settings = await repo.getSettings();
        expect(settings.apiKey, equals(''));
        expect(settings.fontSize, equals(16.0));
      });
    });

    group('settings and profile box independence', () {
      test('clearing settings does not affect profile data', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
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
        final repo = InMemorySettingsRepository();
        await repo.init();
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
      test('saves and retrieves default key', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        await repo.saveApiKey(service: 'default', key: 'sk-default-only');
        expect(await repo.getApiKey(service: 'default'), equals('sk-default-only'));
        expect(await repo.getApiKey(service: 'other'), isNull);
      });

      test('default key is updated when custom service key is saved', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        await repo.saveApiKey(service: 'default', key: 'sk-default');
        await repo.saveApiKey(service: 'custom', key: 'sk-custom');
        expect(await repo.getApiKey(service: 'default'), equals('sk-custom'));
        expect(await repo.getApiKey(service: 'custom'), equals('sk-custom'));
      });

      test('empty string key can be saved', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
        await repo.saveApiKey(service: 'default', key: '');
        expect(await repo.getApiKey(service: 'default'), equals(''));
      });
    });

    group('updateStats with nulls', () {
      test('updateStats with all null preserves existing values', () async {
        final repo = InMemorySettingsRepository();
        await repo.init();
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
        final repo = InMemorySettingsRepository();
        await repo.init();
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

  });
}
