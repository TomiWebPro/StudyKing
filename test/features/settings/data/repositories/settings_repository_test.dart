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

  group('SettingsRepository singleton', () {
    test('factory returns same instance', () {
      final a = SettingsRepository();
      final b = SettingsRepository();
      expect(identical(a, b), isTrue);
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
    });

  });
}
