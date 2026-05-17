import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
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
import '../../../core/services/personal_learning_plan_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/plan_adapter.dart';
import '../../../core/utils/logger.dart';
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
  final PlanAdapter planAdapter;
  final SyllabusResolver syllabusResolver;
  final PlanAdherenceRepository adherenceRepo;
  ActionExecutor? _actionExecutor;
  final String? fixedStudentId;

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
    PlanAdapter? planAdapter,
    SyllabusResolver? syllabusResolver,
    PlanAdherenceRepository? adherenceRepo,
    ActionExecutor? actionExecutor,
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
        planAdapter = planAdapter ?? PlanAdapter(),
        syllabusResolver = syllabusResolver ?? SyllabusResolver(),
        adherenceRepo = adherenceRepo ?? PlanAdherenceRepository(),
        _actionExecutor = actionExecutor;

  String get studentId =>
      fixedStudentId ?? StudentIdService().getStudentId();

  Future<PersonalLearningPlan?> loadExistingPlan() async {
    await planRepo.init();
    return planRepo.loadPlan(studentId);
  }

  Future<List<RoadmapModel>> loadRoadmaps() async {
    await roadmapRepo.init();
    return roadmapRepo.getRoadmapsByStudent(studentId);
  }

  Future<List<PendingActionModel>> loadPendingActions() async {
    await pendingActionRepo.init();
    return pendingActionRepo.getPending(studentId);
  }

  Future<PersonalLearningPlan?> generatePlan({
    required String course,
    required int daysValue,
    required int hoursValue,
  }) async {
    await planRepo.init();
    await roadmapRepo.init();

    final svc = PersonalLearningPlanService(
      masteryService: masteryService,
      repository: repository,
      topicRepository: topicRepository,
      planRepository: planRepo,
      syllabusResolver: syllabusResolver,
      config: PlanGenerationConfig(
        planDurationDays: daysValue,
        targetMinutesPerDay: (hoursValue * 60).toDouble(),
        targetQuestionsPerDay: 15,
      ),
    );

    final result = await svc.generatePlan(
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

    final svc = PersonalLearningPlanService(
      masteryService: masteryService,
      repository: repository,
      topicRepository: topicRepository,
      planRepository: planRepo,
      syllabusResolver: syllabusResolver,
      config: PlanGenerationConfig(
        planDurationDays: daysValue,
        targetMinutesPerDay: (hoursValue * 60).toDouble(),
        targetQuestionsPerDay: 15,
      ),
    );

    final result = await svc.generatePlanFromSyllabus(
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

  Future<RoadmapModel?> createRoadmapFromGoal(
    String goal,
    int days,
    AppLocalizations l10n, {
    String? subjectId,
  }) async {
    return createRoadmap(goal: goal, days: days, l10n: l10n, subjectId: subjectId);
  }

  Future<RoadmapModel?> toggleMilestoneCompletion({
    required String roadmapId,
    required String milestoneId,
    required bool isCompleted,
  }) async {
    await roadmapRepo.init();
    final roadmap = await roadmapRepo.loadRoadmap(roadmapId);
    if (roadmap == null) return null;

    final updatedMilestones = roadmap.milestones.map((m) {
      if (m.id == milestoneId) {
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
    );

    await roadmapRepo.saveRoadmap(updated);
    return updated;
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
      final result = await sessionRepo.save(session);
      return result.isSuccess;
    } catch (e) {
      const Logger('PlannerService.scheduleLesson').e('Failed to schedule lesson', e);
      return false;
    }
  }

  Future<bool> cancelLesson(String sessionId) async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.get(sessionId);
      if (result.isFailure || result.data == null) return false;
      final cancelled = result.data!.copyWith(completed: true);
      final saveResult = await sessionRepo.save(cancelled);
      return saveResult.isSuccess;
    } catch (e) {
      const Logger('PlannerService.cancelLesson').e('Failed to cancel lesson', e);
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
      final saveResult = await sessionRepo.save(rescheduled);
      return saveResult.isSuccess;
    } catch (e) {
      const Logger('PlannerService.rescheduleLesson').e('Failed to reschedule lesson', e);
      return false;
    }
  }

  Future<List<Session>> getScheduledLessons() async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.getAll();
      if (result.isFailure) return [];
      return result.data!
          .where((s) => !s.completed && s.endTime == null)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      const Logger('PlannerService.getScheduledLessons').e('Failed to get scheduled lessons', e);
      return [];
    }
  }

  Future<bool> acceptPendingAction(String actionId) async {
    try {
      await pendingActionRepo.init();
      final action = await pendingActionRepo.get(actionId);
      if (action == null) return false;
      final executed = await actionExecutor.execute(action);
      if (executed) {
        await pendingActionRepo.markCompleted(actionId);
      }
      return executed;
    } catch (e) {
      const Logger('PlannerService.acceptPendingAction').e('Failed to accept pending action', e);
      return false;
    }
  }

  Future<bool> dismissPendingAction(String actionId) async {
    try {
      await pendingActionRepo.init();
      await pendingActionRepo.markRejected(actionId);
      return true;
    } catch (e) {
      const Logger('PlannerService.dismissPendingAction').e('Failed to dismiss pending action', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdherenceReport() async {
    final result = await planAdapter.getAdherenceReport(studentId);
    return result.isSuccess ? result.data! : {};
  }

  Future<AdherenceDeviation?> checkAdherence() async {
    final result = await planAdapter.checkAdherence(studentId);
    return result.isSuccess ? result.data : null;
  }

  Future<PersonalLearningPlan?> regeneratePlanFromAdherence() async {
    final result = await planAdapter.suggestRegeneration(studentId: studentId);
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

  Future<Map<String, int>> getAdherenceMetrics() async {
    await adherenceRepo.init();
    final records = await adherenceRepo.getByStudent(studentId);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    int actualMinutesToday = 0;
    int actualQuestionsToday = 0;
    for (final r in records) {
      final rDay = DateTime(r.date.year, r.date.month, r.date.day);
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

  Future<void> redistributeWorkload(int missedMinutes) async {
    await planService.redistributeMissedWorkloadForStudent(studentId, missedMinutes);
  }

  Future<void> linkDailyPlanToRoadmap(List<String> completedTopicIds) async {
    await planService.linkDailyPlanToRoadmap(studentId, completedTopicIds);
  }
}
