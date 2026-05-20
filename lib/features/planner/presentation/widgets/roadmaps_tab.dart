import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/loading_indicator.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'roadmap_card.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class RoadmapsTab extends ConsumerWidget {
  final Future<void> Function({RoadmapModel? existing}) onCreateRoadmap;
  final void Function(RoadmapModel) onEdit;
  final void Function(RoadmapModel) onDelete;

  const RoadmapsTab({
    super.key,
    required this.onCreateRoadmap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plannerProvider);
    final activeRoadmaps = state.roadmaps.where((r) => r.status == 'active').toList();
    final completedRoadmapsList = state.roadmaps.where((r) => r.status == 'completed').toList();

    return FocusTraversalGroup(
      child: Column(
        children: [
          Padding(
            padding: ResponsiveUtils.screenPadding(context),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onCreateRoadmap(),
                icon: const Icon(Icons.add_road),
                label: Text(l10n.createRoadmap),
              ),
            ),
          ),
          if (state.roadmaps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.myRoadmaps,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (state.isLoadingRoadmaps)
            const Expanded(
              child: LoadingIndicator(),
            )
          else if (state.roadmaps.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map,
                        size: ResponsiveUtils.emptyStateIconSize(context),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(l10n.noRoadmapsYet,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(l10n.roadmapGoalHint,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: ResponsiveUtils.screenPadding(context),
                itemCount: (activeRoadmaps.isNotEmpty ? 1 : 0) +
                    (completedRoadmapsList.isNotEmpty ? 1 : 0) +
                    state.roadmaps.length,
                itemBuilder: (context, index) {
                  var offset = 0;
                  if (activeRoadmaps.isNotEmpty) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          '${l10n.activeRoadmaps} (${activeRoadmaps.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    offset = 1;
                  }
                  if (index == activeRoadmaps.length + offset) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        '${l10n.completedRoadmaps} (${completedRoadmapsList.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    );
                  }
                  final roadmapIndex = index - offset;
                  final roadmap = roadmapIndex < activeRoadmaps.length
                      ? activeRoadmaps[roadmapIndex]
                      : completedRoadmapsList[roadmapIndex - activeRoadmaps.length];
                  return RoadmapCard(
                    roadmap: roadmap,
                    onToggleMilestone: (roadmapId, milestoneId, isCompleted) {
                      ref
                          .read(plannerProvider.notifier)
                          .toggleMilestoneCompletion(
                            roadmapId: roadmapId,
                            milestoneId: milestoneId,
                            isCompleted: isCompleted,
                            l10n: l10n,
                          );
                    },
                    onEdit: () => onEdit(roadmap),
                    onDelete: () => onDelete(roadmap),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
