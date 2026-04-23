import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 5)
class StudentAttempt extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String questionId;

  @HiveField(3)
  final String subjectId;

  @HiveField(4, defaultValue: false)
  final bool isCorrect;

  @HiveField(5, defaultValue: 0)
  final int timeSpentMs;

  @HiveField(6, defaultValue: 3)
  final int confidence;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8, defaultValue: '')
  final String userAnswer;

  @HiveField(9)
  final String? markschemeMatch;

  StudentAttempt({
    required this.id,
    required this.studentId,
    required this.questionId,
    required this.subjectId,
    this.isCorrect = false,
    this.timeSpentMs = 0,
    this.confidence = 3,
    required this.timestamp,
    this.userAnswer = '',
    this.markschemeMatch,
  });
}
