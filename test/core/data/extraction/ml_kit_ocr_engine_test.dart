import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/ml_kit_ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';

void main() {
  group('MlKitOcrEngine', () {
    final engine = MlKitOcrEngine();

    test('exposes engine name and confidence support', () {
      expect(engine.name, 'ml_kit');
      expect(engine.supportsConfidence, isTrue);
    });

    test('returns a failure result on unsupported platforms without throwing',
        () async {
      final result = await engine.recognize(
        const OcrImageInput(rawContent: 'file:///x.png', bytes: [1, 2, 3]),
      );
      expect(result.isFailure, isTrue);
      // On non-mobile hosts ML Kit cannot run, so the engine degrades
      // gracefully and lets the caller fall back to the LLM engine.
      expect(result.error, contains('ml_kit_unavailable'));
    });
  });
}
