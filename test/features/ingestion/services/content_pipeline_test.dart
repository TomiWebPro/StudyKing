import 'dart:async' show TimeoutException;
import 'dart:convert' show utf8;
import 'package:crypto/crypto.dart' show sha256;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
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

class ThrowingDocumentExtractor extends DocumentExtractor {
  ThrowingDocumentExtractor()
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
    throw TimeoutException('timed out');
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
  Future<Result<String>> generateConsolidatedSummary({
    required List<SourceChunk> chunks,
    required String modelId,
    String? existingTopicTitle,
  }) async {
    summarizeCalled = true;
    return Result.success('fake summary');
  }

  @override
  List<SourceChunk> splitIntoChunks(String text) => [
        SourceChunk(chunkIndex: 0, text: text),
      ];
}

class FakeSourceRepository extends SourceRepository {
  final Map<String, Source> _store = {};
  String? lastCreatedId;

  FakeSourceRepository() : super();

  @override
  Future<Result<void>> create(Source source) async {
    lastCreatedId = source.id;
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

class FailingCreateSourceRepository extends FakeSourceRepository {
  @override
  Future<Result<void>> create(Source source) async =>
      Result.failure('simulated create failure');
}

class FailingSaveSourceRepository extends FakeSourceRepository {
  @override
  Future<Result<void>> save(String key, Source item) async =>
      Result.failure('simulated save failure');
}

/// Fails only the final "completed"-status save so the completion gate can be
/// exercised in isolation; every intermediate stage save still succeeds.
class FailCompletedSaveSourceRepository extends FakeSourceRepository {
  @override
  Future<Result<void>> save(String key, Source item) async {
    if (item.processingStatus == ProcessingStatus.completed.name) {
      return Result.failure('simulated final save failure');
    }
    return super.save(key, item);
  }
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
  required DocumentExtractor docExtractor,
  required FakeChunkedContentProcessor chunked,
  required FakeSourceRepository sourceRepo,
  required FakeTopicRepository topicRepo,
  required FakeWebScraper webScraper,
  String localeName = 'en',
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
    localeName: localeName,
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

    test('returns failure when source creation fails', () async {
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(text: '', extractionMethod: 'x'),
        ),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FailingCreateSourceRepository(),
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

      expect(result.isFailure, isTrue);
      expect(result.error, 'simulated create failure');
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

    test('returns failure when the initial source creation fails', () async {
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(
          ExtractionResult(text: 't', extractionMethod: 'x'),
        ),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FailingCreateSourceRepository(),
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
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, 'simulated create failure');
    });

    test('returns failure when a stage save fails', () async {
      final sourceRepo = FailingSaveSourceRepository();
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(
          ExtractionResult(text: 'extracted', extractionMethod: 'x'),
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
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, 'simulated save failure');
      // The created source must not be reported as completed when a save fails.
      final stored = sourceRepo.getStored(sourceRepo.lastCreatedId!);
      expect(stored, isNotNull);
      expect(stored!.processingStatus, ProcessingStatus.pending.name);
    });

    test('returns failure when the final completed save fails', () async {
      final sourceRepo = FailCompletedSaveSourceRepository();
      final docExtractor = FakeDocumentExtractor(ExtractionResult(
        text: 'extracted text',
        extractionMethod: 'pdf_text_direct',
        chunks: [
          SourceChunk(chunkIndex: 0, text: 'chunk one text'),
          SourceChunk(chunkIndex: 1, text: 'chunk two text'),
        ],
      ));
      final topicRepo = FakeTopicRepository([
        Topic(
          id: 'topic-1',
          subjectId: '',
          title: 'Biology',
          description: '',
          syllabusText: '',
        ),
      ]);
      final chunked = FakeChunkedContentProcessor(
        ClassificationResult(topicId: 'Biology', confidence: 1.0),
      );
      final pipeline = buildPipeline(
        docExtractor: docExtractor,
        chunked: chunked,
        sourceRepo: sourceRepo,
        topicRepo: topicRepo,
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
        possibleTopics: ['Biology'],
      );

      expect(result.isFailure, isTrue);
      expect(result.error, 'simulated final save failure');
      // Every intermediate stage save succeeded, but the source must not carry a
      // 'completed' status because the final save failed.
      final stored = sourceRepo.getStored(sourceRepo.lastCreatedId!);
      expect(stored, isNotNull);
      expect(stored!.processingStatus, isNot(ProcessingStatus.completed.name));
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

  group('ContentPipeline localization', () {
    ContentPipeline pipelineFor({String localeName = 'en', DocumentExtractor? docExtractor}) {
      return buildPipeline(
        docExtractor: docExtractor ??
            FakeDocumentExtractor(ExtractionResult(text: '', extractionMethod: 'x')),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FakeSourceRepository(),
        topicRepo: FakeTopicRepository([]),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
        localeName: localeName,
      );
    }

    test('userFriendlyError returns localized English messages', () {
      final pipeline = pipelineFor();
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(pipeline.userFriendlyError(TimeoutException('timed out')),
          l10n.pipelineErrorTimeout);
      expect(pipeline.userFriendlyError(Exception('429 Too many requests')),
          l10n.pipelineErrorRateLimited);
      expect(pipeline.userFriendlyError(Exception('401 API key invalid')),
          l10n.pipelineErrorInvalidApiKey);
      expect(pipeline.userFriendlyError(Exception('404 Model not found')),
          l10n.pipelineErrorModelNotFound);
      expect(pipeline.userFriendlyError(FormatException('JSON parse error')),
          l10n.pipelineErrorMalformedResponse);
      expect(pipeline.userFriendlyError(Exception('Could not read pdf')),
          l10n.pipelineErrorUnreadableFile);
      // Unknown errors pass through unchanged.
      expect(pipeline.userFriendlyError(Exception('boom')), 'Exception: boom');
    });

    test('userFriendlyError returns localized Spanish messages', () {
      final pipeline = pipelineFor(localeName: 'es');
      final l10n = lookupAppLocalizations(const Locale('es'));

      expect(pipeline.userFriendlyError(TimeoutException('timed out')),
          l10n.pipelineErrorTimeout);
      expect(pipeline.userFriendlyError(Exception('429 Too many requests')),
          l10n.pipelineErrorRateLimited);
      expect(pipeline.userFriendlyError(Exception('401 API key invalid')),
          l10n.pipelineErrorInvalidApiKey);
      expect(pipeline.userFriendlyError(Exception('404 Model not found')),
          l10n.pipelineErrorModelNotFound);
      expect(pipeline.userFriendlyError(FormatException('JSON parse error')),
          l10n.pipelineErrorMalformedResponse);
      expect(pipeline.userFriendlyError(Exception('Could not read pdf')),
          l10n.pipelineErrorUnreadableFile);
    });

    test('reports localized progress stage descriptions', () async {
      final stages = <String>[];
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'extracted text',
          extractionMethod: 'pdf_text_direct',
        )),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FakeSourceRepository(),
        topicRepo: FakeTopicRepository([]),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
      );

      await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
        generateQuestions: true,
        onProgress: (status, description) => stages.add(description),
      );

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(stages, contains(l10n.pipelineStageExtracting));
      expect(stages, contains(l10n.pipelineStageSummarizing));
      expect(stages, contains(l10n.pipelineStageGeneratingQuestions));
      expect(stages, contains(l10n.pipelineStageValidatingQuestions));
      expect(stages, contains(l10n.pipelineStageComplete));
    });

    test('reports Spanish progress stage descriptions for the es locale',
        () async {
      final stages = <String>[];
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'extracted text',
          extractionMethod: 'pdf_text_direct',
        )),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FakeSourceRepository(),
        topicRepo: FakeTopicRepository([]),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
        localeName: 'es',
      );

      await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
        generateQuestions: true,
        onProgress: (status, description) => stages.add(description),
      );

      expect(stages, contains('Extrayendo texto del contenido...'));
      expect(stages, contains('Generando resumen...'));
      expect(stages, contains('Generando preguntas del contenido...'));
      expect(stages, contains('Proceso completado'));
      // English-only stage descriptions no longer leak through.
      expect(stages, isNot(contains('Extracting text from content...')));
      expect(stages, isNot(contains('Generating summary...')));
      expect(stages, isNot(contains('Pipeline complete')));
    });

    test('persists and returns the localized failure message', () async {
      final sourceRepo = FakeSourceRepository();
      final pipeline = buildPipeline(
        docExtractor: ThrowingDocumentExtractor(),
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
        localeName: 'es',
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'm',
      );

      final l10n = lookupAppLocalizations(const Locale('es'));
      expect(result.isFailure, isTrue);
      expect(result.error, l10n.pipelineErrorTimeout);
      final stored = sourceRepo.getStored(sourceRepo.lastCreatedId!);
      expect(stored, isNotNull);
      expect(stored!.processingStatus, ProcessingStatus.failed.name);
      expect(stored.errorMessage, l10n.pipelineErrorTimeout);
    });
  });
}
