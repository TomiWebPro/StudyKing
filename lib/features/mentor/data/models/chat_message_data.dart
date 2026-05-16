import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';

class ChatMessageData {
  final ConversationMessage message;
  final bool isComplete;

  ChatMessageData({required this.message, required this.isComplete});
}
