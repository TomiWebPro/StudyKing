import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';

class PendingActionModelAdapter extends TypeAdapter<PendingActionModel> {
  @override
  final int typeId = 5;

  @override
  PendingActionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingActionModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      actionType: fields[2] as String,
      topicTitle: fields[3] as String? ?? '',
      sessionId: fields[4] as String?,
      payload: (fields[5] as Map?)?.map((k, v) => MapEntry(k as String, v)) ?? {},
      createdAt: fields[6] as DateTime?,
      status: fields[7] as String? ?? 'pending',
    );
  }

  @override
  void write(BinaryWriter writer, PendingActionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.actionType)
      ..writeByte(3)
      ..write(obj.topicTitle)
      ..writeByte(4)
      ..write(obj.sessionId)
      ..writeByte(5)
      ..write(obj.payload)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingActionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
