import 'dart:convert';

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

      test('returns valid JSON array with all fields', () {
        final result = ExtractionResult(
          text: 'test',
          chunks: [
            SourceChunk(chunkIndex: 0, text: 'First chunk'),
          ],
        );

        final out = result.chunksToJson();
        // Output must be valid JSON parseable by jsonDecode.
        final decoded = jsonDecode(out) as List;
        expect(decoded.length, 1);
        final map = decoded.first as Map<String, dynamic>;
        expect(map['chunkIndex'], 0);
        expect(map['text'], 'First chunk');
      });

      test('returns JSON with all fields including optional ones', () {
        final result = ExtractionResult(
          text: 'test',
          chunks: [
            SourceChunk(chunkIndex: 0, text: 'A', heading: 'Intro'),
            SourceChunk(chunkIndex: 1, text: 'B', pageStart: 1, pageEnd: 2),
          ],
        );

        final out = result.chunksToJson();
        final decoded = jsonDecode(out) as List;
        expect(decoded.length, 2);
        final first = decoded[0] as Map<String, dynamic>;
        expect(first['heading'], 'Intro');
        final second = decoded[1] as Map<String, dynamic>;
        expect(second['pageStart'], 1);
        expect(second['pageEnd'], 2);
      });

      test('round-trips through chunksToJson → SourceChunk.parse', () {
        final originalChunks = [
          SourceChunk(chunkIndex: 0, text: 'First', heading: 'Intro', pageStart: 1, pageEnd: 3),
          SourceChunk(chunkIndex: 1, text: 'Second', pageStart: 4, pageEnd: 6),
        ];
        final result = ExtractionResult(text: 'test', chunks: originalChunks);

        final json = result.chunksToJson();
        final parsed = SourceChunk.parse(json);

        expect(parsed.length, 2);
        expect(parsed[0].chunkIndex, 0);
        expect(parsed[0].text, 'First');
        expect(parsed[0].heading, 'Intro');
        expect(parsed[0].pageStart, 1);
        expect(parsed[0].pageEnd, 3);
        expect(parsed[1].chunkIndex, 1);
        expect(parsed[1].text, 'Second');
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
        final parsed = SourceChunk.parse(result.chunksToJson());
        // The empty-text chunk must still round-trip.
        expect(parsed.any((c) => c.text == 'valid'), isTrue);
      });

      test('handles chunk with negative page range', () {
        final result = ExtractionResult(
          text: 'test',
          chunks: [
            SourceChunk(chunkIndex: 0, text: 'A', pageStart: -1, pageEnd: 0),
          ],
        );

        final parsed = SourceChunk.parse(result.chunksToJson());
        expect(parsed.length, 1);
        expect(parsed[0].pageStart, -1);
        expect(parsed[0].pageEnd, 0);
      });
    });

    group('truncation fields', () {
      test('truncated defaults to false and truncationNote to null', () {
        final result = ExtractionResult(text: 'Hello');
        expect(result.truncated, isFalse);
        expect(result.truncationNote, isNull);
      });

      test('toMetaJson omits truncated when false', () {
        final result = ExtractionResult(text: 'Hello');
        final meta = result.toMetaJson();
        expect(meta.containsKey('truncated'), isFalse);
      });

      test('toMetaJson includes truncated and note when set', () {
        final result = ExtractionResult(
          text: 'truncated text',
          truncated: true,
          truncationNote: 'Content truncated for token ceiling',
        );
        final meta = result.toMetaJson();
        expect(meta['truncated'], isTrue);
        expect(meta['truncationNote'], 'Content truncated for token ceiling');
      });

      test('toMetaJson omits truncationNote when truncated but no note', () {
        final result = ExtractionResult(
          text: 'truncated text',
          truncated: true,
        );
        final meta = result.toMetaJson();
        expect(meta['truncated'], isTrue);
        expect(meta.containsKey('truncationNote'), isFalse);
      });
    });
  });
}
