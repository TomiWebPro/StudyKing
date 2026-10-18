// Golden (visual) tests for `DashboardNavCard` using the `flutter_to_image`
// package — the first consumer of the package inside the StudyKing app test tree.
//
// These goldens catch pixel-level regressions (overflow, contrast, density,
// stale l10n, RTL chevron placement) that the structural widget tests in
// `dashboard_nav_card_test.dart` cannot.
//
// See: docs/development/visual-testing.md
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';
import 'package:studyking/features/dashboard/presentation/widgets/dashboard_nav_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Locates the StudyKing project root by walking up from the current working
/// directory to the nearest ancestor containing a `pubspec.yaml`.
///
/// `flutter test` runs from the project root, so this is the root; the walk-up
/// is defensive for editors that invoke tests from a subdirectory.
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
  // `test/goldens/dashboard_nav_card_en_375_light.png`. The default
  // `GoldenFileComparator` roots relative golden keys at the *test file's*
  // directory, so from `test/features/dashboard/.../widgets/` that would look
  // in the wrong place. Override it to root lookups at the project root.
  setUp(() {
    final root = _projectRoot();
    goldenFileComparator = LocalFileComparator(
      Uri.file('$root/.goldens_root_placeholder'),
    );
  });

  group('DashboardNavCard goldens', () {
    // Locale-appropriate strings so the en/es matrix is visually meaningful
    // (different glyphs / layout), which is what catches stale-l10n regressions.
    // DashboardNavCard takes plain strings (no AppLocalizations lookup), so the
    // locale is exercised through the injected text + the package's Localizations
    // wrapper.
    DashboardNavCard buildCard(Locale locale) {
      final isEs = locale.languageCode == 'es';
      return DashboardNavCard(
        icon: Icons.school,
        iconColor: Colors.blue,
        title: isEs ? 'Estudiar' : 'Study',
        subtitle: isEs ? 'Sigue tu progreso' : 'Track your progress',
        onTap: null,
      );
    }

    // The 8-file matrix required by the issue: en/es x 375(phone)/1200(desktop)
    // x light/dark.
    testWidgets('matches goldens across locale x width x theme', (tester) async {
      const locales = [Locale('en'), Locale('es')];
      const sizes = [Size(375, 120), Size(1200, 120)];
      const themes = [ThemeMode.light, ThemeMode.dark];

      for (final locale in locales) {
        final matrix = await renderGoldenMatrixFull(
          buildCard(locale),
          locales: [locale],
          sizes: sizes,
          themeModes: themes,
          pixelRatio: 2.0,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          pathBuilder: (l, s, t) =>
              buildGoldenPath('dashboard_nav_card', l, s, t),
        );

        expect(matrix.length, sizes.length * themes.length);
        for (final entry in matrix.entries) {
          expect(entry.value, isNotEmpty);
          await _expectGolden(entry.value, entry.key);
        }
      }
    });

    // A text-scale sweep exercises the package's `renderGoldenTextScaleSweep`
    // helper and guards the accessibility concern from the issue (overflow at
    // larger font sizes) — CardNavCard chevrons/text must remain intact.
    testWidgets('text-scale sweep stays readable at 1.0x/1.5x/2.0x', (tester) async {
      final sweep = await renderGoldenTextScaleSweep(
        buildCard(const Locale('en')),
        locale: const Locale('en'),
        size: const Size(375, 160),
        textScales: [1.0, 1.5, 2.0],
        themeMode: ThemeMode.light,
        pixelRatio: 2.0,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('dashboard_nav_card', locale, size, textScale, theme),
      );

      expect(sweep.length, 3);
      for (final entry in sweep.entries) {
        expect(entry.value, isNotEmpty);
        await _expectGolden(entry.value, entry.key);
      }
    });

    // RTL coverage: the card's chevron flips direction based on
    // `Directionality.of(context)` (lib/features/dashboard/presentation/widgets/
    // dashboard_nav_card.dart:49). This golden guards that the RTL chevron is
    // the mirror icon (`chevron_left`) and that layout stays single-line.
    testWidgets('RTL chevron flips compared to LTR', (tester) async {
      const locale = Locale('en');
      const size = Size(375, 120);
      const theme = ThemeMode.light;

      final ltrPng = await renderWidgetToPng(
        buildCard(locale),
        size: size,
        pixelRatio: 2.0,
        themeMode: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        textDirection: TextDirection.ltr,
      );

      final rtlPng = await renderWidgetToPng(
        buildCard(locale),
        size: size,
        pixelRatio: 2.0,
        themeMode: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        textDirection: TextDirection.rtl,
      );

      expect(rtlPng, isNotEmpty);
      // LTR and RTL must differ — the chevron icon changes direction.
      expect(rtlPng, isNot(equals(ltrPng)));

      // Golden assertion for the RTL variant.
      await _expectGolden(
        rtlPng,
        'test/goldens/dashboard_nav_card_en_375_light_rtl.png',
      );
    });
  });
}
