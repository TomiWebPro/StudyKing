import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';

/// Builds a minimal, valid (uncompressed) PDF document with the given page
/// texts. The structure is straightforward enough that the real parser can
/// resolve the page tree and extract text from the content streams.
Uint8List _buildPdf(List<String> pageTexts) {
  final fontNum = 3 + pageTexts.length * 2;
  final buffer = StringBuffer();
  buffer.writeln('%PDF-1.4');

  // 1: Catalog
  buffer.writeln('1 0 obj');
  buffer.writeln('<< /Type /Catalog /Pages 2 0 R >>');
  buffer.writeln('endobj');

  // 2: Pages
  final kids = <String>[];
  for (var i = 0; i < pageTexts.length; i++) {
    kids.add('${3 + i * 2} 0 R');
  }
  buffer.writeln('2 0 obj');
  buffer.writeln('<< /Type /Pages /Kids [${kids.join(' ')}] /Count ${pageTexts.length} >>');
  buffer.writeln('endobj');

  // Per-page: page object + content stream object.
  for (var i = 0; i < pageTexts.length; i++) {
    final pageNum = 3 + i * 2;
    final contentNum = 4 + i * 2;
    final content = 'BT /F1 12 Tf 72 720 Td (${pageTexts[i]}) Tj ET';
    buffer.writeln('$pageNum 0 obj');
    buffer.writeln('<< /Type /Page /Parent 2 0 R /Contents $contentNum 0 R '
        '/Resources << /Font << /F1 $fontNum 0 R >> >> >>');
    buffer.writeln('endobj');
    buffer.writeln('$contentNum 0 obj');
    buffer.writeln('<< /Length ${content.length} >>');
    buffer.writeln('stream');
    buffer.write(content);
    buffer.writeln();
    buffer.writeln('endstream');
    buffer.writeln('endobj');
  }

  // Shared font object.
  buffer.writeln('$fontNum 0 obj');
  buffer.writeln('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  buffer.writeln('endobj');

  buffer.writeln('trailer');
  buffer.writeln('<< /Root 1 0 R >>');
  buffer.writeln('startxref');
  buffer.writeln('0');
  buffer.writeln('%%EOF');

  return Uint8List.fromList(buffer.toString().codeUnits);
}

void main() {
  group('PdfExtractionResult', () {
    test('stores all properties', () {
      const result = PdfExtractionResult(
        text: 'hello',
        pageCount: 3,
        extractionMethod: 'pdf_text_extracted',
      );
      expect(result.text, 'hello');
      expect(result.pageCount, 3);
      expect(result.extractionMethod, 'pdf_text_extracted');
    });

    test('pageCount can be null', () {
      const result = PdfExtractionResult(
        text: 'hello',
        extractionMethod: 'pdf_text_extracted',
      );
      expect(result.pageCount, isNull);
    });
  });

  group('PdfExtractor', () {
    late PdfExtractor extractor;

    setUp(() => extractor = PdfExtractor());

    group('extractFromBytes', () {
      test('returns empty_content for empty bytes', () async {
        final result = await extractor.extractFromBytes(Uint8List(0));
        expect(result.isSuccess, isTrue);
        expect(result.fold((d) => d.extractionMethod, (_) => ''), 'empty_content');
      });

      test('extracts text from a generated single-page PDF', () async {
        final bytes = _buildPdf(['Hello World from a proper parser']);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.isSuccess, isTrue);
        final data = result.fold((d) => d, (_) => null);
        expect(data, isNotNull);
        expect(data!.text, contains('Hello World from a proper parser'));
        expect(data.extractionMethod, 'pdf_text_extracted');
        expect(data.pageCount, 1);
      });

      test('extracts text and tracks page metadata for multi-page PDF', () async {
        final bytes = _buildPdf([
          'Page one content here',
          'Page two content here',
          'Page three content here',
        ]);
        final result = await extractor.extractFromBytes(bytes);

        expect(result.isSuccess, isTrue);
        final data = result.fold((d) => d, (_) => null);
        expect(data, isNotNull);
        expect(data!.pageCount, 3);
        expect(data.pages, isNotNull);
        expect(data.pages!.length, 3);
        expect(data.pages![0].pageNumber, 1);
        expect(data.pages![0].text, contains('Page one'));
        expect(data.pages![1].pageNumber, 2);
        expect(data.pages![1].text, contains('Page two'));
        expect(data.pages![2].pageNumber, 3);
        expect(data.pages![2].text, contains('Page three'));
        expect(data.text, contains('Page one content here'));
        expect(data.text, contains('Page three content here'));
      });

      test('decodes escaped characters in text strings', () async {
        final bytes = _buildPdf([r'Hello \(escaped\) and \n newline']);
        final result = await extractor.extractFromBytes(bytes);
        expect(result.isSuccess, isTrue);
        final data = result.fold((d) => d, (_) => null);
        expect(data!.text, contains('Hello (escaped) and'));
      });

      test('extracts text from TJ arrays', () async {
        final pdf = _buildPdfWithTjArray('Hello', 'World');
        final result = await extractor.extractFromBytes(pdf);
        expect(result.isSuccess, isTrue);
        final data = result.fold((d) => d, (_) => null);
        expect(data!.text, contains('Hello'));
        expect(data.text, contains('World'));
      });

      test('reports no_text_found as failure for image-only PDF', () async {
        // Content stream with no text-showing operators -> scanned-like PDF.
        final bytes = _buildPdfWithoutText();
        final result = await extractor.extractFromBytes(bytes);
        expect(result.isFailure, isTrue);
        expect(result.fold((_) => '', (e) => e), contains('no_text_found'));
      });

      test('reports extraction_failed for non-PDF bytes', () async {
        final bytes = Uint8List.fromList('just some plain text'.codeUnits);
        final result = await extractor.extractFromBytes(bytes);
        expect(result.isFailure, isTrue);
        expect(result.fold((_) => '', (e) => e), contains('extraction_failed'));
      });
    });

    group('extractFromFile', () {
      test('returns file_not_found for missing file', () async {
        final result = await extractor.extractFromFile('/nonexistent/file.pdf');
        expect(result.isSuccess, isTrue);
        final data = result.fold((d) => d, (_) => null);
        expect(data!.extractionMethod, 'file_not_found');
        expect(data.text, '');
      });

      test('extracts text from a written PDF file', () async {
        final dir = Directory.systemTemp.createTempSync('pdf_extract_test_');
        try {
          final file = File('${dir.path}/doc.pdf');
          await file.writeAsBytes(_buildPdf(['File-based extraction works']));

          final result = await extractor.extractFromFile(file.path);
          expect(result.isSuccess, isTrue);
          final data = result.fold((d) => d, (_) => null);
          expect(data!.text, contains('File-based extraction works'));
          expect(data.pageCount, 1);
        } finally {
          dir.deleteSync(recursive: true);
        }
      });
    });
  });
}

/// Builds a PDF whose single page shows two strings via a `TJ` array.
Uint8List _buildPdfWithTjArray(String a, String b) {
  final content = 'BT /F1 12 Tf 72 720 Td [($a) 12 ($b)] TJ ET';
  final fontNum = 5;
  final buffer = StringBuffer();
  buffer.writeln('%PDF-1.4');
  buffer.writeln('1 0 obj');
  buffer.writeln('<< /Type /Catalog /Pages 2 0 R >>');
  buffer.writeln('endobj');
  buffer.writeln('2 0 obj');
  buffer.writeln('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
  buffer.writeln('endobj');
  buffer.writeln('3 0 obj');
  buffer.writeln('<< /Type /Page /Parent 2 0 R /Contents 4 0 R '
      '/Resources << /Font << /F1 $fontNum 0 R >> >> >>');
  buffer.writeln('endobj');
  buffer.writeln('4 0 obj');
  buffer.writeln('<< /Length ${content.length} >>');
  buffer.writeln('stream');
  buffer.write(content);
  buffer.writeln();
  buffer.writeln('endstream');
  buffer.writeln('endobj');
  buffer.writeln('$fontNum 0 obj');
  buffer.writeln('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  buffer.writeln('endobj');
  buffer.writeln('trailer');
  buffer.writeln('<< /Root 1 0 R >>');
  buffer.writeln('startxref');
  buffer.writeln('0');
  buffer.writeln('%%EOF');
  return Uint8List.fromList(buffer.toString().codeUnits);
}

/// Builds a PDF whose content stream has no text-showing operators, simulating
/// a scanned / image-only document.
Uint8List _buildPdfWithoutText() {
  final content = 'BT /F1 12 Tf 72 720 Td ET'; // no Tj / TJ
  final fontNum = 5;
  final buffer = StringBuffer();
  buffer.writeln('%PDF-1.4');
  buffer.writeln('1 0 obj');
  buffer.writeln('<< /Type /Catalog /Pages 2 0 R >>');
  buffer.writeln('endobj');
  buffer.writeln('2 0 obj');
  buffer.writeln('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
  buffer.writeln('endobj');
  buffer.writeln('3 0 obj');
  buffer.writeln('<< /Type /Page /Parent 2 0 R /Contents 4 0 R >>');
  buffer.writeln('endobj');
  buffer.writeln('4 0 obj');
  buffer.writeln('<< /Length ${content.length} >>');
  buffer.writeln('stream');
  buffer.write(content);
  buffer.writeln();
  buffer.writeln('endstream');
  buffer.writeln('endobj');
  buffer.writeln('$fontNum 0 obj');
  buffer.writeln('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  buffer.writeln('endobj');
  buffer.writeln('trailer');
  buffer.writeln('<< /Root 1 0 R >>');
  buffer.writeln('startxref');
  buffer.writeln('0');
  buffer.writeln('%%EOF');
  return Uint8List.fromList(buffer.toString().codeUnits);
}
