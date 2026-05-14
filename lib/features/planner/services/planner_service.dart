import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/data/repositories/plan_repository.dart';
import '../../../core/data/repositories/mastery_graph_repository.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../../../core/data/repositories/roadmap_repository.dart';
import '../../../core/data/models/roadmap_model.dart';
import '../../../core/services/personal_learning_plan_service.dart';
import '../../../core/services/student_id_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/data/models/personal_learning_plan_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class PlannerService {
  final PlanRepository planRepo;
  final MasteryGraphService masteryService;
  final MasteryGraphRepository? repository;
  final TopicRepository topicRepository;
  final RoadmapRepository roadmapRepo;
  final PersonalLearningPlanService planService;
  final String? fixedStudentId;

  PlannerService({
    PlanRepository? planRepo,
    MasteryGraphService? masteryService,
    this.repository,
    TopicRepository? topicRepository,
    RoadmapRepository? roadmapRepo,
    PersonalLearningPlanService? planService,
    this.fixedStudentId,
  })  : planRepo = planRepo ?? PlanRepository(),
        masteryService = masteryService ?? MasteryGraphService(),
        topicRepository = topicRepository ?? TopicRepository(),
        roadmapRepo = roadmapRepo ?? RoadmapRepository(),
        planService = planService ??
            PersonalLearningPlanService(
              masteryService: masteryService ?? MasteryGraphService(),
            );

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

  Future<RoadmapModel?> createRoadmap({
    required String goal,
    required int days,
    required AppLocalizations l10n,
  }) async {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: days));

    final numMilestones = (days / 7).ceil().clamp(1, 52);
    final milestones = <MilestoneModel>[];
    for (var i = 0; i < numMilestones; i++) {
      final milestoneDeadline = now.add(Duration(
        days: ((i + 1) * days / numMilestones).round(),
      ));
      milestones.add(MilestoneModel(
        id: const Uuid().v4(),
        title: l10n.weekNumber(i + 1),
        description: l10n.milestoneForWeek(i + 1),
        deadline: milestoneDeadline,
        order: i + 1,
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
    );

    await roadmapRepo.init();
    await roadmapRepo.saveRoadmap(roadmap);
    return roadmap;
  }

  Future<RoadmapModel?> createRoadmapFromGoal(
    String goal,
    int days,
    AppLocalizations l10n,
  ) async {
    return createRoadmap(goal: goal, days: days, l10n: l10n);
  }
}
