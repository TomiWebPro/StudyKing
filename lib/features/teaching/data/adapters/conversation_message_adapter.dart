import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';

class ConversationMessageAdapter extends TypeAdapter<ConversationMessage> {
  @override
  final int typeId = 27;

  @override
  ConversationMessage read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return ConversationMessage(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      role: MessageRole.values[fields[2] as int],
      type: MessageType.values[fields[3] as int],
      content: fields[4] as String,
      metadataJson: fields[5] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      tokenCount: fields[7] as int? ?? 0,
      isStreaming: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationMessage obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.sessionId);
    writer.writeByte(2);
    writer.write(obj.role.index);
    writer.writeByte(3);
    writer.write(obj.type.index);
    writer.writeByte(4);
    writer.write(obj.content);
    writer.writeByte(5);
    writer.write(obj.metadataJson);
    writer.writeByte(6);
    writer.write(obj.timestamp.millisecondsSinceEpoch);
    writer.writeByte(7);
    writer.write(obj.tokenCount);
    writer.writeByte(8);
    writer.write(obj.isStreaming);
  }
}

class TutorSessionAdapter extends TypeAdapter<TutorSession> {
  @override
  final int typeId = 28;

  @override
  TutorSession read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return TutorSession(
      id: fields[0] as String,
      studentId: fields[1] as String,
      subjectId: fields[2] as String,
      topicId: fields[3] as String,
      topicTitle: fields[4] as String,
      status: SessionStatus.values[fields[5] as int],
      startTime: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      endTime: fields[7] != null ? DateTime.fromMillisecondsSinceEpoch(fields[7] as int) : null,
      plannedDurationMinutes: fields[8] as int? ?? 45,
      lessonPlanJson: fields[9] as String? ?? '{}',
      questionsAsked: fields[10] as int? ?? 0,
      questionsCorrect: fields[11] as int? ?? 0,
      confidenceRating: fields[12] as int? ?? 0,
      tutorNotes: fields[13] as String?,
      topicsCovered: (fields[14] as List?)?.cast<String>() ?? [],
      totalMessages: fields[15] as int? ?? 0,
      totalTokensUsed: fields[16] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, TutorSession obj) {
    writer.writeByte(17);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.studentId);
    writer.writeByte(2);
    writer.write(obj.subjectId);
    writer.writeByte(3);
    writer.write(obj.topicId);
    writer.writeByte(4);
    writer.write(obj.topicTitle);
    writer.writeByte(5);
    writer.write(obj.status.index);
    writer.writeByte(6);
    writer.write(obj.startTime.millisecondsSinceEpoch);
    writer.writeByte(7);
    writer.write(obj.endTime?.millisecondsSinceEpoch);
    writer.writeByte(8);
    writer.write(obj.plannedDurationMinutes);
    writer.writeByte(9);
    writer.write(obj.lessonPlanJson);
    writer.writeByte(10);
    writer.write(obj.questionsAsked);
    writer.writeByte(11);
    writer.write(obj.questionsCorrect);
    writer.writeByte(12);
    writer.write(obj.confidenceRating);
    writer.writeByte(13);
    writer.write(obj.tutorNotes);
    writer.writeByte(14);
    writer.write(obj.topicsCovered);
    writer.writeByte(15);
    writer.write(obj.totalMessages);
    writer.writeByte(16);
    writer.write(obj.totalTokensUsed);
  }
}
