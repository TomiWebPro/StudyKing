abstract class PlanAdherenceContract {
  Future<void> recordAdherenceForSession({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
  });
}
