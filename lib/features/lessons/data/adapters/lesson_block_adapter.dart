import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';

class LessonBlockAdapter extends TypeAdapter<LessonBlock> {
  @override
  final int typeId = 6;

  @override
  LessonBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonBlock(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      lessonId: fields[2] as String,
      type: fields[3] as LessonBlockType,
      content: fields[4] as String,
      order: fields[5] as int? ?? 0,
      answerKey: fields[6] as String? ?? '',
      chapterTitle: fields[7] as String?,
      sectionTitle: fields[8] as String?,
      chapterOrder: fields[9] as int?,
      sectionOrder: fields[10] as int?,
      slideType: fields[11] as SlideType?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonBlock obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.lessonId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.answerKey)
      ..writeByte(7)
      ..write(obj.chapterTitle)
      ..writeByte(8)
      ..write(obj.sectionTitle)
      ..writeByte(9)
      ..write(obj.chapterOrder)
      ..writeByte(10)
      ..write(obj.sectionOrder)
      ..writeByte(11)
      ..write(obj.slideType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
