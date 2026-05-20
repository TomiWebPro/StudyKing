import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/widgets/error_retry_widget.dart';
import 'package:studyking/core/widgets/shimmer_widget.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/badges_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/collapsible_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:studyking/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart';
import 'package:studyking/features/dashboard/presentation/widgets/absence_banner.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/dashboard/presentation/widgets/export_section.dart';
import 'package:studyking/features/dashboard/presentation/widgets/mastery_progress_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/plan_adherence_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/summary_row.dart';
import 'package:studyking/features/dashboard/presentation/widgets/topic_breakdown_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weak_areas_card.dart';
import 'package:studyking/features/dashboard/presentation/screens/topic_detail_screen.dart';
import 'package:studyking/features/dashboard/presentation/widgets/weekly_chart.dart';
import 'package:studyking/features/dashboard/presentation/widgets/due_reviews_card.dart';
import 'package:studyking/features/dashboard/presentation/widgets/workload_card.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/features/dashboard/presentation/widgets/next_up_card.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/session_summary_card.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/presentation/widgets/syllabus_progress_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String studentId;

  const DashboardScreen({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final _exportSectionKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _scrollToExport() {
    final context = _exportSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final l10n = AppLocalizations.of(context)!;
    final studentId = widget.studentId;

    final allMasteryAsync = ref.watch(dashboardAllMasteryProvider(studentId));
    final snapshotAsync = ref.watch(dashboardMasterySnapshotProvider(studentId));
    final overallStatsAsync =
        ref.watch(dashboardOverallStatsProvider(studentId));
    final weeklyTrendAsync =
        ref.watch(dashboardWeeklyTrendProvider(studentId));
    final focusStatsAsync =
        ref.watch(dashboardFocusStatsProvider(studentId));
    final adherenceAsync =
        ref.watch(dashboardAdherenceDataProvider(studentId));
    final topicNamesAsync =
        ref.watch(dashboardTopicNamesProvider(studentId));
    final badgesAsync = ref.watch(dashboardBadgesProvider(studentId));
    final workloadAsync = ref.watch(dashboardWorkloadProvider(studentId));
    final dueReviewsAsync =
        ref.watch(dashboardDueReviewsProvider(studentId));
    final checklistProgressAsync =
        ref.watch(dashboardChecklistProgressProvider(studentId));

    final allMasteryData = allMasteryAsync.valueOrNull ?? [];
    final snapshotData = snapshotAsync.valueOrNull;
    final overallStatsData = overallStatsAsync.valueOrNull;
    final weeklyTrendData = weeklyTrendAsync.valueOrNull ?? [];
    final focusStatsData = focusStatsAsync.valueOrNull;
    final adherenceData =
        adherenceAsync.valueOrNull ?? const AdherenceData();
    final topicNamesData = topicNamesAsync.valueOrNull ?? {};
    final badgesData = badgesAsync.valueOrNull ?? [];
    final workloadData = workloadAsync.valueOrNull;
    final dueReviewsData = dueReviewsAsync.valueOrNull;

    final hasAnyData = allMasteryData.isNotEmpty ||
        snapshotData != null ||
        overallStatsData != null ||
        weeklyTrendData.isNotEmpty ||
        focusStatsData != null ||
        !adherenceData.isEmpty ||
        topicNamesData.isNotEmpty ||
        badgesData.isNotEmpty ||
        (workloadData != null && workloadData.totalQuestions > 0) ||
        (dueReviewsData != null && dueReviewsData.totalDue > 0);

    final isLoading = overallStatsAsync.isLoading ||
        snapshotAsync.isLoading ||
        weeklyTrendAsync.isLoading ||
        focusStatsAsync.isLoading ||
        adherenceAsync.isLoading ||
        topicNamesAsync.isLoading ||
        badgesAsync.isLoading ||
        workloadAsync.isLoading ||
        dueReviewsAsync.isLoading;

    final showSkeleton = !hasAnyData && isLoading;

    final checklistProgress = checklistProgressAsync.valueOrNull ?? const ChecklistProgress();

    final isFirstRun = !checklistProgress.isComplete && !hasAnyData;

    final daysSinceLastActivity = StudentIdService().getDaysSinceLastActivity();

    final asyncSnapshot =
        ref.watch(dashboardSourceCountProvider(studentId));

    final syllabusGoalsAsync = ref.watch(dashboardSyllabusProgressProvider(studentId));
    final syllabusGoals = syllabusGoalsAsync.valueOrNull ?? [];

    final vs = ResponsiveUtils.verticalSpacing(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardInitProvider);
      },
      child: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(onExportTap: _scrollToExport),
              if (daysSinceLastActivity >= 1) ...[
                SizedBox(height: vs),
                AbsenceBanner(daysSinceLastActivity: daysSinceLastActivity),
              ],
              SizedBox(height: vs),
              NextUpCard(studentId: studentId),
              SizedBox(height: vs),
              if (!checklistProgress.isComplete)
                EmptyDashboardChecklist(progress: checklistProgress),
              if (!checklistProgress.isComplete)
                SizedBox(height: vs),
              _buildPlannerCard(context),
              SizedBox(height: vs),
              _buildSourcesCard(context, asyncSnapshot),
              SizedBox(height: vs),
              if (isFirstRun) ...[
                SizedBox(height: vs),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.statsAppearAfterLearning,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ] else ...[
                _buildQuestionBankCard(context),
                SizedBox(height: vs),
                _buildSessionHistoryCard(context),
                SizedBox(height: vs),
                if (showSkeleton)
                  _buildSkeletonLoading(context)
                else ...[
                  CollapsibleCard(
                    cardId: 'summary',
                    asyncValue: overallStatsAsync,
                    onRetry:
                        _onRetry(dashboardOverallStatsProvider(studentId)),
                    title:
                        _cardTitle(context, Icons.summarize, l10n.summary),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry:
                          _onRetry(dashboardOverallStatsProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: SummaryRow(overallStats: overallStatsData),
                  ),
                  SizedBox(height: vs),
                  Card(
                    key: _exportSectionKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ExportSection(studentId: studentId),
                    ),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'focus',
                    asyncValue: focusStatsAsync,
                    onRetry:
                        _onRetry(dashboardFocusStatsProvider(studentId)),
                    title: _cardTitle(context, Icons.timer, l10n.focusTime),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry:
                          _onRetry(dashboardFocusStatsProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: Semantics(
                      button: true,
                      label: l10n.focusMode,
                      child: InkWell(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.focusMode),
                        child: Row(
                          children: [
                            Expanded(
                              child: SessionSummaryCard(
                                todayStats: focusStatsData != null
                                    ? {
                                        'totalSeconds':
                                            focusStatsData.totalSeconds,
                                        'completedSessions':
                                            focusStatsData.completedSessions,
                                        'totalSessions':
                                            focusStatsData.totalSessions,
                                        'plannedMinutes':
                                            focusStatsData.plannedMinutes,
                                        'hours': formatHours(
                                            focusStatsData.totalSeconds
                                                .toDouble(),
                                            l10n.localeName),
                                      }
                                    : null,
                              ),
                            ),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'weekly_chart',
                    asyncValue: weeklyTrendAsync,
                    onRetry:
                        _onRetry(dashboardWeeklyTrendProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.show_chart, l10n.weeklyActivity),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry:
                          _onRetry(dashboardWeeklyTrendProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: WeeklyChart(weeklyTrend: weeklyTrendData),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'adherence',
                    asyncValue: adherenceAsync,
                    onRetry:
                        _onRetry(dashboardAdherenceDataProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.event_note, l10n.planAdherence),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry:
                          _onRetry(dashboardAdherenceDataProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: PlanAdherenceCard(
                      averageAdherence: adherenceData.averageAdherence,
                      weeklyAdherence: adherenceData.weeklyAdherence,
                      daysSinceLastActivity: daysSinceLastActivity,
                    ),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'mastery',
                    asyncValue: snapshotAsync,
                    onRetry:
                        _onRetry(dashboardMasterySnapshotProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.analytics, l10n.masteryOverview),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry: _onRetry(
                          dashboardMasterySnapshotProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: MasteryProgressCard(snapshot: snapshotData),
                  ),
                  if (syllabusGoals.isNotEmpty) ...[
                    SizedBox(height: vs),
                    _buildSyllabusProgress(context, syllabusGoals, studentId),
                  ],
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'workload',
                    asyncValue: workloadAsync,
                    onRetry:
                        _onRetry(dashboardWorkloadProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.trending_up, l10n.remainingWorkload),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry:
                          _onRetry(dashboardWorkloadProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: workloadData != null
                        ? WorkloadCard(
                            workload: workloadData,
                            resolveTopicName: (id) =>
                                topicNamesData[id] ?? l10n.unknown,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                l10n.noSessionsYet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'due_reviews',
                    asyncValue: dueReviewsAsync,
                    onRetry:
                        _onRetry(dashboardDueReviewsProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.autorenew, l10n.dueForReview),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry: _onRetry(
                          dashboardDueReviewsProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: dueReviewsData != null &&
                            dueReviewsData.totalDue > 0
                        ? DueReviewsCard(data: dueReviewsData)
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                l10n.allCaughtUp,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'weak_areas',
                    asyncValue: allMasteryAsync,
                    onRetry:
                        _onRetry(dashboardAllMasteryProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.warning_amber, l10n.weakAreas),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry: _onRetry(
                          dashboardAllMasteryProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: allMasteryData.isNotEmpty
                        ? WeakAreasCard(
                            allMastery: allMasteryData,
                            resolveTopicName: (id) =>
                                topicNamesData[id] ?? l10n.unknown,
                            onTopicTap: (topicId) => Navigator.pushNamed(
                              context,
                              AppRoutes.topicDetail,
                              arguments: TopicDetailArgs(
                                topicId: topicId,
                                studentId: studentId,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                l10n.noWeakAreasFound,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'topic_breakdown',
                    asyncValue: allMasteryAsync,
                    onRetry:
                        _onRetry(dashboardAllMasteryProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.pie_chart, l10n.topicPerformance),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry: _onRetry(
                          dashboardAllMasteryProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: TopicBreakdownCard(
                      allMastery: allMasteryData,
                      resolveTopicName: (id) =>
                          topicNamesData[id] ?? l10n.unknown,
                      onTopicTap: (topicId) => Navigator.pushNamed(
                        context,
                        AppRoutes.topicDetail,
                        arguments: TopicDetailArgs(
                          topicId: topicId,
                          studentId: studentId,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: vs),
                  CollapsibleCard(
                    cardId: 'badges',
                    asyncValue: badgesAsync,
                    onRetry:
                        _onRetry(dashboardBadgesProvider(studentId)),
                    title: _cardTitle(
                        context, Icons.emoji_events, l10n.achievements),
                    errorWidget: ErrorRetryWidget(
                      message: l10n.somethingWentWrong,
                      onRetry:
                          _onRetry(dashboardBadgesProvider(studentId)),
                    ),
                    loadingSkeleton: _cardSkeleton(context),
                    body: BadgesCard(badges: badgesData),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback _onRetry(ProviderBase<Object?> provider) => () {
        ref.invalidate(provider);
      };

  Widget _cardSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: [
        ShimmerWidget(width: 120, height: 20, color: color),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        ShimmerWidget(width: double.infinity, height: 60, color: color),
      ],
    );
  }

  Widget _buildSyllabusProgress(BuildContext context, List<SyllabusGoal> goals, String studentId) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(l10n.subjectProgress, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SyllabusProgressCard(
                studentId: studentId,
                goal: goal,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHistoryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Semantics(
        button: true,
        label: l10n.sessionHistory,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.sessionHistory),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MergeSemantics(
              child: Row(
                children: [
                  Icon(Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.sessionHistory,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(l10n.sessionHistoryDescription,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourcesCard(
      BuildContext context, AsyncValue<int> sourceCountAsync) {
    final l10n = AppLocalizations.of(context)!;
    final count = sourceCountAsync.valueOrNull ?? 0;
    if (count == 0 && !sourceCountAsync.isLoading) {
      return Card(
        child: Semantics(
          button: true,
          label: l10n.contentLibrary,
          child: InkWell(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.contentLibrary),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.source,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.contentLibrary,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noSourcesAvailable,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
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
    return Card(
      child: Semantics(
        button: true,
        label: l10n.contentLibrary,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.contentLibrary),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MergeSemantics(
              child: Row(
                children: [
                  Icon(Icons.source,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.contentLibrary,
                            style:
                                Theme.of(context).textTheme.titleMedium),
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
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionBankCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Semantics(
        button: true,
        label: l10n.questionBank,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.questionBank),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MergeSemantics(
              child: Row(
                children: [
                  Icon(Icons.quiz,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.questionBank,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(l10n.manageQuestions,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final vs = ResponsiveUtils.verticalSpacing(context);
    return Column(
      children: List.generate(6, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(width: 120, height: 20, color: baseColor),
                SizedBox(height: vs),
                ShimmerWidget(
                    width: double.infinity, height: 60, color: baseColor),
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
      child: Semantics(
        button: true,
        label: l10n.studyPlanner,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.planner),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MergeSemantics(
              child: Row(
                children: [
                  Icon(Icons.calendar_month,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32),
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
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
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
          Icon(icon,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
