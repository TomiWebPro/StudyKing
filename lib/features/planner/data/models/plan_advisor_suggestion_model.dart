import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 37)
class PlanAdvisorSuggestionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final DateTime generatedAt;

  @HiveField(3)
  final String suggestionType;

  @HiveField(4)
  final String? workloadEstimate;

  @HiveField(5)
  final String? pathwaySuggestion;

  @HiveField(6)
  final String? motivationalReasoning;

  @HiveField(7)
  final Map<String, dynamic> metadata;

  @HiveField(8)
  final bool applied;

  PlanAdvisorSuggestionModel({
    required this.id,
    required this.studentId,
    required this.generatedAt,
    this.suggestionType = 'plan_generation',
    this.workloadEstimate,
    this.pathwaySuggestion,
    this.motivationalReasoning,
    this.metadata = const {},
    this.applied = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'generatedAt': generatedAt.toIso8601String(),
    'suggestionType': suggestionType,
    'workloadEstimate': workloadEstimate,
    'pathwaySuggestion': pathwaySuggestion,
    'motivationalReasoning': motivationalReasoning,
    'metadata': metadata,
    'applied': applied,
  };

  factory PlanAdvisorSuggestionModel.fromJson(Map<String, dynamic> json) =>
      PlanAdvisorSuggestionModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        suggestionType: json['suggestionType'] as String? ?? 'plan_generation',
        workloadEstimate: json['workloadEstimate'] as String?,
        pathwaySuggestion: json['pathwaySuggestion'] as String?,
        motivationalReasoning: json['motivationalReasoning'] as String?,
        metadata: json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : const {},
        applied: json['applied'] as bool? ?? false,
      );

  PlanAdvisorSuggestionModel copyWith({
    String? id,
    String? studentId,
    DateTime? generatedAt,
    String? suggestionType,
    String? workloadEstimate,
    String? pathwaySuggestion,
    String? motivationalReasoning,
    Map<String, dynamic>? metadata,
    bool? applied,
  }) {
    return PlanAdvisorSuggestionModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      generatedAt: generatedAt ?? this.generatedAt,
      suggestionType: suggestionType ?? this.suggestionType,
      workloadEstimate: workloadEstimate ?? this.workloadEstimate,
      pathwaySuggestion: pathwaySuggestion ?? this.pathwaySuggestion,
      motivationalReasoning: motivationalReasoning ?? this.motivationalReasoning,
      metadata: metadata ?? this.metadata,
      applied: applied ?? this.applied,
    );
  }
}
