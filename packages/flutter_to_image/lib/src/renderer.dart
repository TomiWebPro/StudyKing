import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Metadata returned alongside the PNG bytes from
/// [renderWidgetToImageResult].
@immutable
class ImageResult {
  /// PNG-encoded image bytes.
  final Uint8List pngBytes;

  /// Logical size used for rendering.
  final Size size;

  /// Pixel ratio applied to the output image.
  final double pixelRatio;

  /// Locale that was active during rendering.
  final Locale locale;

  /// Text direction (LTR or RTL) that was active during rendering.
  final TextDirection textDirection;

  const ImageResult({
    required this.pngBytes,
    required this.size,
    required this.pixelRatio,
    required this.locale,
    this.textDirection = TextDirection.ltr,
  });
}

/// Default rendering size (1080×1920 — common phone portrait).
const Size kDefaultSize = Size(1080, 1920);

/// Default pixel ratio for rendered images.
const double kDefaultPixelRatio = 2.0;

/// Renders [widget] to a PNG image (`Uint8List`).
///
/// No emulator, no GPU, no network — works headlessly under
/// `flutter test` via `TestWidgetsFlutterBinding`.
///
/// The widget is wrapped internally with a `View` root (via
/// `wrapWithDefaultView`), `MediaQuery` (size, text-scale),
/// `Theme` (light/dark per [themeMode]), `Directionality`
/// (LTR by default), and an optional `Localizations` delegate
/// wrapper when [localizationsDelegates] + [supportedLocales] +
/// [locale] are supplied.
///
/// [pixelRatio] describes the scale between logical pixels and output pixels.
/// A value of `2.0` at size 375×667 produces a 750×1334 PNG.
///
/// [textDirection] controls `Directionality` for the rendered widget tree.
Future<Uint8List> renderWidgetToPng(
  Widget widget, {
  Size size = kDefaultSize,
  double pixelRatio = kDefaultPixelRatio,
  Locale? locale,
  ThemeMode themeMode = ThemeMode.system,
  double textScale = 1.0,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  List<Locale>? supportedLocales,
  Brightness? brightness,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final result = await renderWidgetToImageResult(
    widget,
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
  return result.pngBytes;
}

/// Renders [widget] to a PNG and returns [ImageResult] with metadata.
///
/// See [renderWidgetToPng] for parameter documentation.
///
/// Must be called from within a `testWidgets` callback so that the
/// `TestWidgetsFlutterBinding` is in the "in test" state.
Future<ImageResult> renderWidgetToImageResult(
  Widget widget, {
  Size size = kDefaultSize,
  double pixelRatio = kDefaultPixelRatio,
  Locale? locale,
  ThemeMode themeMode = ThemeMode.system,
  double textScale = 1.0,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  List<Locale>? supportedLocales,
  Brightness? brightness,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final boundaryKey = GlobalKey();

  // Constrain the test window so the View rendered by
  // `wrapWithDefaultView` has exactly [size] logical pixels. Without this,
  // the View defaults to the test window's physical size (~800×600 logical),
  // so a 375-wide matrix would be identical to a 1200-wide one and the
  // requested [size] would never reach the captured PNG.
  //
  // Setting devicePixelRatioTestValue also ensures MediaQuery / theme
  // lookups report the correct density so text and icons rasterise as they
  // would on a real device.
  // ignore: deprecated_member_use
  binding.window.physicalSizeTestValue = Size(
    size.width * pixelRatio,
    size.height * pixelRatio,
  );
  // ignore: deprecated_member_use
  binding.window.devicePixelRatioTestValue = pixelRatio;

  // Resolve theme data based on themeMode / brightness.
  try {
    // --- theme resolution ---
    final ThemeData themeData;
    final bool isDark;
    switch (themeMode) {
      case ThemeMode.dark:
        themeData = ThemeData.dark();
        isDark = true;
      case ThemeMode.light:
        themeData = ThemeData.light();
        isDark = false;
      case ThemeMode.system:
        isDark = brightness == Brightness.dark;
        themeData = isDark ? ThemeData.dark() : ThemeData.light();
    }

    // Build the widget tree with all necessary inherited providers.
    Widget tree = widget;

    // Localizations wrapper — only when full locale setup is provided.
    if (locale != null &&
        localizationsDelegates != null &&
        supportedLocales != null) {
      tree = Localizations(
        locale: locale,
        delegates: localizationsDelegates,
        child: tree,
      );
    }

    // Wrap the RepaintBoundary with SizedBox.fromSize so the boundary
    // receives the requested logical size as its own size (the View above
    // now renders at [size] logical pixels thanks to the window override).
    tree = SizedBox.fromSize(
      size: size,
      child: RepaintBoundary(
        key: boundaryKey,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Theme(
            data: themeData,
            child: Directionality(
              textDirection: textDirection,
              child: Center(
                child: tree,
              ),
            ),
          ),
        ),
      ),
    );

    // wrapWithDefaultView wraps the tree in a View widget, providing a
    // proper RenderView root that the render tree can attach to.
    final wrappedTree = binding.wrapWithDefaultView(tree);

    await TestAsyncUtils.guard(() {
      binding.attachRootWidget(wrappedTree);
      binding.scheduleFrame();
      return binding.pump();
    });

    // Settle: keep pumping while the widget tree schedules new frames
    // (animations, post-frame callbacks, etc.).
    await _pumpAndSettle(binding);

    // Locate the RepaintBoundary via its key and capture the image.
    final context = boundaryKey.currentContext;
    if (context == null) {
      throw StateError(
        'flutter_to_image: RepaintBoundary was not rendered. '
        'Ensure the widget tree was pumped successfully.',
      );
    }

    // ignore: use_build_context_synchronously
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        'flutter_to_image: Expected RenderRepaintBoundary but found '
        '${renderObject.runtimeType}.',
      );
    }

    // toImage / toByteData perform real engine work (picture-to-image,
    // PNG encoding) that the FakeAsync clock in flutter_test cannot drive.
    // They must run inside binding.runAsync so microtasks/timers are handled
    // by the real event-loop, preventing the test from hanging on shutdown.
    final image = await binding.runAsync<ui.Image>(() {
      return renderObject.toImage(pixelRatio: pixelRatio);
    });
    if (image == null) {
      throw StateError('flutter_to_image: RenderRepaintBoundary.toImage returned null.');
    }
    final byteData = await binding.runAsync<ByteData?>(() {
      return image.toByteData(format: ui.ImageByteFormat.png);
    });

    if (byteData == null) {
      throw StateError('flutter_to_image: Failed to encode image to PNG.');
    }

    return ImageResult(
      pngBytes: byteData.buffer.asUint8List(),
      size: size,
      pixelRatio: pixelRatio,
      locale: locale ?? const Locale('en'),
      textDirection: textDirection,
    );
  } finally {
    // Restore the test window so subsequent tests are unaffected.
    // ignore: deprecated_member_use
    binding.window.clearPhysicalSizeTestValue();
    // ignore: deprecated_member_use
    binding.window.clearDevicePixelRatioTestValue();
  }
}

/// Renders a full-screen widget to a PNG image (`Uint8List`).
///
/// Unlike [renderWidgetToPng], which wraps the widget in bare `Theme` /
/// `MediaQuery` / `Directionality`, this helper wraps [screen] in a
/// [MaterialApp] with the specified [locale], [themeMode], [textScale],
/// [localizationsDelegates], and [supportedLocales]. This matches the structure
/// used by every screen-level golden test that renders a top-level screen
/// (dashboard, planner, mentor, practice, etc.), so visual tests can render
/// full `MaterialApp`-rooted screens without hand-rolling the same boilerplate.
///
/// The [screen] widget is placed as `home` in the MaterialApp. If the screen
/// does not include its own [Scaffold], wrap it first:
///
/// ```dart
/// final png = await renderScreenToPng(
///   Scaffold(body: MyScreen()),
///   size: const Size(375, 800),
///   locale: const Locale('en'),
///   themeMode: ThemeMode.light,
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
/// );
/// ```
///
/// For dependency injection, wrap [screen] in a `ProviderScope` (or other
/// inherited-widget providers) before passing it in — `renderScreenToPng`
/// places whatever you pass as `home`, so any ancestor providers the screen
/// expects should be present in [screen] itself.
///
/// Text direction is driven by [locale] through MaterialApp's built-in
/// [Directionality] resolution.
///
/// Must be called from within a `testWidgets` callback so that the
/// `TestWidgetsFlutterBinding` is in the "in test" state.
Future<Uint8List> renderScreenToPng(
  Widget screen, {
  required Size size,
  double pixelRatio = kDefaultPixelRatio,
  required Locale locale,
  required ThemeMode themeMode,
  double textScale = 1.0,
  required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required List<Locale> supportedLocales,
}) async {
  final result = await renderScreenToImageResult(
    screen,
    size: size,
    pixelRatio: pixelRatio,
    locale: locale,
    themeMode: themeMode,
    textScale: textScale,
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
  );
  return result.pngBytes;
}

/// Renders a full-screen widget to a PNG and returns [ImageResult] with
/// metadata.
///
/// See [renderScreenToPng] for parameter documentation.
///
/// Must be called from within a `testWidgets` callback.
Future<ImageResult> renderScreenToImageResult(
  Widget screen, {
  required Size size,
  double pixelRatio = kDefaultPixelRatio,
  required Locale locale,
  required ThemeMode themeMode,
  double textScale = 1.0,
  required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required List<Locale> supportedLocales,
}) async {
  final themeData = themeMode == ThemeMode.dark
      ? ThemeData.dark()
      : ThemeData.light();

  // Build a MaterialApp root that carries the locale, theme, text-scale, and
  // localisation delegates — exactly the wrapper every screen-level golden
  // test currently hand-rolls. The [screen] is placed as `home`; callers wrap
  // it in ProviderScope / Scaffold as needed before passing it in.
  final app = MaterialApp(
    locale: locale,
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
    theme: themeData,
    darkTheme: themeData,
    themeMode: themeMode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: screen,
  );

  // Delegate to renderWidgetToImageResult for the pixel capture. We pass
  // locale/themeMode/textScale so the returned ImageResult metadata is correct.
  // The MaterialApp's own Theme/MediaQuery/Localizations override the bare
  // wrappers that renderWidgetToImageResult applies externally — this is
  // intentional and matches the existing per-screen golden test pattern.
  return renderWidgetToImageResult(
    app,
    size: size,
    pixelRatio: pixelRatio,
    locale: locale,
    themeMode: themeMode,
    textScale: textScale,
  );
}

/// Pumps frames until no more are scheduled, mirroring
/// `WidgetTester.pumpAndSettle` but operating directly on the binding.
///
/// [binding.pump] is internally wrapped in `TestAsyncUtils.guard`, so this
/// works correctly inside a `testWidgets` callback.
Future<void> _pumpAndSettle(TestWidgetsFlutterBinding binding) async {
  await binding.pump();
  int iterations = 0;
  while (binding.hasScheduledFrame && iterations < 50) {
    await binding.pump(const Duration(milliseconds: 16));
    iterations++;
  }
}
