import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/data/repositories/plan_repository.dart';
import '../../../core/data/repositories/mastery_graph_repository.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../../../core/data/repositories/roadmap_repository.dart';
import '../../../core/data/repositories/tutor_session_repository.dart';
import '../../../core/data/repositories/pending_action_repository.dart';
import '../../../core/data/models/roadmap_model.dart';
import '../../../core/data/models/personal_learning_plan_model.dart';
import '../../../core/data/models/tutor_session_model.dart';
import '../../../core/data/models/pending_action_model.dart';
import '../../../core/services/personal_learning_plan_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/plan_adapter.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'syllabus_resolver.dart';

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
  final String? fixedStudentId;

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
        syllabusResolver = syllabusResolver ?? SyllabusResolver();

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
      await pendingActionRepo.markCompleted(actionId);
      return true;
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

  Future<void> recordFocusSession(int actualMinutes) async {
    await planAdapter.recordFromFocusSession(
      studentId: studentId,
      actualMinutes: actualMinutes,
    );
  }

  Future<void> recordPracticeSession({
    required int actualQuestions,
    required int actualMinutes,
  }) async {
    await planAdapter.recordFromPracticeSession(
      studentId: studentId,
      actualQuestions: actualQuestions,
      actualMinutes: actualMinutes,
    );
  }

  Future<void> recordTutorSession(int actualMinutes) async {
    await planAdapter.recordFromTutorSession(
      studentId: studentId,
      actualMinutes: actualMinutes,
    );
  }
}
