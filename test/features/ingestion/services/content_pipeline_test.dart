import 'dart:async' show TimeoutException;
import 'dart:convert' show utf8, jsonDecode, jsonEncode;
import 'dart:io' show Directory;
import 'package:crypto/crypto.dart' show sha256;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:studyking/features/subjects/data/adapters/subject_adapter.dart';
import 'package:studyking/features/subjects/data/adapters/topic_adapter.dart';

class FakeLlmService extends LlmService {
  final String response;

  FakeLlmService([this.response = 'llm-response'])
      : super(config: const LlmConfiguration(
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
    return Result.success(response);
  }
}

/// Hand-written fake that records the model ID and feature of every
/// chat call so tests can assert per-task model routing.
class ModelCapturingLlmService extends FakeLlmService {
  final List<String> capturedModelIds = [];
  final List<String> capturedFeatures = [];

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
    capturedModelIds.add(modelId);
    capturedFeatures.add(feature);
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

/// Variant of [FakeChunkedContentProcessor] that reports a non-zero
/// [failedChunkCount] after [generateQuestionsFromChunks] runs, so the
/// pipeline's partial-failure surfacing can be exercised.
class PartialFailureChunkedProcessor extends FakeChunkedContentProcessor {
  final int failureCount;

  PartialFailureChunkedProcessor(
    super.classificationResult,
    this.failureCount,
  );

  @override
  Future<List<ChunkQuestionResult>> generateQuestionsFromChunks({
    required List<SourceChunk> chunks,
    required String modelId,
    required QuestionParser questionParser,
  }) async {
    failedChunkCount = failureCount;
    return [];
  }
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

/// TopicRepository whose writes always fail, to verify the pipeline does
/// not link or return topic ids that were never persisted.
class FailingCreateTopicRepository extends FakeTopicRepository {
  FailingCreateTopicRepository() : super([]);

  @override
  Future<Result<void>> create(Topic topic) async =>
      Result.failure('simulated topic create failure');
}

class FakeQuestionRepository extends QuestionRepository {
  FakeQuestionRepository() : super();
  @override
  Future<Result<void>> create(Question question) async => Result.success(null);
  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}

/// QuestionRepository whose deletes always fail, to verify the
/// pipeline propagates stale-question deletion failures instead of
/// silently keeping the old questions linked to the source.
class FailingDeleteQuestionRepository extends FakeQuestionRepository {
  final List<String> deletedKeys = [];

  @override
  Future<Result<void>> delete(String key) async {
    deletedKeys.add(key);
    return Result.failure('simulated question delete failure');
  }
}

/// QuestionRepository that records every deleted key so tests can
/// assert stale questions are removed before regeneration.
class RecordingQuestionRepository extends FakeQuestionRepository {
  final List<String> deletedKeys = [];

  @override
  Future<Result<void>> delete(String key) async {
    deletedKeys.add(key);
    return super.delete(key);
  }
}

/// QuestionRepository that records every created question so tests can
/// assert how many questions were actually persisted to the bank.
class CountingQuestionRepository extends FakeQuestionRepository {
  final List<Question> createdQuestions = [];

  @override
  Future<Result<void>> create(Question question) async {
    createdQuestions.add(question);
    return super.create(question);
  }
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
  QuestionRepository? questionRepository,
  String localeName = 'en',
}) {
  return ContentPipeline(
    llmService: FakeLlmService(),
    sourceRepository: sourceRepo,
    topicRepository: topicRepo,
    questionRepository: questionRepository ?? FakeQuestionRepository(),
    documentExtractor: docExtractor,
    webScraper: webScraper,
    chunkedProcessor: chunked,
    transcriptionModelId: 'm',
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
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

    test('routes per-task models to classification, summarization and generation', () async {
      final fakeLlm = ModelCapturingLlmService();
      final docExtractor = FakeDocumentExtractor(ExtractionResult(
        text: 'extracted text',
        extractionMethod: 'pdf_text_direct',
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
      final pipeline = ContentPipeline(
        llmService: fakeLlm,
        sourceRepository: FakeSourceRepository(),
        topicRepository: topicRepo,
        questionRepository: FakeQuestionRepository(),
        documentExtractor: docExtractor,
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
        chunkedProcessor: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        transcriptionModelId: 'transcription-model',
        localeName: 'en',
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        classificationModelId: 'classification-model',
        summarizationModelId: 'summarization-model',
        generationModelId: 'generation-model',
        possibleTopics: ['Biology'],
        generateQuestions: true,
      );

      expect(result.isSuccess, isTrue);

      // All pipeline LLM calls must be attributed to the 'pdf_ingestion' prep
      // feature so fromFeature maps them to LlmTaskType.background (prep bucket)
      // instead of classification/summarization/generation (live bucket).
      expect(fakeLlm.capturedFeatures, everyElement('pdf_ingestion'));

      // Each pipeline stage must call the LLM with its own per-task model
      // instead of one global model. Since all calls share the same feature,
      // verify via the ordered model ID sequence.
      expect(
        fakeLlm.capturedModelIds,
        equals([
          'classification-model',
          'summarization-model',
          'generation-model',
        ]),
      );
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
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

    test('returns failure when stale question deletion fails', () async {
      final questionRepo = FailingDeleteQuestionRepository();
      final sourceRepo = FakeSourceRepository();
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'extracted text',
          extractionMethod: 'pdf_text_direct',
        )),
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
        questionRepository: questionRepo,
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
        generateQuestions: true,
        oldQuestionIds: ['q-old-1', 'q-old-2'],
      );

      expect(result.isFailure, isTrue);
      expect(result.error, 'simulated question delete failure');
      // Deletion aborts on the first failed stale question.
      expect(questionRepo.deletedKeys, ['q-old-1']);
      // The source must not be reported as completed when the
      // stale-question cleanup fails.
      final stored = sourceRepo.getStored(sourceRepo.lastCreatedId!);
      expect(stored, isNotNull);
      expect(stored!.processingStatus, isNot(ProcessingStatus.completed.name));
    });

    test('deletes stale questions before regenerating', () async {
      final questionRepo = RecordingQuestionRepository();
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
        questionRepository: questionRepo,
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: 'some content',
        type: SourceType.pdf,
        studentId: 's1',
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
        generateQuestions: true,
        oldQuestionIds: ['q-old-1'],
      );

      expect(result.isSuccess, isTrue);
      expect(questionRepo.deletedKeys, ['q-old-1']);
      expect(result.data!.processingStatus, ProcessingStatus.completed.name);
    });

    test('surfaces partial chunk failures instead of silently completing',
        () async {
      final sourceRepo = FakeSourceRepository();
      final chunked = PartialFailureChunkedProcessor(
        ClassificationResult(topicId: '', confidence: 0),
        3,
      );
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'extracted text',
          extractionMethod: 'pdf_text_direct',
          chunks: [
            SourceChunk(chunkIndex: 0, text: 'chunk one text'),
            SourceChunk(chunkIndex: 1, text: 'chunk two text'),
          ],
        )),
        chunked: chunked,
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
        generateQuestions: true,
      );

      expect(result.isSuccess, isTrue);
      final src = result.data!;
      // Pipeline still completes (partial results generated) but the
      // failure must be surfaced — never silently swallowed.
      expect(src.processingStatus, ProcessingStatus.completed.name);
      expect(src.errorMessage, contains('3 chunk(s) failed'));
      final stored = sourceRepo.getStored(src.id)!;
      final meta = jsonDecode(stored.extractionMeta);
      expect(meta['failedChunkCount'], 3);
      expect(stored.errorMessage, contains('3 chunk(s) failed'));
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('DUPLICATE'));
    });

    test('clamps dense-page questions to per-chunk cap in single-chunk path',
        () async {
      // The dense-page scenario: one chunk = whole source (single-chunk path),
      // and the LLM dumps far more questions than the per-chunk cap (K=8).
      final questionRepo = CountingQuestionRepository();
      final pipeline = ContentPipeline(
        llmService: FakeLlmService(_questionBankJson(200)),
        sourceRepository: FakeSourceRepository(),
        topicRepository: FakeTopicRepository([]),
        questionRepository: questionRepo,
        documentExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'dense page content',
          extractionMethod: 'pdf_text_direct',
        )),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
        chunkedProcessor: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        transcriptionModelId: 'm',
        localeName: 'en',
      );

      final result = await pipeline.processFullPipeline(
        title: 'T',
        content: 'dense page content',
        type: SourceType.pdf,
        studentId: 's1',
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
        generateQuestions: true,
      );

      expect(result.isSuccess, isTrue);
      // Per-chunk cap (K=8) must bound the bank even when the LLM dumps 200.
      expect(
        result.data!.generatedQuestionIds.length,
        ChunkedContentProcessor.maxQuestionsPerChunk,
      );
      expect(
        questionRepo.createdQuestions,
        hasLength(ChunkedContentProcessor.maxQuestionsPerChunk),
      );
    });
  });

  group('ContentPipeline topic auto-creation failures', () {
    late Directory hiveDir;

    // The topic helpers instantiate a real SubjectRepository inline, so
    // Hive must be initialized (with adapters) for its init() to succeed.
    // Otherwise the pre-fix code would also fall back to '' via its
    // catch block and the phantom-topic-id regression could not be
    // distinguished from the fix.
    setUpAll(() async {
      Hive.registerAdapter(SubjectAdapter());
      Hive.registerAdapter(TopicAdapter());
      hiveDir = await Directory.systemTemp.createTemp(
        'content_pipeline_topic_test_',
      );
      Hive.init(hiveDir.path);
    });

    tearDownAll(() async {
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    test('leaves topicId empty when classified-topic auto-creation fails',
        () async {
      final chunks = [
        SourceChunk(chunkIndex: 0, text: 'chunk one text'),
        SourceChunk(chunkIndex: 1, text: 'chunk two text'),
      ];
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'extracted text',
          extractionMethod: 'pdf_text_direct',
          chunks: chunks,
        )),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: 'Biology', confidence: 1.0),
        ),
        sourceRepo: FakeSourceRepository(),
        topicRepo: FailingCreateTopicRepository(),
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
        subjectId: 's1',
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
        possibleTopics: ['Biology'],
      );

      expect(result.isSuccess, isTrue);
      // The failed topic create must not leave a dangling topic id on
      // the source (the classified topic did not exist and could not
      // be auto-created).
      expect(result.data!.topicId, isEmpty);
    });

    test('leaves topicId empty when single-chunk topic auto-creation fails',
        () async {
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'extracted text',
          extractionMethod: 'pdf_text_direct',
        )),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FakeSourceRepository(),
        topicRepo: FailingCreateTopicRepository(),
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
        subjectId: 's1',
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
        // The fake LLM answers "llm-response", which matches "llm".
        possibleTopics: ['llm'],
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, isEmpty);
    });

    test('leaves topicId empty when syllabus topic auto-creation fails',
        () async {
      final pipeline = buildPipeline(
        docExtractor: FakeDocumentExtractor(ExtractionResult(
          text: 'extracted text',
          extractionMethod: 'pdf_text_direct',
        )),
        chunked: FakeChunkedContentProcessor(
          ClassificationResult(topicId: '', confidence: 0),
        ),
        sourceRepo: FakeSourceRepository(),
        topicRepo: FailingCreateTopicRepository(),
        webScraper: FakeWebScraper(
          Result.success(ScrapedPage(
            content: '',
            metadata: const PageMetadata(),
          )),
        ),
      );

      final result = await pipeline.processFullPipeline(
        title: 'Syllabus T',
        content: 'some syllabus content',
        type: SourceType.syllabus,
        studentId: 's1',
        subjectId: 's1',
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
      );

      expect(result.isSuccess, isTrue);
      // The fake LLM response is not valid JSON, so the fallback split
      // yields one topic name whose creation fails; no id may be
      // returned for it.
      expect(result.data!.topicId, isEmpty);
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
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
        classificationModelId: 'm',
        summarizationModelId: 'm',
        generationModelId: 'm',
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

/// Builds a JSON array of [n] minimal, valid question objects for cap tests.
String _questionBankJson(int n) {
  final items = List.generate(n, (i) => jsonEncode({
        'text': 'Question $i',
        'type': 'singleChoice',
        'correctAnswer': 'a',
        'options': ['a', 'b'],
        'explanation': 'explanation $i',
      }));
  return '[${items.join(',')}]';
}
