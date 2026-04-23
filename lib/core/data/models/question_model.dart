import 'package:hive_flutter/hive_flutter.dart';
import '../enums.dart';

@HiveType(typeId: 2)
class Question extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final QuestionType type;

  @HiveField(3, defaultValue: 1)
  final int difficulty;

  @HiveField(4)
  final String subjectId;

  @HiveField(5)
  final String topicId;

  @HiveField(6, defaultValue: [])
  final List<String> variantIds;

  @HiveField(7, defaultValue: [])
  final List<String> sourceIds;

  @HiveField(8, defaultValue: '')
  final String allowedAnswerTypes;

  @HiveField(9)
  final String? markscheme;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.difficulty = 1,
    required this.subjectId,
    required this.topicId,
    this.variantIds = const [],
    this.sourceIds = const [],
    this.allowedAnswerTypes = '',
    this.markscheme,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type.index,
    'difficulty': difficulty,
    'subjectId': subjectId,
    'topicId': topicId,
    'variantIds': variantIds,
    'sourceIds': sourceIds,
    'allowedAnswerTypes': allowedAnswerTypes,
    'markscheme': markscheme,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'],
    text: json['text'],
    type: QuestionType.values[json['type']],
    difficulty: json['difficulty'] ?? 1,
    subjectId: json['subjectId'],
    topicId: json['topicId'],
    variantIds: List<String>.from(json['variantIds'] ?? []),
    sourceIds: List<String>.from(json['sourceIds'] ?? []),
    allowedAnswerTypes: json['allowedAnswerTypes'] ?? '',
    markscheme: json['markscheme'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Question copyWith({
    String? id,
    String? text,
    QuestionType? type,
    int? difficulty,
    String? subjectId,
    String? topicId,
    List<String>? variantIds,
    List<String>? sourceIds,
    String? allowedAnswerTypes,
    String? markscheme,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      variantIds: variantIds ?? this.variantIds,
      sourceIds: sourceIds ?? this.sourceIds,
      allowedAnswerTypes: allowedAnswerTypes ?? this.allowedAnswerTypes,
      markscheme: markscheme ?? this.markscheme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
