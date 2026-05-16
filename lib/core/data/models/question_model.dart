import 'package:hive_flutter/hive_flutter.dart';
import '../enums.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';

/// Shared model used by 4 features (questions, practice, planner, core services).
/// Retained in core because it is shared across >=3 features.
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

  @HiveField(8, defaultValue: [])
  final List<String> options;

  @HiveField(9, defaultValue: '')
  final String allowedAnswerTypes;

  @HiveField(10)
  final Markscheme? markscheme;

  @HiveField(11)
  final String? model;

  @HiveField(12)
  final String? topic;

  @HiveField(13, defaultValue: [])
  final List<String> tags;

  @HiveField(14)
  final String? explanation;

  @HiveField(15)
  final String? difficultyText;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  DateTime updatedAt;

  @HiveField(18)
  final DateTime? nextReview;

  /// JSON-serialized SM-2 data (repetitions, easeFactor, previousInterval, lastReview).
  /// Managed by [SpacedRepetitionEngine] — not a Hive field.
  final String? srDataJson;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.difficulty = 1,
    required this.subjectId,
    required this.topicId,
    this.variantIds = const [],
    this.sourceIds = const [],
    this.options = const [],
    this.allowedAnswerTypes = '',
    this.markscheme,
    this.model,
    this.topic,
    this.tags = const [],
    this.explanation,
    this.difficultyText,
    required this.createdAt,
    required this.updatedAt,
    this.nextReview,
    this.srDataJson,
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
    'options': options,
    'allowedAnswerTypes': allowedAnswerTypes,
    'markscheme': markscheme?.toJson(),
    'model': model,
    'topic': topic,
    'tags': tags,
    'explanation': explanation,
    'difficultyText': difficultyText,
    'nextReview': nextReview?.toIso8601String(),
    'srDataJson': srDataJson,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Question.fromJson(Map<String, dynamic> json) {
    final typeIndex = json['type'];
    final type = typeIndex != null && typeIndex is int
        ? QuestionType.values[typeIndex]
        : QuestionType.singleChoice;
    
    Markscheme? parsedMarkscheme;
    final markschemeData = json['markscheme'];
    if (markschemeData != null) {
      if (markschemeData is Map) {
        parsedMarkscheme = Markscheme.fromJson(Map<String, dynamic>.from(markschemeData));
      } else if (markschemeData is String && markschemeData.isNotEmpty) {
        parsedMarkscheme = Markscheme(
          questionId: json['id'] ?? '',
          correctAnswer: markschemeData,
          acceptableAnswers: List<String>.from(json['acceptableAnswers'] ?? []),
          explanation: json['explanation'],
        );
      }
    }
    
    final createdAt = DateTime.parse(json['createdAt']);
    final updatedAt = DateTime.parse(json['updatedAt']);
    
    return Question(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      type: type,
      difficulty: json['difficulty'] ?? 1,
      subjectId: json['subjectId'] ?? '',
      topicId: json['topicId'] ?? '',
      variantIds: List<String>.from(json['variantIds'] ?? []),
      sourceIds: List<String>.from(json['sourceIds'] ?? []),
      options: List<String>.from(json['options'] ?? []),
      allowedAnswerTypes: json['allowedAnswerTypes'] ?? '',
      markscheme: parsedMarkscheme,
      model: json['model'],
      topic: json['topic'],
      tags: List<String>.from(json['tags'] ?? []),
      explanation: json['explanation'],
      difficultyText: json['difficultyText'],
      nextReview: json['nextReview'] != null ? DateTime.parse(json['nextReview']) : null,
      srDataJson: json['srDataJson'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Question copyWith({
    String? id,
    String? text,
    QuestionType? type,
    int? difficulty,
    String? subjectId,
    String? topicId,
    List<String>? variantIds,
    List<String>? sourceIds,
    List<String>? options,
    String? allowedAnswerTypes,
    Markscheme? markscheme,
    String? model,
    String? topic,
    List<String>? tags,
    String? explanation,
    String? difficultyText,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextReview,
    String? srDataJson,
    bool clearSrData = false,
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
      options: options ?? this.options,
      allowedAnswerTypes: allowedAnswerTypes ?? this.allowedAnswerTypes,
      markscheme: markscheme ?? this.markscheme,
      model: model ?? this.model,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      explanation: explanation ?? this.explanation,
      difficultyText: difficultyText ?? this.difficultyText,
      nextReview: nextReview ?? this.nextReview,
      srDataJson: clearSrData ? null : (srDataJson ?? this.srDataJson),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
