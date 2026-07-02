import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'planner_service_test_helpers.dart';

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('planner_service_sched_test_').path;
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

  group('getScheduledLessons edge cases', () {
    test('returns failure list when getAll throws', () async {
      sessionRepo.throwOnGetAll = true;
      final lessons = await service.getScheduledLessons();
      expect(lessons.isFailure, isTrue);
    });

    test('filters out completed sessions', () async {
      final now = DateTime.now();
      final sessionRepo2 = FakeSessionRepository();
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

      final service2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
      );

      final lessons = (await service2.getScheduledLessons()).data!;
      expect(lessons, hasLength(1));
      expect(lessons.first.id, 'planned-1');
    });

    test('filters out sessions with endTime', () async {
      final now = DateTime.now();
      final sessionRepo2 = FakeSessionRepository();
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

      final service2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
      );

      final lessons = (await service2.getScheduledLessons()).data!;
      expect(lessons, hasLength(1));
      expect(lessons.first.id, 'planned-2');
    });
  });

  group('scheduleLesson with lessonAgentService', () {
    late PlannerService svcWithAgent;
    late FakeSessionRepository sessionRepo2;
    late FakeAdherenceRepo fakeAdherenceRepo;

    setUp(() {
      sessionRepo2 = FakeSessionRepository();
      fakeAdherenceRepo = FakeAdherenceRepo();
    });

    test('generates lesson when lessonAgentService is provided and returns lesson', () async {
      final lesson = Lesson(
        id: 'lesson-1',
        subjectId: 'sub_physics',
        title: 'Kinematics Lesson',
        topicId: 'topic-1',
        createdAt: DateTime.now(),
      );
      svcWithAgent = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo,
        lessonAgentService: StubLessonAgentService((s, t, tt, l) async => lesson),
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
      svcWithAgent = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo,
        lessonAgentService: StubLessonAgentService((s, t, tt, l) async => null),
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
      svcWithAgent = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo,
        lessonAgentService: StubLessonAgentService((s, t, tt, l) async => throw Exception('gen failed')),
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

    test('does not call lessonAgentService when topicId is empty', () async {
      bool agentCalled = false;
      final svc = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
        adherenceRepo: fakeAdherenceRepo,
        lessonAgentService: StubLessonAgentService((s, t, tt, l) async {
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

  group('hasSchedulingConflict', () {
    test('returns false with no sessions', () async {
      final conflict = await service.hasSchedulingConflict(
        startTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(conflict.data, isFalse);
    });

    test('returns true when sessions overlap', () async {
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

    test('returns false when excludeSessionId matches overlapping session', () async {
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

    test('returns false with completed sessions', () async {
      final now = DateTime.now();
      final sessionRepo2 = FakeSessionRepository();
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

      final service2 = createPlannerService(
        repository: masteryRepo,
        topicRepository: topicRepo,
        planRepo: planRepo,
        roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo,
        planOrchestrator: planOrchestrator,
      );

      final conflict = await service2.hasSchedulingConflict(
        startTime: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
      );
      expect(conflict.data, isFalse);
    });

    test('returns false when getAll returns failure', () async {
      sessionRepo.returnFailureOnGetAll = true;
      final conflict = await service.hasSchedulingConflict(
        startTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(conflict.data, isFalse);
    });

    test('returns failure when getAll throws', () async {
      sessionRepo.throwOnGetAll = true;
      final conflict = await service.hasSchedulingConflict(
        startTime: DateTime.now(),
        durationMinutes: 30,
      );
      expect(conflict.isFailure, isTrue);
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

    test('returns missed lessons sorted by newest first', () async {
      final now = DateTime.now();
      final sessionRepo2 = FakeSessionRepository();
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

      final svc2 = createPlannerService(
        repository: masteryRepo, topicRepository: topicRepo,
        planRepo: planRepo, roadmapRepo: roadmapRepo,
        sessionRepo: sessionRepo2,
        pendingActionRepo: pendingActionRepo, planOrchestrator: planOrchestrator,
      );
      final missed = (await svc2.getMissedLessons()).data!;
      expect(missed, hasLength(2));
      expect(missed.first.id, 'newer-missed');
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
}
