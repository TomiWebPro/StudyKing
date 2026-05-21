import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';

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
      toolCallId: fields[9] as String?,
      toolName: fields[10] as String?,
      toolArguments: fields[11] as String?,
      toolResult: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationMessage obj) {
    writer.writeByte(13);
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
    writer.writeByte(9);
    writer.write(obj.toolCallId);
    writer.writeByte(10);
    writer.write(obj.toolName);
    writer.writeByte(11);
    writer.write(obj.toolArguments);
    writer.writeByte(12);
    writer.write(obj.toolResult);
  }
}
