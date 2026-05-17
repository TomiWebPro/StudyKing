import 'dart:async';

import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';

class FakePlanRepository extends PlanRepository {
  final Map<String, PersonalLearningPlan> _storage = {};
  bool failOnInit = false;

  void addPlan(PersonalLearningPlan plan) {
    _storage[plan.studentId] = plan;
  }

  @override
  Future<void> init() async {
    if (failOnInit) throw Exception('Init failed');
  }

  @override
  Future<void> savePlan(PersonalLearningPlan plan) async {
    _storage[plan.studentId] = plan;
  }

  @override
  Future<PersonalLearningPlan?> loadPlan(String studentId) async {
    return _storage[studentId];
  }

  @override
  Future<bool> hasPlan(String studentId) async {
    return _storage.containsKey(studentId);
  }

  @override
  Future<List<PersonalLearningPlan>> getAllPlans() async {
    return _storage.values.toList();
  }

  @override
  Future<void> deletePlan(String studentId) async {
    _storage.remove(studentId);
  }
}

class FakeMasteryGraphRepository extends MasteryGraphRepository {
  final Map<String, MasteryState> _masteryStates = {};
  bool failOnGenerate = false;
  Completer<Result<List<MasteryState>>>? generateCompleter;

  FakeMasteryGraphRepository()
      : super(
          masteryStateRepo: null,
          questionMasteryRepo: null,
          topicDependencyRepo: null,
          questionEvaluationRepo: null,
        );

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    if (generateCompleter != null) {
      return generateCompleter!.future;
    }
    if (failOnGenerate) {
      return Result.failure('Simulated generation error');
    }
    return Result.success(
      _masteryStates.values.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success([]);
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final key = '${studentId}_$topicId';
    if (_masteryStates.containsKey(key)) {
      return Result.success(_masteryStates[key]!);
    }
    final state = MasteryState.initial(studentId: studentId, topicId: topicId);
    _masteryStates[key] = state;
    return Result.success(state);
  }
}

class FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};
  bool shouldThrow = false;

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<void> init() async {}

  @override
  Future<Result<Topic?>> get(String id) async {
    if (shouldThrow) throw Exception('Topic error');
    return Result.success(_topics[id]);
  }

  @override
  Future<Result<List<Topic>>> getAll() async =>
      Result.success(_topics.values.toList());
}

class FakeRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _storage = {};
  bool failOnInit = false;
  bool failOnGet = false;
  bool failOnSave = false;
  Completer<void>? loadCompleter;

  @override
  Future<void> init() async {
    if (failOnInit) throw Exception('Init failed');
    if (loadCompleter != null) await loadCompleter!.future;
  }

  @override
  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    if (failOnSave) throw Exception('Save failed');
    _storage[roadmap.id] = roadmap;
  }

  @override
  Future<RoadmapModel?> loadRoadmap(String id) async {
    return _storage[id];
  }

  @override
  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    if (loadCompleter != null) await loadCompleter!.future;
    if (failOnGet) throw Exception('Get failed');
    return _storage.values
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<RoadmapModel>> getAllRoadmaps() async {
    return _storage.values.toList();
  }

  @override
  Future<void> deleteRoadmap(String id) async {
    _storage.remove(id);
  }
}

class FakeTutorSessionRepository extends TutorSessionRepository {
  final Map<String, TutorSession> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> saveSession(TutorSession session) async {
    _storage[session.id] = session;
  }

  @override
  Future<TutorSession?> getSession(String id) async {
    return _storage[id];
  }

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    return _storage.values
        .where((s) => s.studentId == studentId)
        .toList();
  }
}

class FakePendingActionRepository extends PendingActionRepository {
  final Map<String, PendingActionModel> _storage = {};

  void addAction(PendingActionModel action) {
    _storage[action.id] = action;
  }

  @override
  Future<void> init() async {}

  @override
  Future<List<PendingActionModel>> getPending(String studentId) async {
    return _storage.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList();
  }

  @override
  Future<Result<PendingActionModel?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<void> markCompleted(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'completed');
    }
  }

  @override
  Future<void> markRejected(String id) async {
    final action = _storage[id];
    if (action != null) {
      _storage[id] = action.copyWith(status: 'rejected');
    }
  }
}

class FakePlanAdapter extends PlanAdapter {
  FakePlanAdapter()
      : super(
          adherenceRepository: null,
          planRepository: null,
          planService: null,
          masteryService: null,
          l10n: null,
        );

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    return Result.success(const AdherenceDeviation());
  }

  @override
  Future<Result<Map<String, dynamic>>> getAdherenceReport(String studentId) async {
    return Result.success({'totalDays': 0, 'averageAdherence': 1.0, 'lowAdherenceDays': 0, 'weeklyTrend': <double>[]});
  }

  @override
  Future<void> recordFromFocusSession({required String studentId, required int actualMinutes, String? planId}) async {}

  @override
  Future<void> recordFromPracticeSession({required String studentId, required int actualQuestions, required int actualMinutes, String? planId}) async {}

  @override
  Future<void> recordFromTutorSession({required String studentId, required int actualMinutes, String? planId}) async {}

  @override
  Future<Result<PersonalLearningPlan?>> suggestRegeneration({required String studentId, double? adjustmentFactor}) async {
    return Result.success(null);
  }
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];
  bool throwOnSave = false;
  bool throwOnDelete = false;

  FakeSessionRepository({List<Session>? seed}) {
    if (seed != null) {
      sessions.addAll(seed);
    }
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(List.from(sessions));
  }

  @override
  Future<Result<void>> save(Session session) async {
    if (throwOnSave) throw Exception('save failed');
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (throwOnDelete) throw Exception('delete failed');
    sessions.removeWhere((s) => s.id == id);
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    try {
      final session = sessions.where((s) => s.id == id).firstOrNull;
      return Result.success(session);
    } catch (_) {
      return Result.success(null);
    }
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    final allResult = await getAll();
    if (allResult.isFailure) return Result.failure(allResult.error);
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return Result.success(allResult.data!
        .where((s) =>
            s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            s.startTime.isBefore(end))
        .toList());
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    final allResult = await getAll();
    if (allResult.isFailure) return Result.failure(allResult.error);
    return Result.success(
      allResult.data!.where((s) => s.studentId == studentId).toList(),
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
}

class FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];
  bool throwOnGet = false;

  @override
  Future<void> init() async {}

  void addAttempt(StudentAttempt attempt) {
    _attempts.add(attempt);
  }

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    if (throwOnGet) throw Exception('AttemptRepository error');
    return _attempts.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<List<StudentAttempt>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    return _attempts
        .where((a) => a.studentId == studentId && a.subjectId == subjectId)
        .toList();
  }

  @override
  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    return _attempts.where((a) => a.questionId == questionId).toList();
  }

  @override
  Future<List<StudentAttempt>> getBySubject(String subjectId) async {
    return _attempts.where((a) => a.subjectId == subjectId).toList();
  }

  @override
  Future<Map<String, dynamic>> getSubjectStats(String subjectId) async {
    final attempts = await getBySubject(subjectId);
    final correct = attempts.where((a) => a.isCorrect).length;
    return {
      'total': attempts.length,
      'correct': correct,
      'incorrect': attempts.length - correct,
      'accuracy': attempts.isNotEmpty ? correct / attempts.length : 0.0,
    };
  }

  @override
  Future<void> create(StudentAttempt attempt) async {
    _attempts.add(attempt);
  }
}

class FakeEngagementNudgeRepository extends EngagementNudgeRepository {
  final List<EngagementNudgeModel> nudges = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> create(EngagementNudgeModel nudge) async {
    nudges.add(nudge);
  }

  @override
  Future<List<EngagementNudgeModel>> getByStudent(String studentId) async {
    return nudges.where((n) => n.studentId == studentId).toList();
  }

  @override
  Future<List<EngagementNudgeModel>> getRecentByStudent(
    String studentId, {
    int limit = 10,
  }) async {
    return nudges.where((n) => n.studentId == studentId).take(limit).toList();
  }

  @override
  Future<int> getTodayCount(String studentId) async {
    return nudges.where((n) => n.studentId == studentId).length;
  }

  @override
  Future<List<EngagementNudgeModel>> getUnactedByStudent(
      String studentId) async {
    return nudges
        .where((n) => n.studentId == studentId && !n.wasActedUpon)
        .toList();
  }

  @override
  Future<List<EngagementNudgeModel>> getByType(
      String studentId, String nudgeType) async {
    return nudges
        .where((n) => n.studentId == studentId && n.nudgeType == nudgeType)
        .toList();
  }

  @override
  Future<void> markActedUpon(String id) async {
    final idx = nudges.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      nudges[idx] = nudges[idx].copyWith(
        wasActedUpon: true,
        actedUponAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteOld(int daysOld) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    nudges.removeWhere((n) => n.sentAt.isBefore(cutoff));
  }
}

class FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions = [];

  FakeQuestionRepository({List<Question>? seed}) {
    if (seed != null) {
      _questions.addAll(seed);
    }
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async =>
      Result.success(List.from(_questions));

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(
      _questions.where((q) => q.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<Result<List<Question>>> getByTopic(String topicId) async {
    return Result.success(
      _questions.where((q) => q.topicId == topicId).toList(),
    );
  }

  @override
  Future<Result<void>> create(Question question) async {
    _questions.add(question);
    return Result.success(null);
  }
}

/// Fake for PlannerService used across mentor and planner tests.
class FakeStudentIdService extends StudentIdService {
  String _studentId = 'test-student';
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  String getStudentId() => _studentId;

  @override
  void setStudentId(String id) {
    _studentId = id;
  }
}

class FakePlannerService {
  bool loadExistingPlanCalled = false;
  bool loadRoadmapsCalled = false;
  bool loadPendingActionsCalled = false;
  bool getScheduledLessonsCalled = false;
  bool checkAdherenceCalled = false;
  bool hasSchedulingConflictCalled = false;
  bool scheduleLessonCalled = false;

  Future<PersonalLearningPlan?> loadExistingPlan(String studentId) async {
    loadExistingPlanCalled = true;
    return null;
  }

  Future<List<RoadmapModel>> loadRoadmaps(String studentId) async {
    loadRoadmapsCalled = true;
    return [];
  }

  Future<List<PendingActionModel>> loadPendingActions(String studentId) async {
    loadPendingActionsCalled = true;
    return [];
  }

  Future<List<Session>> getScheduledLessons(String studentId) async {
    getScheduledLessonsCalled = true;
    return [];
  }

  Future<AdherenceDeviation?> checkAdherence(String studentId) async {
    checkAdherenceCalled = true;
    return null;
  }

  Future<bool> hasSchedulingConflict(String studentId, DateTime start, DateTime end) async {
    hasSchedulingConflictCalled = true;
    return false;
  }

  Future<bool> scheduleLesson(String studentId, Map<String, dynamic> lesson) async {
    scheduleLessonCalled = true;
    return false;
  }
}

class FakeMasteryGraphService {
  bool getWeakTopicsCalled = false;
  bool getAtRiskQuestionsCalled = false;

  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    getWeakTopicsCalled = true;
    return Result.success([]);
  }

  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(String studentId) async {
    getAtRiskQuestionsCalled = true;
    return Result.success([]);
  }
}

class FakeProgressTracker {
  bool getOverallStatsCalled = false;
  bool getRecommendationsCalled = false;
  bool getBadgesCalled = false;

  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    getOverallStatsCalled = true;
    return {'accuracy': 0.0, 'totalAttempts': 0};
  }

  Future<List<Map<String, dynamic>>> getRecommendations(String studentId) async {
    getRecommendationsCalled = true;
    return [];
  }

  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    getBadgesCalled = true;
    return [];
  }
}
