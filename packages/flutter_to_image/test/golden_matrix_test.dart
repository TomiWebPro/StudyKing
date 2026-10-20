import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

/// Built-in Flutter localizations delegates that support both `en` and `es`.
/// Used by `renderScreenToPng` / `renderScreenGoldenMatrixFull` tests so
/// MaterialApp doesn't warn about unsupported locales.
const List<LocalizationsDelegate<dynamic>> _kTestDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  group('buildGoldenPath', () {
    // Pure-function tests — no widget rendering needed.
    test('builds path with en locale, width, and light theme', () {
      final path = buildGoldenPath(
        'test_widget',
        const Locale('en'),
        const Size(375, 812),
        ThemeMode.light,
      );
      expect(path, 'test/goldens/test_widget_en_375_light.png');
    });

    test('handles es locale with dark theme', () {
      final path = buildGoldenPath(
        'test_widget',
        const Locale('es'),
        const Size(1200, 800),
        ThemeMode.dark,
      );
      expect(path, 'test/goldens/test_widget_es_1200_dark.png');
    });

    test('floors fractional width to integer', () {
      final path = buildGoldenPath(
        'card',
        const Locale('en'),
        const Size(375.9, 812),
        ThemeMode.system,
      );
      expect(path, 'test/goldens/card_en_375_system.png');
    });

    test('uses "system" for ThemeMode.system', () {
      final path = buildGoldenPath(
        'widget',
        const Locale('en'),
        const Size(100, 100),
        ThemeMode.system,
      );
      expect(path, 'test/goldens/widget_en_100_system.png');
    });

    // ---------------------------------------------------------------------------
    // textDirection (RTL) coverage for buildGoldenPath.
    //
    // `buildGoldenPath` gained a `textDirection` parameter so that RTL golden
    // files get a distinct `_rtl` suffix, preventing collisions with LTR
    // variants. Without this, a RTL golden and its LTR counterpart for the same
    // name × locale × width × theme would resolve to the same file path.
    // ---------------------------------------------------------------------------
    test('rtl textDirection appends _rtl suffix to path', () {
      final path = buildGoldenPath(
        'my_widget',
        const Locale('en'),
        const Size(375, 800),
        ThemeMode.light,
        textDirection: TextDirection.rtl,
      );
      expect(path, 'test/goldens/my_widget_en_375_light_rtl.png');
    });

    test('null textDirection produces no direction suffix (backward compatible)', () {
      final withoutDirection = buildGoldenPath(
        'my_widget',
        const Locale('en'),
        const Size(375, 800),
        ThemeMode.light,
      );
      final withNull = buildGoldenPath(
        'my_widget',
        const Locale('en'),
        const Size(375, 800),
        ThemeMode.light,
        textDirection: null,
      );
      expect(withoutDirection, 'test/goldens/my_widget_en_375_light.png');
      expect(withNull, equals(withoutDirection));
    });

    test('ltr textDirection produces same path as null (no suffix)', () {
      final withNull = buildGoldenPath(
        'card', const Locale('en'), const Size(375, 80), ThemeMode.light,
      );
      final withLtr = buildGoldenPath(
        'card', const Locale('en'), const Size(375, 80), ThemeMode.light,
        textDirection: TextDirection.ltr,
      );
      expect(withLtr, equals(withNull));
    });

    test('rtl and ltr produce distinct paths for same name/locale/width/theme', () {
      final ltr = buildGoldenPath(
        'widget', const Locale('en'), const Size(375, 800), ThemeMode.dark,
      );
      final rtl = buildGoldenPath(
        'widget', const Locale('en'), const Size(375, 800), ThemeMode.dark,
        textDirection: TextDirection.rtl,
      );
      expect(rtl, isNot(equals(ltr)));
      expect(rtl, contains('_rtl.png'));
      expect(ltr, isNot(contains('_rtl.png')));
    });
  });

  group('renderGoldenMatrix', () {
    // renderGoldenMatrix calls renderWidgetToPng internally, so these tests
    // must use testWidgets for the Flutter test binding to be in "inTest" mode.
    testWidgets('renders one PNG per locale x size combination', (tester) async {
      final matrix = await renderGoldenMatrix(
        const Center(child: Text('Matrix')),
        locales: [const Locale('en'), const Locale('es')],
        sizes: [const Size(100, 100), const Size(200, 200)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath(
          'matrix_test',
          locale,
          size,
          theme,
        ),
      );

      // 2 locales x 2 sizes = 4 entries
      expect(matrix.length, 4);

      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
        // PNG magic bytes (first 4 bytes): 0x89 0x50 0x4E 0x47
        expect(entry.value[0], 0x89);
        expect(entry.value[1], 0x50);
        expect(entry.value[2], 0x4E);
        expect(entry.value[3], 0x47);
        // Path follows the buildGoldenPath convention
        expect(entry.key, startsWith('test/goldens/matrix_test_'));
        expect(entry.key, endsWith('.png'));
      }
    });

    testWidgets('produces distinct paths for distinct locales', (tester) async {
      final enMatrix = await renderGoldenMatrix(
        const Center(child: Text('A')),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('x', locale, size, theme),
      );

      final esMatrix = await renderGoldenMatrix(
        const Center(child: Text('A')),
        locales: [const Locale('es')],
        sizes: [const Size(100, 100)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('x', locale, size, theme),
      );

      expect(enMatrix.keys.first, contains('_en_'));
      expect(esMatrix.keys.first, contains('_es_'));
      expect(enMatrix.keys, isNot(equals(esMatrix.keys)));
    });

    testWidgets('returns empty map when locales list is empty', (tester) async {
      final matrix = await renderGoldenMatrix(
        const Center(child: Text('Empty')),
        locales: const [],
        sizes: [const Size(100, 100)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('x', locale, size, theme),
      );

      expect(matrix, isEmpty);
    });

    testWidgets('returns empty map when sizes list is empty', (tester) async {
      final matrix = await renderGoldenMatrix(
        const Center(child: Text('Empty')),
        locales: [const Locale('en')],
        sizes: const [],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('x', locale, size, theme),
      );

      expect(matrix, isEmpty);
    });

    testWidgets('different pixel ratios produce different byte lengths', (tester) async {
      final normal = await renderGoldenMatrix(
        Container(width: 100, height: 100, color: Colors.red),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('pr', locale, size, theme),
      );

      final highRes = await renderGoldenMatrix(
        Container(width: 100, height: 100, color: Colors.red),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeMode: ThemeMode.light,
        pixelRatio: 3.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('pr', locale, size, theme),
      );

      expect(normal.values.first.length, isNot(equals(highRes.values.first.length)));
    });

    testWidgets('dark and light themes produce different bytes', (tester) async {
      final light = await renderGoldenMatrix(
        const Material(child: Center(child: Text('Theme'))),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('theme', locale, size, theme),
      );

      final dark = await renderGoldenMatrix(
        const Material(child: Center(child: Text('Theme'))),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeMode: ThemeMode.dark,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('theme', locale, size, theme),
      );

      expect(light.values.first, isNotEmpty);
      expect(dark.values.first, isNotEmpty);
      expect(light.values.first, isNot(equals(dark.values.first)));
    });
  });

  group('renderGoldenMatrixFull', () {
    testWidgets('renders one PNG per locale x size x theme combination', (tester) async {
      final matrix = await renderGoldenMatrixFull(
        const Material(child: Center(child: Text('Full'))),
        locales: [const Locale('en'), const Locale('es')],
        sizes: [const Size(100, 100), const Size(200, 200)],
        themeModes: [ThemeMode.light, ThemeMode.dark],
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath(
          'full_test',
          locale,
          size,
          theme,
        ),
      );

      // 2 locales x 2 sizes x 2 themes = 8 entries
      expect(matrix.length, 8);

      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
        // PNG magic bytes (first 4 bytes): 0x89 0x50 0x4E 0x47
        expect(entry.value[0], 0x89);
        expect(entry.value[1], 0x50);
        expect(entry.value[2], 0x4E);
        expect(entry.value[3], 0x47);
        expect(entry.key, startsWith('test/goldens/full_test_'));
        expect(entry.key, endsWith('.png'));
      }

      // Verify all theme variations are present
      expect(matrix.keys.where((k) => k.contains('_light.png')), hasLength(4));
      expect(matrix.keys.where((k) => k.contains('_dark.png')), hasLength(4));
    });

    testWidgets('includes both locales in paths', (tester) async {
      final matrix = await renderGoldenMatrixFull(
        const Center(child: Text('X')),
        locales: [const Locale('en'), const Locale('es')],
        sizes: [const Size(100, 100)],
        themeModes: [ThemeMode.light],
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('loc_test', locale, size, theme),
      );

      expect(matrix.keys.where((k) => k.contains('_en_')), hasLength(1));
      expect(matrix.keys.where((k) => k.contains('_es_')), hasLength(1));
    });

    testWidgets('produces distinct bytes for light vs dark', (tester) async {
      final matrix = await renderGoldenMatrixFull(
        const Material(child: Center(child: Text('Theme'))),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeModes: [ThemeMode.light, ThemeMode.dark],
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('theme_test', locale, size, theme),
      );

      final light = matrix.values.first;
      final dark = matrix.values.last;
      expect(light, isNotEmpty);
      expect(dark, isNotEmpty);
      expect(light, isNot(equals(dark)));
    });

    testWidgets('returns empty map when themeModes list is empty', (tester) async {
      final matrix = await renderGoldenMatrixFull(
        const Center(child: Text('Empty')),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeModes: const [],
        pixelRatio: 1.0,
        pathBuilder: (locale, size, theme) => buildGoldenPath('empty_theme', locale, size, theme),
      );

      expect(matrix, isEmpty);
    });

    testWidgets('textDirection rtl produces distinct _rtl-suffixed paths from ltr',
        (tester) async {
      // When the pathBuilder threads `textDirection` into `buildGoldenPath`,
      // RTL and LTR renders must produce different paths — no collision.
      final ltrMatrix = await renderGoldenMatrixFull(
        const Material(child: Center(child: Text('Dir'))),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeModes: [ThemeMode.light],
        pixelRatio: 1.0,
        textDirection: TextDirection.ltr,
        pathBuilder: (locale, size, theme) => buildGoldenPath(
          'dirpath', locale, size, theme,
          textDirection: TextDirection.ltr,
        ),
      );

      final rtlMatrix = await renderGoldenMatrixFull(
        const Material(child: Center(child: Text('Dir'))),
        locales: [const Locale('en')],
        sizes: [const Size(100, 100)],
        themeModes: [ThemeMode.light],
        pixelRatio: 1.0,
        textDirection: TextDirection.rtl,
        pathBuilder: (locale, size, theme) => buildGoldenPath(
          'dirpath', locale, size, theme,
          textDirection: TextDirection.rtl,
        ),
      );

      expect(ltrMatrix.keys.first, 'test/goldens/dirpath_en_100_light.png');
      expect(rtlMatrix.keys.first, 'test/goldens/dirpath_en_100_light_rtl.png');
      expect(rtlMatrix.keys, isNot(equals(ltrMatrix.keys)));
    });
  });

  group('buildGoldenPathWithTextScale', () {
    // Pure-function tests — no widget rendering needed.
    test('encodes text scale with an x separator', () {
      final path = buildGoldenPathWithTextScale(
        'card',
        const Locale('en'),
        const Size(375, 80),
        1.0,
        ThemeMode.light,
      );
      expect(path, 'test/goldens/card_en_375x1.0_light.png');
    });

    test('handles es locale with dark theme and 1.5 scale', () {
      final path = buildGoldenPathWithTextScale(
        'card',
        const Locale('es'),
        const Size(1200, 80),
        1.5,
        ThemeMode.dark,
      );
      expect(path, 'test/goldens/card_es_1200x1.5_dark.png');
    });

    test('floors fractional width to integer', () {
      final path = buildGoldenPathWithTextScale(
        'c',
        const Locale('en'),
        const Size(375.9, 80),
        2.0,
        ThemeMode.system,
      );
      expect(path, 'test/goldens/c_en_375x2.0_system.png');
    });

    test('produces distinct paths for distinct scales', () {
      final a = buildGoldenPathWithTextScale('w', const Locale('en'), const Size(375, 80), 1.0, ThemeMode.light);
      final b = buildGoldenPathWithTextScale('w', const Locale('en'), const Size(375, 80), 2.0, ThemeMode.light);
      expect(a, isNot(equals(b)));
      expect(a, contains('x1.0'));
      expect(b, contains('x2.0'));
    });

    // ---------------------------------------------------------------------------
    // textDirection (RTL) coverage for buildGoldenPathWithTextScale.
    // Same rationale as buildGoldenPath: RTL goldens must get a `_rtl` suffix
    // so they don't collide with their LTR counterparts.
    // ---------------------------------------------------------------------------
    test('rtl textDirection appends _rtl suffix to path', () {
      final path = buildGoldenPathWithTextScale(
        'card', const Locale('en'), const Size(375, 80), 1.0, ThemeMode.light,
        textDirection: TextDirection.rtl,
      );
      expect(path, 'test/goldens/card_en_375x1.0_light_rtl.png');
    });

    test('null textDirection produces no direction suffix (backward compatible)', () {
      final withoutDirection = buildGoldenPathWithTextScale(
        'card', const Locale('en'), const Size(375, 80), 1.5, ThemeMode.dark,
      );
      final withNull = buildGoldenPathWithTextScale(
        'card', const Locale('en'), const Size(375, 80), 1.5, ThemeMode.dark,
        textDirection: null,
      );
      expect(withoutDirection, 'test/goldens/card_en_375x1.5_dark.png');
      expect(withNull, equals(withoutDirection));
    });

    test('ltr textDirection produces same path as null (no suffix)', () {
      final withNull = buildGoldenPathWithTextScale(
        'w', const Locale('es'), const Size(1200, 80), 2.0, ThemeMode.light,
      );
      final withLtr = buildGoldenPathWithTextScale(
        'w', const Locale('es'), const Size(1200, 80), 2.0, ThemeMode.light,
        textDirection: TextDirection.ltr,
      );
      expect(withLtr, equals(withNull));
    });
  });

  group('renderGoldenTextScaleSweep', () {
    // renderGoldenTextScaleSweep calls renderWidgetToPng internally, so these
    // tests must use testWidgets for the Flutter test binding to be in the
    // "in test" mode that AutomatedTestWidgetsFlutterBinding asserts.
    testWidgets('renders one PNG per textScale with distinct scale paths', (tester) async {
      final result = await renderGoldenTextScaleSweep(
        Container(width: 100, height: 100, color: Colors.red),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: [1.0, 1.5, 2.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (locale, size, textScale, theme) => buildGoldenPathWithTextScale(
          'sweep', locale, size, textScale, theme,
        ),
      );

      // 3 scales -> 3 entries
      expect(result.length, 3);

      for (final entry in result.entries) {
        expect(entry.value, isNotEmpty);
        // PNG magic bytes (first 4 bytes): 0x89 0x50 0x4E 0x47
        expect(entry.value[0], 0x89);
        expect(entry.value[1], 0x50);
        expect(entry.value[2], 0x4E);
        expect(entry.value[3], 0x47);
        expect(entry.key, startsWith('test/goldens/sweep_en_100'));
        expect(entry.key, endsWith('.png'));
      }
      expect(result.keys.where((k) => k.contains('x1.0')), hasLength(1));
      expect(result.keys.where((k) => k.contains('x1.5')), hasLength(1));
      expect(result.keys.where((k) => k.contains('x2.0')), hasLength(1));
    });

    testWidgets('produces distinct bytes for different text scales', (tester) async {
      final small = await renderGoldenTextScaleSweep(
        const Center(child: Text('Scale')),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: [1.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (l, s, ts, t) => buildGoldenPathWithTextScale('sc', l, s, ts, t),
      );

      final large = await renderGoldenTextScaleSweep(
        const Center(child: Text('Scale')),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: [3.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (l, s, ts, t) => buildGoldenPathWithTextScale('sc', l, s, ts, t),
      );

      expect(small.values.first, isNotEmpty);
      expect(large.values.first, isNotEmpty);
      expect(small.values.first.length, isNot(equals(large.values.first.length)));
    });

    testWidgets('returns empty map when textScales is empty', (tester) async {
      final result = await renderGoldenTextScaleSweep(
        const SizedBox.shrink(),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: const [],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (l, s, ts, t) => buildGoldenPathWithTextScale('x', l, s, ts, t),
      );

      expect(result, isEmpty);
    });

    testWidgets('textDirection rtl produces distinct _rtl-suffixed paths from ltr',
        (tester) async {
      // When the pathBuilder threads `textDirection` into
      // `buildGoldenPathWithTextScale`, RTL and LTR sweeps must produce
      // different paths — no collision on the same golden file.
      final ltrSweep = await renderGoldenTextScaleSweep(
        const Material(child: Center(child: Text('Dir'))),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: [1.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.ltr,
        pathBuilder: (locale, size, textScale, theme) => buildGoldenPathWithTextScale(
          'sweep_dir', locale, size, textScale, theme,
          textDirection: TextDirection.ltr,
        ),
      );

      final rtlSweep = await renderGoldenTextScaleSweep(
        const Material(child: Center(child: Text('Dir'))),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: [1.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.rtl,
        pathBuilder: (locale, size, textScale, theme) => buildGoldenPathWithTextScale(
          'sweep_dir', locale, size, textScale, theme,
          textDirection: TextDirection.rtl,
        ),
      );

      expect(ltrSweep.keys.first, 'test/goldens/sweep_dir_en_100x1.0_light.png');
      expect(rtlSweep.keys.first, 'test/goldens/sweep_dir_en_100x1.0_light_rtl.png');
      expect(rtlSweep.keys, isNot(equals(ltrSweep.keys)));
    });
  });

  // ---------------------------------------------------------------------------
  // textDirection (RTL) coverage for the matrix helpers.
  //
  // `renderGoldenMatrix` threads `textDirection` through to `renderWidgetToPng`,
  // but the package's own suite never exercised it. This closes the package-level
  // RTL gap for the matrix API surface (the main-repo RTL golden
  // `dashboard_nav_card_golden_test.dart:160` relies on this path).
  // ---------------------------------------------------------------------------
  group('renderGoldenMatrix textDirection', () {
    /// A `Row` with two coloured boxes. `Row` children align to `start`, which
    /// is the left edge in LTR and the right edge in RTL, so the rendered
    /// pixels differ between the two directions.
    Widget directionSensitiveBox() {
      return SizedBox(
        width: 100,
        height: 20,
        child: const Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: ColoredBox(color: Colors.red),
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: ColoredBox(color: Colors.blue),
            ),
          ],
        ),
      );
    }

    testWidgets('rtl produces different bytes from ltr for a direction-sensitive widget',
        (tester) async {
      final ltr = await renderGoldenMatrix(
        directionSensitiveBox(),
        locales: [const Locale('en')],
        sizes: [const Size(100, 50)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        pathBuilder: (l, s, t) => buildGoldenPath('dir', l, s, t),
      );
      final rtl = await renderGoldenMatrix(
        directionSensitiveBox(),
        locales: [const Locale('en')],
        sizes: [const Size(100, 50)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.rtl,
        pathBuilder: (l, s, t) => buildGoldenPath('dir', l, s, t),
      );

      expect(ltr.values.first, isNotEmpty);
      expect(rtl.values.first, isNotEmpty);
      // The Row's `start`-aligned children flip sides, so the pixels differ.
      expect(rtl.values.first, isNot(equals(ltr.values.first)));
    });
  });

  // ---------------------------------------------------------------------------
  // renderScreenGoldenMatrix — the screen-level single-theme matrix helper.
  //
  // This is the single-theme counterpart of renderScreenGoldenMatrixFull and
  // mirrors the renderGoldenMatrix <-> renderGoldenMatrixFull relationship on the
  // widget level. Each cell builds a FRESH MaterialApp via `screenBuilder`, so
  // Overlay-entry reuse errors (Tooltip/PopupMenuButton in an AppBar) cannot
  // occur — the exact trap a single reused widget instance would trigger.
  // ---------------------------------------------------------------------------
  group('renderScreenGoldenMatrix', () {
    /// A screen whose `AppBar` has a `Tooltip` (needs an Overlay ancestor,
    /// provided by the MaterialApp `renderScreenToPng` builds internally).
    Widget tooltipScreen() {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Demo'),
          actions: [
            Tooltip(
              message: 'Action',
              child: const Icon(Icons.star),
            ),
          ],
        ),
        body: const Center(child: Text('Body')),
      );
    }

    testWidgets('renders one PNG per locale x size for a single theme', (tester) async {
      final matrix = await renderScreenGoldenMatrix(
        (_, __) => tooltipScreen(),
        locales: [const Locale('en'), const Locale('es')],
        sizes: [const Size(375, 800), const Size(1200, 800)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en'), Locale('es')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('screen_single', locale, size, theme),
      );

      // 2 locales x 2 sizes = 4 entries (single theme, no theme dimension).
      expect(matrix.length, 4);

      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
        // PNG magic bytes (first 4 bytes): 0x89 0x50 0x4E 0x47
        expect(entry.value[0], 0x89);
        expect(entry.value[1], 0x50);
        expect(entry.value[2], 0x4E);
        expect(entry.value[3], 0x47);
        expect(entry.key, startsWith('test/goldens/screen_single_'));
        expect(entry.key, endsWith('.png'));
      }

      // Only the single requested theme appears in the paths.
      expect(matrix.keys.where((k) => k.contains('_light.png')), hasLength(4));
      expect(matrix.keys.where((k) => k.contains('_dark.png')), isEmpty);
    });

    testWidgets('builds a fresh screen per cell (no shared Overlay entry)', (tester) async {
      var buildCount = 0;
      final matrix = await renderScreenGoldenMatrix(
        (_, __) {
          buildCount++;
          return tooltipScreen();
        },
        locales: [const Locale('en'), const Locale('es')],
        sizes: [const Size(375, 800), const Size(1200, 800)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en'), Locale('es')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('fresh_cell_single', locale, size, theme),
      );

      // 2 locales x 2 sizes = 4 cells => 4 distinct builds.
      expect(matrix.length, 4);
      expect(buildCount, 4);
      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    testWidgets('returns empty map when locales list is empty', (tester) async {
      final matrix = await renderScreenGoldenMatrix(
        (_, __) => tooltipScreen(),
        locales: const [],
        sizes: [const Size(375, 800)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('empty_locale_single', locale, size, theme),
      );

      expect(matrix, isEmpty);
    });

    testWidgets('returns empty map when sizes list is empty', (tester) async {
      final matrix = await renderScreenGoldenMatrix(
        (_, __) => tooltipScreen(),
        locales: [const Locale('en')],
        sizes: const [],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('empty_size_single', locale, size, theme),
      );

      expect(matrix, isEmpty);
    });

    testWidgets('threads textDirection (RTL differs from LTR)', (tester) async {
      /// A Scaffold with a leading (left) red box and trailing (right) blue box.
      /// In LTR the leading icon is on the left; in RTL it moves to the right.
      Widget directionSensitiveScreen(Locale locale, ThemeMode theme) {
        final themeData = theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
        return Theme(
          data: themeData,
          child: Scaffold(
            appBar: AppBar(
              leading: const SizedBox(
                width: 30,
                height: 30,
                child: ColoredBox(color: Colors.red),
              ),
              actions: const [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: ColoredBox(color: Colors.blue),
                ),
              ],
            ),
            body: const Center(child: Text('Screen')),
          ),
        );
      }

      final ltr = await renderScreenGoldenMatrix(
        directionSensitiveScreen,
        locales: [const Locale('en')],
        sizes: [const Size(375, 800)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.ltr,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('dir_ltr_single', locale, size, theme),
      );

      final rtl = await renderScreenGoldenMatrix(
        directionSensitiveScreen,
        locales: [const Locale('en')],
        sizes: [const Size(375, 800)],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.rtl,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('dir_rtl_single', locale, size, theme),
      );

      expect(ltr.values.first, isNotEmpty);
      expect(rtl.values.first, isNotEmpty);
      // The AppBar leading/trailing icons swap sides, so the pixels differ.
      expect(rtl.values.first, isNot(equals(ltr.values.first)));
    });
  });

  // ---------------------------------------------------------------------------
  // renderScreenGoldenMatrixFull — the screen-level full matrix helper.
  //
  // Each cell builds a FRESH MaterialApp via `screenBuilder`, which is what
  // prevents the Overlay-entry reuse errors that `renderGoldenMatrixFull`
  // triggers for screens whose AppBar uses Tooltip/PopupMenuButton. The tests
  // below render exactly that scenario.
  // ---------------------------------------------------------------------------
  group('renderScreenGoldenMatrixFull', () {
    /// A screen whose `AppBar` has a `Tooltip` (needs an Overlay ancestor,
    /// provided by the MaterialApp `renderScreenToPng` builds internally).
    Widget tooltipScreen() {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Demo'),
          actions: [
            Tooltip(
              message: 'Action',
              child: const Icon(Icons.star),
            ),
          ],
        ),
        body: const Center(child: Text('Body')),
      );
    }

    testWidgets('renders one PNG per locale x size x theme combination', (tester) async {
      final matrix = await renderScreenGoldenMatrixFull(
        (_, __) => tooltipScreen(),
        locales: [const Locale('en'), const Locale('es')],
        sizes: [const Size(375, 800), const Size(1200, 800)],
        themeModes: [ThemeMode.light, ThemeMode.dark],
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en'), Locale('es')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('tooltip_screen', locale, size, theme),
      );

      // 2 locales x 2 sizes x 2 themes = 8 entries.
      expect(matrix.length, 8);

      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
        // PNG magic bytes (first 4 bytes): 0x89 0x50 0x4E 0x47
        expect(entry.value[0], 0x89);
        expect(entry.value[1], 0x50);
        expect(entry.value[2], 0x4E);
        expect(entry.value[3], 0x47);
        expect(entry.key, startsWith('test/goldens/tooltip_screen_'));
        expect(entry.key, endsWith('.png'));
      }

      // All matrix dimensions represented in the paths.
      expect(matrix.keys.where((k) => k.contains('_en_')), hasLength(4));
      expect(matrix.keys.where((k) => k.contains('_es_')), hasLength(4));
      expect(matrix.keys.where((k) => k.contains('_light.png')), hasLength(4));
      expect(matrix.keys.where((k) => k.contains('_dark.png')), hasLength(4));
    });

    testWidgets('builds a fresh screen per cell (no shared Overlay entry)', (tester) async {
      var buildCount = 0;
      final matrix = await renderScreenGoldenMatrixFull(
        (_, __) {
          buildCount++;
          return tooltipScreen();
        },
        locales: [const Locale('en')],
        sizes: [const Size(375, 800), const Size(1200, 800)],
        themeModes: [ThemeMode.light, ThemeMode.dark],
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('fresh_cell', locale, size, theme),
      );

      // 1 locale x 2 sizes x 2 themes = 4 cells => 4 distinct builds.
      expect(matrix.length, 4);
      expect(buildCount, 4);
      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    testWidgets('returns empty map when a dimension list is empty', (tester) async {
      final matrix = await renderScreenGoldenMatrixFull(
        (_, __) => tooltipScreen(),
        locales: const [],
        sizes: [const Size(375, 800)],
        themeModes: [ThemeMode.light],
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('empty_dim', locale, size, theme),
      );

      expect(matrix, isEmpty);
    });
  });

  group('renderScreenGoldenTextScaleSweep', () {
    Widget tooltipScreen() {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Demo'),
          actions: [
            Tooltip(
              message: 'Action',
              child: const Icon(Icons.star),
            ),
          ],
        ),
        body: const Center(child: Text('Body')),
      );
    }

    testWidgets('renders one PNG per textScale with distinct paths', (tester) async {
      final result = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => tooltipScreen(),
        locale: const Locale('en'),
        size: const Size(375, 800),
        textScales: [1.0, 1.5, 2.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('sweep', locale, size, textScale, theme),
      );

      expect(result.length, 3);

      for (final entry in result.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.value[0], 0x89);
        expect(entry.value[1], 0x50);
        expect(entry.value[2], 0x4E);
        expect(entry.value[3], 0x47);
        expect(entry.key, startsWith('test/goldens/sweep_en_375'));
        expect(entry.key, endsWith('.png'));
      }
      expect(result.keys.where((k) => k.contains('x1.0')), hasLength(1));
      expect(result.keys.where((k) => k.contains('x1.5')), hasLength(1));
      expect(result.keys.where((k) => k.contains('x2.0')), hasLength(1));
    });

    testWidgets('returns empty map when textScales is empty', (tester) async {
      final result = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => tooltipScreen(),
        locale: const Locale('en'),
        size: const Size(375, 800),
        textScales: const [],
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('empty', locale, size, textScale, theme),
      );

      expect(result, isEmpty);
    });

    testWidgets('builds a fresh screen per cell (Tooltip in AppBar does not crash)', (tester) async {
      var buildCount = 0;
      final result = await renderScreenGoldenTextScaleSweep(
        (_, __) {
          buildCount++;
          return tooltipScreen();
        },
        locale: const Locale('en'),
        size: const Size(375, 800),
        textScales: [1.0, 2.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('fresh', locale, size, textScale, theme),
      );

      expect(result.length, 2);
      expect(buildCount, 2);
      for (final entry in result.entries) {
        expect(entry.value, isNotEmpty);
      }
    });

    testWidgets('different text scales produce different byte lengths', (tester) async {
      final small = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => tooltipScreen(),
        locale: const Locale('en'),
        size: const Size(200, 200),
        textScales: [1.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('small', locale, size, textScale, theme),
      );

      final large = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => tooltipScreen(),
        locale: const Locale('en'),
        size: const Size(200, 200),
        textScales: [3.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('large', locale, size, textScale, theme),
      );

      expect(small.values.first, isNotEmpty);
      expect(large.values.first, isNotEmpty);
      expect(small.values.first.length, isNot(equals(large.values.first.length)));
    });

    testWidgets('honors brightness for ThemeMode.system (dark vs light)', (tester) async {
      final systemDark = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => tooltipScreen(),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: [1.0],
        themeMode: ThemeMode.system,
        pixelRatio: 1.0,
        brightness: Brightness.dark,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('sys_dark', locale, size, textScale, theme),
      );

      final systemLight = await renderScreenGoldenTextScaleSweep(
  (locale, theme) => tooltipScreen(),
        locale: const Locale('en'),
        size: const Size(100, 100),
        textScales: [1.0],
        themeMode: ThemeMode.system,
        pixelRatio: 1.0,
        brightness: Brightness.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('sys_light', locale, size, textScale, theme),
      );

      expect(systemDark.values.first, isNotEmpty);
      expect(systemLight.values.first, isNotEmpty);
      expect(systemDark.values.first, isNot(equals(systemLight.values.first)));
    });
  });

  // ---------------------------------------------------------------------------
  // Screen-level textDirection (RTL) coverage for matrix helpers.
  //
  // `renderScreenGoldenMatrixFull` and `renderScreenGoldenTextScaleSweep` gain
  // a `textDirection` parameter that is forwarded to `renderScreenToPng`. These
  // tests verify that RTL directionality produces different pixels from LTR
  // for a direction-sensitive screen (leading/trailing icons swap) and that
  // the parameter is threaded through both helpers without error.
  // ---------------------------------------------------------------------------
  group('renderScreenGoldenMatrixFull textDirection', () {
    /// A Scaffold with a leading (left) red box and trailing (right) blue box.
    /// In LTR the leading icon is on the left; in RTL it moves to the right.
    Widget directionSensitiveScreen(Locale locale, ThemeMode theme) {
      final themeData = theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
      return Theme(
        data: themeData,
        child: Scaffold(
          appBar: AppBar(
            leading: const SizedBox(
              width: 30,
              height: 30,
              child: ColoredBox(color: Colors.red),
            ),
            actions: const [
              SizedBox(
                width: 30,
                height: 30,
                child: ColoredBox(color: Colors.blue),
              ),
            ],
          ),
          body: const Center(child: Text('Screen')),
        ),
      );
    }

    testWidgets('RTL produces different bytes from LTR for direction-sensitive screens',
        (tester) async {
      final ltr = await renderScreenGoldenMatrixFull(
        directionSensitiveScreen,
        locales: [const Locale('en')],
        sizes: [const Size(375, 800)],
        themeModes: [ThemeMode.light],
        pixelRatio: 1.0,
        textDirection: TextDirection.ltr,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('dir_ltr', locale, size, theme),
      );

      final rtl = await renderScreenGoldenMatrixFull(
        directionSensitiveScreen,
        locales: [const Locale('en')],
        sizes: [const Size(375, 800)],
        themeModes: [ThemeMode.light],
        pixelRatio: 1.0,
        textDirection: TextDirection.rtl,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('dir_rtl', locale, size, theme),
      );

      expect(ltr.values.first, isNotEmpty);
      expect(rtl.values.first, isNotEmpty);
      expect(rtl.values.first, isNot(equals(ltr.values.first)));
    });

    testWidgets('textDirection threads through without error (default LTR)', (tester) async {
      final matrix = await renderScreenGoldenMatrixFull(
        directionSensitiveScreen,
        locales: [const Locale('en')],
        sizes: [const Size(375, 800)],
        themeModes: [ThemeMode.light, ThemeMode.dark],
        pixelRatio: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, theme) =>
            buildGoldenPath('dir_default', locale, size, theme),
      );

      expect(matrix.length, 2);
      for (final entry in matrix.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.value[0], 0x89);
      }
    });
  });

  group('renderScreenGoldenTextScaleSweep textDirection', () {
    Widget directionSensitiveScreen(Locale locale, ThemeMode theme) {
      final themeData = theme == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
      return Theme(
        data: themeData,
        child: Scaffold(
          appBar: AppBar(
            leading: const SizedBox(
              width: 30,
              height: 30,
              child: ColoredBox(color: Colors.red),
            ),
            actions: const [
              SizedBox(
                width: 30,
                height: 30,
                child: ColoredBox(color: Colors.blue),
              ),
            ],
          ),
          body: const Center(child: Text('Screen')),
        ),
      );
    }

    testWidgets('RTL produces different bytes from LTR for direction-sensitive screens',
        (tester) async {
      final ltr = await renderScreenGoldenTextScaleSweep(
        directionSensitiveScreen,
        locale: const Locale('en'),
        size: const Size(375, 800),
        textScales: [1.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.ltr,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('sweep_dir_ltr', locale, size, textScale, theme),
      );

      final rtl = await renderScreenGoldenTextScaleSweep(
        directionSensitiveScreen,
        locale: const Locale('en'),
        size: const Size(375, 800),
        textScales: [1.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.rtl,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('sweep_dir_rtl', locale, size, textScale, theme),
      );

      expect(ltr.values.first, isNotEmpty);
      expect(rtl.values.first, isNotEmpty);
      expect(rtl.values.first, isNot(equals(ltr.values.first)));
    });

    testWidgets('threads through without error for multiple scales', (tester) async {
      final sweeps = await renderScreenGoldenTextScaleSweep(
        directionSensitiveScreen,
        locale: const Locale('en'),
        size: const Size(375, 800),
        textScales: [1.0, 1.5, 2.0],
        themeMode: ThemeMode.light,
        pixelRatio: 1.0,
        textDirection: TextDirection.rtl,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
        pathBuilder: (locale, size, textScale, theme) =>
            buildGoldenPathWithTextScale('sweep_rtl', locale, size, textScale, theme),
      );

      expect(sweeps.length, 3);
      for (final entry in sweeps.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.key, endsWith('.png'));
      }
      expect(sweeps.keys.where((k) => k.contains('x1.0')), hasLength(1));
      expect(sweeps.keys.where((k) => k.contains('x1.5')), hasLength(1));
      expect(sweeps.keys.where((k) => k.contains('x2.0')), hasLength(1));
    });
  });
}
