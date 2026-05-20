import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/services/extraction_result.dart';

class DocumentExtractor {
  static final Logger _logger = const Logger('DocumentExtractor');
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
    required String localeName,
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
            final extension = filePath.split('.').last.normalized;
            try {
              final text = _extractFromZip(bytes, extension);
              if (text.isNotEmpty) {
                final chunks = _chunkContent(text);
                return ExtractionResult(
                  text: text,
                  extractionMethod: '${extension}_parsed',
                  pageCount: chunks.isNotEmpty ? chunks.length : null,
                  chunks: chunks,
                );
              }
            } catch (e) {
              _logger.w('Failed to parse $extension archive: $e');
              return ExtractionResult(
                text: '',
                extractionMethod: '${extension}_parse_failed',
                errorMessage: 'Failed to extract text from $extension file: $e',
              );
            }
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
      _logger.w('Failed to read file as UTF-8: $e');
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

  String _extractFromZip(List<int> bytes, String extension) {
    final archive = ZipDecoder().decodeBytes(bytes);
    switch (extension) {
      case 'docx':
        return _extractDocx(archive);
      case 'epub':
        return _extractEpub(archive);
      case 'xlsx':
        return _extractXlsx(archive);
      case 'pptx':
        return _extractPptx(archive);
      default:
        return '';
    }
  }

  String _extractDocx(Archive archive) {
    final documentFile = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => ArchiveFile('', 0, 0),
    );
    if (documentFile.size == 0) return '';

    final document = XmlDocument.parse(utf8.decode(documentFile.content));
    final buffer = StringBuffer();

    for (final paragraph in document.findAllElements('w:p')) {
      for (final text in paragraph.findAllElements('w:t')) {
        buffer.write(text.innerText);
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  String _extractEpub(Archive archive) {
    String stripHtmlTags(String html) {
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

    String readFileContent(Archive archive, String path) {
      final file = archive.files.firstWhere(
        (f) => f.name == path,
        orElse: () => ArchiveFile('', 0, 0),
      );
      if (file.size == 0) return '';
      return utf8.decode(file.content);
    }

    try {
      final containerXml = readFileContent(archive, 'META-INF/container.xml');
      if (containerXml.isEmpty) return '';

      final container = XmlDocument.parse(containerXml);
      final rootfile = container.findAllElements('rootfile').firstOrNull;
      if (rootfile == null) return '';

      final opfPath = rootfile.getAttribute('full-path') ?? '';
      if (opfPath.isEmpty) return '';

      final opfContent = readFileContent(archive, opfPath);
      if (opfContent.isEmpty) return '';

      final opf = XmlDocument.parse(opfContent);
      final opfDir = opfPath.contains('/')
          ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1)
          : '';

      final spineItemRefs = opf.findAllElements('itemref')
          .map((e) => e.getAttribute('idref'))
          .whereType<String>()
          .toList();

      final manifestItems = <String, String>{};
      for (final item in opf.findAllElements('item')) {
        final id = item.getAttribute('id');
        final href = item.getAttribute('href');
        if (id != null && href != null) {
          manifestItems[id] = href;
        }
      }

      final buffer = StringBuffer();
      for (final ref in spineItemRefs) {
        final href = manifestItems[ref];
        if (href == null) continue;

        final fullPath = opfDir.isNotEmpty ? '$opfDir$href' : href;
        final content = readFileContent(archive, fullPath);
        if (content.isNotEmpty &&
            (content.contains('<html') || content.contains('<!DOCTYPE html'))) {
          buffer.writeln(stripHtmlTags(content));
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      _logger.w('EPUB extraction failed: $e');
      return '';
    }
  }

  String _extractXlsx(Archive archive) {
    String readFile(Archive archive, String path) {
      final file = archive.files.firstWhere(
        (f) => f.name == path,
        orElse: () => ArchiveFile('', 0, 0),
      );
      if (file.size == 0) return '';
      return utf8.decode(file.content);
    }

    try {
      final sharedStringsXml = readFile(archive, 'xl/sharedStrings.xml');
      final sharedStrings = <int, String>{};
      if (sharedStringsXml.isNotEmpty) {
        final ssDoc = XmlDocument.parse(sharedStringsXml);
        var index = 0;
        for (final si in ssDoc.findAllElements('si')) {
          final textParts = si.findAllElements('t').map((t) => t.innerText).join();
          sharedStrings[index++] = textParts;
        }
      }

      final buffer = StringBuffer();
      final sheetFiles = archive.files
          .where((f) => f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final sheetFile in sheetFiles) {
        final sheetXml = utf8.decode(sheetFile.content);
        final sheet = XmlDocument.parse(sheetXml);

        for (final row in sheet.findAllElements('row')) {
          final cells = <String>[];
          for (final cell in row.findAllElements('c')) {
            final type = cell.getAttribute('t');
            final value = cell.findElements('v').firstOrNull;
            if (value == null) continue;

            if (type == 's') {
              final ssIndex = int.tryParse(value.innerText) ?? -1;
              cells.add(sharedStrings[ssIndex] ?? '');
            } else {
              cells.add(value.innerText);
            }
          }
          if (cells.isNotEmpty) {
            buffer.writeln(cells.join('\t'));
          }
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      _logger.w('XLSX extraction failed: $e');
      return '';
    }
  }

  String _extractPptx(Archive archive) {
    String extractSlideText(String xmlContent) {
      try {
        final slide = XmlDocument.parse(xmlContent);
        final buffer = StringBuffer();
        for (final text in slide.findAllElements('t')) {
          buffer.write(text.innerText);
          buffer.write(' ');
        }
        return buffer.toString().trim();
      } catch (e) {
        return '';
      }
    }

    final buffer = StringBuffer();
    final slideFiles = archive.files
        .where((f) => f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final slideFile in slideFiles) {
      final text = extractSlideText(utf8.decode(slideFile.content));
      if (text.isNotEmpty) {
        buffer.writeln(text);
        buffer.writeln('---');
      }
    }

    return buffer.toString().trim();
  }

  void dispose() {
    _transcriptionExtractor.dispose();
  }

  String _detectMimeType(String filePath) {
    final ext = filePath.split('.').last.normalized;
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
