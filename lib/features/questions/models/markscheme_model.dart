import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 12)
class Markscheme extends HiveObject {
  @HiveField(0)
  final String questionId;

  @HiveField(1)
  final String correctAnswer;

  @HiveField(2)
  final List<String> acceptableAnswers;

  @HiveField(3)
  final String? explanation;

  @HiveField(4)
  final double? markschemePoints;

  @HiveField(5, defaultValue: [])
  final List<MarkSchemeStep> steps;

  Markscheme({
    required this.questionId,
    required this.correctAnswer,
    List<String>? acceptableAnswers,
    this.explanation,
    this.markschemePoints,
    List<MarkSchemeStep>? steps,
  })  : acceptableAnswers = acceptableAnswers ?? [],
        steps = steps ?? [];

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'correctAnswer': correctAnswer,
    'acceptableAnswers': acceptableAnswers,
    'explanation': explanation,
    'markschemePoints': markschemePoints,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory Markscheme.fromJson(Map<String, dynamic> json) => Markscheme(
    questionId: json['questionId'],
    correctAnswer: json['correctAnswer'],
    acceptableAnswers: List<String>.from(json['acceptableAnswers'] ?? []),
    explanation: json['explanation'],
    markschemePoints: json['markschemePoints'],
    steps: (json['steps'] as List? ?? [])
        .map((s) => MarkSchemeStep.fromJson(s))
        .toList(),
  );
}

@HiveType(typeId: 13)
class MarkSchemeStep {
  @HiveField(0)
  final String stepNumber;

  @HiveField(1)
  final String requiredAnswer;

  @HiveField(2)
  final double points;

  @HiveField(3)
  final String? description;

  MarkSchemeStep({
    required this.stepNumber,
    required this.requiredAnswer,
    required this.points,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'requiredAnswer': requiredAnswer,
    'points': points,
    'description': description,
  };

  factory MarkSchemeStep.fromJson(Map<String, dynamic> json) => MarkSchemeStep(
    stepNumber: json['stepNumber'],
    requiredAnswer: json['requiredAnswer'],
    points: json['points'] ?? 1.0,
    description: json['description'],
  );
}
