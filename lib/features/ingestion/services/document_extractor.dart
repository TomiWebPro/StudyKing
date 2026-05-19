import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/services/extraction_result.dart';

class DocumentExtractor {
  static final _headingPatterns = [
    RegExp(r'^#{1,6}\s+(.+)$', multiLine: true),
    RegExp(r'^(.+)\n={3,}$', multiLine: true),
    RegExp(r'^(.+)\n-{3,}$', multiLine: true),
  ];

  final PdfExtractor _pdfExtractor;
  final OcrExtractor _ocrExtractor;
  final TranscriptionExtractor _transcriptionExtractor;
  final String modelId;

  DocumentExtractor({
    PdfExtractor? pdfExtractor,
    OcrExtractor? ocrExtractor,
    TranscriptionExtractor? transcriptionExtractor,
    LlmService? llmService,
    required this.modelId,
    String localeName = 'en',
  })  : _pdfExtractor = pdfExtractor ?? PdfExtractor(),
        _ocrExtractor = ocrExtractor ?? OcrExtractor(llmService: llmService, modelId: modelId, localeName: localeName),
        _transcriptionExtractor = transcriptionExtractor ??
            TranscriptionExtractor(llmService: llmService, modelId: modelId, localeName: localeName);

  Future<ExtractionResult> extractText({
    required String rawContent,
    required SourceType sourceType,
    String? sourceUrl,
  }) async {
    switch (sourceType) {
      case SourceType.pdf:
      case SourceType.document:
      case SourceType.textbook:
      case SourceType.syllabus:
        return _extractPdfOrDocument(rawContent, sourceType);
      case SourceType.lectureNotes:
      case SourceType.externalResource:
        return ExtractionResult(text: rawContent, extractionMethod: 'direct');
      case SourceType.webPage:
        return _extractWebPage(rawContent, sourceUrl);
      case SourceType.image:
        return _extractImage(rawContent);
      case SourceType.video:
        return _extractVideo(rawContent, sourceUrl);
      case SourceType.audio:
        return _extractAudio(rawContent, sourceUrl);
    }
  }

  Future<ExtractionResult> _extractPdfOrDocument(
    String rawContent,
    SourceType sourceType,
  ) async {
    if (kIsWeb && rawContent.startsWith('file://')) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: 'pdf_web_unsupported',
      );
    }

    if (rawContent.isEmpty) {
      return ExtractionResult(text: '', extractionMethod: 'pdf_empty');
    }

    if (rawContent.startsWith('file://')) {
      final filePath = rawContent.substring(7);
      final file = File(filePath);
      if (file.existsSync()) {
        try {
          final pdfResult = await _pdfExtractor.extractFromFile(filePath);
          if (pdfResult.text.isNotEmpty) {
            final chunks = _chunkContent(pdfResult.text);
            return ExtractionResult(
              text: pdfResult.text,
              extractionMethod: pdfResult.extractionMethod,
              pageCount: pdfResult.pageCount,
              chunks: chunks,
            );
          }
        } catch (e) {
          // Fall through to raw read
        }
      }
    }

    try {
      if (rawContent.startsWith('file://')) {
        final filePath = rawContent.substring(7);
        final file = File(filePath);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
            final extension = filePath.split('.').last.toLowerCase();
            final formatHint = switch (extension) {
              'docx' => 'DOCX (Word document — ZIP-based XML format)',
              'epub' => 'EPUB (e-book — ZIP-based XML/HTML format)',
              'xlsx' => 'XLSX (Excel spreadsheet — ZIP-based XML format)',
              'pptx' => 'PPTX (PowerPoint — ZIP-based XML format)',
              _ => 'ZIP archive',
            };
            return ExtractionResult(
              text: '[$formatHint] File: $filePath — content is a binary archive, not plain text. '
                  'Please process this file using its native format. If text extraction is needed, '
                  'pass the raw bytes to an LLM with format-specific instructions.',
              extractionMethod: '${extension}_binary_not_decoded',
            );
          }
          final content = utf8.decode(bytes, allowMalformed: true);
          if (content.length > 50) {
            final chunks = _chunkContent(content);
            return ExtractionResult(
              text: content,
              extractionMethod: 'file_read',
              pageCount: chunks.isNotEmpty ? chunks.length : null,
              chunks: chunks,
            );
          }
        }
      }
    } catch (e) {
      const Logger('DocumentExtractor').e('Failed to read file as UTF-8: $e');
    }

    final chunks = _chunkContent(rawContent);
    final heading = _detectHeading(rawContent);
    final extractionMethod = rawContent.startsWith('file://')
        ? 'pdf_file_fallback'
        : 'pdf_text_direct';
    if (chunks.isNotEmpty) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: extractionMethod,
        pageCount: chunks.length > 1 ? chunks.length : null,
        chunks: <SourceChunk>[
          SourceChunk(
            chunkIndex: 0,
            pageStart: 1,
            pageEnd: chunks.length,
            text: rawContent,
            heading: heading,
          ),
        ],
      );
    }
    return ExtractionResult(
      text: rawContent,
      extractionMethod: extractionMethod,
    );
  }

  ExtractionResult _extractWebPage(String rawContent, String? sourceUrl) {
    final isHtml = rawContent.trim().startsWith('<') &&
        rawContent.contains('</');
    if (isHtml) {
      final text = stripHtmlToText(rawContent);
      return ExtractionResult(
        text: text,
        extractionMethod: 'html_stripped',
      );
    }
    return ExtractionResult(text: rawContent, extractionMethod: 'web_direct');
  }

  Future<ExtractionResult> _extractImage(String rawContent) async {
    final ocrResult = await _ocrExtractor.extractText(
      rawContent: rawContent,
      sourceUrl: null,
    );

    if (ocrResult.text.isNotEmpty) {
      return ExtractionResult(
        text: ocrResult.text,
        extractionMethod: ocrResult.extractionMethod,
        ocrConfidence: ocrResult.confidence,
        mimeType: rawContent.startsWith('file://')
            ? _detectMimeType(rawContent.substring(7))
            : null,
      );
    }

    if (ocrResult.isError) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: ocrResult.extractionMethod,
        errorMessage: ocrResult.errorMessage,
      );
    }

    if (rawContent.startsWith('file://')) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: 'image_file',
        mimeType: _detectMimeType(rawContent.substring(7)),
      );
    }
    if (rawContent.startsWith('http://') || rawContent.startsWith('https://')) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: 'image_url',
      );
    }
    return ExtractionResult(text: rawContent, extractionMethod: 'image_raw');
  }

  Future<ExtractionResult> _extractVideo(
    String rawContent,
    String? sourceUrl,
  ) async {
    final result = await _transcriptionExtractor.transcribeVideo(
      rawContent: rawContent,
      sourceUrl: sourceUrl,
    );

    if (result.text.isNotEmpty) {
      return ExtractionResult(
        text: result.text,
        extractionMethod: result.extractionMethod,
        durationSeconds: result.durationSeconds,
      );
    }

    final effectiveUrl = sourceUrl ?? rawContent;
    if (effectiveUrl.contains('youtube.com') || effectiveUrl.contains('youtu.be')) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: 'youtube_url',
        durationSeconds: null,
      );
    }
    if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: 'video_url',
      );
    }
    return ExtractionResult(text: rawContent, extractionMethod: 'video_raw');
  }

  Future<ExtractionResult> _extractAudio(
    String rawContent,
    String? sourceUrl,
  ) async {
    final result = await _transcriptionExtractor.transcribeAudio(
      rawContent: rawContent,
      sourceUrl: sourceUrl,
    );

    if (result.text.isNotEmpty) {
      return ExtractionResult(
        text: result.text,
        extractionMethod: result.extractionMethod,
        durationSeconds: result.durationSeconds,
      );
    }

    final effectiveUrl = sourceUrl ?? rawContent;
    if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      return ExtractionResult(
        text: rawContent,
        extractionMethod: 'audio_url',
      );
    }
    return ExtractionResult(text: rawContent, extractionMethod: 'audio_raw');
  }

  List<SourceChunk> _chunkContent(String text) {
    final chunks = <SourceChunk>[];
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    if (paragraphs.length <= 1) return [];

    for (var i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i].trim();
      if (para.isEmpty) continue;
      final heading = _detectHeading(para);
      chunks.add(SourceChunk(
        chunkIndex: chunks.length,
        text: para,
        heading: heading,
      ));
    }
    return chunks;
  }

  String? _detectHeading(String text) {
    for (final pattern in _headingPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          trimmed.length < 100 &&
          !trimmed.endsWith('.') &&
          trimmed == trimmed.toUpperCase()) {
        return trimmed;
      }
    }
    return null;
  }

  static String stripHtmlToText(String html) {
    final buffer = StringBuffer();
    var text = html;
    final scriptOrStyle = RegExp(r'<(script|style)[^>]*>', caseSensitive: false);
    final endScriptOrStyle = RegExp(r'<\/(script|style)>', caseSensitive: false);

    while (text.isNotEmpty) {
      final scriptStart = scriptOrStyle.firstMatch(text);
      if (scriptStart != null) {
        buffer.write(_stripTags(text.substring(0, scriptStart.start)));
        text = text.substring(scriptStart.start);
        final scriptEnd = endScriptOrStyle.firstMatch(text);
        if (scriptEnd != null) {
          text = text.substring(scriptEnd.end);
        } else {
          break;
        }
      } else {
        buffer.write(_stripTags(text));
        break;
      }
    }

    final result = buffer.toString();
    final lines = result
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 20)
        .toList();

    return lines.join('\n\n');
  }

  static String _stripTags(String html) {
    final buffer = StringBuffer();
    var inTag = false;
    for (var i = 0; i < html.length; i++) {
      final char = html[i];
      if (char == '<') {
        inTag = true;
      } else if (char == '>') {
        inTag = false;
      } else if (!inTag) {
        buffer.write(char);
      }
    }
    return buffer.toString().trim();
  }

  void dispose() {
    _transcriptionExtractor.dispose();
  }

  String _detectMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  int estimateChunkCount(String text, {int chunkSize = 2000}) {
    if (text.isEmpty) return 0;
    return (text.length / chunkSize).ceil();
  }
}
