import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/accessibility_preferences.dart';

void main() {
  group('AccessibilityPreferences', () {
    test('uses default values', () {
      final prefs = AccessibilityPreferences();

      expect(prefs.boldText, isFalse);
      expect(prefs.highContrast, isFalse);
      expect(prefs.reduceMotion, isFalse);
      expect(prefs.largeTouchTargets, isFalse);
    });

    test('sets all fields from constructor', () {
      final prefs = AccessibilityPreferences(
        boldText: true,
        highContrast: true,
        reduceMotion: true,
        largeTouchTargets: true,
      );

      expect(prefs.boldText, isTrue);
      expect(prefs.highContrast, isTrue);
      expect(prefs.reduceMotion, isTrue);
      expect(prefs.largeTouchTargets, isTrue);
    });

    test('toJson returns correct map', () {
      final prefs = AccessibilityPreferences(
        boldText: true,
        highContrast: false,
        reduceMotion: true,
        largeTouchTargets: false,
      );

      final json = prefs.toJson();

      expect(json['boldText'], isTrue);
      expect(json['highContrast'], isFalse);
      expect(json['reduceMotion'], isTrue);
      expect(json['largeTouchTargets'], isFalse);
    });

    test('fromJson parses correctly', () {
      final json = {
        'boldText': true,
        'highContrast': false,
        'reduceMotion': true,
        'largeTouchTargets': false,
      };

      final prefs = AccessibilityPreferences.fromJson(json);

      expect(prefs.boldText, isTrue);
      expect(prefs.highContrast, isFalse);
      expect(prefs.reduceMotion, isTrue);
      expect(prefs.largeTouchTargets, isFalse);
    });

    test('fromJson uses defaults for non-bool values', () {
      final json = {
        'boldText': 'not-a-bool',
        'highContrast': null,
        'reduceMotion': 123,
        'largeTouchTargets': {},
      };

      final prefs = AccessibilityPreferences.fromJson(json);

      expect(prefs.boldText, isFalse);
      expect(prefs.highContrast, isFalse);
      expect(prefs.reduceMotion, isFalse);
      expect(prefs.largeTouchTargets, isFalse);
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      final original = AccessibilityPreferences(
        boldText: true,
        highContrast: false,
        reduceMotion: true,
        largeTouchTargets: false,
      );

      final json = original.toJson();
      final restored = AccessibilityPreferences.fromJson(json);

      expect(restored.boldText, original.boldText);
      expect(restored.highContrast, original.highContrast);
      expect(restored.reduceMotion, original.reduceMotion);
      expect(restored.largeTouchTargets, original.largeTouchTargets);
    });

    test('copyWith preserves unspecified values', () {
      final original = AccessibilityPreferences(
        boldText: true,
        highContrast: true,
        reduceMotion: true,
        largeTouchTargets: true,
      );

      final copy = original.copyWith(boldText: false);

      expect(copy.boldText, isFalse);
      expect(copy.highContrast, isTrue);
      expect(copy.reduceMotion, isTrue);
      expect(copy.largeTouchTargets, isTrue);
    });

    test('toString contains all fields', () {
      final prefs = AccessibilityPreferences(boldText: true, highContrast: false);
      final str = prefs.toString();

      expect(str, contains('boldText: true'));
      expect(str, contains('highContrast: false'));
      expect(str, contains('reduceMotion: false'));
    });
  });
}
