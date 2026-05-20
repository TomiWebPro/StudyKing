import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/services/conversation_phase.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';

class FakeConversationRepository extends ConversationRepository {
  final List<ConversationMessage> _messages = [];

  @override
  Future<Result<void>> saveMessage(ConversationMessage message) async {
    _messages.add(message);
    return Result.success(null);
  }

  @override
  Future<Result<List<ConversationMessage>>> getSessionMessages(String sessionId) async {
    return Result.success(_messages.where((m) => m.sessionId == sessionId).toList());
  }
}

class FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions = [];

  @override
  Future<Result<void>> saveSession(TutorSession session) async {
    _sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<List<TutorSession>>> getStudentSessions(String studentId) async {
    return Result.success(_sessions.where((s) => s.studentId == studentId).toList());
  }

  @override
  Future<Result<Map<String, dynamic>>> getSessionStats(String studentId) async {
    final sessionsResult = await getStudentSessions(studentId);
    final sessions = sessionsResult.data!;
    final completed = sessions.where((s) => s.status == SessionStatus.completed);
    return Result.success({
      'totalSessions': sessions.length,
      'completedSessions': completed.length,
      'totalHours': completed.fold<double>(0, (sum, s) => sum + (s.startTime.difference(s.startTime).inMinutes / 60.0)),
      'totalQuestions': completed.fold<int>(0, (sum, s) => sum + s.questionsAsked),
      'averageAccuracy': completed.isEmpty
          ? 0.0
          : completed.fold<double>(0, (sum, s) => sum + s.accuracy) / completed.length,
    });
  }

  @override
  Future<Result<List<TutorSession>>> getActiveSessions() async {
    return Result.success(_sessions.where((s) => s.status == SessionStatus.inProgress).toList());
  }
}

class FakeLlmService extends LlmService {
  bool _shouldThrowOnChat = false;

  FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
        );

  void setThrowOnChat() => _shouldThrowOnChat = true;

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
    if (_shouldThrowOnChat) throw Exception('LLM failure');
    return Result.success('{"goals":["Learn"],"sections":[{"title":"Intro","duration":10,"type":"explanation"}],"checkpoints":["ck"],"estimatedDifficulty":2}');
  }

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'Tutor response';
  }
}

class FakeExerciseEvaluator extends ExerciseEvaluator {
  FakeExerciseEvaluator()
      : super(
          llmService: FakeLlmService(),
          modelId: 'test-model',
          localeName: 'en',
        );

  @override
  Future<EvaluationResult> evaluate({
    required String question,
    required String studentAnswer,
    required String subjectId,
    required String topicTitle,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    return EvaluationResult(score: 0.8, explanation: 'Good job.');
  }
}

class FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  bool recordActivityCalled = false;

  FakePlanAdherenceOrchestrator() : super();

  @override
  Future<Result<void>> recordActivity({
    required String studentId,
    required int actualMinutes,
    int actualQuestions = 0,
    String? planId,
  }) async {
    recordActivityCalled = true;
    return Result.success(null);
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<Map<String, dynamic>> recordedAttempts = [];

  FakeMasteryGraphService();

  @override
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String topicId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) async {
    recordedAttempts.add({
      'studentId': studentId,
      'topicId': topicId,
      'questionId': questionId,
      'isCorrect': isCorrect,
      'confidence': confidence,
      'timeSpentMs': timeSpentMs,
    });
    return Result.success(null);
  }
}

class FixedClock extends Clock {
  final DateTime fixedTime;
  FixedClock(this.fixedTime);

  @override
  DateTime now() => fixedTime;
}

class FakeQuestionRepository extends QuestionRepository {
  final List<Question> _createdQuestions = [];

  List<Question> get createdQuestions => List.unmodifiable(_createdQuestions);

  @override
  Future<Result<void>> create(Question question) async {
    _createdQuestions.add(question);
    return Result.success(null);
  }
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> _savedSessions = [];

  List<Session> get savedSessions => List.unmodifiable(_savedSessions);

  @override
  @override
  Future<Result<void>> save(String key, Session session) async {
    _savedSessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(List.from(_savedSessions));
  }
}

void main() {
  group('TutorService', () {
    late FakeConversationRepository conversationRepo;
    late FakeTutorSessionRepository tutorSessionRepo;
    late FakeQuestionRepository fakeQuestionRepo;
    late FakeSessionRepository fakeSessionRepo;
    late DatabaseService database;
    late FakeLlmService llmService;
    late FakeMasteryGraphService masteryService;
    late FakeExerciseEvaluator exerciseEvaluator;
    late TutorService tutorService;

    setUp(() {
      conversationRepo = FakeConversationRepository();
      tutorSessionRepo = FakeTutorSessionRepository();
      fakeQuestionRepo = FakeQuestionRepository();
      fakeSessionRepo = FakeSessionRepository();
      database = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: fakeQuestionRepo,
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: fakeSessionRepo,
        subjectRepository: SubjectRepository(),
        conversationRepository: conversationRepo,
        tutorSessionRepository: tutorSessionRepo,
      );
      llmService = FakeLlmService();
      masteryService = FakeMasteryGraphService();
      exerciseEvaluator = FakeExerciseEvaluator();
      tutorService = TutorService(
        database: database,
        llmService: llmService,
        masteryService: masteryService,
        modelId: 'test-model',
        exerciseEvaluator: exerciseEvaluator,
        conversationRepository: conversationRepo,
        planOrchestrator: FakePlanAdherenceOrchestrator(),
      );
    });

    group('initial state', () {
      test('currentManager is null initially', () {
        expect(tutorService.currentManager, isNull);
      });
    });

    group('startLesson', () {
      test('creates a ConversationManager and saves session', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 45,
          localeName: 'en',
        );

        expect(tutorService.currentManager, equals(manager));
        expect(manager.sessionId, startsWith('tutor_'));
        expect(manager.studentId, equals('student-1'));
      });

      test('saves session to repository', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          durationMinutes: 30,
          localeName: 'en',
        );

        expect(tutorSessionRepo._sessions.length, greaterThan(0));
        final saved = tutorSessionRepo._sessions.first;
        expect(saved.studentId, equals('student-1'));
        expect(saved.subjectId, equals('math'));
        expect(saved.topicId, equals('topic-1'));
        expect(saved.topicTitle, equals('Algebra'));
        expect(saved.status, equals(SessionStatus.inProgress));
        expect(saved.plannedDurationMinutes, equals(30));
      });

      test('updates session with lesson plan after generation', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final sessions = tutorSessionRepo._sessions;
        expect(sessions.length, greaterThanOrEqualTo(2));
        final updated = sessions.last;
        expect(updated.lessonPlanJson, contains('goals'));
      });

      test('throws when LLM chat fails', () async {
        llmService.setThrowOnChat();
        expect(
          () async => await tutorService.startLesson(
            studentId: 'student-1',
            subjectId: 'math',
            topicId: 'topic-1',
            topicTitle: 'Algebra',
            localeName: 'en',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('endLesson', () {
      test('does nothing when no active lesson', () async {
        await tutorService.endLesson();
        expect(tutorService.currentManager, isNull);
      });

      test('saves messages to conversation repository', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(conversationRepo._messages.length, equals(2));
      });

      test('saves final session to repository', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        final completedSessions = tutorSessionRepo._sessions
            .where((s) => s.status == SessionStatus.completed);
        expect(completedSessions.isNotEmpty, isTrue);
      });

      test('records attempt in mastery service when questions were asked', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();
        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        await tutorService.endLesson();

        expect(masteryService.recordedAttempts.length, equals(1));
        expect(masteryService.recordedAttempts.first['studentId'], equals('student-1'));
        expect(masteryService.recordedAttempts.first['topicId'], equals('topic-1'));
        expect(masteryService.recordedAttempts.first['isCorrect'], isTrue);
      });

      test('preserves confidence rating correctly without overflow', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();
        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        await tutorService.endLesson();

        final recordedConfidence = masteryService.recordedAttempts.first['confidence'] as int;
        // confidenceRating should be 0-5 range, not multiplied by 20
        // With 1/2 = 0.5 accuracy, confidence = (0.5 * 1.0).clamp(0,1) = 0.5
        // toSession: (0.5 * 5).round() = 3 (or 2)
        // endLesson: should use session.confidenceRating directly (no * 20)
        expect(recordedConfidence, inInclusiveRange(0, 5));
        // The old bug would produce confidence = 100 when there were 0 questions,
        // or with our test setup, the confidence should never exceed 5
        expect(recordedConfidence, lessThanOrEqualTo(5));
      });

      test('clears current manager', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(tutorService.currentManager, isNull);
      });

      test('does not record attempt when no questions were asked', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(masteryService.recordedAttempts, isEmpty);
      });
    });

    group('getLessonHistory', () {
      test('returns empty list when no sessions exist', () async {
        final history = await tutorService.getLessonHistory('nonexistent');
        expect(history, isEmpty);
      });

      test('returns sessions for the given student', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final history = await tutorService.getLessonHistory('student-1');
        expect(history.isNotEmpty, isTrue);
        expect(history.first.studentId, equals('student-1'));
      });
    });

    group('getSessionMessages', () {
      test('returns empty list when no messages exist', () async {
        final messages = await tutorService.getSessionMessages('session-1');
        expect(messages, isEmpty);
      });
    });

    group('getStats', () {
      test('returns stats from repository', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final stats = await tutorService.getStats('student-1');
        expect(stats['totalSessions'], greaterThan(0));
        expect(stats, containsPair('completedSessions', 0));
      });
    });

    group('saveMessage', () {
      test('saves message to conversation repository', () async {
        final message = ConversationMessage(
          id: 'msg-1',
          sessionId: 'session-1',
          role: MessageRole.student,
          type: MessageType.text,
          content: 'Hello',
          timestamp: DateTime.now(),
        );

        await tutorService.saveMessage(message);

        expect(conversationRepo._messages.length, equals(1));
        expect(conversationRepo._messages.first.id, equals('msg-1'));
      });
    });

    group('getActiveSession', () {
      test('returns null when no active sessions', () async {
        final session = await tutorService.getActiveSession();
        expect(session, isNull);
      });

      test('returns active session when one exists', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        final session = await tutorService.getActiveSession();
        expect(session, isNotNull);
        expect(session!.status, equals(SessionStatus.inProgress));
      });
    });

    group('recordAttempt accuracy threshold', () {
      test('records isCorrect=false when accuracy is <= 0.5', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        manager.recordCorrectAnswer();
        manager.recordIncorrectAnswer();

        await tutorService.endLesson();

        expect(masteryService.recordedAttempts.length, equals(1));
        expect(masteryService.recordedAttempts.first['isCorrect'], isFalse);
      });
    });

    group('_persistExercisesAsQuestions', () {
      test('persists exercise as question when exercises and evaluation exist', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        manager.phase = ConversationPhase.exercise;
        await manager.sendMessage('correct').toList();

        await tutorService.endLesson();

        expect(fakeQuestionRepo.createdQuestions.length, equals(1));
        final question = fakeQuestionRepo.createdQuestions.first;
        expect(question.text, contains('Algebra'));
        expect(question.subjectId, equals('math'));
        expect(question.topicId, equals('topic-1'));
        expect(question.type, equals(QuestionType.typedAnswer));
        expect(question.explanation, contains('Good job'));
      });

      test('does not persist question when no exercises done', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(fakeQuestionRepo.createdQuestions, isEmpty);
      });

      test('does not persist question when exerciseCount is 0', () async {
        await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );

        await tutorService.endLesson();

        expect(fakeQuestionRepo.createdQuestions, isEmpty);
      });
    });

    group('endLesson session repository', () {
      test('creates a Session entry in session repository', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          localeName: 'en',
        );
        await manager.sendMessage('Hello').toList();

        await tutorService.endLesson();

        expect(fakeSessionRepo.savedSessions.length, equals(1));
        final session = fakeSessionRepo.savedSessions.first;
        expect(session.studentId, equals('student-1'));
        expect(session.subjectId, equals('math'));
        expect(session.topicId, equals('topic-1'));
        expect(session.type, equals(SessionType.tutoring));
        expect(session.completed, isTrue);
        expect(session.sourceId, startsWith('tutor_'));
      });
    });
  });
}
