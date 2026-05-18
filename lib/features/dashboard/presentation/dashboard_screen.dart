import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
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
import 'package:studyking/features/dashboard/presentation/widgets/due_reviews_card.dart';
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
    final theme = Theme.of(context);
    final allMasteryAsync = ref.watch(dashboardAllMasteryProvider(studentId));
    final snapshotAsync = ref.watch(dashboardMasterySnapshotProvider(studentId));
    final overallStatsAsync = ref.watch(dashboardOverallStatsProvider(studentId));
    final weeklyTrendAsync = ref.watch(dashboardWeeklyTrendProvider(studentId));
    final focusStatsAsync = ref.watch(dashboardFocusStatsProvider(studentId));
    final adherenceAsync = ref.watch(dashboardAdherenceDataProvider(studentId));
    final topicNamesAsync = ref.watch(dashboardTopicNamesProvider(studentId));
    final badgesAsync = ref.watch(dashboardBadgesProvider(studentId));
    final workloadAsync = ref.watch(dashboardWorkloadProvider(studentId));
    final dueReviewsAsync = ref.watch(dashboardDueReviewsProvider(studentId));

    final allMasteryData = allMasteryAsync.valueOrNull ?? [];
    final snapshotData = snapshotAsync.valueOrNull;
    final overallStatsData = overallStatsAsync.valueOrNull;
    final weeklyTrendData = weeklyTrendAsync.valueOrNull ?? [];
    final focusStatsData = focusStatsAsync.valueOrNull;
    final adherenceData = adherenceAsync.valueOrNull ?? const AdherenceData();
    final topicNamesData = topicNamesAsync.valueOrNull ?? {};
    final badgesData = badgesAsync.valueOrNull ?? [];
    final workloadData = workloadAsync.valueOrNull;
    final dueReviewsData = dueReviewsAsync.valueOrNull;

    final allEmpty = allMasteryData.isEmpty &&
        (snapshotData == null || snapshotData.isEmpty) &&
        (overallStatsData == null || overallStatsData.isEmpty) &&
        weeklyTrendData.isEmpty &&
        (focusStatsData == null || focusStatsData.isEmpty) &&
        adherenceData.isEmpty &&
        topicNamesData.isEmpty &&
        badgesData.isEmpty &&
        (workloadData == null || workloadData.totalQuestions == 0) &&
        (dueReviewsData == null || dueReviewsData.totalDue == 0);

    final hasAnyError = overallStatsAsync.hasError ||
        snapshotAsync.hasError ||
        weeklyTrendAsync.hasError ||
        focusStatsAsync.hasError ||
        adherenceAsync.hasError ||
        topicNamesAsync.hasError ||
        badgesAsync.hasError ||
        workloadAsync.hasError ||
        dueReviewsAsync.hasError;

    final isFirstLoad = overallStatsAsync.isLoading &&
        snapshotAsync.isLoading &&
        weeklyTrendAsync.isLoading &&
        focusStatsAsync.isLoading &&
        adherenceAsync.isLoading &&
        topicNamesAsync.isLoading &&
        badgesAsync.isLoading &&
        allEmpty;

    final asyncSnapshot = ref.watch(dashboardSourceCountProvider(studentId));

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
            _buildSourcesCard(context, asyncSnapshot),
            const SizedBox(height: 16),
            _buildQuestionBankCard(context),
            const SizedBox(height: 16),
            _buildSessionHistoryCard(context),
            const SizedBox(height: 16),
            if (isFirstLoad)
              _buildSkeletonLoading(context)
            else if (hasAnyError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(l10n.somethingWentWrong, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () { ref.invalidate(dashboardInitProvider); },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              )
            else if (allEmpty)
              const EmptyDashboardChecklist()
            else ...[
              CollapsibleCard(
                cardId: 'summary',
                asyncValue: overallStatsAsync,
                onRetry: _onRetry(ref, dashboardOverallStatsProvider(studentId)),
                title: _cardTitle(context, Icons.summarize, l10n.summary),
                body: SummaryRow(overallStats: overallStatsData),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'focus',
                asyncValue: focusStatsAsync,
                onRetry: _onRetry(ref, dashboardFocusStatsProvider(studentId)),
                title: _cardTitle(context, Icons.timer, l10n.focusTime),
                body: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.focusMode),
                  child: Row(
                    children: [
                      Expanded(
                        child: SessionSummaryCard(todayStats: focusStatsData != null ? {
                          'totalSeconds': focusStatsData.totalSeconds,
                          'completedSessions': focusStatsData.completedSessions,
                          'totalSessions': focusStatsData.totalSessions,
                          'plannedMinutes': focusStatsData.plannedMinutes,
                          'hours': formatHours(focusStatsData.totalSeconds.toDouble(), l10n.localeName),
                        } : null),
                      ),
                      Icon(Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'weekly_chart',
                asyncValue: weeklyTrendAsync,
                onRetry: _onRetry(ref, dashboardWeeklyTrendProvider(studentId)),
                title: _cardTitle(context, Icons.show_chart, l10n.weeklyActivity),
                body: WeeklyChart(weeklyTrend: weeklyTrendData),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'adherence',
                asyncValue: adherenceAsync,
                onRetry: _onRetry(ref, dashboardAdherenceDataProvider(studentId)),
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
                onRetry: _onRetry(ref, dashboardMasterySnapshotProvider(studentId)),
                title: _cardTitle(context, Icons.analytics, l10n.masteryOverview),
                body: MasteryProgressCard(snapshot: snapshotData),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'workload',
                asyncValue: workloadAsync,
                onRetry: _onRetry(ref, dashboardWorkloadProvider(studentId)),
                title: _cardTitle(context, Icons.trending_up, l10n.remainingWorkload),
                body: workloadData != null
                    ? WorkloadCard(
                        workload: workloadData,
                        resolveTopicName: (id) => topicNamesData[id] ?? id,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'due_reviews',
                asyncValue: dueReviewsAsync,
                onRetry: _onRetry(ref, dashboardDueReviewsProvider(studentId)),
                title: _cardTitle(context, Icons.autorenew, l10n.dueForReview),
                body: dueReviewsData != null && dueReviewsData.totalDue > 0
                    ? DueReviewsCard(data: dueReviewsData)
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            l10n.allCaughtUp,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              CollapsibleCard(
                cardId: 'weak_areas',
                asyncValue: allMasteryAsync,
                onRetry: _onRetry(ref, dashboardAllMasteryProvider(studentId)),
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
                onRetry: _onRetry(ref, dashboardAllMasteryProvider(studentId)),
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
                onRetry: _onRetry(ref, dashboardBadgesProvider(studentId)),
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

  VoidCallback _onRetry(WidgetRef ref, ProviderBase<Object?> provider) => () {
    ref.invalidate(dashboardInitProvider);
    ref.invalidate(provider);
  };

  Widget _buildSessionHistoryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.sessionHistory),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MergeSemantics(
            child: Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.sessionHistory, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(l10n.sessionHistoryDescription, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourcesCard(BuildContext context, AsyncValue<int> sourceCountAsync) {
    final l10n = AppLocalizations.of(context)!;
    final count = sourceCountAsync.valueOrNull ?? 0;
    if (count == 0 && !sourceCountAsync.isLoading) return const SizedBox.shrink();
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.contentLibrary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MergeSemantics(
            child: Row(
              children: [
                Icon(Icons.source, color: Theme.of(context).colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.contentLibrary, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        sourceCountAsync.isLoading
                            ? l10n.loading
                            : l10n.sourcesCount(count),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionBankCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.questionBank),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MergeSemantics(
            child: Row(
              children: [
                Icon(Icons.quiz, color: Theme.of(context).colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.questionBank, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(l10n.manageQuestions, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    return Column(
      children: List.generate(6, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 120, height: 20, color: baseColor),
                const SizedBox(height: 16),
                _shimmerBox(width: double.infinity, height: 60, color: baseColor),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _shimmerBox({required double width, required double height, required Color color}) {
    return _ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
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
          child: MergeSemantics(
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

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Timeouts.dashboardAnimation);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: child);
      },
    );
  }
}
