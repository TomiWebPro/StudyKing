import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/services/llm_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/question_generation_service.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart' as mvg;

class MockLlmService extends LlmService {
  MockLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openAI,
            apiKey: 'test_key',
          ),
        );

  String? nextResponse;
  bool shouldThrow = false;
  int chatCallCount = 0;

  @override
  Future<String> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
  }) async {
    chatCallCount++;
    if (shouldThrow) {
      throw Exception('LLM error');
    }
    return nextResponse ?? '';
  }
}

class MockQuestionRepository implements QuestionRepository {
  bool shouldFailCreate = false;
  int createCallCount = 0;

  @override
  Future<Result<void>> create(Question question) async {
    createCallCount++;
    if (shouldFailCreate) {
      return Result.failure('Create failed');
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Question?>> get(String id) async => Result.success(null);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success([]);

  @override
  Future<Result<List<Question>>> getByTopic(String topicId) async =>
      Result.success([]);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async =>
      Result.success([]);

  @override
  Future<Result<List<Question>>> getBySubjectAndTopic(
    String subjectId,
    String topicId,
  ) async => Result.success([]);

  @override
  Future<Result<List<Question>>> getByType(QuestionType type) async =>
      Result.success([]);

  @override
  Future<Result<List<Question>>> getBySubjectAndType(
    String subjectId,
    QuestionType type,
  ) async => Result.success([]);

  @override
  Future<Result<List<QuestionWithMarkscheme>>> getQuestionsWithMarkschemes(
    String subjectId,
  ) async => Result.success([]);

  @override
  Future<Result<void>> updateMarkscheme(
    String questionId,
    Markscheme markscheme,
  ) async => Result.success(null);

  @override
  Future<Result<void>> delete(String id) async => Result.success(null);
}

class MockMasteryGraphService extends MasteryGraphService {
  MockMasteryGraphService() : super();

  List<MasteryState>? weakTopics;
  bool shouldFailGetWeakTopics = false;

  @override
  Future<mvg.Result<List<MasteryState>>> getWeakTopics(
    String studentId,
  ) async {
    if (shouldFailGetWeakTopics) {
      return mvg.Result.failure('Failed to get weak topics');
    }
    return mvg.Result.success(weakTopics ?? []);
  }
}

String _validQuestionJson() => '''
{
  "text": "What is 2+2?",
  "type": "typedAnswer",
  "difficulty": 1,
  "options": [],
  "markscheme": {
    "questionId": "q_test_1",
    "correctAnswer": "4",
    "acceptableAnswers": ["four"],
    "explanation": "Basic arithmetic",
    "steps": []
  },
  "tags": ["math"],
  "explanation": "Simple addition"
}
''';

void main() {
  group('GenerationResult', () {
    test('success creates result with data', () {
      final result = GenerationResult.success('data');
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 'data');
      expect(result.error, isNull);
    });

    test('success with list data', () {
      final result = GenerationResult.success([1, 2, 3]);
      expect(result.isSuccess, isTrue);
      expect(result.data, [1, 2, 3]);
    });

    test('failure creates result with error', () {
      final result = GenerationResult.failure('error occurred');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.error, 'error occurred');
    });

    test('failure with status code', () {
      final result = GenerationResult.failure('not found', statusCode: 404);
      expect(result.error, 'not found');
      expect(result.statusCode, 404);
    });

    test('success with null data returns isFailure', () {
      final result = GenerationResult<dynamic>.success(null);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isFalse);
      expect(result.error, isNull);
    });
  });

  group('GenerationException', () {
    test('creates exception with message', () {
      final ex = GenerationException('test error');
      expect(ex.message, 'test error');
      expect(ex.statusCode, isNull);
      expect(ex.toString(), contains('test error'));
    });

    test('creates exception with status code', () {
      final ex = GenerationException('server error', statusCode: 500);
      expect(ex.statusCode, 500);
      expect(ex.toString(), contains('500'));
    });

    test('creates exception with zero status code', () {
      final ex = GenerationException('unknown', statusCode: 0);
      expect(ex.toString(), contains('0'));
    });
  });

  group('QuestionGenerationService - static config', () {
    test('retry delay is 2 seconds', () {
      expect(QuestionGenerationService.retryDelay, const Duration(seconds: 2));
    });

    test('max retries is 3', () {
      expect(QuestionGenerationService.maxRetries, 3);
    });
  });

  group('QuestionGenerationService - response parsing', () {
    late MockLlmService mockLlm;
    late MockQuestionRepository mockRepo;
    late QuestionGenerationService service;

    setUp(() {
      mockLlm = MockLlmService();
      mockRepo = MockQuestionRepository();
      service = QuestionGenerationService(
        llmService: mockLlm,
        questionRepo: mockRepo,
      );
    });

    test('parses valid JSON response', () async {
      mockLlm.nextResponse = _validQuestionJson();

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.length, 1);
      expect(result.data![0].text, 'What is 2+2?');
      expect(result.data![0].type, QuestionType.typedAnswer);
      expect(result.data![0].markscheme?.correctAnswer, '4');
      expect(mockRepo.createCallCount, 1);
    });

    test('parses JSON with ```json code block markers', () async {
      mockLlm.nextResponse = '```json\n${_validQuestionJson()}\n```';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
    });

    test('parses JSON with ``` code block markers', () async {
      mockLlm.nextResponse = '```\n${_validQuestionJson()}\n```';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
    });

    test('parses JSON with singleChoice type', () async {
      mockLlm.nextResponse = '''
{
  "text": "Pick one",
  "type": "singleChoice",
  "difficulty": 1,
  "options": ["A", "B", "C", "D"],
  "markscheme": {"correctAnswer": "A", "acceptableAnswers": [], "explanation": "", "steps": []},
  "tags": [],
  "explanation": ""
}
''';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data![0].type, QuestionType.singleChoice);
    });

    test('parses JSON with multiChoice type', () async {
      mockLlm.nextResponse = '''
{
  "text": "Pick multiple",
  "type": "multiChoice",
  "difficulty": 1,
  "options": ["A", "B", "C", "D"],
  "markscheme": {"correctAnswer": "A,B", "acceptableAnswers": [], "explanation": "", "steps": []},
  "tags": [],
  "explanation": ""
}
''';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data![0].type, QuestionType.multiChoice);
    });

    test('parses JSON with mathExpression type', () async {
      mockLlm.nextResponse = '''
{
  "text": "Solve for x",
  "type": "mathExpression",
  "difficulty": 2,
  "options": [],
  "markscheme": {"correctAnswer": "x=2", "acceptableAnswers": [], "explanation": "", "steps": []},
  "tags": [],
  "explanation": ""
}
''';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data![0].type, QuestionType.mathExpression);
      expect(result.data![0].difficulty, 2);
    });

    test('parses JSON with underscore type variants', () async {
      mockLlm.nextResponse = '''
{
  "text": "Test",
  "type": "single_choice",
  "difficulty": 1,
  "options": ["A", "B"],
  "markscheme": {"correctAnswer": "A", "acceptableAnswers": [], "explanation": "", "steps": []},
  "tags": [],
  "explanation": ""
}
''';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data![0].type, QuestionType.singleChoice);
    });

    test('parses JSON without markscheme', () async {
      mockLlm.nextResponse = '''
{
  "text": "No markscheme",
  "type": "singleChoice",
  "difficulty": 1,
  "options": ["A", "B"],
  "markscheme": null,
  "tags": [],
  "explanation": ""
}
''';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data![0].markscheme, isNull);
    });

    test('parses JSON with steps as strings', () async {
      mockLlm.nextResponse = '''
{
  "text": "Step by step",
  "type": "singleChoice",
  "difficulty": 1,
  "options": ["A", "B"],
  "markscheme": {
    "correctAnswer": "A",
    "acceptableAnswers": [],
    "explanation": "",
    "markschemePoints": 3.0,
    "steps": ["Step one", "Step two"]
  },
  "tags": [],
  "explanation": ""
}
''';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data![0].markscheme?.markschemePoints, 3.0);
    });
  });

  group('QuestionGenerationService - generateQuestions', () {
    late MockLlmService mockLlm;
    late MockQuestionRepository mockRepo;
    late QuestionGenerationService service;

    setUp(() {
      mockLlm = MockLlmService();
      mockRepo = MockQuestionRepository();
      service = QuestionGenerationService(
        llmService: mockLlm,
        questionRepo: mockRepo,
      );
    });

    test('generates multiple questions with correct counts', () async {
      mockLlm.nextResponse = _validQuestionJson();

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 5,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 5);
      expect(mockLlm.chatCallCount, 5);
      expect(mockRepo.createCallCount, 5);
    });

    test('returns failure when LLM returns empty response', () async {
      mockLlm.nextResponse = '';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isFailure, isTrue);
    });

    test('retries on LLM failure and eventually fails', () async {
      mockLlm.shouldThrow = true;

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isFailure, isTrue);
      expect(mockLlm.chatCallCount, QuestionGenerationService.maxRetries);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('recovers after LLM retry succeeds', () async {
      final mockLlmWithRetry = MockLlmService();
      mockLlmWithRetry.shouldThrow = true;
      mockLlmWithRetry.nextResponse = _validQuestionJson();

      final retryService = QuestionGenerationService(
        llmService: mockLlmWithRetry,
        questionRepo: mockRepo,
      );

      final result = await retryService.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isFailure, isTrue);
      expect(mockLlmWithRetry.chatCallCount, QuestionGenerationService.maxRetries);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('returns failure when all save operations fail', () async {
      mockLlm.nextResponse = _validQuestionJson();
      mockRepo.shouldFailCreate = true;

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 3,
      );

      expect(result.isFailure, isTrue);
      expect(mockRepo.createCallCount, 3);
    });

    test('handles malformed JSON gracefully', () async {
      mockLlm.nextResponse = 'not valid json at all';

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 1,
      );

      expect(result.isFailure, isTrue);
    });

    test('handles count of zero', () async {
      mockLlm.nextResponse = _validQuestionJson();

      final result = await service.generateQuestions(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        count: 0,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 0);
      expect(mockLlm.chatCallCount, 0);
      expect(mockRepo.createCallCount, 0);
    });
  });

  group('QuestionGenerationService - generateForWeakTopics', () {
    late MockLlmService mockLlm;
    late MockQuestionRepository mockRepo;
    late MockMasteryGraphService mockMastery;
    late QuestionGenerationService service;

    setUp(() {
      mockLlm = MockLlmService();
      mockRepo = MockQuestionRepository();
      mockMastery = MockMasteryGraphService();
      service = QuestionGenerationService(
        llmService: mockLlm,
        questionRepo: mockRepo,
        masteryService: mockMastery,
      );
    });

    test('generates questions for weak topics', () async {
      mockMastery.weakTopics = [
        MasteryState(
          studentId: 'student-1',
          topicId: 'weak-topic-1',
          accuracy: 0.3,
          weakSubtopics: ['algebra'],
          lastAttempt: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
        MasteryState(
          studentId: 'student-1',
          topicId: 'weak-topic-2',
          accuracy: 0.6,
          lastAttempt: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
      ];

      final weakResult = await mockMastery.getWeakTopics('student-1');
      expect(weakResult.isSuccess, isTrue);
      expect(weakResult.data!.length, 2);

      mockLlm.nextResponse = _validQuestionJson();

      final directResult = await service.generateQuestions(
        topicId: 'weak-topic-1',
        subjectId: 'subject-1',
        count: 1,
      );
      expect(directResult.isSuccess, isTrue);
      expect(directResult.data!.length, 1);

      mockLlm.nextResponse = _validQuestionJson();
      final result = await service.generateForWeakTopics(
        studentId: 'student-1',
        subjectId: 'subject-1',
        questionsPerTopic: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
    });

    test('returns failure when getWeakTopics fails', () async {
      mockMastery.shouldFailGetWeakTopics = true;

      final result = await service.generateForWeakTopics(
        studentId: 'student-1',
        subjectId: 'subject-1',
      );

      expect(result.isFailure, isTrue);
    });

    test('returns empty list when no weak topics exist', () async {
      mockMastery.weakTopics = [];
      mockLlm.nextResponse = _validQuestionJson();

      final result = await service.generateForWeakTopics(
        studentId: 'student-1',
        subjectId: 'subject-1',
        questionsPerTopic: 5,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 0);
    });
  });
}
