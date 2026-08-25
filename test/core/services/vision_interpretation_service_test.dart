import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/services/vision_interpretation_service.dart';

class _FakeOcrExtractor extends OcrExtractor {
  final Future<OcrExtractionResult> Function(String rawContent, String? sourceUrl) _onExtract;

  _FakeOcrExtractor(this._onExtract)
      : super(modelId: 'fake-model', localeName: 'en');

  @override
  Future<OcrExtractionResult> extractText({
    required String rawContent,
    required String? sourceUrl,
  }) =>
      _onExtract(rawContent, sourceUrl);
}

void main() {
  group('VisionInterpretationService', () {
    test('returns recognized text on successful OCR', () async {
      final extractor = _FakeOcrExtractor((rawContent, _) async {
        expect(rawContent, isA<String>());
        return const OcrExtractionResult(
          text: '3x + 2 = 8',
          extractionMethod: 'ocr_llm',
        );
      });
      final service = VisionInterpretationService(ocrExtractor: extractor);

      final result = await service.interpretImage(Uint8List.fromList([1, 2, 3]));

      expect(result.isSuccess, isTrue);
      expect(result.data, '3x + 2 = 8');
    });

    test('returns failure when OCR reports an error', () async {
      final extractor = _FakeOcrExtractor((_, _) async => const OcrExtractionResult(
            text: '',
            extractionMethod: 'ocr_llm_failed',
            errorMessage: 'model not available',
          ));
      final service = VisionInterpretationService(ocrExtractor: extractor);

      final result = await service.interpretImage(Uint8List.fromList([9, 9]));

      expect(result.isFailure, isTrue);
      expect(result.error, contains('model not available'));
    });

    test('returns failure when no text is recognized', () async {
      final extractor = _FakeOcrExtractor((_, _) async => const OcrExtractionResult(
            text: '   ',
            extractionMethod: 'ocr_empty_result',
          ));
      final service = VisionInterpretationService(ocrExtractor: extractor);

      final result = await service.interpretImage(Uint8List.fromList([4, 5, 6]));

      expect(result.isFailure, isTrue);
    });

    test('returns failure for empty image', () async {
      final extractor = _FakeOcrExtractor((_, _) async => const OcrExtractionResult(
            text: 'x',
            extractionMethod: 'ocr_llm',
          ));
      final service = VisionInterpretationService(ocrExtractor: extractor);

      final result = await service.interpretImage(Uint8List(0));

      expect(result.isFailure, isTrue);
      expect(result.error, contains('empty'));
    });

    test('encodes image to base64 before passing to OCR', () async {
      String? captured;
      final extractor = _FakeOcrExtractor((rawContent, _) async {
        captured = rawContent;
        return const OcrExtractionResult(text: 'hi', extractionMethod: 'ocr_llm');
      });
      final service = VisionInterpretationService(ocrExtractor: extractor);
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      await service.interpretImage(bytes);

      expect(captured, base64Encode(bytes));
    });
  });
}
