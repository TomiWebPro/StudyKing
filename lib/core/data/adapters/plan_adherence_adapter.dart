import 'package:hive_flutter/hive_flutter.dart';
import '../../services/instrumentation_service.dart';

class PlanAdherenceMetricAdapter extends TypeAdapter<PlanAdherenceMetric> {
  @override
  final int typeId = 30;

  @override
  PlanAdherenceMetric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanAdherenceMetric(
      date: fields[0] as DateTime,
      studentId: fields[1] as String,
      plannedQuestions: fields[2] as int,
      actualQuestions: fields[3] as int,
      plannedMinutes: fields[4] as int,
      actualMinutes: fields[5] as int,
      adherenceScore: fields[6] as double,
      metadata: fields[7] as Map<String, dynamic>?,
    );
  }

  @override
  void write(BinaryWriter writer, PlanAdherenceMetric obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.date);
    writer.writeByte(1);
    writer.write(obj.studentId);
    writer.writeByte(2);
    writer.write(obj.plannedQuestions);
    writer.writeByte(3);
    writer.write(obj.actualQuestions);
    writer.writeByte(4);
    writer.write(obj.plannedMinutes);
    writer.writeByte(5);
    writer.write(obj.actualMinutes);
    writer.writeByte(6);
    writer.write(obj.adherenceScore);
    writer.writeByte(7);
    writer.write(obj.metadata);
  }
}
