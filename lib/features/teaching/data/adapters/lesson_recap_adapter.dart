import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/teaching/data/models/lesson_recap_model.dart';

class LessonRecapAdapter extends TypeAdapter<LessonRecapModel> {
  @override
  final int typeId = 30;

  @override
  LessonRecapModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return LessonRecapModel(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      lessonId: fields[2] as String?,
      studentId: fields[3] as String,
      subjectId: fields[4] as String,
      topicId: fields[5] as String,
      topicTitle: fields[6] as String,
      topicsCovered: (fields[7] as List?)?.cast<String>() ?? [],
      struggles: (fields[8] as List?)?.cast<String>() ?? [],
      homework: (fields[9] as List?)?.cast<String>() ?? [],
      summary: fields[10] as String? ?? '',
      accuracy: (fields[11] as num?)?.toDouble() ?? 0.0,
      questionCount: fields[12] as int? ?? 0,
      correctCount: fields[13] as int? ?? 0,
      confidenceRating: fields[14] as int? ?? 0,
      participationMessages: fields[15] as int? ?? 0,
      generatedAt: fields[16] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[16] as int)
          : DateTime.now(),
      providerName: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonRecapModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.lessonId)
      ..writeByte(3)
      ..write(obj.studentId)
      ..writeByte(4)
      ..write(obj.subjectId)
      ..writeByte(5)
      ..write(obj.topicId)
      ..writeByte(6)
      ..write(obj.topicTitle)
      ..writeByte(7)
      ..write(obj.topicsCovered)
      ..writeByte(8)
      ..write(obj.struggles)
      ..writeByte(9)
      ..write(obj.homework)
      ..writeByte(10)
      ..write(obj.summary)
      ..writeByte(11)
      ..write(obj.accuracy)
      ..writeByte(12)
      ..write(obj.questionCount)
      ..writeByte(13)
      ..write(obj.correctCount)
      ..writeByte(14)
      ..write(obj.confidenceRating)
      ..writeByte(15)
      ..write(obj.participationMessages)
      ..writeByte(16)
      ..write(obj.generatedAt.millisecondsSinceEpoch)
      ..writeByte(17)
      ..write(obj.providerName);
  }
}
