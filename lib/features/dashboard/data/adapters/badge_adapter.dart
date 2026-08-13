import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';

class BadgeModelAdapter extends TypeAdapter<BadgeModel> {
  @override
  final int typeId = 8;

  @override
  BadgeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BadgeModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String,
      iconName: fields[4] as String? ?? 'emoji_events',
      category: fields[5] as String? ?? 'general',
      unlockedAt: fields[6] as DateTime?,
      criteria: (fields[7] as Map?)?.map((k, v) => MapEntry(k as String, v)),
    );
  }

  @override
  void write(BinaryWriter writer, BadgeModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.iconName)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.unlockedAt)
      ..writeByte(7)
      ..write(obj.criteria);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
