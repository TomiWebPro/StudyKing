import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

void main() {
  group('compareImages', () {
    // --- Pixel-perfect comparison ------------------------------------------

    testWidgets('identical images produce matching result with zero diffs',
        (tester) async {
      final png = await renderWidgetToPng(
        Container(width: 100, height: 100, color: Colors.red),
        size: const Size(100, 100),
        pixelRatio: 1.0,
      );

      final result = await compareImages(png, png);

      expect(result.matches, isTrue);
      expect(result.differingPixels, 0);
      expect(result.totalPixels, 100 * 100);
      expect(result.percentDifferent, 0.0);
      expect(result.width, 100);
      expect(result.height, 100);
      // Diff PNG is valid.
      expect(result.diffPng, isNotEmpty);
      expect(result.diffPng[0], 0x89);
      expect(result.diffPng[1], 0x50);
      expect(result.diffPng[2], 0x4E);
      expect(result.diffPng[3], 0x47);
    });

    testWidgets('identical small images produce matching result', (tester) async {
      final png = await renderWidgetToPng(
        Container(width: 10, height: 10, color: Colors.green),
        size: const Size(10, 10),
        pixelRatio: 1.0,
      );

      final result = await compareImages(png, png);

      expect(result.matches, isTrue);
      expect(result.differingPixels, 0);
      expect(result.totalPixels, 100);
    });

    // --- Different images --------------------------------------------------

    testWidgets('different images produce non-matching result', (tester) async {
      final expected = await renderWidgetToPng(
        Container(width: 100, height: 100, color: Colors.red),
        size: const Size(100, 100),
        pixelRatio: 1.0,
      );

      final actual = await renderWidgetToPng(
        Container(width: 100, height: 100, color: Colors.blue),
        size: const Size(100, 100),
        pixelRatio: 1.0,
      );

      final result = await compareImages(expected, actual);

      expect(result.matches, isFalse);
      expect(result.differingPixels, greaterThan(0));
      expect(result.percentDifferent, greaterThan(0));
      expect(result.width, 100);
      expect(result.height, 100);
      expect(result.totalPixels, 100 * 100);
      // Diff PNG is valid.
      expect(result.diffPng, isNotEmpty);
      expect(result.diffPng[0], 0x89);
      expect(result.diffPng[1], 0x50);
      expect(result.diffPng[2], 0x4E);
      expect(result.diffPng[3], 0x47);
    });

    testWidgets('diff PNG differs from expected and actual when images differ',
        (tester) async {
      final expected = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.red),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );

      final actual = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.blue),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );

      final result = await compareImages(expected, actual);

      // The diff PNG has the highlight overlay, so it differs from both inputs.
      expect(result.diffPng, isNotEmpty);
      expect(result.diffPng, isNot(equals(expected)));
      expect(result.diffPng, isNot(equals(actual)));
    });

    // --- Diff image is a valid PNG with correct dimensions -----------------

    testWidgets('diff PNG is a valid PNG with correct magic bytes',
        (tester) async {
      final png = await renderWidgetToPng(
        Container(width: 64, height: 64, color: Colors.orange),
        size: const Size(64, 64),
        pixelRatio: 1.0,
      );

      final result = await compareImages(png, png);

      // PNG magic bytes (first 8 bytes).
      expect(result.diffPng[0], 0x89);
      expect(result.diffPng[1], 0x50);
      expect(result.diffPng[2], 0x4E);
      expect(result.diffPng[3], 0x47);
      expect(result.diffPng[4], 0x0D);
      expect(result.diffPng[5], 0x0A);
      expect(result.diffPng[6], 0x1A);
      expect(result.diffPng[7], 0x0A);
    });

    testWidgets('diff image dimensions match input dimensions', (tester) async {
      final png = await renderWidgetToPng(
        Container(width: 80, height: 60, color: Colors.purple),
        size: const Size(80, 60),
        pixelRatio: 1.0,
      );

      final result = await compareImages(png, png);

      expect(result.width, 80);
      expect(result.height, 60);
    });

    // --- Tolerance ---------------------------------------------------------

    testWidgets('tolerance 0.0 requires exact match', (tester) async {
      final red = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.red),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );
      final blue = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.blue),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );

      final matchResult = await compareImages(red, red, tolerance: 0.0);
      expect(matchResult.matches, isTrue);

      final diffResult = await compareImages(red, blue, tolerance: 0.0);
      expect(diffResult.matches, isFalse);
    });

    testWidgets('tolerance 1.0 accepts any difference', (tester) async {
      final red = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.red),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );
      final blue = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.blue),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );

      final result = await compareImages(red, blue, tolerance: 1.0);

      // 100% of pixels may differ, so this is a "match".
      expect(result.matches, isTrue);
      expect(result.differingPixels, greaterThan(0));
    });

    testWidgets('tolerance is a fractional threshold on percentage',
        (tester) async {
      // Build two 100×100 images where the right half differs:
      // expected = left half red, right half blue
      // actual   = all red
      // → ~50% of pixels differ.
      final expected = await renderWidgetToPng(
        Row(
          children: [
            Expanded(child: Container(color: Colors.red)),
            Expanded(child: Container(color: Colors.blue)),
          ],
        ),
        size: const Size(100, 100),
        pixelRatio: 1.0,
      );

      final actual = await renderWidgetToPng(
        Container(width: 100, height: 100, color: Colors.red),
        size: const Size(100, 100),
        pixelRatio: 1.0,
      );

      final result = await compareImages(expected, actual);

      // Roughly half the pixels differ.
      expect(result.differingPixels, greaterThan(4000));
      expect(result.differingPixels, lessThan(6000));

      // With a 50% tolerance the half-diff should match (boundary inclusive).
      final nearMatch = await compareImages(expected, actual, tolerance: 0.50);
      expect(nearMatch.matches, isTrue);

      // With 10% tolerance the half-diff should NOT match.
      final clearMismatch =
          await compareImages(expected, actual, tolerance: 0.10);
      expect(clearMismatch.matches, isFalse);
    });

    // --- Custom highlight color -------------------------------------------

    testWidgets('custom highlight color produces different diff from default',
        (tester) async {
      final red = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.red),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );
      final blue = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.blue),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );

      final redHighlight = await compareImages(
        red, blue,
        highlightColor: Colors.red,
      );

      final greenHighlight = await compareImages(
        red, blue,
        highlightColor: Colors.green,
      );

      // Red and green highlights produce different diff PNGs.
      expect(redHighlight.diffPng, isNot(equals(greenHighlight.diffPng)));
    });

    // --- Dimension mismatch ------------------------------------------------

    testWidgets('throws StateError when image dimensions differ', (tester) async {
      final small = await renderWidgetToPng(
        Container(width: 50, height: 50, color: Colors.red),
        size: const Size(50, 50),
        pixelRatio: 1.0,
      );

      final large = await renderWidgetToPng(
        Container(width: 100, height: 100, color: Colors.blue),
        size: const Size(100, 100),
        pixelRatio: 1.0,
      );

      expect(
        () => compareImages(small, large),
        throwsA(isA<StateError>()),
      );
    });

    // --- ImageComparisonResult.percentDifferent ---------------------------

    testWidgets('percentDifferent is 0 for identical images', (tester) async {
      final png = await renderWidgetToPng(
        Container(width: 30, height: 30, color: Colors.red),
        size: const Size(30, 30),
        pixelRatio: 1.0,
      );

      final result = await compareImages(png, png);

      expect(result.percentDifferent, 0.0);
    });

    testWidgets('percentDifferent is 100 for completely different images',
        (tester) async {
      final red = await renderWidgetToPng(
        Container(width: 20, height: 20, color: Colors.red),
        size: const Size(20, 20),
        pixelRatio: 1.0,
      );
      final blue = await renderWidgetToPng(
        Container(width: 20, height: 20, color: Colors.blue),
        size: const Size(20, 20),
        pixelRatio: 1.0,
      );

      final result = await compareImages(red, blue);

      // All pixels differ.
      expect(result.percentDifferent, 100.0);
      expect(result.differingPixels, result.totalPixels);
    });

    // --- Edge case: 1×1 image ---------------------------------------------

    testWidgets('1x1 images work correctly', (tester) async {
      final red = await renderWidgetToPng(
        Container(width: 1, height: 1, color: Colors.red),
        size: const Size(1, 1),
        pixelRatio: 1.0,
      );
      final blue = await renderWidgetToPng(
        Container(width: 1, height: 1, color: Colors.blue),
        size: const Size(1, 1),
        pixelRatio: 1.0,
      );

      final sameResult = await compareImages(red, red);
      expect(sameResult.matches, isTrue);
      expect(sameResult.differingPixels, 0);
      expect(sameResult.percentDifferent, 0.0);

      final diffResult = await compareImages(red, blue);
      expect(diffResult.matches, isFalse);
      expect(diffResult.differingPixels, 1);
      expect(diffResult.percentDifferent, 100.0);
    });
  });
}
