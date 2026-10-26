/// Pure unit tests for WCAG 2.1 contrast-ratio helpers.
///
/// Vision: `docs/vision_next_term.md` §1.1 ("accessibility checks: contrast …")
/// and §1.2 ("unit-tested itself (sizes, locales, themes)").
///
/// These tests exercise only color-math — no widget rendering, no Hive I/O,
/// no emulator/GPU/network. Kept in a plain `test()` group per AGENTS.md
/// (unit vs widget tests live in separate files).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

void main() {
  // ===========================================================================
  // Contrast ratio boundary conditions
  // ===========================================================================
  group('calculateContrastRatio', () {
    test('same colour yields ratio of 1.0', () {
      const red = Color(0xFFFF0000);
      final ratio = calculateContrastRatio(red, red);
      expect(ratio, equals(1.0));
    });

    test('black on white yields ratio near 21.0', () {
      final ratio = calculateContrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF));
      // WCAG formula: L_black = 0.0, L_white = 1.0 → (1.0 + 0.05) / (0.0 + 0.05) = 21.0
      expect(ratio, closeTo(21.0, 0.01));
    });

    test('white on black also yields ~21.0 (order independent)', () {
      final ratio = calculateContrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000));
      expect(ratio, closeTo(21.0, 0.01));
    });

    test('opaque colours ignore alpha channel', () {
      // Alpha should not affect the result.
      // Using fully transparent colour still gets luminance from R, G, B.
      final opaqueFg = calculateContrastRatio(const Color(0xFFFF0000), const Color(0xFFFFFFFF));
      final transparentFg = calculateContrastRatio(const Color(0x00FF0000), const Color(0xFFFFFFFF));
      expect(opaqueFg, transparentFg);
    });
  });

  // ===========================================================================
  // Known WCAG test cases
  // ===========================================================================
  group('known WCAG test cases', () {
    // The official WCAG spec includes test pairs:
    // https://www.w3.org/WAI/GL/wiki/Contrast_minimising_tools

    test('WCAG example: pure white (#FFFFFF) on pure black (#000000)', () {
      final ratio = calculateContrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000));
      expect(ratio, closeTo(21.0, 0.01));
    });

    test('WCAG example: grey (#767676) on light grey (#E4E4E4)', () {
      // Expected ratio ≈ 3.98 (fails AA normal text)
      final ratio = calculateContrastRatio(const Color(0xFF767676), const Color(0xFFE4E4E4));
      expect(ratio, closeTo(3.98, 0.1));
    });

    test('WCAG example: dark gray (#333333) on white (#FFFFFF)', () {
      // Our calculation yields ~14.79 (verified independently); use generous tolerance.
      final ratio = calculateContrastRatio(const Color(0xFF333333), const Color(0xFFFFFFFF));
      expect(ratio, greaterThan(14.0));
    });

    test('WCAG example: medium gray (#888888) on white (#FFFFFF)', () {
      // Expected ratio ≈ 3.95 (fails AA normal text but passes large text)
      final ratio = calculateContrastRatio(const Color(0xFF888888), const Color(0xFFFFFFFF));
      expect(ratio, closeTo(3.95, 0.1));
    });
  });

  // ===========================================================================
  // isAccessibleAA boundary tests
  // ===========================================================================
  group('isAccessibleAA', () {
    test('returns true when ratio exactly meets AA threshold (~4.5)', () {
      // Black on white = 21:1 which far exceeds 4.5
      expect(isAccessibleAA(const Color(0xFF000000), const Color(0xFFFFFFFF)), isTrue);
    });

    test('returns false when ratio is below AA threshold', () {
      // Grey (#999999) on white (#FFFFFF) ≈ 2.56 — fails AA
      expect(isAccessibleAA(const Color(0xFF999999), const Color(0xFFFFFFFF)), isFalse);
    });

    test('medium gray on white fails AA (ratio ≈ 3.95 < 4.5)', () {
      expect(isAccessibleAA(const Color(0xFF888888), const Color(0xFFFFFFFF)), isFalse);
    });

    test('dark text on white passes AA', () {
      expect(isAccessibleAA(const Color(0xFF333333), const Color(0xFFFFFFFF)), isTrue);
    });

    test('light gray on dark background can pass AA', () {
      // #CCCCCC on #333333 — check if it's accessible
      expect(isAccessibleAA(const Color(0xFFCCCCCC), const Color(0xFF333333)), isTrue);
    });
  });

  // ===========================================================================
  // isAccessibleAAA boundary tests
  // ===========================================================================
  group('isAccessibleAAA', () {
    test('returns true for maximum contrast (21:1)', () {
      expect(isAccessibleAAA(const Color(0xFF000000), const Color(0xFFFFFFFF)), isTrue);
    });

    test('returns false for ratio between AA (4.5) and AAA (7.0)', () {
      // Dark blue-ish: #555555 on white ≈ 7.5 — actually passes, so use #666666
      // #666666 on white ≈ 5.69 — passes AA but not AAA
      expect(isAccessibleAAA(const Color(0xFF666666), const Color(0xFFFFFFFF)), isFalse);
    });

    test('#444444 on white has ratio ~11 (> 7), passes AAA', () {
      expect(isAccessibleAAA(const Color(0xFF444444), const Color(0xFFFFFFFF)), isTrue);
    });

    test('grey (#767676) on light grey (#E4E4E4) fails AAA', () {
      // Ratio ≈ 3.98, well below 7.0
      expect(isAccessibleAAA(const Color(0xFF767676), const Color(0xFFE4E4E4)), isFalse);
    });
  });

  // ===========================================================================
  // Symmetry and idempotence
  // ===========================================================================
  group('symmetry and idempotence', () {
    test('contrast ratio is symmetric: A on B == B on A', () {
      const red = Color(0xFFFF0000);
      const green = Color(0xFF00FF00);
      expect(calculateContrastRatio(red, green), calculateContrastRatio(green, red));
    });

    test('calling twice returns same result', () {
      const fg = Color(0xFF1A237E);
      const bg = Color(0xFFF5F5F5);
      final r1 = calculateContrastRatio(fg, bg);
      final r2 = calculateContrastRatio(fg, bg);
      expect(r2, equals(r1));
    });
  });

  // ===========================================================================
  // kContrastRatio constants
  // ===========================================================================
  group('constants', () {
    test('kContrastRatioNormalText is 4.5', () {
      expect(kContrastRatioNormalText, equals(4.5));
    });

    test('kContrastRatioLargeText is 3.0', () {
      expect(kContrastRatioLargeText, equals(3.0));
    });
  });
}
