import 'package:studyking/core/errors/result.dart';

class AdvisorAnalysis {
  final String? workloadEstimate;
  final String? pathwaySuggestion;
  final String? motivationalReasoning;
  final String? adaptationReasoning;
  final Map<String, dynamic> metadata;

  const AdvisorAnalysis({
    this.workloadEstimate,
    this.pathwaySuggestion,
    this.motivationalReasoning,
    this.adaptationReasoning,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    if (workloadEstimate != null) 'workloadEstimate': workloadEstimate,
    if (pathwaySuggestion != null) 'pathwaySuggestion': pathwaySuggestion,
    if (motivationalReasoning != null) 'motivationalReasoning': motivationalReasoning,
    if (adaptationReasoning != null) 'adaptationReasoning': adaptationReasoning,
    ...metadata,
  };
}

abstract class PlannerAdvisorStrategy {
  Future<Result<AdvisorAnalysis>> analyzeForPlanGeneration({
    required String studentId,
    required String courseName,
    required int planDurationDays,
    required double targetMinutesPerDay,
    List<String> weakTopicIds = const [],
    List<String> atRiskTopicIds = const [],
    double currentAdherence = 0.0,
    int consecutiveLowAdherenceDays = 0,
  });

  Future<Result<AdvisorAnalysis>> analyzeForAdaptation({
    required String studentId,
    required double currentAdherence,
    required int consecutiveLowDays,
    required String planSummary,
  });
}
