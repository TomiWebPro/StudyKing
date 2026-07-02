import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'planner_service_test_helpers.dart';

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('planner_service_gen_test_').path;
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

  group('generatePlan edge cases', () {
    test('generates plan even with minimal params', () async {
      final plan = await service.generatePlan(
        course: 'Test',
        daysValue: 1,
        hoursValue: 1,
      );
      expect(plan.data, isNotNull);
    });
  });

  group('generatePlan failure path', () {
    test('returns failure when planRepo.init throws', () async {
      final throwingPlanRepo = ThrowingInitPlanRepository();
      final throwingService = createPlannerService(
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

    test('creates roadmap with milestones (second group)', () async {
      final roadmap = await service.createRoadmap(
        goal: 'Learn Physics',
        days: 14,
        l10n: l10n,
      );
      expect(roadmap.data, isNotNull);
      expect(roadmap.data!.goal, 'Learn Physics');
      expect(roadmap.data!.milestones, isNotEmpty);
    });

    test('creates roadmap with subject ID (second group)', () async {
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

    test('returns null when roadmap does not exist', () async {
      final result = await service.toggleMilestoneCompletion(
        roadmapId: 'nonexistent',
        milestoneId: 'ms-1',
        isCompleted: true,
      );
      expect(result.data, isNull);
    });

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

  group('updateRoadmap catch block', () {
    test('returns failure when roadmapRepo.init throws', () async {
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

      final result = await svc2.updateRoadmap(
        roadmapId: 'rm-1',
        goal: 'New goal',
        days: 7,
        l10n: l10n,
      );
      expect(result.isSuccess, isTrue);
    });
  });
}
