import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 32)
class EngagementNudgeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String nudgeType;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final String severity;

  @HiveField(5)
  final String? topicId;

  @HiveField(6)
  final DateTime sentAt;

  @HiveField(7)
  final bool wasActedUpon;

  @HiveField(8)
  final DateTime? actedUponAt;

  EngagementNudgeModel({
    required this.id,
    required this.studentId,
    required this.nudgeType,
    required this.message,
    this.severity = 'medium',
    this.topicId,
    DateTime? sentAt,
    this.wasActedUpon = false,
    this.actedUponAt,
  }) : sentAt = sentAt ?? DateTime.now();

  EngagementNudgeModel copyWith({
    String? id,
    String? studentId,
    String? nudgeType,
    String? message,
    String? severity,
    String? topicId,
    DateTime? sentAt,
    bool? wasActedUpon,
    DateTime? actedUponAt,
  }) {
    return EngagementNudgeModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      nudgeType: nudgeType ?? this.nudgeType,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      topicId: topicId ?? this.topicId,
      sentAt: sentAt ?? this.sentAt,
      wasActedUpon: wasActedUpon ?? this.wasActedUpon,
      actedUponAt: actedUponAt ?? this.actedUponAt,
    );
  }
}

enum NudgeType { overwork, revision, planAdjustment, lessonReminder }

enum NudgeSeverity { low, medium, high }
