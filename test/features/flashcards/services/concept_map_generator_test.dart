import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';
import 'package:studyking/features/flashcards/services/concept_map_generator.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'test',
          ),
        );

  Result<String>? forcedResult;
  String? response;
  String? lastMessage;
  String? lastFeature;
  String? lastSystemPrompt;

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
    lastMessage = message;
    lastFeature = feature;
    lastSystemPrompt = systemPrompt;
    if (forcedResult != null) return forcedResult!;
    return Result.success(response ?? '');
  }
}

class _FakeConceptMapRepository extends ConceptMapRepository {
  final Map<String, ConceptMap> stored = {};

  @override
  Future<Result<void>> create(ConceptMap map) async {
    stored[map.id] = map;
    return Result.success(null);
  }
}

void main() {
  group('ConceptMapGenerator', () {
    late _FakeLlmService llm;
    late _FakeConceptMapRepository repo;
    late ConceptMapGenerator generator;

    setUp(() {
      llm = _FakeLlmService();
      repo = _FakeConceptMapRepository();
      generator = ConceptMapGenerator(llmService: llm, repository: repo);
    });

    test('happy path parses response and saves concept map', () async {
      llm.response = '''
      {
        "nodes": [
          {"id": "n1", "label": "Cell"},
          {"id": "n2", "label": "Nucleus", "description": "Contains DNA"}
        ],
        "edges": [
          {"fromId": "n2", "toId": "n1", "relationship": "is part of"}
        ]
      }
      ''';
      final result = await generator.generateConceptMap(
        content: 'Cells are the basic unit of life.',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isSuccess, isTrue);
      final map = result.data!;
      expect(map.nodes.length, 2);
      expect(map.edges.length, 1);
      expect(map.sourceId, 's1');
      expect(map.title, 'Concept Map: Biology');
      expect(repo.stored.containsKey(map.id), isTrue);
      expect(llm.lastFeature, 'concept_map_generation');
    });

    test('propagates LLM failure', () async {
      llm.forcedResult = Result.failure('model unavailable');
      final result = await generator.generateConceptMap(
        content: 'x',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isFailure, isTrue);
      expect(result.error, 'model unavailable');
      expect(repo.stored, isEmpty);
    });

    test('returns failure when response cannot be parsed', () async {
      llm.response = 'this is not json';
      final result = await generator.generateConceptMap(
        content: 'x',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isFailure, isTrue);
      expect(result.error, contains('Failed to parse'));
    });

    test('returns failure when response has no nodes', () async {
      llm.response = '{"nodes": [], "edges": []}';
      final result = await generator.generateConceptMap(
        content: 'x',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isFailure, isTrue);
      expect(result.error, contains('Failed to parse'));
    });

    test('strips markdown code fences before parsing', () async {
      llm.response = '```json\n{"nodes": [{"id": "n1", "label": "A"}], "edges": []}\n```';
      final result = await generator.generateConceptMap(
        content: 'x',
        sourceId: 's1',
        topicId: 't1',
        subjectId: 'sub1',
        topicTitle: 'Biology',
        modelId: 'model-x',
      );
      expect(result.isSuccess, isTrue);
      expect(result.data!.nodes.length, 1);
    });
  });
}
