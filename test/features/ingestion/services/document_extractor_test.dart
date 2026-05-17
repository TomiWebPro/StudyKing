import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';

class _FakeOcrExtractor extends OcrExtractor {
  _FakeOcrExtractor() : super(modelId: 'test');

  @override
  Future<OcrExtractionResult> extractText({
    required String rawContent,
    required String? sourceUrl,
  }) async {
    return const OcrExtractionResult(
      text: '',
      extractionMethod: 'ocr_failed',
      errorMessage: 'Simulated OCR failure',
    );
  }
}

void main() {
  group('DocumentExtractor', () {
    group('extractText', () {
      test('returns direct text for SourceType.pdf', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'pdf content',
          sourceType: SourceType.pdf,
        );
        expect(result.text, 'pdf content');
        expect(result.extractionMethod, 'pdf_text_direct');
      });

      test('returns direct text for SourceType.document', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'doc content',
          sourceType: SourceType.document,
        );
        expect(result.text, 'doc content');
      });

      test('returns direct text for SourceType.textbook', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'textbook content',
          sourceType: SourceType.textbook,
        );
        expect(result.text, 'textbook content');
      });

      test('returns direct text for SourceType.syllabus', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'syllabus content',
          sourceType: SourceType.syllabus,
        );
        expect(result.text, 'syllabus content');
      });

      test('returns direct text for SourceType.lectureNotes', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'notes content',
          sourceType: SourceType.lectureNotes,
        );
        expect(result.text, 'notes content');
      });

      test('returns direct text for SourceType.externalResource', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'resource content',
          sourceType: SourceType.externalResource,
        );
        expect(result.text, 'resource content');
      });

      test('strips HTML for SourceType.webPage', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: '<html><body><p>Hello world content here</p></body></html>',
          sourceType: SourceType.webPage,
        );
        expect(result.text, contains('Hello world content here'));
        expect(result.extractionMethod, 'html_stripped');
      });

      test('passes through non-HTML for SourceType.webPage', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'plain text content',
          sourceType: SourceType.webPage,
        );
        expect(result.text, 'plain text content');
        expect(result.extractionMethod, 'web_direct');
      });

      test('returns image file path for SourceType.image with file://', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'file:///path/to/image.png',
          sourceType: SourceType.image,
        );
        expect(result.text, 'file:///path/to/image.png');
        expect(result.extractionMethod, 'image_file');
        expect(result.mimeType, 'image/png');
      });

      test('returns image URL for SourceType.image with http URL', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'https://example.com/photo.jpg',
          sourceType: SourceType.image,
        );
        expect(result.text, 'https://example.com/photo.jpg');
        expect(result.extractionMethod, 'image_url');
      });

      test('returns video raw content for SourceType.video', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'transcript content',
          sourceType: SourceType.video,
        );
        expect(result.text, 'transcript content');
        expect(result.extractionMethod, 'video_raw');
      });

      test('detects YouTube URL for SourceType.video', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'https://youtube.com/watch?v=abc123',
          sourceType: SourceType.video,
        );
        expect(result.text, 'https://youtube.com/watch?v=abc123');
        expect(result.extractionMethod, 'youtube_url');
      });

      test('returns audio raw content for SourceType.audio', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'audio transcript',
          sourceType: SourceType.audio,
        );
        expect(result.text, 'audio transcript');
        expect(result.extractionMethod, 'audio_raw');
      });

      test('detects URL for SourceType.audio', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'https://example.com/audio.mp3',
          sourceType: SourceType.audio,
        );
        expect(result.text, 'https://example.com/audio.mp3');
        expect(result.extractionMethod, 'audio_url');
      });

      test('populates extraction metadata via toMetaJson', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: 'some content',
          sourceType: SourceType.pdf,
        );
        final meta = result.toMetaJson();
        expect(meta['extractionMethod'], isNotEmpty);
      });

      test('handles empty content gracefully', () async {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final result = await extractor.extractText(
          rawContent: '',
          sourceType: SourceType.pdf,
        );
        expect(result.text, '');
        expect(result.extractionMethod, 'pdf_empty');
      });

      test('returns error when OCR extraction fails', () async {
        final extractor = DocumentExtractor(
          modelId: 'test-model',
          ocrExtractor: _FakeOcrExtractor(),
        );
        final result = await extractor.extractText(
          rawContent: 'test content',
          sourceType: SourceType.image,
        );
        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Simulated OCR failure'));
      });
    });

    group('estimateChunkCount', () {
      test('returns 0 for empty string', () {
        final extractor = DocumentExtractor(modelId: 'test-model');
        expect(extractor.estimateChunkCount(''), 0);
      });

      test('returns 1 for text shorter than chunkSize', () {
        final extractor = DocumentExtractor(modelId: 'test-model');
        expect(extractor.estimateChunkCount('hello'), 1);
      });

      test('returns 1 for text exactly fitting chunkSize', () {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final text = 'a' * 2000;
        expect(extractor.estimateChunkCount(text), 1);
      });

      test('returns 2 for text at chunkSize boundary + 1', () {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final text = 'a' * 2001;
        expect(extractor.estimateChunkCount(text), 2);
      });

      test('handles single character', () {
        final extractor = DocumentExtractor(modelId: 'test-model');
        expect(extractor.estimateChunkCount('x'), 1);
      });

      test('handles custom chunkSize', () {
        final extractor = DocumentExtractor(modelId: 'test-model');
        final text = 'a' * 500;
        expect(extractor.estimateChunkCount(text, chunkSize: 100), 5);
      });
    });

    group('stripHtmlToText', () {
      test('strips HTML tags from content', () {
        final result = DocumentExtractor.stripHtmlToText(
          '<html><body><p>This is a paragraph with enough text to pass the minimum length filter.</p></body></html>',
        );
        expect(result, 'This is a paragraph with enough text to pass the minimum length filter.');
      });

      test('removes script and style tags', () {
        final result = DocumentExtractor.stripHtmlToText(
          '<html><head><style>.css{color:red}</style></head><body><script>alert("x")</script><p>This is a paragraph with enough text to pass the minimum length filter.</p></body></html>',
        );
        expect(result, 'This is a paragraph with enough text to pass the minimum length filter.');
      });

      test('returns empty for HTML with no text', () {
        final result = DocumentExtractor.stripHtmlToText(
          '<html><head></head><body></body></html>',
        );
        expect(result, isEmpty);
      });
    });
  });
}
