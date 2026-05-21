import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_spacing.dart';

void main() {
  group('AppSpacing constants', () {
    test('xxs is >= 0', () {
      expect(AppSpacing.xxs, greaterThanOrEqualTo(0));
    });

    test('xs is >= 0', () {
      expect(AppSpacing.xs, greaterThanOrEqualTo(0));
    });

    test('sm is >= 0', () {
      expect(AppSpacing.sm, greaterThanOrEqualTo(0));
    });

    test('md is >= 0', () {
      expect(AppSpacing.md, greaterThanOrEqualTo(0));
    });

    test('lg is >= 0', () {
      expect(AppSpacing.lg, greaterThanOrEqualTo(0));
    });

    test('xl is >= 0', () {
      expect(AppSpacing.xl, greaterThanOrEqualTo(0));
    });

    test('xxl is >= 0', () {
      expect(AppSpacing.xxl, greaterThanOrEqualTo(0));
    });
  });

  group('AppSpacing gaps', () {
    test('gapXs has correct width and height', () {
      expect(AppSpacing.gapXs.width, equals(AppSpacing.xs));
      expect(AppSpacing.gapXs.height, equals(AppSpacing.xs));
    });

    test('gapSm has correct width and height', () {
      expect(AppSpacing.gapSm.width, equals(AppSpacing.sm));
      expect(AppSpacing.gapSm.height, equals(AppSpacing.sm));
    });

    test('gapMd has correct width and height', () {
      expect(AppSpacing.gapMd.width, equals(AppSpacing.md));
      expect(AppSpacing.gapMd.height, equals(AppSpacing.md));
    });

    test('gapLg has correct width and height', () {
      expect(AppSpacing.gapLg.width, equals(AppSpacing.lg));
      expect(AppSpacing.gapLg.height, equals(AppSpacing.lg));
    });

    test('gapXl has correct width and height', () {
      expect(AppSpacing.gapXl.width, equals(AppSpacing.xl));
      expect(AppSpacing.gapXl.height, equals(AppSpacing.xl));
    });
  });

  group('AppSpacing.all*', () {
    test('allXs has correct value', () {
      final edge = AppSpacing.allXs;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.xs));
      expect(edge.right, equals(AppSpacing.xs));
      expect(edge.top, equals(AppSpacing.xs));
      expect(edge.bottom, equals(AppSpacing.xs));
    });

    test('allSm has correct value', () {
      final edge = AppSpacing.allSm;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.sm));
      expect(edge.right, equals(AppSpacing.sm));
      expect(edge.top, equals(AppSpacing.sm));
      expect(edge.bottom, equals(AppSpacing.sm));
    });

    test('allMd has correct value', () {
      final edge = AppSpacing.allMd;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.md));
      expect(edge.right, equals(AppSpacing.md));
      expect(edge.top, equals(AppSpacing.md));
      expect(edge.bottom, equals(AppSpacing.md));
    });

    test('allLg has correct value', () {
      final edge = AppSpacing.allLg;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.lg));
      expect(edge.right, equals(AppSpacing.lg));
      expect(edge.top, equals(AppSpacing.lg));
      expect(edge.bottom, equals(AppSpacing.lg));
    });
  });

  group('AppSpacing symH*V*', () {
    test('symH8V4 has correct padding', () {
      final edge = AppSpacing.symH8V4;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.sm));
      expect(edge.right, equals(AppSpacing.sm));
      expect(edge.top, equals(AppSpacing.xs));
      expect(edge.bottom, equals(AppSpacing.xs));
    });

    test('symH16V8 has correct padding', () {
      final edge = AppSpacing.symH16V8;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.md));
      expect(edge.right, equals(AppSpacing.md));
      expect(edge.top, equals(AppSpacing.sm));
      expect(edge.bottom, equals(AppSpacing.sm));
    });

    test('symH16V12 has correct padding', () {
      final edge = AppSpacing.symH16V12;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.md));
      expect(edge.right, equals(AppSpacing.md));
      expect(edge.top, equals(12));
      expect(edge.bottom, equals(12));
    });

    test('symH24V12 has correct padding', () {
      final edge = AppSpacing.symH24V12;
      expect(edge, isA<EdgeInsets>());
      expect(edge.left, equals(AppSpacing.lg));
      expect(edge.right, equals(AppSpacing.lg));
      expect(edge.top, equals(12));
      expect(edge.bottom, equals(12));
    });
  });

  group('AppSpacing onlyB*', () {
    test('onlyB8 has correct bottom padding', () {
      final edge = AppSpacing.onlyB8;
      expect(edge, isA<EdgeInsets>());
      expect(edge.bottom, equals(AppSpacing.sm));
      expect(edge.top, equals(0));
      expect(edge.left, equals(0));
      expect(edge.right, equals(0));
    });

    test('onlyB16 has correct bottom padding', () {
      final edge = AppSpacing.onlyB16;
      expect(edge, isA<EdgeInsets>());
      expect(edge.bottom, equals(AppSpacing.md));
      expect(edge.top, equals(0));
      expect(edge.left, equals(0));
      expect(edge.right, equals(0));
    });
  });
}
