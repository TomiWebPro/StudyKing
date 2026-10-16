// Golden (visual) tests for `SummaryRow` using the `flutter_to_image`
// package — the second consumer of the package inside the StudyKing app
// test tree (after DashboardNavCard).
//
// These goldens catch pixel-level regressions (locale-aware number
// formatting, responsive Wrap reflow at phone vs desktop widths,
// light/dark theme contrast, stale-l10n strings) that the structural
// widget tests in `summary_row_test.dart` cannot.
//
// See: docs/development/visual-testing.md
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/summary_row.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Locates the StudyKing project root by walking up from the current working
/// directory to the nearest ancestor containing a `pubspec.yaml`.
String _projectRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  return Directory.current.path;
}

/// Asserts that [pngBytes] matches the golden file at [relativePath].
///
/// `matchesGoldenFile` decodes the PNG bytes (real engine work) to compare
/// pixels. Under `flutter test` the FakeAsync clock cannot drive that work, so
/// the comparison runs inside the test binding's `runAsync` — the same idiom
/// the `flutter_to_image` package uses for `toImage`/`toByteData`.
Future<void> _expectGolden(Uint8List pngBytes, String relativePath) async {
  final binding = TestWidgetsFlutterBinding.instance;
  final uri = goldenFileComparator.getTestUri(Uri.parse(relativePath), null);
  await binding.runAsync<void>(() async {
    if (autoUpdateGoldenFiles) {
      await goldenFileComparator.update(uri, pngBytes);
    } else {
      await goldenFileComparator.compare(pngBytes, uri);
    }
  });
}

void main() {
  // The package's `buildGoldenPath` produces root-relative paths such as
  // `test/goldens/summary_row_en_375_light.png`. The default
  // `GoldenFileComparator` roots relative golden keys at the *test file's*
  // directory, so from `test/features/dashboard/.../widgets/` that would look
  // in the wrong place. Override it to root lookups at the project root.
  setUp(() {
    final root = _projectRoot();
    goldenFileComparator = LocalFileComparator(
      Uri.file('$root/.goldens_root_placeholder'),
    );
  });

  /// Non-zero stats so the golden images are visually meaningful and locale
  /// differences (e.g. `85.0%` vs `85,0%`) are clearly visible.
  const testStats = OverallStats(
    accuracy: 85,
    totalStudyTimeHours: 12.5,
    dailyActivity: 15,
    topicsStudied: 7,
    totalAttempts: 1500,
  );

  group('SummaryRow goldens', () {
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];
      const sizes = [Size(375, 450), Size(1200, 400)];
      const themes = [ThemeMode.light, ThemeMode.dark];

      final matrix = await renderGoldenMatrixFull(
        const SummaryRow(overallStats: testStats),
        locales: locales,
        sizes: sizes,
        themeModes: themes,
        pixelRatio: 2.0,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('summary_row', locale, size, theme),
      );

      // 2 locales x 2 sizes x 2 themes = 8 entries
      expect(matrix.length, locales.length * sizes.length * themes.length);
      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
        await _expectGolden(entry.value, entry.key);
      }
    });

    // A text-scale sweep exercises the package's `renderGoldenTextScaleSweep`
    // helper and guards the accessibility concern from the issue (overflow at
    // larger font sizes) — SummaryRow's MetricCards and Wrap must remain intact.
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      final sweep = await renderGoldenTextScaleSweep(
        const SummaryRow(overallStats: testStats),
        locale: const Locale('en'),
        size: const Size(375, 1000),
        textScales: [1.0, 1.5, 2.0],
        themeMode: ThemeMode.light,
        pixelRatio: 2.0,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('summary_row', locale, size, textScale, theme),
      );

      expect(sweep.length, 3);
      for (final entry in sweep.entries) {
        expect(entry.value, isNotEmpty);
        await _expectGolden(entry.value, entry.key);
      }
    });
  });
}
