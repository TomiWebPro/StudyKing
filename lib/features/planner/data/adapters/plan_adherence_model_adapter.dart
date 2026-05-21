import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';

class PlanAdherenceModelAdapter extends TypeAdapter<PlanAdherenceModel> {
  @override
  final int typeId = 33;

  @override
  PlanAdherenceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanAdherenceModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      date: fields[2] as DateTime,
      plannedQuestions: fields[3] as int,
      actualQuestions: fields[4] as int,
      plannedMinutes: fields[5] as int,
      actualMinutes: fields[6] as int,
      adherenceScore: fields[7] as double,
      planId: fields[8] as String?,
      metadata: fields[9] != null ? Map<String, dynamic>.from(fields[9]) : null,
    );
  }

  @override
  void write(BinaryWriter writer, PlanAdherenceModel obj) {
    writer.writeByte(10);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.studentId);
    writer.writeByte(2);
    writer.write(obj.date);
    writer.writeByte(3);
    writer.write(obj.plannedQuestions);
    writer.writeByte(4);
    writer.write(obj.actualQuestions);
    writer.writeByte(5);
    writer.write(obj.plannedMinutes);
    writer.writeByte(6);
    writer.write(obj.actualMinutes);
    writer.writeByte(7);
    writer.write(obj.adherenceScore);
    writer.writeByte(8);
    writer.write(obj.planId);
    writer.writeByte(9);
    writer.write(obj.metadata);
  }
}
