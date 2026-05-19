import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/plan_adherence_orchestrator.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/time_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'syllabus_resolver.dart';
import 'action_executor.dart';
class PlannerService {
  final PlanRepository planRepo;
  final MasteryGraphService masteryService;
  final MasteryGraphRepository? repository;
  final TopicRepository topicRepository;
  final RoadmapRepository roadmapRepo;
  final PersonalLearningPlanService planService;
  final SessionRepository sessionRepo;
  final PendingActionRepository pendingActionRepo;
  final PlanAdherenceOrchestrator planOrchestrator;
  final SyllabusResolver syllabusResolver;
  final   PlanAdherenceRepository adherenceRepo;
  final LessonAgentService? lessonAgentService;
  final String? fixedStudentId;
  ActionExecutor? _actionExecutor;

  ActionExecutor get actionExecutor {
    _actionExecutor ??= ActionExecutor(plannerService: this);
    return _actionExecutor!;
  }

  PlannerService({
    PlanRepository? planRepo,
    MasteryGraphService? masteryService,
    this.repository,
    TopicRepository? topicRepository,
    RoadmapRepository? roadmapRepo,
    PersonalLearningPlanService? planService,
    SessionRepository? sessionRepo,
    PendingActionRepository? pendingActionRepo,
    PlanAdherenceOrchestrator? planOrchestrator,
    SyllabusResolver? syllabusResolver,
    PlanAdherenceRepository? adherenceRepo,
    ActionExecutor? actionExecutor,
    this.lessonAgentService,
    this.fixedStudentId,
  })  : planRepo = planRepo ?? PlanRepository(),
        masteryService = masteryService ?? MasteryGraphService(),
        topicRepository = topicRepository ?? TopicRepository(),
        roadmapRepo = roadmapRepo ?? RoadmapRepository(),
        planService = planService ??
            PersonalLearningPlanService(
              masteryService: masteryService ?? MasteryGraphService(),
            ),
        sessionRepo = sessionRepo ?? SessionRepository(),
        pendingActionRepo = pendingActionRepo ?? PendingActionRepository(),
        planOrchestrator = planOrchestrator ?? PlanAdherenceOrchestrator(),
        syllabusResolver = syllabusResolver ?? SyllabusResolver(),
        adherenceRepo = adherenceRepo ?? PlanAdherenceRepository(),
        _actionExecutor = actionExecutor;

  String get studentId =>
      fixedStudentId ?? StudentIdService().getStudentId();

  Future<PersonalLearningPlan?> loadExistingPlan() async {
    await planRepo.init();
    final result = await planRepo.loadPlan(studentId);
    return result.data;
  }

  Future<List<RoadmapModel>> loadRoadmaps() async {
    await roadmapRepo.init();
    final result = await roadmapRepo.getRoadmapsByStudent(studentId);
    return result.data ?? [];
  }

  Future<List<PendingActionModel>> loadPendingActions() async {
    await pendingActionRepo.init();
    final result = await pendingActionRepo.getPending(studentId);
    return result.data ?? [];
  }

  Future<PersonalLearningPlan?> generatePlan({
    required String course,
    required int daysValue,
    required int hoursValue,
  }) async {
    await planRepo.init();
    await roadmapRepo.init();

    planService.config = PlanGenerationConfig(
      planDurationDays: daysValue,
      targetMinutesPerDay: (hoursValue * 60).toDouble(),
      targetQuestionsPerDay: 15,
    );

    final result = await planService.generatePlan(
      studentId,
      courseName: course,
    );
    return result.isSuccess ? result.data : null;
  }

  Future<PersonalLearningPlan?> generatePlanFromSyllabus({
    required List<SyllabusGoal> syllabusGoals,
    required int daysValue,
    required int hoursValue,
  }) async {
    await planRepo.init();
    await roadmapRepo.init();

    planService.config = PlanGenerationConfig(
      planDurationDays: daysValue,
      targetMinutesPerDay: (hoursValue * 60).toDouble(),
      targetQuestionsPerDay: 15,
    );

    final result = await planService.generatePlanFromSyllabus(
      studentId: studentId,
      syllabusGoals: syllabusGoals,
    );
    return result.isSuccess ? result.data : null;
  }

  Future<RoadmapModel?> createRoadmap({
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: days));
    final numMilestones = (days / 7).ceil().clamp(1, 52);
    final milestones = <MilestoneModel>[];

    List<String> syllabusTopicIds = [];
    if (subjectId != null) {
      final result = await syllabusResolver.resolveSyllabus(
        subjectId: subjectId,
        studentId: studentId,
        l10n: l10n,
      );
      if (result.isSuccess) {
        syllabusTopicIds = result.data!.map((n) => n.topic.id).toList();
      }
    }

    for (var i = 0; i < numMilestones; i++) {
      final startIdx = (i * syllabusTopicIds.length / numMilestones).round();
      final endIdx = ((i + 1) * syllabusTopicIds.length / numMilestones).round();
      final milestoneTopics = syllabusTopicIds.sublist(
        startIdx.clamp(0, syllabusTopicIds.length),
        endIdx.clamp(0, syllabusTopicIds.length),
      );

      milestones.add(MilestoneModel(
        id: const Uuid().v4(),
        title: l10n.weekNumber(i + 1),
        description: subjectId != null
            ? l10n.syllabusTopics(milestoneTopics.length)
            : l10n.milestoneForWeek(i + 1),
        deadline: now.add(Duration(
          days: ((i + 1) * days / numMilestones).round(),
        )),
        order: i + 1,
        topicsCovered: milestoneTopics,
        assessmentCriteria: subjectId != null
            ? [l10n.masteryRequirement]
            : [],
      ));
    }

    final roadmap = RoadmapModel(
      id: const Uuid().v4(),
      studentId: studentId,
      goal: goal,
      createdAt: now,
      targetCompletionDate: targetDate,
      milestones: milestones,
      status: 'active',
      subjectId: subjectId,
    );

    await roadmapRepo.init();
    await roadmapRepo.saveRoadmap(roadmap);
    return roadmap;
  }

  Future<RoadmapModel?> updateRoadmap({
    required String roadmapId,
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    await roadmapRepo.init();
    final existingResult = await roadmapRepo.loadRoadmap(roadmapId);
    final existing = existingResult.data;
    if (existing == null) return null;

    final now = DateTime.now();
    final targetDate = now.add(Duration(days: days));
    final updated = existing.copyWith(
      goal: goal,
      targetCompletionDate: targetDate,
      subjectId: subjectId,
    );

    await roadmapRepo.saveRoadmap(updated);
    return updated;
  }



  Future<RoadmapModel?> toggleMilestoneCompletion({
    required String roadmapId,
    required String milestoneId,
    required bool isCompleted,
  }) async {
    await roadmapRepo.init();
    final result = await roadmapRepo.loadRoadmap(roadmapId);
    final roadmap = result.data;
    if (roadmap == null) return null;

    final now = DateTime.now();
    final plannedVsActual = Map<String, double>.from(roadmap.plannedVsActual ?? {});

    final updatedMilestones = roadmap.milestones.map((m) {
      if (m.id == milestoneId) {
        if (isCompleted) {
          plannedVsActual[m.id] = now.millisecondsSinceEpoch.toDouble();
        } else {
          plannedVsActual.remove(m.id);
        }
        return m.copyWith(isCompleted: isCompleted);
      }
      return m;
    }).toList();

    final completedCount = updatedMilestones.where((m) => m.isCompleted).length;
    final newPercentage = (completedCount / updatedMilestones.length * 100);
    final updated = roadmap.copyWith(
      milestones: updatedMilestones,
      completionPercentage: newPercentage,
      status: newPercentage >= 100 ? 'completed' : roadmap.status,
      plannedVsActual: plannedVsActual.isNotEmpty ? plannedVsActual : null,
    );

    await roadmapRepo.saveRoadmap(updated);
    return updated;
  }

  Future<bool> suggestPlanRegeneration({
    required String studentId,
    required double adjustmentFactor,
  }) async {
    final result = await planOrchestrator.suggestRegeneration(
      studentId: studentId,
      adjustmentFactor: adjustmentFactor,
    );
    return result.isSuccess;
  }

  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    try {
      await sessionRepo.init();
      final session = Session(
        id: const Uuid().v4(),
        studentId: studentId,
        subjectId: subjectId,
        topicId: topicId,
        type: SessionType.tutoring,
        startTime: scheduledTime,
        plannedDurationMinutes: durationMinutes,
        completed: false,
        tutorMetadata: TutorMetadata(topicTitle: topicTitle),
      );
      final result = await sessionRepo.save(session.id, session);
      if (result.isSuccess && lessonAgentService != null && topicId.isNotEmpty) {
        try {
          final lesson = await lessonAgentService!.generateLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
          if (lesson != null) {
            final sessionWithLesson = session.copyWith(
              lessonIds: [lesson.id],
              lessonReady: true,
            );
            await sessionRepo.save(session.id, sessionWithLesson);
          } else {
            final failedSession = session.copyWith(lessonReady: false);
            await sessionRepo.save(session.id, failedSession);
          }
        } catch (e) {
          const Logger('PlannerService.scheduleLesson').w('Lesson generation failed', e);
          final failedSession = session.copyWith(lessonReady: false);
          await sessionRepo.save(session.id, failedSession);
        }
      }
      return result.isSuccess;
    } catch (e) {
      const Logger('PlannerService.scheduleLesson').w('Failed to schedule lesson', e);
      return false;
    }
  }

  Future<bool> cancelLesson(String sessionId) async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.get(sessionId);
      if (result.isFailure || result.data == null) return false;
      final cancelled = result.data!.copyWith(completed: true);
      final saveResult = await sessionRepo.save(cancelled.id, cancelled);
      return saveResult.isSuccess;
    } catch (e) {
      const Logger('PlannerService.cancelLesson').w('Failed to cancel lesson', e);
      return false;
    }
  }

  Future<bool> rescheduleLesson({
    required String sessionId,
    required DateTime newStartTime,
    int durationMinutes = 30,
  }) async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.get(sessionId);
      if (result.isFailure || result.data == null) return false;
      final rescheduled = result.data!.copyWith(
        startTime: newStartTime,
        plannedDurationMinutes: durationMinutes,
      );
      final saveResult = await sessionRepo.save(rescheduled.id, rescheduled);
      return saveResult.isSuccess;
    } catch (e) {
      const Logger('PlannerService.rescheduleLesson').w('Failed to reschedule lesson', e);
      return false;
    }
  }

  Future<List<Session>> getScheduledLessons() async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.getAll();
      if (result.isFailure) return [];
      final now = DateTime.now();
      return result.data!
          .where((s) =>
              !s.completed &&
              s.endTime == null &&
              !s.startTime.isBefore(now.subtract(const Duration(hours: 1))))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      const Logger('PlannerService.getScheduledLessons').w('Failed to get scheduled lessons', e);
      return [];
    }
  }

  Future<List<Session>> getMissedLessons() async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.getAll();
      if (result.isFailure) return [];
      final now = DateTime.now();
      return result.data!
          .where((s) =>
              !s.completed &&
              s.endTime == null &&
              s.startTime.isBefore(now.subtract(const Duration(hours: 1))))
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      const Logger('PlannerService.getMissedLessons').w('Failed to get missed lessons', e);
      return [];
    }
  }

  Future<void> dismissAllMissed() async {
    try {
      await sessionRepo.init();
      final missed = await getMissedLessons();
      for (final session in missed) {
        final dismissed = session.copyWith(completed: true);
        await sessionRepo.save(dismissed.id, dismissed);
      }
    } catch (e) {
      const Logger('PlannerService.dismissAllMissed').w('Failed to dismiss missed lessons', e);
    }
  }

  Future<bool> acceptPendingAction(String actionId) async {
    try {
      await pendingActionRepo.init();
      final actionResult = await pendingActionRepo.get(actionId);
      final action = actionResult.data;
      if (action == null) return false;
      final executed = await actionExecutor.execute(action);
      if (executed) {
        await pendingActionRepo.markCompleted(actionId);
      }
      return executed;
    } catch (e) {
      const Logger('PlannerService.acceptPendingAction').w('Failed to accept pending action', e);
      return false;
    }
  }

  Future<bool> dismissPendingAction(String actionId) async {
    try {
      await pendingActionRepo.init();
      await pendingActionRepo.markRejected(actionId);
      return true;
    } catch (e) {
      const Logger('PlannerService.dismissPendingAction').w('Failed to dismiss pending action', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdherenceReport() async {
    final result = await planOrchestrator.getAdherenceReport(studentId);
    return result.isSuccess ? result.data! : {};
  }

  Future<AdherenceDeviation?> checkAdherence() async {
    final result = await planOrchestrator.checkAdherence(studentId);
    return result.isSuccess ? result.data : null;
  }

  Future<PersonalLearningPlan?> regeneratePlanFromAdherence() async {
    final result = await planOrchestrator.suggestRegeneration(studentId: studentId);
    return result.isSuccess ? result.data : null;
  }

  Future<bool> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    await sessionRepo.init();
    final result = await sessionRepo.getAll();
    if (result.isFailure) return false;
    final sessions = result.data!;
    final proposedEnd = startTime.add(Duration(minutes: durationMinutes));
    for (final session in sessions) {
      if (session.completed || session.endTime != null) continue;
      if (session.id == excludeSessionId) continue;
      final plannedDur = session.plannedDurationMinutes ?? durationMinutes;
      final sessionEnd = session.startTime
          .add(Duration(minutes: plannedDur));
      if (startTime.isBefore(sessionEnd) && proposedEnd.isAfter(session.startTime)) {
        return true;
      }
    }
    return false;
  }

  Future<List<PlanAdherenceModel>> getAdherenceRecords() async {
    await adherenceRepo.init();
    return adherenceRepo.getByStudent(studentId);
  }

  Future<Map<String, int>> getAdherenceMetrics() async {
    await adherenceRepo.init();
    final records = await adherenceRepo.getByStudent(studentId);
    final now = DateTime.now();
    final todayStart = now.dateOnly;

    int actualMinutesToday = 0;
    int actualQuestionsToday = 0;
    for (final r in records) {
      final rDay = r.date.dateOnly;
      if (rDay == todayStart) {
        actualMinutesToday += r.actualMinutes;
        actualQuestionsToday += r.actualQuestions;
      }
    }
    return {
      'actualMinutesToday': actualMinutesToday,
      'actualQuestionsToday': actualQuestionsToday,
    };
  }

  Future<void> redistributeWorkload(int missedMinutes, {String strategy = 'days:3'}) async {
    await planService.redistributeMissedWorkloadForStudent(studentId, missedMinutes, strategy: strategy);
  }

  Future<void> extendPlan(int extraDays) async {
    await planService.extendPlan(studentId, extraDays);
  }

  Future<void> linkDailyPlanToRoadmap(List<String> completedTopicIds) async {
    await planService.linkDailyPlanToRoadmap(studentId, completedTopicIds);
  }

  Future<void> adjustPace(double newTargetMinutesPerDay) async {
    await planRepo.init();
    final result = await planRepo.loadPlan(studentId);
    final plan = result.data;
    if (plan == null) return;

    final oldTarget = plan.targetMinutesPerDay;
    if (oldTarget <= 0) return;

    final ratio = newTargetMinutesPerDay / oldTarget;

    final updatedPlans = plan.dailyPlans.map((day) {
      if (day.isRestDay) return day;
      final newMinutes = (day.targetMinutes * ratio).round().clamp(0, (newTargetMinutesPerDay * 2).round());
      final newQuestions = (day.targetQuestions * ratio).round().clamp(0, 50);
      return day.copyWith(
        targetMinutes: newMinutes,
        targetQuestions: newQuestions,
      );
    }).toList();

    final newTargetQuestions = (plan.targetQuestionsPerDay * ratio).round().clamp(5, 50);
    final updatedPlan = plan.copyWith(
      targetMinutesPerDay: newTargetMinutesPerDay,
      targetQuestionsPerDay: newTargetQuestions,
      dailyPlans: updatedPlans,
    );

    await planRepo.savePlan(updatedPlan);
  }
}
