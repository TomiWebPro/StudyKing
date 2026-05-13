import 'package:flutter/material.dart';
import '../../../../core/data/models/conversation_message_model.dart';
import 'package:studyking/core/utils/responsive.dart';

class ChatBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool showSender;

  const ChatBubble({
    super.key,
    required this.message,
    this.showSender = true,
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = message.role == MessageRole.student;
    final isTutor = message.role == MessageRole.tutor;

    return Padding(
      padding: EdgeInsets.only(
        left: isStudent ? ResponsiveUtils.horizontalSpacing(context) : 0,
        right: isStudent ? 0 : ResponsiveUtils.horizontalSpacing(context),
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
            isStudent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isStudent) _buildAvatar(context, isTutor),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isStudent
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isStudent ? 16 : 4),
                  bottomRight: Radius.circular(isStudent ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSender)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        isStudent ? 'You' : (isTutor ? 'Tutor' : 'System'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isStudent
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  _buildContent(context),
                ],
              ),
            ),
          ),
          if (isStudent) const SizedBox(width: 8),
          if (isStudent) _buildAvatar(context, false),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isTutor) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isTutor
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        isTutor ? Icons.smart_toy : Icons.person,
        size: 18,
        color: isTutor
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final content = message.content;

    if (message.isStreaming && content.isEmpty) {
      return SizedBox(
        width: 40,
        child: Row(
          children: [
            _dot(context, 0),
            _dot(context, 0.3),
            _dot(context, 0.6),
          ],
        ),
      );
    }

    return Text(
      content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: message.role == MessageRole.student
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
    );
  }

  Widget _dot(BuildContext context, double delay) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
