import 'package:flutter/material.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/services/study_progress_tracker.dart';
import '../../../core/services/instrumentation_service.dart';
import '../../../core/data/repositories/attempt_repository.dart';
import '../../../core/data/models/mastery_state_model.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/animated_bar_chart.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../../practice/presentation/practice_session_screen.dart';
import '../../practice/presentation/practice_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String studentId;
  final MasteryGraphService masteryService;

  const DashboardScreen({
    super.key,
    required this.studentId,
    required this.masteryService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StudyProgressTracker _tracker = StudyProgressTracker(
    attemptRepo: AttemptRepository(),
  );
  final InstrumentationService _instrumentation = InstrumentationService();
  final TopicRepository _topicRepo = TopicRepository();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSummaryRow(),
            const SizedBox(height: 24),
            _buildWeeklyChart(context),
            const SizedBox(height: 24),
            _buildPlanAdherence(context),
            const SizedBox(height: 24),
            _buildMasteryProgress(context),
            const SizedBox(height: 24),
            _buildWeakAreas(context),
            const SizedBox(height: 24),
            _buildTopicBreakdown(context),
            const SizedBox(height: 24),
            _buildBadges(context),
            const SizedBox(height: 24),
            _buildExportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.dashboard, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Study Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
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
                label: 'Accuracy',
                accent: accuracy >= 80
                    ? Colors.green
                    : accuracy >= 60 ? Colors.orange : Colors.red,
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.timer,
                value: '${totalHours}h',
                label: 'Study Time',
                accent: Colors.blue,
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.trending_up,
                value: '$weeklyActivity',
                label: 'Weekly Activity',
                accent: Colors.teal,
              ),
            ),
            SizedBox(
              width: narrow ? (constraints.maxWidth - 12) / 2 : 160,
              child: MetricCard(
                icon: Icons.book,
                value: '$topicsStudied',
                label: 'Topics',
                accent: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
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
                'Weekly Activity',
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
        ),
      ],
    );
  }

  Widget _buildPlanAdherence(BuildContext context) {
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
                  'Plan Adherence',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildAdherenceMetric(context, 'Overall', '${(avgAdherence * 100).round()}%', avgAdherence)),
                Expanded(child: _buildAdherenceMetric(context, 'This Week', '${(weeklyAvg * 100).round()}%', weeklyAvg)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceMetric(BuildContext context, String label, String value, double score) {
    final color = score >= 0.7 ? Colors.green : score >= 0.4 ? Colors.orange : Colors.red;
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
                  'Mastery Overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: _statColumn('$totalTopics', 'Total Topics', Theme.of(context).colorScheme.primary)),
                Expanded(child: _statColumn('$masteredTopics', 'Mastered', Colors.green)),
                Expanded(child: _statColumn('${totalTopics - masteredTopics - weakTopics}', 'In Progress', Colors.orange)),
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
                _miniStat(context, 'Accuracy', '${(avgAccuracy * 100).round()}%', _getProgressColor(avgAccuracy)),
                _miniStat(context, 'Readiness', '${(avgReadiness * 100).round()}%', Colors.teal),
                _miniStat(context, 'Weak Areas', '$weakTopics', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakAreas(BuildContext context) {
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
                const Icon(Icons.warning_amber, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Weak Areas (Accuracy < 60%)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
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
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    tooltip: 'Practice this topic',
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
                    label: const Text('Practice All Weak Areas'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _practiceWeakArea(String topicId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeSessionScreen(
          subjectId: '',
          topicId: topicId,
        ),
      ),
    );
  }

  void _practiceAllWeakAreas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeScreen(),
      ),
    );
  }

  Widget _buildTopicBreakdown(BuildContext context) {
    if (_allMastery.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No topic data yet. Start studying to see your progress!',
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
                  'Topic Performance',
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
                '${state.totalAttempts} attempts',
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
    switch (level) {
      case MasteryLevel.novice: return 'Novice';
      case MasteryLevel.browsing: return 'Browsing';
      case MasteryLevel.developing: return 'Developing';
      case MasteryLevel.proficient: return 'Proficient';
      case MasteryLevel.expert: return 'Expert';
    }
  }

  Widget _buildBadges(BuildContext context) {
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
                Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _badges.map((badge) {
                return Chip(
                  avatar: Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 18),
                  label: Text(badge['name'] as String? ?? ''),
                  backgroundColor: Colors.amber.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
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
                  label: const Text('Export CSV'),
                ),
                TextButton.icon(
                  onPressed: _exportSessionHistoryCSV,
                  icon: const Icon(Icons.history),
                  label: const Text('Session History'),
                ),
                TextButton.icon(
                  onPressed: _exportInstrumentation,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Instrumentation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProgressCSV() async {
    try {
      final csv = await _tracker.exportProgressCSV(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Progress CSV generated (${csv.length} chars)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _exportSessionHistoryCSV() async {
    try {
      final csv = await _tracker.exportSessionHistoryCSV(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session history CSV generated (${csv.length} chars)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _exportInstrumentation() async {
    try {
      await _instrumentation.exportInstrumentationData(widget.studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instrumentation data exported')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
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
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
