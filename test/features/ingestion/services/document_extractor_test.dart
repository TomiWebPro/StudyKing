import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';

void main() {
  group('DocumentExtractor', () {
    group('extractText', () {
      test('returns rawContent for SourceType.pdf', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'pdf content', sourceType: SourceType.pdf), 'pdf content');
      });

      test('returns rawContent for SourceType.document', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'doc content', sourceType: SourceType.document), 'doc content');
      });

      test('returns rawContent for SourceType.textbook', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'textbook content', sourceType: SourceType.textbook), 'textbook content');
      });

      test('returns rawContent for SourceType.syllabus', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'syllabus content', sourceType: SourceType.syllabus), 'syllabus content');
      });

      test('returns rawContent for SourceType.lectureNotes', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'notes content', sourceType: SourceType.lectureNotes), 'notes content');
      });

      test('returns rawContent for SourceType.externalResource', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'resource content', sourceType: SourceType.externalResource), 'resource content');
      });

      test('returns rawContent for SourceType.webPage', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'web content', sourceType: SourceType.webPage), 'web content');
      });

      test('returns rawContent for SourceType.image', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'image ocr content', sourceType: SourceType.image), 'image ocr content');
      });

      test('returns rawContent for SourceType.video', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'transcript content', sourceType: SourceType.video), 'transcript content');
      });

      test('returns rawContent for SourceType.audio', () {
        final extractor = DocumentExtractor();
        expect(extractor.extractText(rawContent: 'audio transcript', sourceType: SourceType.audio), 'audio transcript');
      });
    });

    group('estimateChunkCount', () {
      test('returns 0 for empty string', () {
        final extractor = DocumentExtractor();
        expect(extractor.estimateChunkCount(''), 0);
      });

      test('returns 1 for text shorter than chunkSize', () {
        final extractor = DocumentExtractor();
        expect(extractor.estimateChunkCount('hello'), 1);
      });

      test('returns 1 for text exactly fitting chunkSize', () {
        final extractor = DocumentExtractor();
        final text = 'a' * 2000;
        expect(extractor.estimateChunkCount(text), 1);
      });

      test('returns 2 for text at chunkSize boundary + 1', () {
        final extractor = DocumentExtractor();
        final text = 'a' * 2001;
        expect(extractor.estimateChunkCount(text), 2);
      });

      test('handles single character', () {
        final extractor = DocumentExtractor();
        expect(extractor.estimateChunkCount('x'), 1);
      });

      test('handles custom chunkSize', () {
        final extractor = DocumentExtractor();
        final text = 'a' * 500;
        expect(extractor.estimateChunkCount(text, chunkSize: 100), 5);
      });
    });
  });
}
