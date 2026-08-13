import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/subject_model.dart';

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 11;

  @override
  Subject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subject(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      syllabus: fields[3] as String?,
      code: fields[4] as String?,
      teacher: fields[5] as String?,
      topicIds: (fields[6] as List?)?.cast<String>() ?? [],
      color: fields[7] as String? ?? '#2196F3',
      createdAt: fields[8] as DateTime? ?? DateTime.now(),
      examDate: fields[9] as DateTime?,
      iconName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.syllabus)
      ..writeByte(4)
      ..write(obj.code)
      ..writeByte(5)
      ..write(obj.teacher)
      ..writeByte(6)
      ..write(obj.topicIds)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.examDate)
      ..writeByte(10)
      ..write(obj.iconName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
