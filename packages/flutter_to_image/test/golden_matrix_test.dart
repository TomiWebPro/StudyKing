import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

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
  });
}
