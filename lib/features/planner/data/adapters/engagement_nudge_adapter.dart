import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';

class EngagementNudgeModelAdapter extends TypeAdapter<EngagementNudgeModel> {
  @override
  final int typeId = 32;

  @override
  EngagementNudgeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EngagementNudgeModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      nudgeType: fields[2] as String,
      message: fields[3] as String,
      severity: fields[4] as String? ?? 'medium',
      topicId: fields[5] as String?,
      sentAt: fields[6] as DateTime,
      wasActedUpon: fields[7] as bool? ?? false,
      actedUponAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EngagementNudgeModel obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.studentId);
    writer.writeByte(2);
    writer.write(obj.nudgeType);
    writer.writeByte(3);
    writer.write(obj.message);
    writer.writeByte(4);
    writer.write(obj.severity);
    writer.writeByte(5);
    writer.write(obj.topicId);
    writer.writeByte(6);
    writer.write(obj.sentAt);
    writer.writeByte(7);
    writer.write(obj.wasActedUpon);
    writer.writeByte(8);
    writer.write(obj.actedUponAt);
  }
}
