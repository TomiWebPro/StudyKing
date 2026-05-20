const double adherenceQuestionWeight = 0.6;
const double adherenceTimeWeight = 0.4;
const double adherenceMaxTimeScore = 1.5;
const double adherenceDefaultScore = 0.5;

const double defaultMasteryThreshold = 0.8;
const double masteryLowAccuracy = 0.6;
const double masteryHighAccuracy = 0.9;
const int masteryStreakConsistency = 3;
const int masteryStreakHigh = 5;
const double masteryReviewUrgencyThreshold = 0.7;
const double masteryChallengeReadiness = 0.8;

const int defaultPlanDurationDays = 7;
const int defaultQuestionsPerDay = 15;
const double defaultMinutesPerDay = 30.0;
const int defaultMaxQuestionsPerTopic = 10;
const int defaultSessionDurationMinutes = 30;
const int lateNightHour = 22;
const int msPerSecond = 1000;
const int msPerMinute = 60000;

double calculateAdherenceScore({
  required int plannedQuestions,
  required int actualQuestions,
  required int plannedMinutes,
  required int actualMinutes,
}) {
  if (plannedQuestions == 0 && plannedMinutes == 0) return 1.0;

  final questionScore = plannedQuestions > 0
      ? (actualQuestions / plannedQuestions).clamp(0.0, 1.0)
      : adherenceDefaultScore;
  final timeScore = plannedMinutes > 0
      ? (actualMinutes / plannedMinutes).clamp(0.0, adherenceMaxTimeScore)
      : adherenceDefaultScore;

  return (questionScore * adherenceQuestionWeight + timeScore * adherenceTimeWeight).clamp(0.0, 1.0);
}
