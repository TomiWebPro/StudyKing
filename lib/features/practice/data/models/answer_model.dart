import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 3)
class Answer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String questionId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final bool isCorrect;

  @HiveField(4, defaultValue: '')
  final String explanation;

  @HiveField(5, defaultValue: [])
  final List<String> variantIds;

  @HiveField(6, defaultValue: 0.0)
  final double confidenceScore;

  Answer({
    required this.id,
    required this.questionId,
    required this.text,
    required this.isCorrect,
    this.explanation = '',
    this.variantIds = const [],
    this.confidenceScore = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionId': questionId,
    'text': text,
    'isCorrect': isCorrect,
    'explanation': explanation,
    'variantIds': variantIds,
    'confidenceScore': confidenceScore,
  };

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    id: json['id'],
    questionId: json['questionId'],
    text: json['text'],
    isCorrect: json['isCorrect'],
    explanation: json['explanation'] ?? '',
    variantIds: List<String>.from(json['variantIds'] ?? []),
    confidenceScore: json['confidenceScore'] ?? 0.0,
  );
}
