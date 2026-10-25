// Golden (visual) tests for `DailyActivityHeatmap` using the `flutter_to_image`
// package — renders the heatmap across locale × theme × size matrices so agents
// can see pixels (overflow, contrast, green-score gradient, locale-dependent day
// labels in Spanish vs English, text-scale readability).
//
// See: docs/development/visual-testing.md
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/daily_activity_heatmap.dart';
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

/// Builds a deterministic set of daily-trend entries anchored to a fixed date
/// so goldens are reproducible regardless of when the test runs.
List<DailyTrendEntry> _buildFixedTrend(DateTime anchorDate) {
  return List.generate(7, (i) {
    final day = anchorDate.subtract(Duration(days: 6 - i));
    return DailyTrendEntry(
      date: day,
      attempts: (i + 1) * 5,
      accuracy: 50.0 + (i * 10),
      focusSeconds: (i + 1) * 300,
      sessions: i + 1,
      compositeScore: (i + 1) / 7,
    );
  });
}

void main() {
  // A fixed "today" value so goldens are reproducible regardless of when
  // the test runs — the heatmap anchors its grid from 7 days before this date.
  final kAnchorDate = DateTime(2026, 10, 20);

  setUp(() {
    // Override the default LocalFileComparator so golden keys that start with
    // `test/goldens/…` resolve relative to the project root rather than the
    // test file's directory.
    final root = _projectRoot();
    goldenFileComparator = LocalFileComparator(
      Uri.file('$root/.goldens_root_placeholder'),
    );
  });

  group('DailyActivityHeatmap goldens', () {
    /// Widget-under-test factory: wraps the heatmap in MaterialApp scaffolding
    /// so Theme.of + Localizations are resolved. No Hive I/O is performed.
    Widget buildHeatmap(Locale locale) {
      final trend = _buildFixedTrend(kAnchorDate);

      return MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: DailyActivityHeatmap(
              dailyTrend: trend,
              now: kAnchorDate,
            ),
          ),
        ),
      );
    }

    // The matrix: en/es × phone width (the heatmap is always within the
    // dashboard card which fills the parent width). Height 400 captures
    // the header + grid + legend for typical activity windows.
    testWidgets('matches goldens across locale x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];

      for (final locale in locales) {
        // Light variant
        final lightPng = await renderWidgetToPng(
          buildHeatmap(locale),
          size: const Size(375, 400),
          pixelRatio: 2.0,
          themeMode: ThemeMode.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );

        expect(lightPng, isNotEmpty);
        await _expectGolden(
          lightPng,
          buildGoldenPath(
            'daily_activity_heatmap',
            locale,
            const Size(375, 400),
            ThemeMode.light,
          ),
        );

        // Dark variant
        final darkPng = await renderWidgetToPng(
          buildHeatmap(locale),
          size: const Size(375, 400),
          pixelRatio: 2.0,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );

        expect(darkPng, isNotEmpty);
        await _expectGolden(
          darkPng,
          buildGoldenPath(
            'daily_activity_heatmap',
            locale,
            const Size(375, 400),
            ThemeMode.dark,
          ),
        );
      }
    });

    // Text-scale sweep exercises accessibility concern: the heatmap must not
    // overflow or squash at larger font sizes. We render once per text scale
    // since `renderGoldenTextScaleSweep` delegates to `renderWidgetToPng`
    // (bare Theme/MediaQuery), so we build the widget inline.
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x',
        (tester) async {
      final locale = const Locale('en');
      final trend = _buildFixedTrend(kAnchorDate);

      for (final textScale in [1.0, 1.5, 2.0]) {
        final png = await renderWidgetToPng(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: DailyActivityHeatmap(
                  dailyTrend: trend,
                  now: kAnchorDate,
                ),
              ),
            ),
          ),
          size: const Size(375, 400),
          pixelRatio: 2.0,
          themeMode: ThemeMode.light,
          textScale: textScale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );

        expect(png, isNotEmpty);
        await _expectGolden(
          png,
          buildGoldenPathWithTextScale(
            'daily_activity_heatmap',
            locale,
            const Size(375, 400),
            textScale,
            ThemeMode.light,
          ),
        );
      }
    });
  });
}
