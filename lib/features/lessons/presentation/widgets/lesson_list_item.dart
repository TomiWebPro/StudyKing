import 'package:flutter/material.dart';
import '../../../../core/data/models/lesson_model.dart';
import '../../../../l10n/generated/app_localizations.dart';

class LessonListItem extends StatelessWidget {
  final Lesson lesson;
  final String topicTitle;
  final String? subjectId;
  final String? topicId;
  final LessonStatusDisplay? status;
  final VoidCallback? onTap;

  const LessonListItem({
    super.key,
    required this.lesson,
    required this.topicTitle,
    this.subjectId,
    this.topicId,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardMargin = Theme.of(context).cardTheme.margin;
    final resolvedMargin = cardMargin?.resolve(Directionality.of(context));
    return Card(
      margin: EdgeInsets.only(
        bottom: resolvedMargin?.bottom ?? 8,
      ),
      child: ListTile(
        leading: _statusIcon(context),
        title: Text(lesson.title),
        subtitle: Row(
          children: [
            Text(l10n.blocksCount(lesson.blocks.length)),
            if (status != null) ...[
              const SizedBox(width: 8),
              _statusChip(context, status!, l10n),
            ],
          ],
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }

  Widget _statusIcon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case LessonStatusDisplay.completed:
        return Icon(Icons.check_circle, color: cs.primary);
      case LessonStatusDisplay.inProgress:
        return Icon(Icons.play_circle_filled, color: cs.tertiary);
      case LessonStatusDisplay.notStarted:
      case null:
        return const Icon(Icons.book);
    }
  }

  Widget _statusChip(
      BuildContext context, LessonStatusDisplay status, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      LessonStatusDisplay.completed => (l10n.completed, cs.primary),
      LessonStatusDisplay.inProgress => (l10n.inProgress, cs.tertiary),
      LessonStatusDisplay.notStarted => (l10n.notStarted, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum LessonStatusDisplay { notStarted, inProgress, completed }
