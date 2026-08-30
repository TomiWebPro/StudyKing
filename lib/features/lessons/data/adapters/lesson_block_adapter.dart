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
    final rawType = fields[3];
    final LessonBlockType type;
    if (rawType is int) {
      type = LessonBlockType.values[rawType.clamp(0, LessonBlockType.values.length - 1)];
    } else if (rawType is LessonBlockType) {
      type = rawType;
    } else {
      type = LessonBlockType.text;
    }
    final rawSlide = fields[11];
    SlideType? slideType;
    if (rawSlide is int) {
      slideType = SlideType.values[rawSlide.clamp(0, SlideType.values.length - 1)];
    } else if (rawSlide is SlideType) {
      slideType = rawSlide;
    }
    return LessonBlock(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      lessonId: fields[2] as String,
      type: type,
      content: fields[4] as String,
      order: fields[5] as int? ?? 0,
      answerKey: fields[6] as String? ?? '',
      chapterTitle: fields[7] as String?,
      sectionTitle: fields[8] as String?,
      chapterOrder: fields[9] as int?,
      sectionOrder: fields[10] as int?,
      slideType: slideType,
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
      ..write(obj.type.index)
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
      ..write(obj.slideType?.index);
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
