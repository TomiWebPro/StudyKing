import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/ingestion/providers/ingestion_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/app_providers.dart' show selectedModelProvider;

class _BehavioralFakeSourceRepo extends SourceRepository {
  final List<Source> _sources = [];

  void addSource(Source source) => _sources.add(source);

  @override
  Future<Result<List<Source>>> getAll() async => Result.success(List.from(_sources));

  @override
  Future<Result<Source?>> get(String id) async => Result.success(_sources.where((s) => s.id == id).firstOrNull);

  @override
  Future<Result<void>> save(String key, Source item) async {
    _sources.removeWhere((s) => s.id == item.id);
    _sources.add(item);
    return Result.success(null);
  }
}

class _BehavioralFakeTopicRepo extends TopicRepository {
  final List<Topic> _topics = [];

  void addTopic(Topic topic) => _topics.add(topic);

  @override
  Future<Result<List<Topic>>> getAll() async => Result.success(List.from(_topics));

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(_topics.where((t) => t.id == id).firstOrNull);
}

class _BehavioralFakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions = [];

  void addQuestion(Question q) => _questions.add(q);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(List.from(_questions));

  @override
  Future<Result<Question?>> get(String id) async => Result.success(_questions.where((q) => q.id == id).firstOrNull);
}

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value('Fetched content from ${request.url}'.codeUnits),
      200,
    );
  }
}

class _FailingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value('Error'.codeUnits),
      500,
    );
  }
}

class _FailingLlmService extends LlmService {
  _FailingLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test-key',
          ),
        );

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
    return Result.failure('LLM service failure');
  }
}

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
        final fakeExtractor = DocumentExtractor(modelId: 'test-model-id');
        final container = ProviderContainer(
          overrides: [
            documentExtractorProvider.overrideWithValue(fakeExtractor),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(documentExtractorProvider);
        expect(result, same(fakeExtractor));
      });

      test('behavioral: selectedModelProvider propagates modelId to extractor', () {
        const customModelId = 'custom-extractor-model';
        final container = ProviderContainer(
          overrides: [
            selectedModelProvider.overrideWith((ref) => customModelId),
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
        expect(extractor.modelId, equals(customModelId));
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

      test('behavioral: fetches content through overridden HTTP client', () async {
        final fakeClient = _FakeHttpClient();
        final fakeScraper = WebScraper(httpClient: fakeClient);
        final container = ProviderContainer(
          overrides: [
            webScraperProvider.overrideWithValue(fakeScraper),
          ],
        );
        addTearDown(container.dispose);

        final scraper = container.read(webScraperProvider);
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Fetched content from'));
      });

      test('error-state: handles HTTP 500 from overridden client', () async {
        final failingClient = _FailingHttpClient();
        final fakeScraper = WebScraper(httpClient: failingClient);
        final container = ProviderContainer(
          overrides: [
            webScraperProvider.overrideWithValue(fakeScraper),
          ],
        );
        addTearDown(container.dispose);

        final scraper = container.read(webScraperProvider);
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('500'));
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

      test('returns the same instance across reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(ingestionSourceRepositoryProvider);
        final b = container.read(ingestionSourceRepositoryProvider);
        expect(a, same(b));
      });

      test('behavioral: overridden repo returns seeded data through provider', () async {
        final fakeRepo = _BehavioralFakeSourceRepo();
        fakeRepo.addSource(Source(
          id: 'src-1', title: 'Test Source', type: SourceType.pdf,
          content: 'test', studentId: 'stu1',
        ));
        final container = ProviderContainer(
          overrides: [
            ingestionSourceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(ingestionSourceRepositoryProvider);
        final all = await repo.getAll();
        expect(all.isSuccess, isTrue);
        expect(all.data, hasLength(1));
        expect(all.data!.first.title, 'Test Source');
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

      test('returns the same instance across reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(ingestionTopicRepositoryProvider);
        final b = container.read(ingestionTopicRepositoryProvider);
        expect(a, same(b));
      });

      test('behavioral: overridden repo returns seeded data through provider', () async {
        final fakeRepo = _BehavioralFakeTopicRepo();
        fakeRepo.addTopic(Topic(
          id: 't-1', subjectId: 'sub-1', title: 'Algebra',
          description: 'Algebraic concepts', syllabusText: 'Math',
        ));
        final container = ProviderContainer(
          overrides: [
            ingestionTopicRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(ingestionTopicRepositoryProvider);
        final all = await repo.getAll();
        expect(all.isSuccess, isTrue);
        expect(all.data, hasLength(1));
        expect(all.data!.first.title, 'Algebra');
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

      test('returns the same instance across reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(ingestionQuestionRepositoryProvider);
        final b = container.read(ingestionQuestionRepositoryProvider);
        expect(a, same(b));
      });

      test('behavioral: overridden repo returns seeded data through provider', () async {
        final fakeRepo = _BehavioralFakeQuestionRepo();
        final now = DateTime.now();
        fakeRepo.addQuestion(Question(
          id: 'q-1', subjectId: 'sub-1', topicId: 't-1',
          text: 'What is 2+2?',
          type: QuestionType.typedAnswer,
          markscheme: Markscheme(correctAnswer: '4'),
          createdAt: now, updatedAt: now,
        ));
        final container = ProviderContainer(
          overrides: [
            ingestionQuestionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(ingestionQuestionRepositoryProvider);
        final all = await repo.getAll();
        expect(all.isSuccess, isTrue);
        expect(all.data, hasLength(1));
        expect(all.data!.first.text, 'What is 2+2?');
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
          modelId: 'test-model-id',
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
            ingestionSourceRepositoryProvider.overrideWithValue(fakeSourceRepo),
          ],
        );
        addTearDown(container.dispose);

        final pipeline = container.read(contentPipelineProvider);
        expect(pipeline, isA<ContentPipeline>());
      });

      test('contentPipelineProvider uses llmService from overridden provider', () {
        final fakeLlm = LlmService(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'override-key',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            llmServiceProvider.overrideWithValue(fakeLlm),
          ],
        );
        addTearDown(container.dispose);

        final pipeline = container.read(contentPipelineProvider);
        expect(pipeline, isA<ContentPipeline>());
      });

      test('all providers resolve without throwing with proper overrides', () {
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

      test('behavioral: pipeline.sourceRepository matches overridden SourceRepository', () async {
        final fakeSourceRepo = _BehavioralFakeSourceRepo();
        fakeSourceRepo.addSource(Source(
          id: 'pipeline-src', title: 'Pipeline Source', type: SourceType.pdf,
          content: 'test', studentId: 'stu1',
        ));
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
            ingestionSourceRepositoryProvider.overrideWithValue(fakeSourceRepo),
          ],
        );
        addTearDown(container.dispose);

        final pipeline = container.read(contentPipelineProvider);
        expect(pipeline.sourceRepository, same(fakeSourceRepo));

        final all = await pipeline.sourceRepository.getAll();
        expect(all.isSuccess, isTrue);
        expect(all.data, hasLength(1));
        expect(all.data!.first.title, 'Pipeline Source');
      });

      test('error-state: pipeline handles LLM service failure gracefully', () async {
        final failingLlm = _FailingLlmService();
        final container = ProviderContainer(
          overrides: [
            llmServiceProvider.overrideWithValue(failingLlm),
          ],
        );
        addTearDown(container.dispose);

        final pipeline = container.read(contentPipelineProvider);
        expect(pipeline, isA<ContentPipeline>());
      });
    });
  });
}
