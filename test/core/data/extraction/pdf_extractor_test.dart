import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';

void main() {
  group('PdfExtractor', () {
    late PdfExtractor extractor;

    setUp(() {
      extractor = PdfExtractor();
    });

    group('extractFromBytes', () {
      test('returns empty result for empty bytes', () async {
        final result = await extractor.extractFromBytes(Uint8List(0));
        expect(result.text, '');
        expect(result.extractionMethod, 'empty_content');
      });

      test('extracts text from simple PDF-like content', () async {
        final bytes = Uint8List.fromList(
          'Some PDF content with (text in parentheses) and more content.'
              .codeUnits,
        );
        final result = await extractor.extractFromBytes(bytes);
        expect(result.text, isNotEmpty);
        expect(result.extractionMethod, contains('pdf'));
      });

      test('extracts text from parentheses in raw bytes', () async {
        final content = '1 0 obj\n'
            '<</Type /Catalog /Pages 2 0 R>>\n'
            'endobj\n'
            '2 0 obj\n'
            '<</Type /Pages /Kids [3 0 R] /Count 1>>\n'
            'endobj\n'
            '3 0 obj\n'
            '<</Type /Page /Parent 2 0 R>>\n'
            'endobj\n'
            'stream\n'
            'BT\n'
            '/F1 12 Tf\n'
            '72 720 Td\n'
            '(Hello World) Tj\n'
            'ET\n'
            'endstream\n'
            'endobj';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.text, contains('Hello World'));
        expect(result.extractionMethod, 'pdf_raw_decode');
      });

      test('falls back to raw decode for non-standard content', () async {
        final content = 'Just some plain text content here\nwith multiple lines\nand more text';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.text, isNotEmpty);
        expect(result.extractionMethod, contains('pdf'));
      });
    });

    group('extractFromFile', () {
      test('returns empty for non-existent file', () async {
        final result = await extractor.extractFromFile('/nonexistent/file.pdf');
        expect(result.text, '');
        expect(result.extractionMethod, 'file_not_found');
      });
    });

    group('extractionMethod values', () {
      test('returns proper method for empty content', () async {
        final result = await extractor.extractFromBytes(Uint8List(0));
        expect(result.extractionMethod, 'empty_content');
      });

      test('extractionMethod is non-empty for valid content', () async {
        final bytes = Uint8List.fromList('sample text'.codeUnits);
        final result = await extractor.extractFromBytes(bytes);
        expect(result.extractionMethod, isNotEmpty);
      });

      test('pageCount is null when pages cannot be determined', () async {
        final bytes = Uint8List.fromList('simple'.codeUnits);
        final result = await extractor.extractFromBytes(bytes);
        expect(result.pageCount, isNull);
      });

      test('pageCount is not null when /Type /Page is found', () async {
        final content = '/Type /Page\n/Type /Page\n/Type /Page';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);
        expect(result.pageCount, 3);
      });

      test('pageCount from /Pages count', () async {
        final content = '/Pages 42';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);
        expect(result.pageCount, 42);
      });
    });
  });
}
