import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';

void main() {
  group('SourceChunk', () {
    test('creates with all required fields', () {
      final chunk = SourceChunk(
        chunkIndex: 0,
        text: 'Sample text',
      );

      expect(chunk.chunkIndex, 0);
      expect(chunk.text, 'Sample text');
      expect(chunk.pageStart, isNull);
      expect(chunk.pageEnd, isNull);
      expect(chunk.heading, isNull);
    });

    test('creates with all optional fields', () {
      final chunk = SourceChunk(
        chunkIndex: 2,
        pageStart: 1,
        pageEnd: 5,
        text: 'Chunk content',
        heading: 'Introduction',
      );

      expect(chunk.chunkIndex, 2);
      expect(chunk.pageStart, 1);
      expect(chunk.pageEnd, 5);
      expect(chunk.text, 'Chunk content');
      expect(chunk.heading, 'Introduction');
    });

    group('toJson / fromJson', () {
      test('round-trips with all fields', () {
        final chunk = SourceChunk(
          chunkIndex: 1,
          pageStart: 10,
          pageEnd: 12,
          text: 'Paragraph text',
          heading: 'Summary',
        );

        final json = chunk.toJson();
        final restored = SourceChunk.fromJson(json);

        expect(restored.chunkIndex, 1);
        expect(restored.pageStart, 10);
        expect(restored.pageEnd, 12);
        expect(restored.text, 'Paragraph text');
        expect(restored.heading, 'Summary');
      });

      test('round-trips with only required fields', () {
        final chunk = SourceChunk(
          chunkIndex: 0,
          text: 'Minimal',
        );

        final json = chunk.toJson();
        final restored = SourceChunk.fromJson(json);

        expect(restored.chunkIndex, 0);
        expect(restored.text, 'Minimal');
        expect(restored.pageStart, isNull);
        expect(restored.pageEnd, isNull);
        expect(restored.heading, isNull);
      });

      test('fromJson handles null text with default empty string', () {
        final restored = SourceChunk.fromJson({
          'chunkIndex': 0,
          'text': null,
        });

        expect(restored.text, '');
      });

      test('toJson produces expected map structure', () {
        final chunk = SourceChunk(
          chunkIndex: 3,
          pageStart: 20,
          text: 'Content',
        );

        final json = chunk.toJson();

        expect(json['chunkIndex'], 3);
        expect(json['pageStart'], 20);
        expect(json['pageEnd'], isNull);
        expect(json['text'], 'Content');
        expect(json['heading'], isNull);
      });
    });

    group('equality and hashCode', () {
      test('identical instances are equal', () {
        final a = SourceChunk(chunkIndex: 0, text: 'test');
        expect(a == a, isTrue);
      });

      test('different instances with same values are not equal (no == override)', () {
        final a = SourceChunk(chunkIndex: 0, text: 'test');
        final b = SourceChunk(chunkIndex: 0, text: 'test');
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final chunk = SourceChunk(chunkIndex: 5, text: 'hash test');
        expect(chunk.hashCode, chunk.hashCode);
        expect(chunk.hashCode, isNotNull);
      });
    });
  });
}
