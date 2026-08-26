import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';

/// In-memory fake of [QuestionRepository] that bypasses Hive.
class FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> store = {};
  final List<Question> created = [];
  final List<String> savedSourceIds = [];

  FakeQuestionRepository() : super();

  @override
  Future<Result<void>> create(Question question) async {
    store[question.id] = question;
    created.add(question);
    return Result.success(null);
  }

  @override
  Future<Result<Question?>> get(String key) async {
    return Result.success(store[key]);
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    store[key] = item;
    savedSourceIds.add(key);
    return Result.success(null);
  }

  @override
  Future<Result<List<Question>>> getByVariantGroupId(String groupId) async {
    if (groupId.isEmpty) return Result.success(const []);
    return Result.success(
      store.values.where((q) => q.variantGroupId == groupId).toList(),
    );
  }

  @override
  Future<Result<List<Question>>> getVariantFamily(String questionId) async {
    final base = store[questionId];
    if (base == null) return Result.failure('Question_not_found: $questionId');
    final family = store.values.where((q) {
      if (q.id == questionId) return true;
      if (base.variantGroupId.isNotEmpty &&
          q.variantGroupId == base.variantGroupId) {
        return true;
      }
      return q.variantIds.contains(questionId) ||
          base.variantIds.contains(q.id);
    }).toList();
    return Result.success(family);
  }
}

/// Hand-written fake of [LlmService] that returns queued responses.
class FakeLlmService extends LlmService {
  final List<Result<String>> queuedResponses;
  int callCount = 0;
  final List<String> requestedMessages = [];

  FakeLlmService({this.queuedResponses = const []})
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.ollama,
            apiKey: 'k',
            model: 'm',
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
    requestedMessages.add(message);
    final response = queuedResponses[callCount];
    callCount++;
    return response;
  }
}

Question buildSourceQuestion({String id = 'q1'}) {
  return Question(
    id: id,
    text: 'What is 2 + 3?',
    type: QuestionType.singleChoice,
    difficulty: 1,
    subjectId: 'math',
    topicId: 'arithmetic',
    options: const ['4', '5', '6', '7'],
    markscheme: Markscheme(
      questionId: 'q1',
      correctAnswer: '5',
      explanation: '2 + 3 = 5',
    ),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

const String validVariantJson = '''
[
  {
    "text": "What is 3 + 4?",
    "options": ["6", "7", "8", "9"],
    "correctAnswer": "7",
    "explanation": "3 + 4 = 7"
  },
  {
    "text": "What is 5 + 1?",
    "options": ["5", "6", "7", "8"],
    "correctAnswer": "6",
    "explanation": "5 + 1 = 6"
  }
]
''';

void main() {
  group('QuestionVariantService.generateVariants', () {
    test('returns failure when no model is selected', () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService();
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: '',
      );

      final result = await service.generateVariants(buildSourceQuestion());

      expect(result.isFailure, isTrue);
      expect(llm.callCount, 0);
    });

    test('returns failure when LLM call fails', () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService(
        queuedResponses: [Result.failure('network error')],
      );
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      final result = await service.generateVariants(buildSourceQuestion());

      expect(result.isFailure, isTrue);
      expect(result.error, contains('network error'));
    });

    test('returns failure when LLM returns unparseable JSON', () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService(
        queuedResponses: [Result.success('not json at all')],
      );
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      final result = await service.generateVariants(buildSourceQuestion());

      expect(result.isFailure, isTrue);
    });

    test('persists variants and links them via variantIds', () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService(
        queuedResponses: [Result.success(validVariantJson)],
      );
      final source = buildSourceQuestion();
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      final result = await service.generateVariants(source, count: 2);

      expect(result.isSuccess, isTrue);
      final variants = result.data!;
      expect(variants.length, 2);

      // Each variant is stored and cross-linked to source + siblings.
      for (final v in variants) {
        expect(repo.store.containsKey(v.id), isTrue);
        expect(v.variantIds, contains(source.id));
      }
      // Source variantIds updated to include both new variants.
      expect(repo.store[source.id]!.variantIds, contains(variants[0].id));
      expect(repo.store[source.id]!.variantIds, contains(variants[1].id));
      // Source preserved.
      expect(repo.store[source.id]!.text, source.text);
    });

    test('variants preserve concept fields (type, difficulty, subject, topic)',
        () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService(
        queuedResponses: [Result.success(validVariantJson)],
      );
      final source = buildSourceQuestion();
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      final result = await service.generateVariants(source, count: 2);

      for (final v in result.data!) {
        expect(v.type, source.type);
        expect(v.difficulty, source.difficulty);
        expect(v.subjectId, source.subjectId);
        expect(v.topicId, source.topicId);
        expect(v.markscheme, isNotNull);
      }
    });
  });

  group('QuestionVariantService.selectVariantForRetry', () {
    test('returns the original question when it has no variants', () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService();
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      final result = await service.selectVariantForRetry(buildSourceQuestion());

      expect(result.isSuccess, isTrue);
      expect(result.data!.id, 'q1');
    });

    test('returns a linked variant when available', () async {
      final repo = FakeQuestionRepository();
      final variant = buildSourceQuestion(id: 'v1').copyWith(
        text: 'What is 3 + 4?',
      );
      repo.store[variant.id] = variant;
      final source = buildSourceQuestion().copyWith(variantIds: ['v1']);

      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: FakeLlmService(),
        modelId: 'model-x',
      );

      final result = await service.selectVariantForRetry(source);

      expect(result.isSuccess, isTrue);
      expect(result.data!.id, 'v1');
    });

    test('excludes the variant already attempted', () async {
      final repo = FakeQuestionRepository();
      final v1 = buildSourceQuestion(id: 'v1');
      final v2 = buildSourceQuestion(id: 'v2');
      repo.store[v1.id] = v1;
      repo.store[v2.id] = v2;
      final source =
          buildSourceQuestion().copyWith(variantIds: ['v1', 'v2']);

      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: FakeLlmService(),
        modelId: 'model-x',
      );

      final result = await service.selectVariantForRetry(
        source,
        excludeVariantId: 'v1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.id, 'v2');
    });

    test('falls back to original when linked variant is missing', () async {
      final repo = FakeQuestionRepository();
      final source = buildSourceQuestion().copyWith(variantIds: ['missing']);

      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: FakeLlmService(),
        modelId: 'model-x',
      );

      final result = await service.selectVariantForRetry(source);

      expect(result.isSuccess, isTrue);
      expect(result.data!.id, 'q1');
    });
  });

  group('QuestionVariantService variantGroupId + family', () {
    test('assigns a shared variantGroupId to source and variants', () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService(
        queuedResponses: [Result.success(validVariantJson)],
      );
      final source = buildSourceQuestion();
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      final result = await service.generateVariants(source, count: 2);

      expect(result.isSuccess, isTrue);
      final variants = result.data!;
      final groupId = repo.store[source.id]!.variantGroupId;
      expect(groupId, isNotEmpty);
      for (final v in variants) {
        expect(v.variantGroupId, groupId);
      }
      expect(repo.store[source.id]!.variantGroupId, groupId);
    });

    test('reuses an existing variantGroupId instead of generating a new one',
        () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService(
        queuedResponses: [Result.success(validVariantJson)],
      );
      final source = buildSourceQuestion().copyWith(variantGroupId: 'vq-existing');
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      final result = await service.generateVariants(source, count: 2);

      expect(result.isSuccess, isTrue);
      for (final v in result.data!) {
        expect(v.variantGroupId, 'vq-existing');
      }
    });

    test('getVariantFamily returns base plus generated variants', () async {
      final repo = FakeQuestionRepository();
      final llm = FakeLlmService(
        queuedResponses: [Result.success(validVariantJson)],
      );
      final source = buildSourceQuestion();
      final service = QuestionVariantService(
        questionRepo: repo,
        llmService: llm,
        modelId: 'model-x',
      );

      await service.generateVariants(source, count: 2);
      final familyResult = await service.getVariantFamily(source);

      expect(familyResult.isSuccess, isTrue);
      // base + 2 variants
      expect(familyResult.data!.length, 3);
      expect(
        familyResult.data!.map((q) => q.id),
        contains(source.id),
      );
    });
  });
}

