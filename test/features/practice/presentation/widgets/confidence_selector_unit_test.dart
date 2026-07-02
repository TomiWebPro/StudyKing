import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/confidence_selector.dart';

void main() {
  group('ConfidenceSelector', () {
    group('getConfidenceColor', () {
      test('returns error for rating 1', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(1, cs), cs.error);
      });

      test('returns tertiary for rating 2', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(2, cs), cs.tertiary);
      });

      test('returns tertiary for rating 3', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(3, cs), cs.tertiary);
      });

      test('returns primary for rating 4', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(4, cs), cs.primary);
      });

      test('returns primary for rating 5', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(5, cs), cs.primary);
      });

      test('returns onSurfaceVariant for default', () {
        const cs = ColorScheme.light();
        expect(ConfidenceSelector.getConfidenceColor(0, cs), cs.onSurfaceVariant);
      });
    });
  });
}
