import 'package:hive_flutter/hive_flutter.dart';

/// Structured end-of-lesson recap ("how the class went").
///
/// Produced from the conversation transcript and attempt data at lesson end and
/// persisted so it can be surfaced from lesson history / detail screens.
@HiveType(typeId: 30)
class LessonRecapModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId;

  @HiveField(2)
  final String? lessonId;

  @HiveField(3)
  final String studentId;

  @HiveField(4)
  final String subjectId;

  @HiveField(5)
  final String topicId;

  @HiveField(6)
  final String topicTitle;

  @HiveField(7)
  final List<String> topicsCovered;

  @HiveField(8)
  final List<String> struggles;

  @HiveField(9)
  final List<String> homework;

  @HiveField(10)
  final String summary;

  @HiveField(11)
  final double accuracy;

  @HiveField(12)
  final int questionCount;

  @HiveField(13)
  final int correctCount;

  @HiveField(14)
  final int confidenceRating;

  @HiveField(15)
  final int participationMessages;

  @HiveField(16)
  final DateTime generatedAt;

  @HiveField(17)
  final String? providerName;

  LessonRecapModel({
    required this.id,
    required this.sessionId,
    this.lessonId,
    required this.studentId,
    required this.subjectId,
    required this.topicId,
    required this.topicTitle,
    this.topicsCovered = const [],
    this.struggles = const [],
    this.homework = const [],
    this.summary = '',
    this.accuracy = 0.0,
    this.questionCount = 0,
    this.correctCount = 0,
    this.confidenceRating = 0,
    this.participationMessages = 0,
    required this.generatedAt,
    this.providerName,
  });

  double get accuracyPercent => (accuracy * 100).clamp(0, 100);

  LessonRecapModel copyWith({
    String? id,
    String? sessionId,
    String? lessonId,
    bool clearLessonId = false,
    String? studentId,
    String? subjectId,
    String? topicId,
    String? topicTitle,
    List<String>? topicsCovered,
    List<String>? struggles,
    List<String>? homework,
    String? summary,
    double? accuracy,
    int? questionCount,
    int? correctCount,
    int? confidenceRating,
    int? participationMessages,
    DateTime? generatedAt,
    String? providerName,
    bool clearProviderName = false,
  }) {
    return LessonRecapModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      lessonId: clearLessonId ? null : (lessonId ?? this.lessonId),
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      topicsCovered: topicsCovered ?? this.topicsCovered,
      struggles: struggles ?? this.struggles,
      homework: homework ?? this.homework,
      summary: summary ?? this.summary,
      accuracy: accuracy ?? this.accuracy,
      questionCount: questionCount ?? this.questionCount,
      correctCount: correctCount ?? this.correctCount,
      confidenceRating: confidenceRating ?? this.confidenceRating,
      participationMessages: participationMessages ?? this.participationMessages,
      generatedAt: generatedAt ?? this.generatedAt,
      providerName:
          clearProviderName ? null : (providerName ?? this.providerName),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'lessonId': lessonId,
        'studentId': studentId,
        'subjectId': subjectId,
        'topicId': topicId,
        'topicTitle': topicTitle,
        'topicsCovered': topicsCovered,
        'struggles': struggles,
        'homework': homework,
        'summary': summary,
        'accuracy': accuracy,
        'questionCount': questionCount,
        'correctCount': correctCount,
        'confidenceRating': confidenceRating,
        'participationMessages': participationMessages,
        'generatedAt': generatedAt.toIso8601String(),
        'providerName': providerName,
      };

  factory LessonRecapModel.fromJson(Map<String, dynamic> json) => LessonRecapModel(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        lessonId: json['lessonId'] as String?,
        studentId: json['studentId'] as String,
        subjectId: json['subjectId'] as String,
        topicId: json['topicId'] as String,
        topicTitle: json['topicTitle'] as String,
        topicsCovered: List<String>.from(json['topicsCovered'] ?? []),
        struggles: List<String>.from(json['struggles'] ?? []),
        homework: List<String>.from(json['homework'] ?? []),
        summary: json['summary'] as String? ?? '',
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        questionCount: json['questionCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        confidenceRating: json['confidenceRating'] as int? ?? 0,
        participationMessages: json['participationMessages'] as int? ?? 0,
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : DateTime.now(),
        providerName: json['providerName'] as String?,
      );
}
