import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';

class MilestoneModelAdapter extends TypeAdapter<MilestoneModel> {
  @override
  final int typeId = 25;

  @override
  MilestoneModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MilestoneModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      deadline: fields[3] as DateTime,
      topicsCovered: (fields[4] as List?)?.cast<String>() ?? [],
      assessmentCriteria: (fields[5] as List?)?.cast<String>() ?? [],
      isCompleted: fields[6] as bool? ?? false,
      progress: (fields[7] as num?)?.toDouble() ?? 0.0,
      order: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, MilestoneModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.deadline)
      ..writeByte(4)
      ..write(obj.topicsCovered)
      ..writeByte(5)
      ..write(obj.assessmentCriteria)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
