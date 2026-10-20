import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/source_figure.dart';

void main() {
  group('SourceFigure', () {
    test('creates with required fields only', () {
      final fig = SourceFigure(
        pageNumber: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(fig.pageNumber, 3);
      expect(fig.bytes, [1, 2, 3]);
      expect(fig.caption, '');
      expect(fig.mimeType, '');
      expect(fig.source, '');
    });

    test('creates with all fields', () {
      final fig = SourceFigure(
        pageNumber: 7,
        bytes: Uint8List.fromList([10, 20, 30]),
        caption: 'Figure 3: Carbon cycle',
        mimeType: 'image/png',
        source: 'pdf',
      );

      expect(fig.pageNumber, 7);
      expect(fig.caption, 'Figure 3: Carbon cycle');
      expect(fig.mimeType, 'image/png');
      expect(fig.source, 'pdf');
    });

    test('hasBytes is false for empty bytes', () {
      final fig = SourceFigure(pageNumber: 1, bytes: Uint8List(0));
      expect(fig.hasBytes, isFalse);
    });

    test('hasBytes is true for non-empty bytes', () {
      final fig = SourceFigure(
        pageNumber: 1,
        bytes: Uint8List.fromList([255]),
      );
      expect(fig.hasBytes, isTrue);
    });

    group('toJson / fromJson round-trip', () {
      test('preserves all fields including bytes', () {
        final original = SourceFigure(
          pageNumber: 5,
          bytes: Uint8List.fromList([0, 128, 255]),
          caption: 'Chart',
          mimeType: 'image/jpeg',
          source: 'docx',
        );

        final restored = SourceFigure.fromJson(original.toJson());

        expect(restored.pageNumber, 5);
        expect(restored.bytes, original.bytes);
        expect(restored.caption, 'Chart');
        expect(restored.mimeType, 'image/jpeg');
        expect(restored.source, 'docx');
      });

      test('handles missing pageNumber with default 0', () {
        final fig = SourceFigure.fromJson({
          'bytes': base64Encode(Uint8List.fromList([1])),
        });
        expect(fig.pageNumber, 0);
      });

      test('handles missing bytes with empty list', () {
        final fig = SourceFigure.fromJson({'pageNumber': 2});
        expect(fig.bytes, isEmpty);
        expect(fig.hasBytes, isFalse);
      });
    });

    group('encode / parse', () {
      test('empty list encodes to empty string', () {
        expect(SourceFigure.encode([]), '');
      });

      test('non-empty list encodes to valid JSON array', () {
        final encoded = SourceFigure.encode([
          SourceFigure(pageNumber: 1, bytes: Uint8List.fromList([1, 2])),
        ]);

        final decoded = jsonDecode(encoded) as List;
        expect(decoded.length, 1);
        final map = decoded.first as Map<String, dynamic>;
        expect(map['pageNumber'], 1);
        expect(map['caption'], '');
      });

      test('parse returns empty list for empty string', () {
        expect(SourceFigure.parse('').length, 0);
      });

      test('parse returns empty list for malformed JSON', () {
        expect(SourceFigure.parse('not json').length, 0);
      });

      test('parse returns empty list for non-list JSON', () {
        expect(SourceFigure.parse('{"a":1}').length, 0);
      });

      test('round-trips through encode → parse', () {
        final original = [
          SourceFigure(
            pageNumber: 2,
            bytes: Uint8List.fromList([10, 20, 30]),
            caption: 'Diagrams',
            mimeType: 'image/png',
            source: 'pdf',
          ),
          SourceFigure(
            pageNumber: 4,
            bytes: Uint8List.fromList([]),
            caption: 'Chart',
            mimeType: 'image/jpeg',
            source: 'docx',
          ),
        ];

        final roundTripped = SourceFigure.parse(SourceFigure.encode(original));

        expect(roundTripped.length, 2);
        expect(roundTripped[0].pageNumber, 2);
        expect(roundTripped[0].bytes, [10, 20, 30]);
        expect(roundTripped[0].caption, 'Diagrams');
        expect(roundTripped[1].pageNumber, 4);
        expect(roundTripped[1].bytes, isEmpty);
      });

      test('parse ignores non-map elements in the JSON list', () {
        final json = '[42, "str", {"pageNumber":1,"bytes":"${base64Encode(Uint8List.fromList([1]))}"}]';
        final parsed = SourceFigure.parse(json);
        expect(parsed.length, 1);
        expect(parsed[0].pageNumber, 1);
      });
    });
  });
}
