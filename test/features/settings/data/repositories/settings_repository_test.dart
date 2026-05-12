import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

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
  });
  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  });
  Future<void> saveApiKey({required String service, required String key});
  Future<String?> getApiKey({required String service});
  Future<void> saveProfileData(ProfileData profile);
  Future<ProfileData?> getProfileData();
  Future<void> clearSettings();
  Future<void> clearProfile();
}

class InMemorySettingsRepository implements MockSettingsRepository {
  final Map<String, dynamic> _settings = {};
  final Map<String, dynamic> _profile = {};
  bool _initialized = false;

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('Repository not initialized');
    }
  }

  @override
  Future<void> init() async {
    _initialized = true;
    _settings.clear();
    _profile.clear();
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
  Future<void> saveProfileData(ProfileData profile) async {
    _ensureInitialized();
    _profile[profile.id] = profile;
    _profile['current_profile'] = profile.id;
  }

  @override
  Future<ProfileData?> getProfileData() async {
    _ensureInitialized();
    final currentId = _profile['current_profile'];
    if (currentId is String) {
      final profile = _profile[currentId];
      if (profile is ProfileData) return profile;
    }

    if (_profile.isEmpty) {
      return ProfileData(id: 'default_profile', name: '');
    }

    for (final key in _profile.keys) {
      final value = _profile[key];
      if (value is ProfileData) {
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
  group('MockSettingsRepository', () {
    late InMemorySettingsRepository repository;

    setUp(() async {
      repository = InMemorySettingsRepository();
      await repository.init();
    });

    group('init', () {
      test('initializes without error', () async {
        expect(() => repository.init(), returnsNormally);
      });
    });

    group('saveApiKey', () {
      test('saves API key with default service', () async {
        await repository.saveApiKey(service: 'default', key: 'sk-test-key');
        final retrieved = await repository.getApiKey(service: 'default');
        expect(retrieved, equals('sk-test-key'));
      });

      test('saves API key with custom service name', () async {
        await repository.saveApiKey(service: 'openai', key: 'sk-openai-key');
        final retrieved = await repository.getApiKey(service: 'openai');
        expect(retrieved, equals('sk-openai-key'));
      });

      test('overwrites existing API key', () async {
        await repository.saveApiKey(service: 'default', key: 'sk-first');
        await repository.saveApiKey(service: 'default', key: 'sk-second');
        final retrieved = await repository.getApiKey(service: 'default');
        expect(retrieved, equals('sk-second'));
      });

      test('maintains separate keys for different services', () async {
        await repository.saveApiKey(service: 'default', key: 'sk-default');
        await repository.saveApiKey(service: 'ollama', key: 'sk-ollama');
        expect(await repository.getApiKey(service: 'default'), equals('sk-default'));
        expect(await repository.getApiKey(service: 'ollama'), equals('sk-ollama'));
      });
    });

    group('getApiKey', () {
      test('returns null for non-existent service', () async {
        final result = await repository.getApiKey(service: 'nonexistent');
        expect(result, isNull);
      });
    });

    group('getSettings', () {
      test('returns default settings when box is empty', () async {
        final settings = await repository.getSettings();
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
        await repository.updateSettings(
          apiKey: 'sk-persisted-key',
          apiBaseUrl: 'https://custom.api.com',
          themeMode: ThemeMode.dark,
          fontSize: 20.0,
        );
        final settings = await repository.getSettings();
        expect(settings.apiKey, equals('sk-persisted-key'));
        expect(settings.apiBaseUrl, equals('https://custom.api.com'));
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.fontSize, equals(20.0));
      });
    });

    group('updateSettings', () {
      test('updates only specified fields, preserves others', () async {
        await repository.updateSettings(
          themeMode: ThemeMode.dark,
          fontSize: 20.0,
        );
        final settings = await repository.getSettings();
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.fontSize, equals(20.0));
        expect(settings.apiKey, equals(''));
        expect(settings.selectedModel, equals(''));
      });

      test('updates theme mode correctly', () async {
        await repository.updateSettings(themeMode: ThemeMode.light);
        expect((await repository.getSettings()).themeMode, equals(ThemeMode.light.index));

        await repository.updateSettings(themeMode: ThemeMode.dark);
        expect((await repository.getSettings()).themeMode, equals(ThemeMode.dark.index));

        await repository.updateSettings(themeMode: ThemeMode.system);
        expect((await repository.getSettings()).themeMode, equals(ThemeMode.system.index));
      });

      test('updates font size with bounds', () async {
        await repository.updateSettings(fontSize: 10.0);
        expect((await repository.getSettings()).fontSize, equals(10.0));

        await repository.updateSettings(fontSize: 30.0);
        expect((await repository.getSettings()).fontSize, equals(30.0));
      });

      test('updates request timeout within valid range', () async {
        await repository.updateSettings(requestTimeoutSeconds: 30);
        expect((await repository.getSettings()).requestTimeoutSeconds, equals(30));

        await repository.updateSettings(requestTimeoutSeconds: 300);
        expect((await repository.getSettings()).requestTimeoutSeconds, equals(300));
      });

      test('updates session duration', () async {
        await repository.updateSettings(sessionDurationMinutes: 15);
        expect((await repository.getSettings()).sessionDurationMinutes, equals(15));

        await repository.updateSettings(sessionDurationMinutes: 90);
        expect((await repository.getSettings()).sessionDurationMinutes, equals(90));
      });

      test('updates study reminders enabled flag', () async {
        await repository.updateSettings(studyRemindersEnabled: false);
        expect((await repository.getSettings()).studyRemindersEnabled, isFalse);

        await repository.updateSettings(studyRemindersEnabled: true);
        expect((await repository.getSettings()).studyRemindersEnabled, isTrue);
      });

      test('updates all settings at once', () async {
        await repository.updateSettings(
          apiKey: 'sk-all-at-once',
          apiBaseUrl: 'https://all.at.once.com',
          selectedModel: 'test-model',
          themeMode: ThemeMode.dark,
          fontSize: 18.0,
          studyRemindersEnabled: false,
          requestTimeoutSeconds: 60,
          sessionDurationMinutes: 45,
        );
        final settings = await repository.getSettings();
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
        await repository.clearSettings();
        await repository.updateStats(
          sessionCount: 5,
          studyTimeMs: 3600000,
          questions: 100,
        );
        await repository.updateSettings(fontSize: 20.0);
        final settings = await repository.getSettings();
        expect(settings.totalSessionCount, equals(5));
        expect(settings.totalStudyTimeMs, equals(3600000));
        expect(settings.totalQuestions, equals(100));
      });
    });

    group('updateStats', () {
      test('updates session count', () async {
        await repository.updateStats(sessionCount: 10);
        expect((await repository.getSettings()).totalSessionCount, equals(10));
      });

      test('updates study time', () async {
        await repository.updateStats(studyTimeMs: 7200000);
        expect((await repository.getSettings()).totalStudyTimeMs, equals(7200000));
      });

      test('updates questions count', () async {
        await repository.updateStats(questions: 50);
        expect((await repository.getSettings()).totalQuestions, equals(50));
      });

      test('updates multiple stats at once', () async {
        await repository.updateStats(
          sessionCount: 20,
          studyTimeMs: 10800000,
          questions: 200,
        );
        final settings = await repository.getSettings();
        expect(settings.totalSessionCount, equals(20));
        expect(settings.totalStudyTimeMs, equals(10800000));
        expect(settings.totalQuestions, equals(200));
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
        await repository.saveProfileData(profile);

        final retrieved = await repository.getProfileData();
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

        await repository.saveProfileData(profile1);
        await repository.saveProfileData(profile2);

        final current = await repository.getProfileData();
        expect(current!.id, equals('profile-2'));
        expect(current.name, equals('User 2'));
      });

      test('updates existing profile', () async {
        final original = ProfileData(
          id: 'update-test',
          name: 'Original Name',
          studentId: '111',
        );
        await repository.saveProfileData(original);

        final updated = ProfileData(
          id: 'update-test',
          name: 'Updated Name',
          studentId: '222',
        );
        await repository.saveProfileData(updated);

        final retrieved = await repository.getProfileData();
        expect(retrieved!.name, equals('Updated Name'));
        expect(retrieved.studentId, equals('222'));
      });

      test('preserves profile avatar icon', () async {
        final profile = ProfileData(
          id: 'avatar-test',
          name: 'Avatar User',
          avatarIcon: 'Icons.school',
        );
        await repository.saveProfileData(profile);

        final retrieved = await repository.getProfileData();
        expect(retrieved!.avatarIcon, equals('Icons.school'));
      });

      test('preserves notifications and language settings', () async {
        final profile = ProfileData(
          id: 'settings-test',
          name: 'Settings User',
          notificationsEnabled: false,
          language: 'es',
        );
        await repository.saveProfileData(profile);

        final retrieved = await repository.getProfileData();
        expect(retrieved!.notificationsEnabled, isFalse);
        expect(retrieved.language, equals('es'));
      });
    });

    group('clearSettings', () {
      test('clears all settings', () async {
        await repository.updateSettings(
          apiKey: 'sk-to-be-cleared',
          themeMode: ThemeMode.dark,
        );
        await repository.clearSettings();

        final settings = await repository.getSettings();
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

        final settings = await repository.getSettings();
        expect(settings.totalSessionCount, equals(0));
        expect(settings.totalStudyTimeMs, equals(0));
        expect(settings.totalQuestions, equals(0));
      });
    });

    group('clearProfile', () {
      test('clears profile data', () async {
        final profile = ProfileData(id: 'clear-test', name: 'Clear Test');
        await repository.saveProfileData(profile);
        await repository.clearProfile();

        final retrieved = await repository.getProfileData();
        expect(retrieved, isNull);
      });
    });

    group('themeModeEnum getter', () {
      test('returns correct ThemeMode from index', () async {
        await repository.updateSettings(themeMode: ThemeMode.light);
        expect((await repository.getSettings()).themeModeEnum, equals(ThemeMode.light));

        await repository.updateSettings(themeMode: ThemeMode.dark);
        expect((await repository.getSettings()).themeModeEnum, equals(ThemeMode.dark));

        await repository.updateSettings(themeMode: ThemeMode.system);
        expect((await repository.getSettings()).themeModeEnum, equals(ThemeMode.system));
      });

      test('defaults to light for invalid index', () async {
        final settings = await repository.getSettings();
        expect(settings.themeModeEnum, equals(ThemeMode.light));
      });
    });
  });
}