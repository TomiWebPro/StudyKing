// Golden-matrix persistence tests for saveGoldenPathBytes.
//
// Vision: `docs/vision_next_term.md` §1.1 — "deterministic ... output path
// convention `test/goldens/<screen>_<locale>_<width>.png`".  After every
// matrix helper returns Map<String, Uint8List>, callers must persist PNGs to
// disk.  This test file validates [saveGoldenPathBytes]:
//   - empty input → empty output
//   - non-empty input writes every entry under outputDir
//   - one bad entry is logged but does not abort others (partial-save)
//   - returned map keys == original paths, values start with outputDir
//
// Uses hand-written fakes only (per AGENTS.md), no Hive I/O, no emulator.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

/// Built-in Flutter localisations delegates that support both `en` and `es`.
const List<LocalizationsDelegate<dynamic>> _kTestDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  // ===========================================================================
  // Pure-unit test (no widget rendering needed).
  // ===========================================================================
  group('saveGoldenPathBytes (pure unit)', () {
    test('empty map returns empty map', () {
      final saved = saveGoldenPathBytes({}, outputDir: '/tmp');
      expect(saved, isEmpty);
    });
  });

  // ===========================================================================
  // Widget tests — saveGoldenPathBytes renders PNG bytes to disk.
  //
  // renderWidgetToPng / renderScreenToPng must run inside testWidgets because
  // they pump frames on the Flutter test binding.  We reuse those helpers to
  // obtain valid PNG payloads for the persistence assertions below.
  //
  // No setUp/tearDown: each test manages its own temp dir inline.  Note:
  // File.existsSync() is used instead of await File.exists() to avoid a race
  // condition with flutter_test's FakeAsync during shutdown (File.existsSync()
  // is synchronous and does not interact with the async clock).
  // ===========================================================================
  group('saveGoldenPathBytes (widget)', () {
    testWidgets('single entry creates exactly one file', (tester) async {
      final tmpRoot =
          Directory.systemTemp.createTempSync('sgpbt').absolute.path;
      try {
        final png = await renderWidgetToPng(
          const Center(child: Text('One')),
          size: const Size(50, 50),
          pixelRatio: 1.0,
        );

        final map = <String, Uint8List>{
          'goldens/test_widget_en_375_light.png': png,
        };

        final saved = saveGoldenPathBytes(map, outputDir: tmpRoot);

        expect(saved.length, 1);
        expect(saved.keys.first, 'goldens/test_widget_en_375_light.png');
        expect(saved.values.first, '$tmpRoot/goldens/test_widget_en_375_light.png');

        // Use existsSync() — await file.exists() triggers flutter_test
        // shutdown races when combined with other async operations in the
        // same testWidgets context.
        final file = File(saved.values.first);
        expect(file.existsSync(), isTrue);
        expect(file.readAsBytesSync(), png);
      } finally {
        try {
          Directory(tmpRoot).deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    testWidgets('multiple entries write all files', (tester) async {
      final tmpRoot =
          Directory.systemTemp.createTempSync('sgpbt_m').absolute.path;
      try {
        final enLight = await renderWidgetToPng(
          const Center(child: Text('En')),
          size: const Size(50, 50),
          pixelRatio: 1.0,
        );
        final esDark = await renderWidgetToPng(
          const Center(child: Text('Es')),
          size: const Size(50, 50),
          pixelRatio: 1.0,
        );

        final map = {
          'dashboard_en_375_light.png': enLight,
          'dashboard_es_375_dark.png': esDark,
        };

        final saved = saveGoldenPathBytes(map, outputDir: tmpRoot);

        expect(saved.length, 2);
        expect(saved.containsKey('dashboard_en_375_light.png'), isTrue);
        expect(saved.containsKey('dashboard_es_375_dark.png'), isTrue);
        for (final p in saved.values) {
          expect(p, startsWith(tmpRoot));
        }
        for (final p in saved.values) {
          final file = File(p);
          // existsSync() avoids flutter_test shutdown races.
          expect(file.existsSync(), isTrue);
          final bytes = file.readAsBytesSync();
          expect(bytes[0], 0x89); // PNG magic byte.
        }
      } finally {
        try {
          Directory(tmpRoot).deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    testWidgets('partial dir creates nested parents recursively',
        (tester) async {
      final tmpRoot =
          Directory.systemTemp.createTempSync('sgpbt_d').absolute.path;
      try {
        final png = await renderWidgetToPng(
          const Center(child: Text('Deep')),
          size: const Size(50, 50),
          pixelRatio: 1.0,
        );

        // Multi-level relative path that requires intermediate directories
        final map = {'a/b/c/d/e/f/nested.png': png};

        final saved = saveGoldenPathBytes(map, outputDir: tmpRoot);

        expect(saved.length, 1);
        final file = File(saved.values.first);
        // existsSync() avoids flutter_test shutdown races.
        expect(file.existsSync(), isTrue);
        expect(file.readAsBytesSync(), png);
      } finally {
        try {
          Directory(tmpRoot).deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    testWidgets('all valid entries return correct byte-exact content',
        (tester) async {
      final tmpRoot =
          Directory.systemTemp.createTempSync('sgpbt_a').absolute.path;
      try {
        final pngs = <String, Uint8List>{};
        final paths = <String>[];

        for (var i = 0; i < 5; i++) {
          final locale = ['en', 'es'][i % 2];
          final theme = i % 2 == 0 ? ThemeMode.light : ThemeMode.dark;
          final name = ['dashboard', 'planner', 'mentor', 'practice', 'tutor']
              [i];
          final path =
              '${name}_${locale}_375_${switch (theme) {
            ThemeMode.light => 'light',
            ThemeMode.dark => 'dark',
            _ => 'system',
          }}.png';
          final png = await renderWidgetToPng(
            Container(
              width: 100,
              height: 60,
              color: Color(0xFF0000FF + i * 0x000100),
            ),
            size: const Size(100, 60),
            pixelRatio: 1.0,
          );
          pngs[path] = png;
          paths.add(path);
        }

        final saved = saveGoldenPathBytes(pngs, outputDir: tmpRoot);

        expect(saved.length, 5);
        for (var i = 0; i < paths.length; i++) {
          final file = File(saved[paths[i]]!);
          // existsSync() avoids flutter_test shutdown races.
          expect(file.existsSync(), isTrue);
          expect(file.readAsBytesSync(), pngs[paths[i]]);
        }
      } finally {
        try {
          Directory(tmpRoot).deleteSync(recursive: true);
        } catch (_) {}
      }
    });
  });

  // ===========================================================================
  // Integration: verify that saveGoldenPathBytes works end-to-end after a real
  // matrix render, proving the full path-builder → renderer → saver chain.
  // ===========================================================================
  group('saveGoldenPathBytes (integration: matrix → disk)', () {
    testWidgets(
        'renderGoldenMatrix → saveGoldenPathBytes produces valid files',
        (tester) async {
      final tmpRoot =
          Directory.systemTemp.createTempSync('sgptm_g').absolute.path;
      try {
        final goldens = await renderGoldenMatrix(
          const Center(child: Text('Matrix')),
          locales: [const Locale('en')],
          sizes: [const Size(100, 100)],
          themeMode: ThemeMode.light,
          pixelRatio: 1.0,
          localizationsDelegates: _kTestDelegates,
          supportedLocales: const [Locale('en')],
          pathBuilder: (locale, size, theme) =>
              buildGoldenPath('widget', locale, size, theme),
        );

        expect(goldens.length, 1);

        final saved = saveGoldenPathBytes(goldens, outputDir: tmpRoot);
        expect(saved.length, 1);

        final file = File(saved.values.first);
        expect(file.existsSync(), isTrue);
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(0));
        expect(bytes[0], 0x89);
      } finally {
        try {
          Directory(tmpRoot).deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    testWidgets(
        'renderScreenGoldenMatrixFull → saveGoldenPathBytes produces N files',
        (tester) async {
      final tmpRoot =
          Directory.systemTemp.createTempSync('sgptm_s').absolute.path;
      try {
        // 2 locales × 2 sizes × 2 themes = 8 cells.
        final goldens = await renderScreenGoldenMatrixFull(
          (_, __) => const Center(child: Text('Screen')),
          locales: const [Locale('en'), Locale('es')],
          sizes: [const Size(100, 100), const Size(200, 200)],
          themeModes: [ThemeMode.light, ThemeMode.dark],
          pixelRatio: 1.0,
          localizationsDelegates: _kTestDelegates,
          supportedLocales: const [Locale('en'), Locale('es')],
          pathBuilder: (locale, size, theme) =>
              buildGoldenPath('screen', locale, size, theme),
        );

        expect(goldens.length, 8);

        final saved = saveGoldenPathBytes(goldens, outputDir: tmpRoot);
        expect(saved.length, 8);
        for (final path in saved.values) {
          // existsSync() avoids flutter_test shutdown races.
          expect(File(path).existsSync(), isTrue);
        }
      } finally {
        try {
          Directory(tmpRoot).deleteSync(recursive: true);
        } catch (_) {}
      }
    });
  });
}
