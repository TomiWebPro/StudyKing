import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';

void main() {
  group('OcrMode.label', () {
    test('fast returns Fast', () {
      expect(OcrMode.fast.label, 'Fast');
    });

    test('accurate returns Accurate', () {
      expect(OcrMode.accurate.label, 'Accurate');
    });

    test('hybrid returns Hybrid', () {
      expect(OcrMode.hybrid.label, 'Hybrid');
    });
  });

  group('OcrMode.prefersOnDeviceFirst', () {
    test('fast prefers on-device first', () {
      expect(OcrMode.fast.prefersOnDeviceFirst, isTrue);
    });

    test('hybrid prefers on-device first', () {
      expect(OcrMode.hybrid.prefersOnDeviceFirst, isTrue);
    });

    test('accurate does not prefer on-device first', () {
      expect(OcrMode.accurate.prefersOnDeviceFirst, isFalse);
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

    test('returns hybrid for unknown value', () {
      expect(OcrMode.fromString('unknown'), OcrMode.hybrid);
      expect(OcrMode.fromString('bogus'), OcrMode.hybrid);
      expect(OcrMode.fromString(''), OcrMode.hybrid);
      expect(OcrMode.fromString('  '), OcrMode.hybrid);
    });

    test('is case-insensitive via normalized', () {
      expect(OcrMode.fromString('FAST'), OcrMode.fast);
      expect(OcrMode.fromString('Fast'), OcrMode.fast);
      expect(OcrMode.fromString('ACCURATE'), OcrMode.accurate);
      expect(OcrMode.fromString('Accurate'), OcrMode.accurate);
      expect(OcrMode.fromString('HYBRID'), OcrMode.hybrid);
      expect(OcrMode.fromString('Hybrid'), OcrMode.hybrid);
    });

    test('trims whitespace via normalized', () {
      expect(OcrMode.fromString(' fast '), OcrMode.fast);
      expect(OcrMode.fromString('  accurate  '), OcrMode.accurate);
      expect(OcrMode.fromString(' hybrid '), OcrMode.hybrid);
      expect(OcrMode.fromString('\tFAST\n'), OcrMode.fast);
    });

    test('handles mixed case and whitespace together', () {
      expect(OcrMode.fromString('  FAST  '), OcrMode.fast);
      expect(OcrMode.fromString('  AccUrAte  '), OcrMode.accurate);
      expect(OcrMode.fromString('  HyBrId  '), OcrMode.hybrid);
    });
  });

  group('OcrMode.toString', () {
    test('returns enum name', () {
      expect(OcrMode.fast.toString(), 'fast');
      expect(OcrMode.accurate.toString(), 'accurate');
      expect(OcrMode.hybrid.toString(), 'hybrid');
    });
  });

  group('OcrEngineResult.hasText', () {
    test('returns false for empty text', () {
      const result = OcrEngineResult(text: '', engineName: 'test');
      expect(result.hasText, isFalse);
    });

    test('returns false for whitespace-only text', () {
      const result = OcrEngineResult(text: '   ', engineName: 'test');
      expect(result.hasText, isFalse);
    });

    test('returns false for whitespace with newlines/tabs', () {
      const result = OcrEngineResult(text: ' \n\t  ', engineName: 'test');
      expect(result.hasText, isFalse);
    });

    test('returns true for non-empty text', () {
      const result = OcrEngineResult(text: 'hello', engineName: 'test');
      expect(result.hasText, isTrue);
    });

    test('returns true for text with surrounding whitespace', () {
      const result = OcrEngineResult(text: '  hello world  ', engineName: 'test');
      expect(result.hasText, isTrue);
    });
  });

  group('OcrEngineResult', () {
    test('stores fields correctly', () {
      const result = OcrEngineResult(
        text: 'sample',
        confidence: 0.85,
        segments: [OcrSegment('sample', 0.85)],
        engineName: 'ml_kit',
        duration: Duration(milliseconds: 100),
      );
      expect(result.text, 'sample');
      expect(result.confidence, 0.85);
      expect(result.segments, hasLength(1));
      expect(result.engineName, 'ml_kit');
      expect(result.duration, const Duration(milliseconds: 100));
    });

    test('defaults segments to empty and confidence/duration to null', () {
      const result = OcrEngineResult(text: 'x', engineName: 'llm');
      expect(result.segments, isEmpty);
      expect(result.confidence, isNull);
      expect(result.duration, isNull);
    });
  });

  group('OcrSegment', () {
    test('stores text and confidence', () {
      const segment = OcrSegment('word', 0.9);
      expect(segment.text, 'word');
      expect(segment.confidence, 0.9);
    });
  });

  group('OcrImageInput', () {
    test('stores rawContent and optional fields', () {
      const input = OcrImageInput(
        rawContent: 'https://example.com/a.png',
        bytes: [1, 2, 3],
        filePath: '/tmp/a.png',
        sourceUrl: 'https://example.com/a.png',
      );
      expect(input.rawContent, 'https://example.com/a.png');
      expect(input.bytes, [1, 2, 3]);
      expect(input.filePath, '/tmp/a.png');
      expect(input.sourceUrl, 'https://example.com/a.png');
    });

    test('optional fields default to null', () {
      const input = OcrImageInput(rawContent: 'base64data');
      expect(input.bytes, isNull);
      expect(input.filePath, isNull);
      expect(input.sourceUrl, isNull);
    });
  });
}
