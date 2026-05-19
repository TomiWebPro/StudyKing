import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 19)
class PersonalLearningPlan extends HiveObject {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final DateTime generatedAt;

  @HiveField(2)
  final List<DailyPlan> dailyPlans;

  @HiveField(3)
  final PlanSummary summary;

  @HiveField(4)
  final List<PlanRecommendation> recommendations;

  @HiveField(5)
  final int planDurationDays;

  @HiveField(6)
  final double targetMinutesPerDay;

  @HiveField(7)
  final int targetQuestionsPerDay;

  @HiveField(8)
  final Map<String, dynamic>? metadata;

  PersonalLearningPlan({
    required this.studentId,
    required this.generatedAt,
    required this.dailyPlans,
    required this.summary,
    required this.recommendations,
    this.planDurationDays = 7,
    this.targetMinutesPerDay = 30.0,
    this.targetQuestionsPerDay = 15,
    this.metadata,
  });

  PersonalLearningPlan copyWith({
    String? studentId,
    DateTime? generatedAt,
    List<DailyPlan>? dailyPlans,
    PlanSummary? summary,
    List<PlanRecommendation>? recommendations,
    int? planDurationDays,
    double? targetMinutesPerDay,
    int? targetQuestionsPerDay,
    Map<String, dynamic>? metadata,
  }) {
    return PersonalLearningPlan(
      studentId: studentId ?? this.studentId,
      generatedAt: generatedAt ?? this.generatedAt,
      dailyPlans: dailyPlans ?? this.dailyPlans,
      summary: summary ?? this.summary,
      recommendations: recommendations ?? this.recommendations,
      planDurationDays: planDurationDays ?? this.planDurationDays,
      targetMinutesPerDay: targetMinutesPerDay ?? this.targetMinutesPerDay,
      targetQuestionsPerDay: targetQuestionsPerDay ?? this.targetQuestionsPerDay,
      metadata: metadata ?? this.metadata,
    );
  }

  List<SyllabusGoal> get syllabusGoals {
    if (metadata == null || !metadata!.containsKey('syllabus_goals')) return [];
    return (metadata!['syllabus_goals'] as List)
        .map((e) => SyllabusGoal.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, List<DailyPlan>> get subjectPlans {
    if (metadata == null || !metadata!.containsKey('subject_plans')) return {};
    final raw = metadata!['subject_plans'] as Map;
    return raw.map((key, value) => MapEntry(
      key as String,
      (value as List).map((e) => DailyPlan.fromJson(Map<String, dynamic>.from(e))).toList(),
    ));
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'generatedAt': generatedAt.toIso8601String(),
    'dailyPlans': dailyPlans.map((d) => d.toJson()).toList(),
    'summary': summary.toJson(),
    'recommendations': recommendations.map((r) => r.toJson()).toList(),
    'planDurationDays': planDurationDays,
    'targetMinutesPerDay': targetMinutesPerDay,
    'targetQuestionsPerDay': targetQuestionsPerDay,
    'metadata': metadata,
  };

  factory PersonalLearningPlan.fromJson(Map<String, dynamic> json) => PersonalLearningPlan(
    studentId: json['studentId'],
    generatedAt: DateTime.parse(json['generatedAt']),
    dailyPlans: (json['dailyPlans'] as List).map((d) => DailyPlan.fromJson(d)).toList(),
    summary: PlanSummary.fromJson(json['summary']),
    recommendations: (json['recommendations'] as List).map((r) => PlanRecommendation.fromJson(r)).toList(),
    planDurationDays: json['planDurationDays'] ?? 7,
    targetMinutesPerDay: (json['targetMinutesPerDay'] ?? 30.0).toDouble(),
    targetQuestionsPerDay: json['targetQuestionsPerDay'] ?? 15,
    metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
  );
}

class SyllabusGoal {
  final String subjectId;
  final String subjectTitle;
  final String syllabusCode;
  final int targetDays;
  final int targetHoursPerDay;

  const SyllabusGoal({
    required this.subjectId,
    required this.subjectTitle,
    this.syllabusCode = '',
    this.targetDays = 30,
    this.targetHoursPerDay = 1,
  });

  Map<String, dynamic> toJson() => {
    'subjectId': subjectId,
    'subjectTitle': subjectTitle,
    'syllabusCode': syllabusCode,
    'targetDays': targetDays,
    'targetHoursPerDay': targetHoursPerDay,
  };

  factory SyllabusGoal.fromJson(Map<String, dynamic> json) => SyllabusGoal(
    subjectId: json['subjectId'] as String,
    subjectTitle: json['subjectTitle'] as String? ?? '',
    syllabusCode: json['syllabusCode'] as String? ?? '',
    targetDays: json['targetDays'] as int? ?? 30,
    targetHoursPerDay: json['targetHoursPerDay'] as int? ?? 1,
  );
}

@HiveType(typeId: 20)
class DailyPlan extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int dayNumber;

  @HiveField(2)
  final List<PlannedTopic> priorityTopics;

  @HiveField(3)
  final List<String> reviewQuestionIds;

  @HiveField(4)
  final List<String> stretchGoalQuestionIds;

  @HiveField(5)
  final int targetQuestions;

  @HiveField(6)
  final int targetMinutes;

  @HiveField(7)
  final String? focus;

  @HiveField(8)
  final bool isRestDay;

  final bool isCompleted;

  DailyPlan({
    required this.date,
    required this.dayNumber,
    required this.priorityTopics,
    required this.reviewQuestionIds,
    required this.stretchGoalQuestionIds,
    required this.targetQuestions,
    required this.targetMinutes,
    this.focus,
    this.isRestDay = false,
    this.isCompleted = false,
  });

  DailyPlan copyWith({
    DateTime? date,
    int? dayNumber,
    List<PlannedTopic>? priorityTopics,
    List<String>? reviewQuestionIds,
    List<String>? stretchGoalQuestionIds,
    int? targetQuestions,
    int? targetMinutes,
    String? focus,
    bool? isRestDay,
    bool? isCompleted,
  }) {
    return DailyPlan(
      date: date ?? this.date,
      dayNumber: dayNumber ?? this.dayNumber,
      priorityTopics: priorityTopics ?? this.priorityTopics,
      reviewQuestionIds: reviewQuestionIds ?? this.reviewQuestionIds,
      stretchGoalQuestionIds: stretchGoalQuestionIds ?? this.stretchGoalQuestionIds,
      targetQuestions: targetQuestions ?? this.targetQuestions,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      focus: focus ?? this.focus,
      isRestDay: isRestDay ?? this.isRestDay,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'dayNumber': dayNumber,
    'priorityTopics': priorityTopics.map((t) => t.toJson()).toList(),
    'reviewQuestionIds': reviewQuestionIds,
    'stretchGoalQuestionIds': stretchGoalQuestionIds,
    'targetQuestions': targetQuestions,
    'targetMinutes': targetMinutes,
    'focus': focus,
    'isRestDay': isRestDay,
  };

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
    date: DateTime.parse(json['date']),
    dayNumber: json['dayNumber'],
    priorityTopics: (json['priorityTopics'] as List).map((t) => PlannedTopic.fromJson(t)).toList(),
    reviewQuestionIds: List<String>.from(json['reviewQuestionIds'] ?? []),
    stretchGoalQuestionIds: List<String>.from(json['stretchGoalQuestionIds'] ?? []),
    targetQuestions: json['targetQuestions'],
    targetMinutes: json['targetMinutes'],
    focus: json['focus'],
    isRestDay: json['isRestDay'] ?? false,
  );
}

@HiveType(typeId: 21)
class PlannedTopic extends HiveObject {
  @HiveField(0)
  final String topicId;

  @HiveField(1)
  final String topicTitle;

  @HiveField(2)
  final double priority;

  @HiveField(3)
  final String reason;

  @HiveField(4)
  final double readinessScore;

  @HiveField(5)
  final double reviewUrgency;

  @HiveField(6)
  final int estimatedQuestions;

  @HiveField(7)
  final int estimatedMinutes;

  @HiveField(8)
  final List<String> reasons;

  @HiveField(9)
  final String subjectId;

  PlannedTopic({
    required this.topicId,
    required this.topicTitle,
    required this.priority,
    required this.reason,
    required this.readinessScore,
    required this.reviewUrgency,
    required this.estimatedQuestions,
    required this.estimatedMinutes,
    required this.reasons,
    this.subjectId = '',
  });

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'topicTitle': topicTitle,
    'priority': priority,
    'reason': reason,
    'readinessScore': readinessScore,
    'reviewUrgency': reviewUrgency,
    'estimatedQuestions': estimatedQuestions,
    'estimatedMinutes': estimatedMinutes,
    'reasons': reasons,
    'subjectId': subjectId,
  };

  factory PlannedTopic.fromJson(Map<String, dynamic> json) => PlannedTopic(
    topicId: json['topicId'],
    topicTitle: json['topicTitle'],
    priority: (json['priority'] ?? 0.0).toDouble(),
    reason: json['reason'],
    readinessScore: (json['readinessScore'] ?? 0.0).toDouble(),
    reviewUrgency: (json['reviewUrgency'] ?? 0.0).toDouble(),
    estimatedQuestions: json['estimatedQuestions'] ?? 0,
    estimatedMinutes: json['estimatedMinutes'] ?? 0,
    reasons: List<String>.from(json['reasons'] ?? []),
    subjectId: json['subjectId'] ?? '',
  );
}

@HiveType(typeId: 22)
class PlanSummary extends HiveObject {
  @HiveField(0)
  final int totalQuestions;

  @HiveField(1)
  final int totalMinutes;

  @HiveField(2)
  final int newTopics;

  @HiveField(3)
  final int reviewTopics;

  @HiveField(4)
  final double estimatedCoverage;

  @HiveField(5)
  final List<String> focusAreas;

  @HiveField(6)
  final Map<String, dynamic>? workloadDistribution;

  PlanSummary({
    required this.totalQuestions,
    required this.totalMinutes,
    required this.newTopics,
    required this.reviewTopics,
    required this.estimatedCoverage,
    required this.focusAreas,
    this.workloadDistribution,
  });

  Map<String, dynamic> toJson() => {
    'totalQuestions': totalQuestions,
    'totalMinutes': totalMinutes,
    'newTopics': newTopics,
    'reviewTopics': reviewTopics,
    'estimatedCoverage': estimatedCoverage,
    'focusAreas': focusAreas,
    'workloadDistribution': workloadDistribution,
  };

  factory PlanSummary.fromJson(Map<String, dynamic> json) => PlanSummary(
    totalQuestions: json['totalQuestions'],
    totalMinutes: json['totalMinutes'],
    newTopics: json['newTopics'] ?? 0,
    reviewTopics: json['reviewTopics'] ?? 0,
    estimatedCoverage: (json['estimatedCoverage'] ?? 0.0).toDouble(),
    focusAreas: List<String>.from(json['focusAreas'] ?? []),
    workloadDistribution: json['workloadDistribution'] != null
        ? Map<String, dynamic>.from(json['workloadDistribution'])
        : null,
  );
}

@HiveType(typeId: 23)
class PlanRecommendation extends HiveObject {
  @HiveField(0)
  final String topicId;

  @HiveField(1)
  final String reason;

  @HiveField(2)
  final String recommendationType;

  @HiveField(3)
  final double priority;

  @HiveField(4)
  final List<String> explanations;

  @HiveField(5)
  final String? prerequisiteReason;

  @HiveField(6)
  final String? weaknessReason;

  @HiveField(7)
  final String? reviewReason;

  PlanRecommendation({
    required this.topicId,
    required this.reason,
    required this.recommendationType,
    required this.priority,
    required this.explanations,
    this.prerequisiteReason,
    this.weaknessReason,
    this.reviewReason,
  });

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'reason': reason,
    'recommendationType': recommendationType,
    'priority': priority,
    'explanations': explanations,
    'prerequisiteReason': prerequisiteReason,
    'weaknessReason': weaknessReason,
    'reviewReason': reviewReason,
  };

  factory PlanRecommendation.fromJson(Map<String, dynamic> json) => PlanRecommendation(
    topicId: json['topicId'],
    reason: json['reason'],
    recommendationType: json['recommendationType'],
    priority: (json['priority'] ?? 0.0).toDouble(),
    explanations: List<String>.from(json['explanations'] ?? []),
    prerequisiteReason: json['prerequisiteReason'],
    weaknessReason: json['weaknessReason'],
    reviewReason: json['reviewReason'],
  );
}