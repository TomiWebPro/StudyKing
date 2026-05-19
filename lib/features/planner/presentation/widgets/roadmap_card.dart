import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'milestone_timeline.dart';

class RoadmapCard extends StatelessWidget {
  final RoadmapModel roadmap;
  final void Function(String roadmapId, String milestoneId, bool isCompleted)?
      onToggleMilestone;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoadmapCard({
    super.key,
    required this.roadmap,
    this.onToggleMilestone,
    this.onEdit,
    this.onDelete,
  });

  String _formatTopicNames(List<String> topicIds) {
    if (topicIds.isEmpty) return '';
    if (topicIds.length <= 2) return topicIds.join(', ');
    return '${topicIds.take(2).join(', ')}, +${topicIds.length - 2} more';
  }

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
            ? theme.colorScheme.tertiary
            : theme.colorScheme.error;
    final statusLabel = switch (roadmap.status) {
      'active' => l10n.inProgress,
      'completed' => l10n.completed,
      _ => l10n.notStarted,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
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
                    statusLabel,
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(l10n.edit),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              Text(l10n.delete),
                            ],
                          ),
                        ),
                    ],
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
                  l10n.completionOfValue(formatPercent(progress * 100, l10n.localeName)),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '$completedMilestones/$totalMilestones ${l10n.milestones}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (roadmap.targetCompletionDate != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.targetCompletion}: ${DateFormat.yMMMd(l10n.localeName).format(roadmap.targetCompletionDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onToggleMilestone != null && roadmap.milestones.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...roadmap.milestones.map((milestone) => SizedBox(
                    height: 56,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
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
                              _formatTopicNames(milestone.topicsCovered),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      value: milestone.isCompleted,
                      onChanged: (val) => onToggleMilestone!(
                            roadmap.id,
                            milestone.id,
                            val ?? false,
                          ),
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
