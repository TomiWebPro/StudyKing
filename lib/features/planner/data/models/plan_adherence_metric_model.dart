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

  factory PlanAdherenceMetric.fromJson(Map<String, dynamic> json) {
    return PlanAdherenceMetric(
      date: DateTime.parse(json['date'] as String),
      studentId: json['studentId'] as String,
      plannedQuestions: (json['plannedQuestions'] as num).toInt(),
      actualQuestions: (json['actualQuestions'] as num).toInt(),
      plannedMinutes: (json['plannedMinutes'] as num).toInt(),
      actualMinutes: (json['actualMinutes'] as num).toInt(),
      adherenceScore: (json['adherenceScore'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

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

  PlanAdherenceMetric copyWith({
    DateTime? date,
    String? studentId,
    int? plannedQuestions,
    int? actualQuestions,
    int? plannedMinutes,
    int? actualMinutes,
    double? adherenceScore,
    Map<String, dynamic>? metadata,
  }) {
    return PlanAdherenceMetric(
      date: date ?? this.date,
      studentId: studentId ?? this.studentId,
      plannedQuestions: plannedQuestions ?? this.plannedQuestions,
      actualQuestions: actualQuestions ?? this.actualQuestions,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      adherenceScore: adherenceScore ?? this.adherenceScore,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanAdherenceMetric &&
          date == other.date &&
          studentId == other.studentId &&
          plannedQuestions == other.plannedQuestions &&
          actualQuestions == other.actualQuestions &&
          plannedMinutes == other.plannedMinutes &&
          actualMinutes == other.actualMinutes &&
          adherenceScore == other.adherenceScore &&
          metadata == other.metadata;

  @override
  int get hashCode =>
      date.hashCode ^
      studentId.hashCode ^
      plannedQuestions.hashCode ^
      actualQuestions.hashCode ^
      plannedMinutes.hashCode ^
      actualMinutes.hashCode ^
      adherenceScore.hashCode ^
      metadata.hashCode;
}
