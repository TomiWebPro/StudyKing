import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/presentation/utils/session_utils.dart';

void main() {
  group('sessionIcon', () {
    for (final type in SessionType.values) {
      test('returns non-null IconData for $type', () {
        final icon = sessionIcon(type);
        expect(icon, isA<IconData>());
      });
    }

    test('focus returns timer icon', () {
      expect(sessionIcon(SessionType.focus), Icons.timer);
    });

    test('practice returns play_arrow icon', () {
      expect(sessionIcon(SessionType.practice), Icons.play_arrow);
    });

    test('tutoring returns school icon', () {
      expect(sessionIcon(SessionType.tutoring), Icons.school);
    });

    test('manual returns edit_note icon', () {
      expect(sessionIcon(SessionType.manual), Icons.edit_note);
    });
  });

  group('sessionColor', () {
    final lightTheme = ThemeData.light();
    final darkTheme = ThemeData.dark();

    for (final type in SessionType.values) {
      test('returns non-null Color for $type with light theme', () {
        final color = sessionColor(type, lightTheme);
        expect(color, isA<Color>());
      });

      test('returns non-null Color for $type with dark theme', () {
        final color = sessionColor(type, darkTheme);
        expect(color, isA<Color>());
      });
    }

    test('focus uses tertiary color', () {
      expect(
        sessionColor(SessionType.focus, lightTheme),
        lightTheme.colorScheme.tertiary,
      );
    });

    test('practice uses primary color', () {
      expect(
        sessionColor(SessionType.practice, lightTheme),
        lightTheme.colorScheme.primary,
      );
    });

    test('tutoring uses secondary color', () {
      expect(
        sessionColor(SessionType.tutoring, lightTheme),
        lightTheme.colorScheme.secondary,
      );
    });

    test('manual uses onSurfaceVariant color', () {
      expect(
        sessionColor(SessionType.manual, lightTheme),
        lightTheme.colorScheme.onSurfaceVariant,
      );
    });
  });
}
