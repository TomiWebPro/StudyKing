import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class LessonProgressBar extends StatelessWidget {
  final int elapsedMinutes;
  final int plannedDurationMinutes;
  final int exerciseCount;
  final int correctCount;
  final String topicTitle;

  const LessonProgressBar({
    super.key,
    required this.elapsedMinutes,
    required this.plannedDurationMinutes,
    required this.exerciseCount,
    required this.correctCount,
    required this.topicTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress =
        (elapsedMinutes / plannedDurationMinutes).clamp(0.0, 1.0);
    final remaining = (plannedDurationMinutes - elapsedMinutes)
        .clamp(0, plannedDurationMinutes);
    final isOvertime = elapsedMinutes > plannedDurationMinutes;

    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topicTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isOvertime
                    ? '+${elapsedMinutes - plannedDurationMinutes}m'
                    : l10n.remainingMinLabel(remaining),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isOvertime
                          ? Theme.of(context).colorScheme.error
                          : remaining <= 5
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOvertime
                    ? Theme.of(context).colorScheme.error
                    : remaining <= 5
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip(context, Icons.quiz_outlined, l10n.questionsCountLabel(exerciseCount)),
              const SizedBox(width: 12),
              _statChip(
                context,
                Icons.check_circle_outline,
                l10n.correctCountLabel(correctCount),
                color: correctCount > 0
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
