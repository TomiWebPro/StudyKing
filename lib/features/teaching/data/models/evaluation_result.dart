class EvaluationResult {
  final double score;
  final String explanation;
  final double? partialCredit;
  final Map<String, double>? conceptBreakdown;

  const EvaluationResult({
    required this.score,
    required this.explanation,
    this.partialCredit,
    this.conceptBreakdown,
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'explanation': explanation,
    if (partialCredit != null) 'partialCredit': partialCredit,
    if (conceptBreakdown != null) 'conceptBreakdown': conceptBreakdown,
  };

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      score: (json['score'] as num?)?.toDouble() ?? 0.5,
      explanation: json['explanation'] as String? ?? '',
      partialCredit: (json['partialCredit'] as num?)?.toDouble(),
      conceptBreakdown: json['conceptBreakdown'] != null
          ? Map<String, double>.from(
              (json['conceptBreakdown'] as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toDouble()),
              ),
            )
          : null,
    );
  }
}
