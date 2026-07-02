import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';

class FakeMasteryGraphRepository extends MasteryGraphRepository {
  final Map<String, MasteryState> _masteryStates = {};
  final List<TopicDependency> _dependencies = [];

  void addMasteryState(MasteryState state) {
    _masteryStates['${state.studentId}_${state.topicId}'] = state;
  }

  void addDependency(TopicDependency dep) => _dependencies.add(dep);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success(
      _masteryStates.values.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success(_dependencies);
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    final key = '${studentId}_$topicId';
    if (_masteryStates.containsKey(key)) {
      return Result.success(_masteryStates[key]!);
    }
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }
}

class FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(_topics[id]);

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async {
    return Result.success(_topics.values.where((t) => t.subjectId == subjectId).toList());
  }
}

class FakePlanRepository extends PlanRepository {
  PersonalLearningPlan? _plan;
  bool throwOnLoad = false;
  bool throwOnSave = false;

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async {
    if (throwOnLoad) throw Exception('load plan error');
    return Result.success(_plan);
  }

  @override
  Future<Result<void>> savePlan(PersonalLearningPlan plan) async {
    if (throwOnSave) throw Exception('save plan error');
    _plan = plan;
    return Result.success(null);
  }

  @override
  Future<Result<bool>> hasPlan(String studentId) async => Result.success(_plan != null);

  @override
  Future<Result<List<PersonalLearningPlan>>> getAllPlans() async => Result.success(_plan != null ? [_plan!] : []);
}

class FakeRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _roadmaps = {};

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> saveRoadmap(RoadmapModel roadmap) async {
    _roadmaps[roadmap.id] = roadmap;
    return Result.success(null);
  }

  @override
  Future<Result<RoadmapModel?>> loadRoadmap(String id) async => Result.success(_roadmaps[id]);

  @override
  Future<Result<List<RoadmapModel>>> getRoadmapsByStudent(String studentId) async {
    return Result.success(_roadmaps.values.where((r) => r.studentId == studentId).toList());
  }

  @override
  Future<Result<List<RoadmapModel>>> getAllRoadmaps() async => Result.success(_roadmaps.values.toList());

  @override
  Future<Result<void>> deleteRoadmap(String id) async {
    _roadmaps.remove(id);
    return Result.success(null);
  }
}

class FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _sessions = {};
  bool throwOnGet = false;
  bool throwOnSave = false;
  bool throwOnGetAll = false;
  bool returnFailureOnGetAll = false;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Session session) async {
    if (throwOnSave) throw Exception('save session error');
    _sessions[session.id] = session;
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    if (throwOnGet) throw Exception('get session error');
    return Result.success(_sessions[id]);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    if (returnFailureOnGetAll) return Result.failure('get all failure');
    if (throwOnGetAll) throw Exception('get all sessions error');
    return Result.success(_sessions.values.toList());
  }
}

class FakePendingActionRepository extends PendingActionRepository {
  final Map<String, PendingActionModel> _actions = {};
  bool throwOnMarkCompleted = false;
  bool throwOnMarkRejected = false;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<PendingActionModel>>> getPending(String studentId) async {
    return Result.success(_actions.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList());
  }

  @override
  Future<Result<PendingActionModel?>> get(String id) async => Result.success(_actions[id]);

  @override
  Future<Result<void>> markCompleted(String id) async {
    if (throwOnMarkCompleted) throw Exception('mark completed error');
    final action = _actions[id];
    if (action != null) {
      _actions[id] = action.copyWith(status: 'completed');
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> markRejected(String id) async {
    if (throwOnMarkRejected) throw Exception('mark rejected error');
    final action = _actions[id];
    if (action != null) {
      _actions[id] = action.copyWith(status: 'rejected');
    }
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(PendingActionModel action) async {
    _actions[action.id] = action;
    return Result.success(null);
  }

  void addAction(PendingActionModel action) => _actions[action.id] = action;
}

class FakeAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];
  bool throwOnGetByStudent = false;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<PlanAdherenceModel>>> getByStudent(String studentId) async {
    if (throwOnGetByStudent) throw Exception('get by student error');
    return Result.success(_records.where((r) => r.studentId == studentId).toList());
  }

  @override
  Future<Result<void>> create(PlanAdherenceModel model) async {
    _records.add(model);
    return Result.success(null);
  }
}

class FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  FakePlanAdherenceOrchestrator() : super();

  bool returnFailureForAdherence = false;
  bool returnFailureForCheck = false;
  PersonalLearningPlan? _regeneratedPlan;

  void setRegeneratedPlan(PersonalLearningPlan p) => _regeneratedPlan = p;

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    if (returnFailureForCheck) return Result.failure('adherence check failed');
    return Result.success(const AdherenceDeviation());
  }

  @override
  Future<Result<Map<String, dynamic>>> getAdherenceReport(String studentId) async {
    if (returnFailureForAdherence) return Result.failure('report failed');
    return Result.success({'totalDays': 0, 'averageAdherence': 1.0, 'lowAdherenceDays': 0, 'weeklyTrend': <double>[]});
  }

  @override
  Future<Result<PersonalLearningPlan?>> suggestRegeneration({required String studentId, double? adjustmentFactor}) async {
    if (_regeneratedPlan != null) return Result.success(_regeneratedPlan);
    return Result.success(null);
  }

  @override
  Future<Result<void>> recordActivity({required String studentId, required int actualMinutes, int actualQuestions = 0, String? planId}) async {
    return Result.success(null);
  }
}

class ThrowingInitPlanRepository extends PlanRepository {
  @override
  Future<Result<void>> init() async => throw Exception('init failed');

  @override
  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async => Result.success(null);

  @override
  Future<Result<void>> savePlan(PersonalLearningPlan plan) async => Result.success(null);

  @override
  Future<Result<bool>> hasPlan(String studentId) async => Result.success(false);

  @override
  Future<Result<List<PersonalLearningPlan>>> getAllPlans() async => Result.success([]);
}

class StubLessonAgentService implements LessonAgentService {
  final Future<Lesson?> Function(String subjectId, String topicId, String topicTitle, String localeName) _generate;

  StubLessonAgentService(this._generate);

  @override
  Future<Lesson?> generateLesson({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    String localeName = 'en',
  }) {
    return _generate(subjectId, topicId, topicTitle, localeName);
  }

  @override
  Future<Lesson?> generateLessonFromSource({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    required String sourceContent,
    String localeName = 'en',
  }) async => null;
}

PlannerService createPlannerService({
  PlanRepository? planRepo,
  MasteryGraphService? masteryService,
  MasteryGraphRepository? repository,
  TopicRepository? topicRepository,
  RoadmapRepository? roadmapRepo,
  PersonalLearningPlanService? planService,
  SessionRepository? sessionRepo,
  PendingActionRepository? pendingActionRepo,
  PlanAdherenceOrchestrator? planOrchestrator,
  SyllabusResolver? syllabusResolver,
  PlanAdherenceRepository? adherenceRepo,
  LessonAgentService? lessonAgentService,
  String? fixedStudentId,
}) {
  return PlannerService(
    planRepo: planRepo,
    masteryService: masteryService,
    repository: repository,
    topicRepository: topicRepository,
    roadmapRepo: roadmapRepo,
    planService: planService,
    sessionRepo: sessionRepo,
    pendingActionRepo: pendingActionRepo,
    planOrchestrator: planOrchestrator,
    syllabusResolver: syllabusResolver,
    adherenceRepo: adherenceRepo,
    lessonAgentService: lessonAgentService,
    fixedStudentId: fixedStudentId ?? 'test-student',
  );
}
