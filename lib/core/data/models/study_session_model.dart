import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 8)
class StudySession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String subjectId;

  @HiveField(3)
  final String lessonId;

  @HiveField(4)
  final DateTime startTime;

  @HiveField(5)
  final DateTime? endTime;

  @HiveField(7, defaultValue: 0)
  int questionsAnswered;

  @HiveField(8, defaultValue: 0)
  int correctAnswers;

  @HiveField(9, defaultValue: 0)
  int timeSpentMs;

  StudySession({
    required this.id,
    required this.studentId,
    required this.subjectId,
    this.lessonId = '',
    required this.startTime,
    this.endTime,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.timeSpentMs = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'subjectId': subjectId,
    'lessonId': lessonId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
    'timeSpentMs': timeSpentMs,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'],
    studentId: json['studentId'],
    subjectId: json['subjectId'],
    lessonId: json['lessonId'] ?? '',
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    questionsAnswered: json['questionsAnswered'] ?? 0,
    correctAnswers: json['correctAnswers'] ?? 0,
    timeSpentMs: json['timeSpentMs'] ?? 0,
  );

  StudySession copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? lessonId,
    DateTime? startTime,
    DateTime? endTime,
    int? questionsAnswered,
    int? correctAnswers,
    int? timeSpentMs,
  }) {
    return StudySession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      lessonId: lessonId ?? this.lessonId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      timeSpentMs: timeSpentMs ?? this.timeSpentMs,
    );
  }
}
