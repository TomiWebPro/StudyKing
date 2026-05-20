class EvaluationResult {
  final double score;
  final String explanation;
  final double? partialCredit;
  final Map<String, double>? conceptBreakdown;
  final String? correctAnswer;
  final List<String>? options;
  final String? exerciseType;

  const EvaluationResult({
    required this.score,
    required this.explanation,
    this.partialCredit,
    this.conceptBreakdown,
    this.correctAnswer,
    this.options,
    this.exerciseType,
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'explanation': explanation,
    if (partialCredit != null) 'partialCredit': partialCredit,
    if (conceptBreakdown != null) 'conceptBreakdown': conceptBreakdown,
    if (correctAnswer != null) 'correctAnswer': correctAnswer,
    if (options != null) 'options': options,
    if (exerciseType != null) 'exerciseType': exerciseType,
  };

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    List<String>? parsedOptions;
    if (optionsRaw is List) {
      parsedOptions = optionsRaw.cast<String>();
    }

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
      correctAnswer: json['correctAnswer'] as String?,
      options: parsedOptions,
      exerciseType: (json['type'] as String?) ?? (json['exerciseType'] as String?),
    );
  }
}
