import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/utils/answer_comparator.dart';
import 'package:studyking/core/utils/string_extensions.dart';

enum EvaluationType {
  exactMatch,
  acceptableMatch,
  fuzzyMatch,
  partialMatch,
  stepBased,
}

@HiveType(typeId: 14)
class QuestionEvaluation extends HiveObject {
  @HiveField(0)
  final String questionId;

  @HiveField(1)
  final String correctAnswer;

  @HiveField(2)
  final List<String> acceptableAnswers;

  @HiveField(3)
  final EvaluationType evaluationType;

  @HiveField(4)
  final String? explanation;

  @HiveField(5)
  final List<EvaluationStep>? steps;

  @HiveField(6)
  final double? maxPoints;

  @HiveField(7)
  final Map<String, dynamic>? metadata;

  @HiveField(8)
  final int version;

  QuestionEvaluation({
    required this.questionId,
    required this.correctAnswer,
    this.acceptableAnswers = const [],
    this.evaluationType = EvaluationType.exactMatch,
    this.explanation,
    this.steps,
    this.maxPoints,
    this.metadata,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'correctAnswer': correctAnswer,
    'acceptableAnswers': acceptableAnswers,
    'evaluationType': evaluationType.index,
    'explanation': explanation,
    'steps': steps?.map((s) => s.toJson()).toList(),
    'maxPoints': maxPoints,
    'metadata': metadata,
    'version': version,
  };

  factory QuestionEvaluation.fromJson(Map<String, dynamic> json) => QuestionEvaluation(
    questionId: json['questionId'],
    correctAnswer: json['correctAnswer'],
    acceptableAnswers: List<String>.from(json['acceptableAnswers'] ?? []),
    evaluationType: EvaluationType.values[json['evaluationType'] ?? 0],
    explanation: json['explanation'],
    steps: (json['steps'] as List?)?.map((s) => EvaluationStep.fromJson(s)).toList(),
    maxPoints: json['maxPoints']?.toDouble(),
    metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    version: json['version'] ?? 1,
  );

  factory QuestionEvaluation.fromLegacy({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) => QuestionEvaluation(
    questionId: questionId,
    correctAnswer: markscheme ?? correctAnswer ?? '',
    acceptableAnswers: options ?? [],
    evaluationType: EvaluationType.exactMatch,
    explanation: explanation,
  );

  factory QuestionEvaluation.fromLegacyMarkscheme({
    required String questionId,
    required String correctAnswer,
    List<String>? acceptableAnswers,
    String? explanation,
    List<String>? steps,
  }) => QuestionEvaluation(
    questionId: questionId,
    correctAnswer: correctAnswer,
    acceptableAnswers: acceptableAnswers ?? [],
    evaluationType: steps != null && steps.isNotEmpty
        ? EvaluationType.stepBased
        : EvaluationType.exactMatch,
    explanation: explanation,
    steps: steps?.asMap().entries.map((e) => EvaluationStep(
      stepNumber: '${e.key + 1}',
      requiredAnswer: e.value,
      points: 1.0,
    )).toList(),
  );

  QuestionEvaluation copyWith({
    String? questionId,
    String? correctAnswer,
    List<String>? acceptableAnswers,
    EvaluationType? evaluationType,
    String? explanation,
    List<EvaluationStep>? steps,
    double? maxPoints,
    Map<String, dynamic>? metadata,
    int? version,
  }) {
    return QuestionEvaluation(
      questionId: questionId ?? this.questionId,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      acceptableAnswers: acceptableAnswers ?? this.acceptableAnswers,
      evaluationType: evaluationType ?? this.evaluationType,
      explanation: explanation ?? this.explanation,
      steps: steps ?? this.steps,
      maxPoints: maxPoints ?? this.maxPoints,
      metadata: metadata ?? this.metadata,
      version: version ?? this.version,
    );
  }

  bool isMatch(String userAnswer) {
    final normalizedAnswer = userAnswer.normalized;
    final normalizedCorrect = correctAnswer.normalized;

    if (AnswerComparator.areEquivalent(userAnswer, correctAnswer)) return true;

    for (final acceptable in acceptableAnswers) {
      if (AnswerComparator.areEquivalent(userAnswer, acceptable)) return true;
    }

    if (evaluationType == EvaluationType.fuzzyMatch && normalizedAnswer.isNotEmpty) {
      final answerWords = normalizedAnswer.split(' ');
      final correctWords = normalizedCorrect.split(' ');
      if (answerWords.length >= correctWords.length * 0.8) {
        final matchingRatio = answerWords.where((word) => correctWords.contains(word)).length / correctWords.length;
        return matchingRatio > 0.7;
      }
    }

    if (evaluationType == EvaluationType.stepBased && steps != null && steps!.isNotEmpty) {
      final answerLower = userAnswer.normalized;
      return steps!.every((step) => answerLower.contains(step.requiredAnswer.normalized));
    }

    return false;
  }
}

@HiveType(typeId: 15)
class EvaluationStep {
  @HiveField(0)
  final String stepNumber;

  @HiveField(1)
  final String requiredAnswer;

  @HiveField(2)
  final double points;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final double? partialCredit;

  EvaluationStep({
    required this.stepNumber,
    required this.requiredAnswer,
    required this.points,
    this.description,
    this.partialCredit,
  });

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'requiredAnswer': requiredAnswer,
    'points': points,
    'description': description,
    'partialCredit': partialCredit,
  };

  factory EvaluationStep.fromJson(Map<String, dynamic> json) => EvaluationStep(
    stepNumber: json['stepNumber'],
    requiredAnswer: json['requiredAnswer'],
    points: (json['points'] ?? 1.0).toDouble(),
    description: json['description'],
    partialCredit: json['partialCredit']?.toDouble(),
  );
}