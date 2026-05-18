import 'package:studyking/core/data/contracts/plan_adherence_contract.dart';
import 'package:studyking/core/services/personal_learning_plan_service.dart';

class SessionPlanAdherenceService implements PlanAdherenceContract {
  final PersonalLearningPlanService _planService;

  SessionPlanAdherenceService({
    PersonalLearningPlanService? planService,
  }) : _planService = planService ?? PersonalLearningPlanService();

  @override
  Future<void> recordAdherenceForSession({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
  }) async {
    await _planService.recordDailyAdherence(
      studentId: studentId,
      actualQuestions: actualQuestions,
      actualMinutes: actualMinutes,
    );
  }
}
