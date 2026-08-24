import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class LessonFeedbackWidget extends ConsumerStatefulWidget {
  final String studentId;
  final String targetType;
  final String? lessonId;
  final String? messageId;
  final VoidCallback? onSubmitted;

  const LessonFeedbackWidget({
    super.key,
    required this.studentId,
    this.targetType = 'explanation',
    this.lessonId,
    this.messageId,
    this.onSubmitted,
  });

  @override
  ConsumerState<LessonFeedbackWidget> createState() =>
      _LessonFeedbackWidgetState();
}

class _LessonFeedbackWidgetState extends ConsumerState<LessonFeedbackWidget> {
  static final Logger _logger = const Logger('LessonFeedbackWidget');

  FeedbackSentiment _sentiment = FeedbackSentiment.none;
  int _starRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _reported = false;
  bool _submitted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(lessonFeedbackRepositoryProvider);
      final result = await repo.submitFeedback(
        studentId: widget.studentId,
        targetType: widget.targetType,
        lessonId: widget.lessonId,
        messageId: widget.messageId,
        sentiment: _sentiment.name,
        starRating: _starRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        reportedIncorrect: _reported,
      );
      if (result.isFailure) {
        _logger.w('Failed to submit feedback: ${result.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.feedbackThanks)),
          );
        }
        return;
      }
      if (mounted) {
        setState(() => _submitted = true);
        widget.onSubmitted?.call();
      }
    } catch (e) {
      _logger.w('Unexpected error submitting feedback: $e', e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_submitted) {
      return _SubmittedView(
        reported: _reported,
        l10n: l10n,
        theme: theme,
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.feedbackSectionTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ThumbButton(
                  icon: Icons.thumb_up_outlined,
                  label: l10n.feedbackThumbsUp,
                  selected: _sentiment == FeedbackSentiment.positive,
                  onTap: () => setState(() =>
                      _sentiment = _sentiment == FeedbackSentiment.positive
                          ? FeedbackSentiment.none
                          : FeedbackSentiment.positive),
                ),
                const SizedBox(width: 8),
                _ThumbButton(
                  icon: Icons.thumb_down_outlined,
                  label: l10n.feedbackThumbsDown,
                  selected: _sentiment == FeedbackSentiment.negative,
                  onTap: () => setState(() =>
                      _sentiment = _sentiment == FeedbackSentiment.negative
                          ? FeedbackSentiment.none
                          : FeedbackSentiment.negative),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.feedbackStarRatingLabel,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    starValue <= _starRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: starValue <= _starRating
                        ? Colors.amber
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() =>
                      _starRating = _starRating == starValue ? 0 : starValue),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.feedbackCommentHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.feedbackReportIncorrect),
              subtitle: Text(l10n.feedbackReportIncorrectHint),
              value: _reported,
              onChanged: (value) => setState(() => _reported = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(l10n.feedbackSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThumbButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  final bool reported;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _SubmittedView({
    required this.reported,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.feedbackThanks,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (reported)
              Chip(
                label: Text(l10n.feedbackReportedBadge),
                avatar: const Icon(Icons.flag_outlined, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
