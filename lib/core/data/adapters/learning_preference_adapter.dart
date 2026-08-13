import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/learning_preference_model.dart';

class LearningPreferenceAdapter extends TypeAdapter<LearningPreference> {
  @override
  final int typeId = 43;

  @override
  LearningPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearningPreference(
      studentId: fields[0] as String,
      preferredBlockType: fields[1] as String? ?? 'exercise',
      optimalSessionDurationMinutes:
          (fields[2] as num?)?.toInt() ?? 25,
      prefersVisualExplanations: fields[3] as bool? ?? false,
      prefersStepByStep: fields[4] as bool? ?? true,
      spacedRepetitionEffectiveness:
          (fields[5] as num?)?.toDouble() ?? 0.0,
      methodEffectivenessScores:
          (fields[6] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
              {},
      lastUpdated: fields[7] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, LearningPreference obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.preferredBlockType)
      ..writeByte(2)
      ..write(obj.optimalSessionDurationMinutes)
      ..writeByte(3)
      ..write(obj.prefersVisualExplanations)
      ..writeByte(4)
      ..write(obj.prefersStepByStep)
      ..writeByte(5)
      ..write(obj.spacedRepetitionEffectiveness)
      ..writeByte(6)
      ..write(obj.methodEffectivenessScores)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
