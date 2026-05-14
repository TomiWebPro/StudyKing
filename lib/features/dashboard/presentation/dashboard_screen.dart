import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/study_progress_tracker.dart';
import '../../../core/services/instrumentation_service.dart';
import '../../../core/data/repositories/attempt_repository.dart';
import '../../../core/data/models/mastery_state_model.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/animated_bar_chart.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String studentId;
  final MasteryGraphService masteryService;
  final StudyProgressTracker? tracker;
  final InstrumentationService? instrumentation;
  final TopicRepository? topicRepo;

  const DashboardScreen({
    super.key,
    required this.studentId,
    required this.masteryService,
    this.tracker,
    this.instrumentation,
    this.topicRepo,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final StudyProgressTracker _tracker;
  late final InstrumentationService _instrumentation;
  late final TopicRepository _topicRepo;

  List<MasteryState> _allMastery = [];
  Map<String, dynamic>? _snapshot;
  Map<String, dynamic>? _overallStats;
  List<Map<String, dynamic>> _weeklyTrend = [];
  List<Map<String, dynamic>> _badges = [];
  Map<String, dynamic>? _instrumentationData;
  bool _isLoading = true;
  final Map<String, String> _topicNameCache = {};

  @override
  void initState() {
    super.initState();
    _tracker = widget.tracker ?? StudyProgressTracker(
      attemptRepo: AttemptRepository(),
    );
    _instrumentation = widget.instrumentation ?? InstrumentationService();
    _topicRepo = widget.topicRepo ?? TopicRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _instrumentation.init();
    await _topicRepo.init();

    final masteryResult = await widget.masteryService.getAllTopicMastery(widget.studentId);
    if (masteryResult.isSuccess) {
      _allMastery = masteryResult.data!;
    }

    final snapshotResult = await widget.masteryService.getMasterySnapshot(widget.studentId);
    if (snapshotResult.isSuccess) {
      _snapshot = snapshotResult.data;
    }

    _overallStats = await _tracker.getOverallStats(widget.studentId);
    _weeklyTrend = await _tracker.getWeeklyTrend(8, studentId: widget.studentId);
    _badges = await _tracker.getBadges(widget.studentId);
    _instrumentationData = (await _instrumentation.getInstrumentationDashboard(widget.studentId)).data;

    for (final state in _allMastery) {
      if (!_topicNameCache.containsKey(state.topicId)) {
        try {
          final topic = await _topicRepo.get(state.topicId);
          _topicNameCache[state.topicId] = topic?.title ?? state.topicId;
        } catch (_) {
          _topicNameCache[state.topicId] = state.topicId;
        }
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _resolveTopicName(String topicId) {
    return _topicNameCache[topicId] ?? topicId;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: _buildHeader(context, AppLocalizations.of(context)!),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: _buildSummaryRow(),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: _buildWeeklyChart(context),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(4),
                child: _buildPlanAdherence(context),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: _buildMasteryProgress(context),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(6),
                child: _buildWeakAreas(context),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(7),
                child: _buildTopicBreakdown(context),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(8),
                child: _buildBadges(context),
              ),
              const SizedBox(height: 24),
              FocusTraversalOrder(
                order: const NumericFocusOrder(9),
                child: _buildExportSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Icon(Icons.dashboard, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          l10n.studyDashboard,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final l10n = AppLocalizations.of(context)!;
    final stats = _overallStats ?? {};
    final accuracy = stats['accuracy'] ?? 0;
    final totalHours = stats['totalStudyTimeHours'] ?? '0';
    final weeklyActivity = stats['weeklyActivity'] ?? 0;
    final topicsStudied = stats['topicsStudied'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.check_circle,
                value: '$accuracy%',
                label: l10n.accuracy,
                accent: AppTheme.progressColor(accuracy / 100.0, context),
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.timer,
                value: '${totalHours}h',
                label: l10n.studyTime,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.trending_up,
                value: '$weeklyActivity',
                label: l10n.weeklyActivity,
                accent: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.book,
                value: '$topicsStudied',
                label: l10n.topics,
                accent: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trend = _weeklyTrend.take(7).toList();
    final chartData = <String, int>{};
    for (var i = 0; i < trend.length; i++) {
      final item = trend[i];
      final weekLabel = 'W${trend.length - i}';
      chartData[weekLabel] = item['attempts'] as int? ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.weeklyActivity,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        AnimatedBarChart(
          data: chartData.isNotEmpty
              ? chartData
              : {'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0},
          accentColor: Theme.of(context).colorScheme.primary,
          reduceMotion: ref.watch(settingsProvider).reduceMotion,
        ),
      ],
    );
  }

  Widget _buildPlanAdherence(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adherence = _instrumentationData?['planAdherence'] as Map<String, dynamic>?;
    final avgAdherence = adherence?['averageAdherence'] as double? ?? 0.0;
    final weeklyAvg = adherence?['weeklyAdherenceAvg'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.planAdherence,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildAdherenceMetric(context, l10n.overall, '${(avgAdherence * 100).round()}%', avgAdherence)),
                Expanded(child: _buildAdherenceMetric(context, l10n.thisWeek, '${(weeklyAvg * 100).round()}%', weeklyAvg)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceMetric(BuildContext context, String label, String value, double score) {
    final color = score >= 0.7
        ? Theme.of(context).colorScheme.primary
        : score >= 0.4
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMasteryProgress(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot ?? {};
    final totalTopics = snapshot['totalTopics'] ?? 0;
    final masteredTopics = snapshot['masteredTopics'] ?? 0;
    final weakTopics = snapshot['weakTopics'] ?? 0;
    final avgAccuracy = snapshot['averageAccuracy'] ?? 0.0;
    final avgReadiness = snapshot['avgReadiness'] ?? 0.0;
    final masteryPercent = totalTopics > 0 ? masteredTopics / totalTopics : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.masteryOverview,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: _statColumn('$totalTopics', l10n.totalTopics, Theme.of(context).colorScheme.primary)),
                Expanded(child: _statColumn('$masteredTopics', l10n.mastered, Theme.of(context).colorScheme.primary)),
                Expanded(child: _statColumn('${totalTopics - masteredTopics - weakTopics}', l10n.inProgress, Theme.of(context).colorScheme.tertiary)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: masteryPercent,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(masteryPercent)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(context, l10n.accuracy, '${(avgAccuracy * 100).round()}%', AppTheme.progressColor(avgAccuracy, context)),
                _miniStat(context, l10n.readiness, '${(avgReadiness * 100).round()}%', Theme.of(context).colorScheme.tertiary),
                _miniStat(context, l10n.weakAreas, '$weakTopics', Theme.of(context).colorScheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakAreas(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weakStates = _allMastery.where((s) => s.accuracy < 0.6).toList();
    if (weakStates.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  l10n.weakAreasAccuracy,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
            const Divider(),
            ...weakStates.take(5).map((state) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _resolveTopicName(state.topicId),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${(state.accuracy * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    tooltip: l10n.practiceThisTopic,
                    onPressed: () => _practiceWeakArea(state.topicId),
                  ),
                ],
              ),
            )),
            if (weakStates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _practiceAllWeakAreas,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.practiceAllWeakAreas),
                    style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _practiceWeakArea(String topicId) {
    Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(subjectId: '', topicId: topicId),
    );
  }

  void _practiceAllWeakAreas() {
    Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(subjectId: ''),
    );
  }

  Widget _buildTopicBreakdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_allMastery.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              l10n.noTopicDataYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final sorted = List<MasteryState>.from(_allMastery)
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.topicPerformance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            ...sorted.take(10).map((state) => _buildTopicRow(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicRow(MasteryState state) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getProgressColor(state.accuracy);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _resolveTopicName(state.topicId),
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(state.accuracy * 100).round()}%',
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: state.accuracy,
              minHeight: 4,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Row(
            children: [
              Text(
                l10n.attemptsCount(state.totalAttempts),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _masteryLabel(state.masteryLevel),
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _masteryLabel(MasteryLevel level) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return level.name;
    switch (level) {
      case MasteryLevel.novice: return l10n.masteryLevelNovice;
      case MasteryLevel.browsing: return l10n.masteryLevelBrowsing;
      case MasteryLevel.developing: return l10n.masteryLevelDeveloping;
      case MasteryLevel.proficient: return l10n.masteryLevelProficient;
      case MasteryLevel.expert: return l10n.masteryLevelExpert;
    }
  }

  Widget _buildBadges(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_badges.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.achievements, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _badges.map((badge) {
                return Chip(
                  avatar: Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary, size: 18),
                  label: Text(badge['name'] as String? ?? ''),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _exportProgressCSV,
                  icon: const Icon(Icons.download),
                  label: Text(l10n.exportCsv),
                ),
                TextButton.icon(
                  onPressed: _exportSessionHistoryCSV,
                  icon: const Icon(Icons.history),
                  label: Text(l10n.sessionHistory),
                ),
                TextButton.icon(
                  onPressed: _exportInstrumentation,
                  icon: const Icon(Icons.analytics),
                  label: Text(l10n.instrumentation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProgressCSV() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await _tracker.exportProgressCSV(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.progressCsvGenerated(csv.length))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportSessionHistoryCSV() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await _tracker.exportSessionHistoryCSV(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sessionHistoryCsvGenerated(csv.length))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportInstrumentation() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _instrumentation.exportInstrumentationData(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.instrumentationDataExported)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Widget _statColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold, color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
      ],
    );
  }

  Widget _miniStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11,
        )),
      ],
    );
  }

  Color _getProgressColor(double value) {
    return AppTheme.progressColor(value, context);
  }
}
