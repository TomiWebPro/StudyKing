import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/data/adapters.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

class _FakePlanRepository extends PlanRepository {
  PersonalLearningPlan? _plan;
  bool _throwOnLoadPlan = false;
  final bool _throwOnSavePlan = false;

  void setThrowOnLoadPlan() => _throwOnLoadPlan = true;
  void setPlan(PersonalLearningPlan p) => _plan = p;

  @override
  Future<void> init() async {}

  @override
  Future<PersonalLearningPlan?> loadPlan(String studentId) async {
    if (_throwOnLoadPlan) throw Exception('load plan error');
    return _plan;
  }

  @override
  Future<void> savePlan(PersonalLearningPlan plan) async {
    if (_throwOnSavePlan) throw Exception('save plan error');
    _plan = plan;
  }
}

class _FakeMasteryRepository extends MasteryGraphRepository {
  bool _throwOnGetAllMasteryStates = false;
  bool _returnFailureOnGetAllMasteryStates = false;
  final Map<String, MasteryState> _masteryStates = {};
  final List<TopicDependency> _dependencies = [];

  void setThrowOnGetAllMasteryStates() =>
      _throwOnGetAllMasteryStates = true;
  void setReturnFailure() =>
      _returnFailureOnGetAllMasteryStates = true;
  void addMasteryState(MasteryState state) {
    _masteryStates['${state.studentId}_${state.topicId}'] = state;
  }
  void addDependency(TopicDependency dep) => _dependencies.add(dep);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    if (_throwOnGetAllMasteryStates) throw Exception('mastery error');
    if (_returnFailureOnGetAllMasteryStates) {
      return Result.failure('mastery repo failure');
    }
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
  Future<void> init() async {}

  @override
  Future<Result<Topic?>> get(String id) async => Result.success(_topics[id]);

  @override
  Future<List<Topic>> getBySubject(String subjectId) async {
    return _topics.values.where((t) => t.subjectId == subjectId).toList();
  }
}

class _FakeRoadmapRepository extends RoadmapRepository {
  final Map<String, RoadmapModel> _roadmaps = {};
  bool _throwOnGetRoadmaps = false;
  bool _throwOnSaveRoadmap = false;
  bool _throwOnLoadRoadmap = false;

  void setThrowOnGetRoadmaps() => _throwOnGetRoadmaps = true;
  void setThrowOnSaveRoadmap() => _throwOnSaveRoadmap = true;
  void setThrowOnLoadRoadmap() => _throwOnLoadRoadmap = true;
  void addRoadmap(RoadmapModel r) => _roadmaps[r.id] = r;

  @override
  Future<void> init() async {}

  @override
  Future<List<RoadmapModel>> getRoadmapsByStudent(String studentId) async {
    if (_throwOnGetRoadmaps) throw Exception('get roadmaps error');
    return _roadmaps.values.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<void> saveRoadmap(RoadmapModel roadmap) async {
    if (_throwOnSaveRoadmap) throw Exception('save roadmap error');
    _roadmaps[roadmap.id] = roadmap;
  }

  @override
  Future<RoadmapModel?> loadRoadmap(String id) async {
    if (_throwOnLoadRoadmap) throw Exception('load roadmap error');
    return _roadmaps[id];
  }

  @override
  Future<List<RoadmapModel>> getAllRoadmaps() async => _roadmaps.values.toList();

  @override
  Future<void> deleteRoadmap(String id) async {
    _roadmaps.remove(id);
  }
}

class _FakeSessionRepo extends SessionRepository {
  final Map<String, Session> _sessions = {};
  bool _throwOnGetSessions = false;

  void setThrowOnGetSessions() => _throwOnGetSessions = true;
  void addSession(Session s) => _sessions[s.id] = s;

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> save(String key, Session session) async {
    _sessions[session.id] = session;
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async => Result.success(_sessions[id]);

  @override
  Future<Result<List<Session>>> getAll() async {
    if (_throwOnGetSessions) throw Exception('get sessions error');
    return Result.success(_sessions.values.toList());
  }
}

class _FakePendingActionRepo extends PendingActionRepository {
  final Map<String, PendingActionModel> _actions = {};
  bool _throwOnGetPending = false;

  void setThrowOnGetPending() => _throwOnGetPending = true;
  void addAction(PendingActionModel action) => _actions[action.id] = action;

  @override
  Future<void> init() async {}

  @override
  Future<List<PendingActionModel>> getPending(String studentId) async {
    if (_throwOnGetPending) throw Exception('get pending error');
    return _actions.values
        .where((a) => a.studentId == studentId && a.status == 'pending')
        .toList();
  }

  @override
  Future<Result<PendingActionModel?>> get(String id) async => Result.success(_actions[id]);

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
}

class _FakeAdherenceRepo extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _records = [];
  bool _throwOnInit = false;

  void addRecord(PlanAdherenceModel record) => _records.add(record);
  void setThrowOnInit() => _throwOnInit = true;

  @override
  Future<void> init() async {
    if (_throwOnInit) throw Exception('adherence init error');
  }

  @override
  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    return _records.where((r) => r.studentId == studentId).toList();
  }
}

class _FakePlanAdapter extends PlanAdapter {
  _FakePlanAdapter() : super();

  AdherenceDeviation? _deviation;
  PersonalLearningPlan? _regeneratedPlan;
  bool _throwOnCheckAdherence = false;
  bool _throwOnSuggestRegeneration = false;

  void setDeviation(AdherenceDeviation d) => _deviation = d;
  void setRegeneratedPlan(PersonalLearningPlan p) => _regeneratedPlan = p;
  void setThrowOnCheckAdherence() => _throwOnCheckAdherence = true;
  void setThrowOnSuggestRegeneration() => _throwOnSuggestRegeneration = true;

  @override
  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    if (_throwOnCheckAdherence) throw Exception('check adherence error');
    if (_deviation != null) return Result.success(_deviation!);
    return Result.success(const AdherenceDeviation());
  }

  @override
  Future<Result<Map<String, dynamic>>> getAdherenceReport(String studentId) async {
    return Result.success({'totalDays': 0, 'averageAdherence': 1.0, 'lowAdherenceDays': 0, 'weeklyTrend': <double>[]});
  }

  @override
  Future<Result<PersonalLearningPlan?>> suggestRegeneration({required String studentId, double? adjustmentFactor}) async {
    if (_throwOnSuggestRegeneration) throw Exception('suggest regeneration error');
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

class _FakeErrorPlannerService extends PlannerService {
  final bool throwOnScheduleLesson;
  final bool throwOnAcceptPendingAction;
  final bool throwOnDismissPendingAction;
  final bool throwOnRedistribute;

  _FakeErrorPlannerService({
    required PlanRepository planRepo,
    required MasteryGraphService masteryService,
    required TopicRepository topicRepository,
    required RoadmapRepository roadmapRepo,
    required SessionRepository sessionRepo,
    required PendingActionRepository pendingActionRepo,
    required PlanAdapter planAdapter,
    super.fixedStudentId,
    super.repository,
    this.throwOnScheduleLesson = false,
    this.throwOnAcceptPendingAction = false,
    this.throwOnDismissPendingAction = false,
    this.throwOnRedistribute = false,
  }) : super(
    planRepo: planRepo,
    masteryService: masteryService,
    topicRepository: topicRepository,
    roadmapRepo: roadmapRepo,
    sessionRepo: sessionRepo,
    pendingActionRepo: pendingActionRepo,
    planAdapter: planAdapter,
  );

  @override
  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    if (throwOnScheduleLesson) throw Exception('schedule error');
    return super.scheduleLesson(
      topicId: topicId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      scheduledTime: scheduledTime,
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<bool> acceptPendingAction(String actionId) async {
    if (throwOnAcceptPendingAction) throw Exception('accept error');
    return super.acceptPendingAction(actionId);
  }

  @override
  Future<bool> dismissPendingAction(String actionId) async {
    if (throwOnDismissPendingAction) throw Exception('dismiss error');
    return super.dismissPendingAction(actionId);
  }

  @override
  Future<void> redistributeWorkload(int missedMinutes) async {
    if (throwOnRedistribute) throw Exception('redistribute error');
    return super.redistributeWorkload(missedMinutes);
  }
}

PlannerService _createService({
  _FakePlanRepository? planRepo,
  _FakeMasteryRepository? masteryRepo,
  _FakeTopicRepository? topicRepo,
  _FakeRoadmapRepository? roadmapRepo,
  _FakeSessionRepo? sessionRepo,
  _FakePendingActionRepo? pendingActionRepo,
  _FakePlanAdapter? planAdapter,
  _FakeAdherenceRepo? adherenceRepo,
  SyllabusResolver? syllabusResolver,
  String? fixedStudentId,
}) {
  final pRepo = planRepo ?? _FakePlanRepository();
  final mRepo = masteryRepo ?? _FakeMasteryRepository();
  final tRepo = topicRepo ?? _FakeTopicRepository();
  final rRepo = roadmapRepo ?? _FakeRoadmapRepository();
  final sRepo = sessionRepo ?? _FakeSessionRepo();
  final paRepo = pendingActionRepo ?? _FakePendingActionRepo();
  final adapter = planAdapter ?? _FakePlanAdapter();
  final resolver = syllabusResolver ?? SyllabusResolver(
    topicRepository: tRepo,
    masteryRepository: mRepo,
  );
  return PlannerService(
    planRepo: pRepo,
    masteryService: MasteryGraphService(repository: mRepo),
    repository: mRepo,
    topicRepository: tRepo,
    roadmapRepo: rRepo,
    sessionRepo: sRepo,
    pendingActionRepo: paRepo,
    planAdapter: adapter,
    adherenceRepo: adherenceRepo,
    syllabusResolver: resolver,
    fixedStudentId: fixedStudentId ?? 'test-student',
  );
}

void main() {
  group('PlannerState', () {
    test('default state has correct initial values', () {
      const state = PlannerState();
      expect(state.plan, isNull);
      expect(state.roadmaps, isEmpty);
      expect(state.isGenerating, false);
      expect(state.isLoadingRoadmaps, false);
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
      expect(state.pendingActions, isEmpty);
      expect(state.scheduledLessons, isEmpty);
      expect(state.adherenceDeviation, isNull);
      expect(state.activeTab, 0);
    });

    test('clearMessages clears error and successMessage', () {
      final state = PlannerState(error: 'err', successMessage: 'ok')
          .clearMessages();
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
    });

    test('copyWith preserves existing values for null fields', () {
      final state = PlannerState(
        plan: null,
        roadmaps: const [],
        isGenerating: true,
        error: 'err',
        successMessage: 'ok',
        activeTab: 2,
      );
      final copied = state.copyWith(activeTab: 3);
      expect(copied.isGenerating, true);
      expect(copied.error, isNull);
      expect(copied.successMessage, isNull);
      expect(copied.activeTab, 3);
    });
  });

  group('PlannerNotifier', () {
    late _FakePlanRepository planRepo;
    late _FakeMasteryRepository masteryRepo;
    late AppLocalizationsEn l10n;
    late _FakeTopicRepository topicRepo;
    late _FakeRoadmapRepository roadmapRepo;
    late _FakeSessionRepo sessionRepo;
    late _FakePendingActionRepo pendingActionRepo;
    late _FakePlanAdapter planAdapter;
    late PlannerService service;
    late PlannerNotifier notifier;

    setUp(() {
      Hive.init(Directory.systemTemp.createTempSync('planner_providers_test_').path);
      registerPlannerAdapters();

      planRepo = _FakePlanRepository();
      masteryRepo = _FakeMasteryRepository();
      l10n = AppLocalizationsEn();
      topicRepo = _FakeTopicRepository();
      roadmapRepo = _FakeRoadmapRepository();
      sessionRepo = _FakeSessionRepo();
      pendingActionRepo = _FakePendingActionRepo();
      planAdapter = _FakePlanAdapter();

      final syllabusResolver = SyllabusResolver(
        topicRepository: topicRepo,
        masteryRepository: masteryRepo,
      );

      service = _createService(
        planRepo: planRepo,
        masteryRepo: masteryRepo,
        topicRepo: topicRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planAdapter: planAdapter,
        syllabusResolver: syllabusResolver,
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

      test('updates to different indices', () {
        notifier.setActiveTab(2);
        expect(notifier.currentState.activeTab, 2);
        notifier.setActiveTab(0);
        expect(notifier.currentState.activeTab, 0);
      });
    });

    group('clearMessages', () {
      test('clears error and success message', () {
        notifier.currentState = notifier.currentState.copyWith(
          error: 'test error',
          successMessage: 'test success',
        );
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
          l10n: l10n,
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
          l10n: l10n,
        );

        expect(notifier.currentState.plan, isNotNull);
        expect(notifier.currentState.plan!.studentId, 'test-student');
      });

      test('sets success message on generation', () async {
        await notifier.generatePlan(
          course: 'Physics',
          daysValue: 3,
          hoursValue: 1,
          l10n: l10n,
        );

        expect(notifier.currentState.successMessage, isNotNull);
      });

      test('sets error when service returns null', () async {
        masteryRepo.setReturnFailure();

        await notifier.generatePlan(
          course: 'Physics',
          daysValue: 3,
          hoursValue: 1,
          l10n: l10n,
        );

        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.error, l10n.failedToGeneratePlan);
      });

      test('sets error when service throws', () async {
        masteryRepo.setThrowOnGetAllMasteryStates();

        await notifier.generatePlan(
          course: 'Physics',
          daysValue: 3,
          hoursValue: 1,
          l10n: l10n,
        );

        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.error, contains('Error:'));
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
          l10n: l10n,
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
          l10n: l10n,
        );

        expect(notifier.currentState.isGenerating, true);
        await future;
        expect(notifier.currentState.isGenerating, false);
      });

      test('sets error when service returns null', () async {
        masteryRepo.setReturnFailure();

        await notifier.generatePlanFromSyllabus(
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
          l10n: l10n,
        );

        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.error, l10n.failedToGenerateSyllabusPlan);
      });

      test('sets error when service throws', () async {
        masteryRepo.setThrowOnGetAllMasteryStates();

        await notifier.generatePlanFromSyllabus(
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
          l10n: l10n,
        );

        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.error, contains('Error:'));
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

      test('sets error when service throws', () async {
        roadmapRepo.setThrowOnSaveRoadmap();
        final l10n = AppLocalizationsEn();

        await notifier.createRoadmap(
          goal: 'Learn Physics',
          days: 14,
          l10n: l10n,
        );

        expect(notifier.currentState.error, 'Failed to create roadmap');
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
          l10n: l10n,
        );

        final updated = notifier.currentState.roadmaps.first;
        final milestone = updated.milestones.firstWhere((m) => m.id == milestoneId);
        expect(milestone.isCompleted, true);
      });

      test('sets error when service throws', () async {
        final l10n = AppLocalizationsEn();
        await notifier.createRoadmap(
          goal: 'Learn Physics',
          days: 14,
          l10n: l10n,
        );
        final roadmap = notifier.currentState.roadmaps.first;
        roadmapRepo.setThrowOnLoadRoadmap();

        await notifier.toggleMilestoneCompletion(
          roadmapId: roadmap.id,
          milestoneId: 'nonexistent',
          isCompleted: true,
          l10n: l10n,
        );

        expect(notifier.currentState.error, 'Failed to update milestone');
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
          l10n: l10n,
        );

        expect(success, true);
        expect(notifier.currentState.scheduledLessons, hasLength(1));
      });

      test('returns true and sets success message', () async {
        final success = await notifier.scheduleLesson(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: DateTime.now().add(const Duration(days: 1)),
          l10n: l10n,
        );

        expect(success, true);
        expect(notifier.currentState.successMessage, 'Lesson scheduled');
      });

      test('sets error when service throws', () async {
        final fakeService = _FakeErrorPlannerService(
          planRepo: planRepo,
          masteryService: MasteryGraphService(repository: masteryRepo),
          repository: masteryRepo,
          topicRepository: topicRepo,
          roadmapRepo: roadmapRepo,
          sessionRepo: sessionRepo,
          pendingActionRepo: pendingActionRepo,
          planAdapter: planAdapter,
          fixedStudentId: 'test-student',
          throwOnScheduleLesson: true,
        );
        final throwingNotifier = PlannerNotifier(fakeService);

        final result = await throwingNotifier.scheduleLesson(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: DateTime.now(),
          l10n: l10n,
        );

        expect(result, false);
        expect(throwingNotifier.currentState.error, 'Failed to schedule lesson');
      });
    });

    group('cancelLesson', () {
      test('cancels lesson and removes from scheduled list', () async {
        await notifier.scheduleLesson(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: DateTime.now().add(const Duration(days: 1)),
          l10n: l10n,
        );
        expect(notifier.currentState.scheduledLessons, hasLength(1));

        final success = await notifier.cancelLesson(
          notifier.currentState.scheduledLessons.first.id,
          l10n,
        );
        expect(success, true);
        expect(notifier.currentState.successMessage, 'Session deleted');
      });

      test('sets error when service throws', () async {
        final fakeService = _FakeErrorPlannerService(
          planRepo: planRepo,
          masteryService: MasteryGraphService(repository: masteryRepo),
          repository: masteryRepo,
          topicRepository: topicRepo,
          roadmapRepo: roadmapRepo,
          sessionRepo: sessionRepo,
          pendingActionRepo: pendingActionRepo,
          planAdapter: planAdapter,
          fixedStudentId: 'test-student',
        );
        final throwingNotifier = PlannerNotifier(fakeService);

        final result = await throwingNotifier.cancelLesson(
          'nonexistent',
          l10n,
        );
        expect(result, false);
      });
    });

    group('rescheduleLesson', () {
      test('reschedules lesson successfully', () async {
        await notifier.scheduleLesson(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: DateTime.now().add(const Duration(days: 1)),
          l10n: l10n,
        );
        expect(notifier.currentState.scheduledLessons, hasLength(1));

        final sessionId = notifier.currentState.scheduledLessons.first.id;
        final newTime = DateTime.now().add(const Duration(days: 2));
        final success = await notifier.rescheduleLesson(
          sessionId: sessionId,
          newStartTime: newTime,
          durationMinutes: 45,
          l10n: l10n,
        );
        expect(success, true);
        expect(notifier.currentState.successMessage, 'Lesson scheduled');
      });

      test('returns false when session does not exist', () async {
        final result = await notifier.rescheduleLesson(
          sessionId: 'nonexistent',
          newStartTime: DateTime.now(),
          durationMinutes: 30,
          l10n: l10n,
        );
        expect(result, false);
      });
    });

    group('pending actions', () {
      test('acceptPendingAction removes from pending list', () async {
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

        await notifier.loadPendingActions();
        expect(notifier.currentState.pendingActions, hasLength(1));

        await notifier.acceptPendingAction('action-1', l10n);
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

        await notifier.dismissPendingAction('action-2', l10n);
        expect(notifier.currentState.pendingActions, isEmpty);
      });

      test('acceptPendingAction sets success message', () async {
        pendingActionRepo.addAction(PendingActionModel(
          id: 'action-3',
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
        await notifier.loadPendingActions();

        await notifier.acceptPendingAction('action-3', l10n);

        expect(notifier.currentState.successMessage, 'Action accepted');
      });

      test('acceptPendingAction sets error when service throws', () async {
        final fakeService = _FakeErrorPlannerService(
          planRepo: planRepo,
          masteryService: MasteryGraphService(repository: masteryRepo),
          repository: masteryRepo,
          topicRepository: topicRepo,
          roadmapRepo: roadmapRepo,
          sessionRepo: sessionRepo,
          pendingActionRepo: pendingActionRepo,
          planAdapter: planAdapter,
          fixedStudentId: 'test-student',
          throwOnAcceptPendingAction: true,
        );
        final throwingNotifier = PlannerNotifier(fakeService);

        pendingActionRepo.addAction(PendingActionModel(
          id: 'action-4',
          studentId: 'test-student',
          actionType: 'schedule',
          status: 'pending',
        ));

        await throwingNotifier.acceptPendingAction('action-4', l10n);

        expect(throwingNotifier.currentState.error, 'Failed to accept action');
      });

      test('dismissPendingAction sets error when service throws', () async {
        final fakeService = _FakeErrorPlannerService(
          planRepo: planRepo,
          masteryService: MasteryGraphService(repository: masteryRepo),
          repository: masteryRepo,
          topicRepository: topicRepo,
          roadmapRepo: roadmapRepo,
          sessionRepo: sessionRepo,
          pendingActionRepo: pendingActionRepo,
          planAdapter: planAdapter,
          fixedStudentId: 'test-student',
          throwOnDismissPendingAction: true,
        );
        final throwingNotifier = PlannerNotifier(fakeService);

        pendingActionRepo.addAction(PendingActionModel(
          id: 'action-5',
          studentId: 'test-student',
          actionType: 'schedule',
          status: 'pending',
        ));

        await throwingNotifier.dismissPendingAction('action-5', l10n);

        expect(throwingNotifier.currentState.error, 'Failed to dismiss action');
      });

      test('acceptPendingAction on non-existent action', () async {
        await notifier.acceptPendingAction('non-existent', l10n);

        expect(notifier.currentState.error, 'Failed to execute action — missing parameters');
        expect(notifier.currentState.successMessage, isNull);
      });
    });

    group('regenerateFromAdherence', () {
      test('shows error when plan adapter returns null', () async {
        await notifier.regenerateFromAdherence(l10n);
        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.error, isNotNull);
      });

      test('regenerates plan successfully', () async {
        planAdapter.setRegeneratedPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0.0,
            focusAreas: [],
          ),
          recommendations: [],
        ));

        await notifier.regenerateFromAdherence(l10n);

        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.plan, isNotNull);
        expect(notifier.currentState.successMessage, 'Plan regenerated based on your adherence');
      });

      test('sets error when service throws', () async {
        planAdapter.setThrowOnSuggestRegeneration();

        await notifier.regenerateFromAdherence(l10n);

        expect(notifier.currentState.isGenerating, false);
        expect(notifier.currentState.error, contains('Error:'));
      });
    });

    group('loadExistingPlan', () {
      test('loads plan into state when plan exists', () async {
        planRepo.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0.0,
            focusAreas: [],
          ),
          recommendations: [],
        ));

        await notifier.loadExistingPlan();

        expect(notifier.currentState.plan, isNotNull);
        expect(notifier.currentState.plan!.studentId, 'test-student');
      });

      test('does not update state when no plan exists', () async {
        await notifier.loadExistingPlan();

        expect(notifier.currentState.plan, isNull);
      });

      test('handles exception gracefully', () async {
        planRepo.setThrowOnLoadPlan();

        await notifier.loadExistingPlan();

        expect(notifier.currentState.plan, isNull);
      });
    });

    group('loadRoadmaps', () {
      test('loads roadmaps into state', () async {
        roadmapRepo.addRoadmap(RoadmapModel(
          id: 'rm-1',
          studentId: 'test-student',
          goal: 'Learn Dart',
          createdAt: DateTime.now(),
        ));

        await notifier.loadRoadmaps();

        expect(notifier.currentState.roadmaps, hasLength(1));
        expect(notifier.currentState.roadmaps.first.goal, 'Learn Dart');
        expect(notifier.currentState.isLoadingRoadmaps, false);
      });

      test('handles exception gracefully', () async {
        notifier.currentState = notifier.currentState.copyWith(
          roadmaps: [],
          isLoadingRoadmaps: false,
        );
        roadmapRepo.setThrowOnGetRoadmaps();

        await notifier.loadRoadmaps();

        expect(notifier.currentState.isLoadingRoadmaps, false);
        expect(notifier.currentState.roadmaps, isEmpty);
      });
    });

    group('loadPendingActions', () {
      test('loads pending actions into state', () async {
        pendingActionRepo.addAction(PendingActionModel(
          id: 'pa-1',
          studentId: 'test-student',
          actionType: 'review',
          status: 'pending',
        ));

        await notifier.loadPendingActions();

        expect(notifier.currentState.pendingActions, hasLength(1));
        expect(notifier.currentState.pendingActions.first.id, 'pa-1');
      });

      test('handles exception gracefully', () async {
        pendingActionRepo.setThrowOnGetPending();

        await notifier.loadPendingActions();

        expect(notifier.currentState.pendingActions, isEmpty);
      });
    });

    group('loadScheduledLessons', () {
      test('loads scheduled lessons into state', () async {
        sessionRepo.addSession(Session(
          id: 'ts-1',
          studentId: 'test-student',
          subjectId: 'sub_physics',
          topicId: 'topic-1',
          startTime: DateTime.now().add(const Duration(days: 1)),
          type: SessionType.tutoring,
          status: SessionStatus.planned,
          tutorMetadata: TutorMetadata(topicTitle: 'Kinematics'),
        ));

        await notifier.loadScheduledLessons();

        expect(notifier.currentState.scheduledLessons, hasLength(1));
        expect(notifier.currentState.scheduledLessons.first.id, 'ts-1');
      });

      test('handles exception gracefully', () async {
        sessionRepo.setThrowOnGetSessions();

        await notifier.loadScheduledLessons();

        expect(notifier.currentState.scheduledLessons, isEmpty);
      });
    });

    group('checkAdherence', () {
      test('updates state with adherence deviation', () async {
        planAdapter.setDeviation(const AdherenceDeviation(
          consecutiveLowDays: 5,
          averageAdherence: 0.4,
          requiresRegeneration: true,
          message: 'Low adherence detected',
        ));

        await notifier.checkAdherence();

        expect(notifier.currentState.adherenceDeviation, isNotNull);
        expect(notifier.currentState.adherenceDeviation!.consecutiveLowDays, 5);
        expect(notifier.currentState.adherenceDeviation!.requiresRegeneration, true);
      });

      test('sets default deviation when adapter returns no significant deviation', () async {
        await notifier.checkAdherence();

        expect(notifier.currentState.adherenceDeviation, isNotNull);
        expect(notifier.currentState.adherenceDeviation!.consecutiveLowDays, 0);
        expect(notifier.currentState.adherenceDeviation!.requiresRegeneration, false);
      });

      test('handles exception gracefully', () async {
        planAdapter.setThrowOnCheckAdherence();

        await notifier.checkAdherence();

        expect(notifier.currentState.adherenceDeviation, isNull);
      });
    });

    group('loadInitialData', () {
      test('loads plan and roadmaps', () async {
        await notifier.loadInitialData();
        expect(notifier.currentState.plan, isNull);
        expect(notifier.currentState.roadmaps, isEmpty);
      });

      test('loads plan and roadmaps when data exists', () async {
        planRepo.setPlan(PersonalLearningPlan(
          studentId: 'test-student',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0,
            totalMinutes: 0,
            newTopics: 0,
            reviewTopics: 0,
            estimatedCoverage: 0.0,
            focusAreas: [],
          ),
          recommendations: [],
        ));
        roadmapRepo.addRoadmap(RoadmapModel(
          id: 'rm-init',
          studentId: 'test-student',
          goal: 'Master Math',
          createdAt: DateTime.now(),
        ));

        await notifier.loadInitialData();

        expect(notifier.currentState.plan, isNotNull);
        expect(notifier.currentState.roadmaps, hasLength(1));
        expect(notifier.currentState.roadmaps.first.goal, 'Master Math');
      });
    });

    group('loadAdditionalData', () {
      test('loads pending actions, scheduled lessons, and adherence', () async {
        await notifier.loadAdditionalData();
        expect(notifier.currentState.pendingActions, isEmpty);
        expect(notifier.currentState.scheduledLessons, isEmpty);
      });

      test('loads data when actions and deviations exist', () async {
        pendingActionRepo.addAction(PendingActionModel(
          id: 'pa-add',
          studentId: 'test-student',
          actionType: 'practice',
          status: 'pending',
        ));
        sessionRepo.addSession(Session(
          id: 'ts-add',
          studentId: 'test-student',
          subjectId: 'sub_physics',
          topicId: 'topic-2',
          startTime: DateTime.now().add(const Duration(days: 2)),
          type: SessionType.tutoring,
          status: SessionStatus.planned,
          tutorMetadata: TutorMetadata(topicTitle: 'Vectors'),
        ));
        planAdapter.setDeviation(const AdherenceDeviation(
          consecutiveLowDays: 3,
          averageAdherence: 0.5,
          requiresRegeneration: true,
          message: 'Consider regenerating',
        ));

        await notifier.loadAdditionalData();

        expect(notifier.currentState.pendingActions, hasLength(1));
        expect(notifier.currentState.scheduledLessons, hasLength(1));
        expect(notifier.currentState.adherenceDeviation, isNotNull);
      });
    });

    group('scheduleLessonWithConflictCheck', () {
      test('schedules lesson when no conflict', () async {
        final success = await notifier.scheduleLessonWithConflictCheck(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: DateTime.now().add(const Duration(days: 1)),
          l10n: l10n,
        );
        expect(success, true);
        expect(notifier.currentState.scheduledLessons, hasLength(1));
        expect(notifier.currentState.successMessage, 'Lesson scheduled');
      });

      test('rejects when time conflict exists', () async {
        final baseTime = DateTime.now().add(const Duration(days: 1));
        await notifier.scheduleLesson(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: baseTime,
          durationMinutes: 60,
          l10n: l10n,
        );
        final success = await notifier.scheduleLessonWithConflictCheck(
          topicId: 'topic-2',
          topicTitle: 'Vectors',
          subjectId: 'sub_physics',
          scheduledTime: baseTime.add(const Duration(minutes: 30)),
          durationMinutes: 30,
          l10n: l10n,
        );
        expect(success, false);
        expect(notifier.currentState.error, 'Time conflict with existing scheduled lesson');
      });

      test('sets error when service throws', () async {
        sessionRepo.setThrowOnGetSessions();
        final result = await notifier.scheduleLessonWithConflictCheck(
          topicId: 'topic-1',
          topicTitle: 'Kinematics',
          subjectId: 'sub_physics',
          scheduledTime: DateTime.now().add(const Duration(days: 1)),
          l10n: l10n,
        );
        expect(result, false);
        expect(notifier.currentState.error, 'Failed to schedule lesson');
      });
    });

    group('redistributeWorkload', () {
      test('redistributes successfully and sets success message', () async {
        await notifier.redistributeWorkload(30, l10n);
        expect(notifier.currentState.successMessage, 'Missed workload redistributed over next 3 days');
      });

      test('sets error on failure', () async {
        final failingService = _FakeErrorPlannerService(
          planRepo: planRepo,
          masteryService: MasteryGraphService(repository: masteryRepo),
          repository: masteryRepo,
          topicRepository: topicRepo,
          roadmapRepo: roadmapRepo,
          sessionRepo: sessionRepo,
          pendingActionRepo: pendingActionRepo,
          planAdapter: planAdapter,
          fixedStudentId: 'test-student',
          throwOnRedistribute: true,
        );
        final failingNotifier = PlannerNotifier(failingService);
        await failingNotifier.redistributeWorkload(30, l10n);
        expect(failingNotifier.currentState.error, 'Failed to redistribute workload');
      });
    });

    group('linkDailyPlanToRoadmap', () {
      test('completes without error when called', () async {
        await notifier.linkDailyPlanToRoadmap(['topic-1', 'topic-2']);
        expect(notifier.currentState.roadmaps, isEmpty);
      });

      test('updates roadmaps when roadmaps exist', () async {
        roadmapRepo.addRoadmap(RoadmapModel(
          id: 'rm-1',
          studentId: 'test-student',
          goal: 'Learn Physics',
          createdAt: DateTime.now(),
        ));
        await notifier.linkDailyPlanToRoadmap(['topic-1']);
        expect(notifier.currentState.roadmaps, hasLength(1));
      });

      test('handles exception gracefully when service throws', () async {
        roadmapRepo.setThrowOnGetRoadmaps();
        await notifier.linkDailyPlanToRoadmap(['topic-1']);
        expect(notifier.currentState.roadmaps, isEmpty);
      });
    });
  });

  group('plannerServiceProvider', () {
    test('creates PlannerService with overridden value', () {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(_createService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(plannerServiceProvider);
      expect(service, isA<PlannerService>());
    });
  });

  group('plannerProvider', () {
    test('creates PlannerNotifier with PlannerService', () {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(
            _createService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(plannerProvider.notifier);
      expect(notifier, isA<PlannerNotifier>());
      expect(notifier.currentState, isA<PlannerState>());
      expect(notifier.currentState.activeTab, 0);
    });

    test('can set active tab through provider', () {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(
            _createService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(plannerProvider.notifier);
      notifier.setActiveTab(2);

      expect(container.read(plannerProvider).activeTab, 2);
    });
  });

  group('planProgressProvider', () {
    test('returns default data when no plan exists', () async {
      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(
            _createService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final progress = await container.read(planProgressProvider.future);
      expect(progress.plannedMinutesToday, 0);
      expect(progress.actualMinutesToday, 0);
      expect(progress.todayProgress, 0.0);
      expect(progress.totalPlanDays, 0);
      expect(progress.completedDays, 0);
      expect(progress.cumulativeProgress, 0.0);
    });

    test('computes progress from plan with adherence records', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final todayPlan = DailyPlan(
        date: now,
        dayNumber: 1,
        priorityTopics: [],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        targetQuestions: 15,
        targetMinutes: 60,
      );

      final plan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [todayPlan],
        summary: PlanSummary(
          totalQuestions: 150,
          totalMinutes: 600,
          newTopics: 5,
          reviewTopics: 3,
          estimatedCoverage: 0.8,
          focusAreas: [],
        ),
        recommendations: [],
      );

      final planRepo = _FakePlanRepository();
      planRepo.setPlan(plan);

      final adherenceRepo = _FakeAdherenceRepo();
      adherenceRepo.addRecord(PlanAdherenceModel(
        id: 'ad-1',
        studentId: 'test-student',
        date: todayStart,
        plannedMinutes: 60,
        actualMinutes: 45,
        plannedQuestions: 15,
        actualQuestions: 10,
        adherenceScore: 0.75,
      ));

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(
            _createService(
              planRepo: planRepo,
              adherenceRepo: adherenceRepo,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final progress = await container.read(planProgressProvider.future);
      expect(progress.plannedMinutesToday, 60);
      expect(progress.actualMinutesToday, 45);
      expect(progress.plannedQuestionsToday, 15);
      expect(progress.actualQuestionsToday, 10);
      expect(progress.todayProgress, greaterThan(0));
      expect(progress.totalPlanDays, 1);
      expect(progress.completedDays, 1);
      expect(progress.cumulativeProgress, 1.0);
      expect(progress.weeklyProgress, hasLength(7));
    });

    test('todayProgress is clamped to 1.5', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final todayPlan = DailyPlan(
        date: now,
        dayNumber: 1,
        priorityTopics: [],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        targetQuestions: 10,
        targetMinutes: 30,
      );

      final plan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: now,
        dailyPlans: [todayPlan],
        summary: PlanSummary(
          totalQuestions: 100, totalMinutes: 300,
          newTopics: 3, reviewTopics: 2,
          estimatedCoverage: 0.5, focusAreas: [],
        ),
        recommendations: [],
      );
      final planRepo = _FakePlanRepository();
      planRepo.setPlan(plan);

      final adherenceRepo = _FakeAdherenceRepo();
      adherenceRepo.addRecord(PlanAdherenceModel(
        id: 'ad-over',
        studentId: 'test-student',
        date: todayStart,
        plannedMinutes: 30,
        actualMinutes: 60,
        plannedQuestions: 10,
        actualQuestions: 20,
        adherenceScore: 1.0,
      ));

      final container = ProviderContainer(
        overrides: [
          plannerServiceProvider.overrideWithValue(
            _createService(
              planRepo: planRepo,
              adherenceRepo: adherenceRepo,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final progress = await container.read(planProgressProvider.future);
      expect(progress.todayProgress, 1.5);
    });
  });
}
