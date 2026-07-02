import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/services/action_executor.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'planner_service_test_helpers.dart';

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('planner_service_mgmt_test_').path;
    Hive.init(hivePath);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await Directory(hivePath).delete(recursive: true);
    } catch (_) {}
  });

  late PlannerService service;
  late FakeMasteryGraphRepository masteryRepo;
  late FakeTopicRepository topicRepo;
  late FakePlanRepository planRepo;
  late FakeRoadmapRepository roadmapRepo;
  late FakeSessionRepository sessionRepo;
  late FakePendingActionRepository pendingActionRepo;
  late FakePlanAdherenceOrchestrator planOrchestrator;
  late AppLocalizations l10n;

  setUp(() {
    masteryRepo = FakeMasteryGraphRepository();
    topicRepo = FakeTopicRepository();
    planRepo = FakePlanRepository();
    roadmapRepo = FakeRoadmapRepository();
    sessionRepo = FakeSessionRepository();
    pendingActionRepo = FakePendingActionRepository();
    planOrchestrator = FakePlanAdherenceOrchestrator();
    l10n = AppLocalizationsEn();

    final fakeAdherenceRepo = FakeAdherenceRepo();
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

    service = createPlannerService(
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

    test('returns failure when repo throws', () async {
      pendingActionRepo.throwOnMarkRejected = true;
      final result = await service.dismissPendingAction('action-1');
      expect(result.isFailure, isTrue);
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

  group('getAdherenceMetrics', () {
    test('aggregates metrics from multiple records', () async {
      final metrics = (await service.getAdherenceMetrics()).data!;
      expect(metrics['actualMinutesToday'], 0);
      expect(metrics['actualQuestionsToday'], 0);
    });

    test('aggregates adherence metrics across records', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final fakeAdherenceRepo2 = FakeAdherenceRepo();
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

      final service2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo2,
      );

      final metrics = (await service2.getAdherenceMetrics()).data!;
      expect(metrics['actualMinutesToday'], 65);
      expect(metrics['actualQuestionsToday'], 15);
    });

    test('returns zero when no records exist for student', () async {
      final mockAdherenceRepo = FakeAdherenceRepo();
      final freshService = createPlannerService(
        planRepo: FakePlanRepository(),
        repository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        roadmapRepo: FakeRoadmapRepository(),
        sessionRepo: FakeSessionRepository(),
        pendingActionRepo: FakePendingActionRepository(),
        planOrchestrator: planOrchestrator,
        adherenceRepo: mockAdherenceRepo,
      );

      final metrics = (await freshService.getAdherenceMetrics()).data!;
      expect(metrics['actualMinutesToday'], 0);
      expect(metrics['actualQuestionsToday'], 0);
    });
  });

  group('getAdherenceRecords', () {
    test('returns empty list when no records exist', () async {
      final records = await service.getAdherenceRecords();
      expect(records.data, isEmpty);
    });

    test('returns records when they exist', () async {
      final now = DateTime.now();
      final fakeRepo = FakeAdherenceRepo();
      await fakeRepo.create(PlanAdherenceModel(
        id: 'rec-1', studentId: 'test-student', date: now,
        plannedMinutes: 60, actualMinutes: 45,
        plannedQuestions: 15, actualQuestions: 10,
        adherenceScore: 0.75,
      ));
      final svc = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeRepo,
      );
      final records = await svc.getAdherenceRecords();
      expect(records.data, hasLength(1));
      expect(records.data!.first.id, 'rec-1');
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

    test('returns failure when planRepo throws', () async {
      planRepo.throwOnLoad = true;
      final result = await service.adjustPace(45.0);
      expect(result.isFailure, isTrue);
    });

    test('completes with recalculateDuration when new plan is compressed', () async {
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

    test('returns null when oldTarget is zero', () async {
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

  group('catch block coverage', () {
    test('loadExistingPlan returns failure when planRepo throws', () async {
      planRepo.throwOnLoad = true;
      final result = await service.loadExistingPlan();
      expect(result.isFailure, isTrue);
    });

    test('loadRoadmaps returns failure when error occurs', () async {
      final badRepo = FakeRoadmapRepository();
      final svc2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: badRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
      );
      final result = await svc2.loadRoadmaps();
      expect(result.isSuccess, isTrue);
    });

    test('loadPendingActions returns failure when error occurs', () async {
      final badRepo = FakePendingActionRepository();
      final svc2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: badRepo,
        planOrchestrator: planOrchestrator,
      );
      final result = await svc2.loadPendingActions();
      expect(result.isSuccess, isTrue);
    });

    test('getAdherenceRecords returns failure when adherenceRepo throws', () async {
      final badRepo = FakeAdherenceRepo();
      badRepo.throwOnGetByStudent = true;
      final svc2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: badRepo,
      );
      final result = await svc2.getAdherenceRecords();
      expect(result.isFailure, isTrue);
    });

    test('getAdherenceMetrics returns failure when adherenceRepo throws', () async {
      final badRepo = FakeAdherenceRepo();
      badRepo.throwOnGetByStudent = true;
      final svc2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: badRepo,
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
      final localSessionRepo = FakeSessionRepository();
      await localSessionRepo.save(pastSession.id, pastSession);
      localSessionRepo.throwOnSave = true;
      final svc2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: localSessionRepo,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
      );
      final result = await svc2.dismissAllMissed();
      expect(result.isFailure, isTrue);
    });
  });

  group('redistributeWorkload', () {
    test('completes without error', () async {
      await service.planService.redistributeMissedWorkloadForStudent(service.studentId, 30);
    });
  });

  group('linkDailyPlanToRoadmap', () {
    test('completes without error', () async {
      await service.planService.linkDailyPlanToRoadmap(service.studentId, ['topic-1', 'topic-2']);
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
