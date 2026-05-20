import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/mastery_improvement_metric_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

class MasteryImprovementMetricAdapter extends TypeAdapter<MasteryImprovementMetric> {
  @override
  final int typeId = 31;

  @override
  MasteryImprovementMetric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MasteryImprovementMetric(
      date: fields[0] as DateTime,
      studentId: fields[1] as String,
      topicId: fields[2] as String,
      previousAccuracy: fields[3] as double,
      currentAccuracy: fields[4] as double,
      accuracyDelta: fields[5] as double,
      previousMasteryLevel: fields[6] as double,
      currentMasteryLevel: fields[7] as double,
      previousLevel: MasteryLevel.values[fields[8] as int],
      currentLevel: MasteryLevel.values[fields[9] as int],
      metadata: fields[10] != null ? Map<String, dynamic>.from(fields[10] as Map) : null,
    );
  }

  @override
  void write(BinaryWriter writer, MasteryImprovementMetric obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.date);
    writer.writeByte(1);
    writer.write(obj.studentId);
    writer.writeByte(2);
    writer.write(obj.topicId);
    writer.writeByte(3);
    writer.write(obj.previousAccuracy);
    writer.writeByte(4);
    writer.write(obj.currentAccuracy);
    writer.writeByte(5);
    writer.write(obj.accuracyDelta);
    writer.writeByte(6);
    writer.write(obj.previousMasteryLevel);
    writer.writeByte(7);
    writer.write(obj.currentMasteryLevel);
    writer.writeByte(8);
    writer.write(obj.previousLevel.index);
    writer.writeByte(9);
    writer.write(obj.currentLevel.index);
    writer.writeByte(10);
    writer.write(obj.metadata);
  }
}
