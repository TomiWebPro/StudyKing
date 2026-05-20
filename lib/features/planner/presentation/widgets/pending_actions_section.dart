import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'pending_action_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class PendingActionsSection extends ConsumerWidget {
  const PendingActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);
    final actions = state.pendingActions;
    if (actions.isEmpty) return const SizedBox.shrink();

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.pendingActions,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...actions.map((action) => PendingActionCard(
                action: action,
                onAccept: () => ref
                    .read(plannerProvider.notifier)
                    .acceptPendingAction(action.id, l10n),
                onDismiss: () => ref
                    .read(plannerProvider.notifier)
                    .dismissPendingAction(action.id, l10n),
              )),
        ],
      ),
    );
  }
}
