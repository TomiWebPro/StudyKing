class TopicWorkload {
  final String topicId;
  final String topicTitle;
  final int totalQuestions;
  final int masteredQuestions;
  final int atRiskQuestions;
  final int unattemptedQuestions;
  final double masteryLevel;
  final double estimatedLessonsRemaining;

  const TopicWorkload({
    required this.topicId,
    required this.topicTitle,
    required this.totalQuestions,
    required this.masteredQuestions,
    required this.atRiskQuestions,
    required this.unattemptedQuestions,
    required this.masteryLevel,
    required this.estimatedLessonsRemaining,
  });
}

class SubjectWorkload {
  final String subjectId;
  final String subjectTitle;
  final int totalQuestions;
  final int masteredQuestions;
  final int atRiskQuestions;
  final int unattemptedQuestions;
  final double overallMasteryLevel;
  final double estimatedLessonsRemaining;
  final List<TopicWorkload> topicWorkloads;

  const SubjectWorkload({
    required this.subjectId,
    required this.subjectTitle,
    required this.totalQuestions,
    required this.masteredQuestions,
    required this.atRiskQuestions,
    required this.unattemptedQuestions,
    required this.overallMasteryLevel,
    required this.estimatedLessonsRemaining,
    required this.topicWorkloads,
  });
}

class RemainingWorkloadEstimator {
  // Minimum mastery level (70%) to consider a topic "mastered"
  static const double masteryThreshold = 0.7;
  // Below this mastery level (50%), a topic is considered "at risk"
  static const double atRiskThreshold = 0.5;
  // Assumed number of questions needed per lesson for workload estimation
  static const int questionsPerLesson = 8;

  double _lessonsFromCount(int count) {
    return count / questionsPerLesson;
  }

  SubjectWorkload estimateSubjectWorkload({
    required String subjectId,
    required String subjectTitle,
    required Map<String, String> topicTitles,
    required Map<String, int> questionsPerTopic,
    required Map<String, double> topicMasteryLevels,
  }) {
    int totalQuestions = 0;
    int totalMastered = 0;
    int totalAtRisk = 0;
    int totalUnattempted = 0;
    final topicWorkloads = <TopicWorkload>[];

    for (final entry in questionsPerTopic.entries) {
      final topicId = entry.key;
      final topicTitle = topicTitles[topicId] ?? topicId;
      final total = entry.value;
      final masteryLevel =
          (topicMasteryLevels[topicId] ?? 0.0).clamp(0.0, 1.0).toDouble();

      // Bucket counts follow the actual mastery proportionally instead of
      // all-or-nothing thresholds, so the estimate varies continuously
      // with mastery (no cliff at the thresholds) and the reported
      // mastery level matches the input data.
      final mastered = (total * masteryLevel).round();
      final remaining = total - mastered;
      final effectiveAtRisk = masteryLevel < atRiskThreshold ? remaining : 0;
      final unattempted = remaining - effectiveAtRisk;

      final lessonsRemaining = _lessonsFromCount(effectiveAtRisk + unattempted);

      topicWorkloads.add(TopicWorkload(
        topicId: topicId,
        topicTitle: topicTitle,
        totalQuestions: total,
        masteredQuestions: mastered,
        atRiskQuestions: effectiveAtRisk,
        unattemptedQuestions: unattempted,
        masteryLevel: masteryLevel,
        estimatedLessonsRemaining: lessonsRemaining,
      ));

      totalQuestions += total;
      totalMastered += mastered;
      totalAtRisk += effectiveAtRisk;
      totalUnattempted += unattempted;
    }

    final overallMastery = totalQuestions == 0
        ? 1.0
        : (totalMastered + (totalAtRisk * 0.3)) / totalQuestions;

    return SubjectWorkload(
      subjectId: subjectId,
      subjectTitle: subjectTitle,
      totalQuestions: totalQuestions,
      masteredQuestions: totalMastered,
      atRiskQuestions: totalAtRisk,
      unattemptedQuestions: totalUnattempted,
      overallMasteryLevel: overallMastery,
      estimatedLessonsRemaining: _lessonsFromCount(totalAtRisk + totalUnattempted),
      topicWorkloads: topicWorkloads,
    );
  }

  double estimateOverallMastery(List<SubjectWorkload> workloads) {
    if (workloads.isEmpty) return 1.0;
    final totalQuestions = workloads.fold<int>(0, (s, w) => s + w.totalQuestions);
    if (totalQuestions == 0) return 1.0;
    final totalMastered = workloads.fold<int>(0, (s, w) => s + w.masteredQuestions);
    final totalAtRisk = workloads.fold<int>(0, (s, w) => s + w.atRiskQuestions);
    return (totalMastered + (totalAtRisk * 0.3)) / totalQuestions;
  }

  double estimateTotalLessonsRemaining(List<SubjectWorkload> workloads) {
    final count = workloads.fold<int>(0, (s, w) => s + w.atRiskQuestions + w.unattemptedQuestions);
    return _lessonsFromCount(count);
  }
}
