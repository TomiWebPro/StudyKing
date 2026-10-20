// Locale-fidelity tests for the `flutter_to_image` package.
//
// Vision: `docs/vision_next_term.md` §1.1 ("multi-locale matrix (en/es)" to catch
// stale-l10n) and §1.2 ("unit-tested itself (sizes, locales, themes)").
//
// The package renders locale-distinct PNGs, but its test suite previously never
// asserted that `Locale('en')` vs `Locale('es')` produces *different* pixels for
// the *same* localised widget. These tests close that gap: they render one
// locale-aware widget under two locales and assert the bytes differ — so a
// regression that drops the `locale` threading (which would silently collapse
// every `es` golden to its `en` twin) is caught at the package level.
//
// Uses a hand-written `LocalizationsDelegate` fake (per AGENTS.md — no mockito/
// mocktail) returning deterministic ASCII strings per locale (en: "Hello"/
// "World"; es: "Hola"/"Mundo"). ASCII avoids font/glyph non-determinism and
// the package does not import the app's generated `AppLocalizations`. No Hive
// I/O, no emulator/GPU/network — runs under `flutter test`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

/// A tiny, deterministic localised resource bundle (a hand-written fake).
///
/// `load()` returns distinct content per `languageCode`, so rendering the same
/// widget under `Locale('en')` vs `Locale('es')` must produce different pixels.
@immutable
class _AppL10n {
  final String title;
  final String subtitle;
  const _AppL10n(this.title, this.subtitle);
}

/// A single const delegate instance supporting `en` and `es` and choosing the
/// strings at load time based on the requested locale.
class _AppL10nDelegate extends LocalizationsDelegate<_AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'es';

  @override
  Future<_AppL10n> load(Locale locale) {
    final isEs = locale.languageCode == 'es';
    return SynchronousFuture(_AppL10n(
      isEs ? 'Hola' : 'Hello',
      isEs ? 'Mundo' : 'World',
    ));
  }

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

/// A widget that renders its strings from [_AppL10n], so its pixels are
/// locale-sensitive. Used as the "representative screen/widget" for the
/// locale-fidelity assertions below.
class _LocalizedCard extends StatelessWidget {
  const _LocalizedCard();

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<_AppL10n>(context, _AppL10n);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n!.title, style: const TextStyle(fontSize: 14)),
          Text(l10n.subtitle, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

const List<LocalizationsDelegate<dynamic>> _kLocalDelegates = [
  GlobalWidgetsLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  _AppL10nDelegate(),
];
const List<Locale> _kSupported = [Locale('en'), Locale('es')];

/// Minimal PNG-signature sanity check matching the rest of the package suite.
bool _looksLikePng(Uint8List bytes) =>
    bytes.length >= 8 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4E &&
    bytes[3] == 0x47 &&
    bytes[4] == 0x0D &&
    bytes[5] == 0x0A &&
    bytes[6] == 0x1A &&
    bytes[7] == 0x0A;

void main() {
  group('locale fidelity (en vs es must differ)', () {
    // --- renderWidgetToPng ------------------------------------------------

    testWidgets(
        'renderWidgetToPng: same localised widget renders different bytes '
        'for en vs es', (tester) async {
      final en = await renderWidgetToPng(
        const _LocalizedCard(),
        size: const Size(200, 120),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        localizationsDelegates: _kLocalDelegates,
        supportedLocales: _kSupported,
      );
      final es = await renderWidgetToPng(
        const _LocalizedCard(),
        size: const Size(200, 120),
        pixelRatio: 1.0,
        locale: const Locale('es'),
        localizationsDelegates: _kLocalDelegates,
        supportedLocales: _kSupported,
      );

      expect(en, isNotEmpty);
      expect(es, isNotEmpty);
      expect(_looksLikePng(en), isTrue);
      expect(_looksLikePng(es), isTrue);
      // The locale parameter actually changes pixels — the core stale-l10n
      // guarantee the multi-locale matrix depends on.
      expect(es, isNot(equals(en)));
    });

    testWidgets('renderWidgetToPng: identical locale is stable across renders',
        (tester) async {
      final a = await renderWidgetToPng(
        const _LocalizedCard(),
        size: const Size(200, 120),
        pixelRatio: 1.0,
        locale: const Locale('es'),
        localizationsDelegates: _kLocalDelegates,
        supportedLocales: _kSupported,
      );
      final b = await renderWidgetToPng(
        const _LocalizedCard(),
        size: const Size(200, 120),
        pixelRatio: 1.0,
        locale: const Locale('es'),
        localizationsDelegates: _kLocalDelegates,
        supportedLocales: _kSupported,
      );

      // Same locale + same widget => same bytes (determinism).
      expect(a, equals(b));
    });

    // --- renderScreenToPng ------------------------------------------------

    testWidgets(
        'renderScreenToPng: same localised screen renders different bytes '
        'for en vs es', (tester) async {
      final en = await renderScreenToPng(
        const _LocalizedCard(),
        size: const Size(375, 800),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kLocalDelegates,
        supportedLocales: _kSupported,
      );
      final es = await renderScreenToPng(
        const _LocalizedCard(),
        size: const Size(375, 800),
        pixelRatio: 1.0,
        locale: const Locale('es'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kLocalDelegates,
        supportedLocales: _kSupported,
      );

      expect(en, isNotEmpty);
      expect(es, isNotEmpty);
      expect(_looksLikePng(en), isTrue);
      expect(_looksLikePng(es), isTrue);
      expect(es, isNot(equals(en)));
    });

    // --- renderScreenGoldenMatrixFull -------------------------------------

    testWidgets(
        'renderScreenGoldenMatrixFull: locale entries are distinct in bytes '
        'and paths', (tester) async {
      final matrix = await renderScreenGoldenMatrixFull(
        (_, __) => const _LocalizedCard(),
        locales: [const Locale('en'), const Locale('es')],
        sizes: [const Size(375, 800)],
        themeModes: [ThemeMode.light],
        pixelRatio: 1.0,
        localizationsDelegates: _kLocalDelegates,
        supportedLocales: _kSupported,
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('locale_fidelity', locale, size, theme),
      );

      // 2 locales × 1 size × 1 theme = 2 cells.
      expect(matrix.length, 2);

      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
        expect(_looksLikePng(entry.value), isTrue);
        // Each path carries the locale token (buildGoldenPath convention).
        expect(entry.key, anyOf(contains('_en_'), contains('_es_')));
        expect(entry.key, startsWith('test/goldens/locale_fidelity_'));
        expect(entry.key, endsWith('.png'));
      }

      final enPath =
          matrix.keys.singleWhere((k) => k.contains('_en_') && !k.contains('_es_'));
      final esPath =
          matrix.keys.singleWhere((k) => k.contains('_es_') && !k.contains('_en_'));
      final enBytes = matrix[enPath]!;
      final esBytes = matrix[esPath]!;

      // Distinct paths → distinct bytes: the matrix cannot silently collapse
      // en/es for a locale-sensitive screen.
      expect(esPath, isNot(equals(enPath)));
      expect(esBytes, isNot(equals(enBytes)));
    });
  });
}
