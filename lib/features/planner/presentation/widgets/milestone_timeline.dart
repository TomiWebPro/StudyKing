import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class MilestoneTimeline extends StatelessWidget {
  final RoadmapModel roadmap;

  const MilestoneTimeline({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) {
    if (roadmap.milestones.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.timeline,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final now = DateTime.now();
              final startDate = roadmap.createdAt;
              final endDate = roadmap.targetCompletionDate ??
                  startDate.add(const Duration(days: 30));
              final totalDuration =
                  endDate.difference(startDate).inMilliseconds.toDouble();
              if (totalDuration <= 0) return const SizedBox.shrink();

              return Stack(
                children: [
                  Container(
                    height: 4,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ...roadmap.milestones.map((milestone) {
                    final msDuration = milestone.deadline
                        .difference(startDate)
                        .inMilliseconds
                        .toDouble();
                    final left = (msDuration / totalDuration * totalWidth)
                        .clamp(0.0, totalWidth);
                    final isPast = milestone.deadline.isBefore(now);
                    final isCompleted = milestone.isCompleted;
                    final color = isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : isPast
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.tertiary;

                    return Positioned(
                      left: left - 6,
                      top: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.milestoneShort(milestone.order),
                            style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: roadmap.milestones.map((ms) {
            final isPast = ms.deadline.isBefore(DateTime.now());
            return Semantics(
              label: l10n.milestoneOfWithDeadline(
                  ms.title, DateFormat.yMMMd(l10n.localeName).format(ms.deadline)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ms.isCompleted
                      ? Theme.of(context).colorScheme.primaryContainer
                      : isPast
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${ms.title}: ${DateFormat.MMMd(l10n.localeName).format(ms.deadline)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: ms.isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : isPast
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
