import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

class _FakeLlmService extends LlmService {
  Result<String>? _nextResult;
  bool shouldThrow = false;

  _FakeLlmService() : super(
    config: LlmConfiguration(provider: LlmProvider.ollama, apiKey: 'test-key'),
  );

  void setResult(Result<String> result) => _nextResult = result;
  void setFailNext() => shouldThrow = true;

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
    if (shouldThrow) {
      throw Exception('LLM API error');
    }
    if (_nextResult != null) {
      final r = _nextResult!;
      _nextResult = null;
      return r;
    }
    return Result.success(jsonEncode([
      {'type': 'text', 'content': 'Introduction', 'order': 0},
      {'type': 'slide', 'content': 'Key concepts', 'order': 1},
    ]));
  }
}

class _FakeLessonRepository extends LessonRepository {
  final Map<String, Lesson> _storage = {};
  bool throwOnCreate = false;
  String? lastCreatedId;

  @override
  Future<Result<void>> create(Lesson lesson) async {
    if (throwOnCreate) return Result.failure('Create failed');
    _storage[lesson.id] = lesson;
    lastCreatedId = lesson.id;
    return Result.success(null);
  }

  @override
  Future<Result<Lesson?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<List<Lesson>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<List<Lesson>>> getBySubject(String subjectId) async {
    return Result.success(_storage.values.where((l) => l.subjectId == subjectId).toList());
  }

  @override
  Future<Result<List<Lesson>>> getByTopic(String topicId) async {
    return Result.success(_storage.values.where((l) => l.topicId == topicId).toList());
  }

  @override
  Future<Result<List<Lesson>>> getBySubjectAndTopic(
      String subjectId, String topicId) async {
    return Result.success(_storage.values
        .where((l) => l.subjectId == subjectId && l.topicId == topicId).toList());
  }

  @override
  Future<Result<void>> addBlock(LessonBlock block) async {
    return Result.success(null);
  }

  @override
  Future<Result<List<LessonBlock>>> getBlocksForLesson(String lessonId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<LessonBlock>>> getBlocksBySubject(String subjectId) async {
    return Result.success([]);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }
}

DatabaseService _dummyDatabase() {
  return DatabaseService(
    topicRepository: TopicRepository(),
    questionRepository: QuestionRepository(),
    attemptRepository: AttemptRepository(),
    lessonRepository: LessonRepository(),
    sessionRepository: SessionRepository(),
    subjectRepository: SubjectRepository(),
    conversationRepository: ConversationRepository(),
    tutorSessionRepository: TutorSessionRepository(),
  );
}

void main() {
  group('LessonAgentService', () {
    late _FakeLlmService fakeLlm;
    late _FakeLessonRepository fakeLessonRepo;
    late LessonAgentService service;

    setUp(() {
      fakeLlm = _FakeLlmService();
      fakeLessonRepo = _FakeLessonRepository();
      service = LessonAgentService(
        llmService: fakeLlm,
        modelId: 'test-model',
        lessonRepository: fakeLessonRepo,
        database: _dummyDatabase(),
      );
    });

    group('generateLesson', () {
      test('generates lesson from valid LLM JSON response', () async {
        final lesson = await service.generateLesson(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Algebra Basics',
          localeName: 'en',
        );

        expect(lesson, isNotNull);
        expect(lesson!.subjectId, 'sub-1');
        expect(lesson.topicId, 'topic-1');
        expect(lesson.title, 'Algebra Basics');
        expect(lesson.generatedBy, GeneratedBy.ai);
        expect(lesson.blocks.length, 2);
        expect(lesson.blocks[0].type, LessonBlockType.text);
        expect(lesson.blocks[0].content, 'Introduction');
        expect(lesson.blocks[1].type, LessonBlockType.slide);
        expect(lesson.blocks[1].content, 'Key concepts');
        expect(lesson.blocks[1].order, 1);
      });

      test('persists lesson in repository', () async {
        await service.generateLesson(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        expect(fakeLessonRepo.lastCreatedId, isNotNull);
        final saved = await fakeLessonRepo.get(fakeLessonRepo.lastCreatedId!);
        expect(saved.isSuccess, isTrue);
        expect(saved.data, isNotNull);
        expect(saved.data!.title, 'Algebra');
      });

      test('falls back to generic blocks when LLM returns failure', () async {
        fakeLlm.setResult(Result.failure('LLM error'));

        final lesson = await service.generateLesson(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Calculus',
          localeName: 'en',
        );

        expect(lesson, isNotNull);
        expect(lesson!.blocks.length, 2);
        expect(lesson.blocks[0].content, contains('Calculus'));
      });

      test('falls back when LLM returns empty data', () async {
        fakeLlm.setResult(Result.success('null'));

        final lesson = await service.generateLesson(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Physics',
          localeName: 'en',
        );

        expect(lesson, isNotNull);
        expect(lesson!.blocks.length, 1);
      });

      test('returns null when repository creation fails', () async {
        fakeLessonRepo.throwOnCreate = true;

        final lesson = await service.generateLesson(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Chemistry',
          localeName: 'en',
        );

        expect(lesson, isNull);
      });

      test('handles LLM service exception gracefully', () async {
        fakeLlm.setFailNext();

        final lesson = await service.generateLesson(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Biology',
          localeName: 'en',
        );

        expect(lesson, isNull);
      });
    });

    group('generateLessonFromSource', () {
      test('generates lesson from source content with valid LLM response', () async {
        fakeLlm.setResult(Result.success(jsonEncode([
          {'type': 'slide', 'content': 'Source-based slide', 'order': 0},
        ])));

        final lesson = await service.generateLessonFromSource(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'From Source',
          sourceContent: 'Chapter 1 content',
          localeName: 'en',
        );

        expect(lesson, isNotNull);
        expect(lesson!.blocks.length, 1);
        expect(lesson.blocks[0].content, 'Source-based slide');
      });

      test('returns null when LLM returns failure', () async {
        fakeLlm.setResult(Result.failure('LLM error'));

        final lesson = await service.generateLessonFromSource(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Failed Source',
          sourceContent: 'Some content',
          localeName: 'en',
        );

        expect(lesson, isNull);
      });

      test('returns null when repository creation fails', () async {
        fakeLlm.setResult(Result.success(jsonEncode([
          {'type': 'text', 'content': 'Content', 'order': 0},
        ])));
        fakeLessonRepo.throwOnCreate = true;

        final lesson = await service.generateLessonFromSource(
          subjectId: 'sub-1',
          topicId: 'topic-1',
          topicTitle: 'Repo Fail',
          sourceContent: 'Content',
          localeName: 'en',
        );

        expect(lesson, isNull);
      });
    });
  });
}
