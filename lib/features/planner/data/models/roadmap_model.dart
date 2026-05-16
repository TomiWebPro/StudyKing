import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 29)
class RoadmapModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String goal;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? targetCompletionDate;

  @HiveField(5)
  final List<MilestoneModel> milestones;

  @HiveField(6)
  final double completionPercentage;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final String? subjectId;

  @HiveField(9)
  final Map<String, double>? plannedVsActual;

  RoadmapModel({
    required this.id,
    required this.studentId,
    required this.goal,
    required this.createdAt,
    this.targetCompletionDate,
    this.milestones = const [],
    this.completionPercentage = 0.0,
    this.status = 'active',
    this.subjectId,
    this.plannedVsActual,
  });

  RoadmapModel copyWith({
    String? id,
    String? studentId,
    String? goal,
    DateTime? createdAt,
    DateTime? targetCompletionDate,
    List<MilestoneModel>? milestones,
    double? completionPercentage,
    String? status,
    String? subjectId,
    Map<String, double>? plannedVsActual,
  }) {
    return RoadmapModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      milestones: milestones ?? this.milestones,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      status: status ?? this.status,
      subjectId: subjectId ?? this.subjectId,
      plannedVsActual: plannedVsActual ?? this.plannedVsActual,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'goal': goal,
    'createdAt': createdAt.toIso8601String(),
    'targetCompletionDate': targetCompletionDate?.toIso8601String(),
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'completionPercentage': completionPercentage,
    'status': status,
    'subjectId': subjectId,
    'plannedVsActual': plannedVsActual,
  };

  factory RoadmapModel.fromJson(Map<String, dynamic> json) => RoadmapModel(
    id: json['id'],
    studentId: json['studentId'],
    goal: json['goal'],
    createdAt: DateTime.parse(json['createdAt']),
    targetCompletionDate: json['targetCompletionDate'] != null
        ? DateTime.parse(json['targetCompletionDate'])
        : null,
    milestones: (json['milestones'] as List?)
            ?.map((m) => MilestoneModel.fromJson(m))
            .toList() ??
        [],
    completionPercentage: (json['completionPercentage'] ?? 0.0).toDouble(),
    status: json['status'] ?? 'active',
    subjectId: json['subjectId'],
    plannedVsActual: json['plannedVsActual'] != null
        ? Map<String, double>.from(json['plannedVsActual'])
        : null,
  );
}

@HiveType(typeId: 25)
class MilestoneModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime deadline;

  @HiveField(4)
  final List<String> topicsCovered;

  @HiveField(5)
  final List<String> assessmentCriteria;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final double progress;

  @HiveField(8)
  final int order;

  MilestoneModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.deadline,
    this.topicsCovered = const [],
    this.assessmentCriteria = const [],
    this.isCompleted = false,
    this.progress = 0.0,
    this.order = 0,
  });

  MilestoneModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    List<String>? topicsCovered,
    List<String>? assessmentCriteria,
    bool? isCompleted,
    double? progress,
    int? order,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      topicsCovered: topicsCovered ?? this.topicsCovered,
      assessmentCriteria: assessmentCriteria ?? this.assessmentCriteria,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'deadline': deadline.toIso8601String(),
    'topicsCovered': topicsCovered,
    'assessmentCriteria': assessmentCriteria,
    'isCompleted': isCompleted,
    'progress': progress,
    'order': order,
  };

  factory MilestoneModel.fromJson(Map<String, dynamic> json) => MilestoneModel(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    deadline: DateTime.parse(json['deadline']),
    topicsCovered: List<String>.from(json['topicsCovered'] ?? []),
    assessmentCriteria: List<String>.from(json['assessmentCriteria'] ?? []),
    isCompleted: json['isCompleted'] ?? false,
    progress: (json['progress'] ?? 0.0).toDouble(),
    order: json['order'] ?? 0,
  );
}
