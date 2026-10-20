import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'renderer.dart';

/// Builds a golden file path from locale, size, and theme.
typedef GoldenPathBuilder = String Function(
  Locale locale,
  Size size,
  ThemeMode theme,
);

/// Renders [widget] across a matrix of [locales] × [sizes] and returns a
/// map of golden-path → PNG bytes.
///
/// This is the convenience helper for generating the full golden matrix
/// described in `vision_next_term.md` §1.1 (locale × width × theme/light-dark).
///
/// Pass [themeMode] = `ThemeMode.light` or `ThemeMode.dark` to render a
/// single theme. For both, call twice and merge the maps.
///
/// [pathBuilder] receives the locale, size, and theme mode and returns the
/// golden file path (convention: `test/goldens/<widget>_<locale>_<width>_<theme>.png`).
Future<Map<String, Uint8List>> renderGoldenMatrix(
  Widget widget, {
  required List<Locale> locales,
  required List<Size> sizes,
  ThemeMode themeMode = ThemeMode.system,
  Brightness? brightness,
  double pixelRatio = 2.0,
  double textScale = 1.0,
  TextDirection textDirection = TextDirection.ltr,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  List<Locale>? supportedLocales,
  required GoldenPathBuilder pathBuilder,
}) async {
  final results = <String, Uint8List>{};

  for (final locale in locales) {
    for (final size in sizes) {
      final path = pathBuilder(locale, size, themeMode);
      final png = await renderWidgetToPng(
        widget,
        size: size,
        pixelRatio: pixelRatio,
        locale: locale,
        themeMode: themeMode,
        textScale: textScale,
        textDirection: textDirection,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        brightness: brightness,
      );
      results[path] = png;
    }
  }

  return results;
}

/// Renders [widget] across a matrix of [locales] × [sizes] ×
/// [themeModes] and returns a map of golden-path → PNG bytes.
///
/// This is a convenience wrapper around [renderGoldenMatrix] that
/// iterates over all requested theme modes, producing the complete
/// locale × width × theme matrix described in `vision_next_term.md` §1.1
/// in a single call — no manual merge step required.
///
/// [pathBuilder] receives the locale, size, and theme mode and returns the
/// golden file path (convention: `test/goldens/<widget>_<locale>_<width>_<theme>.png`).
Future<Map<String, Uint8List>> renderGoldenMatrixFull(
  Widget widget, {
  required List<Locale> locales,
  required List<Size> sizes,
  required List<ThemeMode> themeModes,
  Brightness? brightness,
  double pixelRatio = 2.0,
  double textScale = 1.0,
  TextDirection textDirection = TextDirection.ltr,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  List<Locale>? supportedLocales,
  required GoldenPathBuilder pathBuilder,
}) async {
  final results = <String, Uint8List>{};

  for (final themeMode in themeModes) {
    final matrix = await renderGoldenMatrix(
      widget,
      locales: locales,
      sizes: sizes,
      themeMode: themeMode,
      brightness: brightness,
      pixelRatio: pixelRatio,
      textScale: textScale,
      textDirection: textDirection,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      pathBuilder: pathBuilder,
    );
    results.addAll(matrix);
  }

  return results;
}

/// Default path builder following the convention:
/// `test/goldens/<name>_<locale>_<width>_<theme>.png`
///
/// Pass [textDirection] as [TextDirection.rtl] to append a `_rtl` suffix to the
/// path (e.g. `test/goldens/<name>_en_375_light_rtl.png`), matching the
/// convention used by RTL golden tests. When `null` or [TextDirection.ltr]
/// (the default), no direction suffix is appended — LTR is the default
/// direction and needs no token, preserving backward compatibility.
String buildGoldenPath(
  String name,
  Locale locale,
  Size size,
  ThemeMode theme, {
  TextDirection? textDirection,
}) {
  final themeName = switch (theme) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
  final directionSuffix = textDirection == TextDirection.rtl ? '_rtl' : '';
  return 'test/goldens/${name}_${locale.languageCode}_${size.width.toInt()}_$themeName$directionSuffix.png';
}

/// Path builder for [renderGoldenTextScaleSweep].
///
/// Receives the locale, size, text scale, and theme mode and returns the
/// golden file path. Use [buildGoldenPathWithTextScale] to follow the
/// conventional `test/goldens/<name>_<locale>_<width>x<textScale>_<theme>.png`
/// path.
typedef TextScaleGoldenPathBuilder = String Function(
  Locale locale,
  Size size,
  double textScale,
  ThemeMode theme,
);

/// Default path convention for a text-scale sweep:
/// `test/goldens/<name>_<locale>_<width>x<textScale>_<theme>.png`.
///
/// `<textScale>` is written with one decimal place and an `x` separator
/// (e.g. `x1.0`, `x1.5`, `x2.0`) so every scale yields a unique, sortable
/// filename, mirroring [buildGoldenPath] but extending it with the scale.
///
/// Pass [textDirection] as [TextDirection.rtl] to append a `_rtl` suffix
/// (e.g. `test/goldens/<name>_en_375x1.0_light_rtl.png`); when `null` or
/// [TextDirection.ltr] no suffix is appended (backward compatible).
String buildGoldenPathWithTextScale(
  String name,
  Locale locale,
  Size size,
  double textScale,
  ThemeMode theme, {
  TextDirection? textDirection,
}) {
  final themeName = switch (theme) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
  final scaleName = textScale.toStringAsFixed(1);
  final directionSuffix = textDirection == TextDirection.rtl ? '_rtl' : '';
  return 'test/goldens/${name}_${locale.languageCode}_${size.width.toInt()}x${scaleName}_$themeName$directionSuffix.png';
}

/// Renders [widget] across a sweep of [textScales] (keeping locale, size, and
/// theme fixed) and returns a map of golden-path -> PNG bytes.
///
/// Supports the "text-scale sweep" helper from `vision_next_term.md` §1.1: a
/// widget must stay readable and overflow-free at larger font sizes (an
/// accessibility concern). Each text scale produces a distinct PNG, so
/// regressions in text-scaling behaviour are caught by `matchesGoldenFile`.
///
/// [pathBuilder] receives the locale, size, text scale, and theme mode and
/// should return the golden file path. Use [buildGoldenPathWithTextScale] for
/// the conventional `test/goldens/<name>_<locale>_<width>x<textScale>_<theme>.png`
/// path.
///
/// Must be called from within a `testWidgets` callback so that the
/// `TestWidgetsFlutterBinding` is in the "in test" state (see
/// [renderWidgetToPng]).
Future<Map<String, Uint8List>> renderGoldenTextScaleSweep(
  Widget widget, {
  required Locale locale,
  required Size size,
  required List<double> textScales,
  ThemeMode themeMode = ThemeMode.system,
  Brightness? brightness,
  double pixelRatio = 2.0,
  TextDirection textDirection = TextDirection.ltr,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  List<Locale>? supportedLocales,
  required TextScaleGoldenPathBuilder pathBuilder,
}) async {
  final results = <String, Uint8List>{};
  if (textScales.isEmpty) {
    return results;
  }
  for (final textScale in textScales) {
    final path = pathBuilder(locale, size, textScale, themeMode);
    final png = await renderWidgetToPng(
      widget,
      size: size,
      pixelRatio: pixelRatio,
      locale: locale,
      themeMode: themeMode,
      textScale: textScale,
      textDirection: textDirection,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      brightness: brightness,
    );
    results[path] = png;
  }
  return results;
}

/// Renders a full-screen widget (wrapped in a fresh [MaterialApp] per cell)
/// across a matrix of [locales] × [sizes] for a SINGLE [themeMode] and returns
/// a map of golden-path → PNG bytes.
///
/// This is the screen-level, single-theme counterpart of
/// [renderGoldenMatrix] (widget-level), mirroring the relationship between
/// [renderGoldenMatrix] (single theme) and [renderGoldenMatrixFull] (multi
/// theme). Use it when a screen golden only needs one theme — typically
/// `ThemeMode.light` — so the matrix is `locales × sizes` rather than
/// `locales × sizes × themes`.
///
/// Like [renderScreenGoldenMatrixFull], [screenBuilder] is invoked **once per
/// cell**, producing a fresh widget tree each time. Each fresh tree is handed to
/// [renderScreenToPng], which builds its own `MaterialApp`, so `Overlay`
/// entries (used by `AppBar` `Tooltip`/`PopupMenuButton`) never collide.
///
/// Every screen placed as `home` must already be wrapped in any needed
/// `ProviderScope` / `Scaffold` ancestors by [screenBuilder] —
/// [renderScreenToPng] only adds the `MaterialApp` root.
///
/// [textDirection] is forwarded to [renderScreenToPng]; see its documentation
/// for how it overrides locale-based directionality.
///
/// Must be called from within a `testWidgets` callback so that the
/// `TestWidgetsFlutterBinding` is in the "in test" state (see
/// [renderWidgetToPng]).
Future<Map<String, Uint8List>> renderScreenGoldenMatrix(
  Widget Function(Locale locale, ThemeMode theme) screenBuilder, {
  required List<Locale> locales,
  required List<Size> sizes,
  required ThemeMode themeMode,
  Brightness? brightness,
  double pixelRatio = kDefaultPixelRatio,
  double textScale = 1.0,
  TextDirection textDirection = TextDirection.ltr,
  required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required List<Locale> supportedLocales,
  required GoldenPathBuilder pathBuilder,
}) async {
  final results = <String, Uint8List>{};

  for (final locale in locales) {
    for (final size in sizes) {
      final path = pathBuilder(locale, size, themeMode);
      final png = await renderScreenToPng(
        screenBuilder(locale, themeMode),
        size: size,
        pixelRatio: pixelRatio,
        locale: locale,
        themeMode: themeMode,
        textScale: textScale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        brightness: brightness,
        textDirection: textDirection,
      );
      results[path] = png;
    }
  }

  return results;
}

/// Renders a full-screen widget (wrapped in a fresh [MaterialApp] per cell)
/// across a matrix of [locales] × [sizes] × [themeModes] and returns a map of
/// golden-path → PNG bytes.
///
/// This is the screen-level counterpart of [renderGoldenMatrixFull]. Unlike
/// that helper — which reuses a *single* widget instance across cells (and so
/// triggers `OverlayEntry` reuse errors for `MaterialApp`-rooted screens whose
/// `AppBar` uses `Tooltip`/`PopupMenuButton`) — this function takes a
/// [screenBuilder] that is invoked **once per cell**, producing a fresh widget
/// tree each time. Each fresh tree is handed to [renderScreenToPng], which builds
/// its own `MaterialApp`, so `Overlay` entries never collide. This removes the
/// boilerplate the top-level screen golden tests currently hand-roll (see
/// `test/features/dashboard/presentation/dashboard_screen_golden_test.dart` and
/// `test/features/teaching/presentation/tutor_screen_golden_test.dart`).
///
/// Every screen placed as `home` must already be wrapped in any needed
/// `ProviderScope` / `Scaffold` ancestors by [screenBuilder] — `renderScreenToPng`
/// only adds the `MaterialApp` root.
///
/// [textDirection] is forwarded to [renderScreenToPng]; see its documentation
/// for how it overrides locale-based directionality.
///
/// Must be called from within a `testWidgets` callback so that the
/// `TestWidgetsFlutterBinding` is in the "in test" state (see
/// [renderScreenToPng]).
Future<Map<String, Uint8List>> renderScreenGoldenMatrixFull(
  Widget Function(Locale locale, ThemeMode theme) screenBuilder, {
  required List<Locale> locales,
  required List<Size> sizes,
  required List<ThemeMode> themeModes,
  Brightness? brightness,
  double pixelRatio = kDefaultPixelRatio,
  double textScale = 1.0,
  TextDirection textDirection = TextDirection.ltr,
  required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required List<Locale> supportedLocales,
  required GoldenPathBuilder pathBuilder,
}) async {
  final results = <String, Uint8List>{};

  for (final locale in locales) {
    for (final size in sizes) {
      for (final theme in themeModes) {
        final path = pathBuilder(locale, size, theme);
        final png = await renderScreenToPng(
          screenBuilder(locale, theme),
          size: size,
          pixelRatio: pixelRatio,
          locale: locale,
          themeMode: theme,
          textScale: textScale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          brightness: brightness,
          textDirection: textDirection,
        );
        results[path] = png;
      }
    }
  }

  return results;
}

/// Renders [screenBuilder] (wrapped in a fresh [MaterialApp] per cell via
/// [renderScreenToPng]) across a sweep of [textScales] and returns a map of
/// golden-path → PNG bytes.
///
/// This is the screen-level counterpart of [renderGoldenTextScaleSweep].
/// Unlike that helper — which calls [renderWidgetToPng] (bare Theme/MediaQuery,
/// no MaterialApp) — this function calls [renderScreenToPng], so each cell gets
/// a fresh `MaterialApp` root with proper Overlay, ScaffoldMessenger, and
/// Localizations. The [screenBuilder] is invoked **once per text-scale cell**,
/// producing a fresh widget tree each time; this avoids the "OverlayEntry
/// already present in a different Overlay" error when a screen's AppBar
/// contains a `Tooltip`/`PopupMenuButton`.
///
/// Every screen placed as `home` must already be wrapped in any needed
/// `ProviderScope` / `Scaffold` ancestors by [screenBuilder] —
/// [renderScreenToPng] only adds the `MaterialApp` root.
///
/// [pathBuilder] receives the locale, size, text-scale, and theme mode for each
/// cell. Use [buildGoldenPathWithTextScale] for the conventional
/// `test/goldens/<name>_<locale>_<width>x<textScale>_<theme>.png` path.
///
/// [textDirection] is forwarded to [renderScreenToPng]; see its documentation
/// for how it overrides locale-based directionality.
///
/// Must be called from within a `testWidgets` callback so that the
/// `TestWidgetsFlutterBinding` is in the "in test" state (see
/// [renderScreenToPng]).
Future<Map<String, Uint8List>> renderScreenGoldenTextScaleSweep(
  Widget Function(Locale locale, ThemeMode theme) screenBuilder, {
  required Locale locale,
  required Size size,
  required List<double> textScales,
  ThemeMode themeMode = ThemeMode.light,
  double pixelRatio = kDefaultPixelRatio,
  Brightness? brightness,
  TextDirection textDirection = TextDirection.ltr,
  required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required List<Locale> supportedLocales,
  required TextScaleGoldenPathBuilder pathBuilder,
}) async {
  final results = <String, Uint8List>{};
  if (textScales.isEmpty) {
    return results;
  }
  for (final textScale in textScales) {
    final path = pathBuilder(locale, size, textScale, themeMode);
    final png = await renderScreenToPng(
      screenBuilder(locale, themeMode),
      size: size,
      pixelRatio: pixelRatio,
      locale: locale,
      themeMode: themeMode,
      textScale: textScale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      brightness: brightness,
      textDirection: textDirection,
    );
    results[path] = png;
  }
  return results;
}
