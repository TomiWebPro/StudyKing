import 'package:flutter/material.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/teaching/presentation/widgets/chat_bubble.dart';

class MessageListWidget extends StatelessWidget {
  final List<ConversationMessage> messages;
  final ScrollController scrollController;
  final bool reduceMotion;

  const MessageListWidget({
    super.key,
    required this.messages,
    required this.scrollController,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: ResponsiveUtils.listPadding(context),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ChatBubble(
          message: message,
          reduceMotion: reduceMotion,
        );
      },
    );
  }
}
