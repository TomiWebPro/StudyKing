import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class PendingActionCard extends StatelessWidget {
  final PendingActionModel action;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const PendingActionCard({
    super.key,
    required this.action,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Row(
          children: [
            Icon(
              _actionIcon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _actionTitle(l10n),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (action.topicTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.topicTitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: l10n.accept,
              child: IconButton(
                icon: Icon(Icons.check_circle_outline,
                    color: theme.colorScheme.primary),
                tooltip: l10n.accept,
                onPressed: onAccept,
              ),
            ),
            Semantics(
              button: true,
              label: l10n.dismiss,
              child: IconButton(
                icon: Icon(Icons.cancel_outlined,
                    color: theme.colorScheme.error),
                tooltip: l10n.dismiss,
                onPressed: onDismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _actionIcon {
    switch (action.actionType) {
      case 'schedule':
        return Icons.event;
      case 'reschedule':
        return Icons.event_busy;
      case 'planAdjustment':
        return Icons.tune;
      default:
        return Icons.notifications;
    }
  }

  String _actionTitle(AppLocalizations l10n) {
    switch (action.actionType) {
      case 'schedule':
        return l10n.scheduleALesson;
      case 'reschedule':
        return l10n.rescheduleLesson;
      case 'planAdjustment':
        return l10n.planAdjustmentTitle;
      default:
        return l10n.actionNeeded;
    }
  }
}
