import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/contracts/plan_adherence_contract.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import '../services/instrumentation_service.dart';

class SessionPlanAdherenceService implements PlanAdherenceContract {
  final Logger _logger = const Logger('SessionPlanAdherenceService');

  @override
  Future<void> recordAdherenceForSession({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
  }) async {
    try {
      final planRepo = PlanRepository();
      await planRepo.init();
      final plan = await planRepo.loadPlan(studentId);
      if (plan != null) {
        final todayPlan = plan.dailyPlans.where((d) =>
            d.date.year == DateTime.now().year &&
            d.date.month == DateTime.now().month &&
            d.date.day == DateTime.now().day).firstOrNull;
        if (todayPlan != null) {
          final instrumentation = InstrumentationService(
            adherenceRepository: PlanAdherenceRepository(),
          );
          await instrumentation.init();
          instrumentation.recordPlanAdherence(
            studentId: studentId,
            date: DateTime.now(),
            plannedQuestions: todayPlan.targetQuestions,
            actualQuestions: actualQuestions,
            plannedMinutes: todayPlan.targetMinutes,
            actualMinutes: actualMinutes,
          );
        }
      }
    } catch (e) {
      _logger.e('Failed to track plan adherence after session', e);
    }
  }
}
