import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/data/models/roadmap_model.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'milestone_timeline.dart';

class RoadmapCard extends StatelessWidget {
  final RoadmapModel roadmap;
  final void Function(String roadmapId, String milestoneId, bool isCompleted)?
      onToggleMilestone;

  const RoadmapCard({
    super.key,
    required this.roadmap,
    this.onToggleMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final completedMilestones =
        roadmap.milestones.where((m) => m.isCompleted).length;
    final totalMilestones = roadmap.milestones.length;
    final progress = totalMilestones > 0
        ? completedMilestones / totalMilestones
        : roadmap.completionPercentage / 100.0;
    final statusColor = roadmap.status == 'active'
        ? theme.colorScheme.primary
        : roadmap.status == 'completed'
            ? theme.colorScheme.primary
            : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roadmap.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    roadmap.goal,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.completionOfValue(progress * 100),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '$completedMilestones/$totalMilestones ${l10n.milestones.toLowerCase()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (roadmap.targetCompletionDate != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.targetCompletion}: ${DateFormat.yMMMd().format(roadmap.targetCompletionDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onToggleMilestone != null && roadmap.milestones.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...roadmap.milestones.map((milestone) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    title: Text(milestone.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: milestone.isCompleted
                              ? FontWeight.w500
                              : FontWeight.normal,
                          decoration: milestone.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        )),
                    subtitle: milestone.topicsCovered.isNotEmpty
                        ? Text(
                            '${milestone.topicsCovered.length} topics',
                            style: theme.textTheme.bodySmall,
                          )
                        : null,
                    value: milestone.isCompleted,
                    onChanged: milestone.isCompleted
                        ? null
                        : (val) => onToggleMilestone!(
                              roadmap.id,
                              milestone.id,
                              val ?? false,
                            ),
                  )),
            ],
            const SizedBox(height: 8),
            MilestoneTimeline(roadmap: roadmap),
          ],
        ),
      ),
    );
  }
}
