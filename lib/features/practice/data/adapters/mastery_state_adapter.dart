import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';

class MasteryStateAdapter extends TypeAdapter<MasteryState> {
  @override
  final int typeId = 16;

  @override
  MasteryState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MasteryState(
      studentId: fields[0] as String,
      topicId: fields[1] as String,
      accuracy: fields[2] as double? ?? 0.0,
      confidenceTrend: fields[3] as double? ?? 0.5,
      speedTrend: fields[4] as double? ?? 0.5,
      forgettingRisk: fields[5] as double? ?? 0.0,
      totalAttempts: fields[6] as int? ?? 0,
      correctAttempts: fields[7] as int? ?? 0,
      averageTimeMs: fields[8] as double? ?? 0.0,
      lastAttempt: fields[9] as DateTime,
      lastUpdated: fields[10] as DateTime,
      currentStreak: fields[11] as int? ?? 0,
      bestStreak: fields[12] as int? ?? 0,
      recentConfidence: (fields[13] as List?)?.cast<int>() ?? [],
      recentAccuracy: (fields[14] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      masteryLevel: MasteryLevel.values[fields[15] as int? ?? 0],
      readinessScore: fields[16] as double? ?? 0.0,
      reviewUrgency: fields[17] as double? ?? 0.0,
      weakSubtopics: (fields[18] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, MasteryState obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.topicId)
      ..writeByte(2)
      ..write(obj.accuracy)
      ..writeByte(3)
      ..write(obj.confidenceTrend)
      ..writeByte(4)
      ..write(obj.speedTrend)
      ..writeByte(5)
      ..write(obj.forgettingRisk)
      ..writeByte(6)
      ..write(obj.totalAttempts)
      ..writeByte(7)
      ..write(obj.correctAttempts)
      ..writeByte(8)
      ..write(obj.averageTimeMs)
      ..writeByte(9)
      ..write(obj.lastAttempt)
      ..writeByte(10)
      ..write(obj.lastUpdated)
      ..writeByte(11)
      ..write(obj.currentStreak)
      ..writeByte(12)
      ..write(obj.bestStreak)
      ..writeByte(13)
      ..write(obj.recentConfidence)
      ..writeByte(14)
      ..write(obj.recentAccuracy)
      ..writeByte(15)
      ..write(obj.masteryLevel.index)
      ..writeByte(16)
      ..write(obj.readinessScore)
      ..writeByte(17)
      ..write(obj.reviewUrgency)
      ..writeByte(18)
      ..write(obj.weakSubtopics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
