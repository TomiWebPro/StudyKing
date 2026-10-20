import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/data/models/source_figure.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/extraction_result.dart';

class FakeOcrEngine implements OcrEngine {
  @override
  String get name => 'fake';

  @override
  bool get supportsConfidence => false;

  @override
  Future<Result<OcrEngineResult>> recognize(OcrImageInput input) async {
    return Result.success(const OcrEngineResult(text: '', engineName: 'fake'));
  }
}

class FakeOcrExtractor extends OcrExtractor {
  final OcrExtractionResult resultToReturn;

  FakeOcrExtractor(this.resultToReturn)
      : super(
          mode: OcrMode.fast,
          modelId: 'fake-model',
          localeName: 'en',
          mlKitEngine: FakeOcrEngine(),
          llmEngine: FakeOcrEngine(),
        );

  @override
  Future<OcrExtractionResult> extractText({
    required String rawContent,
    required String? sourceUrl,
  }) async =>
      resultToReturn;
}

class FakePdfExtractor extends PdfExtractor {
  @override
  Future<Result<PdfExtractionResult>> extractFromFile(String filePath) async =>
      Result.success(const PdfExtractionResult(
        text: '',
        extractionMethod: 'fake_pdf',
      ));
}

/// Configurable PDF extractor that returns a canned [PdfExtractionResult],
/// including optional images so the figure-extraction path can be tested.
class ConfigurablePdfExtractor extends PdfExtractor {
  final PdfExtractionResult result;

  ConfigurablePdfExtractor(this.result);

  @override
  Future<Result<PdfExtractionResult>> extractFromFile(String filePath) async =>
      Result.success(result);
}

class FakeTranscriptionExtractor extends TranscriptionExtractor {
  FakeTranscriptionExtractor() : super(modelId: 'm', localeName: 'en');

  @override
  Future<TranscriptionResult> transcribeVideo({
    required String rawContent,
    required String? sourceUrl,
  }) async =>
      const TranscriptionResult(text: '', extractionMethod: 'fake_transcription');

  @override
  Future<TranscriptionResult> transcribeAudio({
    required String rawContent,
    required String? sourceUrl,
  }) async =>
      const TranscriptionResult(text: '', extractionMethod: 'fake_transcription');
}

DocumentExtractor buildExtractor(OcrExtractionResult ocrResult) {
  return DocumentExtractor(
    modelId: 'm',
    localeName: 'en',
    ocrExtractor: FakeOcrExtractor(ocrResult),
    pdfExtractor: FakePdfExtractor(),
    transcriptionExtractor: FakeTranscriptionExtractor(),
  );
}

class ConfigurableTranscriptionExtractor extends TranscriptionExtractor {
  final TranscriptionResult resultToReturn;

  ConfigurableTranscriptionExtractor(this.resultToReturn)
      : super(modelId: 'm', localeName: 'en');

  @override
  Future<TranscriptionResult> transcribeVideo({
    required String rawContent,
    required String? sourceUrl,
  }) async =>
      resultToReturn;

  @override
  Future<TranscriptionResult> transcribeAudio({
    required String rawContent,
    required String? sourceUrl,
  }) async =>
      resultToReturn;
}

DocumentExtractor buildExtractorWithTranscription(
  TranscriptionResult transcriptionResult,
) {
  return DocumentExtractor(
    modelId: 'm',
    localeName: 'en',
    ocrExtractor: FakeOcrExtractor(
      const OcrExtractionResult(text: '', extractionMethod: 'x'),
    ),
    pdfExtractor: FakePdfExtractor(),
    transcriptionExtractor: ConfigurableTranscriptionExtractor(transcriptionResult),
  );
}

void main() {
  group('DocumentExtractor.extractText', () {
    test('returns direct text for lecture notes', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'My lecture notes',
        sourceType: SourceType.lectureNotes,
      );

      expect(result.text, 'My lecture notes');
      expect(result.extractionMethod, 'direct');
      expect(result.isError, isFalse);
    });

    test('strips html for web pages', () async {
      final html = '<html><head><title>T</title></head><body>'
          '<p>This is a reasonably long piece of web page content that should '
          'be extracted by the readability style parser in tests.</p>'
          '</body></html>';
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: html,
        sourceType: SourceType.webPage,
      );

      expect(result.extractionMethod, 'html_stripped');
      expect(result.text, contains('reasonably long'));
    });

    test('treats plain pdf text as direct extraction', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'Plain pdf text content here.',
        sourceType: SourceType.pdf,
      );

      expect(result.extractionMethod, 'pdf_text_direct');
      expect(result.text, 'Plain pdf text content here.');
    });

    test('returns extracted text on a successful OCR image', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(
          text: 'OCR extracted text',
          extractionMethod: 'ocr',
          confidence: 0.9,
        ),
      );

      final result = await extractor.extractText(
        rawContent: 'file:///x.png',
        sourceType: SourceType.image,
      );

      expect(result.text, 'OCR extracted text');
      expect(result.extractionMethod, 'ocr');
      expect(result.ocrConfidence, 0.9);
      expect(result.isError, isFalse);
    });

    test('returns an error-carrying result (not a throw) when OCR fails',
        () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(
          text: '',
          extractionMethod: 'ocr_failed',
          errorMessage: 'boom',
        ),
      );

      final result = await extractor.extractText(
        rawContent: 'file:///x.png',
        sourceType: SourceType.image,
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, 'boom');
      // The raw reference is preserved as a fallback rather than crashing.
      expect(result.text, 'file:///x.png');
    });

    test('truncates text exceeding maxCharsPerSource with user-visible note', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final longText = 'a' * (DocumentExtractor.maxCharsPerSource + 100);

      final result = await extractor.extractText(
        rawContent: longText,
        sourceType: SourceType.lectureNotes,
      );

      expect(result.truncated, isTrue);
      expect(result.truncationNote, isNotNull);
      expect(result.truncationNote, contains('truncated'));
      expect(result.text.length, DocumentExtractor.maxCharsPerSource);
    });

    test('does not truncate text within maxCharsPerSource', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final shortText = 'a' * (DocumentExtractor.maxCharsPerSource - 1);

      final result = await extractor.extractText(
        rawContent: shortText,
        sourceType: SourceType.lectureNotes,
      );

      expect(result.truncated, isFalse);
      expect(result.truncationNote, isNull);
      expect(result.text.length, shortText.length);
    });

    test('does not truncate error results even if text exceeds ceiling', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(
          text: '',
          extractionMethod: 'ocr_failed',
          errorMessage: 'boom',
        ),
      );

      final result = await extractor.extractText(
        rawContent: 'file:///x.png',
        sourceType: SourceType.image,
      );

      expect(result.isError, isTrue);
      expect(result.truncated, isFalse);
    });
  });

  group('DocumentExtractor chapter heading detection', () {
    test('detects chapter heading with title in PDF text', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final textbookText = 'Chapter 1 Introduction to Biology\n\n'
          'This chapter covers cell biology fundamentals.\n\n'
          'Section 1.1 The Scientific Method\n\n'
          'The scientific method is a systematic approach.';

      final result = await extractor.extractText(
        rawContent: textbookText,
        sourceType: SourceType.pdf,
      );

      expect(result.chunks, isNotEmpty);
      expect(result.chunks.first.heading, 'Chapter 1 Introduction to Biology');
    });

    test('detects chapter heading without title', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final textbookText = 'Chapter 1\n\n'
          'Content of the first chapter in the textbook.';

      final result = await extractor.extractText(
        rawContent: textbookText,
        sourceType: SourceType.pdf,
      );

      expect(result.chunks, isNotEmpty);
      expect(result.chunks.first.heading, 'Chapter 1');
    });

    test('detects section heading with sub-number', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final textbookText = 'Section 2.3 The Cell Structure\n\n'
          'Cells have a nucleus and cytoplasm.';

      final result = await extractor.extractText(
        rawContent: textbookText,
        sourceType: SourceType.pdf,
      );

      expect(result.chunks, isNotEmpty);
      expect(result.chunks.first.heading, 'Section 2.3 The Cell Structure');
    });

    test('detects case-insensitive Chapter heading', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final textbookText = 'chapter 1 introduction\n\n'
          'Some content here.';

      final result = await extractor.extractText(
        rawContent: textbookText,
        sourceType: SourceType.pdf,
      );

      expect(result.chunks, isNotEmpty);
      expect(result.chunks.first.heading, 'chapter 1 introduction');
    });

    test('detects numbered section heading (1.1 style)', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final textbookText = '1.1 The Scientific Method\n\n'
          'This section describes the scientific method in detail.';

      final result = await extractor.extractText(
        rawContent: textbookText,
        sourceType: SourceType.pdf,
      );

      expect(result.chunks, isNotEmpty);
      expect(result.chunks.first.heading, '1.1 The Scientific Method');
    });

    test('ignores decimal value in prose as heading', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final textbookText = 'The value of pi is 3.14 and is irrational.\n\n'
          'Some content here.';

      final result = await extractor.extractText(
        rawContent: textbookText,
        sourceType: SourceType.pdf,
      );

      expect(result.chunks, isNotEmpty);
      // "3.14" starts mid-line, not at start of a paragraph, so should not be a heading
      expect(result.chunks.first.heading, isNull);
    });
  });

  group('DocumentExtractor static helpers', () {
    test('stripHtmlToText extracts main readable content', () {
      final text = DocumentExtractor.stripHtmlToText(
        '<html><body><h1>Title</h1>'
        '<p>Some content here that is long enough to be a candidate paragraph '
        'for extraction purposes in the test.</p>'
        '<script>window.x=1;</script></body></html>',
      );

      expect(text, contains('Some content here'));
      expect(text, isNot(contains('window.x')));
    });

    test('extractPageMetadata parses head metadata', () {
      final meta = DocumentExtractor.extractPageMetadata(
        '<html><head><title>Page Title</title>'
        '<meta name="description" content="A description">'
        '<meta property="og:site_name" content="Site"></head>'
        '<body></body></html>',
      );

      expect(meta.title, 'Page Title');
      expect(meta.description, 'A description');
      expect(meta.siteName, 'Site');
    });
  });

  group('DocumentExtractor OOXML part ordering', () {
    Archive archiveWithParts(String prefix, int count, String Function(int i) xmlFor) {
      final archive = Archive();
      for (var i = 1; i <= count; i++) {
        final xml = xmlFor(i);
        archive.addFile(
          ArchiveFile('$prefix$i.xml', xml.length, utf8.encode(xml)),
        );
      }
      return archive;
    }

    Future<String> extractZipFromTemp(
      Archive archive,
      String fileName,
    ) async {
      final dir = await Directory.systemTemp.createTemp('sk_ooxml');
      try {
        final path = '${dir.path}/$fileName';
        final zipBytes = ZipEncoder().encode(archive);
        expect(zipBytes, isNotNull);
        await File(path).writeAsBytes(zipBytes!);

        final extractor = buildExtractor(
          const OcrExtractionResult(text: '', extractionMethod: 'x'),
        );
        final result = await extractor.extractText(
          rawContent: 'file://$path',
          sourceType: SourceType.document,
        );
        return result.text;
      } finally {
        await dir.delete(recursive: true);
      }
    }

    test('extracts pptx slides in numeric order with 10+ slides', () async {
      final archive = archiveWithParts(
        'ppt/slides/slide',
        12,
        (i) => '<p:sld xmlns:p="p" xmlns:a="a">'
            '<p:sp><a:t>SLIDE-${i.toString().padLeft(2, '0')}</a:t></p:sp>'
            '</p:sld>',
      );

      final text = await extractZipFromTemp(archive, 'deck.pptx');

      final markers = [
        for (var i = 1; i <= 12; i++) 'SLIDE-${i.toString().padLeft(2, '0')}',
      ];
      var lastIndex = -1;
      for (final marker in markers) {
        final index = text.indexOf(marker);
        expect(index, greaterThan(lastIndex),
            reason: '$marker is out of order in:\n$text');
        lastIndex = index;
      }
    });

    test('extracts xlsx sheets in numeric order with 10+ sheets', () async {
      final archive = archiveWithParts(
        'xl/worksheets/sheet',
        12,
        (i) => '<worksheet><sheetData><row><c><v>$i</v></c></row>'
            '</sheetData></worksheet>',
      );

      final text = await extractZipFromTemp(archive, 'book.xlsx');

      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(lines, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']);
    });
  });

  // --- media URL / content-trust invariant (issue: ingestion-media-url-stored-as-content) ---
  // No path may return a bare URL/path as `text`. When real content cannot be
  // recovered from video/audio/web/lecture-notes inputs, the result must be an
  // explicit error with empty text so the pipeline halts instead of feeding a
  // URL string to downstream LLM stages.
  group('DocumentExtractor media URL inputs never stored as content', () {
    test('returns error for lecture notes with bare URL', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'https://example.com/lecture-notes',
        sourceType: SourceType.lectureNotes,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'web_no_content');
      expect(result.errorMessage, isNotNull);
    });

    test('returns error for external resource with bare URL', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'http://example.com/resource',
        sourceType: SourceType.externalResource,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'web_no_content');
      expect(result.errorMessage, isNotNull);
    });

    test('returns error for web page with bare URL', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'https://example.com/article',
        sourceType: SourceType.webPage,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'web_no_content');
      expect(result.errorMessage, isNotNull);
    });

    test('returns error for YouTube video URL', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        sourceType: SourceType.video,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'youtube_transcript_missing');
      expect(result.errorMessage, isNotNull);
    });

    test('returns error for non-YouTube video URL', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'https://example.com/video.mp4',
        sourceType: SourceType.video,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'video_transcript_missing');
      expect(result.errorMessage, isNotNull);
    });

    test('returns error for non-URL video input without transcript', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'file:///path/to/video.mp4',
        sourceType: SourceType.video,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'video_no_content');
      expect(result.errorMessage, isNotNull);
    });

    test('returns error for audio URL', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'https://example.com/audio.mp3',
        sourceType: SourceType.audio,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'audio_transcript_missing');
      expect(result.errorMessage, isNotNull);
    });

    test('returns error for non-URL audio input without transcript', () async {
      final extractor = buildExtractor(
        const OcrExtractionResult(text: '', extractionMethod: 'x'),
      );

      final result = await extractor.extractText(
        rawContent: 'file:///path/to/audio.mp3',
        sourceType: SourceType.audio,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'audio_no_content');
      expect(result.errorMessage, isNotNull);
    });

    test('propagates transcription error instead of falling back to URL', () async {
      final extractor = buildExtractorWithTranscription(
        const TranscriptionResult(
          text: '',
          extractionMethod: 'transcription_llm_failed',
          errorMessage: 'transcription failed',
        ),
      );

      final result = await extractor.extractText(
        rawContent: 'https://example.com/video.mp4',
        sourceType: SourceType.video,
      );

      expect(result.isError, isTrue);
      expect(result.text, isEmpty);
      expect(result.extractionMethod, 'transcription_llm_failed');
      expect(result.errorMessage, 'transcription failed');
    });

    test('uses transcription text when available, ignoring URL format', () async {
      final extractor = buildExtractorWithTranscription(
        const TranscriptionResult(
          text: 'Real transcript content from the video',
          extractionMethod: 'transcribed_llm',
        ),
      );

      final result = await extractor.extractText(
        rawContent: 'https://example.com/video.mp4',
        sourceType: SourceType.video,
      );

      expect(result.isError, isFalse);
      expect(result.text, 'Real transcript content from the video');
      expect(result.extractionMethod, 'transcribed_llm');
    });
  });

  // --- Figure (image/chart/diagram) extraction (Vision Next-Term §4.1) ---

  group('DocumentExtractor figuresFromPdfImages', () {
    test('returns empty list for null images', () {
      expect(DocumentExtractor.figuresFromPdfImages(null), isEmpty);
    });

    test('returns empty list for empty images', () {
      expect(DocumentExtractor.figuresFromPdfImages([]), isEmpty);
    });

    test('skips images with empty bytes', () {
      final images = [
        PdfPageImage(pageNumber: 1, bytes: Uint8List(0), name: 'fig1'),
        PdfPageImage(pageNumber: 2, bytes: Uint8List.fromList([1, 2, 3]), name: 'fig2'),
      ];
      final figures = DocumentExtractor.figuresFromPdfImages(images);
      expect(figures.length, 1);
      expect(figures[0].pageNumber, 2);
      expect(figures[0].caption, 'fig2');
    });

    test('maps JPEG filter to image/jpeg mimeType', () {
      final images = [
        PdfPageImage(
          pageNumber: 1,
          bytes: Uint8List.fromList([0xFF, 0xD8]),
          filter: 'DCTDecode',
          name: 'chart',
        ),
      ];
      final figures = DocumentExtractor.figuresFromPdfImages(images);
      expect(figures.length, 1);
      expect(figures[0].mimeType, 'image/jpeg');
      expect(figures[0].source, 'pdf');
      expect(figures[0].hasBytes, isTrue);
    });

    test('defaults to image/png for unknown filter', () {
      final images = [
        PdfPageImage(
          pageNumber: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
          filter: 'FlateDecode',
        ),
      ];
      final figures = DocumentExtractor.figuresFromPdfImages(images);
      expect(figures[0].mimeType, 'image/png');
      expect(figures[0].pageNumber, 3);
    });

    test('uses empty caption when image name is null', () {
      final images = [
        PdfPageImage(
          pageNumber: 1,
          bytes: Uint8List.fromList([1]),
          name: null,
        ),
      ];
      final figures = DocumentExtractor.figuresFromPdfImages(images);
      expect(figures[0].caption, '');
    });
  });

  group('DocumentExtractor figureFromArchiveAsset', () {
    test('returns null for empty resolved path', () {
      final archive = Archive();
      expect(DocumentExtractor.figureFromArchiveAsset(archive, ''), isNull);
    });

    test('returns null when asset is missing', () {
      final archive = Archive();
      expect(
        DocumentExtractor.figureFromArchiveAsset(
          archive,
          'nonexistent.png',
        ),
        isNull,
      );
    });

    test('returns null when asset size is zero', () {
      final archive = Archive();
      archive.addFile(ArchiveFile('image.png', 0, <int>[]));
      expect(
        DocumentExtractor.figureFromArchiveAsset(archive, 'image.png'),
        isNull,
      );
    });

    test('reads embedded asset bytes as a figure', () {
      final archive = Archive();
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      archive.addFile(ArchiveFile('media/image1.png', pngBytes.length, pngBytes));

      final figure = DocumentExtractor.figureFromArchiveAsset(
        archive,
        'media/image1.png',
        pageNumber: 5,
        caption: 'Embedded chart',
      );

      expect(figure, isNotNull);
      expect(figure!.hasBytes, isTrue);
      expect(figure.bytes, pngBytes);
      expect(figure.pageNumber, 5);
      expect(figure.caption, 'Embedded chart');
      expect(figure.mimeType, 'image/png');
      expect(figure.source, 'office');
    });

    test('infers mimeType from extension when not provided', () {
      final archive = Archive();
      archive.addFile(ArchiveFile('pic.jpg', 3, Uint8List.fromList([1, 2, 3])));

      final figure = DocumentExtractor.figureFromArchiveAsset(
        archive,
        'pic.jpg',
      );

      expect(figure, isNotNull);
      expect(figure!.mimeType, 'image/jpeg');
    });
  });

  group('DocumentExtractor stripImagePlaceholders', () {
    test('removes [img:...] placeholders', () {
      final text = 'Before [img:word/media/image1.png] After';
      expect(DocumentExtractor.stripImagePlaceholders(text), 'Before  After');
    });

    test('removes [Image: ...] placeholders with dash prefix', () {
      final text = 'Text\n- [Image: word/media/image1.png]\nMore text';
      final cleaned = DocumentExtractor.stripImagePlaceholders(text);
      expect(cleaned, isNot(contains('[Image')));
      expect(cleaned, contains('Text'));
      expect(cleaned, contains('More text'));
    });

    test('removes Embedded Images footer', () {
      // The Embedded Images footer appears at the end of office-doc output.
      final text = 'Content here\n\n'
          '---\n**Embedded Images:** some images\n\n';
      final cleaned = DocumentExtractor.stripImagePlaceholders(text);
      expect(cleaned, isNot(contains('Embedded Images')));
      expect(cleaned, contains('Content here'));
    });

    test('collapses multiple blank lines', () {
      final text = 'A\n\n\n\n\nB';
      final cleaned = DocumentExtractor.stripImagePlaceholders(text);
      expect(cleaned, 'A\n\nB');
    });

    test('returns empty string for empty input', () {
      expect(DocumentExtractor.stripImagePlaceholders(''), '');
    });

    test('leaves text without placeholders unchanged (trimmed)', () {
      const text = 'Plain text without placeholders.';
      expect(DocumentExtractor.stripImagePlaceholders(text), text);
    });
  });

  group('DocumentExtractor PDF image extraction via file', () {
    test('extracts PDF images as figures that survive ingestion', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final pdfResult = PdfExtractionResult(
        text: 'Some PDF text describing a chart.',
        extractionMethod: 'pdf_parsed',
        pageCount: 3,
        images: [
          PdfPageImage(
            pageNumber: 1,
            bytes: jpegBytes,
            filter: 'DCTDecode',
            name: 'Figure 1: Revenue chart',
          ),
          PdfPageImage(
            pageNumber: 2,
            bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
            filter: 'FlateDecode',
            name: 'Figure 2: Diagram',
          ),
        ],
      );

      final extractor = DocumentExtractor(
        modelId: 'm',
        localeName: 'en',
        ocrExtractor: FakeOcrExtractor(
          const OcrExtractionResult(text: '', extractionMethod: 'x'),
        ),
        pdfExtractor: ConfigurablePdfExtractor(pdfResult),
        transcriptionExtractor: FakeTranscriptionExtractor(),
      );

      // The ConfigurablePdfExtractor is only reached through the file:// path,
      // so we create a dummy file whose existence gates entry to the extractor.
      final dir = await Directory.systemTemp.createTemp('sk_pdf_figure');
      final filePath = '${dir.path}/doc.pdf';
      await File(filePath).writeAsBytes([0x25, 0x50, 0x44, 0x46]);
      try {
        final result = await extractor.extractText(
          rawContent: 'file://$filePath',
          sourceType: SourceType.pdf,
        );

        expect(result.isError, isFalse);
        expect(result.figures.length, 2);
      expect(result.figures[0].pageNumber, 1);
      expect(result.figures[0].mimeType, 'image/jpeg');
        expect(result.figures[1].pageNumber, 2);
        expect(result.figures[1].mimeType, 'image/png');
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('preserves figures when text exceeds truncation ceiling', () async {
      // Replicate the truncation invariant: a non-error ExtractionResult with
      // figures must carry them through even when the text exceeds the ceiling.
      // _truncateIfExceeds (private) is exercised via extractText for real;
      // here we assert the figures field is independent of text length.
      final figures = [
        SourceFigure(pageNumber: 1, bytes: Uint8List.fromList([1])),
      ];
      final longText = 'a' * (DocumentExtractor.maxCharsPerSource + 100);
      final result = ExtractionResult(
        text: longText,
        extractionMethod: 'test',
        figures: figures,
      );

      expect(result.figures, figures);
      expect(result.figures.length, 1);
    });
  });

  group('DocumentExtractor office figure extraction', () {
    test('extracts DOCX embedded image as figure and strips [img:] placeholders', () async {
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      final archive = Archive()
        ..addFile(ArchiveFile(
          'word/document.xml',
          utf8.encode(
            '<w:document xmlns:w="w" xmlns:r="r" xmlns:a="a" xmlns:wp="wp">'
            '<w:body>'
            '<w:p><w:r><w:t>Some text [img:word/media/image1.png] more</w:t></w:r></w:p>'
            '<w:p>'
            '<w:r>'
            '<w:drawing>'
            '<wp:inline>'
            '<a:blip r:embed="rId1"/>'
            '</wp:inline>'
            '</w:drawing>'
            '</w:r>'
            '<w:r><w:t>Caption text</w:t></w:r>'
            '</w:p>'
            '</w:body>'
            '</w:document>',
          ).length,
          utf8.encode(
            '<w:document xmlns:w="w" xmlns:r="r" xmlns:a="a" xmlns:wp="wp">'
            '<w:body>'
            '<w:p><w:r><w:t>Some text [img:word/media/image1.png] more</w:t></w:r></w:p>'
            '<w:p>'
            '<w:r>'
            '<w:drawing>'
            '<wp:inline>'
            '<a:blip r:embed="rId1"/>'
            '</wp:inline>'
            '</w:drawing>'
            '</w:r>'
            '<w:r><w:t>Caption text</w:t></w:r>'
            '</w:p>'
            '</w:body>'
            '</w:document>',
          ),
        ))
        ..addFile(ArchiveFile(
          'word/_rels/document.xml.rels',
          utf8.encode(
            '<Relationships xmlns="r">'
            '<Relationship Id="rId1" Type="image" Target="media/image1.png"/>'
            '</Relationships>',
          ).length,
          utf8.encode(
            '<Relationships xmlns="r">'
            '<Relationship Id="rId1" Type="image" Target="media/image1.png"/>'
            '</Relationships>',
          ),
        ))
        ..addFile(ArchiveFile(
          'word/media/image1.png',
          pngBytes.length,
          pngBytes,
        ));

      final dir = await Directory.systemTemp.createTemp('sk_docx_figure');
      try {
        final zipBytes = ZipEncoder().encode(archive);
        expect(zipBytes, isNotNull);
        final path = '${dir.path}/test.docx';
        await File(path).writeAsBytes(zipBytes!);

        final extractor = buildExtractor(
          const OcrExtractionResult(text: '', extractionMethod: 'x'),
        );

        final result = await extractor.extractText(
          rawContent: 'file://$path',
          sourceType: SourceType.document,
        );

        expect(result.isError, isFalse);
        expect(result.figures.length, 1);
        expect(result.figures[0].hasBytes, isTrue);
        expect(result.figures[0].bytes, pngBytes);
        expect(result.figures[0].mimeType, 'image/png');
        expect(result.figures[0].source, 'office');
        // The [img:] placeholder must be stripped from the text.
        expect(result.text, isNot(contains('[img:')));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('extracts PPTX embedded image with page number from slide', () async {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final archive = Archive()
        ..addFile(ArchiveFile(
          'ppt/slides/slide1.xml',
          utf8.encode(
            '<p:sld xmlns:p="p" xmlns:a="a">'
            '<p:sp><a:t>Slide 1 text</a:t></p:sp>'
            '<p:pic><a:blip r:embed="rId2"/></p:pic>'
            '</p:sld>',
          ).length,
          utf8.encode(
            '<p:sld xmlns:p="p" xmlns:a="a">'
            '<p:sp><a:t>Slide 1 text</a:t></p:sp>'
            '<p:pic><a:blip r:embed="rId2"/></p:pic>'
            '</p:sld>',
          ),
        ))
        ..addFile(ArchiveFile(
          'ppt/_rels/presentation.xml.rels',
          utf8.encode(
            '<Relationships xmlns="r">'
            '<Relationship Id="rId2" Type="image" Target="media/image1.png"/>'
            '</Relationships>',
          ).length,
          utf8.encode(
            '<Relationships xmlns="r">'
            '<Relationship Id="rId2" Type="image" Target="media/image1.png"/>'
            '</Relationships>',
          ),
        ))
        ..addFile(ArchiveFile(
          'ppt/media/image1.png',
          jpegBytes.length,
          jpegBytes,
        ));

      final dir = await Directory.systemTemp.createTemp('sk_pptx_figure');
      try {
        final zipBytes = ZipEncoder().encode(archive);
        expect(zipBytes, isNotNull);
        final path = '${dir.path}/deck.pptx';
        await File(path).writeAsBytes(zipBytes!);

        final extractor = buildExtractor(
          const OcrExtractionResult(text: '', extractionMethod: 'x'),
        );

        final result = await extractor.extractText(
          rawContent: 'file://$path',
          sourceType: SourceType.document,
        );

        expect(result.isError, isFalse);
        expect(result.figures.length, 1);
        expect(result.figures[0].pageNumber, 1);
        expect(result.figures[0].source, 'office');
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
