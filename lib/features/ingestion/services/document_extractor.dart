import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' show parse;

import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_pipeline.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/services/extraction_result.dart';
import 'package:studyking/features/ingestion/services/page_metadata.dart';

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
  final TranscriptionPipeline? _transcriptionPipeline;
  final String modelId;

  DocumentExtractor({
    PdfExtractor? pdfExtractor,
    OcrExtractor? ocrExtractor,
    TranscriptionExtractor? transcriptionExtractor,
    TranscriptionPipeline? transcriptionPipeline,
    LlmService? llmService,
    required this.modelId,
    required String localeName,
    OcrMode ocrMode = OcrMode.hybrid,
    AsrEngine? asrEngine,
  })  : _pdfExtractor = pdfExtractor ?? PdfExtractor(),
        _ocrExtractor = ocrExtractor ??
            OcrExtractor(
              mode: ocrMode,
              llmService: llmService,
              modelId: modelId,
              localeName: localeName,
            ),
        _transcriptionExtractor = transcriptionExtractor ??
            TranscriptionExtractor(llmService: llmService, modelId: modelId, localeName: localeName, asrEngine: asrEngine),
        _transcriptionPipeline = transcriptionPipeline;

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
          final bytes = file.readAsBytesSync();
          final isZip = bytes.length >= 4 &&
              bytes[0] == 0x50 && bytes[1] == 0x4B &&
              bytes[2] == 0x03 && bytes[3] == 0x04;

          if (isZip) {
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

          final extension = filePath.split('.').last.normalized;
          if (extension == 'rtf') {
            final content = utf8.decode(bytes, allowMalformed: true);
            if (content.startsWith('{\\rtf') || content.length > 50) {
              final text = _extractRtf(content);
              if (text.isNotEmpty) {
                final chunks = _chunkContent(text);
                return ExtractionResult(
                  text: text,
                  extractionMethod: 'rtf_parsed',
                  pageCount: chunks.isNotEmpty ? chunks.length : null,
                  chunks: chunks,
                );
              }
            }
          }

          if (!isZip) {
            final pdfResult = await _pdfExtractor.extractFromFile(filePath);
            final extracted = pdfResult.fold(
              (data) {
                if (data.text.isNotEmpty) {
                  final chunks = _chunkContent(data.text);
                  return ExtractionResult(
                    text: data.text,
                    extractionMethod: data.extractionMethod,
                    pageCount: data.pageCount,
                    chunks: chunks,
                  );
                }
                return null;
              },
              (_) => null,
            );
            if (extracted != null) return extracted;
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
        } catch (e) {
          _logger.w('Failed to read file: $e');
        }
      }
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
    final pipeline = _transcriptionPipeline;
    final result = pipeline != null
        ? await pipeline.transcribe(rawContent: rawContent, sourceUrl: sourceUrl)
        : await _transcriptionExtractor.transcribeVideo(
            rawContent: rawContent,
            sourceUrl: sourceUrl,
          );

    if (result.text.isNotEmpty) {
      return ExtractionResult(
        text: result.text,
        extractionMethod: result.extractionMethod,
        durationSeconds: result.durationSeconds,
        transcriptionConfidence: result.confidence,
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
    final pipeline = _transcriptionPipeline;
    final result = pipeline != null
        ? await pipeline.transcribe(rawContent: rawContent, sourceUrl: sourceUrl)
        : await _transcriptionExtractor.transcribeAudio(
            rawContent: rawContent,
            sourceUrl: sourceUrl,
          );

    if (result.text.isNotEmpty) {
      return ExtractionResult(
        text: result.text,
        extractionMethod: result.extractionMethod,
        durationSeconds: result.durationSeconds,
        transcriptionConfidence: result.confidence,
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

  /// Converts an HTML document into cleaned main-content text using a proper
  /// DOM parser. This is a Readability-style two-pass extraction: non-content
  /// subtrees (script/style/nav/aside/footer/...) are removed, the most text-
  /// dense block is selected as the main content, and its text is rendered with
  /// short/empty lines dropped. Falls back to naive tag-stripping if parsing
  /// fails.
  static String stripHtmlToText(String html) {
    try {
      final doc = parse(html);
      final main = _extractMainContentNode(doc);
      return _renderMainText(main).trim();
    } catch (e) {
      _logger.w('HTML DOM parse failed; falling back to tag strip', e);
      return _fallbackStripTags(html);
    }
  }

  static final _removeTags = [
    'script',
    'style',
    'noscript',
    'header',
    'nav',
    'footer',
    'aside',
    'iframe',
    'svg',
    'template',
    'form',
    'button',
    'figure',
  ];

  static const _boilerplateKeywords = [
    'sidebar',
    'side-bar',
    'aside',
    'advert',
    'ad-',
    'adv-',
    'banner',
    'menu',
    'navbar',
    'breadcrumb',
    'comment',
    'promo',
    'social',
    'share',
    'related',
    'popup',
    'cookie',
    'modal',
    'newsletter',
    'footer',
    'header',
    'nav',
  ];

  static const _terminalBlockTags = {
    'p',
    'li',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'pre',
    'td',
    'th',
    'dd',
    'dt',
    'address',
    'caption',
  };

  /// Returns the DOM node that most likely holds the article's main content.
  static Element _extractMainContentNode(Document doc) {
    for (final tag in _removeTags) {
      doc.querySelectorAll(tag).forEach((e) => e.remove());
    }

    doc.querySelectorAll('[class],[id],[role]').forEach((e) {
      final signature =
          '${e.className} ${e.id} ${e.attributes['role'] ?? ''}'.toLowerCase();
      if (_boilerplateKeywords.any((k) => signature.contains(k))) {
        e.remove();
      }
    });

    final root = doc.body ?? doc.documentElement;
    if (root == null) return doc.documentElement!;

    final candidates = <Element, double>{};
    final scoreNodes = root.querySelectorAll(
      'p, div, article, section, li, td, th, h1, h2, h3, h4, h5, h6, blockquote, pre, main',
    );
    for (final el in scoreNodes) {
      final text = el.text.trim();
      if (text.length < 25) continue;
      var score = text.length / 25.0;
      final linkTextLen = el
          .querySelectorAll('a')
          .fold(0, (int s, n) => s + n.text.trim().length);
      if (text.isNotEmpty) {
        score *= (1 - (linkTextLen / text.length).clamp(0.0, 1.0));
      }
      if (el.localName == 'article' ||
          el.localName == 'main' ||
          el.localName == 'section') {
        score *= 1.5;
      }
      candidates[el] = score;
    }

    if (candidates.isEmpty) return root;
    return candidates.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  static String _renderMainText(Element root) {
    final blocks = <String>[];

    void collect(Element e) {
      for (final node in e.nodes) {
        if (node is! Element) continue;
        final tag = node.localName?.toLowerCase();
        if (tag == null) continue;
        if (_terminalBlockTags.contains(tag)) {
          final t = node.text.trim();
          if (t.isNotEmpty) blocks.add(t);
        } else {
          collect(node);
        }
      }
    }

    collect(root);
    if (blocks.isEmpty) {
      final t = root.text.trim();
      if (t.isNotEmpty) blocks.add(t);
    }

    final lines = blocks
        .expand((b) => b.split(RegExp(r'\s*\n\s*')))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length >= 20)
        .toList();
    return lines.join('\n\n');
  }

  /// Extracts page metadata (title, description, author, publish date, site
  /// name, canonical URL) from an HTML document.
  static PageMetadata extractPageMetadata(String html) {
    try {
      final doc = parse(html);
      final title = doc.querySelector('title')?.text.trim();
      final descriptionMeta = doc.querySelector('meta[name="description"]') ??
          doc.querySelector('meta[property="og:description"]');
      final authorMeta = doc.querySelector('meta[name="author"]') ??
          doc.querySelector('meta[property="article:author"]');
      final dateMeta = doc.querySelector('meta[property="article:published_time"]') ??
          doc.querySelector('meta[itemprop="datePublished"]') ??
          doc.querySelector('meta[name="publish-date"]');
      final siteMeta = doc.querySelector('meta[property="og:site_name"]');
      final canonical = doc.querySelector('link[rel="canonical"]');

      String? oneLine(String? value) {
        if (value == null) return null;
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }

      return PageMetadata(
        title: oneLine(title),
        description: oneLine(descriptionMeta?.attributes['content']),
        author: oneLine(authorMeta?.attributes['content']),
        publicationDate: oneLine(dateMeta?.attributes['content']),
        siteName: oneLine(siteMeta?.attributes['content']),
        canonicalUrl: oneLine(canonical?.attributes['href']),
      );
    } catch (e) {
      _logger.w('HTML metadata extraction failed', e);
      return const PageMetadata();
    }
  }

  static String _fallbackStripTags(String html) {
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
    final result = buffer.toString().trim();
    final lines = result
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 20)
        .toList();
    return lines.join('\n\n');
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
      case 'odt':
        return _extractOdt(archive);
      case 'pages':
        return _extractIwork(archive, 'pages');
      case 'numbers':
        return _extractIwork(archive, 'numbers');
      case 'key':
        return _extractIwork(archive, 'keynote');
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
    final footnoteBuffer = StringBuffer();
    final imageReferences = <String>[];

    final body = document.findAllElements('w:body').firstOrNull;
    if (body != null) {
      for (final child in body.childElements) {
        final localName = child.name.local;
        if (localName == 'p') {
          _extractDocxParagraph(archive, child, buffer, footnoteBuffer, imageReferences);
        } else if (localName == 'tbl') {
          buffer.writeln(_extractDocxTable(child));
        }
      }
    }

    final footnotes = _extractDocxFootnotes(archive);
    if (footnotes.isNotEmpty) {
      buffer.writeln('\n---\n**Footnotes:**');
      for (final entry in footnotes.entries) {
        buffer.writeln('[${entry.key}] ${entry.value}');
      }
    }

    if (imageReferences.isNotEmpty) {
      buffer.writeln('\n---\n**Embedded Images:**');
      for (final ref in imageReferences) {
        buffer.writeln('- $ref');
      }
    }

    return buffer.toString().trim();
  }

  void _extractDocxParagraph(
    Archive archive,
    XmlElement paragraph,
    StringBuffer buffer,
    StringBuffer footnoteBuffer,
    List<String> imageReferences,
  ) {
    final hasFootnoteRef = paragraph.findAllElements('w:footnoteReference').isNotEmpty;
    final hasImage = paragraph.findAllElements('a:blip').isNotEmpty ||
        paragraph.findAllElements('wp:inline').isNotEmpty ||
        paragraph.findAllElements('wp:anchor').isNotEmpty;

    for (final text in paragraph.findAllElements('w:t')) {
      buffer.write(text.innerText);
    }

    if (hasFootnoteRef) {
      for (final ref in paragraph.findAllElements('w:footnoteReference')) {
        final id = ref.getAttribute('w:id') ?? '?';
        buffer.write(' [$id]');
      }
    }

    if (hasImage) {
      for (final blip in paragraph.findAllElements('a:blip')) {
        final rId = blip.getAttribute('r:embed') ?? '';
        if (rId.isNotEmpty) {
          final imagePath = _resolveDocxImagePath(archive, rId);
          if (imagePath.isNotEmpty) {
            imageReferences.add('[Image: $imagePath]');
            buffer.write(' [img:$imagePath]');
          }
        }
      }
    }

    buffer.writeln();
  }

  String _extractDocxTable(XmlElement table) {
    final rows = <List<String>>[];
    for (final row in table.findAllElements('w:tr')) {
      final cells = <String>[];
      for (final cell in row.findAllElements('w:tc')) {
        final cellText = StringBuffer();
        for (final paragraph in cell.findAllElements('w:p')) {
          for (final text in paragraph.findAllElements('w:t')) {
            cellText.write(text.innerText);
          }
        }
        cells.add(cellText.toString());
      }
      rows.add(cells);
    }

    if (rows.isEmpty) return '';

    final buffer = StringBuffer();
    final maxCols = rows.fold<int>(0, (max, row) => row.length > max ? row.length : max);

    if (rows.isNotEmpty) {
      buffer.writeln('| ${rows[0].join(' | ')} |');
      buffer.writeln('|${List.filled(maxCols, '---').join('|')}|');
    }

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      while (row.length < maxCols) {
        row.add('');
      }
      buffer.writeln('| ${row.join(' | ')} |');
    }

    return buffer.toString();
  }

  String _resolveDocxImagePath(Archive archive, String rId) {
    final relsFile = archive.files.firstWhere(
      (f) => f.name == 'word/_rels/document.xml.rels',
      orElse: () => ArchiveFile('', 0, 0),
    );
    if (relsFile.size == 0) return '';

    try {
      final rels = XmlDocument.parse(utf8.decode(relsFile.content));
      for (final rel in rels.findAllElements('Relationship')) {
        if (rel.getAttribute('Id') == rId) {
          final target = rel.getAttribute('Target') ?? '';
          if (target.isNotEmpty) {
            return target.startsWith('media/') ? 'word/$target' : target;
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to resolve DOCX image relationship: $e');
    }
    return '';
  }

  Map<int, String> _extractDocxFootnotes(Archive archive) {
    final footnotes = <int, String>{};
    final footnotesFile = archive.files.firstWhere(
      (f) => f.name == 'word/footnotes.xml',
      orElse: () => ArchiveFile('', 0, 0),
    );
    if (footnotesFile.size == 0) return footnotes;

    try {
      final doc = XmlDocument.parse(utf8.decode(footnotesFile.content));
      for (final fn in doc.findAllElements('w:footnote')) {
        final idStr = fn.getAttribute('w:id');
        if (idStr == null) continue;
        final id = int.tryParse(idStr);
        if (id == null || id < 1) continue;

        final text = StringBuffer();
        for (final t in fn.findAllElements('w:t')) {
          text.write(t.innerText);
        }
        if (text.isNotEmpty) {
          footnotes[id] = text.toString();
        }
      }
    } catch (e) {
      _logger.w('Failed to extract DOCX footnotes: $e');
    }
    return footnotes;
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
        for (final element in slide.descendantElements) {
          if (element.name.local == 't') {
            buffer.write(element.innerText);
            buffer.write(' ');
          }
        }
        return buffer.toString().trim();
      } catch (e) {
        return '';
      }
    }

    List<String> extractSlideImages(String xmlContent) {
      final images = <String>[];
      try {
        final slide = XmlDocument.parse(xmlContent);
        for (final element in slide.descendantElements) {
          if (element.name.local == 'blip') {
            final rId = element.getAttribute('r:embed') ?? '';
            if (rId.isNotEmpty) {
              images.add(rId);
            }
          }
        }
      } catch (e) {
        // Ignore parse errors
      }
      return images;
    }

    final buffer = StringBuffer();
    final imageReferences = <String>[];
    final slideFiles = archive.files
        .where((f) => f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final slideFile in slideFiles) {
      final xmlContent = utf8.decode(slideFile.content);
      final text = extractSlideText(xmlContent);
      if (text.isNotEmpty) {
        buffer.writeln(text);
      }

      final slideImages = extractSlideImages(xmlContent);
      for (final rId in slideImages) {
        final imagePath = _resolvePptxImagePath(archive, rId);
        if (imagePath.isNotEmpty) {
          imageReferences.add('[Image: $imagePath]');
          buffer.writeln('[img:$imagePath]');
        }
      }

      buffer.writeln('---');
    }

    if (imageReferences.isNotEmpty) {
      buffer.writeln('\n**Embedded Images:**');
      for (final ref in imageReferences) {
        buffer.writeln('- $ref');
      }
    }

    return buffer.toString().trim();
  }

  String _resolvePptxImagePath(Archive archive, String rId) {
    final relsFile = archive.files.firstWhere(
      (f) => f.name == 'ppt/_rels/presentation.xml.rels',
      orElse: () => ArchiveFile('', 0, 0),
    );
    if (relsFile.size == 0) return '';

    try {
      final rels = XmlDocument.parse(utf8.decode(relsFile.content));
      for (final rel in rels.findAllElements('Relationship')) {
        if (rel.getAttribute('Id') == rId) {
          final target = rel.getAttribute('Target') ?? '';
          if (target.isNotEmpty) {
            return target.startsWith('media/') ? 'ppt/$target' : target;
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to resolve PPTX image relationship: $e');
    }
    return '';
  }

  String _extractOdt(Archive archive) {
    final contentFile = archive.files.firstWhere(
      (f) => f.name == 'content.xml',
      orElse: () => ArchiveFile('', 0, 0),
    );
    if (contentFile.size == 0) return '';

    try {
      final document = XmlDocument.parse(utf8.decode(contentFile.content));
      final buffer = StringBuffer();
      final imageReferences = <String>[];

      for (final paragraph in document.findAllElements('text:p')) {
        _extractOdtParagraph(archive, paragraph, buffer, imageReferences);
      }

      for (final table in document.findAllElements('table:table')) {
        buffer.writeln(_extractOdtTable(table));
      }

      if (imageReferences.isNotEmpty) {
        buffer.writeln('\n---\n**Embedded Images:**');
        for (final ref in imageReferences) {
          buffer.writeln('- $ref');
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      _logger.w('ODT extraction failed: $e');
      return '';
    }
  }

  void _extractOdtParagraph(
    Archive archive,
    XmlElement paragraph,
    StringBuffer buffer,
    List<String> imageReferences,
  ) {
    final hasChildElements = paragraph.childElements.isNotEmpty;

    if (hasChildElements) {
      for (final child in paragraph.childElements) {
        final localName = child.name.local;
        if (localName == 'span') {
          buffer.write(child.innerText);
        } else if (localName == 's') {
          final textContent = child.innerText;
          if (textContent.isNotEmpty) {
            buffer.write(textContent);
          } else {
            buffer.write(' ');
          }
        } else if (localName == 'tab') {
          buffer.write('\t');
        } else if (localName == 'line-break') {
          buffer.writeln();
        }
      }
    } else {
      buffer.write(paragraph.innerText);
    }

    for (final image in paragraph.findAllElements('draw:image')) {
      final href = image.getAttribute('xlink:href') ?? '';
      if (href.isNotEmpty && !href.startsWith('data:')) {
        imageReferences.add('[Image: $href]');
        buffer.write(' [img:$href]');
      }
    }

    buffer.writeln();
  }

  String _extractOdtTable(XmlElement table) {
    final rows = <List<String>>[];
    for (final row in table.findAllElements('table:table-row')) {
      final cells = <String>[];
      for (final cell in row.findAllElements('table:table-cell')) {
        final cellText = StringBuffer();
        for (final paragraph in cell.findAllElements('text:p')) {
          for (final text in paragraph.findAllElements('text:span')) {
            cellText.write(text.innerText);
          }
        }
        final repeat = int.tryParse(cell.getAttribute('table:number-columns-repeated') ?? '1') ?? 1;
        for (var i = 0; i < repeat; i++) {
          cells.add(cellText.toString());
        }
      }
      rows.add(cells);
    }

    if (rows.isEmpty) return '';

    final buffer = StringBuffer();
    final maxCols = rows.fold<int>(0, (max, row) => row.length > max ? row.length : max);

    if (rows.isNotEmpty) {
      buffer.writeln('| ${rows[0].join(' | ')} |');
      buffer.writeln('|${List.filled(maxCols, '---').join('|')}|');
    }

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      while (row.length < maxCols) {
        row.add('');
      }
      buffer.writeln('| ${row.join(' | ')} |');
    }

    return buffer.toString();
  }

  String _extractRtf(String rawContent) {
    var text = rawContent;

    text = text.replaceAllMapped(
      RegExp(r'\\par[d]?[ ]?'),
      (match) => '\n',
    );

    text = text.replaceAllMapped(
      RegExp(r'\\tab[ ]?'),
      (match) => '\t',
    );

    text = text.replaceAllMapped(
      RegExp(r'\\line[ ]?'),
      (match) => '\n',
    );

    text = text.replaceAllMapped(
      RegExp(r"\\'([0-9a-fA-F]{2})"),
      (match) {
        final hex = match.group(1);
        if (hex != null) {
          final code = int.tryParse(hex, radix: 16);
          if (code != null && code >= 32 && code < 127) {
            return String.fromCharCode(code);
          }
        }
        return '';
      },
    );

    text = text.replaceAllMapped(
      RegExp(r'\\u(\d+)\??'),
      (match) {
        final code = int.tryParse(match.group(1) ?? '');
        if (code != null) {
          return String.fromCharCode(code > 32767 ? code - 65536 : code);
        }
        return '';
      },
    );

    text = text.replaceAllMapped(
      RegExp(r'\\[a-zA-Z]+\d*\s?'),
      (match) => '',
    );

    text = text.replaceAll(RegExp(r'[{}]'), '');
    text = text.replaceAll(RegExp(r'\\ '), ' ');

    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return lines.join('\n\n');
  }

  String _extractIwork(Archive archive, String type) {
    String readFile(String path) {
      final file = archive.files.firstWhere(
        (f) => f.name == path,
        orElse: () => ArchiveFile('', 0, 0),
      );
      if (file.size == 0) return '';
      return utf8.decode(file.content);
    }

    try {
      final indexXml = readFile('index.xml');
      if (indexXml.isEmpty) return '';

      final document = XmlDocument.parse(indexXml);
      final buffer = StringBuffer();

      for (final text in document.findAllElements('t')) {
        final content = text.innerText;
        if (content.isNotEmpty) {
          buffer.write(content);
          buffer.write(' ');
        }
      }

      for (final text in document.findAllElements('text')) {
        final content = text.innerText;
        if (content.isNotEmpty && content.length > 2) {
          buffer.writeln(content);
        }
      }

      final result = buffer.toString().trim();
      if (result.isNotEmpty) return result;

      final allText = document.toXmlString();
      final textOnly = allText.replaceAll(RegExp(r'<[^>]+>'), ' ');
      final cleaned = textOnly.split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .join(' ');
      return cleaned;
    } catch (e) {
      _logger.w('$type extraction failed: $e');
      return '';
    }
  }

  void dispose() {
    _transcriptionExtractor.dispose();
    _transcriptionPipeline?.dispose();
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
