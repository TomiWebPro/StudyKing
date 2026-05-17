import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart' show localeProvider, selectedModelProvider;
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';

final documentExtractorProvider = Provider<DocumentExtractor>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final locale = ref.watch(localeProvider);
  final modelId = ref.watch(selectedModelProvider);
  return DocumentExtractor(llmService: llmService, modelId: modelId, localeName: locale.languageCode);
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
    documentExtractor: documentExtractor,
    webScraper: webScraper,
    modelId: modelId,
    localeName: locale.languageCode,
  );
});
