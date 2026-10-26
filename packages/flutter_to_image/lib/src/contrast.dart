/// WCAG 2.1 accessibility contrast-ratio helpers.
///
/// Used by visual-test workflows (golden-matrix, image-diff) to verify
/// foreground/background colour pairs meet WCAG AA thresholds.
/// See `docs/vision_next_term.md` §1.1 ("accessibility checks: contrast …")
/// and `docs/development/visual-testing.md` §Accessibility checks.
library;

import 'dart:math' show pow;

import 'package:flutter/material.dart';

/// WCAG 2.1 AA contrast-ratio threshold for **normal** text (< 18.6 px).
///
/// Text below this ratio is considered inaccessible.
const double kContrastRatioNormalText = 4.5;

/// WCAG 2.1 AA contrast-ratio threshold for **large** text (≥ 18.6 px bold
/// or ≥ 24 px regular).
const double kContrastRatioLargeText = 3.0;

/// Calculates the WCAG 2.1 contrast ratio between [foreground] and
/// [background].
///
/// The result is a value from `1` (same colour → no contrast) to `21`
/// (pure white on pure black).
///
/// Per WCAG 2.1 AA, a ratio of **≥ 4.5** is required for normal text and
/// **≥ 3.0** for large text.
///
/// Each input colour's RGB components are linearised (inverse sRGB),
/// combined using the WCAG luminance formula `(R × 0.2126 + G × 0.7152 + B × 0.0722)`,
/// and then the lighter/luminance pair produces the ratio via
/// `(lighterLum + 0.05) / (darkerLum + 0.05)`.
double calculateContrastRatio(Color foreground, Color background) {
  final fgLuminance = _relativeLuminance(foreground);
  final bgLuminance = _relativeLuminance(background);

  final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
  final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}

/// Returns `true` when [foreground] meets **WCAG AA** contrast against
/// [background] for **normal** text (< 18.6 px).
bool isAccessibleAA(Color foreground, Color background) =>
    calculateContrastRatio(foreground, background) >= kContrastRatioNormalText;

/// Returns `true` when [foreground] meets **WCAG AAA** contrast against
/// [background] for **normal** text (< 18.6 px).
///
/// AAA requires a ratio of **≥ 7**.
bool isAccessibleAAA(Color foreground, Color background) =>
    calculateContrastRatio(foreground, background) >= 7.0;

// ---------------------------------------------------------------------------
// Internal helpers — all work with normalised (0–1) channel values.
// Use .r, .g, .b (the non-deprecated channel accessors) which return
// double values in the 0–1 range.
// ---------------------------------------------------------------------------

/// Linearises an sRGB channel value in [0..1] per WCAG 2.1 spec.
///
/// Values ≤ 0.04045 are divided by 12.92; larger values follow
/// `((v + 0.055) / 1.055) ^ 2.4`.
double _linearise(double value) {
  final v = value.clamp(0.0, 1.0);
  return v <= 0.04045 ? (v / 12.92) : pow(v, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  // .r, .g, .b return 0–1 range doubles (no deprecated .value needed).
  final r = _linearise(color.r);
  final g = _linearise(color.g);
  final b = _linearise(color.b);
  return r * 0.2126 + g * 0.7152 + b * 0.0722;
}
