import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';

class LessonFeedbackAdapter extends TypeAdapter<LessonFeedbackModel> {
  @override
  final int typeId = 44;

  @override
  LessonFeedbackModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return LessonFeedbackModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      targetType: fields[2] as String? ?? 'explanation',
      lessonId: fields[3] as String?,
      messageId: fields[4] as String?,
      sentiment: fields[5] as String? ?? 'none',
      starRating: fields[6] as int? ?? 0,
      comment: fields[7] as String?,
      reportedIncorrect: fields[8] as bool? ?? false,
      createdAt: fields[9] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, LessonFeedbackModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.targetType)
      ..writeByte(3)
      ..write(obj.lessonId)
      ..writeByte(4)
      ..write(obj.messageId)
      ..writeByte(5)
      ..write(obj.sentiment)
      ..writeByte(6)
      ..write(obj.starRating)
      ..writeByte(7)
      ..write(obj.comment)
      ..writeByte(8)
      ..write(obj.reportedIncorrect)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
