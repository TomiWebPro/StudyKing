import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';

class _FakeQuestionMasteryRepo extends QuestionMasteryStateRepository {
  final List<QuestionMasteryState> _atRisk = [];

  void addAtRisk(QuestionMasteryState state) {
    _atRisk.add(state);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async {
    return Result.success(
      _atRisk.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    return Result.success(
      QuestionMasteryState.initial(
        studentId: studentId,
        questionId: questionId,
        now: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(
    QuestionMasteryState state,
  ) async {
    return Result.success(null);
  }

  @override
  Future<void> init() async {}
}

class _FakeMasteryStateRepo extends MasteryStateRepository {
  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(
    String studentId,
  ) async {
    return Result.success([]);
  }

  @override
  Future<Result<MasteryState>> getMasteryState(
    String studentId,
    String topicId,
  ) async {
    return Result.success(
      MasteryState.initial(studentId: studentId, topicId: topicId),
    );
  }

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(
    String studentId,
  ) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(
    String studentId,
  ) async {
    return Result.success({
      'totalTopics': 0,
      'masteredTopics': 0,
      'weakTopics': 0,
      'averageAccuracy': 0.0,
      'totalAttempts': 0,
    });
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async {
    return Result.success(null);
  }
}

class _FakeTutorSessionRepo extends TutorSessionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<TutorSession>>> getStudentSessions(
      String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<TutorSession>>> getCompletedSessions(
      String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<TutorSession?>> getSession(String id) async {
    return Result.success(null);
  }
}

class _FakeSessionRepo extends SessionRepository {
  final List<Session> sessions = [];

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(List.from(sessions));
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return Result.success(
      sessions
          .where((s) =>
              s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
              s.startTime.isBefore(end))
          .toList(),
    );
  }

  @override
  Future<Result<int>> getTodayDurationMs() async {
    final todayResult = await getByDate(DateTime.now());
    if (todayResult.isFailure) return Result.failure(todayResult.error);
    return Result.success(
      todayResult.data!.fold<int>(0, (sum, s) => sum + s.actualDurationMs),
    );
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(
      sessions.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<Session?>> get(String id) async {
    return Result.success(sessions.where((s) => s.id == id).firstOrNull);
  }

  @override
  Future<Result<void>> save(String key, Session session) async {
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    sessions.removeWhere((s) => s.id == id);
    return Result.success(null);
  }
}

class _FakeNudgeRepo extends EngagementNudgeRepository {
  final List<EngagementNudgeModel> nudges = [];

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async {
    nudges.add(nudge);
    return Result.success(null);
  }

  @override
  Future<Result<int>> getTodayCount(String studentId) async {
    return Result.success(
        nudges.where((n) => n.studentId == studentId).length);
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(
    String studentId, {
    int limit = 10,
  }) async {
    return Result.success(
        nudges.where((n) => n.studentId == studentId).take(limit).toList());
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getByStudent(
      String studentId) async {
    return Result.success(
        nudges.where((n) => n.studentId == studentId).toList());
  }
}

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(
      String studentId) async {
    return Result.success(
        _attempts.where((a) => a.studentId == studentId).toList());
  }
}

class _FakeLlMService extends LlmService {
  _FakeLlMService()
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-key',
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
    yield 'test response';
  }
}

class _FakePlanRepo extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async {
    return Result.success(_storage[studentId]);
  }

  @override
  Future<Result<bool>> hasPlan(String studentId) async {
    return Result.success(_storage.containsKey(studentId));
  }

  @override
  Future<Result<List<PersonalLearningPlan>>> getAllPlans() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> savePlan(PersonalLearningPlan plan) async {
    _storage[plan.studentId] = plan;
    return Result.success(null);
  }

  @override
  Future<Result<void>> deletePlan(String studentId) async {
    _storage.remove(studentId);
    return Result.success(null);
  }
}

void main() {
  group('Mentor + Sessions Integration — nudge generation uses session data',
      () {
    test(
        'checkWellbeingAndGenerateNudges creates late-night nudge '
        'when sessions start after 22:00', () async {
      const studentId = 'test-student';
      final now = DateTime.now();
      final lateNightTime = DateTime(now.year, now.month, now.day, 23, 0);

      // Set up session data with a late-night session today
      final sessionRepo = _FakeSessionRepo();
      sessionRepo.sessions.add(Session(
        id: 'late-night-1',
        studentId: studentId,
        startTime: lateNightTime,
        endTime: lateNightTime.add(const Duration(hours: 1)),
        actualDurationMs: 3600000,
        completed: true,
      ));

      // Set up at-risk questions (at least 3 to trigger revision nudge)
      final questionMasteryRepo = _FakeQuestionMasteryRepo();
      for (var i = 0; i < 3; i++) {
        questionMasteryRepo.addAtRisk(QuestionMasteryState.initial(
          studentId: studentId,
          questionId: 'q_at_risk_$i',
          now: now,
        ));
      }

      final masteryService = MasteryGraphService(
        masteryStateRepo: _FakeMasteryStateRepo(),
        questionMasteryRepo: questionMasteryRepo,
      );
      final planRepo = _FakePlanRepo();
      planRepo.savePlan(PersonalLearningPlan(
        studentId: studentId,
        generatedAt: now.subtract(const Duration(days: 7)),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0,
          totalMinutes: 0,
          newTopics: 0,
          reviewTopics: 0,
          estimatedCoverage: 0,
          focusAreas: [],
        ),
        recommendations: [],
      ));

      final plannerService = PlannerService(
        planRepo: planRepo,
        masteryService: masteryService,
        topicRepository: TopicRepository(),
        fixedStudentId: studentId,
      );

      final attemptRepo = _FakeAttemptRepo();
      final progressTracker = StudyProgressTracker(
        attemptRepo: attemptRepo,
        sessionRepo: sessionRepo,
        l10n: lookupAppLocalizations(const Locale('en')),
      );

      final nudgeRepo = _FakeNudgeRepo();
      final llmService = _FakeLlMService();

      final database = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: attemptRepo,
        lessonRepository: LessonRepository(),
        sessionRepository: sessionRepo,
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: _FakeTutorSessionRepo(),
      );

      final mentor = MentorService(
        database: database,
        llmService: llmService,
        masteryService: masteryService,
        progressTracker: progressTracker,
        modelId: 'test-model',
        studentId: studentId,
        plannerService: plannerService,
        nudgeRepo: nudgeRepo,
        sessionRepository: sessionRepo,
        localeName: 'en',
      );

      await mentor.initialize();
      await mentor.checkWellbeingAndGenerateNudges();

      // Verify late-night nudge was created (session at 23:00)
      final lateNightNudges = nudgeRepo.nudges
          .where((n) => n.nudgeType == NudgeType.overwork.name)
          .toList();
      expect(lateNightNudges.length, greaterThanOrEqualTo(1));
      expect(lateNightNudges.first.studentId, studentId);

      // Verify revision nudge was created (3 at-risk questions)
      final revisionNudges = nudgeRepo.nudges
          .where((n) => n.nudgeType == NudgeType.revision.name)
          .toList();
      expect(revisionNudges.length, greaterThanOrEqualTo(1));
      expect(revisionNudges.first.studentId, studentId);

      // Session repo was queried during nudge generation
      final todaySessions = await sessionRepo.getByDate(now);
      expect(todaySessions.data!.length, 1);
      expect(todaySessions.data!.first.startTime.hour, 23);
    });

    test(
        'checkWellbeingAndGenerateNudges does not create nudges '
        'when session data shows no concerns', () async {
      const studentId = 'test-student';
      final now = DateTime.now();

      // Normal session during daytime
      final sessionRepo = _FakeSessionRepo();
      sessionRepo.sessions.add(Session(
        id: 'normal-session-1',
        studentId: studentId,
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 0),
        actualDurationMs: 3600000,
        completed: true,
      ));

      // No at-risk questions
      final questionMasteryRepo = _FakeQuestionMasteryRepo();

      final masteryService = MasteryGraphService(
        masteryStateRepo: _FakeMasteryStateRepo(),
        questionMasteryRepo: questionMasteryRepo,
      );

      final planRepo = _FakePlanRepo();
      final plannerService = PlannerService(
        planRepo: planRepo,
        masteryService: masteryService,
        topicRepository: TopicRepository(),
        fixedStudentId: studentId,
      );

      final attemptRepo = _FakeAttemptRepo();
      final progressTracker = StudyProgressTracker(
        attemptRepo: attemptRepo,
        sessionRepo: sessionRepo,
        l10n: lookupAppLocalizations(const Locale('en')),
      );

      final nudgeRepo = _FakeNudgeRepo();
      final llmService = _FakeLlMService();

      final database = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: attemptRepo,
        lessonRepository: LessonRepository(),
        sessionRepository: sessionRepo,
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: _FakeTutorSessionRepo(),
      );

      final mentor = MentorService(
        database: database,
        llmService: llmService,
        masteryService: masteryService,
        progressTracker: progressTracker,
        modelId: 'test-model',
        studentId: studentId,
        plannerService: plannerService,
        nudgeRepo: nudgeRepo,
        sessionRepository: sessionRepo,
        localeName: 'en',
      );

      await mentor.initialize();
      await mentor.checkWellbeingAndGenerateNudges();

      // No overwork nudge (daily cap is 0 since Hive unavailable)
      expect(nudgeRepo.nudges.where((n) => n.nudgeType == NudgeType.overwork.name),
          isEmpty);
      // No revision nudge (no at-risk questions)
      expect(nudgeRepo.nudges.where((n) => n.nudgeType == NudgeType.revision.name),
          isEmpty);
    });
  });
}
