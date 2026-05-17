import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';

class _FakeLlmService extends LlmService {
  _FakeLlmService() : super(config: LlmConfiguration(provider: LlmProvider.openRouter, apiKey: 'test'));

  bool classifyShouldFail = false;
  bool questionGenShouldThrow = false;
  String classifyResult = 'Math';
  int classifyCallCount = 0;
  String summaryResult = 'Test summary';
  String questionResult = '';

  static const String defaultQuestions = '''[
    {"text": "Q1", "type": "singleChoice", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "explanation": "Exp1"},
    {"text": "Q2", "type": "singleChoice", "options": ["X", "Y", "Z", "W"], "correctAnswer": "X", "explanation": "Exp2"}
  ]''';

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    classifyCallCount++;
    if (feature == 'question_generation' && questionGenShouldThrow) {
      throw Exception('Question generation failed');
    }
    if (feature == 'content_classification') {
      if (classifyShouldFail) return Result.success('');
      return Result.success(classifyResult);
    }
    if (feature == 'content_summarization') {
      return Result.success(summaryResult);
    }
    if (feature == 'question_generation') {
      return Result.success(questionResult.isNotEmpty ? questionResult : defaultQuestions);
    }
    return Result.success('');
  }
}

class _FakeSourceRepository extends SourceRepository {
  final Map<String, Source> _storage = {};
  bool shouldThrow = false;
  int saveCallCount = 0;
  int failSaveAfter = 999;

  @override
  Future<void> init() async {}

  @override
  Future<void> create(Source source) async {
    if (shouldThrow) throw Exception('Simulated error');
    _storage[source.id] = source;
  }

  @override
  Future<void> save(String key, Source item) async {
    saveCallCount++;
    if (saveCallCount >= failSaveAfter) throw Exception('Save error');
    _storage[key] = item;
  }

  @override
  Future<Source?> get(String id) async => _storage[id];

  @override
  Future<List<Source>> getAll() async => _storage.values.toList();

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Source>> getByStudent(String studentId) async => [];

  @override
  Future<List<Source>> getBySubject(String subjectId) async => [];

  @override
  Future<List<Source>> getByTopic(String topicId) async => [];

  @override
  Future<List<Source>> getByType(String sourceType) async => [];

  @override
  Future<List<Source>> getByStatus(ProcessingStatus status) async => [];

  @override
  Future<List<Source>> getPending() async => [];

  @override
  Future<List<Source>> getFailed() async => [];

  @override
  Future<List<Source>> getCompleted() async => [];
}

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};
  bool _shouldThrowOnGetAll = false;

  @override
  Future<void> init() async {}

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  void clear() => _topics.clear();

  void throwOnGetAll() => _shouldThrowOnGetAll = true;

  @override
  Future<Topic?> get(String id) async => _topics[id];

  @override
  Future<List<Topic>> getAll() async {
    if (_shouldThrowOnGetAll) throw Exception('DB error');
    return _topics.values.toList();
  }
}

class _FakeQuestionRepository extends QuestionRepository {
  bool createShouldFail = false;

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Question question) async {
    if (createShouldFail) {
      return Result.failure('Create failed');
    }
    return Result.success(null);
  }
}

void main() {
  late _FakeSourceRepository mockSourceRepo;
  late _FakeLlmService mockLlmService;
  late _FakeTopicRepository mockTopicRepo;
  late _FakeQuestionRepository mockQuestionRepo;
  late ContentPipeline pipeline;

  setUp(() {
    mockSourceRepo = _FakeSourceRepository();
    mockLlmService = _FakeLlmService();
    mockTopicRepo = _FakeTopicRepository();
    mockQuestionRepo = _FakeQuestionRepository();
    mockLlmService.classifyShouldFail = false;
    mockLlmService.classifyResult = 'Math';
    mockLlmService.classifyCallCount = 0;
    mockLlmService.questionResult = '';
    mockTopicRepo.clear();
    pipeline = ContentPipeline(
      llmService: mockLlmService,
      sourceRepository: mockSourceRepo,
      topicRepository: mockTopicRepo,
      questionRepository: mockQuestionRepo,
      modelId: 'test-model',
    );
  });

  group('ContentPipeline.processUpload', () {
    test('saves source and returns success result with correct fields', () async {
      final result = await pipeline.processUpload(
        title: 'Test Title',
        content: 'Test content',
        type: SourceType.externalResource,
        studentId: 'student-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.title, 'Test Title');
      expect(result.data!.content, 'Test content');
      expect(result.data!.studentId, 'student-1');
      expect(result.data!.type, SourceType.externalResource);
      expect(result.data!.processingStatus, 'pending');
    });

    test('returns failure when source repository throws', () async {
      mockSourceRepo.shouldThrow = true;

      final result = await pipeline.processUpload(
        title: 'Title',
        content: 'Content',
        type: SourceType.pdf,
        studentId: 's1',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Simulated error'));
    });

    test('sets subjectId and sourceUrl when provided', () async {
      final result = await pipeline.processUpload(
        title: 'Math Notes',
        content: 'Math content',
        type: SourceType.textbook,
        studentId: 's1',
        subjectId: 'math-1',
        sourceUrl: 'https://example.com',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.subjectId, 'math-1');
      expect(result.data!.sourceUrl, 'https://example.com');
    });

    test('creates source with unique id', () async {
      final result1 = await pipeline.processUpload(
        title: 'First', content: 'A', type: SourceType.pdf, studentId: 's1',
      );
      final result2 = await pipeline.processUpload(
        title: 'Second', content: 'B', type: SourceType.pdf, studentId: 's1',
      );

      expect(result1.data!.id, isNot(result2.data!.id));
    });

    test('passes through topicId, syllabusId, and language when provided',
        () async {
      final result = await pipeline.processUpload(
        title: 'Biology Notes',
        content: 'Cell structure',
        type: SourceType.pdf,
        studentId: 's1',
        topicId: 'topic_bio',
        syllabusId: 'syllabus_1',
        language: 'en',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, 'topic_bio');
      expect(result.data!.syllabusId, 'syllabus_1');
      expect(result.data!.language, 'en');
    });
  });

  group('ContentPipeline.processFullPipeline', () {
    test('processes pipeline end-to-end with classification', () async {
      mockTopicRepo.addTopic(Topic(
        id: 'topic_math',
        subjectId: 'sub_math',
        title: 'Math',
        description: 'Mathematics',
        syllabusText: 'Math topics',
      ));

      final result = await pipeline.processFullPipeline(
        title: 'Math Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
        possibleTopics: ['Math', 'Physics'],
        generateQuestions: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.processingStatus, 'completed');
      expect(result.data!.summary, 'Test summary');
    });

    test('saves source completed status when pipeline succeeds', () async {
      final result = await pipeline.processFullPipeline(
        title: 'Notes',
        content: 'Content',
        type: SourceType.externalResource,
        studentId: 's1',
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.processingStatus, 'completed');
    });

    test('generates questions when generateQuestions is true', () async {
      final result = await pipeline.processFullPipeline(
        title: 'Notes',
        content: 'Content for questions',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
        possibleTopics: [],
        generateQuestions: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.generatedQuestionIds, isNotEmpty);
    });

    test('handles topic matching with case-insensitive comparison', () async {
      mockTopicRepo.addTopic(Topic(
        id: 'topic_math',
        subjectId: 'sub_math',
        title: 'MATH',
        description: 'Mathematics',
        syllabusText: 'Math topics',
      ));

      final result = await pipeline.processFullPipeline(
        title: 'Algebra Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
        possibleTopics: ['Math'],
        generateQuestions: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, 'topic_math');
    });

    test('handles classification failure gracefully', () async {
      mockLlmService.classifyShouldFail = true;

      final result = await pipeline.processFullPipeline(
        title: 'Notes',
        content: 'Content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
        possibleTopics: ['Math'],
        generateQuestions: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, isEmpty);
    });

    test('passes through subjectId and sourceUrl', () async {
      final result = await pipeline.processFullPipeline(
        title: 'Notes',
        content: 'Content',
        type: SourceType.textbook,
        studentId: 's1',
        modelId: 'model-1',
        subjectId: 'sub_math',
        sourceUrl: 'https://example.com',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.subjectId, 'sub_math');
      expect(result.data!.sourceUrl, 'https://example.com');
    });

    test('handles topic repository failure gracefully', () async {
      mockTopicRepo.throwOnGetAll();

      final result = await pipeline.processFullPipeline(
        title: 'Notes',
        content: 'Content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
        possibleTopics: ['Math'],
        generateQuestions: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, isEmpty);
    });

    test('sets extractionMethod on source', () async {
      final result = await pipeline.processFullPipeline(
        title: 'Notes',
        content: 'Some content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.extractionMethod, isNotEmpty);
    });

    test('skips invalid generated questions during validation', () async {
      mockLlmService.questionResult = '''[
        {"text": "Valid Q", "type": "singleChoice", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "explanation": "Good explanation"},
        {"text": "", "type": "singleChoice", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "explanation": "Bad - empty text"},
        {"text": "Few options", "type": "singleChoice", "options": ["A"], "correctAnswer": "A", "explanation": "Bad - only 1 option"},
        {"text": "No correct", "type": "singleChoice", "options": ["A", "B", "C", "D"], "correctAnswer": "", "explanation": "Bad - no correct answer"},
        {"text": "Wrong answer", "type": "singleChoice", "options": ["A", "B", "C", "D"], "correctAnswer": "Z", "explanation": "Bad - Z not in options"},
        {"text": "No expl", "type": "singleChoice", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "explanation": ""}
      ]''';

      final result = await pipeline.processFullPipeline(
        title: 'Validation Test',
        content: 'Test content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
        generateQuestions: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.generatedQuestionIds, hasLength(1));
    });

    test('preserves original source on pipeline failure', () async {
      mockSourceRepo.failSaveAfter = 1;

      final result = await pipeline.processFullPipeline(
        title: 'Fail Test',
        content: 'Content',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
      );

      expect(result.isFailure, isTrue);
    });

    test('reuses original source ID on mid-pipeline error', () async {
      mockLlmService.questionGenShouldThrow = true;

      final result = await pipeline.processFullPipeline(
        title: 'Mid Fail',
        content: 'Content for questions',
        type: SourceType.pdf,
        studentId: 's1',
        modelId: 'model-1',
        generateQuestions: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.processingStatus, 'completed');
      expect(result.data!.id, startsWith('src_'));
    });
  });
}
