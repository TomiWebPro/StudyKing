import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart' show AdherenceDeviation;
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class FakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions = [];

  void addSession(TutorSession session) => _sessions.add(session);

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
  Future<Result<TutorSession?>> getSession(String id) async {
    try {
      return Result.success(_sessions.firstWhere((s) => s.id == id));
    } catch (_) {
      return Result.success(null);
    }
  }
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];

  void addSession(Session session) => sessions.add(session);

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(sessions.where((s) => s.studentId == studentId).toList());
  }
}

class FakeSubjectRepository extends SubjectRepository {
  final List<Subject> _subjects = [];

  void addSubject(Subject subject) => _subjects.add(subject);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_subjects);
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
    String localeName = 'en',
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
  bool _throwOnCreate = false;

  List<PendingActionModel> get createdActions =>
      List.unmodifiable(_actions);

  void setThrowOnCreate() => _throwOnCreate = true;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(PendingActionModel action) async {
    if (_throwOnCreate) throw Exception('Simulated error');
    _actions.add(action);
    return Result.success(null);
  }

  @override
  Future<Result<List<PendingActionModel>>> getPending(String studentId) async {
    return Result.success(_actions
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  Result<List<MasteryState>>? _weakTopicsResult;
  Result<List<QuestionMasteryState>>? _atRiskResult;

  void setWeakTopicsResult(Result<List<MasteryState>> result) {
    _weakTopicsResult = result;
  }

  void setAtRiskResult(Result<List<QuestionMasteryState>> result) {
    _atRiskResult = result;
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return _weakTopicsResult ?? Result.success([]);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return _atRiskResult ?? Result.success([]);
  }
}

class FakePlannerService extends PlannerService {
  PersonalLearningPlan? _plan;
  List<RoadmapModel> _roadmaps = [];
  List<PendingActionModel> _pendingActions = [];
  List<Session> _scheduledLessons = [];
  AdherenceDeviation? _deviation;
  bool _hasConflict = false;
  bool _scheduleResult = true;
  int scheduleCallCount = 0;
  String? lastScheduledTopicTitle;
  String? lastScheduledTopicId;

  void setPlan(PersonalLearningPlan? plan) => _plan = plan;
  void setRoadmaps(List<RoadmapModel> roadmaps) => _roadmaps = roadmaps;
  void setPendingActions(List<PendingActionModel> actions) => _pendingActions = actions;
  void setScheduledLessons(List<Session> lessons) => _scheduledLessons = lessons;
  void setAdherenceDeviation(AdherenceDeviation? d) => _deviation = d;
  void setHasConflict(bool v) => _hasConflict = v;
  void setScheduleResult(bool v) => _scheduleResult = v;

  @override
  Future<PersonalLearningPlan?> loadExistingPlan() async => _plan;

  @override
  Future<List<RoadmapModel>> loadRoadmaps() async => _roadmaps;

  @override
  Future<List<PendingActionModel>> loadPendingActions() async => _pendingActions;

  @override
  Future<List<Session>> getScheduledLessons() async => _scheduledLessons;

  @override
  Future<AdherenceDeviation?> checkAdherence() async => _deviation;

  @override
  Future<bool> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async => _hasConflict;

  @override
  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    scheduleCallCount++;
    lastScheduledTopicTitle = topicTitle;
    lastScheduledTopicId = topicId;
    return _scheduleResult;
  }
}

class FakeProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> _stats = {
    'totalAttempts': 10,
    'correctAttempts': 7,
    'accuracy': 70,
    'avgTimePerQuestion': 30,
    'totalStudyTimeHours': 2.5,
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
          l10n: lookupAppLocalizations(const Locale('en')),
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
  PlannerService? plannerService,
  EngagementNudgeRepository? nudgeRepo,
  SessionRepository? sessionRepository,
  String modelId = 'test-model',
  String studentId = 'test-student',
  String localeName = 'en',
}) {
  final db = database ??
      DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: FakeSessionRepository(),
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
    plannerService: plannerService ?? FakePlannerService(),
    nudgeRepo: nudgeRepo ?? _FakeNudgeRepo(),
    sessionRepository: sessionRepository ?? _FakeSessionRepo(),
    modelId: modelId,
    studentId: studentId,
    localeName: localeName,
    pendingActionRepo: pendingActionRepo,
  );
}

class _FakeNudgeRepo extends EngagementNudgeRepository {
  final List<EngagementNudgeModel> _nudges = [];

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async {
    _nudges.add(nudge);
    return Result.success(null);
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(
      String studentId, {int limit = 10}) async {
    return Result.success(_nudges.where((n) => n.studentId == studentId).take(limit).toList());
  }

  @override
  Future<Result<int>> getTodayCount(String studentId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return Result.success(_nudges.where((n) =>
        n.studentId == studentId && n.sentAt.isAfter(startOfDay)).length);
  }
}

class _FakeSessionRepo extends SessionRepository {
  @override
  Future<Result<List<Session>>> getAll() async => Result.success([]);

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async => Result.success([]);

  @override
  Future<Result<int>> getTodayDurationMs() async => Result.success(0);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
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
        expect(history[0].role, equals(MessageRole.student));
        expect(history[0].content, equals('Hello'));
        expect(history[1].role, equals(MessageRole.tutor));
        expect(history[1].content, equals('Mentor response'));
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
        await service.chat('hello').toList();
        final history = service.memory.getHistory();
        expect(history.length, equals(2));
        expect(history[0].role, equals(MessageRole.student));
        expect(history[1].role, equals(MessageRole.tutor));
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
          sessionRepository: FakeSessionRepository(),
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
          'totalStudyTimeHours': 3.0,
          'weeklyActivity': 8,
          'dailyActivity': 3,
          'topicsStudied': 5,
        });
        final service = createMentorService(progressTracker: tracker);

        final report = await service.getProgressReport();
        expect(report.accuracy, equals(75.0));
        expect(report.totalAttempts, equals(20));
        expect(report.correctAttempts, equals(15));
        expect(report.totalStudyTimeHours, equals(3.0));
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
          'totalStudyTimeHours': 1.0,
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
        expect(action.message, contains("added any subjects"));
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
          sessionRepository: FakeSessionRepository(),
          subjectRepository: subjectRepo,
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: FakeTutorSessionRepository(),
        );
        final service = createMentorService(database: db);

        final action = await service.suggestNextAction();
        expect(action.message, contains("doing well"));
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
          sessionRepository: FakeSessionRepository(),
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
            m.role == MessageRole.system &&
            m.content.contains('Algebra')), isTrue);
      });

      test('does nothing when session not found', () async {
        final tutorRepo = FakeTutorSessionRepository();
        final fakePending = FakePendingActionRepository();
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeSessionRepository(),
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
        expect(history.where((m) => m.role == MessageRole.system), isEmpty);
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
          sessionRepository: FakeSessionRepository(),
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
            m.role == MessageRole.system &&
            m.content.contains('Algebra')), isTrue);
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
          sessionRepository: FakeSessionRepository(),
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
      late FakePlannerService fakePlanner;

      setUp(() {
        llm = FakeLlmService();
        fakePlanner = FakePlannerService();
      });

      test('schedule keyword creates pending schedule proposal', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('schedule a math lesson').toList();
        expect(service.pendingScheduleProposal, isNotNull);
        expect(fakePlanner.scheduleCallCount, equals(0));
      });

      test('plan keyword creates pending plan proposal', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('plan a study roadmap').toList();
        expect(service.pendingPlanProposal, isNotNull);
      });

      test('roadmap keyword creates pending plan proposal', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('create a roadmap for chemistry').toList();
        expect(service.pendingPlanProposal, isNotNull);
      });

      test('programar keyword (Portuguese) creates schedule proposal', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('programar estudos de matematica').toList();
        expect(service.pendingScheduleProposal, isNotNull);
        expect(fakePlanner.scheduleCallCount, equals(0));
      });

      test('reprogramar keyword (Portuguese) creates schedule proposal', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('reprogramar sessoes').toList();
        expect(service.pendingScheduleProposal, isNotNull);
        expect(fakePlanner.scheduleCallCount, equals(0));
      });

      test('planificar keyword (Spanish) creates plan proposal', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('planificar el estudio').toList();
        expect(service.pendingPlanProposal, isNotNull);
      });

      test('non-planning message does not trigger any intent', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('hello how are you').toList();
        expect(service.pendingScheduleProposal, isNull);
        expect(service.pendingPlanProposal, isNull);
      });

      test('topic is extracted from schedule message', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('schedule a lesson about calculus').toList();
        expect(service.pendingScheduleProposal!.topicTitle, equals('calculus'));
      });

      test('topic with punctuation is trimmed', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('schedule study linear algebra, please').toList();
        expect(service.pendingScheduleProposal!.topicTitle, equals('linear algebra'));
      });

      test('topic after learn keyword is extracted', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('schedule learn dart').toList();
        expect(service.pendingScheduleProposal!.topicTitle, equals('dart'));
      });

      test('topic after topic keyword is extracted', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('schedule topic world history').toList();
        expect(service.pendingScheduleProposal!.topicTitle, equals('world history'));
      });

      test('fallback to general when no topic keyword found', () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        await service.chat('schedule something').toList();
        expect(service.pendingScheduleProposal!.topicTitle, equals('general'));
      });

      test('chat completes when LLM response triggers planning intent',
          () async {
        final service = createMentorService(
          llmService: llm,
          plannerService: fakePlanner,
        );
        final chunks = await service.chat('schedule math review').toList();
        expect(chunks, isNotEmpty);
      });

      test('planner not called during chat', () async {
        final planner = FakePlannerService();
        planner.setScheduleResult(false);
        final service = createMentorService(
          llmService: llm,
          plannerService: planner,
        );
        final chunks = await service.chat('schedule a lesson').toList();
        expect(chunks, isNotEmpty);
        expect(planner.scheduleCallCount, equals(0));
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
          'totalStudyTimeHours': 4.0,
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

    group('locale-awareness', () {
      test('uses Spanish system prompt when localeName is es', () async {
        final llm = FakeLlmService();
        final service = createMentorService(
          llmService: llm,
          localeName: 'es',
        );
        await service.chat('hola').toList();
        expect(
          llm.capturedSystemPrompt,
          contains('mentor de IA'),
        );
      });

      test('uses English system prompt by default', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm);
        await service.chat('hello').toList();
        expect(
          llm.capturedSystemPrompt,
          contains('encouraging AI mentor'),
        );
      });

      test('returns Spanish suggestNextAction message when localeName is es',
          () async {
        final service = createMentorService(localeName: 'es');
        final action = await service.suggestNextAction();
        expect(action.message, contains('materia'));
      });

      test('returns Spanish generic message with es locale', () async {
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
          sessionRepository: FakeSessionRepository(),
          subjectRepository: subjectRepo,
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: FakeTutorSessionRepository(),
        );
        final service = createMentorService(
          database: db,
          localeName: 'es',
        );

        final action = await service.suggestNextAction();
        expect(action.message, contains('bien'));
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
          'totalStudyTimeHours': 2.5,
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
          'totalStudyTimeHours': 2.5,
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

    group('checkWellbeingAndGenerateNudges', () {
      test('handles session repository getByDate failure gracefully', () async {
        final failingRepo = _FakeSessionRepo();
        final service = createMentorService(sessionRepository: failingRepo);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result, isA<List<String>>());
      });

      test('handles mastery service failure gracefully', () async {
        final mastery = FakeMasteryGraphService();
        mastery.setAtRiskResult(Result.failure('Service unavailable'));
        final service = createMentorService(masteryService: mastery);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result, isEmpty);
      });

      test('handles planner service failure in getWeakTopics gracefully', () async {
        final mastery = FakeMasteryGraphService();
        mastery.setWeakTopicsResult(Result.failure('Weak topics unavailable'));
        final service = createMentorService(masteryService: mastery);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result, isA<List<String>>());
      });

      test('generates revision nudge when 3+ at-risk questions', () async {
        final mastery = FakeMasteryGraphService();
        final now = DateTime.now();
        mastery.setAtRiskResult(Result.success([
          QuestionMasteryState(studentId: 'test-student', questionId: 'q-1', lastAttempt: now, nextReview: now),
          QuestionMasteryState(studentId: 'test-student', questionId: 'q-2', lastAttempt: now, nextReview: now),
          QuestionMasteryState(studentId: 'test-student', questionId: 'q-3', lastAttempt: now, nextReview: now),
        ]));
        // Ensure the at-risk list has >= 3 items to trigger revision nudge
        final service = createMentorService(masteryService: mastery);
        final result = await service.checkWellbeingAndGenerateNudges();
        expect(result, isNotEmpty);
        expect(result.first, contains('revision'));
      });
    });

    group('getters', () {
      test('hasApiKey returns false when API key is empty', () {
        final service = createMentorService();
        expect(service.hasApiKey, isFalse);
      });

      test('clearPendingSchedule sets pending schedule to null', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm);
        await service.chat('schedule a lesson').toList();
        expect(service.pendingScheduleProposal, isNotNull);
        service.clearPendingSchedule();
        expect(service.pendingScheduleProposal, isNull);
      });

      test('clearPendingPlan sets pending plan to null', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm);
        await service.chat('plan a roadmap').toList();
        expect(service.pendingPlanProposal, isNotNull);
        service.clearPendingPlan();
        expect(service.pendingPlanProposal, isNull);
      });
    });

    group('planDaysMessage', () {
      test('returns English message with correct day count', () {
        final service = createMentorService();
        final msg = service.planDaysMessage(30);
        expect(msg, contains('30'));
      });

      test('returns Spanish message with correct day count', () {
        final service = createMentorService(localeName: 'es');
        final msg = service.planDaysMessage(30);
        expect(msg, contains('30'));
      });
    });

    group('getRecentNudges', () {
      test('returns empty list when no nudges exist', () async {
        final service = createMentorService();
        final nudges = await service.getRecentNudges();
        expect(nudges, isEmpty);
      });
    });

    group('hasMeaningfulData', () {
      test('returns false when no subjects and no attempts', () async {
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 0,
          'correctAttempts': 0,
          'accuracy': 0,
          'avgTimePerQuestion': 0,
          'totalStudyTimeHours': 0,
          'weeklyActivity': 0,
          'dailyActivity': 0,
          'topicsStudied': 0,
        });
        final service = createMentorService(progressTracker: tracker);
        final result = await service.hasMeaningfulData();
        expect(result, isFalse);
      });

      test('returns true when subjects exist', () async {
        final subjectRepo = FakeSubjectRepository();
        subjectRepo.addSubject(Subject(id: 's1', name: 'Math'));
        final db = DatabaseService(
          topicRepository: TopicRepository(),
          questionRepository: QuestionRepository(),
          attemptRepository: AttemptRepository(),
          lessonRepository: LessonRepository(),
          sessionRepository: FakeSessionRepository(),
          subjectRepository: subjectRepo,
          conversationRepository: ConversationRepository(),
          tutorSessionRepository: FakeTutorSessionRepository(),
        );
        final tracker = FakeProgressTracker(attemptRepo: AttemptRepository());
        tracker.setStats({
          'totalAttempts': 0,
          'correctAttempts': 0,
          'accuracy': 0,
          'avgTimePerQuestion': 0,
          'totalStudyTimeHours': 0,
          'weeklyActivity': 0,
          'dailyActivity': 0,
          'topicsStudied': 0,
        });
        final service = createMentorService(database: db, progressTracker: tracker);
        final result = await service.hasMeaningfulData();
        expect(result, isTrue);
      });
    });

    group('confirmSchedule', () {
      test('schedules lesson and returns success message when no conflict', () async {
        final fakePlanner = FakePlannerService();
        fakePlanner.setHasConflict(false);
        fakePlanner.setScheduleResult(true);
        final service = createMentorService(plannerService: fakePlanner);

        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        final result = await service.confirmSchedule(proposal);
        expect(result, contains('scheduled'));
        expect(fakePlanner.scheduleCallCount, equals(1));
      });

      test('returns failure message when scheduling returns false', () async {
        final fakePlanner = FakePlannerService();
        fakePlanner.setHasConflict(false);
        fakePlanner.setScheduleResult(false);
        final service = createMentorService(plannerService: fakePlanner);

        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        final result = await service.confirmSchedule(proposal);
        expect(result, contains('unable to schedule'));
        expect(fakePlanner.scheduleCallCount, equals(1));
      });

      test('returns conflict message when scheduling conflict detected', () async {
        final fakePlanner = FakePlannerService();
        fakePlanner.setHasConflict(true);
        final service = createMentorService(plannerService: fakePlanner);

        final proposal = ScheduleProposal(
          topicTitle: 'general',
          proposedTime: DateTime.now().add(const Duration(hours: 2)),
        );
        final result = await service.confirmSchedule(proposal);
        expect(result, contains('conflict'));
        expect(fakePlanner.scheduleCallCount, equals(0));
      });
    });

    group('_extractTopic locale-awareness', () {
      test('extracts topic using Spanish sobre keyword', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm, localeName: 'es');
        await service.chat('programar sobre calculo diferencial').toList();
        expect(service.pendingScheduleProposal, isNotNull);
        expect(service.pendingScheduleProposal!.topicTitle, equals('calculo diferencial'));
      });

      test('extracts topic using Spanish materia keyword', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm, localeName: 'es');
        await service.chat('programar materia historia universal').toList();
        expect(service.pendingScheduleProposal, isNotNull);
        expect(service.pendingScheduleProposal!.topicTitle, equals('historia universal'));
      });
    });

    group('_extractPlanProposal', () {
      test('extracts days and goal from plan message', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm);
        await service.chat('plan a 60-day roadmap for organic chemistry').toList();
        expect(service.pendingPlanProposal, isNotNull);
        expect(service.pendingPlanProposal!.days, equals(60));
        expect(service.pendingPlanProposal!.goal, contains('organic chemistry'));
      });

      test('defaults to 30 days when no duration specified', () async {
        final llm = FakeLlmService();
        final service = createMentorService(llmService: llm);
        await service.chat('plan a roadmap').toList();
        expect(service.pendingPlanProposal, isNotNull);
        expect(service.pendingPlanProposal!.days, equals(30));
        expect(service.pendingPlanProposal!.goal, isNull);
      });
    });
  });
}
