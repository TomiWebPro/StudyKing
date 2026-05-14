import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/source_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
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

  @override
  Future<Result<String>> classifyTopic({
    required String content,
    required List<String> possibleTopics,
    required String modelId,
  }) async {
    return Result.success('Math');
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
  @override
  Future<void> init() async {}

  @override
  Future<List<Topic>> getAll() async => [];
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
      expect(result.error, contains('Failed to save source'));
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
      final result2 = await pipeline.processUpload(
        title: 'Second', content: 'B', type: SourceType.pdf, studentId: 's1',
      );

      expect(result1.data!.id, isNot(result2.data!.id));
    });
  });

  group('ContentPipeline.extractQuestionsFromSource', () {
    test('returns result from ingestion service', () async {
      final result = await pipeline.extractQuestionsFromSource(
        content: 'What is 2+2?',
        modelId: 'gpt-4',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });
  });

  group('ContentPipeline.generateSummary', () {
    test('returns summary from ingestion service', () async {
      final result = await pipeline.generateSummary(
        content: 'Long text content',
        topicName: 'Algebra',
        modelId: 'gpt-4',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 'Summary');
    });
  });
}
