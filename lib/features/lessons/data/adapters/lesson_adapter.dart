import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';

class LessonAdapter extends TypeAdapter<Lesson> {
  @override
  final int typeId = 7;

  @override
  Lesson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final rawGen = fields[6];
    final GeneratedBy gen;
    if (rawGen is int) {
      gen = GeneratedBy.values[rawGen.clamp(0, GeneratedBy.values.length - 1)];
    } else if (rawGen is GeneratedBy) {
      gen = rawGen;
    } else {
      gen = GeneratedBy.manual;
    }
    return Lesson(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      title: fields[2] as String,
      topicId: fields[3] as String,
      blocks: (fields[4] as List?)?.cast<LessonBlock>() ?? [],
      difficulty: fields[5] as int? ?? 1,
      generatedBy: gen,
      createdAt: fields[7] as DateTime,
      markscheme: fields[8] as String?,
      sessionId: fields[9] as String?,
      validationStatus: _parseValidationStatus(fields[10]),
    );
  }

  static ValidationStatus _parseValidationStatus(dynamic raw) {
    if (raw is int && raw >= 0 && raw < ValidationStatus.values.length) {
      return ValidationStatus.values[raw];
    }
    // Fall back to pending for legacy data written before the field existed,
    // so older AI-generated lessons are flagged for review rather than
    // silently trusted (vision_next_term.md §4.3).
    return ValidationStatus.pending;
  }

  @override
  void write(BinaryWriter writer, Lesson obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.topicId)
      ..writeByte(4)
      ..write(obj.blocks)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.generatedBy.index)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.markscheme)
      ..writeByte(9)
      ..write(obj.sessionId);
    writer
      ..writeByte(10)
      ..write(obj.validationStatus.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
