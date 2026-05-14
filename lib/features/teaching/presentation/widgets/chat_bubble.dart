import 'package:flutter/material.dart';
import '../../../../core/data/models/conversation_message_model.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ChatBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool showSender;
  final bool reduceMotion;

  const ChatBubble({
    super.key,
    required this.message,
    this.showSender = true,
    this.reduceMotion = false,
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
                        isStudent ? AppLocalizations.of(context)!.senderYou : (isTutor ? AppLocalizations.of(context)!.senderTutor : AppLocalizations.of(context)!.senderSystem),
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
      return _TypingIndicator(reduceMotion: reduceMotion);
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
}

class _TypingIndicator extends StatefulWidget {
  final bool reduceMotion;

  const _TypingIndicator({this.reduceMotion = false});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return _buildStaticDots(context);
    }
    return SizedBox(
      width: 40,
      child: Row(
        children: [
          _animatedDot(context, 0),
          _animatedDot(context, 0.2),
          _animatedDot(context, 0.4),
        ],
      ),
    );
  }

  Widget _buildStaticDots(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Row(
        children: List.generate(3, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        )),
      ),
    );
  }

  Widget _animatedDot(BuildContext context, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = (_controller.value - delay).clamp(0.0, 1.0);
        final value = (phase * 4.0) % 1.0;
        final opacity = 0.3 + (0.7 * _easeInOut(value));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  double _easeInOut(double t) {
    if (t < 0.5) return 2 * t * t;
    return -1 + (4 - 2 * t) * t;
  }
}
