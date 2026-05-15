import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/pending_action_model.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/core/data/models/subject_model.dart';
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
  String? capturedMessage;
  String? capturedSystemPrompt;

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
    String feature = 'general',
  }) async* {
    capturedMessage = message;
    capturedSystemPrompt = systemPrompt;
    yield 'Mentor response';
  }
}

class FakePendingActionRepository extends PendingActionRepository {
  final List<PendingActionModel> _actions = [];

  List<PendingActionModel> get createdActions =>
      List.unmodifiable(_actions);

  @override
  Future<void> init() async {}

  @override
  Future<void> create(PendingActionModel action) async {
    _actions.add(action);
  }

  @override
  Future<List<PendingActionModel>> getPending(String studentId) async {
    return _actions
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
  PendingActionRepository? pendingActionRepo,
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
    pendingActionRepo: pendingActionRepo,
  );
}

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('mentor_test_');
    Hive.init(dir.path);
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });

  group('MentorService', () {
    group('initial state', () {
      test('memory is a ConversationMemory', () {
        final service = createMentorService();
        expect(service.memory, isA<ConversationMemory>());
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

    group('chat - all messages delegate to LLM', () {
      test('schedule keyword delegates to LLM', () async {
        final service = createMentorService();
        final chunks = await service.chat('schedule a lesson').toList();
        expect(chunks, isNotEmpty);
        expect(chunks.first, equals('Mentor response'));
      });

      test('progress keyword delegates to LLM', () async {
        final service = createMentorService();
        final chunks = await service.chat('show my progress').toList();
        expect(chunks.first, equals('Mentor response'));
      });

      test('inactivity keyword delegates to LLM', () async {
        final service = createMentorService();
        final chunks = await service.chat('i am inactive').toList();
        expect(chunks.first, equals('Mentor response'));
      });

      test('adds user and assistant messages to memory', () async {
        final service = createMentorService();
        await service.chat('schedule a lesson').toList();
        final history = service.memory.getHistory();
        expect(history.length, equals(2));
        expect(history[0]['role'], equals('user'));
        expect(history[1]['role'], equals('assistant'));
      });
    });

    group('suggestReschedule', () {
      test('stores pending action in repository', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final fakePending = FakePendingActionRepository();
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
        final service = createMentorService(
          database: db,
          pendingActionRepo: fakePending,
        );

        await service.suggestReschedule('session-1');
        final chatResult = await service.chat('hello').toList();
        expect(chatResult.first, equals('Mentor response'));
      });
    });

    group('getProgressReport', () {
      test('returns structured progress report with stats', () async {
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
        expect(report.accuracy, equals(75.0));
        expect(report.totalAttempts, equals(20));
        expect(report.correctAttempts, equals(15));
        expect(report.totalStudyTimeHours, equals('3.0'));
        expect(report.weeklyActivity, equals(8));
        expect(report.topicsStudied, equals(5));
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
        expect(report.weakTopics.length, equals(1));
        expect(report.weakTopics.first.topicId, equals('topic_weak'));
      });

      test('throws on failure', () async {
        final errorTracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        errorTracker.setStats({'throw': true});
        final service = createMentorService(progressTracker: errorTracker);

        expect(() => service.getProgressReport(), throwsA(isA<Exception>()));
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
        expect(action.message, equals('Focus on reviewing fundamentals'));
      });

      test('returns subject setup message when no subjects', () async {
        final service = createMentorService();
        final action = await service.suggestNextAction();
        expect(action.message, contains("haven't added any subjects"));
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
        expect(action.message, contains("You're doing well"));
      });
    });

    group('suggestReschedule', () {
      test('stores pending action and adds system message for existing session',
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
        final fakePending = FakePendingActionRepository();
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
        final service = createMentorService(
          database: db,
          pendingActionRepo: fakePending,
        );

        await service.suggestReschedule('session-1');

        final history = service.memory.getHistory();
        expect(history.any((m) =>
            m['role'] == 'system' &&
            m['content']!.contains('Algebra')), isTrue);
      });

      test('does nothing when session not found', () async {
        final tutorRepo = FakeTutorSessionRepository();
        final fakePending = FakePendingActionRepository();
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
        final service = createMentorService(
          database: db,
          pendingActionRepo: fakePending,
        );

        await service.suggestReschedule('nonexistent');
        final history = service.memory.getHistory();
        expect(history.where((m) => m['role'] == 'system'), isEmpty);
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
        final fakePending = FakePendingActionRepository();
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
        final service = createMentorService(
          database: db,
          pendingActionRepo: fakePending,
        );

        await service.suggestReschedule('session-1');

        final history = service.memory.getHistory();
        expect(history.any((m) =>
            m['role'] == 'system' &&
            m['content']!.contains('Algebra')), isTrue);
      });

      test('creates pending action with correct fields', () async {
        final tutorRepo = FakeTutorSessionRepository();
        tutorRepo.addSession(TutorSession(
          id: 'session-1',
          studentId: 'test-student',
          subjectId: 'math',
          topicId: 't1',
          topicTitle: 'Algebra',
          startTime: DateTime.now(),
        ));
        final fakePending = FakePendingActionRepository();
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
        final service = createMentorService(
          database: db,
          pendingActionRepo: fakePending,
        );

        await service.suggestReschedule('session-1');

        expect(fakePending.createdActions.length, equals(1));
        final action = fakePending.createdActions.first;
        expect(action.actionType, equals(PendingActionType.reschedule.name));
        expect(action.topicTitle, equals('Algebra'));
        expect(action.studentId, equals('test-student'));
        expect(action.sessionId, equals('session-1'));
      });
    });

    group('initialize', () {
      test('completes successfully without conversation repo', () async {
        final service = createMentorService();
        await expectLater(service.initialize(), completes);
      });

      test('does not throw when memory has no repository', () async {
        final service = createMentorService();
        await service.initialize();
        final history = service.memory.getHistory();
        expect(history, isEmpty);
      });
    });

    group('chat - planning intent', () {
      late FakeLlmService llm;
      late FakePendingActionRepository fakePending;

      setUp(() {
        llm = FakeLlmService();
        fakePending = FakePendingActionRepository();
      });

      test('schedule keyword creates pending action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('schedule a math lesson').toList();
        expect(fakePending.createdActions.length, equals(1));
        expect(
          fakePending.createdActions.first.actionType,
          equals(PendingActionType.schedule.name),
        );
      });

      test('reschedule keyword creates reschedule type action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('reschedule my physics session').toList();
        expect(fakePending.createdActions.length, equals(1));
        expect(
          fakePending.createdActions.first.actionType,
          equals(PendingActionType.reschedule.name),
        );
      });

      test('plan keyword creates pending action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('plan a study roadmap').toList();
        expect(fakePending.createdActions.length, equals(1));
      });

      test('roadmap keyword creates pending action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('create a roadmap for chemistry').toList();
        expect(fakePending.createdActions.length, equals(1));
      });

      test('programar keyword (Portuguese) creates pending action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('programar estudos de matematica').toList();
        expect(fakePending.createdActions.length, equals(1));
      });

      test('reprogramar keyword (Portuguese) creates pending action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('reprogramar sessoes').toList();
        expect(fakePending.createdActions.length, equals(1));
      });

      test('planificar keyword (Spanish) creates pending action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('planificar el estudio').toList();
        expect(fakePending.createdActions.length, equals(1));
      });

      test('does not create duplicate when existing pending exists',
          () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('schedule a lesson').toList();
        await service.chat('schedule another lesson').toList();
        expect(fakePending.createdActions.length, equals(1));
      });

      test('non-planning message does not create pending action', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('hello how are you').toList();
        expect(fakePending.createdActions, isEmpty);
      });

      test('topic is extracted from schedule message', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('schedule a lesson about calculus').toList();
        expect(fakePending.createdActions.first.topicTitle, equals('calculus'));
      });

      test('topic with punctuation is trimmed', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('schedule study linear algebra, please').toList();
        expect(
          fakePending.createdActions.first.topicTitle,
          equals('linear algebra'),
        );
      });

      test('topic after learn keyword is extracted', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('schedule learn dart').toList();
        expect(
          fakePending.createdActions.first.topicTitle,
          equals('dart'),
        );
      });

      test('topic after topic keyword is extracted', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('schedule topic world history').toList();
        expect(
          fakePending.createdActions.first.topicTitle,
          equals('world history'),
        );
      });

      test('fallback to general when no topic keyword found', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        await service.chat('schedule something').toList();
        expect(
          fakePending.createdActions.first.topicTitle,
          equals('general'),
        );
      });

      test('pending action includes original message in payload', () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        const originalMsg = 'schedule a review for tomorrow';
        await service.chat(originalMsg).toList();
        final payload =
            fakePending.createdActions.first.payload;
        expect(payload['originalMessage'], equals(originalMsg));
      });

      test('chat completes when LLM response triggers planning intent',
          () async {
        final service = createMentorService(
          llmService: llm,
          pendingActionRepo: fakePending,
        );
        final chunks = await service.chat('schedule math review').toList();
        expect(chunks, isNotEmpty);
      });
    });

    group('chat - context prompt', () {
      test('includes student stats in LLM prompt', () async {
        final llm = FakeLlmService();
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 15,
          'correctAttempts': 10,
          'accuracy': 67,
          'avgTimePerQuestion': 25,
          'totalStudyTimeHours': '4.0',
          'weeklyActivity': 6,
          'dailyActivity': 2,
          'topicsStudied': 4,
        });
        final service = createMentorService(
          llmService: llm,
          progressTracker: tracker,
        );
        await service.chat('hello').toList();
        expect(llm.capturedMessage, contains('Total attempts: 15'));
        expect(llm.capturedMessage, contains('Student: hello'));
      });

      test('includes accuracy and topics studied in prompt', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm);
        await service.chat('hello').toList();
        expect(llm.capturedMessage, contains('Accuracy'));
        expect(llm.capturedMessage, contains('Topics studied'));
      });

      test('uses mentor system prompt', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm);
        await service.chat('hello').toList();
        expect(
          llm.capturedSystemPrompt,
          contains('encouraging AI mentor'),
        );
      });
    });

    group('getProgressReport - badges', () {
      test('includes badges in progress report', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setBadges([
          {
            'id': 'first_attempt',
            'name': 'First Attempt',
            'description': 'Completed your first attempt',
            'unlockedAt': '2024-01-01T00:00:00.000',
          },
        ]);
        tracker.setStats({
          'totalAttempts': 10,
          'correctAttempts': 7,
          'accuracy': 70,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '2.5',
          'weeklyActivity': 5,
          'dailyActivity': 2,
          'topicsStudied': 3,
        });
        final service = createMentorService(progressTracker: tracker);

        final report = await service.getProgressReport();
        expect(report.badges.length, equals(1));
        expect(report.badges.first['id'], equals('first_attempt'));
        expect(report.badges.first['name'], equals('First Attempt'));
      });

      test('includes recommendations in progress report', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setRecommendations([
          {
            'type': 'review',
            'priority': 'high',
            'message': 'Review algebra fundamentals',
            'action': 'Review',
          },
        ]);
        tracker.setStats({
          'totalAttempts': 10,
          'correctAttempts': 7,
          'accuracy': 70,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '2.5',
          'weeklyActivity': 5,
          'dailyActivity': 2,
          'topicsStudied': 3,
        });
        final service = createMentorService(progressTracker: tracker);

        final report = await service.getProgressReport();
        expect(report.recommendations.length, equals(1));
        expect(
          report.recommendations.first['type'],
          equals('review'),
        );
      });
    });
  });
}
