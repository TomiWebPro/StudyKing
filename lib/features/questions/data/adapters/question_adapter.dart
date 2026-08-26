import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 2;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      text: fields[1] as String,
      type: fields[2] as QuestionType,
      difficulty: fields[3] as int? ?? 1,
      subjectId: fields[4] as String,
      topicId: fields[5] as String,
      variantIds: (fields[6] as List?)?.cast<String>() ?? [],
      sourceIds: (fields[7] as List?)?.cast<String>() ?? [],
      options: (fields[8] as List?)?.cast<String>() ?? [],
      allowedAnswerTypes: fields[9] as String? ?? '',
      markscheme: fields[10],
      model: fields[11] as String?,
      topic: fields[12] as String?,
      tags: (fields[13] as List?)?.cast<String>() ?? [],
      explanation: fields[14] as String?,
      difficultyText: fields[15] as String?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      nextReview: fields[18] as DateTime?,
      variantGroupId: fields[19] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.subjectId)
      ..writeByte(5)
      ..write(obj.topicId)
      ..writeByte(6)
      ..write(obj.variantIds)
      ..writeByte(7)
      ..write(obj.sourceIds)
      ..writeByte(8)
      ..write(obj.options)
      ..writeByte(9)
      ..write(obj.allowedAnswerTypes)
      ..writeByte(10)
      ..write(obj.markscheme)
      ..writeByte(11)
      ..write(obj.model)
      ..writeByte(12)
      ..write(obj.topic)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.explanation)
      ..writeByte(15)
      ..write(obj.difficultyText)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.nextReview)
      ..writeByte(19)
      ..write(obj.variantGroupId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
