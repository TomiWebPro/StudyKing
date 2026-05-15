class PlanAdherenceMetric {
  final DateTime date;
  final String studentId;
  final int plannedQuestions;
  final int actualQuestions;
  final int plannedMinutes;
  final int actualMinutes;
  final double adherenceScore;
  final Map<String, dynamic>? metadata;

  PlanAdherenceMetric({
    required this.date,
    required this.studentId,
    required this.plannedQuestions,
    required this.actualQuestions,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.adherenceScore,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'studentId': studentId,
    'plannedQuestions': plannedQuestions,
    'actualQuestions': actualQuestions,
    'plannedMinutes': plannedMinutes,
    'actualMinutes': actualMinutes,
    'adherenceScore': adherenceScore,
    'metadata': metadata,
  };
}
