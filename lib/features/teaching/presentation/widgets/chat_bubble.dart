import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/core/utils/responsive.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ChatBubble extends StatelessWidget {
  static final Logger _logger = const Logger('ChatBubble');

  final ConversationMessage message;
  final bool showSender;
  final bool reduceMotion;
  final VoidCallback? onSpeak;

  const ChatBubble({
    super.key,
    required this.message,
    this.showSender = true,
    this.reduceMotion = false,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = message.role == MessageRole.student;
    final isTutor = message.role == MessageRole.tutor;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: ResponsiveUtils.horizontalSpacing(context),
        end: ResponsiveUtils.horizontalSpacing(context),
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
              padding: ResponsiveUtils.cardPadding(context),
              decoration: BoxDecoration(
                color: isStudent
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(16),
                  topEnd: const Radius.circular(16),
                  bottomStart: Radius.circular(isStudent ? (isRtl ? 4 : 16) : (isRtl ? 16 : 4)),
                  bottomEnd: Radius.circular(isStudent ? (isRtl ? 16 : 4) : (isRtl ? 4 : 16)),
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
                  if (!isStudent && onSpeak != null && !message.isStreaming)
                    Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: IconButton(
                        icon: const Icon(Icons.volume_up, size: 16),
                        onPressed: onSpeak,
                        tooltip: 'Read aloud',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ),
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

    if (message.type == MessageType.feedback || _isEvaluationMessage(content)) {
      return _buildEvaluationContent(context, content);
    }

    final textWidget = Text(
      content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: message.role == MessageRole.student
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
    );

    if (message.isStreaming) {
      return Semantics(
        liveRegion: message.content.length < 50,
        child: textWidget,
      );
    }

    return Semantics(
      label: message.content,
      child: textWidget,
    );
  }

  bool _isEvaluationMessage(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data['type'] == 'evaluation';
    } catch (e) {
      _logger.e('Failed to parse evaluation message', e);
      return false;
    }
  }

  String _evaluationSemanticLabel(BuildContext context, double score) {
    final l10n = AppLocalizations.of(context)!;
    final label = score >= 0.7 ? l10n.correctFeedback : (score <= 0.3 ? l10n.incorrectFeedback : l10n.partialLabel);
    return '$label, ${formatPercent(score * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)}';
  }

  Widget _buildEvaluationContent(BuildContext context, String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final score = (data['score'] as num).toDouble();
      final explanation = data['explanation'] as String? ?? '';
      final cs = Theme.of(context).colorScheme;
      final evalColor = score >= 0.7
          ? cs.primary
          : score <= 0.3
              ? cs.error
              : cs.tertiary;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: _evaluationSemanticLabel(context, score),
            child: Row(
              children: [
                Icon(
                  score >= 0.7 ? Icons.check_circle : (score <= 0.3 ? Icons.cancel : Icons.info),
                  size: 18,
                  color: evalColor,
                ),
                const SizedBox(width: 8),
                Text(
                  formatPercent(score * 100, AppLocalizations.of(context)!.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: evalColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(evalColor),
            ),
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      );
    } catch (e) {
      _logger.e('Failed to build evaluation content', e);
      return Text(content);
    }
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
    if (!widget.reduceMotion) {
      _controller.dispose();
    }
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
