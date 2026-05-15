import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 33)
class PlanAdherenceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int plannedQuestions;

  @HiveField(4)
  final int actualQuestions;

  @HiveField(5)
  final int plannedMinutes;

  @HiveField(6)
  final int actualMinutes;

  @HiveField(7)
  final double adherenceScore;

  @HiveField(8)
  final String? planId;

  @HiveField(9)
  final Map<String, dynamic>? metadata;

  PlanAdherenceModel({
    required this.id,
    required this.studentId,
    required this.date,
    this.plannedQuestions = 0,
    this.actualQuestions = 0,
    this.plannedMinutes = 0,
    this.actualMinutes = 0,
    this.adherenceScore = 0.0,
    this.planId,
    this.metadata,
  });

  PlanAdherenceModel copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    int? plannedQuestions,
    int? actualQuestions,
    int? plannedMinutes,
    int? actualMinutes,
    double? adherenceScore,
    String? planId,
    Map<String, dynamic>? metadata,
  }) {
    return PlanAdherenceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      plannedQuestions: plannedQuestions ?? this.plannedQuestions,
      actualQuestions: actualQuestions ?? this.actualQuestions,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      adherenceScore: adherenceScore ?? this.adherenceScore,
      planId: planId ?? this.planId,
      metadata: metadata ?? this.metadata,
    );
  }
}
