import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/conversation_repository.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/features/subjects/data/models/subject_model.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions = [];

  void addSession(TutorSession session) => _sessions.add(session);

  @override
  Future<void> saveSession(TutorSession session) async {
    _sessions.add(session);
  }

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    return _sessions.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<TutorSession?> getSession(String id) async {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

class FakeStudySessionRepository extends StudySessionRepository {
  final List<StudySession> _sessions = [];

  void addSession(StudySession session) => _sessions.add(session);

  @override
  Future<List<StudySession>> getByStudent(String studentId) async {
    return _sessions.where((s) => s.studentId == studentId).toList();
  }
}

class FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects = [];

  void addSubject(Subject subject) => _subjects.add(subject);

  @override
  Future<List<Subject>> getAll() async => _subjects;
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
  Stream<String> chatStream({
    required String message,
    required String modelId,
    String? systemPrompt,
    ConversationMemory? memory,
    List<Map<String, String>>? history,
  }) async* {
    yield 'Mentor response';
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  Result<List<MasteryState>>? _weakTopicsResult;

  void setWeakTopicsResult(Result<List<MasteryState>> result) {
    _weakTopicsResult = result;
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return _weakTopicsResult ?? Result.success([]);
  }
}

class FakeProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> _stats = {
    'totalAttempts': 10,
    'correctAttempts': 7,
    'accuracy': 70,
    'avgTimePerQuestion': 30,
    'totalStudyTimeHours': '2.5',
    'weeklyActivity': 5,
    'dailyActivity': 2,
    'topicsStudied': 3,
  };
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _badges = [];

  FakeProgressTracker({
    AttemptRepository? attemptRepo,
    super.masteryService,
  }) : super(
          attemptRepo: attemptRepo ?? AttemptRepository(),
        );

  void setStats(Map<String, dynamic> stats) => _stats = stats;
  void setRecommendations(List<Map<String, dynamic>> recs) =>
      _recommendations = recs;
  void setBadges(List<Map<String, dynamic>> badges) => _badges = badges;

  @override
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    if (_stats.containsKey('throw')) throw Exception('Simulated error');
    return _stats;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendations(
      String studentId) async => _recommendations;

  @override
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async =>
      _badges;
}

MentorService createMentorService({
  DatabaseService? database,
  LlmService? llmService,
  MasteryGraphService? masteryService,
  StudyProgressTracker? progressTracker,
  String modelId = 'test-model',
  String studentId = 'test-student',
}) {
  final db = database ??
      DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: FakeStudySessionRepository(),
        subjectRepository: FakeSubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: FakeTutorSessionRepository(),
      );
  final llm = llmService ?? FakeLlmService();
  final mastery = masteryService ?? FakeMasteryGraphService();
  final tracker = progressTracker ??
      FakeProgressTracker(
        attemptRepo: AttemptRepository(),
        masteryService: mastery,
      );
  return MentorService(
    database: db,
    llmService: llm,
    masteryService: mastery,
    progressTracker: tracker,
    modelId: modelId,
    studentId: studentId,
    l10n: AppLocalizationsEn(),
  );
}

void main() {
  group('MentorService', () {
    group('initial state', () {
      test('memory is a ConversationMemory', () {
        final service = createMentorService();
        expect(service.memory, isA<ConversationMemory>());
      });

      test('hasPendingConfirmation is false initially', () {
        final service = createMentorService();
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('pendingAction is null initially', () {
        final service = createMentorService();
        expect(service.pendingAction, isNull);
      });
    });

    group('chat - regular messages', () {
      late MentorService service;
      late FakeLlmService llmService;

      setUp(() {
        llmService = FakeLlmService();
        service = createMentorService(llmService: llmService);
      });

      test('sends regular message to LLM and returns chunks', () async {
        final chunks = await service.chat('Hello mentor').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, equals('Mentor response'));
      });

      test('adds user and assistant messages to memory', () async {
        await service.chat('Hello').toList();
        final history = service.memory.getHistory();
        expect(history.length, equals(2));
        expect(history[0]['role'], equals('user'));
        expect(history[0]['content'], equals('Hello'));
        expect(history[1]['role'], equals('assistant'));
        expect(history[1]['content'], equals('Mentor response'));
      });
    });

    group('chat - schedule request handling', () {
      test('handles schedule keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('schedule a lesson').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, contains('lesson'));
      });

      test('handles plan keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('plan my study').toList();
        expect(chunks, isNotEmpty);
      });

      test('handles reschedule keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('reschedule my lesson').toList();
        expect(chunks, isNotEmpty);
      });

      test('handles when keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('when is my next study').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, contains('lesson'));
      });

      test('handles "next study" keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('next study session').toList();
        expect(chunks, isNotEmpty);
      });

      test('adds user message to memory for schedule request', () async {
        final service = createMentorService();
        await service.chat('schedule a lesson').toList();
        final history = service.memory.getHistory();
        expect(history.isNotEmpty, isTrue);
        expect(history.last['role'], equals('user'));
      });
    });

    group('chat - progress request handling', () {
      test('handles progress keyword', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 5,
          'correctAttempts': 4,
          'accuracy': 80,
          'avgTimePerQuestion': 20,
          'totalStudyTimeHours': '1.0',
          'weeklyActivity': 3,
          'dailyActivity': 1,
          'topicsStudied': 2,
        });
        final service = createMentorService(progressTracker: tracker);

        final chunks = await service.chat('show my progress').toList();
        expect(chunks.join(), contains('80'));
      });

      test('handles "how am i doing" keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('how am i doing').toList();
        expect(chunks.join(), contains('Study Progress Report'));
      });

      test('handles stats keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('show stats').toList();
        expect(chunks.join(), contains('Study Progress Report'));
      });

      test('handles weak keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('my weak areas').toList();
        expect(chunks.join(), contains('Study Progress Report'));
      });

      test('adds only user message to memory for progress request', () async {
        final service = createMentorService();
        await service.chat('show my progress').toList();
        final history = service.memory.getHistory();
        expect(history.isNotEmpty, isTrue);
        expect(history.last['role'], equals('user'));
      });
    });

    group('chat - inactivity check handling', () {
      test('handles inactive keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('i am inactive').toList();
        expect(chunks.first, contains("haven't started studying"));
      });

      test('handles reminder keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('send a reminder').toList();
        expect(chunks.first, contains("haven't started studying"));
      });

      test('handles nudge keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat('give me a nudge').toList();
        expect(chunks.first, contains("haven't started studying"));
      });

      test('handles "haven\'t studied" keyword', () async {
        final service = createMentorService();
        final chunks = await service.chat("i haven't studied").toList();
        expect(chunks.first, contains("haven't started studying"));
      });
    });

    group('chat - pending confirmation flow', () {
      test('confirmation with "yes" executes pending reschedule action',
          () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');
        expect(service.hasPendingConfirmation, isTrue);

        final chunks = await service.chat('yes').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, contains('Algebra'));
        expect(chunks.first, contains('rescheduled'));
        expect(service.hasPendingConfirmation, isFalse);
        expect(service.pendingAction, isNull);
      });

      test('confirmation with "sure" executes pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('sure').toList();
        expect(chunks.first, contains('rescheduled'));
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('confirmation with "ok" executes pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('ok').toList();
        expect(chunks.first, contains('rescheduled'));
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('confirmation with "go ahead" executes pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('go ahead').toList();
        expect(chunks.first, contains('rescheduled'));
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('confirmation with "confirm" executes pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('confirm').toList();
        expect(chunks.first, contains('rescheduled'));
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('confirmation with "please do" executes pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('please do').toList();
        expect(chunks.first, contains('rescheduled'));
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('rejection with "no" clears pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('no').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, contains("No problem"));
        expect(service.hasPendingConfirmation, isFalse);
        expect(service.pendingAction, isNull);
      });

      test('rejection with "cancel" clears pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('cancel').toList();
        expect(chunks.first, contains("No problem"));
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('rejection with "never mind" clears pending action', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final chunks = await service.chat('never mind').toList();
        expect(chunks.first, contains("No problem"));
        expect(service.hasPendingConfirmation, isFalse);
      });

      test('neither confirm nor reject falls through to regular handler',
          () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');
        expect(service.hasPendingConfirmation, isTrue);

        final chunks = await service.chat('hello there').toList();
        expect(chunks.first, equals('Mentor response'));
        expect(service.hasPendingConfirmation, isTrue);
      });
    });

    group('_handleScheduleRequest behavior via chat', () {
      test('yields empty schedule message when no scheduled lessons exist',
          () async {
        final service = createMentorService();
        final chunks = await service.chat('schedule something').toList();
        expect(chunks, isNotEmpty);
        final combined = chunks.join();
        expect(combined, contains("don't have any lessons scheduled yet"));
      });

      test('yields upcoming lessons when planned sessions exist', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.planned,
          startTime: DateTime(2025, 6, 15),
          plannedDurationMinutes: 45,
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('schedule something').toList();
        final combined = chunks.join();
        expect(combined, contains('Algebra'));
        expect(combined, contains('upcoming'));
      });

      test('yields multiple upcoming lessons', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.planned,
          startTime: DateTime(2025, 6, 15),
          plannedDurationMinutes: 45,
        ));
        tutorRepo.addSession(TutorSession(
          id: 's2',
          studentId: 'test-student',
          subjectId: 'physics',
          topicId: 't2',
          topicTitle: 'Newton Laws',
          status: SessionStatus.planned,
          startTime: DateTime(2025, 6, 16),
          plannedDurationMinutes: 60,
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('schedule something').toList();
        final combined = chunks.join();
        expect(combined, contains('Algebra'));
        expect(combined, contains('Newton Laws'));
      });

      test('yields recent session message when no upcoming but has recent',
          () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now(),
        ));
        final studyRepo = FakeStudySessionRepository();
        studyRepo.addSession(StudySession(
          id: 'ss1',
          studentId: 'test-student',
          subjectId: 'math',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: studyRepo,
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('schedule something').toList();
        final combined = chunks.join();
        expect(combined, contains('schedule a new lesson'));
      });

      test('asks to schedule new lesson when no upcoming but has recent session',
          () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now(),
        ));
        final studyRepo = FakeStudySessionRepository();
        studyRepo.addSession(StudySession(
          id: 'ss1',
          studentId: 'test-student',
          subjectId: 'math',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: studyRepo,
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('schedule something').toList();
        final combined = chunks.join();
        expect(combined, contains("schedule a new lesson"));
      });
    });

    group('_handleProgressRequest behavior via chat', () {
      test('returns progress report with accuracy', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 20,
          'correctAttempts': 15,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '3.0',
          'weeklyActivity': 8,
          'dailyActivity': 3,
          'topicsStudied': 5,
        });
        final service = createMentorService(progressTracker: tracker);

        final chunks = await service.chat('how am i doing').toList();
        final combined = chunks.join();
        expect(combined, contains('75'));
        expect(combined, contains('Study Progress Report'));
      });

      test('includes weak topics when available', () async {
        final mastery = FakeMasteryGraphService();
        mastery.setWeakTopicsResult(Result.success([
          MasteryState(
            studentId: 'test-student',
            topicId: 'topic_weak',
            accuracy: 0.45,
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ]));
        final tracker = FakeProgressTracker(
          attemptRepo: AttemptRepository(),
          masteryService: mastery,
        );
        tracker.setStats({
          'totalAttempts': 20,
          'correctAttempts': 15,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '3.0',
          'weeklyActivity': 8,
          'dailyActivity': 3,
          'topicsStudied': 5,
        });
        final service =
            createMentorService(masteryService: mastery, progressTracker: tracker);

        final chunks = await service.chat('progress').toList();
        final combined = chunks.join();
        expect(combined, contains('topic_weak'));
        expect(combined, contains('45'));
      });

      test('includes badges when available', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 20,
          'correctAttempts': 15,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '3.0',
          'weeklyActivity': 8,
          'dailyActivity': 3,
          'topicsStudied': 5,
        });
        tracker.setBadges([
          {
            'id': 'first_attempt',
            'name': 'First Step',
            'description': 'Answered your first question!',
            'unlockedAt': DateTime.now().toIso8601String(),
          },
        ]);
        final service = createMentorService(progressTracker: tracker);

        final chunks = await service.chat('progress').toList();
        expect(chunks.join(), contains('First Step'));
      });

      test('includes recommendations when available', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 20,
          'correctAttempts': 15,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '3.0',
          'weeklyActivity': 8,
          'dailyActivity': 3,
          'topicsStudied': 5,
        });
        tracker.setRecommendations([
          {
            'type': 'review',
            'priority': 'high',
            'message': 'Review basic concepts',
            'action': 'Review',
          },
        ]);
        final service = createMentorService(progressTracker: tracker);

        final chunks = await service.chat('progress').toList();
        expect(chunks.join(), contains('Review basic concepts'));
      });
    });

    group('_handleInactivityCheck behavior via chat', () {
      test('yields welcome message when no sessions exist', () async {
        final service = createMentorService();
        final chunks = await service.chat('i am inactive').toList();
        expect(chunks.first, contains("haven't started studying"));
      });

      test('yields nudge when last session was 3+ days ago', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime.now().subtract(const Duration(days: 5)),
          endTime: DateTime.now().subtract(const Duration(days: 5)),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('reminder').toList();
        expect(chunks.first, contains("haven't studied in"));
      });

      test('yields encouragement when session was today', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          endTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('reminder').toList();
        expect(chunks.first, contains('Great job'));
        expect(chunks.first, contains('today'));
      });

      test('yields encouragement when last session was recent', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now().subtract(const Duration(days: 1)),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('reminder').toList();
        expect(chunks.first, contains('Great job'));
        expect(chunks.first, contains('1 days ago'));
      });

      test('handles sessions without endTime', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.inProgress,
          startTime: DateTime.now().subtract(const Duration(days: 1)),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final chunks = await service.chat('reminder').toList();
        expect(chunks.first, contains('Welcome'));
      });
    });

    group('getProgressReport', () {
      test('returns formatted progress report with stats', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 20,
          'correctAttempts': 15,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '3.0',
          'weeklyActivity': 8,
          'dailyActivity': 3,
          'topicsStudied': 5,
        });
        final service = createMentorService(progressTracker: tracker);

        final report = await service.getProgressReport();
        expect(report, contains('Study Progress Report'));
        expect(report, contains('75%'));
        expect(report, contains('3.0 hours'));
      });

      test('includes weak topics in report', () async {
        final mastery = FakeMasteryGraphService();
        mastery.setWeakTopicsResult(Result.success([
          MasteryState(
            studentId: 'test-student',
            topicId: 'topic_weak',
            accuracy: 0.3,
            lastAttempt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ]));
        final tracker = FakeProgressTracker(
          attemptRepo: AttemptRepository(),
          masteryService: mastery,
        );
        tracker.setStats({
          'totalAttempts': 10,
          'correctAttempts': 5,
          'accuracy': 50,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '1.0',
          'weeklyActivity': 2,
          'dailyActivity': 1,
          'topicsStudied': 2,
        });
        final service =
            createMentorService(masteryService: mastery, progressTracker: tracker);

        final report = await service.getProgressReport();
        expect(report, contains('Areas needing attention'));
        expect(report, contains('topic_weak'));
      });

      test('returns error message on failure', () async {
        final errorTracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        errorTracker.setStats({'throw': true});
        final service = createMentorService(progressTracker: errorTracker);

        final report = await service.getProgressReport();
        expect(report, contains('Unable to generate progress report'));
      });
    });

    group('getSchedule', () {
      test('returns upcoming lessons from tutor session repo', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 's1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          status: SessionStatus.planned,
          startTime: DateTime(2025, 6, 15),
          plannedDurationMinutes: 45,
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        final schedule = await service.getSchedule();
        expect(schedule['upcomingLessons'], isNotEmpty);
        expect(schedule['upcomingLessons'].first['topic'], equals('Algebra'));
        expect(schedule['totalSessions'], equals(1));
      });

      test('returns recent study sessions', () async {
        final studyRepo = FakeStudySessionRepository();
        studyRepo.addSession(StudySession(
          id: 'ss1',
          studentId: 'test-student',
          subjectId: 'math',
          startTime: DateTime.now(),
          timeSpentMs: 3600000,
          questionsAnswered: 10,
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: studyRepo,
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: FakeTutorSessionRepository(),
        );
        final service = createMentorService(database: db);

        final schedule = await service.getSchedule();
        expect(schedule['recentSessions'], isNotEmpty);
        expect(schedule['recentSessions'].first['questions'], equals(10));
      });

      test('handles plan repository error gracefully', () async {
        final service = createMentorService();
        final schedule = await service.getSchedule();
        expect(schedule, contains('upcomingLessons'));
        expect(schedule, contains('recentSessions'));
        expect(schedule, contains('totalSessions'));
      });
    });

    group('suggestNextAction', () {
      test('returns recommendation message when recommendations exist',
          () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setRecommendations([
          {
            'type': 'review',
            'priority': 'high',
            'message': 'Focus on reviewing fundamentals',
            'action': 'Review',
          },
        ]);
        final service = createMentorService(progressTracker: tracker);

        final action = await service.suggestNextAction();
        expect(action, equals('Focus on reviewing fundamentals'));
      });

      test('returns subject setup message when no subjects', () async {
        final service = createMentorService();
        final action = await service.suggestNextAction();
        expect(action, contains("haven't added any subjects"));
      });

      test('returns generic message when recommendations and subjects exist',
          () async {
        final subjectRepo = FakeSubjectRepository();
        subjectRepo.addSubject(Subject(
          id: 'math',
          name: 'Mathematics',
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: subjectRepo,
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: FakeTutorSessionRepository(),
        );
        final service = createMentorService(database: db);

        final action = await service.suggestNextAction();
        expect(action, contains("You're doing well"));
      });
    });

    group('suggestReschedule', () {
      test('sets pending confirmation and action for existing session',
          () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        expect(service.hasPendingConfirmation, isTrue);
        expect(service.pendingAction, isNotNull);
        expect(service.pendingAction!['type'], equals('reschedule'));
        expect(service.pendingAction!['sessionId'], equals('session-1'));
        expect(service.pendingAction!['topic'], equals('Algebra'));
      });

      test('does nothing when session not found', () async {
        final tutorRepo = FakeTutorSessionRepository();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('nonexistent');
        expect(service.hasPendingConfirmation, isFalse);
        expect(service.pendingAction, isNull);
      });

      test('adds system message about rescheduling to memory', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeStudySessionRepository(),
          subjectRepository: FakeSubjectRepository(),
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: tutorRepo,
        );
        final service = createMentorService(database: db);

        await service.suggestReschedule('session-1');

        final history = service.memory.getHistory();
        expect(history.any((m) =>
            m['role'] == 'system' &&
            m['content']!.contains('Algebra')), isTrue);
      });
    });
  });
}
