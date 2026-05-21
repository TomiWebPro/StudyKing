import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/services/extraction_result.dart';

void main() {
  group('ExtractionResult', () {
    test('creates with default values', () {
      final result = ExtractionResult(text: 'Hello');

      expect(result.text, 'Hello');
      expect(result.extractionMethod, 'direct');
      expect(result.pageCount, isNull);
      expect(result.ocrConfidence, isNull);
      expect(result.durationSeconds, isNull);
      expect(result.mimeType, isNull);
      expect(result.chunks, isEmpty);
    });

    test('creates with all fields', () {
      final result = ExtractionResult(
        text: 'Full result',
        extractionMethod: 'ocr',
        pageCount: 10,
        ocrConfidence: 0.95,
        durationSeconds: 120,
        mimeType: 'application/pdf',
        chunks: [
          SourceChunk(chunkIndex: 0, text: 'Chunk 1'),
          SourceChunk(chunkIndex: 1, text: 'Chunk 2'),
        ],
      );

      expect(result.text, 'Full result');
      expect(result.extractionMethod, 'ocr');
      expect(result.pageCount, 10);
      expect(result.ocrConfidence, 0.95);
      expect(result.durationSeconds, 120);
      expect(result.mimeType, 'application/pdf');
      expect(result.chunks.length, 2);
    });

    group('toMetaJson', () {
      test('includes only extractionMethod when no optional fields set', () {
        final result = ExtractionResult(text: 'test');
        final meta = result.toMetaJson();

        expect(meta, {'extractionMethod': 'direct'});
      });

      test('includes all non-null optional fields', () {
        final result = ExtractionResult(
          text: 'test',
          extractionMethod: 'pdf',
          pageCount: 5,
          ocrConfidence: 0.85,
          durationSeconds: 300,
          mimeType: 'application/pdf',
        );
        final meta = result.toMetaJson();

        expect(meta['extractionMethod'], 'pdf');
        expect(meta['pageCount'], 5);
        expect(meta['ocrConfidence'], 0.85);
        expect(meta['durationSeconds'], 300);
        expect(meta['mimeType'], 'application/pdf');
      });

      test('omits null optional fields', () {
        final result = ExtractionResult(
          text: 'test',
          pageCount: null,
          ocrConfidence: null,
          durationSeconds: null,
          mimeType: null,
        );
        final meta = result.toMetaJson();

        expect(meta.keys, ['extractionMethod']);
      });

      test('includes subset of optional fields', () {
        final result = ExtractionResult(
          text: 'test',
          extractionMethod: 'web',
          pageCount: 3,
        );
        final meta = result.toMetaJson();

        expect(meta['extractionMethod'], 'web');
        expect(meta['pageCount'], 3);
        expect(meta.containsKey('ocrConfidence'), isFalse);
        expect(meta.containsKey('durationSeconds'), isFalse);
        expect(meta.containsKey('mimeType'), isFalse);
      });
    });

    group('chunksToJson', () {
      test('returns empty string when chunks is empty', () {
        final result = ExtractionResult(text: 'test');
        expect(result.chunksToJson(), '');
      });

      test('returns wrapped chunks when chunks present', () {
        final result = ExtractionResult(
          text: 'test',
          chunks: [
            SourceChunk(chunkIndex: 0, text: 'First chunk'),
          ],
        );

        final out = result.chunksToJson();
        expect(out, startsWith('['));
        expect(out, endsWith(']'));
        expect(out, contains('chunkIndex: 0'));
        expect(out, contains('text: First chunk'));
      });

      test('returns combined string for multiple chunks', () {
        final result = ExtractionResult(
          text: 'test',
          chunks: [
            SourceChunk(chunkIndex: 0, text: 'A', heading: 'Intro'),
            SourceChunk(chunkIndex: 1, text: 'B', pageStart: 1, pageEnd: 2),
          ],
        );

        final out = result.chunksToJson();
        expect(out, contains('chunkIndex: 0'));
        expect(out, contains('chunkIndex: 1'));
        expect(out, contains('heading: Intro'));
        expect(out, contains('pageStart: 1'));
      });
    });

    group('error path', () {
      test('isError returns true when errorMessage is set', () {
        final result = ExtractionResult(
          text: '',
          errorMessage: 'Extraction failed: OCR timeout',
        );
        expect(result.isError, isTrue);
      });

      test('isError returns false when no errorMessage', () {
        final result = ExtractionResult(text: 'success');
        expect(result.isError, isFalse);
      });

      test('toMetaJson includes errorMessage when set', () {
        final result = ExtractionResult(
          text: '',
          errorMessage: 'Failed',
          extractionMethod: 'ocr',
        );
        final meta = result.toMetaJson();
        expect(meta.containsKey('errorMessage'), isTrue);
        expect(meta['errorMessage'], 'Failed');
      });

      test('toMetaJson omits errorMessage when not set', () {
        final result = ExtractionResult(text: 'success');
        final meta = result.toMetaJson();
        expect(meta.containsKey('errorMessage'), isFalse);
      });

      test('handles chunk with empty text gracefully', () {
        final result = ExtractionResult(
          text: 'parent',
          chunks: [
            SourceChunk(chunkIndex: 0, text: ''),
            SourceChunk(chunkIndex: 1, text: 'valid'),
          ],
        );
        final out = result.chunksToJson();
        expect(out, contains('chunkIndex: 1'));
      });

      test('handles chunk with negative page range', () {
        final result = ExtractionResult(
          text: 'test',
          chunks: [
            SourceChunk(chunkIndex: 0, text: 'A', pageStart: -1, pageEnd: 0),
          ],
        );
        final out = result.chunksToJson();
        expect(out, contains('pageStart: -1'));
      });
    });
  });
}
