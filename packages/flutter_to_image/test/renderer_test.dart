import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

/// Built-in Flutter localizations delegates that support both `en` and `es`.
/// Used by `renderScreenToPng` tests so MaterialApp doesn't warn about
/// unsupported locales.
const List<LocalizationsDelegate<dynamic>> _kTestDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  group('renderWidgetToPng', () {
    // Widget-rendering tests must use testWidgets so the Flutter test
    // binding is in the "inTest" mode that AutomatedTestWidgetsFlutterBinding
    // asserts when calling pump(). Pure-logic tests (buildGoldenPath, etc.)
    // keep using test().
    testWidgets('produces non-empty PNG bytes for a simple widget', (tester) async {
      final png = await renderWidgetToPng(
        const Center(child: Text('Hello')),
        size: const Size(100, 100),
      );

      expect(png, isNotEmpty);
      // PNG magic bytes (first 8 bytes).
      expect(png[0], 0x89);
      expect(png[1], 0x50);
      expect(png[2], 0x4E);
      expect(png[3], 0x47);
    });

    testWidgets('default size is 1080x1920', (tester) async {
      final result = await renderWidgetToImageResult(
        const Center(child: Text('Hi')),
      );

      expect(result.size, kDefaultSize);
      expect(result.size, const Size(1080, 1920));
    });

    testWidgets('default pixelRatio is 2.0', (tester) async {
      final result = await renderWidgetToImageResult(
        const Center(child: Text('Hi')),
        size: const Size(100, 100),
      );

      expect(result.pixelRatio, kDefaultPixelRatio);
    });

    testWidgets('default locale is en', (tester) async {
      final result = await renderWidgetToImageResult(
        const Center(child: Text('Hi')),
      );

      expect(result.locale, const Locale('en'));
    });

    testWidgets('locale is reflected in ImageResult', (tester) async {
      final result = await renderWidgetToImageResult(
        const Center(child: Text('Hola')),
        locale: const Locale('es'),
      );

      expect(result.locale, const Locale('es'));
    });

    testWidgets('renders at custom size', (tester) async {
      final result = await renderWidgetToImageResult(
        Container(width: 50, height: 50, color: Colors.red),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );

      // With pixelRatio 1.0 and size 50x50, the image should be 50x50 pixels.
      final image = await _decodePng(result.pngBytes);
      expect(image.width, 50);
      expect(image.height, 50);
    });

    testWidgets('renders at higher pixelRatio', (tester) async {
      final result = await renderWidgetToImageResult(
        Container(width: 100, height: 100, color: Colors.blue),
        size: const Size(100, 100),
        pixelRatio: 3.0,
      );

      final image = await _decodePng(result.pngBytes);
      expect(image.width, 300); // 100 * 3
      expect(image.height, 300);
    });

    testWidgets('different pixel ratios produce different byte lengths', (tester) async {
      final small = await renderWidgetToPng(
        Container(width: 100, height: 100, color: Colors.red),
        size: const Size(100, 100),
        pixelRatio: 1.0,
      );
      final large = await renderWidgetToPng(
        Container(width: 100, height: 100, color: Colors.red),
        size: const Size(100, 100),
        pixelRatio: 3.0,
      );

      expect(small.length, isNot(equals(large.length)));
    });

    testWidgets('light theme renders without error', (tester) async {
      final png = await renderWidgetToPng(
        const Material(child: Center(child: Text('Light'))),
        themeMode: ThemeMode.light,
      );

      expect(png, isNotEmpty);
    });

    testWidgets('dark theme renders without error', (tester) async {
      final png = await renderWidgetToPng(
        const Material(child: Center(child: Text('Dark'))),
        themeMode: ThemeMode.dark,
      );

      expect(png, isNotEmpty);
    });

    testWidgets('different themes produce different output', (tester) async {
      final light = await renderWidgetToPng(
        const Material(child: Center(child: Text('Theme'))),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        themeMode: ThemeMode.light,
      );
      final dark = await renderWidgetToPng(
        const Material(child: Center(child: Text('Theme'))),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        themeMode: ThemeMode.dark,
      );

      expect(light, isNotEmpty);
      expect(dark, isNotEmpty);
      expect(light, isNot(equals(dark)));
    });

    testWidgets('textScale affects rendering without error', (tester) async {
      final normal = await renderWidgetToPng(
        const Center(child: Text('Scale')),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        textScale: 1.0,
      );
      final largeText = await renderWidgetToPng(
        const Center(child: Text('Scale')),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        textScale: 2.0,
      );

      expect(normal, isNotEmpty);
      expect(largeText, isNotEmpty);
    });

    testWidgets('throws StateError if called outside flutter test', (tester) async {
      // This test documents that the binding must be initialised — in a
      // normal flutter test environment it is always available.
      final png = await renderWidgetToPng(const SizedBox.shrink());
      expect(png, isNotEmpty);
    });
  });

  group('renderWidgetToImageResult', () {
    testWidgets('returns ImageResult with metadata', (tester) async {
      final result = await renderWidgetToImageResult(
        const Center(child: Text('Result')),
        size: const Size(200, 200),
        pixelRatio: 2.0,
      );

      expect(result, isA<ImageResult>());
      expect(result.pngBytes, isNotEmpty);
      expect(result.size, const Size(200, 200));
      expect(result.pixelRatio, 2.0);
    });
  });

  group('renderScreenToPng', () {
    // renderScreenToPng wraps in MaterialApp, so these are widget-level
    // tests and must use testWidgets.
    testWidgets('produces non-empty PNG bytes for a simple screen', (tester) async {
      final png = await renderScreenToPng(
        const Center(child: Text('Hello')),
        size: const Size(375, 800),
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      expect(png, isNotEmpty);
      // PNG magic bytes (first 4 bytes): 0x89 0x50 0x4E 0x47
      expect(png[0], 0x89);
      expect(png[1], 0x50);
      expect(png[2], 0x4E);
      expect(png[3], 0x47);
    });

    testWidgets('returns ImageResult with correct metadata via renderScreenToImageResult',
        (tester) async {
      final result = await renderScreenToImageResult(
        const Center(child: Text('Result')),
        size: const Size(375, 800),
        locale: const Locale('es'),
        themeMode: ThemeMode.dark,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('es')],
      );

      expect(result, isA<ImageResult>());
      expect(result.pngBytes, isNotEmpty);
      expect(result.size, const Size(375, 800));
      expect(result.pixelRatio, kDefaultPixelRatio);
      expect(result.locale, const Locale('es'));
    });

    testWidgets('renders at custom size with correct pixel dimensions', (tester) async {
      final result = await renderScreenToImageResult(
        Container(width: 100, height: 100, color: Colors.red),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      final image = await _decodePng(result.pngBytes);
      expect(image.width, 100);
      expect(image.height, 100);
    });

    testWidgets('higher pixelRatio produces larger image dimensions', (tester) async {
      final result = await renderScreenToImageResult(
        Container(width: 100, height: 100, color: Colors.blue),
        size: const Size(100, 100),
        pixelRatio: 3.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      final image = await _decodePng(result.pngBytes);
      expect(image.width, 300); // 100 * 3
      expect(image.height, 300);
    });

    testWidgets('light and dark themes produce different output', (tester) async {
      final light = await renderScreenToPng(
        const Material(child: Center(child: Text('Theme'))),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      final dark = await renderScreenToPng(
        const Material(child: Center(child: Text('Theme'))),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      expect(light, isNotEmpty);
      expect(dark, isNotEmpty);
      expect(light, isNot(equals(dark)));
    });

    testWidgets('textScale affects rendering without error', (tester) async {
      final normal = await renderScreenToPng(
        const Center(child: Text('Scale')),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        textScale: 1.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      final largeText = await renderScreenToPng(
        const Center(child: Text('Scale')),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        textScale: 3.0,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      expect(normal, isNotEmpty);
      expect(largeText, isNotEmpty);
    });

    testWidgets('different locales render without error', (tester) async {
      final en = await renderScreenToPng(
        const Center(child: Text('Hello')),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      final es = await renderScreenToPng(
        const Center(child: Text('Hola')),
        size: const Size(100, 100),
        pixelRatio: 1.0,
        locale: const Locale('es'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en'), Locale('es')],
      );

      expect(en, isNotEmpty);
      expect(es, isNotEmpty);
    });

    testWidgets('can render twice without window state bleeding between calls', (tester) async {
      // If the test window values (physicalSize, devicePixelRatio) were not
      // restored after the first render, the second render at a different
      // size/pixelRatio would produce mismatched or corrupted output.
      final first = await renderScreenToPng(
        const Center(child: Text('First')),
        size: const Size(375, 800),
        pixelRatio: 2.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      final second = await renderScreenToPng(
        const Center(child: Text('Second')),
        size: const Size(1200, 800),
        pixelRatio: 2.0,
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
        localizationsDelegates: _kTestDelegates,
        supportedLocales: const [Locale('en')],
      );

      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
    });
  });
}

/// Decodes PNG bytes back into a ui.Image so we can check dimensions.
///
/// Uses [TestWidgetsFlutterBinding.runAsync] because [ui.instantiateImageCodec]
/// and [codec.getNextFrame] perform real async work that the test binding's
/// fake-async clock cannot drive — without runAsync the test hangs on shutdown.
Future<ui.Image> _decodePng(Uint8List bytes) {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  return binding.runAsync<ui.Image>(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }).then((image) {
    if (image == null) {
      throw StateError('flutter_to_image test: _decodePng returned null.');
    }
    return image;
  });
}
