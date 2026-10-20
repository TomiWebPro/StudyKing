import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Result of comparing two images with [compareImages].
///
/// Provides pixel-level difference metadata and a visual diff PNG that can
/// be attached to an issue so reviewers can see exactly which pixels changed.
///
/// See: `docs/vision_next_term.md` §1.1 — "Agent loop: visual diffs are
/// attached to issues (expected vs actual PNG + diff)".
@immutable
class ImageComparisonResult {
  /// Whether the two images are considered matching.
  ///
  /// True when `differingPixels / totalPixels ≤ tolerance` (passed to
  /// [compareImages]).
  final bool matches;

  /// Number of pixels that differ between the expected and actual images.
  final int differingPixels;

  /// Total number of pixels compared.
  final int totalPixels;

  /// Percentage of pixels that differ (0.0 to 100.0).
  ///
  /// Returns `0.0` when [totalPixels] is zero.
  double get percentDifferent =>
      totalPixels == 0 ? 0.0 : (differingPixels / totalPixels) * 100.0;

  /// Diff PNG bytes. Matching pixels are copied from the expected image;
  /// differing pixels are replaced with the `highlightColor` from
  /// [compareImages].
  final Uint8List diffPng;

  /// Width of the compared images in physical pixels.
  final int width;

  /// Height of the compared images in physical pixels.
  final int height;

  const ImageComparisonResult({
    required this.matches,
    required this.differingPixels,
    required this.totalPixels,
    required this.diffPng,
    required this.width,
    required this.height,
  });
}

/// Compares two PNG images pixel-by-pixel and returns an [ImageComparisonResult].
///
/// [expected] and [actual] are PNG-encoded byte arrays. Both images must have
/// the same dimensions; a dimension mismatch throws a [StateError].
///
/// The returned [ImageComparisonResult.diffPng] highlights the differences:
/// matching pixels are copied from [expected] so the diff image remains a
/// recognisable base, and differing pixels are painted with [highlightColor]
/// (default `Colors.red`). This diff PNG can be attached to an issue so
/// reviewers can *see* exactly which pixels changed.
///
/// [tolerance] is an acceptable *fraction* of differing pixels (0.0–1.0).
/// When the proportion of differing pixels falls at or below [tolerance],
/// [ImageComparisonResult.matches] is `true`. This is useful for tolerating
/// anti-aliasing jitter between golden regeneration runs (e.g. a tolerance
/// of `0.05` allows up to 5 % of pixels to differ).
///
/// Example — producing a diff PNG for an issue:
///
/// ```dart
/// final expected = await renderScreenToPng(
///   const MyScreen(),
///   size: const Size(375, 800),
///   locale: const Locale('en'),
///   themeMode: ThemeMode.light,
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
/// );
/// final actual = /* ... re-rendered after a change ... */;
///
/// final result = await compareImages(expected, actual);
/// if (!result.matches) {
///   // Attach result.diffPng to the issue for visual review.
///   print('${result.differingPixels}/${result.totalPixels} pixels differ '
///         '(${result.percentDifferent.toStringAsFixed(2)}%)');
/// }
/// ```
///
/// Must be called from within a `testWidgets` callback (like
/// [renderWidgetToPng]) because [ui.instantiateImageCodec] and
/// [Image.toByteData] perform real engine async work that the test
/// binding's FakeAsync clock cannot drive.
Future<ImageComparisonResult> compareImages(
  Uint8List expected,
  Uint8List actual, {
  Color highlightColor = Colors.red,
  double tolerance = 0.0,
}) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // --- Decode both PNG byte arrays into ui.Image objects. ---
  //
  // instantiateImageCodec and codec.getNextFrame() perform real async work
  // (PNG decoding) that the FakeAsync clock in flutter_test cannot drive.
  // They must run inside runAsync so the real event-loop can process them.
  final expectedImage = await binding.runAsync<ui.Image>(() async {
    final codec = await ui.instantiateImageCodec(expected);
    final frame = await codec.getNextFrame();
    return frame.image;
  });
  if (expectedImage == null) {
    throw StateError('flutter_to_image: failed to decode expected PNG bytes.');
  }

  final actualImage = await binding.runAsync<ui.Image>(() async {
    final codec = await ui.instantiateImageCodec(actual);
    final frame = await codec.getNextFrame();
    return frame.image;
  });
  if (actualImage == null) {
    throw StateError('flutter_to_image: failed to decode actual PNG bytes.');
  }

  // --- Guard: both images must have the same dimensions. ---
  if (expectedImage.width != actualImage.width ||
      expectedImage.height != actualImage.height) {
    throw StateError(
      'flutter_to_image: image dimensions do not match '
      '(expected ${expectedImage.width}\u00d7${expectedImage.height}, '
      'actual ${actualImage.width}×${actualImage.height}).',
    );
  }

  final width = expectedImage.width;
  final height = expectedImage.height;
  final totalPixels = width * height;
  const bytesPerPixel = 4; // RGBA
  final totalBytes = totalPixels * bytesPerPixel;

  // --- Extract raw premultiplied RGBA bytes from both images. ---
  final expectedByteData = await binding.runAsync<ByteData?>(() async {
    return expectedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  });
  final actualByteData = await binding.runAsync<ByteData?>(() async {
    return actualImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  });
  if (expectedByteData == null || actualByteData == null) {
    throw StateError(
      'flutter_to_image: failed to extract raw pixel data from one or both images.',
    );
  }

  final expectedPixels = expectedByteData.buffer
      .asUint8List(expectedByteData.offsetInBytes, expectedByteData.lengthInBytes);
  final actualPixels = actualByteData.buffer
      .asUint8List(actualByteData.offsetInBytes, actualByteData.lengthInBytes);

  // --- Pixel-by-pixel comparison + collect differing positions. ---
  int differingPixels = 0;
  final diffPoints = <double>[];

  for (int i = 0; i < totalBytes; i += bytesPerPixel) {
    final differs = expectedPixels[i] != actualPixels[i] ||
        expectedPixels[i + 1] != actualPixels[i + 1] ||
        expectedPixels[i + 2] != actualPixels[i + 2] ||
        expectedPixels[i + 3] != actualPixels[i + 3];

    if (differs) {
      differingPixels++;
      final pixelIndex = i ~/ bytesPerPixel;
      final x = pixelIndex % width;
      final y = pixelIndex ~/ width;
      diffPoints.add(x.toDouble());
      diffPoints.add(y.toDouble());
    }
  }

  // --- Build the diff PNG: expected image as base + highlight overlay. ---
  //
  // We use PictureRecorder + Canvas.drawImage for the base (correct format
  // handling by the engine) and drawRawPoints for the highlight overlay.
  // This avoids any raw-byte-endianness ambiguity that
  // decodeImageFromPixelsSync would carry.
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );

  // Draw the expected image as the recognisable base layer.
  canvas.drawImage(expectedImage, Offset.zero, Paint());

  // Overlay the highlight colour on every differing pixel.
  if (diffPoints.isNotEmpty) {
    final highlightPaint = Paint()..color = highlightColor;
    canvas.drawRawPoints(
      ui.PointMode.points,
      Float32List.fromList(diffPoints),
      highlightPaint,
    );
  }

  final picture = recorder.endRecording();

  // toImageSync is synchronous (no runAsync needed); only PNG encoding
  // performs real engine async work that needs runAsync.
  final diffImage = picture.toImageSync(width, height);

  final pngByteData = await binding.runAsync<ByteData?>(() async {
    return diffImage.toByteData(format: ui.ImageByteFormat.png);
  });
  if (pngByteData == null) {
    throw StateError(
      'flutter_to_image: failed to encode diff image to PNG.',
    );
  }

  final diffPng = pngByteData.buffer
      .asUint8List(pngByteData.offsetInBytes, pngByteData.lengthInBytes);

  final matches =
      totalPixels == 0 || (differingPixels / totalPixels) <= tolerance;

  return ImageComparisonResult(
    matches: matches,
    differingPixels: differingPixels,
    totalPixels: totalPixels,
    diffPng: diffPng,
    width: width,
    height: height,
  );
}
