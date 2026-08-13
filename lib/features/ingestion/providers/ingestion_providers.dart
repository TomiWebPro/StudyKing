import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_config.dart';
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/data/extraction/transcription_pipeline.dart';
import 'package:studyking/core/providers/app_providers.dart' show localeProvider, selectedModelProvider;
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart' show lessonAgentServiceProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/flashcards/services/flashcard_generator.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';

final whisperAsrEngineProvider = Provider<AsrEngine>((ref) {
  final whisperApiKey = AppConstants.instance.secrets.whisperApiKey;
  if (whisperApiKey != null && whisperApiKey.isNotEmpty) {
    return WhisperApiAsrEngine(apiKey: whisperApiKey);
  }
  return NoopAsrEngine();
});

final transcriptionExtractorProvider = Provider<TranscriptionExtractor>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final locale = ref.watch(localeProvider);
  final modelId = ref.watch(selectedModelProvider);
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
  final modelId = ref.watch(selectedModelProvider);
  final asrEngine = ref.watch(whisperAsrEngineProvider);
  final transcriptionPipeline = ref.watch(transcriptionPipelineProvider);
  return DocumentExtractor(
    llmService: llmService,
    modelId: modelId,
    localeName: locale.languageCode,
    asrEngine: asrEngine,
    transcriptionPipeline: transcriptionPipeline,
  );
});

final webScraperProvider = Provider<WebScraper>((ref) {
  return WebScraper();
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
  final modelId = ref.watch(selectedModelProvider);
  return ContentPipeline(
    llmService: llmService,
    sourceRepository: sourceRepository,
    topicRepository: topicRepository,
    questionRepository: questionRepository,
    lessonAgentService: ref.watch(lessonAgentServiceProvider),
    flashcardGenerator: ref.watch(flashcardGeneratorProvider),
    documentExtractor: documentExtractor,
    webScraper: webScraper,
    modelId: modelId,
    localeName: locale.languageCode,
  );
});
