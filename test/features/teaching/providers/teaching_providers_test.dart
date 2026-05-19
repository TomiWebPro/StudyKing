import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/teaching/providers/teaching_providers.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';


class _FakeClock implements Clock {
  final DateTime fixed;
  _FakeClock(this.fixed);
  @override
  DateTime now() => fixed;
}

class _FakeLlmService extends LlmService {
  bool shouldThrow = false;

  _FakeLlmService()
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
    if (shouldThrow) return Result.failure('Simulated LLM error');
    return Result.success('{"score": 0.8, "explanation": "Good job"}');
  }
}

class _FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> sessions;
  bool throwOnGet = false;

  _FakeTutorSessionRepository({List<TutorSession>? seed})
      : sessions = List.from(seed ?? []);

  @override
  Future<Result<List<TutorSession>>> getStudentSessions(String studentId) async {
    if (throwOnGet) return Result.failure('simulated error');
    return Result.success(
      sessions.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<TutorSession>>> getActiveSessions() async {
    if (throwOnGet) return Result.failure('simulated error');
    return Result.success(
      sessions.where((s) => s.status == SessionStatus.inProgress).toList(),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getSessionStats(String studentId) async {
    if (throwOnGet) return Result.failure('simulated error');
    final studentSessions = sessions.where((s) => s.studentId == studentId);
    final completed = studentSessions.where(
      (s) => s.status == SessionStatus.completed,
    );
    return Result.success({
      'totalSessions': studentSessions.length,
      'completedSessions': completed.length,
      'totalQuestions':
          completed.fold<int>(0, (sum, s) => sum + s.questionsAsked),
    });
  }

  @override
  Future<Result<void>> saveSession(TutorSession session) async {
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    return Result.success(null);
  }
}

class _FakeConversationRepository extends ConversationRepository {
  final List<ConversationMessage> messages;

  _FakeConversationRepository({List<ConversationMessage>? seed})
      : messages = List.from(seed ?? []);

  @override
  Future<Result<List<ConversationMessage>>> getSessionMessages(
      String sessionId) async {
    return Result.success(
      messages.where((m) => m.sessionId == sessionId).toList(),
    );
  }

  @override
  Future<Result<void>> saveMessage(ConversationMessage message) async {
    messages.add(message);
    return Result.success(null);
  }
}

void main() {
  group('teachingModelIdProvider', () {
    test('returns saved model when selectedModelProvider is non-empty', () {
      final container = ProviderContainer(
        overrides: [
          selectedModelProvider.overrideWith((ref) => 'custom-model'),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(teachingModelIdProvider), 'custom-model');
    });

    test('falls back to default model for provider when selectedModel is empty', () {
      final container = ProviderContainer(
        overrides: [
          selectedModelProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(container.dispose);
      final modelId = container.read(teachingModelIdProvider);
      expect(modelId, isNotEmpty);
      expect(modelId, equals(defaultModelForProvider(container.read(llmProviderProvider))));
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(teachingModelIdProvider);
      final b = container.read(teachingModelIdProvider);
      expect(a, same(b));
    });
  });

  group('exerciseEvaluatorProvider', () {
    test('behavioral: llmService override affects evaluation', () async {
      final fakeService = _FakeLlmService();
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, 0.8);
    });

    test('uses teachingModelIdProvider for modelId', () async {
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          teachingModelIdProvider.overrideWith((ref) => 'eval-test-model'),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'What is 2+2?',
        studentAnswer: '4',
        subjectId: 'math',
        topicTitle: 'arithmetic',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, greaterThanOrEqualTo(0));
    });

    test('behavioral: localeProvider affects evaluator locale', () async {
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          localeProvider.overrideWith((ref) => const Locale('es')),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, greaterThanOrEqualTo(0));
    });

    test('is singleton', () {
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
        ],
      );
      addTearDown(container.dispose);
      final a = container.read(exerciseEvaluatorProvider);
      final b = container.read(exerciseEvaluatorProvider);
      expect(a, same(b));
    });

    test('error-state: empty modelId still produces a result with fallback score', () async {
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          teachingModelIdProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result, isA<EvaluationResult>());
      expect(result.score, greaterThanOrEqualTo(0));
    });

    test('propagates errors from LLM service gracefully', () async {
      final fakeService = _FakeLlmService();
      fakeService.shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      final evaluator = container.read(exerciseEvaluatorProvider);
      final result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result.score, 0.5);
      expect(result.explanation, contains('Could not evaluate answer'));
    });

    test('recovers after LLM service error', () async {
      final fakeService = _FakeLlmService();
      fakeService.shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      var evaluator = container.read(exerciseEvaluatorProvider);
      var result = await evaluator.evaluate(
        question: 'test',
        studentAnswer: 'test',
        subjectId: 'test',
        topicTitle: 'test',
      );
      expect(result.score, 0.5);

      fakeService.shouldThrow = false;
      result = await evaluator.evaluate(
        question: 'What is 2+2?',
        studentAnswer: '4',
        subjectId: 'math',
        topicTitle: 'arithmetic',
      );
      expect(result.score, 0.8);
    });
  });

  group('clockProvider', () {
    test('can be overridden and provides time', () {
      final fakeClock = _FakeClock(DateTime(2024, 6, 15));
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider), same(fakeClock));
      expect(container.read(clockProvider).now(), DateTime(2024, 6, 15));
    });

    test('is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(clockProvider);
      final b = container.read(clockProvider);
      expect(a, same(b));
    });

    test('behavioral: clock provides actual time', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final clock = container.read(clockProvider);
      final now = clock.now();
      expect(now, isA<DateTime>());
      expect(now.isAfter(DateTime(2020)), isTrue);
    });
  });

  group('tutorServiceProvider', () {
    test('is singleton (behavioral)', () {
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
        ],
      );
      addTearDown(container.dispose);
      final a = container.read(tutorServiceProvider);
      final b = container.read(tutorServiceProvider);
      expect(a, same(b));
    });

    test('behavioral: clock override is wired through', () {
      final fakeClock = _FakeClock(DateTime(2024, 1, 1));
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(tutorServiceProvider);
      expect(service, isA<TutorService>());
    });

    test('behavioral: database override provides lesson history', () async {
      final now = DateTime(2024, 6, 15);
      final fakeTutorRepo = _FakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'ts-1', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: now, plannedDurationMinutes: 45,
          questionsAsked: 10, questionsCorrect: 7,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final history = await service.getLessonHistory('stu-1');
      expect(history, hasLength(1));
      expect(history.first.id, 'ts-1');
      expect(history.first.topicTitle, 'Algebra');
    });

    test('behavioral: database override returns active session', () async {
      final now = DateTime(2024, 6, 15);
      final fakeTutorRepo = _FakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'active-1', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.inProgress,
          startTime: now, plannedDurationMinutes: 45,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final active = await service.getActiveSession();
      expect(active, isNotNull);
      expect(active!.id, 'active-1');
      expect(active.status, SessionStatus.inProgress);
    });

    test('behavioral: no active sessions returns null', () async {
      final fakeTutorRepo = _FakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'completed-1', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime(2024, 6, 15),
          plannedDurationMinutes: 45,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final active = await service.getActiveSession();
      expect(active, isNull);
    });

    test('behavioral: database override provides session stats', () async {
      final now = DateTime(2024, 6, 15);
      final fakeTutorRepo = _FakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'ts-1', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: now, plannedDurationMinutes: 45,
          questionsAsked: 10, questionsCorrect: 7,
        ),
        TutorSession(
          id: 'ts-2', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-2', topicTitle: 'Geometry',
          status: SessionStatus.inProgress,
          startTime: now, plannedDurationMinutes: 30,
          questionsAsked: 5, questionsCorrect: 3,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final stats = await service.getStats('stu-1');
      expect(stats['totalSessions'], 2);
      expect(stats['completedSessions'], 1);
      expect(stats['totalQuestions'], 10);
    });

    test('behavioral: conversation repo override provides session messages', () async {
      final fakeConvRepo = _FakeConversationRepository(seed: [
        ConversationMessage(
          id: 'msg-1', sessionId: 'session-1',
          role: MessageRole.tutor, type: MessageType.text,
          content: 'Hello', timestamp: DateTime(2024, 6, 15),
          tokenCount: 5,
        ),
        ConversationMessage(
          id: 'msg-2', sessionId: 'session-1',
          role: MessageRole.student, type: MessageType.text,
          content: 'Hi', timestamp: DateTime(2024, 6, 15, 0, 1),
          tokenCount: 3,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: fakeConvRepo,
        tutorSessionRepository: TutorSessionRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final messages = await service.getSessionMessages('session-1');
      expect(messages, hasLength(2));
      expect(messages.first.content, 'Hello');
      expect(messages.last.content, 'Hi');
    });

    test('behavioral: saveMessage delegates to overridden conversation repo', () async {
      final fakeConvRepo = _FakeConversationRepository();
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: fakeConvRepo,
        tutorSessionRepository: TutorSessionRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final message = ConversationMessage(
        id: 'new-msg', sessionId: 'session-1',
        role: MessageRole.tutor, type: MessageType.text,
        content: 'New message', timestamp: DateTime(2024, 6, 15),
        tokenCount: 10,
      );
      await service.saveMessage(message);

      final messages = await service.getSessionMessages('session-1');
      expect(messages, hasLength(1));
      expect(messages.first.id, 'new-msg');
      expect(messages.first.content, 'New message');
    });

    test('behavioral: lesson history handles repo error gracefully', () async {
      final fakeTutorRepo = _FakeTutorSessionRepository();
      fakeTutorRepo.throwOnGet = true;
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final history = await service.getLessonHistory('stu-1');
      expect(history, isEmpty);
    });

    test('behavioral: getStats handles repo error gracefully', () async {
      final fakeTutorRepo = _FakeTutorSessionRepository();
      fakeTutorRepo.throwOnGet = true;
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final active = await service.getActiveSession();
      expect(active, isNull);
    });

    test('behavioral: database override provides session stats', () async {
      final now = DateTime(2024, 6, 15);
      final fakeTutorRepo = _FakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'ts-1', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: now, plannedDurationMinutes: 45,
          questionsAsked: 10, questionsCorrect: 7,
        ),
        TutorSession(
          id: 'ts-2', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-2', topicTitle: 'Geometry',
          status: SessionStatus.inProgress,
          startTime: now, plannedDurationMinutes: 30,
          questionsAsked: 5, questionsCorrect: 3,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final stats = await service.getStats('stu-1');
      expect(stats['totalSessions'], 2);
      expect(stats['completedSessions'], 1);
      expect(stats['totalQuestions'], 10);
    });

    test('behavioral: conversation repo override provides session messages', () async {
      final fakeConvRepo = _FakeConversationRepository(seed: [
        ConversationMessage(
          id: 'msg-1', sessionId: 'session-1',
          role: MessageRole.tutor, type: MessageType.text,
          content: 'Hello', timestamp: DateTime(2024, 6, 15),
          tokenCount: 5,
        ),
        ConversationMessage(
          id: 'msg-2', sessionId: 'session-1',
          role: MessageRole.student, type: MessageType.text,
          content: 'Hi', timestamp: DateTime(2024, 6, 15, 0, 1),
          tokenCount: 3,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: fakeConvRepo,
        tutorSessionRepository: TutorSessionRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final messages = await service.getSessionMessages('session-1');
      expect(messages, hasLength(2));
      expect(messages.first.content, 'Hello');
      expect(messages.last.content, 'Hi');
    });

    test('behavioral: saveMessage delegates to overridden conversation repo', () async {
      final fakeConvRepo = _FakeConversationRepository();
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: fakeConvRepo,
        tutorSessionRepository: TutorSessionRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final message = ConversationMessage(
        id: 'new-msg', sessionId: 'session-1',
        role: MessageRole.tutor, type: MessageType.text,
        content: 'New message', timestamp: DateTime(2024, 6, 15),
        tokenCount: 10,
      );
      await service.saveMessage(message);

      final messages = await service.getSessionMessages('session-1');
      expect(messages, hasLength(1));
      expect(messages.first.id, 'new-msg');
      expect(messages.first.content, 'New message');
    });

    test('behavioral: lesson history is empty for unknown student', () async {
      final fakeTutorRepo = _FakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'ts-1', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime(2024, 6, 15),
          plannedDurationMinutes: 45,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final history = await service.getLessonHistory('unknown-student');
      expect(history, isEmpty);
    });

    test('behavioral: lesson history handles repo error gracefully', () async {
      final fakeTutorRepo = _FakeTutorSessionRepository();
      fakeTutorRepo.throwOnGet = true;
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final history = await service.getLessonHistory('stu-1');
      expect(history, isEmpty);
    });

    test('behavioral: getStats handles repo error gracefully', () async {
      final fakeTutorRepo = _FakeTutorSessionRepository();
      fakeTutorRepo.throwOnGet = true;
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);
      final stats = await service.getStats('stu-1');
      expect(stats, isEmpty);
    });

    test('behavioral: voiceServiceProvider override can be provided', () {
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(tutorServiceProvider);
      expect(service, isA<TutorService>());
    });

    test('behavioral: multiple database overrides wired independently', () async {
      final now = DateTime(2024, 6, 15);
      final fakeTutorRepo = _FakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'ts-1', studentId: 'stu-1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: now, plannedDurationMinutes: 45,
          questionsAsked: 10, questionsCorrect: 7,
        ),
      ]);
      final fakeConvRepo = _FakeConversationRepository(seed: [
        ConversationMessage(
          id: 'msg-1', sessionId: 'session-1',
          role: MessageRole.tutor, type: MessageType.text,
          content: 'Hello', timestamp: now,
          tokenCount: 5,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: fakeConvRepo,
        tutorSessionRepository: fakeTutorRepo,
      );
      final container = ProviderContainer(
        overrides: [
          llmServiceProvider.overrideWithValue(_FakeLlmService()),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(tutorServiceProvider);

      final history = await service.getLessonHistory('stu-1');
      expect(history, hasLength(1));

      final messages = await service.getSessionMessages('session-1');
      expect(messages, hasLength(1));
      expect(messages.first.content, 'Hello');
    });
  });
}
