import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/pdf_ingestion_service.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';

class _MockSourceRepository extends SourceRepository {
  Source? lastCreated;
  bool shouldThrow = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> create(Source source) async {
    if (shouldThrow) throw Exception('Simulated error');
    lastCreated = source;
  }

  @override
  Future<Source?> get(String id) async => null;

  @override
  Future<List<Source>> getAll() async => [];

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
}

class _MockPdfIngestionService extends PdfIngestionService {
  _MockPdfIngestionService() : super(apiKey: 'test-key');

  bool classifyShouldFail = false;
  String classifyResult = 'Math';
  int classifyCallCount = 0;

  @override
  Future<Result<String>> classifyTopic({
    required String content,
    required List<String> possibleTopics,
    required String modelId,
  }) async {
    classifyCallCount++;
    if (classifyShouldFail) {
      return Result.failure('Classification failed');
    }
    return Result.success(classifyResult);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> extractQuestions(
    String content,
    String modelId,
  ) async {
    return Result.success([]);
  }

  @override
  Future<Result<String>> generateSummary(
    String content,
    String topicName,
    String modelId,
  ) async {
    return Result.success('Summary');
  }
}

class _MockTopicRepository extends TopicRepository {
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

void main() {
  late _MockSourceRepository mockSourceRepo;
  late _MockPdfIngestionService mockIngestion;
  late _MockTopicRepository mockTopicRepo;
  late ContentPipeline pipeline;

  setUp(() {
    mockSourceRepo = _MockSourceRepository();
    mockIngestion = _MockPdfIngestionService();
    mockTopicRepo = _MockTopicRepository();
    mockIngestion.classifyShouldFail = false;
    mockIngestion.classifyResult = 'Math';
    mockIngestion.classifyCallCount = 0;
    mockTopicRepo.clear();
    pipeline = ContentPipeline(
      ingestionService: mockIngestion,
      sourceRepository: mockSourceRepo,
      topicRepository: mockTopicRepo,
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

    test('creates source with unique id based on timestamp', () async {
      final result1 = await pipeline.processUpload(
        title: 'First', content: 'A', type: SourceType.pdf, studentId: 's1',
      );
      await Future.delayed(const Duration(milliseconds: 2));
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

  group('ContentPipeline.processAndClassify', () {
    test('calls classifyTopic on ingestion service', () async {
      await pipeline.processAndClassify(
        title: 'Math Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['Math', 'Physics'],
        modelId: 'model-1',
      );

      expect(mockIngestion.classifyCallCount, 1);
    });

    test('saves source with topic id when classification matches existing topic',
        () async {
      mockTopicRepo.addTopic(Topic(
        id: 'topic_math',
        subjectId: 'sub_math',
        title: 'Math',
        description: 'Mathematics',
        syllabusText: 'Math topics',
      ));

      final result = await pipeline.processAndClassify(
        title: 'Algebra Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['Math', 'Physics'],
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, 'topic_math');
    });

    test('saves source with empty topic id when classification fails', () async {
      mockIngestion.classifyShouldFail = true;

      final result = await pipeline.processAndClassify(
        title: 'Algebra Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['Math', 'Physics'],
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, isEmpty);
    });

    test('saves source with empty topic id when matched topic title not found',
        () async {
      mockIngestion.classifyResult = 'UnknownTopic';

      final result = await pipeline.processAndClassify(
        title: 'Algebra Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['Math', 'Physics'],
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, isEmpty);
    });

    test('passes through subjectId and sourceUrl to the created source',
        () async {
      mockTopicRepo.addTopic(Topic(
        id: 'topic_math',
        subjectId: 'sub_math',
        title: 'Math',
        description: 'Mathematics',
        syllabusText: 'Math topics',
      ));

      final result = await pipeline.processAndClassify(
        title: 'Algebra Notes',
        content: 'Algebra content',
        type: SourceType.textbook,
        studentId: 's1',
        possibleTopics: ['Math'],
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

      final result = await pipeline.processAndClassify(
        title: 'Algebra Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['Math'],
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, isEmpty);
    });

    test('matches topic with case-insensitive comparison', () async {
      mockTopicRepo.addTopic(Topic(
        id: 'topic_math',
        subjectId: 'sub_math',
        title: 'MATH',
        description: 'Mathematics',
        syllabusText: 'Math topics',
      ));

      final result = await pipeline.processAndClassify(
        title: 'Algebra Notes',
        content: 'Algebra content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['Math'],
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, 'topic_math');
    });

    test('matches topic by substring/contains', () async {
      mockTopicRepo.addTopic(Topic(
        id: 'topic_adv_math',
        subjectId: 'sub_math',
        title: 'Advanced Mathematics',
        description: 'Advanced math topics',
        syllabusText: 'Calculus, Algebra',
      ));

      final result = await pipeline.processAndClassify(
        title: 'Calc Notes',
        content: 'Calculus content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['Math'],
        modelId: 'model-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.topicId, 'topic_adv_math');
    });

    test('passes through language to the created source', () async {
      final result = await pipeline.processAndClassify(
        title: 'French Notes',
        content: 'French content',
        type: SourceType.pdf,
        studentId: 's1',
        possibleTopics: ['French'],
        modelId: 'model-1',
        language: 'fr',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.language, 'fr');
    });
  });

}
