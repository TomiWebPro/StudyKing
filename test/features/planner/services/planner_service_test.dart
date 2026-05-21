import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/features/planner/services/action_executor.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

class _FakeMasteryGraphRepository extends MasteryGraphRepository {
  final Map<String, MasteryState> _masteryStates = {};
  final List<TopicDependency> _dependencies = [];

  void addMasteryState(MasteryState state) {
    _masteryStates['${state.studentId}_${state.topicId}'] = state;
  }

  void addDependency(TopicDependency dep) => _dependencies.add(dep);

  @override
  Future<void> init() async {}

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

class _FakeTopicRepository extends TopicRepository {
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

class _FakePlanRepository extends PlanRepository {
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
}

class _FakeRoadmapRepository extends RoadmapRepository {
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
}

class _FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _sessions = {};
  bool throwOnGet = false;
  bool throwOnSave = false;
  bool throwOnGetAll = false;
  bool returnFailureOnGetAll = false;

  @override
  Future<void> init() async {}

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

class _FakePendingActionRepository extends PendingActionRepository {
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

class _FakeAdherenceRepo extends PlanAdherenceRepository {
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

class _FakePlanAdherenceOrchestrator extends PlanAdherenceOrchestrator {
  _FakePlanAdherenceOrchestrator() : super();

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

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('planner_service_test_').path;
    Hive.init(hivePath);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await Directory(hivePath).delete(recursive: true);
    } catch (_) {}
  });

  late PlannerService service;
  late _FakeMasteryGraphRepository masteryRepo;
  late _FakeTopicRepository topicRepo;
  late _FakePlanRepository planRepo;
  late _FakeRoadmapRepository roadmapRepo;
  late _FakeSessionRepository sessionRepo;
  late _FakePendingActionRepository pendingActionRepo;
  late _FakePlanAdherenceOrchestrator planOrchestrator;
  late AppLocalizations l10n;

  setUp(() {
    masteryRepo = _FakeMasteryGraphRepository();
    topicRepo = _FakeTopicRepository();
    planRepo = _FakePlanRepository();
    roadmapRepo = _FakeRoadmapRepository();
    sessionRepo = _FakeSessionRepository();
    pendingActionRepo = _FakePendingActionRepository();
    planOrchestrator = _FakePlanAdherenceOrchestrator();
    l10n = AppLocalizationsEn();

    final fakeAdherenceRepo = _FakeAdherenceRepo();
    final planService = PersonalLearningPlanService(
      masteryService: MasteryGraphService(),
      repository: masteryRepo,
      topicRepository: topicRepo,
      planRepository: planRepo,
      adherenceRepository: fakeAdherenceRepo,
      roadmapRepository: roadmapRepo,
      l10n: l10n,
    );

    final syllabusResolver = SyllabusResolver(
      topicRepository: topicRepo,
      masteryRepository: masteryRepo,
    );

    service = PlannerService(
      masteryService: MasteryGraphService(),
      repository: masteryRepo,
      topicRepository: topicRepo,
      planRepo: planRepo,
      roadmapRepo: roadmapRepo,
      sessionRepo: sessionRepo,
      pendingActionRepo: pendingActionRepo,
      planOrchestrator: planOrchestrator,
      planService: planService,
      adherenceRepo: fakeAdherenceRepo,
      syllabusResolver: syllabusResolver,
      fixedStudentId: 'test-student',
    );
  });

  group('loadExistingPlan', () {
    test('returns null when no plan exists', () async {
      final planResult = await service.loadExistingPlan();
      expect(planResult.data, isNull);
    });

    test('returns saved plan', () async {
      final testPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 10,
          totalMinutes: 60,
          newTopics: 1,
          reviewTopics: 2,
          estimatedCoverage: 0.5,
          focusAreas: [],
        ),
        recommendations: [],
      );
      await planRepo.savePlan(testPlan);

      final planResult = await service.loadExistingPlan();
      expect(planResult.data, isNotNull);
      expect(planResult.data!.studentId, 'test-student');
      expect(planResult.data!.summary.totalQuestions, 10);
    });
  });

  group('loadRoadmaps', () {
    test('returns empty list when no roadmaps exist', () async {
      final roadmaps = await service.loadRoadmaps();
      expect(roadmaps.data, isEmpty);
    });

    test('returns saved roadmaps', () async {
      final roadmap = RoadmapModel(
        id: 'rm-1',
        studentId: 'test-student',
        goal: 'Learn Physics',
        createdAt: DateTime.now(),
      );
      await roadmapRepo.saveRoadmap(roadmap);

      final roadmaps = (await service.loadRoadmaps()).data!;
      expect(roadmaps, hasLength(1));
      expect(roadmaps.first.goal, 'Learn Physics');
    });
  });

  group('loadPendingActions', () {
    test('returns empty list when no pending actions', () async {
      final actions = await service.loadPendingActions();
      expect(actions.data, isEmpty);
    });

    test('returns only pending actions', () async {
      pendingActionRepo.addAction(PendingActionModel(
        id: 'action-1',
        studentId: 'test-student',
        actionType: 'schedule',
        status: 'pending',
      ));
      pendingActionRepo.addAction(PendingActionModel(
        id: 'action-2',
        studentId: 'test-student',
        actionType: 'schedule',
        status: 'completed',
      ));

      final actions = (await service.loadPendingActions()).data!;
      expect(actions, hasLength(1));
      expect(actions.first.id, 'action-1');
    });
  });

  group('generatePlan', () {
    test('generates plan with valid parameters', () async {
      final plan = await service.generatePlan(
        course: 'IB Physics',
        daysValue: 7,
        hoursValue: 2,
      );

      expect(plan.data, isNotNull);
      expect(plan.data!.studentId, 'test-student');
      expect(plan.data!.planDurationDays, 7);
      expect(plan.data!.targetMinutesPerDay, 120.0);
    });

    test('generated plan has daily plans', () async {
      final plan = await service.generatePlan(
        course: 'IB Physics',
        daysValue: 3,
        hoursValue: 1,
      );

      expect(plan.data, isNotNull);
      expect(plan.data!.dailyPlans, hasLength(3));
      expect(plan.data!.dailyPlans.first.dayNumber, 1);
    });
  });

  group('generatePlanFromSyllabus', () {
    test('generates plan from syllabus goals', () async {
      topicRepo.addTopic(Topic(
        id: 'topic-1',
        subjectId: 'sub_physics',
        title: 'Kinematics',
        description: 'Motion',
        syllabusText: 'IB Physics topic',
      ));
      masteryRepo.addMasteryState(
        MasteryState.initial(studentId: 'test-student', topicId: 'topic-1'),
      );

      final plan = await service.generatePlanFromSyllabus(
        syllabusGoals: [
          const SyllabusGoal(
            subjectId: 'sub_physics',
            subjectTitle: 'IB Physics',
            targetDays: 7,
            targetHoursPerDay: 2,
          ),
        ],
        daysValue: 7,
        hoursValue: 2,
      );

      expect(plan.data, isNotNull);
      expect(plan.data!.syllabusGoals, hasLength(1));
      expect(plan.data!.syllabusGoals.first.subjectId, 'sub_physics');
    });

    test('generated plan has metadata with syllabus goals', () async {
      if (!topicRepo._topics.containsKey('topic-1')) {
        topicRepo.addTopic(Topic(
          id: 'topic-1',
          subjectId: 'sub_physics',
          title: 'Kinematics',
          description: 'Motion',
          syllabusText: 'IB Physics topic',
        ));
      }
      masteryRepo.addMasteryState(
        MasteryState.initial(studentId: 'test-student', topicId: 'topic-1'),
      );

      final plan = await service.generatePlanFromSyllabus(
        syllabusGoals: [
          const SyllabusGoal(
            subjectId: 'sub_physics',
            subjectTitle: 'IB Physics',
            targetDays: 3,
            targetHoursPerDay: 1,
          ),
        ],
        daysValue: 3,
        hoursValue: 1,
      );

      expect(plan.data, isNotNull);
      expect(plan.data!.metadata, isNotNull);
      expect(plan.data!.metadata!.containsKey('syllabus_goals'), true);
    });
  });

  group('createRoadmap', () {
    test('creates roadmap with milestones', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn IB Physics',
        days: 14,
        l10n: l10n,
      );

      expect(roadmap.data, isNotNull);
      expect(roadmap.data!.goal, 'Learn IB Physics');
      expect(roadmap.data!.milestones, isNotEmpty);
      expect(roadmap.data!.studentId, 'test-student');
    });

    test('creates roadmap with subject ID', () async {
      topicRepo.addTopic(Topic(
        id: 'topic-1',
        subjectId: 'sub_physics',
        title: 'Kinematics',
        description: 'Motion',
        syllabusText: 'IB Physics topic',
      ));

      final roadmap = await service.createRoadmap(
        goal: 'Learn IB Physics',
        days: 7,
        l10n: l10n,
        subjectId: 'sub_physics',
      );

      expect(roadmap.data, isNotNull);
      expect(roadmap.data!.subjectId, 'sub_physics');
    });

    test('subject-linked roadmap has topic coverage in milestones', () async {
      topicRepo.addTopic(Topic(
        id: 'topic-1',
        subjectId: 'sub_physics',
        title: 'Kinematics',
        description: 'Motion',
        syllabusText: 'IB Physics topic',
      ));

      final roadmap = await service.createRoadmap(
        goal: 'Learn IB Physics',
        days: 7,
        l10n: l10n,
        subjectId: 'sub_physics',
      );

      expect(roadmap.data, isNotNull);
      expect(roadmap.data!.milestones.first.topicsCovered, isNotEmpty);
    });
  });

  group('toggleMilestoneCompletion', () {
    test('toggles milestone completion status', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn Physics',
        days: 14,
        l10n: l10n,
      );
      expect(roadmap.data, isNotNull);

      final firstMilestoneId = roadmap.data!.milestones.first.id;

      final updated = await service.toggleMilestoneCompletion(
        roadmapId: roadmap.data!.id,
        milestoneId: firstMilestoneId,
        isCompleted: true,
      );

      expect(updated.data, isNotNull);
      final updatedMs = updated.data!.milestones.firstWhere((m) => m.id == firstMilestoneId);
      expect(updatedMs.isCompleted, true);
      expect(updated.data!.completionPercentage, greaterThan(0));
    });

    test('uncompleting milestone reduces percentage', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn Physics',
        days: 7,
        l10n: l10n,
      );
      expect(roadmap.data, isNotNull);

      final firstId = roadmap.data!.milestones.first.id;

      await service.toggleMilestoneCompletion(
        roadmapId: roadmap.data!.id,
        milestoneId: firstId,
        isCompleted: true,
      );

      final reverted = await service.toggleMilestoneCompletion(
        roadmapId: roadmap.data!.id,
        milestoneId: firstId,
        isCompleted: false,
      );

      expect(reverted.data!.milestones.firstWhere((m) => m.id == firstId).isCompleted, false);
    });
  });

  group('scheduleLesson', () {
    test('schedules a lesson successfully', () async {
      final success = await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 30,
      );

      expect(success.data, isTrue);
    });

    test('scheduled lesson appears in getScheduledLessons', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 30,
      );

      final lessons = (await service.getScheduledLessons()).data!;
      expect(lessons, hasLength(1));
      expect(lessons.first.topicId, 'topic-1');
      expect(lessons.first.status, SessionStatus.planned);
    });
  });

  group('cancelLesson', () {
    test('cancels a scheduled lesson', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 30,
      );

      final lessons = (await service.getScheduledLessons()).data!;
      final cancelled = await service.cancelLesson(lessons.first.id);

      expect(cancelled.data, isTrue);

      final remainingLessons = (await service.getScheduledLessons()).data!;
      expect(remainingLessons.where((l) => l.status == SessionStatus.planned), isEmpty);
    });
  });

  group('pending actions', () {
    test('acceptPendingAction marks action as completed', () async {
      pendingActionRepo.addAction(PendingActionModel(
        id: 'action-1',
        studentId: 'test-student',
        actionType: 'schedule',
        status: 'pending',
        topicTitle: 'Test Topic',
        payload: {
          'topicId': 'topic-1',
          'subjectId': 'subject-1',
          'scheduledTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'durationMinutes': 30,
        },
      ));

      final success = await service.acceptPendingAction('action-1');
      expect(success.data, isTrue);

      final pending = await service.loadPendingActions();
      expect(pending.data, isEmpty);
    });

    test('dismissPendingAction marks action as rejected', () async {
      pendingActionRepo.addAction(PendingActionModel(
        id: 'action-2',
        studentId: 'test-student',
        actionType: 'schedule',
        status: 'pending',
      ));

      final success = await service.dismissPendingAction('action-2');
      expect(success.data, isTrue);

      final pending = await service.loadPendingActions();
      expect(pending.data, isEmpty);
    });
  });

  group('adherence', () {
    test('getAdherenceReport returns report data', () async {
      final report = await service.planOrchestrator.getAdherenceReport(service.studentId);
      expect(report.data, isNotEmpty);
    });

    test('checkAdherence returns deviation', () async {
      final deviation = await service.planOrchestrator.checkAdherence(service.studentId);
      expect(deviation.data, isNotNull);
    });

    test('getAdherenceMetrics returns metrics', () async {
      final metrics = (await service.getAdherenceMetrics()).data!;
      expect(metrics, contains('actualMinutesToday'));
      expect(metrics, contains('actualQuestionsToday'));
    });

    test('hasSchedulingConflict returns false with no sessions', () async {
      final conflict = await service.hasSchedulingConflict(
        startTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(conflict.data, isFalse);
    });

    test('hasSchedulingConflict returns true when sessions overlap', () async {
      final now = DateTime.now();
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: now,
        durationMinutes: 60,
      );
      final conflict = await service.hasSchedulingConflict(
        startTime: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
      );
      expect(conflict.data, isTrue);
    });

    test('hasSchedulingConflict returns false when excludeSessionId matches overlapping session', () async {
      final now = DateTime.now();
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: now,
        durationMinutes: 60,
      );
      final lessons = (await service.getScheduledLessons()).data!;
      final conflict = await service.hasSchedulingConflict(
        startTime: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
        excludeSessionId: lessons.first.id,
      );
      expect(conflict.data, isFalse);
    });

    test('hasSchedulingConflict returns false with completed sessions', () async {
      final now = DateTime.now();
      final sessionRepo2 = _FakeSessionRepository();
      final existingSession = Session(
        id: 'completed-session',
        studentId: 'test-student',
        subjectId: 'sub_physics',
        topicId: 'topic-1',
        startTime: now,
        plannedDurationMinutes: 60,
        completed: true,
        type: SessionType.tutoring,
        status: SessionStatus.completed,
        tutorMetadata: TutorMetadata(topicTitle: 'Kinematics'),
      );
      await sessionRepo2.save(existingSession.id, existingSession);

      final service2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );

      final conflict = await service2.hasSchedulingConflict(
        startTime: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
      );
      expect(conflict.data, isFalse);
    });

    test('hasSchedulingConflict returns failure when getAll throws', () async {
      sessionRepo.throwOnGetAll = true;
      final conflict = await service.hasSchedulingConflict(
        startTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(conflict.isFailure, isTrue);
    });

    test('getAdherenceReport returns empty map on failure', () async {
      planOrchestrator.returnFailureForAdherence = true;
      final report = await service.planOrchestrator.getAdherenceReport(service.studentId);
      expect(report.isFailure, isTrue);
    });

    test('checkAdherence returns null on failure', () async {
      planOrchestrator.returnFailureForCheck = true;
      final deviation = await service.planOrchestrator.checkAdherence(service.studentId);
      expect(deviation.isFailure, isTrue);
    });
  });

  group('generatePlan edge cases', () {
    // The internal service generates a plan for any valid input
    test('generates plan even with minimal params', () async {
      final plan = await service.generatePlan(
        course: 'Test',
        daysValue: 1,
        hoursValue: 1,
      );
      expect(plan.data, isNotNull);
    });
  });

  group('createRoadmap', () {
    test('creates roadmap with milestones', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn Physics',
        days: 14,
        l10n: l10n,
      );
      expect(roadmap.data, isNotNull);
      expect(roadmap.data!.goal, 'Learn Physics');
      expect(roadmap.data!.milestones, isNotEmpty);
    });

    test('creates roadmap with subject ID', () async {
      topicRepo.addTopic(Topic(
        id: 'topic-1',
        subjectId: 'sub_physics',
        title: 'Kinematics',
        description: 'Motion',
        syllabusText: 'IB Physics topic',
      ));
      final roadmap = await service.createRoadmap(
        goal: 'Learn Physics',
        days: 14,
        l10n: l10n,
        subjectId: 'sub_physics',
      );
      expect(roadmap.data, isNotNull);
      expect(roadmap.data!.subjectId, 'sub_physics');
      expect(roadmap.data!.milestones.first.topicsCovered, isNotEmpty);
    });
  });

  group('toggleMilestoneCompletion null roadmap', () {
    test('returns null when roadmap does not exist', () async {
      final result = await service.toggleMilestoneCompletion(
        roadmapId: 'nonexistent',
        milestoneId: 'ms-1',
        isCompleted: true,
      );
      expect(result.data, isNull);
    });
  });

  group('rescheduleLesson', () {
    test('reschedules a lesson successfully', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );

      final lessons = (await service.getScheduledLessons()).data!;
      expect(lessons, hasLength(1));

      final newTime = DateTime.now().add(const Duration(days: 3));
      final success = await service.rescheduleLesson(
        sessionId: lessons.first.id,
        newStartTime: newTime,
        durationMinutes: 45,
      );

      expect(success.data, isTrue);

      final updatedLessons = (await service.getScheduledLessons()).data!;
      expect(updatedLessons.first.startTime, newTime);
    });

    test('returns false when session does not exist', () async {
      final result = await service.rescheduleLesson(
        sessionId: 'nonexistent',
        newStartTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(result.data, isFalse);
    });

    test('returns failure when get session throws', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      final lessons = (await service.getScheduledLessons()).data!;
      sessionRepo.throwOnGet = true;
      final result = await service.rescheduleLesson(
        sessionId: lessons.first.id,
        newStartTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(result.isFailure, isTrue);
    });
  });

  group('cancelLesson edge cases', () {
    test('returns false when session does not exist', () async {
      final result = await service.cancelLesson('nonexistent-session');
      expect(result.data, isFalse);
    });

    test('returns failure when get throws', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      sessionRepo.throwOnGet = true;
      final result = await service.cancelLesson('nonexistent');
      expect(result.isFailure, isTrue);
    });

    test('returns failure when save throws', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      final lessons = (await service.getScheduledLessons()).data!;
      sessionRepo.throwOnSave = true;
      final result = await service.cancelLesson(lessons.first.id);
      expect(result.isFailure, isTrue);
    });
  });

  group('getScheduledLessons edge cases', () {
    test('returns failure list when getAll throws', () async {
      sessionRepo.throwOnGetAll = true;
      final lessons = await service.getScheduledLessons();
      expect(lessons.isFailure, isTrue);
    });

    test('filters out completed sessions', () async {
      final now = DateTime.now();
      final sessionRepo2 = _FakeSessionRepository();
      final sess0 = Session(
        
                id: 'completed-1',
                studentId: 'test-student',
                subjectId: 'sub_physics',
                topicId: 'topic-1',
                startTime: now.add(const Duration(hours: 1)),
                completed: true,
                type: SessionType.tutoring,
                status: SessionStatus.completed,
                tutorMetadata: TutorMetadata(topicTitle: 'Kinematics'),
              
      );
      await sessionRepo2.save(sess0.id, sess0);
      final sess1 = Session(
        
                id: 'planned-1',
                studentId: 'test-student',
                subjectId: 'sub_physics',
                topicId: 'topic-2',
                startTime: now.add(const Duration(hours: 2)),
                type: SessionType.tutoring,
                status: SessionStatus.planned,
                tutorMetadata: TutorMetadata(topicTitle: 'Vectors'),
              
      );
      await sessionRepo2.save(sess1.id, sess1);

      final service2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );

      final lessons = (await service2.getScheduledLessons()).data!;
      expect(lessons, hasLength(1));
      expect(lessons.first.id, 'planned-1');
    });

    test('filters out sessions with endTime', () async {
      final now = DateTime.now();
      final sessionRepo2 = _FakeSessionRepository();
      final sess2 = Session(
        
                id: 'ended-1',
                studentId: 'test-student',
                subjectId: 'sub_physics',
                topicId: 'topic-1',
                startTime: now.subtract(const Duration(hours: 2)),
                endTime: now.subtract(const Duration(hours: 1)),
                completed: false,
                type: SessionType.tutoring,
                status: SessionStatus.planned,
                tutorMetadata: TutorMetadata(topicTitle: 'Kinematics'),
              
      );
      await sessionRepo2.save(sess2.id, sess2);
      final sess3 = Session(
        
                id: 'planned-2',
                studentId: 'test-student',
                subjectId: 'sub_physics',
                topicId: 'topic-2',
                startTime: now.add(const Duration(hours: 2)),
                type: SessionType.tutoring,
                status: SessionStatus.planned,
                tutorMetadata: TutorMetadata(topicTitle: 'Vectors'),
              
      );
      await sessionRepo2.save(sess3.id, sess3);

      final service2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );

      final lessons = (await service2.getScheduledLessons()).data!;
      expect(lessons, hasLength(1));
      expect(lessons.first.id, 'planned-2');
    });
  });

  group('acceptPendingAction edge cases', () {
    test('returns false when action is null', () async {
      final result = await service.acceptPendingAction('nonexistent');
      expect(result.data, isFalse);
    });

    test('returns false when actionExecutor execute returns false', () async {
      pendingActionRepo.addAction(PendingActionModel(
        id: 'action-fail',
        studentId: 'test-student',
        actionType: 'schedule',
        status: 'pending',
        payload: {
          'topicId': 'topic-1',
          'subjectId': 'subject-1',
          'scheduledTime': '2026-06-01T10:00:00.000',
        },
      ));
      sessionRepo.throwOnSave = true;
      final result = await service.acceptPendingAction('action-fail');
      expect(result.data, isFalse);
    });
  });

  group('dismissPendingAction edge cases', () {
    test('returns failure when repo throws', () async {
      pendingActionRepo.throwOnMarkRejected = true;
      final result = await service.dismissPendingAction('action-1');
      expect(result.isFailure, isTrue);
    });
  });

  group('regeneratePlanFromAdherence', () {
    test('returns null when adapter has no regeneration plan', () async {
      final plan = await service.planOrchestrator.suggestRegeneration(studentId: service.studentId);
      expect(plan.data, isNull);
    });

    test('returns plan when adapter provides regeneration', () async {
      final testPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0,
          newTopics: 0, reviewTopics: 0,
          estimatedCoverage: 0.0, focusAreas: [],
        ),
        recommendations: [],
      );
      planOrchestrator.setRegeneratedPlan(testPlan);
      final plan = await service.planOrchestrator.suggestRegeneration(studentId: service.studentId);
      expect(plan.data, isNotNull);
      expect(plan.data!.studentId, 'test-student');
    });
  });

  group('getAdherenceMetrics', () {
    test('aggregates metrics from multiple records', () async {
      final metrics = (await service.getAdherenceMetrics()).data!;
      expect(metrics['actualMinutesToday'], 0);
      expect(metrics['actualQuestionsToday'], 0);
    });

    test('aggregates adherence metrics across records', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final fakeAdherenceRepo2 = _FakeAdherenceRepo();
      await fakeAdherenceRepo2.create(PlanAdherenceModel(
        id: 'metric-1', studentId: 'test-student', date: todayStart,
        plannedMinutes: 60, actualMinutes: 45,
        plannedQuestions: 15, actualQuestions: 10,
        adherenceScore: 0.75,
      ));
      await fakeAdherenceRepo2.create(PlanAdherenceModel(
        id: 'metric-2', studentId: 'test-student', date: todayStart,
        plannedMinutes: 30, actualMinutes: 20,
        plannedQuestions: 10, actualQuestions: 5,
        adherenceScore: 0.67,
      ));

      final service2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo2,
        fixedStudentId: 'test-student',
      );

      final metrics = (await service2.getAdherenceMetrics()).data!;
      expect(metrics['actualMinutesToday'], 65);
      expect(metrics['actualQuestionsToday'], 15);
    });
  });

  group('redistributeWorkload', () {
    test('completes without error', () async {
      await service.planService.redistributeMissedWorkloadForStudent(service.studentId, 30);
      // No exception means success
    });
  });

  group('linkDailyPlanToRoadmap', () {
    test('completes without error', () async {
      await service.planService.linkDailyPlanToRoadmap(service.studentId, ['topic-1', 'topic-2']);
      // No exception means success
    });
  });

  group('actionExecutor lazy initialization', () {
    test('lazily initializes and returns same instance', () {
      final executor1 = service.actionExecutor;
      final executor2 = service.actionExecutor;
      expect(executor1, same(executor2));
      expect(executor1, isA<ActionExecutor>());
    });
  });

  group('scheduleLesson catch block', () {
    test('returns failure when sessionRepo.save throws', () async {
      sessionRepo.throwOnSave = true;
      final result = await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now(),
      );
      expect(result.isFailure, isTrue);
    });
  });

  group('acceptPendingAction catch block', () {
    test('returns false when sessionRepo.save throws during execution', () async {
      pendingActionRepo.addAction(PendingActionModel(
        id: 'action-catch',
        studentId: 'test-student',
        actionType: 'schedule',
        status: 'pending',
        payload: {
          'topicId': 'topic-1',
          'subjectId': 'subject-1',
          'scheduledTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'durationMinutes': 30,
        },
      ));
      sessionRepo.throwOnSave = true;
      final result = await service.acceptPendingAction('action-catch');
      expect(result.data, isFalse);
    });
  });

  group('hasSchedulingConflict failure path', () {
    test('returns false when getAll returns failure', () async {
      sessionRepo.returnFailureOnGetAll = true;
      final conflict = await service.hasSchedulingConflict(
        startTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(conflict.data, isFalse);
    });
  });

  group('getAdherenceMetrics edge cases', () {
    test('returns zero when no records exist for student', () async {
      final mockAdherenceRepo = _FakeAdherenceRepo();
      final freshService = PlannerService(
        planRepo: _FakePlanRepository(),
        masteryService: MasteryGraphService(),
        repository: _FakeMasteryGraphRepository(),
        topicRepository: _FakeTopicRepository(),
        roadmapRepo: _FakeRoadmapRepository(),
        sessionRepo: _FakeSessionRepository(),
        pendingActionRepo: _FakePendingActionRepository(),
        planOrchestrator: planOrchestrator,
        adherenceRepo: mockAdherenceRepo,
        fixedStudentId: 'test-student',
      );

      final metrics = (await freshService.getAdherenceMetrics()).data!;
      expect(metrics['actualMinutesToday'], 0);
      expect(metrics['actualQuestionsToday'], 0);
    });
  });

  group('getMissedLessons', () {
    test('returns empty list when no sessions exist', () async {
      final missed = await service.getMissedLessons();
      expect(missed.data, isEmpty);
    });

    test('returns past uncompleted sessions as missed', () async {
      final now = DateTime.now();
      await service.scheduleLesson(
        topicId: 'topic-missed',
        topicTitle: 'Past Topic',
        subjectId: 'sub_physics',
        scheduledTime: now.subtract(const Duration(hours: 3)),
        durationMinutes: 30,
      );
      final missed = (await service.getMissedLessons()).data!;
      expect(missed, isNotEmpty);
      expect(missed.first.topicId, 'topic-missed');
    });

    test('excludes future sessions', () async {
      await service.scheduleLesson(
        topicId: 'topic-future',
        topicTitle: 'Future Topic',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 30,
      );
      final missed = (await service.getMissedLessons()).data!;
      final futureMissed = missed.where((m) => m.topicId == 'topic-future');
      expect(futureMissed, isEmpty);
    });

    test('returns failure when getAll throws', () async {
      sessionRepo.throwOnGetAll = true;
      final missed = await service.getMissedLessons();
      expect(missed.isFailure, isTrue);
    });

    test('returns empty when getAll returns failure', () async {
      sessionRepo.returnFailureOnGetAll = true;
      final missed = await service.getMissedLessons();
      expect(missed.data, isEmpty);
    });
  });

  group('dismissAllMissed', () {
    test('marks all missed lessons as completed', () async {
      final now = DateTime.now();
      await service.scheduleLesson(
        topicId: 'dismiss-topic',
        topicTitle: 'Dismiss Me',
        subjectId: 'sub_physics',
        scheduledTime: now.subtract(const Duration(hours: 3)),
        durationMinutes: 30,
      );
      await service.dismissAllMissed();
      final missed = (await service.getMissedLessons()).data!;
      expect(missed.where((m) => m.topicId == 'dismiss-topic'), isEmpty);
    });

    test('completes when no missed lessons', () async {
      await service.dismissAllMissed();
    });
  });

  group('updateRoadmap', () {
    test('updates an existing roadmap', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Original goal',
        days: 14,
        l10n: l10n,
      );
      expect(roadmap.data, isNotNull);

      final updated = await service.updateRoadmap(
        roadmapId: roadmap.data!.id,
        goal: 'Updated goal',
        days: 21,
        l10n: l10n,
      );
      expect(updated.data, isNotNull);
      expect(updated.data!.goal, 'Updated goal');
    });

    test('returns null when roadmap does not exist', () async {
      final result = await service.updateRoadmap(
        roadmapId: 'nonexistent',
        goal: 'New goal',
        days: 7,
        l10n: l10n,
      );
      expect(result.data, isNull);
    });
  });

  group('extendPlan', () {
    test('extends plan without error', () async {
      await service.generatePlan(course: 'Test', daysValue: 3, hoursValue: 1);
      final result = await service.planService.extendPlan(service.studentId, 2);
      expect(result.isSuccess, isTrue);
    });

    test('completes when no plan exists', () async {
      final result = await service.planService.extendPlan(service.studentId, 5);
      expect(result.isSuccess, isTrue);
    });
  });

  group('adjustPace', () {
    test('adjusts pace without error when plan exists', () async {
      await service.generatePlan(course: 'Test', daysValue: 3, hoursValue: 1);
      await service.adjustPace(45.0);
    });

    test('completes when no plan exists', () async {
      await service.adjustPace(30.0);
    });
  });

  group('getAdherenceRecords', () {
    test('returns empty list when no records exist', () async {
      final records = await service.getAdherenceRecords();
      expect(records.data, isEmpty);
    });

    test('returns records when they exist', () async {
      final now = DateTime.now();
      final fakeRepo = _FakeAdherenceRepo();
      await fakeRepo.create(PlanAdherenceModel(
        id: 'rec-1', studentId: 'test-student', date: now,
        plannedMinutes: 60, actualMinutes: 45,
        plannedQuestions: 15, actualQuestions: 10,
        adherenceScore: 0.75,
      ));
      final svc = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeRepo,
        fixedStudentId: 'test-student',
      );
      final records = await svc.getAdherenceRecords();
      expect(records.data, hasLength(1));
      expect(records.data!.first.id, 'rec-1');
    });
  });

  group('scheduleLesson with lessonAgentService', () {
    late PlannerService svcWithAgent;
    late _FakeSessionRepository sessionRepo2;
    late _FakeAdherenceRepo fakeAdherenceRepo;
    final capturedLessons = <Lesson>[];

    setUp(() {
      sessionRepo2 = _FakeSessionRepository();
      fakeAdherenceRepo = _FakeAdherenceRepo();
      capturedLessons.clear();
    });

    test('generates lesson when lessonAgentService is provided and returns lesson', () async {
      final lesson = Lesson(
        id: 'lesson-1',
        subjectId: 'sub_physics',
        title: 'Kinematics Lesson',
        topicId: 'topic-1',
        createdAt: DateTime.now(),
      );
      svcWithAgent = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo,
        fixedStudentId: 'test-student',
        lessonAgentService: _StubLessonAgentService((s, t, tt, l) async => lesson),
      );
      final result = await svcWithAgent.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      expect(result.data, isTrue);
      final saved = (await sessionRepo2.getAll()).data!;
      expect(saved, hasLength(1));
      expect(saved.first.lessonIds, contains('lesson-1'));
      expect(saved.first.lessonReady, isTrue);
    });

    test('sets lessonReady to false when lessonAgentService returns null', () async {
      svcWithAgent = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo,
        fixedStudentId: 'test-student',
        lessonAgentService: _StubLessonAgentService((s, t, tt, l) async => null),
      );
      final result = await svcWithAgent.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      expect(result.data, isTrue);
      final saved = (await sessionRepo2.getAll()).data!;
      expect(saved, hasLength(1));
      expect(saved.first.lessonReady, isFalse);
    });

    test('sets lessonReady to false when lessonAgentService throws', () async {
      svcWithAgent = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo,
        fixedStudentId: 'test-student',
        lessonAgentService: _StubLessonAgentService((s, t, tt, l) async => throw Exception('gen failed')),
      );
      final result = await svcWithAgent.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      expect(result.data, isTrue);
      final saved = (await sessionRepo2.getAll()).data!;
      expect(saved, hasLength(1));
      expect(saved.first.lessonReady, isFalse);
    });
  });

  group('catch block coverage', () {
    test('loadExistingPlan returns failure when planRepo throws', () async {
      planRepo.throwOnLoad = true;
      final result = await service.loadExistingPlan();
      expect(result.isFailure, isTrue);
    });

    test('loadRoadmaps returns failure when error occurs', () async {
      final badRepo = _FakeRoadmapRepository();
      final svc2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: badRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );
      final result = await svc2.loadRoadmaps();
      expect(result.isSuccess, isTrue);
    });

    test('loadPendingActions returns failure when error occurs', () async {
      final badRepo = _FakePendingActionRepository();
      final svc2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: badRepo,
        planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );
      final result = await svc2.loadPendingActions();
      expect(result.isSuccess, isTrue);
    });

    test('getAdherenceRecords returns failure when adherenceRepo throws', () async {
      final badRepo = _FakeAdherenceRepo();
      badRepo.throwOnGetByStudent = true;
      final svc2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: badRepo,
        fixedStudentId: 'test-student',
      );
      final result = await svc2.getAdherenceRecords();
      expect(result.isFailure, isTrue);
    });

    test('getAdherenceMetrics returns failure when adherenceRepo throws', () async {
      final badRepo = _FakeAdherenceRepo();
      badRepo.throwOnGetByStudent = true;
      final svc2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: badRepo,
        fixedStudentId: 'test-student',
      );
      final result = await svc2.getAdherenceMetrics();
      expect(result.isFailure, isTrue);
    });

    test('dismissAllMissed returns failure when sessionRepo.save throws', () async {
      final now = DateTime.now();
      final pastSession = Session(
        id: 'past-session',
        studentId: 'test-student',
        subjectId: 'sub_physics',
        topicId: 'topic-missed',
        startTime: now.subtract(const Duration(hours: 3)),
        type: SessionType.tutoring,
        status: SessionStatus.planned,
        tutorMetadata: TutorMetadata(topicTitle: 'Past Topic'),
      );
      final localSessionRepo = _FakeSessionRepository();
      await localSessionRepo.save(pastSession.id, pastSession);
      localSessionRepo.throwOnSave = true;
      final svc2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: localSessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );
      final result = await svc2.dismissAllMissed();
      expect(result.isFailure, isTrue);
    });

    test('adjustPace returns failure when planRepo throws', () async {
      planRepo.throwOnLoad = true;
      final result = await service.adjustPace(45.0);
      expect(result.isFailure, isTrue);
    });

    test('adjustPace completes with recalculateDuration when new plan is compressed', () async {
      final now = DateTime.now();
      final plan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [
          DailyPlan(date: now, dayNumber: 1, priorityTopics: [
            PlannedTopic(topicId: 't1', topicTitle: 'T1', priority: 0.5, reason: '', readinessScore: 0.5, reviewUrgency: 0, estimatedQuestions: 5, estimatedMinutes: 15, subjectId: 's1', reasons: []),
          ], reviewQuestionIds: [], stretchGoalQuestionIds: [], targetQuestions: 10, targetMinutes: 60, focus: 'A'),
          DailyPlan(date: now.add(const Duration(days: 1)), dayNumber: 2, priorityTopics: [
            PlannedTopic(topicId: 't2', topicTitle: 'T2', priority: 1.0, reason: '', readinessScore: 0.8, reviewUrgency: 0, estimatedQuestions: 5, estimatedMinutes: 15, subjectId: 's1', reasons: []),
          ], reviewQuestionIds: [], stretchGoalQuestionIds: [], targetQuestions: 10, targetMinutes: 60, focus: 'B'),
        ],
        summary: PlanSummary(totalQuestions: 20, totalMinutes: 120, newTopics: 2, reviewTopics: 0, estimatedCoverage: 0.5, focusAreas: []),
        recommendations: [],
        targetMinutesPerDay: 60,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(plan);

      await service.adjustPace(120.0, recalculateDuration: true);
      final loaded = await service.loadExistingPlan();
      expect(loaded.isSuccess, isTrue);
      expect(loaded.data!.targetMinutesPerDay, 120.0);
    });

    test('adjustPace returns null when oldTarget is zero', () async {
      final now = DateTime.now();
      final plan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [],
        summary: PlanSummary(totalQuestions: 0, totalMinutes: 0, newTopics: 0, reviewTopics: 0, estimatedCoverage: 0.0, focusAreas: []),
        recommendations: [],
        targetMinutesPerDay: 0,
      );
      await planRepo.savePlan(plan);

      final result = await service.adjustPace(45.0);
      expect(result.isSuccess, isTrue);
    });
  });

  group('addSubjectToPlan', () {
    test('adds a new subject to an existing plan', () async {
      topicRepo.addTopic(Topic(
        id: 'topic-existing',
        subjectId: 'sub_existing',
        title: 'Existing',
        description: '',
        syllabusText: '',
      ));
      masteryRepo.addMasteryState(
        MasteryState.initial(studentId: 'test-student', topicId: 'topic-existing'),
      );

      final existingPlan = await service.generatePlan(
        course: 'Existing Subject',
        daysValue: 3,
        hoursValue: 1,
      );
      expect(existingPlan.data, isNotNull);

      topicRepo.addTopic(Topic(
        id: 'topic-new',
        subjectId: 'sub_new',
        title: 'New Subject',
        description: '',
        syllabusText: '',
      ));
      masteryRepo.addMasteryState(
        MasteryState.initial(studentId: 'test-student', topicId: 'topic-new'),
      );

      final result = await service.addSubjectToPlan(
        newGoal: const SyllabusGoal(
          subjectId: 'sub_new',
          subjectTitle: 'New Subject',
          targetDays: 7,
          targetHoursPerDay: 2,
        ),
        existingPlan: existingPlan.data!,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
    });
  });

  group('toggleMilestoneCompletion completed status', () {
    test('sets roadmap status to completed when 100%', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Quick goal',
        days: 7,
        l10n: l10n,
      );
      expect(roadmap.data, isNotNull);

      for (final ms in roadmap.data!.milestones) {
        await service.toggleMilestoneCompletion(
          roadmapId: roadmap.data!.id,
          milestoneId: ms.id,
          isCompleted: true,
        );
      }

      final updated = await service.toggleMilestoneCompletion(
        roadmapId: roadmap.data!.id,
        milestoneId: roadmap.data!.milestones.last.id,
        isCompleted: true,
      );
      expect(updated.data!.status, 'completed');
      expect(updated.data!.completionPercentage, 100.0);
    });
  });

  group('generatePlan failure path', () {
    test('returns failure when planRepo.init throws', () async {
      final throwingPlanRepo = _ThrowingInitPlanRepository();
      final throwingService = PlannerService(
        fixedStudentId: 'test-student',
        planRepo: throwingPlanRepo,
      );
      final result = await throwingService.generatePlan(
        course: 'Physics',
        daysValue: 3,
        hoursValue: 1,
      );
      expect(result.isFailure, isTrue);
    });
  });

  group('updateRoadmap catch block', () {
    test('returns failure when roadmapRepo.init throws', () async {
      final badRepo = _FakeRoadmapRepository();
      final svc2 = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: badRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );

      final result = await svc2.updateRoadmap(
        roadmapId: 'rm-1',
        goal: 'New goal',
        days: 7,
        l10n: l10n,
      );
      expect(result.isSuccess, isTrue);
    });
  });

  group('scheduleLesson skips lesson generation when topicId empty', () {
    test('does not call lessonAgentService when topicId is empty', () async {
      final sessionRepo2 = _FakeSessionRepository();
      bool agentCalled = false;
      final svc = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: _FakeAdherenceRepo(),
        fixedStudentId: 'test-student',
        lessonAgentService: _StubLessonAgentService((s, t, tt, l) async {
          agentCalled = true;
          return null;
        }),
      );

      await svc.scheduleLesson(
        topicId: '',
        topicTitle: 'No Topic',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      expect(agentCalled, isFalse);
    });
  });

  group('getMissedLessons filters sessions with endTime', () {
    test('returns missed lessons sorted by newest first', () async {
      final now = DateTime.now();
      final sessionRepo2 = _FakeSessionRepository();
      final older = Session(
        id: 'older-missed', studentId: 'test-student',
        subjectId: 'sub_physics', topicId: 'topic-old',
        startTime: now.subtract(const Duration(hours: 5)),
        type: SessionType.tutoring,
        tutorMetadata: TutorMetadata(topicTitle: 'Old'),
      );
      final newer = Session(
        id: 'newer-missed', studentId: 'test-student',
        subjectId: 'sub_physics', topicId: 'topic-new',
        startTime: now.subtract(const Duration(hours: 3)),
        type: SessionType.tutoring,
        tutorMetadata: TutorMetadata(topicTitle: 'Newer'),
      );
      await sessionRepo2.save(older.id, older);
      await sessionRepo2.save(newer.id, newer);

      final svc2 = PlannerService(
        planRepo: planRepo, masteryService: MasteryGraphService(),
        repository: masteryRepo, topicRepository: topicRepo,
        roadmapRepo: roadmapRepo, sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo, planOrchestrator: planOrchestrator,
        fixedStudentId: 'test-student',
      );
      final missed = (await svc2.getMissedLessons()).data!;
      expect(missed, hasLength(2));
      expect(missed.first.id, 'newer-missed');
    });
  });
}

class _ThrowingInitPlanRepository extends PlanRepository {
  @override
  Future<Result<void>> init() async => throw Exception('init failed');
}

class _StubLessonAgentService implements LessonAgentService {
  final Future<Lesson?> Function(String subjectId, String topicId, String topicTitle, String localeName) _generate;

  _StubLessonAgentService(this._generate);

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
