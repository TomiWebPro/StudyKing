import 'package:hive_flutter/hive_flutter.dart';

enum SessionStatus { planned, inProgress, completed, cancelled }

@HiveType(typeId: 28)
class TutorSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String subjectId;

  @HiveField(3)
  final String topicId;

  @HiveField(4)
  final String topicTitle;

  @HiveField(5)
  final SessionStatus status;

  @HiveField(6)
  final DateTime startTime;

  @HiveField(7)
  final DateTime? endTime;

  @HiveField(8)
  final int plannedDurationMinutes;

  @HiveField(9)
  final String lessonPlanJson;

  @HiveField(10)
  final int questionsAsked;

  @HiveField(11)
  final int questionsCorrect;

  @HiveField(12)
  final int confidenceRating;

  @HiveField(13)
  final String? tutorNotes;

  @HiveField(14)
  final List<String> topicsCovered;

  @HiveField(15)
  final int totalMessages;

  @HiveField(16)
  final int totalTokensUsed;

  TutorSession({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.topicId,
    required this.topicTitle,
    this.status = SessionStatus.planned,
    required this.startTime,
    this.endTime,
    this.plannedDurationMinutes = 45,
    this.lessonPlanJson = '{}',
    this.questionsAsked = 0,
    this.questionsCorrect = 0,
    this.confidenceRating = 0,
    this.tutorNotes,
    this.topicsCovered = const [],
    this.totalMessages = 0,
    this.totalTokensUsed = 0,
  });

  double get accuracy =>
      questionsAsked > 0 ? questionsCorrect / questionsAsked : 0.0;

  int get elapsedMinutes =>
      DateTime.now().difference(startTime).inMinutes;

  int get remainingMinutes =>
      (plannedDurationMinutes - elapsedMinutes).clamp(0, plannedDurationMinutes);

  bool get isOverTime => elapsedMinutes > plannedDurationMinutes;

  TutorSession copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? topicId,
    String? topicTitle,
    SessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? plannedDurationMinutes,
    String? lessonPlanJson,
    int? questionsAsked,
    int? questionsCorrect,
    int? confidenceRating,
    String? tutorNotes,
    List<String>? topicsCovered,
    int? totalMessages,
    int? totalTokensUsed,
  }) {
    return TutorSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      lessonPlanJson: lessonPlanJson ?? this.lessonPlanJson,
      questionsAsked: questionsAsked ?? this.questionsAsked,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      confidenceRating: confidenceRating ?? this.confidenceRating,
      tutorNotes: tutorNotes ?? this.tutorNotes,
      topicsCovered: topicsCovered ?? this.topicsCovered,
      totalMessages: totalMessages ?? this.totalMessages,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'subjectId': subjectId,
    'topicId': topicId,
    'topicTitle': topicTitle,
    'status': status.name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'plannedDurationMinutes': plannedDurationMinutes,
    'lessonPlanJson': lessonPlanJson,
    'questionsAsked': questionsAsked,
    'questionsCorrect': questionsCorrect,
    'confidenceRating': confidenceRating,
    'tutorNotes': tutorNotes,
    'topicsCovered': topicsCovered,
    'totalMessages': totalMessages,
    'totalTokensUsed': totalTokensUsed,
  };

  factory TutorSession.fromJson(Map<String, dynamic> json) => TutorSession(
    id: json['id'],
    studentId: json['studentId'],
    subjectId: json['subjectId'],
    topicId: json['topicId'],
    topicTitle: json['topicTitle'],
    status: SessionStatus.values.firstWhere((s) => s.name == json['status']),
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    plannedDurationMinutes: json['plannedDurationMinutes'] ?? 45,
    lessonPlanJson: json['lessonPlanJson'] ?? '{}',
    questionsAsked: json['questionsAsked'] ?? 0,
    questionsCorrect: json['questionsCorrect'] ?? 0,
    confidenceRating: json['confidenceRating'] ?? 0,
    tutorNotes: json['tutorNotes'],
    topicsCovered: List<String>.from(json['topicsCovered'] ?? []),
    totalMessages: json['totalMessages'] ?? 0,
    totalTokensUsed: json['totalTokensUsed'] ?? 0,
  );
}
