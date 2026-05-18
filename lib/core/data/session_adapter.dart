import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'hive_type_ids.dart';

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = sessionTypeId;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      studentId: fields[1] as String,
      subjectId: fields[2] as String?,
      topicId: fields[3] as String?,
      type: SessionType.values[fields[4] as int],
      startTime: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
      endTime: fields[6] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[6] as int)
          : null,
      plannedDurationMinutes: fields[7] as int?,
      actualDurationMs: fields[8] as int? ?? 0,
      questionsAnswered: fields[9] as int? ?? 0,
      correctAnswers: fields[10] as int? ?? 0,
      completed: fields[11] as bool? ?? false,
      sourceId: fields[12] as String?,
      sourceIds: fields[13] != null
          ? List<String>.from(fields[13] as List)
          : const [],
      lessonIds: fields[14] != null
          ? List<String>.from(fields[14] as List)
          : const [],
      tags: fields[15] != null
          ? List<String>.from(fields[15] as List)
          : const [],
      createdAt: fields[16] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[16] as int)
          : DateTime.now(),
      tutorMetadata: fields[17] != null
          ? _readTutorMetadata(fields[17] as Map)
          : null,
    );
  }

  TutorMetadata _readTutorMetadata(Map fields) {
    return TutorMetadata(
      topicTitle: fields[0] as String?,
      lessonPlanJson: fields[1] as String?,
      confidenceRating: fields[2] as int? ?? 0,
      tutorNotes: fields[3] as String?,
      topicsCovered: fields[4] != null
          ? List<String>.from(fields[4] as List)
          : const [],
      totalMessages: fields[5] as int? ?? 0,
      totalTokensUsed: fields[6] as int? ?? 0,
    );
  }

  Map _writeTutorMetadata(TutorMetadata meta) {
    return {
      0: meta.topicTitle,
      1: meta.lessonPlanJson,
      2: meta.confidenceRating,
      3: meta.tutorNotes,
      4: meta.topicsCovered,
      5: meta.totalMessages,
      6: meta.totalTokensUsed,
    };
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer.writeByte(18);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.studentId);
    writer.writeByte(2);
    writer.write(obj.subjectId);
    writer.writeByte(3);
    writer.write(obj.topicId);
    writer.writeByte(4);
    writer.write(obj.type.index);
    writer.writeByte(5);
    writer.write(obj.startTime.millisecondsSinceEpoch);
    writer.writeByte(6);
    writer.write(obj.endTime?.millisecondsSinceEpoch);
    writer.writeByte(7);
    writer.write(obj.plannedDurationMinutes);
    writer.writeByte(8);
    writer.write(obj.actualDurationMs);
    writer.writeByte(9);
    writer.write(obj.questionsAnswered);
    writer.writeByte(10);
    writer.write(obj.correctAnswers);
    writer.writeByte(11);
    writer.write(obj.completed);
    writer.writeByte(12);
    writer.write(obj.sourceId);
    writer.writeByte(13);
    writer.write(obj.sourceIds);
    writer.writeByte(14);
    writer.write(obj.lessonIds);
    writer.writeByte(15);
    writer.write(obj.tags);
    writer.writeByte(16);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    writer.writeByte(17);
    writer.write(obj.tutorMetadata != null
        ? _writeTutorMetadata(obj.tutorMetadata!)
        : null);
  }
}