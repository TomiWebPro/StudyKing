# Visual Testing Guide

## Overview

StudyKing uses **golden (visual) tests** to catch regressions in pixel-level
UI quality that structural widget assertions cannot detect: layout overflow,
contrast, density, hierarchy, stale-l10n strings, desktop-width truncation,
and RTL chevron placement.

The mechanism is the `flutter_to_image` package (`packages/flutter_to_image/`),
which renders any Flutter widget to a PNG (`Uint8List`) headlessly under
`flutter test` — no emulator or GPU required. Agents and CI use these PNG
diffs to *see* the UI and optimise it.

> **Vision reference:** `docs/vision_next_term.md` §1.1

---

## When to add a golden test

| Situation | Add a golden? |
|---|---|
| New top-level screen (dashboard, planner, teaching, mentor, practice, lessons) | ✅ Yes — one golden test per screen |
| Pure widget with locale/theme/width/RTL sensitivity (e.g. `DashboardNavCard`) | ✅ Yes |
| Pure logic or model (no UI) | ❌ No — use unit tests |
| Widget already has structural widget tests (`findsOneWidget`) | ✅ Add golden to verify pixels |

Every top-level screen must have **at least one golden test** consumed from
`packages/flutter_to_image/`. See issue template `visual-*.md` for the
accepted criteria.

---

## Current golden test coverage

| Screen / Widget | Golden test file | Matrix |
|---|---|---|
| `DashboardNavCard` | `test/features/dashboard/presentation/widgets/dashboard_nav_card_golden_test.dart` | en/es × 375/1200 × light/dark + text-scale sweep + RTL |
| `SummaryRow` | `test/features/dashboard/presentation/widgets/summary_row_golden_test.dart` | en/es × 375/1200 × light/dark + text-scale sweep |
| `DashboardScreen` | `test/features/dashboard/presentation/dashboard_screen_golden_test.dart` | en/es × 375/1200 × light/dark |
| `PlannerScreen` | `test/features/planner/presentation/planner_screen_golden_test.dart` | en/es × 375/1200 × light/dark + text-scale sweep |
| `MentorScreen` | `test/features/mentor/presentation/mentor_screen_golden_test.dart` | en/es × 375/1200 × light/dark + text-scale sweep |
| `LessonListScreen` | `test/features/lessons/presentation/lesson_list_screen_golden_test.dart` | en/es × 375/1200 × light/dark + text-scale sweep |
| `PracticeScreen` | `test/features/practice/presentation/screens/practice_screen_golden_test.dart` | en/es × 375/1200 × light/dark + text-scale sweep |
| `TutorScreen` | `test/features/teaching/presentation/tutor_screen_golden_test.dart` | en/es × 375/1200 × light/dark + text-scale sweep |

---

## API reference

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
})
```

Renders `widget` to PNG bytes. The widget is wrapped internally with
`MediaQuery` (size, text-scale), `Theme` (light/dark), `Directionality`
(LTR), and an optional `Localizations` delegate wrapper.

### `renderWidgetToImageResult`

Like `renderWidgetToPng` but returns an `ImageResult` carrying metadata
(`size`, `pixelRatio`, `locale`).

### `renderScreenToPng`

Like `renderWidgetToPng` but wraps the supplied `screen` widget in a
`MaterialApp` with the given locale, theme, text-scale, and localisation
delegates before rendering. Use this for **screen-level** golden tests where
the widget expects a `MaterialApp` ancestor (for `Theme`, `Overlay`,
`ScaffoldMessenger`, or `Localizations`).

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
})
```

Example — rendering a full screen golden:

```dart
final png = await renderScreenToPng(
  ProviderScope(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
    ],
    child: const MyScreen(),
  ),
  size: const Size(375, 800),
  locale: const Locale('es'),
  themeMode: ThemeMode.dark,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
expectLater(png, matchesGoldenFile('test/goldens/my_screen_es_375_dark.png'));
```

If the screen does not include its own `Scaffold`, wrap it:

```dart
await renderScreenToPng(
  Scaffold(body: MyScreen()),
  ...
);
```

The optional `brightness` parameter resolves `ThemeMode.system` to light or dark,
mirroring `renderWidgetToPng`. It is ignored when `themeMode` is explicitly
`ThemeMode.light` or `ThemeMode.dark`.

### `renderScreenToImageResult`

Like `renderScreenToPng` but returns an `ImageResult` carrying metadata
(`size`, `pixelRatio`, `locale`).

### Golden matrix helpers

```dart
String buildGoldenPath(String name, Locale locale, Size size, ThemeMode theme)
```

Returns a path following the convention:
`test/goldens/<name>_<locale>_<width>_<theme>.png`

```dart
Future<Map<String, Uint8List>> renderGoldenMatrix(
  Widget widget, {
  required List<Locale> locales,
  required List<Size> sizes,
  ThemeMode themeMode = ThemeMode.system,
  ...
  required GoldenPathBuilder pathBuilder,
})
```

Renders across every locale × size combination and returns a map of
golden-path → PNG bytes.

### `renderScreenGoldenMatrixFull`

Screen-level counterpart of `renderGoldenMatrixFull`. Use this for
**screen-level** golden matrices (a `MaterialApp`-rooted screen across
`en`/`es` × phone/desktop × light/dark).

```dart
Future<Map<String, Uint8List>> renderScreenGoldenMatrixFull(
  Widget Function(Locale locale, ThemeMode theme) screenBuilder, {
  required List<Locale> locales,
  required List<Size> sizes,
  required List<ThemeMode> themeModes,
  Brightness? brightness,
  double pixelRatio = 2.0,
  double textScale = 1.0,
  required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
  required List<Locale> supportedLocales,
  required GoldenPathBuilder pathBuilder,
})
```

[`renderGoldenMatrixFull`] renders a *single* widget instance across all cells,
which breaks for `MaterialApp`-rooted screens whose `AppBar` uses
`Tooltip`/`PopupMenuButton` — their `OverlayEntry` is reused across cells and
Flutter throws "entry already present in a different Overlay".
`renderScreenGoldenMatrixFull` solves this by taking a `screenBuilder` that is
invoked **once per cell**, producing a fresh `MaterialApp` (and therefore a
fresh `Overlay`) each time. Pass your `ProviderScope` + `Scaffold` wrapping
inside `screenBuilder`:

```dart
final goldens = await renderScreenGoldenMatrixFull(
  (locale, theme) => ProviderScope(
    overrides: [studentIdValueProvider.overrideWithValue('test-student')],
    child: const MyScreen(),
  ),
  locales: [const Locale('en'), const Locale('es')],
  sizes: [const Size(375, 800), const Size(1200, 800)],
  themeModes: [ThemeMode.light, ThemeMode.dark],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  pathBuilder: (locale, size, theme) =>
      buildGoldenPath('my_screen', locale, size, theme),
);
for (final entry in goldens.entries) {
  expectLater(entry.value, matchesGoldenFile(entry.key));
}
```

This replaces the manual `MaterialApp` + `renderWidgetToPng` loop documented
below for screens that need an `Overlay`.

### `renderScreenGoldenTextScaleSweep`

Screen-level counterpart of `renderGoldenTextScaleSweep`. Use this to render a
`MaterialApp`-rooted screen across a sweep of text scales (e.g. `1.0x`, `1.5x`,
`2.0x`) for accessibility/regression coverage. Like `renderScreenGoldenMatrixFull`,
it takes a `screenBuilder` invoked **once per cell** so `Overlay` entries never
collide:

```dart
final sweeps = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => ProviderScope(
    overrides: [studentIdValueProvider.overrideWithValue('test-student')],
    child: const MyScreen(),
  ),
  locale: const Locale('en'),
  size: const Size(1200, 800),
  textScales: [1.0, 1.5, 2.0],
  themeMode: ThemeMode.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  pathBuilder: (locale, size, textScale, theme) =>
      buildGoldenPathWithTextScale('my_screen', locale, size, textScale, theme),
);
for (final entry in sweeps.entries) {
  expectLater(entry.value, matchesGoldenFile(entry.key));
}
```

This replaces the manual per-scale `MaterialApp` + `renderWidgetToPng` loop that
every screen golden test currently hand-rolls (see
`test/features/mentor/presentation/mentor_screen_golden_test.dart:157` and
`test/features/planner/presentation/planner_screen_golden_test.dart:187`).

---

## Image diff helper

### `compareImages`

When a golden test fails, `matchesGoldenFile` reports the numeric pixel
count but does **not** produce a visual diff. The `compareImages` helper
fills that gap so agents and CI can attach a diff PNG to an issue — exactly
as called for in `docs/vision_next_term.md` §1.1 ("visual diffs are
attached to issues: expected vs actual PNG + diff"):

```dart
Future<ImageComparisonResult> compareImages(
  Uint8List expected,
  Uint8List actual, {
  Color highlightColor = Colors.red,
  double tolerance = 0.0,
})
```

- **`expected`**, **`actual`** — PNG-encoded byte arrays (e.g. from
  `renderWidgetToPng` or `renderScreenToPng`). Both must have the same
  dimensions.
- **`highlightColor`** — colour used to paint differing pixels in the
  diff image (default `Colors.red`).
- **`tolerance`** — acceptable *fraction* of differing pixels (0.0–1.0).
  When `differingPixels / totalPixels ≤ tolerance`, `matches` is `true`.
  Use a small value (e.g. `0.05`) to tolerate anti-aliasing jitter between
  golden regeneration runs.

Returns an `ImageComparisonResult`:

| Field | Type | Description |
|---|---|---|
| `matches` | `bool` | `true` if the diff is within `tolerance` |
| `differingPixels` | `int` | exact count of differing pixels |
| `totalPixels` | `int` | total pixels compared |
| `percentDifferent` | `double` | 0.0–100.0 percentage |
| `diffPng` | `Uint8List` | PNG where matching pixels are copied from `expected` and differing pixels are highlighted |
| `width` | `int` | width of the compared images |
| `height` | `int` | height of the compared images |

### Usage — producing a diff PNG for an issue

```dart
final expected = await renderScreenToPng(
  const MyScreen(),
  size: const Size(375, 800),
  locale: const Locale('en'),
  themeMode: ThemeMode.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
// ... after a UI change ...
final actual = await renderScreenToPng(/* same args */);

final result = await compareImages(expected, actual);
if (!result.matches) {
  // Persist the expected, actual, and diff PNGs so they can be attached to
  // an issue for visual review (vision_next_term.md §1.1 agent loop).
  await savePng(expected, 'issues/open/visual-foo_expected.png');
  await savePng(actual, 'issues/open/visual-foo_actual.png');
  await result.saveDiff('issues/open/visual-foo_diff.png');
  print('${result.differingPixels}/${result.totalPixels} pixels differ '
        '(${result.percentDifferent}%)');
}
```

Must be called from within a `testWidgets` callback (same as
`renderWidgetToPng`) because PNG decoding and PNG encoding perform real
engine async work that the test binding's FakeAsync clock cannot drive.
`savePng` / `ImageComparisonResult.saveDiff` may be called outside
`runAsync`: their underlying write is synchronous (`dart:io` `File` APIs), so
it is unaffected by the FakeAsync clock — unlike `compareImages`, they do not
need a `testWidgets` binding and are safe to call from dev tooling.

The package's own test suite (`packages/flutter_to_image/test/diff_test.dart`)
verifies: identical images match, different images differ, diff PNG is a
valid PNG with correct dimensions, tolerance boundary behaviour, custom
highlight colour, dimension-mismatch throws `StateError`, and `percentDifferent`
is correct for 0 % and 100 % diffs. (`packages/flutter_to_image/test/file_io_test.dart`)
verifies `savePng` writes byte-exact files, creates nested parent dirs, and
that `ImageComparisonResult.saveDiff` persists the diff PNG.

### `savePng` / `ImageComparisonResult.saveDiff`

```dart
String savePng(Uint8List pngBytes, String path)
Future<String> ImageComparisonResult.saveDiff(String path)
```

`savePng` writes any PNG byte array — a rendered screen, an `expected` image,
or an `actual` image — to `path` on disk, creating parent directories
recursively, and returns the path. `ImageComparisonResult.saveDiff` is a
convenience that persists the diff PNG returned by `compareImages` (delegating
to `savePng`). Together they let an agent/loop emit the
"expected vs actual PNG + diff" artifacts the vision calls for to attach to
issues (see `docs/vision_next_term.md` §1.1 agent loop):

```dart
final expected = await renderScreenToPng(...);
final actual = await renderScreenToPng(...);
final result = await compareImages(expected, actual);
if (!result.matches) {
  await savePng(expected, 'issues/open/visual-foo_expected.png');
  await savePng(actual, 'issues/open/visual-foo_actual.png');
  await result.saveDiff('issues/open/visual-foo_diff.png');
}
```

Both helpers perform a synchronous `dart:io` write, so they are unaffected by
the `flutter_test` `FakeAsync` clock and need no `runAsync` — they can be
called from any `test`/`testWidgets` context or from dev tooling. They use
`dart:io` and are therefore for `flutter test` (VM) / dev contexts only, not
release app code or the web. A write failure (e.g. `path` is an existing
directory) throws `StateError`.

---

## Golden file path convention

```
test/goldens/<widget_or_screen>_<locale>_<width>_<theme>.png
```

| Field | Values | Example |
|---|---|---|
| `<locale>` | `en`, `es` | `en` |
| `<width>` | phone `375`, desktop `1200` | `375` |
| `<theme>` | `light`, `dark` | `light` |

**Example:** `test/goldens/lesson_list_es_375_dark.png`

Use `buildGoldenPath()` from the package to generate paths — it enforces the
convention for you.

---

## Golden file lifecycle

### Are golden PNGs tracked in git?

**No.** Golden PNGs are binary test fixtures and are **not tracked** in git.
They are listed in `test/goldens/.gitignore`.

This prevents:
- Large binary blobs bloating the repository
- Merge conflicts on binary files
- Stale goldens drifting out of sync

### Generating goldens

To (re)generate golden files locally:

```bash
flutter test --update-goldens
```

Or target a specific test file:

```bash
flutter test test/features/lessons/presentation/lesson_list_screen_golden_test.dart --update-goldens
flutter test test/features/mentor/presentation/mentor_screen_golden_test.dart --update-goldens
```

### Running golden tests

```bash
flutter test test/features/lessons/presentation/lesson_list_screen_golden_test.dart
flutter test test/features/mentor/presentation/mentor_screen_golden_test.dart
```

If a golden file does not exist, the test **fails** (it does not auto-generate).
Run with `--update-goldens` first.

### CI behaviour

CI runs golden tests **without** `--update-goldens`. A failure means a visual
regression was detected — the diff image is saved to the CI artifacts for
review.

---

## Test patterns (per AGENTS.md)

### No Hive I/O

Golden tests must **not** touch Hive. Inject `fixedStudentId` and hand-written
fakes instead of `StudentIdService` or real repositories:

```dart
ProviderScope(
  overrides: [
    lessonRepositoryProvider.overrideWithValue(fakeRepo),
    sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
    studentIdValueProvider.overrideWithValue('test-student'),
  ],
  child: LessonListScreen(args: LessonListArgs(...)),
)
```

### Hand-written fakes

Use hand-written fake classes (not `mockito`/`mocktail`):

```dart
class _FakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;
  _FakeLessonRepository({List<Lesson>? lessons}) : _lessons = lessons ?? [];

  @override
  Future<Result<List<Lesson>>> getAll() async => Result.success(_lessons);
  // ...
}
```

### Wrappers for screens that need an Overlay

The `flutter_to_image` package wraps widgets in `Theme`, `MediaQuery`,
`Directionality`, `SizedBox`, `RepaintBoundary`, and `View` — but **not**
`MaterialApp`/`Navigator`/`Overlay`. Screens whose `AppBar` contains a
`Tooltip` or `IconButton` need an `Overlay` ancestor, which `MaterialApp`
provides internally.

**Preferred — use `renderScreenGoldenMatrixFull`:** it builds a fresh
`MaterialApp` *per matrix cell*, so `OverlayEntry` is never reused and you
avoid the "entry already present in a different Overlay" error. Pass a
`screenBuilder` that returns the fully-wrapped screen (ProviderScope +
Scaffold + screen):

```dart
final goldens = await renderScreenGoldenMatrixFull(
  (locale, theme) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light(),
    themeMode: theme,
    home: ProviderScope(
      overrides: [/* fakes */],
      child: const MyScreen(),
    ),
  ),
  locales: [const Locale('en'), const Locale('es')],
  sizes: [const Size(375, 800), const Size(1200, 800)],
  themeModes: [ThemeMode.light, ThemeMode.dark],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  pathBuilder: (locale, size, theme) =>
      buildGoldenPath('my_screen', locale, size, theme),
);
```

**Fallback — loop manually (one `MaterialApp` per matrix cell):** only when
you need full control over `textScale`/`pixelRatio` per cell that the helper
doesn't expose, or when rendering a single screen (not a matrix):

```dart
Widget _buildScreen(Locale locale, ThemeMode theme, double textScale) {
  final themeData = theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: themeData,
    darkTheme: themeData,
    themeMode: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: ProviderScope(
      overrides: [/* fakes */],
      child: const MentorScreen(),
    ),
  );
}
```

Each matrix cell builds a fresh `MaterialApp`, avoiding
`OverlayEntry` reuse errors ("entry already present in a different Overlay")
when `renderWidgetToPng` is called multiple times.

### Unit vs widget tests

- **Unit tests** (pure logic): package tests for `buildGoldenPath`, etc.
- **Widget tests** (UI rendering): golden tests that render widgets via
  `renderWidgetToPng` and assert with `matchesGoldenFile`.

Keep them in **separate files**.

---

## Golden matrix

For each golden-tested screen, render across the following matrix:

| Dimension | Values |
|---|---|
| **Locale** | `en`, `es` |
| **Width** | `375` (phone), `1200` (desktop) |
| **Theme** | `light`, `dark` |

**Example matrix (8 files):**

```
test/goldens/lesson_list_en_375_light.png
test/goldens/lesson_list_en_375_dark.png
test/goldens/lesson_list_en_1200_light.png
test/goldens/lesson_list_en_1200_dark.png
test/goldens/lesson_list_es_375_light.png
test/goldens/lesson_list_es_375_dark.png
test/goldens/lesson_list_es_1200_light.png
test/goldens/lesson_list_es_1200_dark.png
```

Use `renderGoldenMatrix` to render all combinations in one call, or loop
manually for full control over `textScale` and `pixelRatio`. For
**screen-level** matrices, use `renderScreenGoldenMatrixFull` (which builds a
fresh `MaterialApp` per cell); see [Wrappers for screens that need an
Overlay](#wrappers-for-screens-that-need-an-overlay).

### `buildGoldenPathWithTextScale`

```dart
String buildGoldenPathWithTextScale(
  String name,
  Locale locale,
  Size size,
  double textScale,
  ThemeMode theme,
)
```

Returns a path following the convention:
`test/goldens/<name>_<locale>_<width>x<textScale>_<theme>.png`

Used by `renderGoldenTextScaleSweep` (widget-level) and
`renderScreenGoldenTextScaleSweep` (screen-level) to produce unique, sortable
filenames for each text scale (e.g. `mentor_screen_en_1200x1.5_light.png`).

---

## Accessibility checks

Golden tests should also verify accessibility:

### Contrast
Ensure text/background pairs meet WCAG 2.1 AA contrast (≥ 4.5:1). Review
golden images on both light and dark themes.

### Touch targets (≥ 48dp)
Any tappable element must be at least 48 × 48 logical pixels. Check in the
golden image or add a `testWidgets` assertion:

```dart
expect(
  tester.renderObject<RenderBox>(find.byKey(tapTargetKey)).size,
  greaterThanOrEqualTo(const Size(48, 48)),
);
```

### Semantics labels
Verify that interactive widgets have `Semantics` labels:

```dart
expect(find.bySemanticsLabel('Start AI Tutoring'), findsOneWidget);
```

---

## Localisation verification

When rendering with `locale: const Locale('es')`, verify the golden image
shows Spanish strings (not English). This catches stale-l10n bugs where a
screen caches `l10n` in a local variable instead of reading it in `build()`.

The `flutter_to_image` package passes the `locale` to a `Localizations`
wrapper. Combine with `AppLocalizations.localizationsDelegates` and
`AppLocalizations.supportedLocales` from `lib/l10n/generated/app_localizations.dart`.

---

## RTL / text-direction testing

The `flutter_to_image` package supports explicit text-direction control on
both widget-level and screen-level APIs via the `textDirection` parameter:

### Widget-level — `renderWidgetToPng` / `renderWidgetToImageResult`

The `textDirection` parameter wraps the widget in a `Directionality` widget
(default `TextDirection.ltr`):

```dart
final rtl = await renderWidgetToPng(
  const MyWidget(),
  size: const Size(375, 800),
  textDirection: TextDirection.rtl,
);
```

`ImageResult.textDirection` reflects the requested direction.

### Screen-level — `renderScreenToPng` / `renderScreenToImageResult`

When rendering a `MaterialApp`-rooted screen, `textDirection` is applied as a
`Directionality` wrapper inside the MaterialApp's `builder`, **overriding** the
locale-based directionality resolution. This lets you force RTL rendering for
an LTR locale (e.g. `en`) to test layout mirroring without needing an RTL
locale:

```dart
final result = await renderScreenToImageResult(
  const MyScreen(),
  size: const Size(375, 800),
  locale: const Locale('en'),
  themeMode: ThemeMode.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  textDirection: TextDirection.rtl,
);
expect(result.textDirection, TextDirection.rtl);
```

### Screen-level matrix helpers

`renderScreenGoldenMatrixFull` and `renderScreenGoldenTextScaleSweep` both
accept and forward `textDirection`:

```dart
final rtlGoldens = await renderScreenGoldenMatrixFull(
  (locale, theme) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData.light(),
    home: ProviderScope(
      overrides: [/* fakes */],
      child: const MyScreen(),
    ),
  ),
  locales: [const Locale('en')],
  sizes: [const Size(375, 800)],
  themeModes: [ThemeMode.light],
  textDirection: TextDirection.rtl,
  pathBuilder: (locale, size, theme) =>
      buildGoldenPath('my_screen_rtl', locale, size, theme),
);
```

For a direction-sensitive screen (e.g. one with a leading icon and trailing
actions), the RTL and LTR renders should produce **different pixels**:

```dart
final ltr = await renderScreenToPng(/* textDirection: TextDirection.ltr */);
final rtl = await renderScreenToPng(/* textDirection: TextDirection.rtl */);
expect(rtl, isNot(equals(ltr)));
```

---

## Regenerating after intentional UI changes

1. Run with `--update-goldens`:
   ```bash
   flutter test test/features/.../<name>_golden_test.dart --update-goldens
   ```
2. Review the new golden PNGs visually (open them in an image viewer).
3. If the change is intentional, commit the updated goldens.

> Note: goldens are not tracked in git (see `.gitignore` above). CI
> regenerates them via `--update-goldens` on a schedule or on demand.
