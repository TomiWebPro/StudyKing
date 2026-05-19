import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

final _dashboardUpcomingLessonsProvider =
    FutureProvider.family<List<Session>, String>((ref, studentId) async {
  final plannerService = ref.watch(plannerServiceProvider);
  return plannerService.getScheduledLessons();
});

final _dashboardWeakTopicsProvider =
    FutureProvider.family<int, String>((ref, studentId) async {
  final masteryService = ref.watch(masteryGraphServiceProvider);
  final result = await masteryService.getWeakTopics(studentId);
  return result.isSuccess ? (result.data?.length ?? 0) : 0;
});

class NextUpCard extends ConsumerWidget {
  final String studentId;

  const NextUpCard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueReviewsAsync = ref.watch(dashboardDueReviewsProvider(studentId));
    final upcomingLessonsAsync = ref.watch(_dashboardUpcomingLessonsProvider(studentId));
    final weakCountAsync = ref.watch(_dashboardWeakTopicsProvider(studentId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;
    final dueCount = dueReviewsAsync.valueOrNull?.totalDue ?? 0;
    final upcomingLessons = upcomingLessonsAsync.valueOrNull ?? [];
    final weakCount = weakCountAsync.valueOrNull ?? 0;

    if (dueCount == 0 && upcomingLessons.isEmpty && weakCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.allCaughtUp,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              headingLevel: 3,
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.nextUp,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (upcomingLessons.isNotEmpty)
              _buildActionTile(
                context: context,
                icon: Icons.schedule,
                iconColor: cs.tertiary,
                title: upcomingLessons.first.tutorMetadata?.topicTitle ?? upcomingLessons.first.topicId ?? l10n.scheduledLesson,
                subtitle: l10n.upcomingLessonsCount(upcomingLessons.length),
                onTap: () => Navigator.pushNamed(context, AppRoutes.planner),
              ),
            if (dueCount > 0)
              _buildActionTile(
                context: context,
                icon: Icons.autorenew,
                iconColor: cs.primary,
                title: l10n.reviewsDueCount(dueCount),
                subtitle: l10n.dueForReviewSubtitle,
                onTap: () => Navigator.pushNamed(context, AppRoutes.practiceSession),
              ),
            if (weakCount > 0)
              _buildActionTile(
                context: context,
                icon: Icons.psychology,
                iconColor: cs.error,
                title: l10n.weakTopicsCount(weakCount),
                subtitle: l10n.practiceWeakAreas,
                onTap: () => Navigator.pushNamed(context, AppRoutes.practiceSession),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
