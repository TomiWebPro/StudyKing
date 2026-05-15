import 'package:hive_flutter/hive_flutter.dart';

part 'student_attempt_model.g.dart';

@HiveType(typeId: 24)
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

  @HiveField(10)
  final DateTime? lastDueDate;

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
    this.lastDueDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'questionId': questionId,
    'subjectId': subjectId,
    'isCorrect': isCorrect,
    'timeSpentMs': timeSpentMs,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
    'userAnswer': userAnswer,
    'markschemeMatch': markschemeMatch,
    'lastDueDate': lastDueDate?.toIso8601String(),
  };

  factory StudentAttempt.fromJson(Map<String, dynamic> json) => StudentAttempt(
    id: json['id'],
    studentId: json['studentId'],
    questionId: json['questionId'],
    subjectId: json['subjectId'],
    isCorrect: json['isCorrect'] ?? false,
    timeSpentMs: json['timeSpentMs'] ?? 0,
    confidence: json['confidence'] ?? 3,
    timestamp: DateTime.parse(json['timestamp']),
    userAnswer: json['userAnswer'] ?? '',
    markschemeMatch: json['markschemeMatch'],
    lastDueDate: json['lastDueDate'] != null ? DateTime.parse(json['lastDueDate']) : null,
  );

  StudentAttempt copyWith({
    String? id,
    String? studentId,
    String? questionId,
    String? subjectId,
    bool? isCorrect,
    int? timeSpentMs,
    int? confidence,
    DateTime? timestamp,
    String? userAnswer,
    String? markschemeMatch,
    DateTime? lastDueDate,
  }) {
    return StudentAttempt(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      questionId: questionId ?? this.questionId,
      subjectId: subjectId ?? this.subjectId,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSpentMs: timeSpentMs ?? this.timeSpentMs,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      userAnswer: userAnswer ?? this.userAnswer,
      markschemeMatch: markschemeMatch ?? this.markschemeMatch,
      lastDueDate: lastDueDate ?? this.lastDueDate,
    );
  }
}
