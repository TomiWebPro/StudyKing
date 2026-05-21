import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';

void main() {
  group('SettingsBox.copyWith', () {
    final original = SettingsBox(
      apiKey: 'sk-original',
      apiBaseUrl: 'https://original.com',
      selectedModel: 'gpt-4',
      themeMode: ThemeMode.dark.index,
      fontSize: 18.0,
      totalSessionCount: 10,
      totalStudyTimeMs: 50000,
      totalQuestions: 100,
      studyRemindersEnabled: false,
      requestTimeoutSeconds: 60,
      sessionDurationMinutes: 45,
      highContrastEnabled: true,
      largeTouchTargets: true,
      reduceMotion: true,
      revisionRemindersEnabled: false,
      lessonNotificationsEnabled: false,
      overworkAlertsEnabled: false,
      planAdjustmentNotificationsEnabled: false,
    );

    test('copyWith with all null preserves original', () {
      final copy = original.copyWith();
      expect(copy.apiKey, original.apiKey);
      expect(copy.apiBaseUrl, original.apiBaseUrl);
      expect(copy.selectedModel, original.selectedModel);
      expect(copy.themeMode, original.themeMode);
      expect(copy.fontSize, original.fontSize);
      expect(copy.studyRemindersEnabled, original.studyRemindersEnabled);
      expect(copy.requestTimeoutSeconds, original.requestTimeoutSeconds);
      expect(copy.sessionDurationMinutes, original.sessionDurationMinutes);
      expect(copy.highContrastEnabled, original.highContrastEnabled);
      expect(copy.revisionRemindersEnabled, original.revisionRemindersEnabled);
    });

    test('copyWith updates apiKey only', () {
      final copy = original.copyWith(apiKey: 'sk-new');
      expect(copy.apiKey, 'sk-new');
      expect(copy.apiBaseUrl, original.apiBaseUrl);
      expect(copy.selectedModel, original.selectedModel);
    });

    test('copyWith updates apiBaseUrl only', () {
      final copy = original.copyWith(apiBaseUrl: 'https://new.com');
      expect(copy.apiBaseUrl, 'https://new.com');
      expect(copy.apiKey, original.apiKey);
    });

    test('copyWith updates selectedModel only', () {
      final copy = original.copyWith(selectedModel: 'claude-3');
      expect(copy.selectedModel, 'claude-3');
      expect(copy.apiKey, original.apiKey);
    });

    test('copyWith updates themeMode via enum', () {
      final copy = original.copyWith(themeModeEnum: ThemeMode.light);
      expect(copy.themeMode, ThemeMode.light.index);
      expect(copy.fontSize, original.fontSize);
    });

    test('copyWith updates fontSize only', () {
      final copy = original.copyWith(fontSize: 24.0);
      expect(copy.fontSize, 24.0);
      expect(copy.themeMode, original.themeMode);
    });

    test('copyWith updates integer fields', () {
      final copy = original.copyWith(
        totalSessionCount: 20,
        totalStudyTimeMs: 100000,
        totalQuestions: 200,
        requestTimeoutSeconds: 120,
        sessionDurationMinutes: 60,
      );
      expect(copy.totalSessionCount, 20);
      expect(copy.totalStudyTimeMs, 100000);
      expect(copy.totalQuestions, 200);
      expect(copy.requestTimeoutSeconds, 120);
      expect(copy.sessionDurationMinutes, 60);
    });

    test('copyWith updates boolean toggles', () {
      final copy = original.copyWith(
        studyRemindersEnabled: true,
        highContrastEnabled: false,
        largeTouchTargets: false,
        reduceMotion: false,
        revisionRemindersEnabled: true,
        lessonNotificationsEnabled: true,
        overworkAlertsEnabled: true,
        planAdjustmentNotificationsEnabled: true,
      );
      expect(copy.studyRemindersEnabled, isTrue);
      expect(copy.highContrastEnabled, isFalse);
      expect(copy.largeTouchTargets, isFalse);
      expect(copy.reduceMotion, isFalse);
      expect(copy.revisionRemindersEnabled, isTrue);
      expect(copy.lessonNotificationsEnabled, isTrue);
      expect(copy.overworkAlertsEnabled, isTrue);
      expect(copy.planAdjustmentNotificationsEnabled, isTrue);
    });

    test('copyWith with zero values updates correctly', () {
      final copy = original.copyWith(
        apiKey: '',
        fontSize: 0.0,
        totalSessionCount: 0,
        studyRemindersEnabled: false,
        requestTimeoutSeconds: 0,
      );
      expect(copy.apiKey, '');
      expect(copy.fontSize, 0.0);
      expect(copy.totalSessionCount, 0);
      expect(copy.studyRemindersEnabled, isFalse);
      expect(copy.requestTimeoutSeconds, 0);
    });
  });

  group('SettingsBox.fromJson type edge cases', () {
    test('fromJson with string apiKey as non-string', () {
      final restored = SettingsBox.fromJson({'apiKey': 12345});
      expect(restored.apiKey, '');
    });

    test('fromJson with apiBaseUrl as non-string', () {
      final restored = SettingsBox.fromJson({'apiBaseUrl': true});
      expect(restored.apiBaseUrl, 'https://openrouter.ai/api/v1');
    });

    test('fromJson with selectedModel as non-string', () {
      final restored = SettingsBox.fromJson({'selectedModel': 42});
      expect(restored.selectedModel, '');
    });

    test('fromJson with studyRemindersEnabled as non-bool string', () {
      final restored = SettingsBox.fromJson({'studyRemindersEnabled': 'yes'});
      expect(restored.studyRemindersEnabled, isTrue);
    });

    test('fromJson with studyRemindersEnabled as non-bool int', () {
      final restored = SettingsBox.fromJson({'studyRemindersEnabled': 1});
      expect(restored.studyRemindersEnabled, isTrue);
    });

    test('fromJson with highContrastEnabled as non-bool string', () {
      final restored = SettingsBox.fromJson({'highContrastEnabled': 'true'});
      expect(restored.highContrastEnabled, isFalse);
    });

    test('fromJson with largeTouchTargets as non-bool int', () {
      final restored = SettingsBox.fromJson({'largeTouchTargets': 0});
      expect(restored.largeTouchTargets, isFalse);
    });

    test('fromJson with reduceMotion as non-bool null', () {
      final restored = SettingsBox.fromJson({'reduceMotion': null});
      expect(restored.reduceMotion, isFalse);
    });

    test('fromJson with revisionRemindersEnabled as non-bool string', () {
      final restored = SettingsBox.fromJson({'revisionRemindersEnabled': 'no'});
      expect(restored.revisionRemindersEnabled, isTrue);
    });

    test('fromJson with lessonNotificationsEnabled as non-bool', () {
      final restored = SettingsBox.fromJson({'lessonNotificationsEnabled': {}});
      expect(restored.lessonNotificationsEnabled, isTrue);
    });

    test('fromJson with overworkAlertsEnabled as non-bool', () {
      final restored = SettingsBox.fromJson({'overworkAlertsEnabled': []});
      expect(restored.overworkAlertsEnabled, isTrue);
    });

    test('fromJson with notification fields as null defaults to true', () {
      final restored = SettingsBox.fromJson({
        'revisionRemindersEnabled': null,
        'lessonNotificationsEnabled': null,
        'overworkAlertsEnabled': null,
        'planAdjustmentNotificationsEnabled': null,
      });
      expect(restored.revisionRemindersEnabled, isTrue);
      expect(restored.lessonNotificationsEnabled, isTrue);
      expect(restored.overworkAlertsEnabled, isTrue);
      expect(restored.planAdjustmentNotificationsEnabled, isTrue);
    });

    test('fromJson with accessibility fields as null defaults to false', () {
      final restored = SettingsBox.fromJson({
        'highContrastEnabled': null,
        'largeTouchTargets': null,
        'reduceMotion': null,
      });
      expect(restored.highContrastEnabled, isFalse);
      expect(restored.largeTouchTargets, isFalse);
      expect(restored.reduceMotion, isFalse);
    });
  });

  group('SettingsBox serialization round-trip', () {
    test('round-trip preserves all fields with notification defaults reversed', () {
      final original = SettingsBox(
        apiKey: 'sk-test',
        apiBaseUrl: 'https://test.api.com',
        selectedModel: 'test-model',
        themeMode: ThemeMode.light.index,
        fontSize: 20.0,
        totalSessionCount: 5,
        totalStudyTimeMs: 3600000,
        totalQuestions: 50,
        studyRemindersEnabled: false,
        requestTimeoutSeconds: 180,
        sessionDurationMinutes: 60,
        highContrastEnabled: true,
        largeTouchTargets: true,
        reduceMotion: true,
        revisionRemindersEnabled: false,
        lessonNotificationsEnabled: false,
        overworkAlertsEnabled: false,
        planAdjustmentNotificationsEnabled: false,
      );
      final json = original.toJson();
      final restored = SettingsBox.fromJson(json);
      expect(restored.apiKey, original.apiKey);
      expect(restored.highContrastEnabled, isTrue);
      expect(restored.largeTouchTargets, isTrue);
      expect(restored.reduceMotion, isTrue);
      expect(restored.revisionRemindersEnabled, isFalse);
      expect(restored.lessonNotificationsEnabled, isFalse);
      expect(restored.overworkAlertsEnabled, isFalse);
      expect(restored.planAdjustmentNotificationsEnabled, isFalse);
    });
  });

  group('SettingsBox toString', () {
    test('toString masks api key and shows theme and font size', () {
      final settings = SettingsBox(
        apiKey: 'some-secret-key',
        themeMode: ThemeMode.dark.index,
        fontSize: 18.0,
        highContrastEnabled: true,
      );
      final str = settings.toString();
      expect(str, contains('(hidden)'));
      expect(str, contains('ThemeMode.dark'));
      expect(str, contains('18px'));
      expect(str, contains('highContrast: true'));
    });
  });
}
