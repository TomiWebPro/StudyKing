import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';

void main() {
  group('OcrExtractor', () {
    late OcrExtractor extractor;

    setUp(() {
      extractor = OcrExtractor();
    });

    group('extractText', () {
      test('returns empty result for file:// path without LLM', () async {
        final result = await extractor.extractText(
          rawContent: 'file:///path/to/image.png',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'image_file_not_found');
      });

      test('returns empty result for http URL without LLM', () async {
        final result = await extractor.extractText(
          rawContent: 'https://example.com/photo.jpg',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'image_url_no_llm');
      });

      test('returns empty for base64 content without LLM', () async {
        final result = await extractor.extractText(
          rawContent: 'SGVsbG8gV29ybGQ=' * 10,
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'image_base64_no_llm');
      });

      test('returns empty for short content that appears as raw', () async {
        final result = await extractor.extractText(
          rawContent: 'short text',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'ocr_no_llm_available');
      });

      test('returns empty for base64 shorter than 100 chars', () async {
        final result = await extractor.extractText(
          rawContent: 'abc123',
          sourceUrl: null,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'ocr_no_llm_available');
      });
    });
  });
}
