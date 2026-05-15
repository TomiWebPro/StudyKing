import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';

class PersonalLearningPlanAdapter extends TypeAdapter<PersonalLearningPlan> {
  @override
  final int typeId = 19;

  @override
  PersonalLearningPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonalLearningPlan(
      studentId: fields[0] as String,
      generatedAt: fields[1] as DateTime,
      dailyPlans: (fields[2] as List).cast<DailyPlan>(),
      summary: fields[3] as PlanSummary,
      recommendations: (fields[4] as List).cast<PlanRecommendation>(),
      planDurationDays: fields[5] as int? ?? 7,
      targetMinutesPerDay: fields[6] as double? ?? 30.0,
      targetQuestionsPerDay: fields[7] as int? ?? 15,
      metadata: fields[8] != null ? Map<String, dynamic>.from(fields[8] as Map) : null,
    );
  }

  @override
  void write(BinaryWriter writer, PersonalLearningPlan obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.generatedAt)
      ..writeByte(2)
      ..write(obj.dailyPlans)
      ..writeByte(3)
      ..write(obj.summary)
      ..writeByte(4)
      ..write(obj.recommendations)
      ..writeByte(5)
      ..write(obj.planDurationDays)
      ..writeByte(6)
      ..write(obj.targetMinutesPerDay)
      ..writeByte(7)
      ..write(obj.targetQuestionsPerDay)
      ..writeByte(8)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalLearningPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyPlanAdapter extends TypeAdapter<DailyPlan> {
  @override
  final int typeId = 20;

  @override
  DailyPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyPlan(
      date: fields[0] as DateTime,
      dayNumber: fields[1] as int,
      priorityTopics: (fields[2] as List).cast<PlannedTopic>(),
      reviewQuestionIds: (fields[3] as List).cast<String>(),
      stretchGoalQuestionIds: (fields[4] as List).cast<String>(),
      targetQuestions: fields[5] as int,
      targetMinutes: fields[6] as int,
      focus: fields[7] as String?,
      isRestDay: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DailyPlan obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.dayNumber)
      ..writeByte(2)
      ..write(obj.priorityTopics)
      ..writeByte(3)
      ..write(obj.reviewQuestionIds)
      ..writeByte(4)
      ..write(obj.stretchGoalQuestionIds)
      ..writeByte(5)
      ..write(obj.targetQuestions)
      ..writeByte(6)
      ..write(obj.targetMinutes)
      ..writeByte(7)
      ..write(obj.focus)
      ..writeByte(8)
      ..write(obj.isRestDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlannedTopicAdapter extends TypeAdapter<PlannedTopic> {
  @override
  final int typeId = 21;

  @override
  PlannedTopic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlannedTopic(
      topicId: fields[0] as String,
      topicTitle: fields[1] as String,
      priority: fields[2] as double,
      reason: fields[3] as String,
      readinessScore: fields[4] as double,
      reviewUrgency: fields[5] as double,
      estimatedQuestions: fields[6] as int,
      estimatedMinutes: fields[7] as int,
      reasons: (fields[8] as List).cast<String>(),
      subjectId: fields[9] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, PlannedTopic obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.topicId)
      ..writeByte(1)
      ..write(obj.topicTitle)
      ..writeByte(2)
      ..write(obj.priority)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.readinessScore)
      ..writeByte(5)
      ..write(obj.reviewUrgency)
      ..writeByte(6)
      ..write(obj.estimatedQuestions)
      ..writeByte(7)
      ..write(obj.estimatedMinutes)
      ..writeByte(8)
      ..write(obj.reasons)
      ..writeByte(9)
      ..write(obj.subjectId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannedTopicAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlanSummaryAdapter extends TypeAdapter<PlanSummary> {
  @override
  final int typeId = 22;

  @override
  PlanSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanSummary(
      totalQuestions: fields[0] as int,
      totalMinutes: fields[1] as int,
      newTopics: fields[2] as int? ?? 0,
      reviewTopics: fields[3] as int? ?? 0,
      estimatedCoverage: fields[4] as double,
      focusAreas: (fields[5] as List).cast<String>(),
      workloadDistribution: fields[6] != null ? Map<String, dynamic>.from(fields[6] as Map) : null,
    );
  }

  @override
  void write(BinaryWriter writer, PlanSummary obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.totalQuestions)
      ..writeByte(1)
      ..write(obj.totalMinutes)
      ..writeByte(2)
      ..write(obj.newTopics)
      ..writeByte(3)
      ..write(obj.reviewTopics)
      ..writeByte(4)
      ..write(obj.estimatedCoverage)
      ..writeByte(5)
      ..write(obj.focusAreas)
      ..writeByte(6)
      ..write(obj.workloadDistribution);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlanRecommendationAdapter extends TypeAdapter<PlanRecommendation> {
  @override
  final int typeId = 23;

  @override
  PlanRecommendation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanRecommendation(
      topicId: fields[0] as String,
      reason: fields[1] as String,
      recommendationType: fields[2] as String,
      priority: fields[3] as double,
      explanations: (fields[4] as List).cast<String>(),
      prerequisiteReason: fields[5] as String?,
      weaknessReason: fields[6] as String?,
      reviewReason: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlanRecommendation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.topicId)
      ..writeByte(1)
      ..write(obj.reason)
      ..writeByte(2)
      ..write(obj.recommendationType)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.explanations)
      ..writeByte(5)
      ..write(obj.prerequisiteReason)
      ..writeByte(6)
      ..write(obj.weaknessReason)
      ..writeByte(7)
      ..write(obj.reviewReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanRecommendationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
