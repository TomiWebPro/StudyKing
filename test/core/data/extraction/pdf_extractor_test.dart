import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';

void main() {
  group('PdfExtractionResult', () {
    test('stores all properties', () {
      const result = PdfExtractionResult(
        text: 'hello',
        pageCount: 3,
        extractionMethod: 'pdf_test',
      );
      expect(result.text, 'hello');
      expect(result.pageCount, 3);
      expect(result.extractionMethod, 'pdf_test');
    });

    test('pageCount can be null', () {
      const result = PdfExtractionResult(
        text: 'hello',
        extractionMethod: 'pdf_test',
      );
      expect(result.pageCount, isNull);
    });

    test('text can be empty', () {
      const result = PdfExtractionResult(
        text: '',
        extractionMethod: 'no_text',
      );
      expect(result.text, '');
    });
  });

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

      test('returns simple extraction when text > 50 chars', () async {
        final content = '(This is a very long text that definitely exceeds fifty characters in total length for sure)';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.text.length, greaterThan(50));
        expect(result.extractionMethod, 'pdf_text_extracted');
      });

      test('returns extraction_failed when no text found and clean fails', () async {
        final content = '%PDF-1.4\nendobj\nstream\nendstream\nxref\ntrailer\nstartxref';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.text, '');
        expect(result.extractionMethod, 'extraction_failed');
      });

      test('handles escaped characters in parentheses', () async {
        final content = r'(hello \(world\) and \n newline)';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.text, contains('hello'));
      });

      test('extracts text when parentheses are effectively empty via raw decode', () async {
        final content = 'PDF content with () and ( ) empty parens';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.text, isNotEmpty);
        expect(result.extractionMethod, 'pdf_raw_decode');
      });
    });

    group('extractFromFile', () {
      test('returns empty for non-existent file', () async {
        final result = await extractor.extractFromFile('/nonexistent/file.pdf');
        expect(result.text, '');
        expect(result.extractionMethod, 'file_not_found');
      });

      test('returns file_read_error for restricted file', () async {
        final dir = Directory.systemTemp.createTempSync('pdf_perm_test_');
        try {
          final file = File('${dir.path}/restricted.pdf');
          await file.writeAsBytes([0x25, 0x50, 0x44, 0x46]);
          await Process.run('chmod', ['000', file.path]);

          final result = await extractor.extractFromFile(file.path);
          expect(result.text, '');
          expect(result.extractionMethod, 'file_read_error');
        } finally {
          await Process.run('chmod', ['-R', '777', dir.path]);
          dir.deleteSync(recursive: true);
        }
      });

      test('extracts from existing file', () async {
        final dir = Directory.systemTemp.createTempSync('pdf_test_');
        try {
          final file = File('${dir.path}/test.pdf');
          final content = 'Some PDF with (Hello from file) and (more text here) and (lots of content to exceed fifty chars in this test)';
          await file.writeAsBytes(content.codeUnits);

          final result = await extractor.extractFromFile(file.path);
          expect(result.text, contains('Hello from file'));
          expect(result.extractionMethod, contains('pdf'));
        } finally {
          dir.deleteSync(recursive: true);
        }
      });

      test('extracts from existing file with page count', () async {
        final dir = Directory.systemTemp.createTempSync('pdf_test_');
        try {
          final file = File('${dir.path}/test.pdf');
          final content = '/Type /Page\n/Type /Page\n(Hello World)';
          await file.writeAsBytes(content.codeUnits);

          final result = await extractor.extractFromFile(file.path);
          expect(result.pageCount, 2);
          expect(result.text, contains('Hello World'));
        } finally {
          dir.deleteSync(recursive: true);
        }
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

      test('pageCount prefers /Type /Page over /Pages count', () async {
        final content = '/Type /Page\n/Type /Page\n/Pages 99';
        final bytes = Uint8List.fromList(content.codeUnits);
        final result = await extractor.extractFromBytes(bytes);
        expect(result.pageCount, 2);
      });
    });

    group('internal methods', () {
      test('_cleanRawPdfContent removes structural PDF tags', () async {
        final raw = '%PDF-1.4\n'
            '1 0 obj\n'
            'endobj\n'
            'stream\n'
            'endstream\n'
            'xref\n'
            'trailer\n'
            'startxref\n'
            '(actual content)';
        final bytes = Uint8List.fromList(raw.codeUnits);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.text, contains('actual content'));
      });
    });
  });
}
