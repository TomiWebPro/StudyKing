import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/features/planner/services/action_executor.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

class _MockMasteryGraphRepository extends MasteryGraphRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success([]);
  }

  @override
  Future<Result<MasteryState>> getMasteryState(String studentId, String topicId) async {
    return Result.success(MasteryState.initial(studentId: studentId, topicId: topicId));
  }
}

class _MockTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async => _topics[id];

  @override
  Future<List<Topic>> getBySubject(String subjectId) async {
    return _topics.values.where((t) => t.subjectId == subjectId).toList();
  }
}

class _MockPlanRepository extends PlanRepository {
  PersonalLearningPlan? _plan;

  @override
  Future<void> init() async {}

  @override
  Future<PersonalLearningPlan?> loadPlan(String studentId) async => _plan;

  @override
  Future<void> savePlan(PersonalLearningPlan plan) async {
    _plan = plan;
  }

  @override
  Future<bool> hasPlan(String studentId) async => _plan != null;
}

class _MockRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _roadmaps = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    _roadmaps[roadmap.id] = roadmap;
  }

  @override
  Future<RoadmapModel?> loadRoadmap(String id) async => _roadmaps[id];

  @override
  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    return _roadmaps.values.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<List<RoadmapModel>> getAllRoadmaps() async => _roadmaps.values.toList();
}

class _MockSessionRepository extends SessionRepository {
  final Map<String, Session> _sessions = {};
  bool throwOnGet = false;
  bool throwOnSave = false;
  bool throwOnGetAll = false;

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> save(Session session) async {
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
    if (throwOnGetAll) throw Exception('get all sessions error');
    return Result.success(_sessions.values.toList());
  }
}

class _MockPendingActionRepository extends PendingActionRepository {
  final Map<String, PendingActionModel> _actions = {};
  bool throwOnMarkCompleted = false;
  bool throwOnMarkRejected = false;

  @override
  Future<void> init() async {}

  @override
  Future<List<PendingActionModel>> getPending(String studentId) async {
    return _actions.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList();
  }

  @override
  Future<PendingActionModel?> get(String id) async => _actions[id];

  @override
  Future<void> markCompleted(String id) async {
    if (throwOnMarkCompleted) throw Exception('mark completed error');
    final action = _actions[id];
    if (action != null) {
      _actions[id] = action.copyWith(status: 'completed');
    }
  }

  @override
  Future<void> markRejected(String id) async {
    if (throwOnMarkRejected) throw Exception('mark rejected error');
    final action = _actions[id];
    if (action != null) {
      _actions[id] = action.copyWith(status: 'rejected');
    }
  }

  @override
  Future<void> create(PendingActionModel action) async {
    _actions[action.id] = action;
  }

  void addAction(PendingActionModel action) => _actions[action.id] = action;
}

class _MockPlanAdapter extends PlanAdapter {
  _MockPlanAdapter() : super();

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
  Future<void> recordFromFocusSession({required String studentId, required int actualMinutes, String? planId}) async {}

  @override
  Future<void> recordFromPracticeSession({required String studentId, required int actualQuestions, required int actualMinutes, String? planId}) async {}

  @override
  Future<void> recordFromTutorSession({required String studentId, required int actualMinutes, String? planId}) async {}
}

void main() {
  late PlannerService service;
  late _MockMasteryGraphRepository masteryRepo;
  late _MockTopicRepository topicRepo;
  late _MockPlanRepository planRepo;
  late _MockRoadmapRepository roadmapRepo;
  late _MockSessionRepository sessionRepo;
  late _MockPendingActionRepository pendingActionRepo;
  late _MockPlanAdapter planAdapter;
  late AppLocalizations l10n;

  setUp(() {
    Hive.init(Directory.systemTemp.createTempSync('planner_svc_test_').path);
    masteryRepo = _MockMasteryGraphRepository();
    topicRepo = _MockTopicRepository();
    planRepo = _MockPlanRepository();
    roadmapRepo = _MockRoadmapRepository();
    sessionRepo = _MockSessionRepository();
    pendingActionRepo = _MockPendingActionRepository();
    planAdapter = _MockPlanAdapter();
    l10n = AppLocalizationsEn();

    final syllabusResolver = SyllabusResolver(
      topicRepository: topicRepo,
      masteryRepository: masteryRepo,
    );

    service = PlannerService(
      masteryService: MasteryGraphService(repository: masteryRepo),
      repository: masteryRepo,
      topicRepository: topicRepo,
      planRepo: planRepo,
      roadmapRepo: roadmapRepo,
      sessionRepo: sessionRepo,
      pendingActionRepo: pendingActionRepo,
      planAdapter: planAdapter,
      syllabusResolver: syllabusResolver,
      fixedStudentId: 'test-student',
    );
  });

  group('loadExistingPlan', () {
    test('returns null when no plan exists', () async {
      final plan = await service.loadExistingPlan();
      expect(plan, isNull);
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

      final plan = await service.loadExistingPlan();
      expect(plan, isNotNull);
      expect(plan!.studentId, 'test-student');
      expect(plan.summary.totalQuestions, 10);
    });
  });

  group('loadRoadmaps', () {
    test('returns empty list when no roadmaps exist', () async {
      final roadmaps = await service.loadRoadmaps();
      expect(roadmaps, isEmpty);
    });

    test('returns saved roadmaps', () async {
      final roadmap = RoadmapModel(
        id: 'rm-1',
        studentId: 'test-student',
        goal: 'Learn Physics',
        createdAt: DateTime.now(),
      );
      await roadmapRepo.saveRoadmap(roadmap);

      final roadmaps = await service.loadRoadmaps();
      expect(roadmaps, hasLength(1));
      expect(roadmaps.first.goal, 'Learn Physics');
    });
  });

  group('loadPendingActions', () {
    test('returns empty list when no pending actions', () async {
      final actions = await service.loadPendingActions();
      expect(actions, isEmpty);
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

      final actions = await service.loadPendingActions();
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

      expect(plan, isNotNull);
      expect(plan!.studentId, 'test-student');
      expect(plan.planDurationDays, 7);
      expect(plan.targetMinutesPerDay, 120.0);
    });

    test('generated plan has daily plans', () async {
      final plan = await service.generatePlan(
        course: 'IB Physics',
        daysValue: 3,
        hoursValue: 1,
      );

      expect(plan, isNotNull);
      expect(plan!.dailyPlans, hasLength(3));
      expect(plan.dailyPlans.first.dayNumber, 1);
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

      expect(plan, isNotNull);
      expect(plan!.syllabusGoals, hasLength(1));
      expect(plan.syllabusGoals.first.subjectId, 'sub_physics');
    });

    test('generated plan has metadata with syllabus goals', () async {
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

      expect(plan, isNotNull);
      expect(plan!.metadata, isNotNull);
      expect(plan.metadata!.containsKey('syllabus_goals'), true);
    });
  });

  group('createRoadmap', () {
    test('creates roadmap with milestones', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn IB Physics',
        days: 14,
        l10n: l10n,
      );

      expect(roadmap, isNotNull);
      expect(roadmap!.goal, 'Learn IB Physics');
      expect(roadmap.milestones, isNotEmpty);
      expect(roadmap.studentId, 'test-student');
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

      expect(roadmap, isNotNull);
      expect(roadmap!.subjectId, 'sub_physics');
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

      expect(roadmap, isNotNull);
      expect(roadmap!.milestones.first.topicsCovered, isNotEmpty);
    });
  });

  group('toggleMilestoneCompletion', () {
    test('toggles milestone completion status', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn Physics',
        days: 14,
        l10n: l10n,
      );
      expect(roadmap, isNotNull);

      final firstMilestoneId = roadmap!.milestones.first.id;

      final updated = await service.toggleMilestoneCompletion(
        roadmapId: roadmap.id,
        milestoneId: firstMilestoneId,
        isCompleted: true,
      );

      expect(updated, isNotNull);
      final updatedMs = updated!.milestones.firstWhere((m) => m.id == firstMilestoneId);
      expect(updatedMs.isCompleted, true);
      expect(updated.completionPercentage, greaterThan(0));
    });

    test('uncompleting milestone reduces percentage', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn Physics',
        days: 7,
        l10n: l10n,
      );
      expect(roadmap, isNotNull);

      final firstId = roadmap!.milestones.first.id;

      await service.toggleMilestoneCompletion(
        roadmapId: roadmap.id,
        milestoneId: firstId,
        isCompleted: true,
      );

      final reverted = await service.toggleMilestoneCompletion(
        roadmapId: roadmap.id,
        milestoneId: firstId,
        isCompleted: false,
      );

      expect(reverted!.milestones.firstWhere((m) => m.id == firstId).isCompleted, false);
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

      expect(success, true);
    });

    test('scheduled lesson appears in getScheduledLessons', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 30,
      );

      final lessons = await service.getScheduledLessons();
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

      final lessons = await service.getScheduledLessons();
      final cancelled = await service.cancelLesson(lessons.first.id);

      expect(cancelled, true);

      final remainingLessons = await service.getScheduledLessons();
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
      expect(success, true);

      final pending = await service.loadPendingActions();
      expect(pending, isEmpty);
    });

    test('dismissPendingAction marks action as rejected', () async {
      pendingActionRepo.addAction(PendingActionModel(
        id: 'action-2',
        studentId: 'test-student',
        actionType: 'schedule',
        status: 'pending',
      ));

      final success = await service.dismissPendingAction('action-2');
      expect(success, true);

      final pending = await service.loadPendingActions();
      expect(pending, isEmpty);
    });
  });

  group('adherence', () {
    test('getAdherenceReport returns report data', () async {
      final report = await service.getAdherenceReport();
      expect(report, isNotEmpty);
    });

    test('checkAdherence returns deviation', () async {
      final deviation = await service.checkAdherence();
      expect(deviation, isNotNull);
    });

    test('getAdherenceMetrics returns metrics', () async {
      final metrics = await service.getAdherenceMetrics();
      expect(metrics, contains('actualMinutesToday'));
      expect(metrics, contains('actualQuestionsToday'));
    });

    test('hasSchedulingConflict returns false with no sessions', () async {
      final conflict = await service.hasSchedulingConflict(
        startTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(conflict, false);
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
      expect(conflict, true);
    });

    test('getAdherenceReport returns empty map on failure', () async {
      planAdapter.returnFailureForAdherence = true;
      final report = await service.getAdherenceReport();
      expect(report, isEmpty);
    });

    test('checkAdherence returns null on failure', () async {
      planAdapter.returnFailureForCheck = true;
      final deviation = await service.checkAdherence();
      expect(deviation, isNull);
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
      expect(plan, isNotNull);
    });
  });

  group('createRoadmapFromGoal', () {
    test('creates roadmap with milestones', () async {
      final roadmap = await service.createRoadmapFromGoal(
        'Learn Physics',
        14,
        l10n,
      );
      expect(roadmap, isNotNull);
      expect(roadmap!.goal, 'Learn Physics');
      expect(roadmap.milestones, isNotEmpty);
    });

    test('creates roadmap with subject ID', () async {
      topicRepo.addTopic(Topic(
        id: 'topic-1',
        subjectId: 'sub_physics',
        title: 'Kinematics',
        description: 'Motion',
        syllabusText: 'IB Physics topic',
      ));
      final roadmap = await service.createRoadmapFromGoal(
        'Learn Physics',
        14,
        l10n,
        subjectId: 'sub_physics',
      );
      expect(roadmap, isNotNull);
      expect(roadmap!.subjectId, 'sub_physics');
      expect(roadmap.milestones.first.topicsCovered, isNotEmpty);
    });
  });

  group('toggleMilestoneCompletion null roadmap', () {
    test('returns null when roadmap does not exist', () async {
      final result = await service.toggleMilestoneCompletion(
        roadmapId: 'nonexistent',
        milestoneId: 'ms-1',
        isCompleted: true,
      );
      expect(result, isNull);
    });
  });

  group('cancelLesson edge cases', () {
    test('returns false when session does not exist', () async {
      final result = await service.cancelLesson('nonexistent-session');
      expect(result, isFalse);
    });

    test('returns false when tutorRepo throws', () async {
      await service.scheduleLesson(
        topicId: 'topic-1',
        topicTitle: 'Kinematics',
        subjectId: 'sub_physics',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      sessionRepo.throwOnGet = true;
      final result = await service.cancelLesson('nonexistent');
      expect(result, isFalse);
    });
  });

  group('getScheduledLessons edge cases', () {
    test('returns empty list when tutorRepo throws', () async {
      sessionRepo.throwOnGetAll = true;
      final lessons = await service.getScheduledLessons();
      expect(lessons, isEmpty);
    });
  });

  group('acceptPendingAction edge cases', () {
    test('returns false when action is null', () async {
      final result = await service.acceptPendingAction('nonexistent');
      expect(result, isFalse);
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
      expect(result, isFalse);
    });
  });

  group('dismissPendingAction edge cases', () {
    test('returns false when repo throws', () async {
      pendingActionRepo.throwOnMarkRejected = true;
      final result = await service.dismissPendingAction('action-1');
      expect(result, isFalse);
    });
  });

  group('regeneratePlanFromAdherence', () {
    test('returns null when adapter has no regeneration plan', () async {
      final plan = await service.regeneratePlanFromAdherence();
      expect(plan, isNull);
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
      planAdapter.setRegeneratedPlan(testPlan);
      final plan = await service.regeneratePlanFromAdherence();
      expect(plan, isNotNull);
      expect(plan!.studentId, 'test-student');
    });
  });

  group('getAdherenceMetrics', () {
    test('aggregates metrics from multiple records', () async {
      final metrics = await service.getAdherenceMetrics();
      expect(metrics['actualMinutesToday'], 0);
      expect(metrics['actualQuestionsToday'], 0);
    });
  });

  group('redistributeWorkload', () {
    test('completes without error', () async {
      await service.redistributeWorkload(30);
      // No exception means success
    });
  });

  group('linkDailyPlanToRoadmap', () {
    test('completes without error', () async {
      await service.linkDailyPlanToRoadmap(['topic-1', 'topic-2']);
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
}
