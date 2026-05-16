import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/ingestion/providers/ingestion_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';

void main() {
  group('ingestionProviders', () {
    group('documentExtractorProvider', () {
      test('creates a DocumentExtractor', () {
        final container = ProviderContainer(
          overrides: [
            llmServiceProvider.overrideWithValue(
              LlmService(
                config: const LlmConfiguration(
                  provider: LlmProvider.openRouter,
                  apiKey: 'test-key',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final extractor = container.read(documentExtractorProvider);
        expect(extractor, isA<DocumentExtractor>());
      });

      test('passes llmService to DocumentExtractor', () {
        final fakeService = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            llmServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final extractor = container.read(documentExtractorProvider);
        expect(extractor, isA<DocumentExtractor>());
      });

      test('can be overridden with custom DocumentExtractor', () {
        final fakeExtractor = DocumentExtractor();
        final container = ProviderContainer(
          overrides: [
            documentExtractorProvider.overrideWithValue(fakeExtractor),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(documentExtractorProvider);
        expect(result, same(fakeExtractor));
      });
    });

    group('webScraperProvider', () {
      test('creates a WebScraper', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final scraper = container.read(webScraperProvider);
        expect(scraper, isA<WebScraper>());
      });

      test('can be overridden', () {
        final fakeScraper = WebScraper();
        final container = ProviderContainer(
          overrides: [
            webScraperProvider.overrideWithValue(fakeScraper),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(webScraperProvider);
        expect(result, same(fakeScraper));
      });

      test('returns the same instance across reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(webScraperProvider);
        final b = container.read(webScraperProvider);
        expect(a, same(b));
      });
    });

    group('ingestionSourceRepositoryProvider', () {
      test('creates a SourceRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(ingestionSourceRepositoryProvider);
        expect(repo, isA<SourceRepository>());
      });

      test('can be overridden', () {
        final fakeRepo = SourceRepository();
        final container = ProviderContainer(
          overrides: [
            ingestionSourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(ingestionSourceRepositoryProvider);
        expect(result, same(fakeRepo));
      });
    });

    group('ingestionTopicRepositoryProvider', () {
      test('creates a TopicRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(ingestionTopicRepositoryProvider);
        expect(repo, isA<TopicRepository>());
      });

      test('can be overridden', () {
        final fakeRepo = TopicRepository();
        final container = ProviderContainer(
          overrides: [
            ingestionTopicRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(ingestionTopicRepositoryProvider);
        expect(result, same(fakeRepo));
      });
    });

    group('ingestionQuestionRepositoryProvider', () {
      test('creates a QuestionRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(ingestionQuestionRepositoryProvider);
        expect(repo, isA<QuestionRepository>());
      });

      test('can be overridden', () {
        final fakeRepo = QuestionRepository();
        final container = ProviderContainer(
          overrides: [
            ingestionQuestionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(ingestionQuestionRepositoryProvider);
        expect(result, same(fakeRepo));
      });
    });

    group('contentPipelineProvider', () {
      test('creates a ContentPipeline', () {
        final container = ProviderContainer(
          overrides: [
            llmServiceProvider.overrideWithValue(
              LlmService(
                config: const LlmConfiguration(
                  provider: LlmProvider.openRouter,
                  apiKey: 'test-key',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final pipeline = container.read(contentPipelineProvider);
        expect(pipeline, isA<ContentPipeline>());
      });

      test('can be overridden', () {
        final fakePipeline = ContentPipeline(
          llmService: LlmService(
            config: const LlmConfiguration(
              provider: LlmProvider.openRouter,
              apiKey: 'test-key',
            ),
          ),
          sourceRepository: SourceRepository(),
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
        );
        final container = ProviderContainer(
          overrides: [
            contentPipelineProvider.overrideWithValue(fakePipeline),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(contentPipelineProvider);
        expect(result, same(fakePipeline));
      });

      test('is wired to sub-providers', () {
        final fakeSourceRepo = SourceRepository();
        final fakePipeline = ContentPipeline(
          llmService: LlmService(
            config: const LlmConfiguration(
              provider: LlmProvider.openRouter,
              apiKey: 'test-key',
            ),
          ),
          sourceRepository: fakeSourceRepo,
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
        );
        final container = ProviderContainer(
          overrides: [
            contentPipelineProvider.overrideWithValue(fakePipeline),
            ingestionSourceRepositoryProvider.overrideWithValue(fakeSourceRepo),
          ],
        );
        addTearDown(container.dispose);

        final pipeline = container.read(contentPipelineProvider);
        expect(pipeline, isA<ContentPipeline>());
      });

      test('all providers resolve without throwing', () {
        final container = ProviderContainer(
          overrides: [
            llmServiceProvider.overrideWithValue(
              LlmService(
                config: const LlmConfiguration(
                  provider: LlmProvider.openRouter,
                  apiKey: 'test-key',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(documentExtractorProvider), isA<DocumentExtractor>());
        expect(container.read(webScraperProvider), isA<WebScraper>());
        expect(container.read(ingestionSourceRepositoryProvider), isA<SourceRepository>());
        expect(container.read(ingestionTopicRepositoryProvider), isA<TopicRepository>());
        expect(container.read(ingestionQuestionRepositoryProvider), isA<QuestionRepository>());
        expect(container.read(contentPipelineProvider), isA<ContentPipeline>());
      });
    });
  });
}
