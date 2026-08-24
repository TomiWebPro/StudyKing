import 'package:hive_flutter/hive_flutter.dart';

enum FeedbackTargetType {
  explanation,
  lesson,
  content,
}

enum FeedbackSentiment {
  none,
  positive,
  negative,
}

@HiveType(typeId: 44)
class LessonFeedbackModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String targetType;

  @HiveField(3)
  final String? lessonId;

  @HiveField(4)
  final String? messageId;

  @HiveField(5)
  final String sentiment;

  @HiveField(6)
  final int starRating;

  @HiveField(7)
  final String? comment;

  @HiveField(8)
  final bool reportedIncorrect;

  @HiveField(9)
  final DateTime createdAt;

  LessonFeedbackModel({
    required this.id,
    required this.studentId,
    required this.targetType,
    this.lessonId,
    this.messageId,
    this.sentiment = 'none',
    this.starRating = 0,
    this.comment,
    this.reportedIncorrect = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  FeedbackTargetType get targetTypeEnum =>
      FeedbackTargetType.values.firstWhere(
        (t) => t.name == targetType,
        orElse: () => FeedbackTargetType.explanation,
      );

  FeedbackSentiment get sentimentEnum =>
      FeedbackSentiment.values.firstWhere(
        (s) => s.name == sentiment,
        orElse: () => FeedbackSentiment.none,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'targetType': targetType,
        'lessonId': lessonId,
        'messageId': messageId,
        'sentiment': sentiment,
        'starRating': starRating,
        'comment': comment,
        'reportedIncorrect': reportedIncorrect,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LessonFeedbackModel.fromJson(Map<String, dynamic> json) =>
      LessonFeedbackModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        targetType: json['targetType'] as String? ?? 'explanation',
        lessonId: json['lessonId'] as String?,
        messageId: json['messageId'] as String?,
        sentiment: json['sentiment'] as String? ?? 'none',
        starRating: json['starRating'] as int? ?? 0,
        comment: json['comment'] as String?,
        reportedIncorrect: json['reportedIncorrect'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  LessonFeedbackModel copyWith({
    String? id,
    String? studentId,
    String? targetType,
    String? lessonId,
    String? messageId,
    String? sentiment,
    int? starRating,
    String? comment,
    bool? reportedIncorrect,
    DateTime? createdAt,
  }) {
    return LessonFeedbackModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      targetType: targetType ?? this.targetType,
      lessonId: lessonId ?? this.lessonId,
      messageId: messageId ?? this.messageId,
      sentiment: sentiment ?? this.sentiment,
      starRating: starRating ?? this.starRating,
      comment: comment ?? this.comment,
      reportedIncorrect: reportedIncorrect ?? this.reportedIncorrect,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
