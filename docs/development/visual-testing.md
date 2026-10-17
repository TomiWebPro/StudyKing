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

When a screen has such widgets, wrap it in `MaterialApp` inside the
`ProviderScope` and loop manually (one `MaterialApp` per matrix cell)
instead of using `renderGoldenMatrixFull`:

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
manually for full control over `textScale` and `pixelRatio`.

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

Used by `renderGoldenTextScaleSweep` to produce unique, sortable filenames
for each text scale (e.g. `mentor_screen_en_1200x1.5_light.png`).

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

## Regenerating after intentional UI changes

1. Run with `--update-goldens`:
   ```bash
   flutter test test/features/.../<name>_golden_test.dart --update-goldens
   ```
2. Review the new golden PNGs visually (open them in an image viewer).
3. If the change is intentional, commit the updated goldens.

> Note: goldens are not tracked in git (see `.gitignore` above). CI
> regenerates them via `--update-goldens` on a schedule or on demand.
