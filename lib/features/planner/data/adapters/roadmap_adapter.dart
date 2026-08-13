import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

class RoadmapModelAdapter extends TypeAdapter<RoadmapModel> {
  @override
  final int typeId = 29;

  @override
  RoadmapModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoadmapModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      goal: fields[2] as String,
      createdAt: fields[3] as DateTime,
      targetCompletionDate: fields[4] as DateTime?,
      milestones: (fields[5] as List?)?.cast<MilestoneModel>() ?? [],
      completionPercentage: (fields[6] as num?)?.toDouble() ?? 0.0,
      status: fields[7] as String? ?? 'active',
      subjectId: fields[8] as String?,
      plannedVsActual: (fields[9] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toDouble())),
    );
  }

  @override
  void write(BinaryWriter writer, RoadmapModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.goal)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.targetCompletionDate)
      ..writeByte(5)
      ..write(obj.milestones)
      ..writeByte(6)
      ..write(obj.completionPercentage)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.subjectId)
      ..writeByte(9)
      ..write(obj.plannedVsActual);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoadmapModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
