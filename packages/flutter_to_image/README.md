# flutter_to_image

A small Dart/Flutter package that renders any Flutter widget to a PNG
image (`Uint8List`) headlessly — no emulator, no GPU, no network. Works
under `flutter test` by using `TestWidgetsFlutterBinding` to pump the
widget and `RenderRepaintBoundary.toImage()` to capture pixels.

## Why

Widget tests today assert `findsOneWidget` but never judge visual quality —
overflow, contrast, density, hierarchy, stale-l10n, desktop width, RTL
chevron placement. This package gives tests and agents the pixels to
optimise pixels.

## Installation

Add this package to your project via a path dependency:

```yaml
dependencies:
  flutter_to_image:
    path: packages/flutter_to_image
```

## API

### `renderWidgetToPng`

```dart
Future<Uint8List> renderWidgetToPng(
  Widget widget, {
  Size size = const Size(1080, 1920),
  double pixelRatio = 2.0,
  Locale? locale,
  ThemeMode themeMode = ThemeMode.system,
  double textScale = 1.0,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  List<Locale>? supportedLocales,
  Brightness? brightness,
  TextDirection textDirection = TextDirection.ltr,
})
```

Renders `widget` to PNG bytes. The widget is wrapped internally with a
`MediaQuery` (for size / text-scale), `Theme` (light/dark), `Directionality`
(LTR by default), and an optional `Localizations` delegate wrapper.

### `renderWidgetToImageResult`

Like `renderWidgetToPng` but returns an `ImageResult` that also carries
metadata (size, pixelRatio, locale).

### `renderScreenToPng`

Like [renderWidgetToPng] but wraps the supplied `screen` in a `MaterialApp`
with the given locale, theme, text-scale, and localisation delegates before
rendering — for screen-level golden tests that need MaterialApp context.

```dart
Future<Uint8List> renderScreenToPng(
  Widget screen, {
  required Size size,
  double pixelRatio = 2.0,
  required Locale locale,
  required ThemeMode themeMode,
  double textScale = 1.0,
  required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required List<Locale> supportedLocales,
  Brightness? brightness,
  TextDirection textDirection = TextDirection.ltr,
})
```

The `brightness` parameter resolves `ThemeMode.system` to a concrete theme
(light or dark), mirroring `renderWidgetToPng`. It is ignored when `themeMode`
is explicitly `ThemeMode.light` or `ThemeMode.dark`.

The `textDirection` parameter is applied as a `Directionality` wrapper inside
the MaterialApp's builder, overriding the locale-based directionality resolution
for screen content. This mirrors the `textDirection` on `renderWidgetToPng` and
lets you force RTL or LTR rendering independent of locale — essential for
catching RTL layout regressions (chevron placement, overflow on translated
strings, touch-target alignment).

The `screen` is placed as `home` in the MaterialApp. If it needs a `Scaffold`
ancestor that it doesn't provide itself, wrap it before passing. For
dependency injection, wrap `screen` in a `ProviderScope` first.

### `renderScreenToImageResult`

Like `renderScreenToPng` but returns an `ImageResult` that also carries
metadata (size, pixelRatio, locale, textDirection).

### Golden matrix helpers

```dart
Future<Map<String, Uint8List>> renderGoldenMatrix(
  Widget widget, {
  required List<Locale> locales,
  required List<Size> sizes,
  ThemeMode themeMode = ThemeMode.system,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  List<Locale>? supportedLocales,
  double pixelRatio = 2.0,
  double textScale = 1.0,
  String Function(Locale locale, Size size, ThemeMode themeMode) pathBuilder,
})
```

Renders the same widget across every locale × size combination and returns a
map of golden-path → PNG bytes.

### `renderGoldenMatrixFull`

Like `renderGoldenMatrix`, but accepts a list of `ThemeMode` values so the
full locale × width × theme matrix is rendered in a single call:

```dart
final goldens = await renderGoldenMatrixFull(
  widget,
  locales: [const Locale('en'), const Locale('es')],
  sizes: [const Size(375, 800), const Size(1200, 800)],
  themeModes: [ThemeMode.light, ThemeMode.dark],
  pathBuilder: (locale, size, theme) => buildGoldenPath(
    'my_widget', locale, size, theme,
  ),
);
// goldens now contains 8 entries (2×2×2).
```

### `renderScreenGoldenMatrixFull`

Screen-level counterpart of `renderGoldenMatrixFull`. Use this for a
`MaterialApp`-rooted screen across the full `en`/`es` × phone/desktop ×
light/dark matrix. Unlike `renderGoldenMatrixFull` (which reuses a single widget
instance and therefore hits `OverlayEntry`-reuse errors for screens whose
`AppBar` uses `Tooltip`/`PopupMenuButton`), this helper takes a `screenBuilder`
invoked **once per cell**, producing a fresh `MaterialApp` (and `Overlay`) each
time:

```dart
final goldens = await renderScreenGoldenMatrixFull(
  (locale, theme) => Scaffold(
    appBar: AppBar(title: Text('Demo')),
    body: MyScreen(),
  ),
  locales: [const Locale('en'), const Locale('es')],
  sizes: [const Size(375, 800), const Size(1200, 800)],
  themeModes: [ThemeMode.light, ThemeMode.dark],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  pathBuilder: (locale, size, theme) => buildGoldenPath(
    'my_screen', locale, size, theme,
  ),
);
// goldens now contains 8 entries (2×2×2).
```

### `renderGoldenTextScaleSweep`

Renders the same widget across a sweep of text scales (keeping locale, size,
and theme fixed) and returns a map of golden-path → PNG bytes:

```dart
final sweeps = await renderGoldenTextScaleSweep(
  widget,
  locale: const Locale('en'),
  size: const Size(375, 800),
  textScales: [1.0, 1.5, 2.0],
  themeMode: ThemeMode.light,
  pathBuilder: (locale, size, textScale, theme) =>
      buildGoldenPathWithTextScale('my_widget', locale, size, textScale, theme),
);
// sweeps now contains 3 entries (one per text scale).
```

### `renderScreenGoldenTextScaleSweep`

Screen-level counterpart of `renderGoldenTextScaleSweep`. Use this for a
`MaterialApp`-rooted screen across text scales. Like
`renderScreenGoldenMatrixFull`, it takes a `screenBuilder` invoked **once per
cell** to avoid `OverlayEntry`-reuse errors:

```dart
final sweeps = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => Scaffold(
    appBar: AppBar(title: Text('Demo')),
    body: MyScreen(),
  ),
  locale: const Locale('en'),
  size: const Size(375, 800),
  textScales: [1.0, 1.5, 2.0],
  themeMode: ThemeMode.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  pathBuilder: (locale, size, textScale, theme) =>
      buildGoldenPathWithTextScale('my_screen', locale, size, textScale, theme),
);
// sweeps now contains 3 entries (one per text scale).
```

### `compareImages`

Compares two PNG images pixel-by-pixel and returns an `ImageComparisonResult`
that includes a visual diff PNG — useful for attaching "expected vs actual"
diff images to issues (per `vision_next_term.md` §1.1):

```dart
Future<ImageComparisonResult> compareImages(
  Uint8List expected,
  Uint8List actual, {
  Color highlightColor = Colors.red,
  double tolerance = 0.0,
})
```

The returned `ImageComparisonResult` carries:
- `matches` — `true` if the diff is within `tolerance` (a fraction 0.0–1.0)
- `differingPixels` / `totalPixels` — exact counts
- `percentDifferent` — 0.0–100.0 percentage
- `diffPng` — a PNG where matching pixels come from `expected` and differing pixels
  are highlighted with `highlightColor`
- `width` / `height` — dimensions of the compared images

```dart
final result = await compareImages(expectedPng, actualPng, tolerance: 0.05);
if (!result.matches) {
  // Persist the expected, actual, and diff PNGs to attach to an issue.
  await savePng(expectedPng, 'issues/open/my_issue_expected.png');
  await savePng(actualPng, 'issues/open/my_issue_actual.png');
  await result.saveDiff('issues/open/my_issue_diff.png');
  print('${result.differingPixels} pixels differ (${result.percentDifferent}%)');
}
```

### `savePng` / `ImageComparisonResult.saveDiff`

```dart
String savePng(Uint8List pngBytes, String path)
```

Writes any PNG byte array (a rendered screen, an `expected` image, or an
`actual` image) to `path`, creating parent directories recursively, and
returns the path. Intended for the vision §1.1 "agent loop" workflow where
"expected vs actual PNG + diff" artifacts are attached to issues.

The write is synchronous (`dart:io`), so it is unaffected by the `flutter_test`
`FakeAsync` clock — it may be called from any `test`/`testWidgets` context or
from dev tooling. Uses `dart:io`, so it is for `flutter test` (VM) / dev
contexts only, not release app code or the web. A write failure (e.g. `path`
collides with an existing directory) throws `StateError`.

`ImageComparisonResult.saveDiff(String path)` is a convenience that persists the
diff PNG returned by `compareImages` (it delegates to `savePng`).

## Usage in a golden test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

testWidgets('DashboardNavCard golden - en, light', (tester) async {
  final png = await renderWidgetToPng(
    const DashboardNavCard(icon: Icons.home, iconColor: Colors.blue,
      title: 'Home', subtitle: 'Go home', onTap: null),
    size: const Size(375, 80),
    themeMode: ThemeMode.light,
  );
  expectLater(png, matchesGoldenFile(
    'test/goldens/dashboard_nav_card_en_375_light.png'));
});
```

## Determinism

* Font rendering uses the Flutter test font — deterministic across runs.
* `pixelRatio` is fixed per call so dimensions are stable.
* Rendering makes no real network or GPU calls.
* `renderWidgetToPng` / `renderScreenToPng` make no disk writes; the optional
  `savePng` helper performs synchronous `dart:io` file writes for persisting
  rendered/diff PNGs to disk (intended for test/dev tooling, not rendering).
