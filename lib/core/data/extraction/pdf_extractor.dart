import 'dart:io';
import 'dart:typed_data';

import 'package:studyking/core/utils/logger.dart';

class PdfExtractionResult {
  final String text;
  final int? pageCount;
  final String extractionMethod;

  const PdfExtractionResult({
    required this.text,
    this.pageCount,
    required this.extractionMethod,
  });
}

class PdfExtractor {
  final Logger _logger = const Logger('PdfExtractor');

  Future<PdfExtractionResult> extractFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _logger.w('PDF file not found: $filePath');
        return const PdfExtractionResult(
          text: '',
          extractionMethod: 'file_not_found',
        );
      }
      final bytes = await file.readAsBytes();
      return extractFromBytes(bytes);
    } catch (e) {
      _logger.e('Failed to read PDF file', e);
      return const PdfExtractionResult(
        text: '',
        extractionMethod: 'file_read_error',
      );
    }
  }

  Future<PdfExtractionResult> extractFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return const PdfExtractionResult(
        text: '',
        extractionMethod: 'empty_content',
      );
    }

    final content = String.fromCharCodes(bytes);
    final pageCount = _estimatePageCount(content);

    final simpleExtraction = _extractTextSimple(bytes, pageCount);
    if (simpleExtraction.text.length > 50) {
      return simpleExtraction;
    }

    try {
      final cleaned = _cleanRawPdfContent(content);
      if (cleaned.length > simpleExtraction.text.length) {
        return PdfExtractionResult(
          text: cleaned,
          pageCount: pageCount,
          extractionMethod: 'pdf_raw_decode',
        );
      }
    } catch (e) {
      _logger.e('Failed to clean raw PDF content', e);
    }

    if (simpleExtraction.text.isNotEmpty) {
      return simpleExtraction;
    }

    return PdfExtractionResult(
      text: '',
      pageCount: pageCount,
      extractionMethod: 'extraction_failed',
    );
  }

  PdfExtractionResult _extractTextSimple(
    Uint8List bytes,
    int? pageCount,
  ) {
    try {
      final content = String.fromCharCodes(bytes);
      final textObjects = <String>[];
      final regex = RegExp(r'\((?:[^()\\]|\\.)*\)');
      for (final match in regex.allMatches(content)) {
        var text = match.group(0)!;
        text = text.substring(1, text.length - 1);
        text = text
            .replaceAll(r'\(', '(')
            .replaceAll(r'\)', ')')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\r', '\r')
            .replaceAll(r'\t', '\t')
            .trim();
        if (text.isNotEmpty && text.length > 2) {
          textObjects.add(text);
        }
      }

      if (textObjects.isEmpty) {
        return PdfExtractionResult(
          text: '',
          pageCount: pageCount,
          extractionMethod: 'no_text_found',
        );
      }

      return PdfExtractionResult(
        text: textObjects.join('\n'),
        pageCount: pageCount,
        extractionMethod: 'pdf_text_extracted',
      );
    } catch (e) {
      _logger.e('Simple PDF extraction failed', e);
      return PdfExtractionResult(
        text: '',
        pageCount: pageCount,
        extractionMethod: 'simple_extraction_failed',
      );
    }
  }

  String _cleanRawPdfContent(String raw) {
    final lines = raw.split('\n');
    final filtered = lines.where((l) {
      final trimmed = l.trim();
      if (trimmed.isEmpty) return false;
      if (trimmed.startsWith('%') || trimmed.startsWith('endobj') ||
          trimmed.startsWith('endstream') || trimmed.startsWith('stream') ||
          trimmed.startsWith('obj') || trimmed.startsWith('xref') ||
          trimmed.startsWith('trailer') || trimmed.startsWith('startxref')) {
        return false;
      }
      return true;
    }).toList();

    return filtered.join('\n').trim();
  }

  int? _estimatePageCount(String content) {
    final matches = RegExp(r'/Type\s*/Page(?!s)').allMatches(content);
    if (matches.isNotEmpty) return matches.length;
    final pages = RegExp(r'/Pages\s*(\d+)').firstMatch(content);
    if (pages != null) return int.tryParse(pages.group(1)!);
    return null;
  }
}
