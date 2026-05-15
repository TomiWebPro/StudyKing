import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/conversation_message_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';

class FakeConversationRepository extends ConversationRepository {
  final List<ConversationMessage> _messages = [];

  @override
  Future<void> saveMessage(ConversationMessage message) async {
    _messages.add(message);
  }

  @override
  Future<List<ConversationMessage>> getSessionMessages(String sessionId) async {
    return _messages.where((m) => m.sessionId == sessionId).toList();
  }
}

class FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions = [];

  @override
  Future<void> saveSession(TutorSession session) async {
    _sessions.add(session);
  }

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    return _sessions.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<Map<String, dynamic>> getSessionStats(String studentId) async {
    final sessions = await getStudentSessions(studentId);
    final completed = sessions.where((s) => s.status == SessionStatus.completed);
    return {
      'totalSessions': sessions.length,
      'completedSessions': completed.length,
      'totalHours': completed.fold<double>(0, (sum, s) => sum + (s.elapsedMinutes / 60.0)),
      'totalQuestions': completed.fold<int>(0, (sum, s) => sum + s.questionsAsked),
      'averageAccuracy': completed.isEmpty
          ? 0.0
          : completed.fold<double>(0, (sum, s) => sum + s.accuracy) / completed.length,
    };
  }

  @override
  Future<List<TutorSession>> getActiveSessions() async {
    return _sessions.where((s) => s.status == SessionStatus.inProgress).toList();
  }
}

class FakeLlmService extends LlmService {
  FakeLlmService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: '',
          ),
        );

  @override
  Future<String> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    return '{"goals":["Learn"],"sections":[{"title":"Intro","duration":10,"type":"explanation"}],"checkpoints":["ck"],"estimatedDifficulty":2}';
  }

  @override
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async* {
    yield 'Tutor response';
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<Map<String, dynamic>> recordedAttempts = [];

  FakeMasteryGraphService() : super();

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

void main() {
  group('TutorService', () {
    late FakeConversationRepository conversationRepo;
    late FakeTutorSessionRepository tutorSessionRepo;
    late DatabaseService database;
    late FakeLlmService llmService;
    late FakeMasteryGraphService masteryService;
    late TutorService tutorService;

    setUp(() {
      conversationRepo = FakeConversationRepository();
      tutorSessionRepo = FakeTutorSessionRepository();
      database = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: SessionRepository(),
        subjectRepository: SubjectRepository(),
        conversationRepository: conversationRepo,
        tutorSessionRepository: tutorSessionRepo,
      );
      llmService = FakeLlmService();
      masteryService = FakeMasteryGraphService();
      tutorService = TutorService(
        database: database,
        llmService: llmService,
        masteryService: masteryService,
        modelId: 'test-model',
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
          durationMinutes: 45,
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
          durationMinutes: 30,
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
        );

        final sessions = tutorSessionRepo._sessions;
        expect(sessions.length, greaterThanOrEqualTo(2));
        final updated = sessions.last;
        expect(updated.lessonPlanJson, contains('goals'));
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
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

      test('clears current manager', () async {
        final manager = await tutorService.startLesson(
          studentId: 'student-1',
          subjectId: 'math',
          topicId: 'topic-1',
          topicTitle: 'Algebra',
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
        );

        final stats = await tutorService.getStats('student-1');
        expect(stats['totalSessions'], greaterThan(0));
        expect(stats, containsPair('completedSessions', 0));
        expect(stats, containsPair('totalHours', 0.0));
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
          correctKeywords: [],
          incorrectKeywords: [],
          exerciseKeywords: [],
        );

        final session = await tutorService.getActiveSession();
        expect(session, isNotNull);
        expect(session!.status, equals(SessionStatus.inProgress));
      });
    });
  });
}
