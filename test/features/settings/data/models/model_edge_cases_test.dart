import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:studyking/features/settings/data/models/accessibility_preferences.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';

void main() {
  group('SettingsBox edge cases', () {
    group('fromJson type coercion', () {
      test('studyRemindersEnabled falls back to true for non-bool values', () {
        final settings = SettingsBox.fromJson({'studyRemindersEnabled': 0});
        expect(settings.studyRemindersEnabled, isTrue);
      });

      test('requestTimeoutSeconds parses from int-like num', () {
        final settings = SettingsBox.fromJson({'requestTimeoutSeconds': 60.0});
        expect(settings.requestTimeoutSeconds, equals(60));
      });

      test('sessionDurationMinutes parses from int-like num', () {
        final settings = SettingsBox.fromJson({'sessionDurationMinutes': 45.0});
        expect(settings.sessionDurationMinutes, equals(45));
      });

      test('fontSize parses from int', () {
        final settings = SettingsBox.fromJson({'fontSize': 14});
        expect(settings.fontSize, equals(14.0));
      });

      test('themeMode parses from double', () {
        final settings = SettingsBox.fromJson({'themeMode': 2.0});
        expect(settings.themeMode, equals(2));
      });

      test('null numeric values use defaults', () {
        final settings = SettingsBox.fromJson({
          'themeMode': null,
          'fontSize': null,
          'totalSessionCount': null,
          'requestTimeoutSeconds': null,
          'sessionDurationMinutes': null,
        });
        expect(settings.themeMode, equals(0));
        expect(settings.fontSize, equals(16.0));
        expect(settings.totalSessionCount, equals(0));
        expect(settings.requestTimeoutSeconds, equals(120));
        expect(settings.sessionDurationMinutes, equals(30));
      });

      test('missing numeric keys use defaults', () {
        final settings = SettingsBox.fromJson({});
        expect(settings.themeMode, equals(0));
        expect(settings.fontSize, equals(16.0));
        expect(settings.totalSessionCount, equals(0));
        expect(settings.requestTimeoutSeconds, equals(120));
        expect(settings.sessionDurationMinutes, equals(30));
      });

      test('non-string apiBaseUrl uses default', () {
        final settings = SettingsBox.fromJson({'apiBaseUrl': 123});
        expect(settings.apiBaseUrl, equals('https://openrouter.ai/api/v1'));
      });

      test('non-string apiKey uses default empty string', () {
        final settings = SettingsBox.fromJson({'apiKey': 123});
        expect(settings.apiKey, equals(''));
      });
    });

    group('round-trip with all fields', () {
      test('toJson and fromJson preserve all fields including booleans and ints', () {
        final original = SettingsBox(
          apiKey: 'test-key',
          apiBaseUrl: 'https://test.api.com',
          selectedModel: 'gpt-4',
          themeMode: 2,
          fontSize: 20.0,
          totalSessionCount: 10,
          totalStudyTimeMs: 5000000,
          totalQuestions: 250,
          studyRemindersEnabled: false,
          requestTimeoutSeconds: 60,
          sessionDurationMinutes: 45,
        );

        final json = original.toJson();
        final restored = SettingsBox.fromJson(json);

        expect(restored.apiKey, original.apiKey);
        expect(restored.apiBaseUrl, original.apiBaseUrl);
        expect(restored.selectedModel, original.selectedModel);
        expect(restored.themeMode, original.themeMode);
        expect(restored.fontSize, original.fontSize);
        expect(restored.totalSessionCount, original.totalSessionCount);
        expect(restored.totalStudyTimeMs, original.totalStudyTimeMs);
        expect(restored.totalQuestions, original.totalQuestions);
        expect(restored.studyRemindersEnabled, original.studyRemindersEnabled);
        expect(restored.requestTimeoutSeconds, original.requestTimeoutSeconds);
        expect(restored.sessionDurationMinutes, original.sessionDurationMinutes);
      });
    });

    group('setThemeMode', () {
      test('setThemeMode updates themeMode and themeModeEnum', () {
        final settings = SettingsBox();
        expect(settings.themeMode, equals(0));

        settings.setThemeMode(ThemeMode.dark);
        expect(settings.themeMode, equals(ThemeMode.dark.index));
        expect(settings.themeModeEnum, equals(ThemeMode.dark));

        settings.setThemeMode(ThemeMode.light);
        expect(settings.themeMode, equals(ThemeMode.light.index));

        settings.setThemeMode(ThemeMode.system);
        expect(settings.themeMode, equals(ThemeMode.system.index));
      });
    });
  });

  group('ProfileData edge cases', () {
    test('fromJson with null values for optional fields', () {
      final profile = ProfileData.fromJson({
        'id': 'test-id',
        'name': 'Test',
        'studentId': null,
        'avatarIcon': null,
        'learningGoal': null,
        'preferredStudyTime': null,
      });

      expect(profile.id, 'test-id');
      expect(profile.name, 'Test');
      expect(profile.studentId, isNull);
      expect(profile.avatarIcon, isNull);
      expect(profile.learningGoal, isNull);
      expect(profile.preferredStudyTime, isNull);
    });

    test('fromJson with missing id and name uses empty strings', () {
      final profile = ProfileData.fromJson({});
      expect(profile.id, '');
      expect(profile.name, '');
    });

    test('fromJson with non-bool notificationsEnabled defaults to true', () {
      final profile = ProfileData.fromJson({
        'id': 'test',
        'name': 'Test',
        'notificationsEnabled': 'yes',
      });
      expect(profile.notificationsEnabled, isTrue);
    });

    test('fromJson with non-string language defaults to en', () {
      final profile = ProfileData.fromJson({
        'id': 'test',
        'name': 'Test',
        'language': 123,
      });
      expect(profile.language, equals('en'));
    });

    test('round-trip preserves all fields', () {
      final original = ProfileData(
        id: 'rt-id',
        name: 'Round Trip',
        studentId: 'ST-999',
        avatarIcon: 'Icons.person',
        learningGoal: 'Master Dart',
        preferredStudyTime: 'Afternoon',
        notificationsEnabled: false,
        language: 'de',
      );

      final json = original.toJson();
      final restored = ProfileData.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.studentId, original.studentId);
      expect(restored.avatarIcon, original.avatarIcon);
      expect(restored.learningGoal, original.learningGoal);
      expect(restored.preferredStudyTime, original.preferredStudyTime);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.language, original.language);
    });
  });

  group('UserProfile edge cases', () {
    test('fromJson with non-bool notificationsEnabled defaults to true', () {
      final profile = UserProfile.fromJson({
        'id': 'test',
        'name': 'Test',
        'notificationsEnabled': 0,
      });
      expect(profile.notificationsEnabled, isTrue);
    });

    test('fromJson with non-string language defaults to en', () {
      final profile = UserProfile.fromJson({
        'id': 'test',
        'name': 'Test',
        'language': 456,
      });
      expect(profile.language, equals('en'));
    });

    test('fromJson with non-Map accessibilityPrefs defaults to null', () {
      final profile = UserProfile.fromJson({
        'id': 'test',
        'name': 'Test',
        'accessibilityPrefs': 789,
      });
      expect(profile.accessibilityPrefs, isNull);
    });

    test('fromJson with missing id and name uses empty strings', () {
      final profile = UserProfile.fromJson({});
      expect(profile.id, '');
      expect(profile.name, '');
    });

    test('fromJson with null optional fields', () {
      final profile = UserProfile.fromJson({
        'id': 'test',
        'name': 'Test',
        'studentId': null,
        'avatarUrl': null,
        'learningGoal': null,
        'preferredStudyTime': null,
      });

      expect(profile.studentId, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.learningGoal, isNull);
      expect(profile.preferredStudyTime, isNull);
    });

    test('copyWith updates only specified fields', () {
      final original = UserProfile(
        id: 'original-id',
        name: 'Original Name',
        studentId: 'ST-001',
        avatarUrl: 'https://example.com/avatar.png',
        learningGoal: 'Learn Flutter',
        preferredStudyTime: 'Morning',
        notificationsEnabled: true,
        language: 'en',
      );

      final copy = original.copyWith(name: 'Updated Name', language: 'es');

      expect(copy.id, 'original-id');
      expect(copy.name, 'Updated Name');
      expect(copy.studentId, 'ST-001');
      expect(copy.avatarUrl, 'https://example.com/avatar.png');
      expect(copy.learningGoal, 'Learn Flutter');
      expect(copy.preferredStudyTime, 'Morning');
      expect(copy.notificationsEnabled, isTrue);
      expect(copy.language, 'es');
      expect(copy.accessibilityPrefs, isNull);
    });

    test('copyWith updates all fields', () {
      final original = UserProfile(
        id: 'original-id',
        name: 'Original Name',
        studentId: null,
        avatarUrl: null,
        learningGoal: null,
        preferredStudyTime: null,
        notificationsEnabled: true,
        language: 'en',
      );

      final copy = original.copyWith(
        id: 'new-id',
        name: 'New Name',
        studentId: 'ST-999',
        avatarUrl: 'https://new.com/avatar.png',
        learningGoal: 'Master Dart',
        preferredStudyTime: 'Evening',
        notificationsEnabled: false,
        language: 'de',
        accessibilityPrefs: AccessibilityPreferences(boldText: true),
      );

      expect(copy.id, 'new-id');
      expect(copy.name, 'New Name');
      expect(copy.studentId, 'ST-999');
      expect(copy.avatarUrl, 'https://new.com/avatar.png');
      expect(copy.learningGoal, 'Master Dart');
      expect(copy.preferredStudyTime, 'Evening');
      expect(copy.notificationsEnabled, isFalse);
      expect(copy.language, 'de');
      expect(copy.accessibilityPrefs, isNotNull);
      expect(copy.accessibilityPrefs!.boldText, isTrue);
    });

    test('round-trip preserves all fields', () {
      final original = UserProfile(
        id: 'rt-id',
        name: 'Round Trip User',
        studentId: 'ST-777',
        avatarUrl: 'https://example.com/rt.png',
        learningGoal: 'Go Language',
        preferredStudyTime: 'Night',
        notificationsEnabled: false,
        language: 'fr',
        accessibilityPrefs: AccessibilityPreferences(highContrast: true),
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.studentId, original.studentId);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.learningGoal, original.learningGoal);
      expect(restored.preferredStudyTime, original.preferredStudyTime);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.language, original.language);
      expect(restored.accessibilityPrefs?.toJson(), original.accessibilityPrefs?.toJson());
    });
  });

  group('UserProfileAdapter', () {
    test('write/read round-trip', () {
      final adapter = UserProfileAdapter();
      final source = UserProfile(
        id: 'adapter-test',
        name: 'Adapter User',
        studentId: 'ST-001',
        avatarUrl: 'https://example.com/avatar.png',
        learningGoal: 'Learn Testing',
        preferredStudyTime: 'Anytime',
        notificationsEnabled: false,
        language: 'es',
        accessibilityPrefs: AccessibilityPreferences(boldText: true),
      );

      final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), TypeRegistryImpl.nullImpl);
      final restored = adapter.read(reader);

      expect(restored.id, source.id);
      expect(restored.name, source.name);
      expect(restored.studentId, source.studentId);
      expect(restored.avatarUrl, source.avatarUrl);
      expect(restored.learningGoal, source.learningGoal);
      expect(restored.preferredStudyTime, source.preferredStudyTime);
      expect(restored.notificationsEnabled, source.notificationsEnabled);
      expect(restored.language, source.language);
      expect(restored.accessibilityPrefs?.toJson(), source.accessibilityPrefs?.toJson());
    });

    test('write/read with minimal fields', () {
      final adapter = UserProfileAdapter();
      final source = UserProfile(id: 'min', name: 'Minimal');

      final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
      adapter.write(writer, source);
      final reader = BinaryReaderImpl(writer.toBytes(), TypeRegistryImpl.nullImpl);
      final restored = adapter.read(reader);

      expect(restored.id, 'min');
      expect(restored.name, 'Minimal');
      expect(restored.studentId, isNull);
      expect(restored.avatarUrl, isNull);
      expect(restored.learningGoal, isNull);
      expect(restored.preferredStudyTime, isNull);
      expect(restored.notificationsEnabled, isTrue);
      expect(restored.language, 'en');
      expect(restored.accessibilityPrefs, isNull);
    });

    test('typeId is 10', () {
      expect(UserProfileAdapter().typeId, 10);
    });

    test('hashCode and equality', () {
      expect(UserProfileAdapter().hashCode, 10.hashCode);
      expect(UserProfileAdapter() == UserProfileAdapter(), isTrue);
      expect(UserProfileAdapter().runtimeType == SettingsBoxAdapter().runtimeType, isFalse);
    });
  });
}
