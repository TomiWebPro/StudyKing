import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../data/models/lesson_plan_model.dart';

class LessonProgressBar extends StatelessWidget {
  final int elapsedMinutes;
  final int plannedDurationMinutes;
  final int exerciseCount;
  final int correctCount;
  final String topicTitle;
  final LessonPlan? lessonPlan;

  const LessonProgressBar({
    super.key,
    required this.elapsedMinutes,
    required this.plannedDurationMinutes,
    required this.exerciseCount,
    required this.correctCount,
    required this.topicTitle,
    this.lessonPlan,
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
                child: Semantics(
                  header: true,
                  child: Text(
                    topicTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                isOvertime
                    ? l10n.overtimeLabel(elapsedMinutes - plannedDurationMinutes)
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
          Semantics(
            label: '${(progress * 100).round()}%',
            child: ClipRRect(
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
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          if (lessonPlan != null && lessonPlan!.sections.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionTimeline(context),
          ],
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
                formatPercent(progress * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
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

  Widget _buildSectionTimeline(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = lessonPlan!;
    int cumulative = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...plan.sections.map((section) {
          final sectionStart = cumulative;
          cumulative += section.durationMinutes;
          final sectionEnd = cumulative;
          final isCurrentSection =
              elapsedMinutes >= sectionStart && elapsedMinutes < sectionEnd;
          final isCompleted = elapsedMinutes >= sectionEnd;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isCurrentSection
                          ? Icons.play_circle_filled
                          : Icons.circle_outlined,
                  size: 14,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : isCurrentSection
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: isCurrentSection ? FontWeight.w600 : null,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : isCurrentSection
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                Text(
                  l10n.durationMinutes(section.durationMinutes),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }),
      ],
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
