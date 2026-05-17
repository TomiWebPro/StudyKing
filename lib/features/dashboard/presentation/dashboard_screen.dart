import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/badges_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/collapsible_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:studyking/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart';
import 'package:studyking/features/dashboard/presentation/widgets/export_section.dart';
import 'package:studyking/features/dashboard/presentation/widgets/mastery_progress_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/plan_adherence_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/summary_row.dart';
import 'package:studyking/features/dashboard/presentation/widgets/topic_breakdown_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weak_areas_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weekly_chart.dart';
import 'package:studyking/features/dashboard/presentation/widgets/workload_card.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  final String studentId;

  const DashboardScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final allMasteryAsync = ref.watch(dashboardAllMasteryProvider(studentId));
    final snapshotAsync = ref.watch(dashboardMasterySnapshotProvider(studentId));
    final overallStatsAsync = ref.watch(dashboardOverallStatsProvider(studentId));
    final weeklyTrendAsync = ref.watch(dashboardWeeklyTrendProvider(studentId));
    final focusStatsAsync = ref.watch(dashboardFocusStatsProvider(studentId));
    final adherenceAsync = ref.watch(dashboardAdherenceDataProvider(studentId));
    final topicNamesAsync = ref.watch(dashboardTopicNamesProvider(studentId));
    final badgesAsync = ref.watch(dashboardBadgesProvider(studentId));

    final allMasteryData = allMasteryAsync.valueOrNull ?? [];
    final snapshotData = snapshotAsync.valueOrNull;
    final overallStatsData = overallStatsAsync.valueOrNull;
    final weeklyTrendData = weeklyTrendAsync.valueOrNull ?? [];
    final focusStatsData = focusStatsAsync.valueOrNull;
    final adherenceData = adherenceAsync.valueOrNull ?? const AdherenceData();
    final topicNamesData = topicNamesAsync.valueOrNull ?? {};
    final badgesData = badgesAsync.valueOrNull ?? [];

    final allEmpty = allMasteryData.isEmpty &&
        (snapshotData == null || snapshotData.isEmpty) &&
        (overallStatsData == null || overallStatsData.isEmpty) &&
        weeklyTrendData.isEmpty &&
        (focusStatsData == null || focusStatsData.isEmpty) &&
        adherenceData.isEmpty &&
        topicNamesData.isEmpty &&
        badgesData.isEmpty;

    final isFirstLoad = overallStatsAsync.isLoading &&
        snapshotAsync.isLoading &&
        weeklyTrendAsync.isLoading &&
        focusStatsAsync.isLoading &&
        adherenceAsync.isLoading &&
        topicNamesAsync.isLoading &&
        badgesAsync.isLoading &&
        allEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardInitProvider);
      },
      child: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: FocusTraversalGroup(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(),
            const SizedBox(height: 24),
            _buildPlannerCard(context),
            const SizedBox(height: 16),
            if (isFirstLoad)
              _buildSkeletonLoading(context)
            else if (allEmpty)
              const EmptyDashboardChecklist()
            else ...[
              CollapsibleCard(
                cardId: 'summary',
                asyncValue: overallStatsAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardOverallStatsProvider(studentId)); },
                title: _cardTitle(context, Icons.summarize, l10n.summary),
                body: SummaryRow(overallStats: overallStatsData),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'focus',
                asyncValue: focusStatsAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardFocusStatsProvider(studentId)); },
                title: _cardTitle(context, Icons.timer, l10n.focusTime),
                body: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.focusMode),
                  child: SessionSummaryCard(todayStats: focusStatsData != null ? {
                    'totalSeconds': focusStatsData.totalSeconds,
                    'completedSessions': focusStatsData.completedSessions,
                    'totalSessions': focusStatsData.totalSessions,
                    'plannedMinutes': focusStatsData.plannedMinutes,
                    'hours': formatHours(focusStatsData.totalSeconds.toDouble(), l10n.localeName),
                  } : null),
                ),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'weekly_chart',
                asyncValue: weeklyTrendAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardWeeklyTrendProvider(studentId)); },
                title: _cardTitle(context, Icons.show_chart, l10n.weeklyActivity),
                body: WeeklyChart(weeklyTrend: weeklyTrendData),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'adherence',
                asyncValue: adherenceAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardAdherenceDataProvider(studentId)); },
                title: _cardTitle(context, Icons.event_note, l10n.planAdherence),
                body: PlanAdherenceCard(
                  averageAdherence: adherenceData.averageAdherence,
                  weeklyAdherence: adherenceData.weeklyAdherence,
                ),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'mastery',
                asyncValue: snapshotAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardMasterySnapshotProvider(studentId)); },
                title: _cardTitle(context, Icons.analytics, l10n.masteryOverview),
                body: MasteryProgressCard(snapshot: snapshotData),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'workload',
                asyncValue: allMasteryAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardAllMasteryProvider(studentId)); },
                title: _cardTitle(context, Icons.trending_up, 'Remaining Workload'),
                body: allMasteryData.isNotEmpty
                    ? WorkloadCard(
                        allMastery: allMasteryData,
                        resolveTopicName: (id) => topicNamesData[id] ?? id,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'weak_areas',
                asyncValue: allMasteryAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardAllMasteryProvider(studentId)); },
                title: _cardTitle(context, Icons.warning_amber, l10n.weakAreas),
                body: allMasteryData.isNotEmpty
                    ? WeakAreasCard(
                        allMastery: allMasteryData,
                        resolveTopicName: (id) => topicNamesData[id] ?? id,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'topic_breakdown',
                asyncValue: allMasteryAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardAllMasteryProvider(studentId)); },
                title: _cardTitle(context, Icons.pie_chart, l10n.topicPerformance),
                body: TopicBreakdownCard(
                  allMastery: allMasteryData,
                  resolveTopicName: (id) => topicNamesData[id] ?? id,
                ),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'badges',
                asyncValue: badgesAsync,
                onRetry: () { ref.invalidate(dashboardInitProvider); ref.invalidate(dashboardBadgesProvider(studentId)); },
                title: _cardTitle(context, Icons.emoji_events, l10n.achievements),
                body: BadgesCard(badges: badgesData),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ExportSection(studentId: studentId),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    return Column(
      children: List.generate(6, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildPlannerCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.planner),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.studyPlanner,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(l10n.studyPlanOverview,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardTitle(BuildContext context, IconData icon, String label) {
    return Semantics(
      headingLevel: 3,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
