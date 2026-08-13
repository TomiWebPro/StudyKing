class LearningPreference {
  final String studentId;
  final String preferredBlockType;
  final int optimalSessionDurationMinutes;
  final bool prefersVisualExplanations;
  final bool prefersStepByStep;
  final double spacedRepetitionEffectiveness;
  final Map<String, double> methodEffectivenessScores;
  final DateTime lastUpdated;

  const LearningPreference({
    required this.studentId,
    this.preferredBlockType = 'exercise',
    this.optimalSessionDurationMinutes = 25,
    this.prefersVisualExplanations = false,
    this.prefersStepByStep = true,
    this.spacedRepetitionEffectiveness = 0.0,
    this.methodEffectivenessScores = const {},
    required this.lastUpdated,
  });

  factory LearningPreference.empty(String studentId) {
    return LearningPreference(
      studentId: studentId,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'preferredBlockType': preferredBlockType,
      'optimalSessionDurationMinutes': optimalSessionDurationMinutes,
      'prefersVisualExplanations': prefersVisualExplanations,
      'prefersStepByStep': prefersStepByStep,
      'spacedRepetitionEffectiveness': spacedRepetitionEffectiveness,
      'methodEffectivenessScores': methodEffectivenessScores,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory LearningPreference.fromMap(Map<String, dynamic> map) {
    return LearningPreference(
      studentId: map['studentId'] as String? ?? '',
      preferredBlockType: map['preferredBlockType'] as String? ?? 'exercise',
      optimalSessionDurationMinutes:
          (map['optimalSessionDurationMinutes'] as num?)?.toInt() ?? 25,
      prefersVisualExplanations:
          map['prefersVisualExplanations'] as bool? ?? false,
      prefersStepByStep: map['prefersStepByStep'] as bool? ?? true,
      spacedRepetitionEffectiveness:
          (map['spacedRepetitionEffectiveness'] as num?)?.toDouble() ?? 0.0,
      methodEffectivenessScores:
          (map['methodEffectivenessScores'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              {},
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String) ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  LearningPreference copyWith({
    String? preferredBlockType,
    int? optimalSessionDurationMinutes,
    bool? prefersVisualExplanations,
    bool? prefersStepByStep,
    double? spacedRepetitionEffectiveness,
    Map<String, double>? methodEffectivenessScores,
  }) {
    return LearningPreference(
      studentId: studentId,
      preferredBlockType: preferredBlockType ?? this.preferredBlockType,
      optimalSessionDurationMinutes:
          optimalSessionDurationMinutes ?? this.optimalSessionDurationMinutes,
      prefersVisualExplanations:
          prefersVisualExplanations ?? this.prefersVisualExplanations,
      prefersStepByStep: prefersStepByStep ?? this.prefersStepByStep,
      spacedRepetitionEffectiveness: spacedRepetitionEffectiveness ??
          this.spacedRepetitionEffectiveness,
      methodEffectivenessScores:
          methodEffectivenessScores ?? this.methodEffectivenessScores,
      lastUpdated: DateTime.now(),
    );
  }
}
