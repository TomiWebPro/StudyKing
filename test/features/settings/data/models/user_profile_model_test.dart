import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/accessibility_preferences.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';

void main() {
  group('UserProfile', () {
    test('creates with required fields', () {
      final profile = UserProfile(id: '1', name: 'Alice');

      expect(profile.id, '1');
      expect(profile.name, 'Alice');
      expect(profile.studentId, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.notificationsEnabled, isTrue);
      expect(profile.language, 'en');
      expect(profile.accessibilityPrefs, isNull);
    });

    test('creates with all fields', () {
      final profile = UserProfile(
        id: '2',
        name: 'Bob',
        studentId: 'STU123',
        avatarUrl: 'https://example.com/avatar.png',
        learningGoal: 'Master IB Physics',
        preferredStudyTime: 'Evening',
        notificationsEnabled: false,
        language: 'es',
        accessibilityPrefs: AccessibilityPreferences(highContrast: true),
      );

      expect(profile.id, '2');
      expect(profile.name, 'Bob');
      expect(profile.studentId, 'STU123');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.learningGoal, 'Master IB Physics');
      expect(profile.preferredStudyTime, 'Evening');
      expect(profile.notificationsEnabled, isFalse);
      expect(profile.language, 'es');
      expect(profile.accessibilityPrefs, isNotNull);
      expect(profile.accessibilityPrefs!.highContrast, isTrue);
    });

    group('toJson', () {
      test('serializes all fields', () {
        final profile = UserProfile(
          id: '1',
          name: 'Alice',
          studentId: 'STU001',
          avatarUrl: 'https://example.com/avatar.png',
          learningGoal: 'Learn Flutter',
          preferredStudyTime: 'Morning',
          notificationsEnabled: false,
          language: 'en',
        );

        final json = profile.toJson();

        expect(json['id'], '1');
        expect(json['name'], 'Alice');
        expect(json['studentId'], 'STU001');
        expect(json['avatarUrl'], 'https://example.com/avatar.png');
        expect(json['learningGoal'], 'Learn Flutter');
        expect(json['preferredStudyTime'], 'Morning');
        expect(json['notificationsEnabled'], isFalse);
        expect(json['language'], 'en');
        expect(json['accessibilityPrefs'], isNull);
      });

      test('serializes default values', () {
        final profile = UserProfile(id: '2', name: 'Bob');
        final json = profile.toJson();

        expect(json['notificationsEnabled'], isTrue);
        expect(json['language'], 'en');
        expect(json['accessibilityPrefs'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes with all fields', () {
        final json = {
          'id': '1',
          'name': 'Alice',
          'studentId': 'STU001',
          'avatarUrl': null,
          'learningGoal': null,
          'preferredStudyTime': null,
          'notificationsEnabled': false,
          'language': 'es',
          'accessibilityPrefs': {'highContrast': true},
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, '1');
        expect(profile.name, 'Alice');
        expect(profile.studentId, 'STU001');
        expect(profile.avatarUrl, isNull);
        expect(profile.notificationsEnabled, isFalse);
        expect(profile.language, 'es');
        expect(profile.accessibilityPrefs, isNotNull);
        expect(profile.accessibilityPrefs!.highContrast, isTrue);
      });

      test('deserializes with missing fields', () {
        final json = {
          'id': '2',
          'name': 'Bob',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, '2');
        expect(profile.name, 'Bob');
        expect(profile.studentId, isNull);
        expect(profile.avatarUrl, isNull);
        expect(profile.notificationsEnabled, isTrue);
        expect(profile.language, 'en');
        expect(profile.accessibilityPrefs, isNull);
      });

      test('deserializes with wrong types', () {
        final json = {
          'id': 123,
          'name': 456,
          'notificationsEnabled': 'yes',
          'language': 789,
          'accessibilityPrefs': null,
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, '');
        expect(profile.name, '');
        expect(profile.notificationsEnabled, isTrue);
        expect(profile.language, 'en');
        expect(profile.accessibilityPrefs, isNull);
      });

      test('deserializes empty json', () {
        final json = <String, dynamic>{};
        final profile = UserProfile.fromJson(json);

        expect(profile.id, '');
        expect(profile.name, '');
        expect(profile.studentId, isNull);
        expect(profile.notificationsEnabled, isTrue);
        expect(profile.language, 'en');
        expect(profile.accessibilityPrefs, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = UserProfile(id: '1', name: 'Alice');
        final copy = original.copyWith(name: 'Alice Updated', language: 'es');

        expect(copy.id, '1');
        expect(copy.name, 'Alice Updated');
        expect(copy.language, 'es');
      });

      test('creates copy preserving original fields', () {
        final original = UserProfile(id: '1', name: 'Alice', studentId: 'STU001');
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.studentId, original.studentId);
      });

    test('preserves fields when copyWith has no arguments', () {
      final original = UserProfile(
        id: '1',
        name: 'Alice',
        studentId: 'STU001',
        avatarUrl: 'https://example.com/avatar.png',
      );
      final copy = original.copyWith();

      expect(copy.avatarUrl, 'https://example.com/avatar.png');
      expect(copy.studentId, 'STU001');
    });
    });
  });
}
