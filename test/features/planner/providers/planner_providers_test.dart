import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/roadmap_model.dart';
import 'package:studyking/core/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/plan_repository.dart';
import 'package:studyking/core/data/repositories/roadmap_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/models/pending_action_model.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

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
}

class _MockMasteryRepository extends MasteryGraphRepository {
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
  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async => null;

  @override
  Future<List<Topic>> getBySubject(String subjectId) async => [];
}

class _MockRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _roadmaps = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    return _roadmaps.values.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    _roadmaps[roadmap.id] = roadmap;
  }

  @override
  Future<RoadmapModel?> loadRoadmap(String id) async => _roadmaps[id];

  @override
  Future<List<RoadmapModel>> getAllRoadmaps() async => _roadmaps.values.toList();

  @override
  Future<void> deleteRoadmap(String id) async {
    _roadmaps.remove(id);
  }
}

class _MockTutorRepo extends TutorSessionRepository {
  final Map<String, TutorSession> _sessions = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> saveSession(TutorSession session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<TutorSession?> getSession(String id) async => _sessions[id];

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    return _sessions.values.where((s) => s.studentId == studentId).toList();
  }
}

class _MockPendingActionRepo extends PendingActionRepository {
  final Map<String, PendingActionModel> _actions = {};

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
    final action = _actions[id];
    if (action != null) {
      _actions[id] = action.copyWith(status: 'completed');
    }
  }

  @override
  Future<void> markRejected(String id) async {
    final action = _actions[id];
    if (action != null) {
      _actions[id] = action.copyWith(status: 'rejected');
    }
  }

  void addAction(PendingActionModel action) => _actions[action.id] = action;
}

class _MockPlanAdapter extends PlanAdapter {
  _MockPlanAdapter() : super();

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    return Result.success(const AdherenceDeviation());
  }

  @override
  Future<Result<Map<String, dynamic>>> getAdherenceReport(String studentId) async {
    return Result.success({'totalDays': 0, 'averageAdherence': 1.0, 'lowAdherenceDays': 0, 'weeklyTrend': <double>[]});
  }

  @override
  Future<Result<PersonalLearningPlan?>> suggestRegeneration({required String studentId, double? adjustmentFactor}) async {
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
  group('PlannerNotifier', () {
    late _MockPlanRepository planRepo;
    late _MockMasteryRepository masteryRepo;
    late _MockTopicRepository topicRepo;
    late _MockRoadmapRepository roadmapRepo;
    late _MockTutorRepo tutorRepo;
    late _MockPendingActionRepo pendingActionRepo;
    late _MockPlanAdapter planAdapter;
    late PlannerService service;
    late PlannerNotifier notifier;

    setUp(() {
      Hive.init(Directory.systemTemp.createTempSync('planner_prov_test_').path);
      planRepo = _MockPlanRepository();
      masteryRepo = _MockMasteryRepository();
      topicRepo = _MockTopicRepository();
      roadmapRepo = _MockRoadmapRepository();
      tutorRepo = _MockTutorRepo();
      pendingActionRepo = _MockPendingActionRepo();
      planAdapter = _MockPlanAdapter();

      service = PlannerService(
        planRepo: planRepo,
        masteryService: MasteryGraphService(repository: masteryRepo),
        repository: masteryRepo,
        topicRepository: topicRepo,
        roadmapRepo: roadmapRepo,
        tutorRepo: tutorRepo,
        pendingActionRepo: pendingActionRepo,
        planAdapter: planAdapter,
        fixedStudentId: 'test-student',
      );

      notifier = PlannerNotifier(service);
    });

    group('initial state', () {
      test('starts with default state', () {
        expect(notifier.currentState.plan, isNull);
        expect(notifier.currentState.roadmaps, isEmpty);
        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.pendingActions, isEmpty);
        expect(notifier.currentState.activeTab, 0);
      });
    });

    group('setActiveTab', () {
      test('updates active tab index', () {
        notifier.setActiveTab(1);
        expect(notifier.currentState.activeTab, 1);
      });
    });

    group('clearMessages', () {
      test('clears error and success message', () {
        notifier.currentState = notifier.currentState.copyWith(error: 'test error', successMessage: 'test success');
        notifier.clearMessages();
        expect(notifier.currentState.error, isNull);
        expect(notifier.currentState.successMessage, isNull);
      });
    });

    group('generatePlan', () {
      test('sets generating state during generation', () async {
        final future = notifier.generatePlan(
          course: 'Physics',
          daysValue: 7,
          hoursValue: 2,
        );

        expect(notifier.currentState.isGenerating, true);
        await future;
        expect(notifier.currentState.isGenerating, false);
      });

      test('stores plan on success', () async {
        await notifier.generatePlan(
          course: 'Physics',
          daysValue: 3,
          hoursValue: 1,
        );

        expect(notifier.currentState.plan, isNotNull);
        expect(notifier.currentState.plan!.studentId, 'test-student');
      });

      test('sets success message on generation', () async {
        await notifier.generatePlan(
          course: 'Physics',
          daysValue: 3,
          hoursValue: 1,
        );

        expect(notifier.currentState.successMessage, isNotNull);
      });
    });

    group('generatePlanFromSyllabus', () {
      test('generates plan from syllabus goals', () async {
        await notifier.generatePlanFromSyllabus(
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

        expect(notifier.currentState.plan, isNotNull);
        expect(notifier.currentState.plan!.syllabusGoals, hasLength(1));
      });

      test('sets generating state', () async {
        final future = notifier.generatePlanFromSyllabus(
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

        expect(notifier.currentState.isGenerating, true);
        await future;
        expect(notifier.currentState.isGenerating, false);
      });
    });

    group('createRoadmap', () {
      test('creates roadmap and adds to roadmaps list', () async {
        final l10n = AppLocalizationsEn();

        await notifier.createRoadmap(
          goal: 'Learn Physics',
          days: 30,
          l10n: l10n,
        );

        expect(notifier.currentState.roadmaps, isNotEmpty);
        expect(notifier.currentState.roadmaps.first.goal, 'Learn Physics');
      });

      test('creates roadmap with subject id', () async {
        final l10n = AppLocalizationsEn();

        await notifier.createRoadmap(
          goal: 'Learn Physics',
          days: 14,
          l10n: l10n,
          subjectId: 'sub_physics',
        );

        expect(notifier.currentState.roadmaps.first.subjectId, 'sub_physics');
      });
    });

    group('toggleMilestoneCompletion', () {
      test('toggles milestone and updates roadmaps', () async {
        final l10n = AppLocalizationsEn();

        await notifier.createRoadmap(
          goal: 'Learn Physics',
          days: 14,
          l10n: l10n,
        );

        final roadmap = notifier.currentState.roadmaps.first;
        final milestoneId = roadmap.milestones.first.id;

        await notifier.toggleMilestoneCompletion(
          roadmapId: roadmap.id,
          milestoneId: milestoneId,
          isCompleted: true,
        );

        final updated = notifier.currentState.roadmaps.first;
        final milestone = updated.milestones.firstWhere((m) => m.id == milestoneId);
        expect(milestone.isCompleted, true);
      });
    });

    group('scheduleLesson', () {
      test('schedules lesson and refreshes scheduled lessons', () async {
        final success = await notifier.scheduleLesson(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: DateTime.now().add(const Duration(days: 1)),
          durationMinutes: 30,
        );

        expect(success, true);
        expect(notifier.currentState.scheduledLessons, hasLength(1));
      });
    });

    group('pending actions', () {
      test('acceptPendingAction removes from pending list', () async {
        pendingActionRepo.addAction(PendingActionModel(
          id: 'action-1',
          studentId: 'test-student',
          actionType: 'schedule',
          status: 'pending',
        ));

        await notifier.loadPendingActions();
        expect(notifier.currentState.pendingActions, hasLength(1));

        await notifier.acceptPendingAction('action-1');
        expect(notifier.currentState.pendingActions, isEmpty);
      });

      test('dismissPendingAction removes from pending list', () async {
        pendingActionRepo.addAction(PendingActionModel(
          id: 'action-2',
          studentId: 'test-student',
          actionType: 'schedule',
          status: 'pending',
        ));

        await notifier.loadPendingActions();
        expect(notifier.currentState.pendingActions, hasLength(1));

        await notifier.dismissPendingAction('action-2');
        expect(notifier.currentState.pendingActions, isEmpty);
      });
    });

    group('regenerateFromAdherence', () {
      test('shows error when plan adapter returns null', () async {
        await notifier.regenerateFromAdherence();
        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.error, isNotNull);
      });
    });

    group('loadInitialData', () {
      test('loads plan and roadmaps', () async {
        await notifier.loadInitialData();
        // Plan is null since none saved, roadmaps empty
        expect(notifier.currentState.plan, isNull);
        expect(notifier.currentState.roadmaps, isEmpty);
      });
    });

    group('loadAdditionalData', () {
      test('loads pending actions and scheduled lessons', () async {
        await notifier.loadAdditionalData();
        expect(notifier.currentState.pendingActions, isEmpty);
        expect(notifier.currentState.scheduledLessons, isEmpty);
      });
    });
  });
}
