import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import '../../../core/services/personal_learning_plan_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/plan_adapter.dart';
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
  final TutorSessionRepository tutorRepo;
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
    TutorSessionRepository? tutorRepo,
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
        tutorRepo = tutorRepo ?? TutorSessionRepository(),
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

    final result = await svc.generatePlan(studentId);
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
            ? 'Topics: ${milestoneTopics.length} syllabus topics'
            : l10n.milestoneForWeek(i + 1),
        deadline: now.add(Duration(
          days: ((i + 1) * days / numMilestones).round(),
        )),
        order: i + 1,
        topicsCovered: milestoneTopics,
        assessmentCriteria: subjectId != null
            ? ['Mastery >= 80% on all milestone topics']
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
      await tutorRepo.init();
      final session = TutorSession(
        id: const Uuid().v4(),
        studentId: studentId,
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        status: SessionStatus.planned,
        startTime: scheduledTime,
        plannedDurationMinutes: durationMinutes,
      );
      await tutorRepo.saveSession(session);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelLesson(String sessionId) async {
    try {
      await tutorRepo.init();
      final session = await tutorRepo.getSession(sessionId);
      if (session == null) return false;
      final cancelled = session.copyWith(
        status: SessionStatus.cancelled,
      );
      await tutorRepo.saveSession(cancelled);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<TutorSession>> getScheduledLessons() async {
    try {
      await tutorRepo.init();
      final sessions = await tutorRepo.getStudentSessions(studentId);
      return sessions
          .where((s) => s.status == SessionStatus.planned)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (_) {
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
    } catch (_) {
      return false;
    }
  }

  Future<bool> dismissPendingAction(String actionId) async {
    try {
      await pendingActionRepo.init();
      await pendingActionRepo.markRejected(actionId);
      return true;
    } catch (_) {
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
    await tutorRepo.init();
    final sessions = await tutorRepo.getStudentSessions(studentId);
    final proposedEnd = startTime.add(Duration(minutes: durationMinutes));
    for (final session in sessions) {
      if (session.status != SessionStatus.planned) continue;
      if (session.id == excludeSessionId) continue;
      final sessionEnd = session.startTime
          .add(Duration(minutes: session.plannedDurationMinutes));
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
    await planRepo.init();
    final plan = await planRepo.loadPlan(studentId);
    if (plan == null) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final redistributeDays = 3;
    final extraPerDay = (missedMinutes / redistributeDays).ceil();

    final updatedPlans = plan.dailyPlans.map((day) {
      final dDay = DateTime(day.date.year, day.date.month, day.date.day);
      if (dDay.isAfter(todayStart) &&
          dDay.difference(todayStart).inDays <= redistributeDays &&
          !day.isRestDay) {
        return day.copyWith(
          targetMinutes: day.targetMinutes + extraPerDay,
        );
      }
      return day;
    }).toList();

    final updated = plan.copyWith(dailyPlans: updatedPlans);
    await planRepo.savePlan(updated);
  }

  Future<void> linkDailyPlanToRoadmap(List<String> completedTopicIds) async {
    await roadmapRepo.init();
    final roadmaps = await roadmapRepo.getRoadmapsByStudent(studentId);
    for (final roadmap in roadmaps) {
      if (roadmap.status == 'completed') continue;
      bool changed = false;
      final updatedMilestones = roadmap.milestones.map((m) {
        if (m.isCompleted) return m;
        final hasAny = completedTopicIds.any((id) => m.topicsCovered.contains(id));
        if (hasAny) {
          changed = true;
          return m.copyWith(isCompleted: true);
        }
        return m;
      }).toList();
      if (changed) {
        final completedCount = updatedMilestones.where((m) => m.isCompleted).length;
        final newPercentage = (completedCount / updatedMilestones.length * 100);
        await roadmapRepo.saveRoadmap(roadmap.copyWith(
          milestones: updatedMilestones,
          completionPercentage: newPercentage,
          status: newPercentage >= 100 ? 'completed' : roadmap.status,
        ));
      }
    }
  }
}
