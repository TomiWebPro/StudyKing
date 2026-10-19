import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_context_repository.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/plan_adherence_orchestrator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/study_utils.dart';
import '../../../core/utils/time_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'syllabus_resolver.dart';
import 'action_executor.dart';
import 'planner_advisor_strategy.dart';
class PlannerService {
  static final Logger _logger = const Logger('PlannerService');

  /// Computes the plan duration (longest goal's `targetDays`) and total
  /// daily hours (sum of per-subject `targetHoursPerDay`) from a list of
  /// `SyllabusGoal`s.
  ///
  /// Goals are studied concurrently, so the plan must last as long as the
  /// longest goal — averaging silently truncates long subjects. Daily hours
  /// are summed without clamping; the caller shows a warning when the total
  /// exceeds a sensible ceiling (see `planHoursExceedsDailyCap`).
  ///
  /// Shared by `PlannerService.addSubjectToPlan` (incremental path) and
  /// `StudyPlanTab._generatePlan` (multi-create path) so both produce
  /// identical durations for identical inputs.
  static ({int days, int hours}) computeSyllabusDimensions(
    List<SyllabusGoal> goals,
  ) {
    if (goals.isEmpty) return (days: 0, hours: 0);
    var maxDays = 0;
    var sumHours = 0;
    for (final g in goals) {
      if (g.targetDays > maxDays) maxDays = g.targetDays;
      sumHours += g.targetHoursPerDay;
    }
    return (days: maxDays, hours: sumHours);
  }

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
  final PlanAdherenceRepository adherenceRepo;
  final PlanContextRepository planContextRepo;
  final LessonAgentService? lessonAgentService;
  final PlannerAdvisorStrategy? advisor;
  final String? fixedStudentId;
  final Clock _clock;
  final String _localeName;
  final NotificationService? _notificationService;
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
    PlanContextRepository? planContextRepo,
    ActionExecutor? actionExecutor,
    this.lessonAgentService,
    this.advisor,
    this.fixedStudentId,
    String localeName = 'en',
    AppLocalizations? l10n,
    Clock? clock,
    NotificationService? notificationService,
  })  : _localeName = localeName,
        _notificationService = notificationService,
        planRepo = planRepo ?? PlanRepository(),
        masteryService = masteryService ?? MasteryGraphService(),
        topicRepository = topicRepository ?? TopicRepository(),
        roadmapRepo = roadmapRepo ?? RoadmapRepository(),
        planService = planService ??
            PersonalLearningPlanService(
              masteryService: masteryService ?? MasteryGraphService(),
              advisor: advisor,
              l10n: l10n,
              clock: clock,
        ),
        sessionRepo = sessionRepo ?? SessionRepository(),
        pendingActionRepo = pendingActionRepo ?? PendingActionRepository(),
        planOrchestrator = planOrchestrator ?? PlanAdherenceOrchestrator(),
        syllabusResolver = syllabusResolver ?? SyllabusResolver(),
        adherenceRepo = adherenceRepo ?? PlanAdherenceRepository(),
        planContextRepo = planContextRepo ?? PlanContextRepository(),
        _actionExecutor = actionExecutor,
        _clock = clock ?? SystemClock();

  String get studentId =>
      fixedStudentId ?? (StudentIdService().getStudentId().data ?? '');

  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    try {
      await planRepo.init();
      await planContextRepo.init();
      final activeIdResult = await planContextRepo.getActivePlanId(studentId);
      final activeId = activeIdResult.isSuccess ? activeIdResult.data : null;
      if (activeId != null && activeId.isNotEmpty) {
        final byIdResult = await planRepo.loadPlanById(activeId);
        if (byIdResult.isSuccess && byIdResult.data != null) {
          return Result.success(byIdResult.data);
        }
      }
      final result = await planRepo.loadPlan(studentId);
      return Result.success(result.data);
    } catch (e) {
      _logger.w('loadExistingPlan failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<PersonalLearningPlan?>> loadPlanById(String planId) async {
    try {
      await planRepo.init();
      final result = await planRepo.loadPlanById(planId);
      return Result.success(result.data);
    } catch (e) {
      _logger.w('loadPlanById failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<PersonalLearningPlan>>> getPlans() async {
    try {
      await planRepo.init();
      final result = await planRepo.getAllPlansForStudent(studentId);
      return Result.success(result.data ?? []);
    } catch (e) {
      _logger.w('getPlans failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<String?>> getActivePlanId() async {
    try {
      await planContextRepo.init();
      final result = await planContextRepo.getActivePlanId(studentId);
      return Result.success(result.isSuccess ? result.data : null);
    } catch (e) {
      _logger.w('getActivePlanId failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> setActivePlanId(String planId) async {
    try {
      await planRepo.init();
      await planContextRepo.init();
      final plansResult = await planRepo.getAllPlansForStudent(studentId);
      final plans = plansResult.data ?? [];
      if (!plans.any((p) => p.planId == planId)) {
        return Result.failure('Plan $planId does not belong to student');
      }
      final result = await planContextRepo.setActivePlanId(studentId, planId);
      if (result.isFailure) return Result.failure(result.error);
      return Result.success(null);
    } catch (e) {
      _logger.w('setActivePlanId failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> deletePlan(String planId) async {
    try {
      await planRepo.init();
      await planContextRepo.init();
      final plansResult = await planRepo.getAllPlansForStudent(studentId);
      final plans = plansResult.data ?? [];
      final target = plans.where((p) => p.planId == planId).firstOrNull;
      if (target == null) {
        return Result.failure('Plan $planId does not belong to student');
      }
      await planRepo.deletePlanById(planId);
      final activeIdResult = await planContextRepo.getActivePlanId(studentId);
      final activeId = activeIdResult.isSuccess ? activeIdResult.data : null;
      if (activeId == planId) {
        await planContextRepo.clearActivePlanId(studentId);
      }
      return Result.success(null);
    } catch (e) {
      _logger.w('deletePlan failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<PersonalLearningPlan?>> _persistGeneratedPlan(
    PersonalLearningPlan plan, {
    required String? name,
  }) async {
    try {
      await planRepo.init();
      await planContextRepo.init();
      final planId = const Uuid().v4();
      final namedPlan = plan.copyWith(
        planId: planId,
        name: name?.isNotEmpty == true ? name! : plan.name,
      );
      await planRepo.savePlan(namedPlan);
      final activeResult = await planContextRepo.setActivePlanId(studentId, planId);
      if (activeResult.isFailure) {
        _logger.w('Failed to persist active plan id: ${activeResult.error}');
      }
      return Result.success(namedPlan);
    } catch (e) {
      _logger.w('Failed to persist generated plan', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<RoadmapModel>>> loadRoadmaps() async {
    try {
      await roadmapRepo.init();
      final result = await roadmapRepo.getRoadmapsByStudent(studentId);
      return Result.success(result.data ?? []);
    } catch (e) {
      _logger.w('loadRoadmaps failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<PendingActionModel>>> loadPendingActions() async {
    try {
      await pendingActionRepo.init();
      final result = await pendingActionRepo.getPending(studentId);
      return Result.success(result.data ?? []);
    } catch (e) {
      _logger.w('loadPendingActions failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<PersonalLearningPlan?>> generatePlan({
    required String course,
    required int daysValue,
    required int hoursValue,
    String? name,
  }) async {
    try {
      await planRepo.init();
      await roadmapRepo.init();

      planService.config = PlanGenerationConfig(
        planDurationDays: daysValue,
        targetMinutesPerDay: (hoursValue * 60).toDouble(),
        targetQuestionsPerDay: defaultQuestionsPerDay,
      );

      final result = await planService.generatePlan(
        studentId,
        courseName: course,
      );
      if (!result.isSuccess || result.data == null) {
        return Result.success(null);
      }
      final persisted = await _persistGeneratedPlan(result.data!, name: name ?? course);
      return persisted;
    } catch (e) {
      _logger.w('generatePlan failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<PersonalLearningPlan?>> generatePlanFromSyllabus({
    required List<SyllabusGoal> syllabusGoals,
    required int daysValue,
    required int hoursValue,
    String? name,
    String? existingPlanId,
  }) async {
    try {
      await planRepo.init();
      await roadmapRepo.init();

      planService.config = PlanGenerationConfig(
        planDurationDays: daysValue,
        targetMinutesPerDay: (hoursValue * 60).toDouble(),
        targetQuestionsPerDay: defaultQuestionsPerDay,
      );

      final result = await planService.generatePlanFromSyllabus(
        studentId: studentId,
        syllabusGoals: syllabusGoals,
      );
      if (!result.isSuccess || result.data == null) {
        return Result.success(null);
      }
      if (existingPlanId != null && existingPlanId.isNotEmpty) {
        await planRepo.init();
        final existingResult = await planRepo.loadPlanById(existingPlanId);
        final existing = existingResult.data;
        final preserved = result.data!.copyWith(
          planId: existingPlanId,
          name: existing?.name.isNotEmpty == true ? existing!.name : (name ?? ''),
        );
        await planRepo.savePlan(preserved);
        await planContextRepo.init();
        final activeResult = await planContextRepo.setActivePlanId(studentId, existingPlanId);
        if (activeResult.isFailure) {
          _logger.w('Failed to persist active plan id: ${activeResult.error}');
        }
        return Result.success(preserved);
      }
      final persisted = await _persistGeneratedPlan(result.data!, name: name);
      return persisted;
    } catch (e) {
      _logger.w('generatePlanFromSyllabus failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<PersonalLearningPlan?>> addSubjectToPlan({
    required SyllabusGoal newGoal,
    required PersonalLearningPlan existingPlan,
  }) async {
    try {
      await planRepo.init();
      await roadmapRepo.init();
      
      final existingGoals = existingPlan.syllabusGoals;
      final combinedGoals = [...existingGoals, newGoal];
      final dims = PlannerService.computeSyllabusDimensions(combinedGoals);

      planService.config = PlanGenerationConfig(
        planDurationDays: dims.days.clamp(1, 365),
        targetMinutesPerDay: (dims.hours * 60).toDouble(),
        targetQuestionsPerDay: defaultQuestionsPerDay,
      );

      final result = await planService.generatePlanFromSyllabus(
        studentId: studentId,
        syllabusGoals: combinedGoals,
      );

      if (result.isSuccess && result.data != null) {
        final newPlan = result.data!;
        final oldDateRanges = existingPlan.dailyPlans
            .where((d) => !d.isRestDay)
            .map((d) => d.date.toIso8601String())
            .toList();
        final updatedMetadata = Map<String, dynamic>.from(newPlan.metadata ?? {});
        updatedMetadata['previous_plan_dates'] = oldDateRanges;
        // Preserve pacing state that regeneration would otherwise discard:
        // the last redistribution marker (so catch-up work already moved onto
        // future days is not silently re-triggered) plus the student's manual
        // rest-day/completed-day flags, matched by calendar date so the
        // monthly subject-add does not reset scheduling decisions the student
        // already made. (vision §83-84: adapt plans as progress changes;
        // track actual adherence vs intended schedule.)
        final lastRedistribution =
            existingPlan.metadata?['lastRedistributionDate'];
        if (lastRedistribution != null) {
          updatedMetadata['lastRedistributionDate'] = lastRedistribution;
        }
        final mergedDailyPlans = _mergeDailyPlanState(
          existingPlan.dailyPlans, newPlan.dailyPlans);
        final preservedNewPlan = newPlan.copyWith(
          planId: existingPlan.planId,
          name: existingPlan.name,
          dailyPlans: mergedDailyPlans,
          metadata: updatedMetadata,
        );
        await planRepo.savePlan(preservedNewPlan);
        await planContextRepo.init();
        final activeResult = await planContextRepo.setActivePlanId(studentId, existingPlan.planId);
        if (activeResult.isFailure) {
          _logger.w('Failed to persist active plan id: ${activeResult.error}');
        }
        return Result.success(preservedNewPlan);
      }

      return Result.success(result.data);
    } catch (e) {
      _logger.w('addSubjectToPlan failed', e);
      return Result.failure(e.toString());
    }
  }

  /// Carries the student's scheduling decisions (manual rest days and
  /// completed-day flags) from [previous] into [regenerated] by matching
  /// calendar dates, so a monthly subject-add does not silently reset the
  /// rest days and completion state already chosen by the student.
  ///
  /// Only matching calendar dates are touched; the regenerated plan's
  /// freshly-derived topics/exercises for the added subject are preserved.
  /// Days the student left untouched (no rest-day, not completed) are passed
  /// through unchanged.
  List<DailyPlan> _mergeDailyPlanState(
    List<DailyPlan> previous,
    List<DailyPlan> regenerated,
  ) {
    if (previous.isEmpty) return regenerated;

    final stateByDate = <DateTime, ({bool isRestDay, bool isCompleted})>{};
    for (final d in previous) {
      stateByDate[d.date.dateOnly] = (
        isRestDay: d.isRestDay,
        isCompleted: d.isCompleted,
      );
    }
    if (stateByDate.isEmpty) return regenerated;

    return regenerated.map((d) {
      final prev = stateByDate[d.date.dateOnly];
      if (prev == null) return d;
      if (!prev.isRestDay && !prev.isCompleted) return d;
      return d.copyWith(
        isRestDay: prev.isRestDay,
        isCompleted: prev.isCompleted,
      );
    }).toList();
  }

  Future<Result<RoadmapModel?>> createRoadmap({
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    try {
      final now = _clock.now();
      final targetDate = addCalendarDays(now, days);
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
          deadline: addCalendarDays(
            now,
            ((i + 1) * days / numMilestones).round(),
          ),
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
      return Result.success(roadmap);
    } catch (e) {
      _logger.w('createRoadmap failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<RoadmapModel?>> updateRoadmap({
    required String roadmapId,
    required String goal,
    required int days,
    required AppLocalizations l10n,
    String? subjectId,
  }) async {
    try {
      await roadmapRepo.init();
      final existingResult = await roadmapRepo.loadRoadmap(roadmapId);
      final existing = existingResult.data;
      if (existing == null) return Result.success(null);

      final now = _clock.now();
      final targetDate = addCalendarDays(now, days);
      final updated = existing.copyWith(
        goal: goal,
        targetCompletionDate: targetDate,
        subjectId: subjectId,
      );

      await roadmapRepo.saveRoadmap(updated);
      return Result.success(updated);
    } catch (e) {
      _logger.w('updateRoadmap failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<RoadmapModel?>> toggleMilestoneCompletion({
    required String roadmapId,
    required String milestoneId,
    required bool isCompleted,
  }) async {
    try {
      await roadmapRepo.init();
      final result = await roadmapRepo.loadRoadmap(roadmapId);
      final roadmap = result.data;
      if (roadmap == null) return Result.success(null);

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
      return Result.success(updated);
    } catch (e) {
      _logger.w('toggleMilestoneCompletion failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = defaultSessionDurationMinutes,
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
      if (!result.isSuccess) {
        return Result.success(false);
      }
      var lessonStateSaved = true;
      Session finalSession = session;
      if (lessonAgentService != null && topicId.isNotEmpty) {
        try {
          final lesson = await lessonAgentService!.generateLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
            localeName: _localeName,
          );
          finalSession = lesson != null
              ? session.copyWith(
                  lessonIds: [lesson.id],
                  lessonReady: true,
                )
              : session.copyWith(lessonReady: false);
          lessonStateSaved = await _persistLessonState(
            session.id,
            finalSession,
          );
        } catch (e) {
          _logger.w('Lesson generation failed', e);
          finalSession = session.copyWith(lessonReady: false);
          lessonStateSaved = await _persistLessonState(
            session.id,
            finalSession,
          );
        }
      }

      // Arm an OS-level one-shot reminder so the lesson notification
      // fires even while the app is backgrounded or terminated.
      await _armLessonReminder(finalSession);

      return Result.success(lessonStateSaved);
    } catch (e) {
      _logger.w('Failed to schedule lesson', e);
      return Result.failure(e.toString());
    }
  }

  Future<bool> _persistLessonState(String sessionId, Session session) async {
    final saveResult = await sessionRepo.save(sessionId, session);
    if (saveResult.isFailure) {
      _logger.w(
        'Failed to save lesson state for session $sessionId',
        saveResult.error,
      );
    }
    return saveResult.isSuccess;
  }

  /// Arms an OS-level upcoming-lesson reminder for [session] via
  /// [NotificationService.scheduleLessonReminder]. Sets the persisted
  /// `reminderScheduled` flag on successful scheduling so the foreground
  /// `EngagementScheduler` can skip the lesson and avoid double-firing.
  /// Past lessons are skipped — they are handled by the missed-lessons
  /// flow, not upcoming reminders.
  Future<void> _armLessonReminder(Session session) async {
    final ns = _notificationService;
    if (ns == null) return;
    if (!session.startTime.isAfter(DateTime.now())) return;
    final result = await ns.scheduleLessonReminder(
      sessionId: session.id,
      lessonTitle:
          session.tutorMetadata?.topicTitle ?? session.topicId ?? 'Lesson',
      startTime: session.startTime,
    );
    if (result.isSuccess) {
      final updated = session.copyWith(reminderScheduled: true);
      final saveResult = await sessionRepo.save(updated.id, updated);
      if (saveResult.isFailure) {
        _logger.w(
          'Failed to persist reminderScheduled flag for session ${session.id}',
          saveResult.error,
        );
      }
    } else {
      _logger.w(
        'Failed to arm OS lesson reminder for session ${session.id}',
        result.error,
      );
    }
  }

  Future<Result<bool>> cancelLesson(String sessionId) async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.get(sessionId);
      if (result.isFailure || result.data == null) return Result.success(false);
      final cancelled = result.data!.copyWith(completed: true);
      final ns = _notificationService;
      if (ns != null) {
        final cancelResult = await ns.cancelLessonReminder(cancelled.id);
        if (cancelResult.isFailure) {
          _logger.w('Failed to cancel OS lesson reminder for session ${cancelled.id}', cancelResult.error);
        }
      }
      final saveResult = await sessionRepo.save(cancelled.id, cancelled);
      return Result.success(saveResult.isSuccess);
    } catch (e) {
      _logger.w('Failed to cancel lesson', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> rescheduleLesson({
    required String sessionId,
    required DateTime newStartTime,
    int durationMinutes = defaultSessionDurationMinutes,
  }) async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.get(sessionId);
      if (result.isFailure || result.data == null) return Result.success(false);
      final rescheduled = result.data!.copyWith(
        startTime: newStartTime,
        plannedDurationMinutes: durationMinutes,
        reminderScheduled: false,
      );
      final saveResult = await sessionRepo.save(rescheduled.id, rescheduled);
      if (!saveResult.isSuccess) {
        return Result.success(false);
      }
      // Cancel the old OS alarm (same notification id since the
      // session id is unchanged) and re-arm for the new start time.
      final ns = _notificationService;
      if (ns != null) {
        await ns.cancelLessonReminder(rescheduled.id);
      }
      await _armLessonReminder(rescheduled);
      return Result.success(saveResult.isSuccess);
    } catch (e) {
      _logger.w('Failed to reschedule lesson', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getScheduledLessons() async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.getAll();
      if (result.isFailure) return Result.success([]);
      final now = DateTime.now();
      final lessons = result.data!
          .where((s) =>
              !s.completed &&
              s.endTime == null &&
              !s.startTime.isBefore(now.subtract(Timeouts.recentSessionWindow)))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      return Result.success(lessons);
    } catch (e) {
      _logger.w('Failed to get scheduled lessons', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getMissedLessons() async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.getAll();
      if (result.isFailure) return Result.success([]);
      final now = DateTime.now();
      final lessons = result.data!
          .where((s) =>
              !s.completed &&
              s.endTime == null &&
              s.startTime.isBefore(now.subtract(Timeouts.recentSessionWindow)))
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      return Result.success(lessons);
    } catch (e) {
      _logger.w('Failed to get missed lessons', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> dismissAllMissed() async {
    try {
      await sessionRepo.init();
      final missedResult = await getMissedLessons();
      if (missedResult.isFailure) return Result.failure(missedResult.error);
      final missed = missedResult.data!;
      for (final session in missed) {
        final dismissed = session.copyWith(completed: true);
        final saveResult = await sessionRepo.save(dismissed.id, dismissed);
        if (saveResult.isFailure) {
          _logger.w(
            'Failed to dismiss missed lesson ${dismissed.id}',
            saveResult.error,
          );
          return Result.failure(saveResult.error);
        }
      }
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to dismiss missed lessons', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> acceptPendingAction(String actionId) async {
    try {
      await pendingActionRepo.init();
      final actionResult = await pendingActionRepo.get(actionId);
      final action = actionResult.data;
      if (action == null) return Result.success(false);
      final executedResult = await actionExecutor.execute(action);
      if (executedResult.isFailure) {
        _logger.w('Failed to execute pending action: ${executedResult.error}');
        return Result.failure(executedResult.error);
      }
      final executed = executedResult.data ?? false;
      if (executed) {
        final completedResult = await pendingActionRepo.markCompleted(actionId);
        if (completedResult.isFailure) {
          _logger.w(
            'Failed to mark pending action completed: $actionId',
            completedResult.error,
          );
          return Result.failure(completedResult.error);
        }
      }
      return Result.success(executed);
    } catch (e) {
      _logger.w('Failed to accept pending action', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> dismissPendingAction(String actionId) async {
    try {
      await pendingActionRepo.init();
      final rejectedResult = await pendingActionRepo.markRejected(actionId);
      if (rejectedResult.isFailure) {
        _logger.w(
          'Failed to mark pending action rejected: $actionId',
          rejectedResult.error,
        );
        return Result.failure(rejectedResult.error);
      }
      return Result.success(true);
    } catch (e) {
      _logger.w('Failed to dismiss pending action', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    try {
      await sessionRepo.init();
      final result = await sessionRepo.getAll();
      if (result.isFailure) return Result.success(false);
      final sessions = result.data!;
      final proposedEnd = startTime.add(Duration(minutes: durationMinutes));
      for (final session in sessions) {
        if (session.completed || session.endTime != null) continue;
        if (session.id == excludeSessionId) continue;
        final plannedDur = session.plannedDurationMinutes ?? durationMinutes;
        final sessionEnd = session.startTime
            .add(Duration(minutes: plannedDur));
        if (startTime.isBefore(sessionEnd) && proposedEnd.isAfter(session.startTime)) {
          return Result.success(true);
        }
      }
      return Result.success(false);
    } catch (e) {
      _logger.w('hasSchedulingConflict failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    try {
      await adherenceRepo.init();
      final result = await adherenceRepo.getByStudent(studentId);
      return result;
    } catch (e) {
      _logger.w('getAdherenceRecords failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, int>>> getAdherenceMetrics() async {
    try {
      await adherenceRepo.init();
      final recordsResult = await adherenceRepo.getByStudent(studentId);
      final records = recordsResult.data ?? [];
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
      return Result.success({
        'actualMinutesToday': actualMinutesToday,
        'actualQuestionsToday': actualQuestionsToday,
      });
    } catch (e) {
      _logger.w('getAdherenceMetrics failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> adjustPace(double newTargetMinutesPerDay, {bool recalculateDuration = false}) async {
    try {
      await planRepo.init();
      final result = await planRepo.loadPlan(studentId);
      final plan = result.data;
      if (plan == null) return Result.success(null);

      final oldTarget = plan.targetMinutesPerDay;
      if (oldTarget <= 0) return Result.success(null);

      final ratio = newTargetMinutesPerDay / oldTarget;

      if (recalculateDuration && plan.summary.totalMinutes > 0) {
        final newTotalDays = (plan.summary.totalMinutes / newTargetMinutesPerDay).ceil();
        final oldNonRestDays = plan.dailyPlans.where((d) => !d.isRestDay).length;
        if (newTotalDays < oldNonRestDays && newTotalDays > 0) {
          final compressedPlans = plan.dailyPlans.where((d) => !d.isRestDay).toList();
          final step = compressedPlans.length / newTotalDays;
          final newPlans = <DailyPlan>[];
          final now = plan.dailyPlans.first.date;
          for (var i = 0; i < newTotalDays; i++) {
            final startIdx = (i * step).round();
            final endIdx = ((i + 1) * step).round().clamp(0, compressedPlans.length);
            final topics = compressedPlans.sublist(startIdx, endIdx)
                .expand((d) => d.priorityTopics)
                .toList();
            newPlans.add(DailyPlan(
              date: addCalendarDays(now, i),
              dayNumber: i + 1,
              priorityTopics: topics,
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: newTargetMinutesPerDay.toInt() ~/ 4,
              targetMinutes: newTargetMinutesPerDay.round(),
              focus: 'Adjusted pace',
            ));
          }
          final updatedPlan = plan.copyWith(
            targetMinutesPerDay: newTargetMinutesPerDay,
            targetQuestionsPerDay: (plan.targetQuestionsPerDay * ratio).round().clamp(5, 50),
            dailyPlans: newPlans,
            planDurationDays: newTotalDays,
          );
          await planRepo.savePlan(updatedPlan);
          return Result.success(null);
        }
      }

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
      return Result.success(null);
    } catch (e) {
      _logger.w('adjustPace failed', e);
      return Result.failure(e.toString());
    }
  }

  /// Updates a single [SyllabusGoal.targetHoursPerDay] for [subjectId] and
  /// recomputes the plan's global daily target as the sum of all per-subject
  /// goals (the same convention used at plan creation), rescaling daily plans
  /// through the shared pace-adjustment path.
  Future<Result<void>> updateSyllabusGoalHours(
    String subjectId,
    double targetHoursPerDay,
  ) async {
    try {
      await planRepo.init();
      final result = await planRepo.loadPlan(studentId);
      final plan = result.data;
      if (plan == null) {
        return Result.failure('No plan found for student $studentId');
      }

      final goals = plan.syllabusGoals;
      if (goals.isEmpty) {
        return Result.failure('Plan ${plan.planId} has no syllabus goals');
      }

      var matched = false;
      final updatedGoals = goals.map((goal) {
        if (goal.subjectId != subjectId) return goal;
        matched = true;
        return SyllabusGoal(
          subjectId: goal.subjectId,
          subjectTitle: goal.subjectTitle,
          syllabusCode: goal.syllabusCode,
          targetDays: goal.targetDays,
          targetHoursPerDay: targetHoursPerDay.round(),
        );
      }).toList();

      if (!matched) {
        return Result.failure('No syllabus goal for subject $subjectId');
      }

      final totalMinutes = updatedGoals.fold<double>(
        0,
        (sum, goal) => sum + goal.targetHoursPerDay * 60,
      );

      final metadata = Map<String, dynamic>.from(plan.metadata ?? {});
      metadata['syllabus_goals'] = updatedGoals.map((g) => g.toJson()).toList();
      await planRepo.savePlan(plan.copyWith(metadata: metadata));

      // Recompute the global pace as the sum of all per-subject goals
      // and rescale daily plans proportionally.
      return await adjustPace(totalMinutes);
    } catch (e) {
      _logger.w('updateSyllabusGoalHours failed', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> extendPlan(int extraDays) async {
    return planService.extendPlan(studentId, extraDays);
  }

  Future<Result<void>> redistributeMissedWorkload(
    int missedMinutes, {
    String strategy = 'days:3',
  }) {
    return planService.redistributeMissedWorkloadForStudent(
      studentId,
      missedMinutes,
      strategy: strategy,
    );
  }

  /// Marks the daily plan for [date] (matched by calendar day) as a rest day.
  ///
  /// Rest days carry no study targets and are excluded from adherence and
  /// workload aggregation (see `adjustPace` and `MentorContextBuilder`). This
  /// backs the `schedule_rest_day` agent tool so the mentor can protect the
  /// student from overwork (Vision Next-Term §3.1,
  /// `scenario_overworked_student`). It is an explicit agent action — the
  /// mentor only calls it after the student confirms — so it never silently
  /// alters the plan.
  Future<Result<bool>> markRestDay(DateTime date, {required AppLocalizations l10n}) async {
    try {
      await planRepo.init();
      await planContextRepo.init();
      final result = await planRepo.loadPlan(studentId);
      final plan = result.data;
      if (plan == null) {
        return Result.failure('No plan found for student $studentId');
      }

      final target = date.dateOnly;
      final matches = plan.dailyPlans.where((d) => d.date.dateOnly == target);
      if (matches.isEmpty) {
        // No daily plan exists for that calendar day (plan ended or date out
        // of range). Report success:false so the agent surfaces a clear
        // message instead of silently doing nothing.
        return Result.success(false);
      }

      final restFocus = l10n.planFocusRestAndReview;
      final updatedPlans = plan.dailyPlans.map((d) {
        if (d.date.dateOnly == target) {
          return d.copyWith(
            isRestDay: true,
            targetMinutes: 0,
            targetQuestions: 0,
            focus: restFocus,
          );
        }
        return d;
      }).toList();

      await planRepo.savePlan(plan.copyWith(dailyPlans: updatedPlans));
      return Result.success(true);
    } catch (e) {
      _logger.w('markRestDay failed', e);
      return Result.failure(e.toString());
    }
  }
}
