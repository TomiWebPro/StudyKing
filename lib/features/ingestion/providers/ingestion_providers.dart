import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_config.dart';
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_pipeline.dart';
import 'package:studyking/core/providers/app_providers.dart' show localeProvider;
import 'package:studyking/core/providers/llm_providers.dart'
    show llmServiceProvider, llmTaskManagerProvider, llmUsageMeterProvider, modelRouterProvider, systemMonitorServiceProvider;
import 'package:studyking/core/providers/prep_budget_providers.dart'
    show prepBudgetSettingsProvider;
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/providers/ocr_provider.dart';
import 'package:studyking/features/ingestion/services/bulk_ingestion_service.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/page_metadata.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart' show lessonAgentServiceProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/flashcards/services/flashcard_generator.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';

final _ingestionProvidersLogger = const Logger('IngestionProviders');

final whisperAsrEngineProvider = Provider<AsrEngine>((ref) {
  final String? whisperApiKey;
  try {
    whisperApiKey = AppConstants.instance.secrets.whisperApiKey;
  } catch (e) {
    // Config is not initialized (e.g. providers exercised in
    // isolation by tests). Degrade to the no-op engine — the same
    // behavior as a missing API key — instead of breaking every
    // provider that transitively depends on this one.
    _ingestionProvidersLogger.w(
      'AppConstants not initialized; ASR engine disabled',
      e,
    );
    return NoopAsrEngine();
  }
  if (whisperApiKey != null && whisperApiKey.isNotEmpty) {
    return WhisperApiAsrEngine(apiKey: whisperApiKey);
  }
  return NoopAsrEngine();
});

final transcriptionExtractorProvider = Provider<TranscriptionExtractor>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final locale = ref.watch(localeProvider);
  // Transcription LLM fallback resolves through the model router so a
  // per-task `transcriptionModelId` (multimodal-capable) is honored
  // instead of always using the globally selected model.
  final modelId =
      ref.watch(modelRouterProvider).resolve(LlmTaskType.transcription);
  final asrEngine = ref.watch(whisperAsrEngineProvider);
  return TranscriptionExtractor(
    llmService: llmService,
    modelId: modelId,
    localeName: locale.languageCode,
    asrEngine: asrEngine,
  );
});

final transcriptionPipelineProvider = Provider<TranscriptionPipeline>((ref) {
  final extractor = ref.watch(transcriptionExtractorProvider);
  final asrEngine = ref.watch(whisperAsrEngineProvider);
  final llmService = ref.watch(llmServiceProvider);
  return TranscriptionPipeline(
    extractor: extractor,
    asrEngine: asrEngine,
    llmService: llmService,
  );
});

final documentExtractorProvider = Provider<DocumentExtractor>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final locale = ref.watch(localeProvider);
  // OCR/transcription extraction resolves through the model router so a
  // per-task `transcriptionModelId` is honored instead of always using
  // the globally selected model.
  final modelId =
      ref.watch(modelRouterProvider).resolve(LlmTaskType.transcription);
  final asrEngine = ref.watch(whisperAsrEngineProvider);
  final transcriptionPipeline = ref.watch(transcriptionPipelineProvider);
  final ocrMode = ref.watch(ocrModeProvider);
  return DocumentExtractor(
    llmService: llmService,
    modelId: modelId,
    localeName: locale.languageCode,
    ocrMode: ocrMode,
    asrEngine: asrEngine,
    transcriptionPipeline: transcriptionPipeline,
  );
});

final webScraperProvider = Provider<WebScraper>((ref) {
  return WebScraper(
    cache: HiveScrapeCache(ttl: const Duration(hours: 24)),
    politenessDelay: const Duration(seconds: 1),
  );
});

final ingestionSourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return SourceRepository();
});

final ingestionTopicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository();
});

final ingestionQuestionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository();
});

final flashcardGeneratorProvider = Provider<FlashcardGenerator>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  return FlashcardGenerator(
    llmService: llmService,
    flashcardRepository: flashcardRepo,
  );
});

final contentPipelineProvider = Provider<ContentPipeline>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final sourceRepository = ref.watch(ingestionSourceRepositoryProvider);
  final topicRepository = ref.watch(ingestionTopicRepositoryProvider);
  final questionRepository = ref.watch(ingestionQuestionRepositoryProvider);
  final documentExtractor = ref.watch(documentExtractorProvider);
  final webScraper = ref.watch(webScraperProvider);
  final locale = ref.watch(localeProvider);
  // The default document extractor (OCR/transcription) resolves through
  // the model router so the per-task `transcriptionModelId` is honored.
  // Classification/summarization/generation models are resolved per call
  // by the screens via `modelRouterProvider`.
  final transcriptionModelId =
      ref.watch(modelRouterProvider).resolve(LlmTaskType.transcription);
  return ContentPipeline(
    llmService: llmService,
    sourceRepository: sourceRepository,
    topicRepository: topicRepository,
    questionRepository: questionRepository,
    lessonAgentService: ref.watch(lessonAgentServiceProvider),
    flashcardGenerator: ref.watch(flashcardGeneratorProvider),
    documentExtractor: documentExtractor,
    webScraper: webScraper,
    transcriptionModelId: transcriptionModelId,
    localeName: locale.languageCode,
  );
});

/// Background queue for off-period ingestion and prep tasks
/// (Vision Next-Term §4.1/§4.3). Uses the same quiet-hours and CPU/battery
/// deferral predicates as the agent's [IdleExecutor], so bulk uploads
/// respect the student's "Prepare while I'm away" settings.
final idleExecutorProvider = Provider<IdleExecutor>((ref) {
  final taskManager = ref.watch(llmTaskManagerProvider);
  final systemMonitor = ref.watch(systemMonitorServiceProvider);
  final prepBudget = ref.watch(prepBudgetSettingsProvider);
  final usageMeter = ref.watch(llmUsageMeterProvider);
  final executor = IdleExecutor(
    llmTaskManager: taskManager,
    studentId: 'default',
    systemMonitor: systemMonitor,
    shouldDeferForQuietHours: (now) => prepBudget.shouldDeferForQuietHours(now),
    isPrepEnabledForSubject: (subjectId) =>
        prepBudget.isPrepEnabledForSubject(subjectId),
    usageMeter: usageMeter,
  );
  executor.startIdleMonitoring();
  ref.onDispose(executor.dispose);
  return executor;
});

/// Service that manages bulk ingestion of study materials through the
/// [IdleExecutor] background queue. The student can multi-select many files,
/// leave the upload screen, and the queue continues processing in the
/// background with per-file progress tracking and retry on transient errors.
final bulkIngestionServiceProvider =
    ChangeNotifierProvider<BulkIngestionService>((ref) {
  final service = BulkIngestionService(
    pipeline: ref.watch(contentPipelineProvider),
    idleExecutor: ref.watch(idleExecutorProvider),
  );
  return service;
});
