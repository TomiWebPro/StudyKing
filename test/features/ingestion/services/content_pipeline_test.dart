import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert' show utf8;

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/data/extraction/ocr_extractor.dart';
import 'package:studyking/core/data/extraction/pdf_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/services/chunked_content_processor.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/extraction_result.dart';
import 'package:studyking/features/ingestion/services/page_metadata.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';

class FakeLlmService extends LlmService {
  FakeLlmService() : super(config: const LlmConfiguration(
    provider: LlmProvider.ollama,
    apiKey: 'k',
    baseUrl: '',
    model: 'm',
  ));

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    return Result.success('llm-response');
  }
}

class FakeOcrEngine implements OcrEngine {
  @override
  String get name => 'fake';
  @override
  bool get supportsConfidence => false;
  @override
  Future<Result<OcrEngineResult>> recognize(OcrImageInput input) async =>
      Result.success(const OcrEngineResult(text: '', engineName: 'fake'));
}

class FakeOcrExtractor extends OcrExtractor {
  FakeOcrExtractor()
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
      const OcrExtractionResult(text: '', extractionMethod: 'x');
}

class FakePdfExtractor extends PdfExtractor {
  @override
  Future<Result<PdfExtractionResult>> extractFromFile(String filePath) async =>
      Result.success(const PdfExtractionResult(text: '', extractionMethod: 'fake'));
}

class FakeTranscriptionExtractor extends TranscriptionExtractor {
  FakeTranscriptionExtractor() : super(modelId: 'm', localeName: 'en');
  @override
  Future<TranscriptionResult> transcribeVideo({
    required String rawContent,
    required String? sourceUrl,
  }) async =>
      const TranscriptionResult(text: '', extractionMethod: 'fake');
  @override
  Future<TranscriptionResult> transcribeAudio({
    required String rawContent,
    required String? sourceUrl,
  }) async =>
      const TranscriptionResult(text: '', extractionMethod: 'fake');
}

class FakeDocumentExtractor extends DocumentExtractor {
  final ExtractionResult resultToReturn;
  bool extractTextCalled = false;

  FakeDocumentExtractor(this.resultToReturn)
      : super(
          modelId: 'm',
          localeName: 'en',
          ocrExtractor: FakeOcrExtractor(),
          pdfExtractor: FakePdfExtractor(),
          transcriptionExtractor: FakeTranscriptionExtractor(),
        );

  @override
  Future<ExtractionResult> extractText({
    required String rawContent,
    required SourceType sourceType,
    String? sourceUrl,
  }) async {
    extractTextCalled = true;
    return resultToReturn;
  }

  @override
  void dispose() {}
}

class FakeChunkedContentProcessor extends ChunkedContentProcessor {
  final ClassificationResult classificationResult;
  bool classifyCalled = false;
  bool summarizeCalled = false;

  FakeChunkedContentProcessor(this.classificationResult)
      : super(llmService: FakeLlmService(), localeName: 'en');

  @override
  Future<ClassificationResult> classifyChunks({
    required List<SourceChunk> chunks,
    required List<String> possibleTopics,
    required String modelId,
    required String subjectId,
  }) async {
    classifyCalled = true;
    return classificationResult;
  }

  @override
  Future<String> generateConsolidatedSummary({
    required List<SourceChunk> chunks,
    required String modelId,
    String? existingTopicTitle,
  }) async {
    summarizeCalled = true;
    return 'fake summary';
  }

  @override
  List<SourceChunk> splitIntoChunks(String text) => [
        SourceChunk(chunkIndex: 0, text: text),
      ];
}

class FakeSourceRepository extends SourceRepository {
  final Map<String, Source> _store = {};

  FakeSourceRepository() : super();

  @override
  Future<Result<void>> create(Source source) async {
    _store[source.id] = source;
    return Result.success(null);
  }

  @override
  Future<Result<void>> save(String key, Source item) async {
    _store[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<List<Source>>> getAll() async =>
      Result.success(_store.values.toList());

  Source? getStored(String id) => _store[id];
}

class FakeTopicRepository extends TopicRepository {
  final List<Topic> _topics;
  FakeTopicRepository(this._topics) : super();

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(_topics);

  @override
  Future<Result<void>> create(Topic topic) async => Result.success(null);
}

class FakeQuestionRepository extends QuestionRepository {
  FakeQuestionRepository() : super();
  @override
  Future<Result<void>> create(Question question) async => Result.success(null);
  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

class FakeWebScraper extends WebScraper {
  final Result<ScrapedPage> pageResult;
  FakeWebScraper(this.pageResult) : super();

  @override
  Future<Result<ScrapedPage>> fetchPageContent(String url) async => pageResult;

  @override
  void dispose() {}
}

ContentPipeline buildPipeline({
  required FakeDocumentExtractor docExtractor,
  required FakeChunkedContentProcessor chunked,
  required FakeSourceRepository sourceRepo,
  required FakeTopicRepository topicRepo,
  required FakeWebScraper webScraper,
}) {
  return ContentPipeline(
    llmService: FakeLlmService(),
    sourceRepository: sourceRepo,
    topicRepository: topicRepo,
    questionRepository: FakeQuestionRepository(),
    documentExtractor: docExtractor,
    webScraper: webScraper,
    chunkedProcessor: chunked,
    modelId: 'm',
    localeName: 'en',
  );
}

void main() {
  group('ContentPipeline.processUpload', () {
    test('persists the source and returns success', () async {
      final sourceRepo = FakeSourceRepository();
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(text: '', extractionMethod: 'x'),
        ),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: sourceRepo,
        topicRepo: FakeTopicRepository([]),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
      );

      final result = await pipeline.processUpload(
        title: 'T',
        content: 'hello world content',
        type: SourceType.pdf,
        studentId: 's1',
      );

      expect(result.isSuccess, isTrue);
      final src = result.data!;
      expect(src.id, isNotEmpty);
      expect(sourceRepo.getStored(src.id), isNotNull);
    });

    test('detects duplicates by content hash', () async {
      final sourceRepo = FakeSourceRepository();
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(text: '', extractionMethod: 'x'),
        ),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: sourceRepo,
        topicRepo: FakeTopicRepository([]),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
      );

      final first = await pipeline.processUpload(
        title: 'T',
        content: 'dup content',
        type: SourceType.pdf,
        studentId: 's1',
      );
      expect(first.isSuccess, isTrue);

      final second = await pipeline.processUpload(
        title: 'T2',
        content: 'dup content',
        type: SourceType.pdf,
        studentId: 's1',
      );
      expect(second.isFailure, isTrue);
      expect(second.error, contains('DUPLICATE'));
    });
  });

  group('ContentPipeline.processFullPipeline', () {
    test('routes extraction, classification and summarization', () async {
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'chunk one text'),
        SourceChunk(chunkIndex: 1, text: 'chunk two text'),
      ];
      final docExtractor = FakeDocumentExtractor(ExtractionResult(
        text: 'extracted text',
        extractionMethod: 'pdf_text_direct',
        chunks: chunks,
      ));
      final topic = Topic(
        id: 'topic-1',
        subjectId: '',
        title: 'Biology',
        description: '',
        syllabusText: '',
      );
      final topicRepo = FakeTopicRepository([topic]);
      final chunked = FakeChunkedContentProcessor(
        ClassificationResult(topicId: 'Biology', confidence: 1.0),
      );
      final sourceRepo = FakeSourceRepository();
      final webScraper = FakeWebScraper(
        Result.success(ScrapedPage(
          content: '',
          metadata: const PageMetadata(),
        )),
      );

      final pipeline = buildPipeline(
        docExtractor: docExtractor,
        chunked: chunked,
        sourceRepo: sourceRepo,
        topicRepo: topicRepo,
        webScraper: webScraper,
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
        possibleTopics: ['Biology'],
      );

      expect(result.isSuccess, isTrue);
      final src = result.data!;
      expect(docExtractor.extractTextCalled, isTrue);
      expect(chunked.classifyCalled, isTrue);
      expect(chunked.summarizeCalled, isTrue);
      expect(src.topicId, 'topic-1');
      expect(src.summary, 'fake summary');
      expect(src.processingStatus, 'completed');
    });

    test('returns DUPLICATE failure when a matching source already exists',
        () async {
      final content = 'shared content';
      final existing = Source(
        id: 'existing',
        title: 'Old',
        type: SourceType.pdf,
        content: content,
        studentId: 's1',
        contentHash: sha256.convert(utf8.encode(content)).toString(),
      );
      final sourceRepo = FakeSourceRepository();
      await sourceRepo.create(existing);

      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(text: 't', extractionMethod: 'x'),
        ),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: sourceRepo,
        topicRepo: FakeTopicRepository([]),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: content,
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('DUPLICATE'));
    });
  });

  group('ContentPipeline.fetchAndScrapeUrl', () {
    test('delegates to the web scraper and returns the content', () async {
      final webScraper = FakeWebScraper(
        Result.success(ScrapedPage(
          content: 'scraped content',
          metadata: const PageMetadata(title: 'Scraped'),
        )),
      );
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(text: '', extractionMethod: 'x'),
        ),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FakeSourceRepository(),
        topicRepo: FakeTopicRepository([]),
        webScraper: webScraper,
      );

      final result = await pipeline.fetchAndScrapeUrl('https://example.com');

      expect(result.isSuccess, isTrue);
      expect(result.data, 'scraped content');
    });
  });
}
