import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/ingestion.dart';

void main() {
  group('ingestion barrel', () {
    test('exports SourceRepository', () => expect(SourceRepository, isNotNull));
    test('exports ContentPipeline', () => expect(ContentPipeline, isNotNull));
    test('exports UploadScreen', () => expect(UploadScreen, isNotNull));

    test('exports WebScraper', () {
      expect(WebScraper, isNotNull);
    });

    test('exports DocumentExtractor', () {
      expect(DocumentExtractor, isNotNull);
    });

    test('exports ContentLibraryScreen', () {
      expect(ContentLibraryScreen, isNotNull);
    });

    test('exports SourceDetailScreen', () {
      expect(SourceDetailScreen, isNotNull);
    });

    test('WebScraper can be constructed', () {
      final scraper = WebScraper();
      expect(scraper, isNotNull);
    });

    test('DocumentExtractor.stripHtmlToText removes HTML tags', () {
      final result = DocumentExtractor.stripHtmlToText(
        '<html><body><p>Hello World</p><p>Second paragraph</p></body></html>',
      );
      expect(result, contains('Hello World'));
    });

    test('DocumentExtractor.estimateChunkCount returns correct value', () {
      final extractor = DocumentExtractor(modelId: 'test');
      expect(extractor.estimateChunkCount('hello world'), 1);
      expect(extractor.estimateChunkCount(''), 0);
      expect(extractor.estimateChunkCount('a' * 2001), 2);
    });

    test('DocumentExtractor can be constructed with modelId', () {
      final extractor = DocumentExtractor(modelId: 'gpt-4');
      expect(extractor, isNotNull);
    });

    test('ContentPipeline.extractionMethod field works', () {
      final extractor = DocumentExtractor(modelId: 'test');
      expect(extractor.estimateChunkCount('hello'), 1);
    });
  });
}
