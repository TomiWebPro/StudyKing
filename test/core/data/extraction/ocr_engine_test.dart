import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';

void main() {
  group('OcrMode.label', () {
    test('fast label is Fast', () {
      expect(OcrMode.fast.label, 'Fast');
    });

    test('accurate label is Accurate', () {
      expect(OcrMode.accurate.label, 'Accurate');
    });

    test('hybrid label is Hybrid', () {
      expect(OcrMode.hybrid.label, 'Hybrid');
    });
  });

  group('OcrMode.fromString', () {
    test('parses fast', () {
      expect(OcrMode.fromString('fast'), OcrMode.fast);
    });

    test('parses accurate', () {
      expect(OcrMode.fromString('accurate'), OcrMode.accurate);
    });

    test('parses hybrid', () {
      expect(OcrMode.fromString('hybrid'), OcrMode.hybrid);
    });

    test('returns hybrid for null', () {
      expect(OcrMode.fromString(null), OcrMode.hybrid);
    });

    test('returns hybrid for unknown string garbage', () {
      expect(OcrMode.fromString('garbage'), OcrMode.hybrid);
    });

    test('normalizes input via .normalized (trim and case-insensitive)', () {
      expect(OcrMode.fromString(' FAST '), OcrMode.fast);
      expect(OcrMode.fromString('ACCURATE'), OcrMode.accurate);
      expect(OcrMode.fromString(' Hybrid '), OcrMode.hybrid);
      expect(OcrMode.fromString(' FaSt'), OcrMode.fast);
    });

    test('returns hybrid for empty and whitespace strings', () {
      expect(OcrMode.fromString(''), OcrMode.hybrid);
      expect(OcrMode.fromString('   '), OcrMode.hybrid);
    });

    test('returns hybrid for unknown strings with whitespace', () {
      expect(OcrMode.fromString(' unknown '), OcrMode.hybrid);
    });
  });

  group('OcrMode.toString', () {
    test('returns enum name', () {
      expect(OcrMode.fast.toString(), 'fast');
      expect(OcrMode.accurate.toString(), 'accurate');
      expect(OcrMode.hybrid.toString(), 'hybrid');
    });
  });

  group('OcrMode.prefersOnDeviceFirst', () {
    test('is true for fast and hybrid, false for accurate', () {
      expect(OcrMode.fast.prefersOnDeviceFirst, isTrue);
      expect(OcrMode.hybrid.prefersOnDeviceFirst, isTrue);
      expect(OcrMode.accurate.prefersOnDeviceFirst, isFalse);
    });
  });
}
