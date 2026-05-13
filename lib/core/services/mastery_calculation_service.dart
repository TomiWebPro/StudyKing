import '../data/models/mastery_state_model.dart';

class MasteryCalculationService {
  MasteryState recordAttempt({
    required MasteryState current,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) {
    final totalAttempts = current.totalAttempts + 1;
    final correctAttempts = current.correctAttempts + (isCorrect ? 1 : 0);

    final averageTimeMs =
        (current.averageTimeMs * (totalAttempts - 1) + timeSpentMs) / totalAttempts;

    final recentConfidence = [...current.recentConfidence, confidence];
    if (recentConfidence.length > 20) recentConfidence.removeAt(0);

    final recentAccuracyVal = isCorrect ? 1.0 : 0.0;
    final recentAccuracy = [...current.recentAccuracy, recentAccuracyVal];
    if (recentAccuracy.length > 20) recentAccuracy.removeAt(0);

    int currentStreak;
    int bestStreak;
    if (isCorrect) {
      currentStreak = current.currentStreak + 1;
      bestStreak = currentStreak > current.bestStreak ? currentStreak : current.bestStreak;
    } else {
      currentStreak = 0;
      bestStreak = current.bestStreak;
    }

    final now = DateTime.now();

    final weakSubtopics = [...current.weakSubtopics];
    if (subtopicId != null && !isCorrect && !weakSubtopics.contains(subtopicId)) {
      weakSubtopics.add(subtopicId);
    }

    final accuracy = _updateAccuracy(correctAttempts, totalAttempts);
    final confidenceTrend = _updateConfidenceTrend(recentConfidence);
    final speedTrend = _updateSpeedTrend(averageTimeMs);
    final forgettingRisk = _updateForgettingRisk(accuracy, now, now);
    final masteryLevel = _updateMasteryLevel(accuracy, currentStreak, totalAttempts);
    final readinessScore = _updateReadinessScore(
      accuracy,
      currentStreak,
      confidenceTrend,
      now,
      now,
    );
    final reviewUrgency = _updateReviewUrgency(forgettingRisk, now, now);

    return MasteryState(
      studentId: current.studentId,
      topicId: current.topicId,
      accuracy: accuracy,
      confidenceTrend: confidenceTrend,
      speedTrend: speedTrend,
      forgettingRisk: forgettingRisk,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      averageTimeMs: averageTimeMs,
      lastAttempt: now,
      lastUpdated: now,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      recentConfidence: recentConfidence,
      recentAccuracy: recentAccuracy,
      masteryLevel: masteryLevel,
      readinessScore: readinessScore,
      reviewUrgency: reviewUrgency,
      weakSubtopics: weakSubtopics,
    );
  }

  double _updateAccuracy(int correctAttempts, int totalAttempts) {
    if (totalAttempts == 0) return 0.0;
    return correctAttempts / totalAttempts;
  }

  double _updateConfidenceTrend(List<int> recentConfidence) {
    if (recentConfidence.isEmpty) return 0.5;
    return recentConfidence.reduce((a, b) => a + b) / recentConfidence.length / 5.0;
  }

  double _updateSpeedTrend(double averageTimeMs) {
    const expectedTimeMs = 60000.0;
    if (averageTimeMs > 0) {
      return (expectedTimeMs / averageTimeMs).clamp(0.0, 1.0);
    }
    return 0.5;
  }

  double _updateForgettingRisk(double accuracy, DateTime lastAttempt, DateTime now) {
    final daysSinceLastAttempt = now.difference(lastAttempt).inDays;
    final retentionDecay = accuracy * (1 - (daysSinceLastAttempt / 30.0).clamp(0.0, 1.0));
    return 1 - retentionDecay;
  }

  MasteryLevel _updateMasteryLevel(double accuracy, int currentStreak, int totalAttempts) {
    if (accuracy >= 0.9 && currentStreak >= 5 && totalAttempts >= 10) {
      return MasteryLevel.expert;
    } else if (accuracy >= 0.8 && totalAttempts >= 5) {
      return MasteryLevel.proficient;
    } else if (accuracy >= 0.6 && totalAttempts >= 3) {
      return MasteryLevel.developing;
    } else if (totalAttempts >= 1) {
      return MasteryLevel.browsing;
    } else {
      return MasteryLevel.novice;
    }
  }

  double _recencyScore(DateTime lastAttempt, DateTime now) {
    final daysSince = now.difference(lastAttempt).inDays;
    if (daysSince == 0) return 1.0;
    if (daysSince <= 1) return 0.9;
    if (daysSince <= 3) return 0.7;
    if (daysSince <= 7) return 0.5;
    if (daysSince <= 14) return 0.3;
    return 0.1;
  }

  double _updateReadinessScore(
    double accuracy,
    int currentStreak,
    double confidenceTrend,
    DateTime lastAttempt,
    DateTime now,
  ) {
    const accuracyWeight = 0.4;
    const streakWeight = 0.2;
    const confidenceWeight = 0.2;
    const recencyWeight = 0.2;

    final streakNorm = (currentStreak / 10.0).clamp(0.0, 1.0);
    final recencyScore = _recencyScore(lastAttempt, now);

    return (accuracy * accuracyWeight) +
        (streakNorm * streakWeight) +
        (confidenceTrend * confidenceWeight) +
        (recencyScore * recencyWeight);
  }

  double _updateReviewUrgency(double forgettingRisk, DateTime lastAttempt, DateTime now) {
    final daysSinceAttempt = now.difference(lastAttempt).inDays;

    double urgency;
    if (daysSinceAttempt == 0) {
      urgency = 0.1;
    } else if (daysSinceAttempt <= 1) {
      urgency = 0.3;
    } else if (daysSinceAttempt <= 3) {
      urgency = 0.5 + (forgettingRisk * 0.2);
    } else if (daysSinceAttempt <= 7) {
      urgency = 0.7 + (forgettingRisk * 0.15);
    } else {
      urgency = 0.9 + (forgettingRisk * 0.1);
    }

    return urgency.clamp(0.0, 1.0);
  }
}
