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

    group('toJson', () {
      test('produces expected map structure with all fields', () {
        final chunk = SourceChunk(
          chunkIndex: 3,
          pageStart: 20,
          pageEnd: 25,
          text: 'Content',
          heading: 'Section',
        );

        final json = chunk.toJson();

        expect(json['chunkIndex'], 3);
        expect(json['pageStart'], 20);
        expect(json['pageEnd'], 25);
        expect(json['text'], 'Content');
        expect(json['heading'], 'Section');
      });

      test('serializes null optional fields', () {
        final chunk = SourceChunk(chunkIndex: 0, text: 'test');

        final json = chunk.toJson();

        expect(json['chunkIndex'], 0);
        expect(json['pageStart'], isNull);
        expect(json['pageEnd'], isNull);
        expect(json['text'], 'test');
        expect(json['heading'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'chunkIndex': 1,
          'pageStart': 10,
          'pageEnd': 12,
          'text': 'Paragraph text',
          'heading': 'Summary',
        };
        final chunk = SourceChunk.fromJson(json);

        expect(chunk.chunkIndex, 1);
        expect(chunk.pageStart, 10);
        expect(chunk.pageEnd, 12);
        expect(chunk.text, 'Paragraph text');
        expect(chunk.heading, 'Summary');
      });

      test('deserializes with only required fields', () {
        final json = {
          'chunkIndex': 0,
          'text': 'Minimal',
        };
        final chunk = SourceChunk.fromJson(json);

        expect(chunk.chunkIndex, 0);
        expect(chunk.text, 'Minimal');
        expect(chunk.pageStart, isNull);
        expect(chunk.pageEnd, isNull);
        expect(chunk.heading, isNull);
      });

      test('handles null text with default empty string', () {
        final chunk = SourceChunk.fromJson({
          'chunkIndex': 0,
          'text': null,
        });

        expect(chunk.text, '');
      });

      test('handles missing text key with default empty string', () {
        final chunk = SourceChunk.fromJson({
          'chunkIndex': 0,
        });

        expect(chunk.text, '');
      });

      test('handles explicitly null optional fields', () {
        final chunk = SourceChunk.fromJson({
          'chunkIndex': 5,
          'text': 'hello',
          'pageStart': null,
          'pageEnd': null,
          'heading': null,
        });

        expect(chunk.chunkIndex, 5);
        expect(chunk.pageStart, isNull);
        expect(chunk.pageEnd, isNull);
        expect(chunk.heading, isNull);
        expect(chunk.text, 'hello');
      });

      test('handles non-null text string', () {
        final chunk = SourceChunk.fromJson({
          'chunkIndex': 1,
          'text': 'Hello World',
        });

        expect(chunk.text, 'Hello World');
      });

      test('throws TypeError when chunkIndex is missing', () {
        expect(
          () => SourceChunk.fromJson({'text': 'oops'}),
          throwsA(isA<TypeError>()),
        );
      });

      test('throws TypeError when chunkIndex has wrong type', () {
        expect(
          () => SourceChunk.fromJson({'chunkIndex': 'one', 'text': 'bad'}),
          throwsA(isA<TypeError>()),
        );
      });

      test('throws TypeError when text has wrong type', () {
        expect(
          () => SourceChunk.fromJson({'chunkIndex': 1, 'text': 42}),
          throwsA(isA<TypeError>()),
        );
      });

      test('ignores extra unknown fields', () {
        final chunk = SourceChunk.fromJson({
          'chunkIndex': 7,
          'text': 'ignore extra',
          'extraField': 'should be ignored',
        });

        expect(chunk.chunkIndex, 7);
        expect(chunk.text, 'ignore extra');
      });
    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = SourceChunk(
          chunkIndex: 1,
          pageStart: 10,
          pageEnd: 12,
          text: 'Paragraph text',
          heading: 'Summary',
        );

        final restored = SourceChunk.fromJson(original.toJson());

        expect(restored.chunkIndex, original.chunkIndex);
        expect(restored.pageStart, original.pageStart);
        expect(restored.pageEnd, original.pageEnd);
        expect(restored.text, original.text);
        expect(restored.heading, original.heading);
      });

      test('preserves null optional fields', () {
        final original = SourceChunk(chunkIndex: 0, text: 'minimal');
        final restored = SourceChunk.fromJson(original.toJson());

        expect(restored.chunkIndex, 0);
        expect(restored.text, 'minimal');
        expect(restored.pageStart, isNull);
        expect(restored.pageEnd, isNull);
        expect(restored.heading, isNull);
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

      test('different instances have different hashCodes', () {
        final a = SourceChunk(chunkIndex: 1, text: 'a');
        final b = SourceChunk(chunkIndex: 2, text: 'b');
        expect(a.hashCode == b.hashCode, isFalse);
      });
    });

    group('toString', () {
      test('includes Instance of SourceChunk', () {
        final chunk = SourceChunk(chunkIndex: 0, text: 'test');
        expect(chunk.toString(), contains('SourceChunk'));
      });
    });
  });
}
