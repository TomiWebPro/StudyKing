import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_radius.dart';

void main() {
  group('AppRadius constants', () {
    test('xs is positive', () {
      expect(AppRadius.xs, greaterThan(0));
    });

    test('sm is positive', () {
      expect(AppRadius.sm, greaterThan(0));
    });

    test('md is positive', () {
      expect(AppRadius.md, greaterThan(0));
    });

    test('lg is positive', () {
      expect(AppRadius.lg, greaterThan(0));
    });

    test('xl is positive', () {
      expect(AppRadius.xl, greaterThan(0));
    });
  });

  group('AppRadius.circular*', () {
    test('circularXs produces BorderRadius with xs value', () {
      final radius = AppRadius.circularXs;
      expect(radius, isA<BorderRadius>());
      expect(
        radius.resolve(TextDirection.ltr).topLeft.x,
        equals(AppRadius.xs),
      );
    });

    test('circularSm produces BorderRadius with sm value', () {
      final radius = AppRadius.circularSm;
      expect(radius, isA<BorderRadius>());
      expect(
        radius.resolve(TextDirection.ltr).topLeft.x,
        equals(AppRadius.sm),
      );
    });

    test('circularMd produces BorderRadius with md value', () {
      final radius = AppRadius.circularMd;
      expect(radius, isA<BorderRadius>());
      expect(
        radius.resolve(TextDirection.ltr).topLeft.x,
        equals(AppRadius.md),
      );
    });

    test('circularLg produces BorderRadius with lg value', () {
      final radius = AppRadius.circularLg;
      expect(radius, isA<BorderRadius>());
      expect(
        radius.resolve(TextDirection.ltr).topLeft.x,
        equals(AppRadius.lg),
      );
    });

    test('circularXl produces BorderRadius with xl value', () {
      final radius = AppRadius.circularXl;
      expect(radius, isA<BorderRadius>());
      expect(
        radius.resolve(TextDirection.ltr).topLeft.x,
        equals(AppRadius.xl),
      );
    });
  });

  group('AppRadius.rounded*', () {
    test('roundedSm is RoundedRectangleBorder with sm borderRadius', () {
      final border = AppRadius.roundedSm;
      expect(border, isA<RoundedRectangleBorder>());
      expect(
        border.borderRadius,
        equals(AppRadius.circularSm),
      );
    });

    test('roundedMd is RoundedRectangleBorder with md borderRadius', () {
      final border = AppRadius.roundedMd;
      expect(border, isA<RoundedRectangleBorder>());
      expect(
        border.borderRadius,
        equals(AppRadius.circularMd),
      );
    });

    test('roundedLg is RoundedRectangleBorder with lg borderRadius', () {
      final border = AppRadius.roundedLg;
      expect(border, isA<RoundedRectangleBorder>());
      expect(
        border.borderRadius,
        equals(AppRadius.circularLg),
      );
    });
  });
}
