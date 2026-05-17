abstract class ActionPlanner {
  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  });

  Future<bool> cancelLesson(String sessionId);

  Future<bool> suggestPlanRegeneration({
    required String studentId,
    required double adjustmentFactor,
  });
}
