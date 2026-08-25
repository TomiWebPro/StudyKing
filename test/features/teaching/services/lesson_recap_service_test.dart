import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';
import 'package:studyking/features/teaching/services/lesson_recap_service.dart';

class FakeLlmService extends LlmService {
  FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
        );

  String chatResponse = '{}';
  bool shouldFail = false;

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
    if (shouldFail) return Result.failure('Simulated LLM failure');
    return Result.success(chatResponse);
  }
}

class FakeLessonRecapRepository extends LessonRecapRepository {
  final Map<String, LessonRecapModel> _store = {};
  bool open = true;

  @override
  bool get isOpen => open;

  @override
  Future<void> openBox(String boxName) async => open = true;

  @override
  Future<Result<void>> saveRecap(LessonRecapModel recap) async {
    _store[recap.id] = recap;
    return Result.success(null);
  }

  @override
  Future<Result<LessonRecapModel?>> getBySession(String sessionId) async {
    for (final r in _store.values) {
      if (r.sessionId == sessionId) return Result.success(r);
    }
    return Result.success(null);
  }

  @override
  Future<Result<LessonRecapModel?>> getByLesson(String lessonId) async {
    for (final r in _store.values) {
      if (r.lessonId == lessonId) return Result.success(r);
    }
    return Result.success(null);
  }

  @override
  Future<Result<List<LessonRecapModel>>> getStudentRecaps(
      String studentId) async {
    final list = _store.values
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return Result.success(list);
  }
}

TutorSession makeSession({
  String id = 'sess-1',
  String lessonId = 'L1',
  int asked = 4,
  int correct = 3,
}) {
  return TutorSession(
    id: id,
    studentId: 'student-1',
    subjectId: 'subj-1',
    topicId: 'topic-1',
    topicTitle: 'Cell Division',
    startTime: DateTime(2026, 1, 1),
    questionsAsked: asked,
    questionsCorrect: correct,
    confidenceRating: 4,
    topicsCovered: ['mitosis', 'meiosis'],
    totalMessages: 10,
    lessonId: lessonId,
  );
}

List<ConversationMessage> makeMessages() => [
      ConversationMessage(
        id: 'm1',
        sessionId: 'sess-1',
        role: MessageRole.tutor,
        type: MessageType.text,
        content: 'Today we will learn about cell division.',
        timestamp: DateTime(2026, 1, 1),
      ),
      ConversationMessage(
        id: 'm2',
        sessionId: 'sess-1',
        role: MessageRole.student,
        type: MessageType.text,
        content: 'What is the difference between mitosis and meiosis?',
        timestamp: DateTime(2026, 1, 1),
      ),
    ];

void main() {
  group('LessonRecapService', () {
    late FakeLlmService llm;
    late FakeLessonRecapRepository repo;
    late LessonRecapService service;

    setUp(() {
      llm = FakeLlmService();
      repo = FakeLessonRecapRepository();
      service = LessonRecapService(
        llmService: llm,
        modelId: 'model-1',
        repository: repo,
        localeName: 'en',
      );
    });

    test('generateAndStoreRecap parses LLM JSON into structured recap',
        () async {
      llm.chatResponse = '''
      {
        "topicsCovered": ["mitosis", "meiosis"],
        "struggles": ["confused chromosome number"],
        "homework": ["draw a mitosis diagram"],
        "summary": "We explored cell division clearly."
      }
      ''';
      final result = await service.generateAndStoreRecap(
        session: makeSession(),
        messages: makeMessages(),
      );

      expect(result.isSuccess, isTrue);
      final recap = result.data!;
      expect(recap.sessionId, 'sess-1');
      expect(recap.lessonId, 'L1');
      expect(recap.topicsCovered, contains('mitosis'));
      expect(recap.struggles, contains('confused chromosome number'));
      expect(recap.homework, contains('draw a mitosis diagram'));
      expect(recap.summary, 'We explored cell division clearly.');
      expect(recap.accuracy, closeTo(0.75, 0.001));
      expect(recap.correctCount, 3);
      expect(recap.questionCount, 4);
      expect(recap.participationMessages, 10);

      // persisted so it is viewable from history
      final stored = await repo.getBySession('sess-1');
      expect(stored.data?.id, recap.id);
    });

    test('generateAndStoreRecap falls back to derived recap when LLM fails',
        () async {
      llm.shouldFail = true;
      final result = await service.generateAndStoreRecap(
        session: makeSession(asked: 2, correct: 1),
        messages: makeMessages(),
      );

      expect(result.isSuccess, isTrue);
      final recap = result.data!;
      expect(recap.summary, contains('Cell Division'));
      expect(recap.accuracy, closeTo(0.5, 0.001));
      // persisted despite the LLM failure
      final stored = await repo.getBySession('sess-1');
      expect(stored.data, isNotNull);
    });

    test('generateAndStoreRecap falls back when LLM returns no JSON',
        () async {
      llm.chatResponse = 'Sorry, I could not summarize that.';
      final result = await service.generateAndStoreRecap(
        session: makeSession(),
        messages: makeMessages(),
      );

      expect(result.isSuccess, isTrue);
      final recap = result.data!;
      // derived recap uses session topics when LLM gives nothing usable
      expect(recap.topicsCovered, contains('mitosis'));
      expect(recap.homework, isEmpty);
    });

    test('getRecapForLesson returns the stored recap by lessonId', () async {
      llm.chatResponse = '{"summary":"ok"}';
      await service.generateAndStoreRecap(
        session: makeSession(),
        messages: makeMessages(),
      );
      final byLesson = await service.getRecapForLesson('L1');
      expect(byLesson.isSuccess, isTrue);
      expect(byLesson.data?.lessonId, 'L1');
    });
  });
}
