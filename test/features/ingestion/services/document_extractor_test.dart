import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';

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
}
