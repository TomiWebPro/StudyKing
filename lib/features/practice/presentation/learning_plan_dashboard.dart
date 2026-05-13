import 'package:flutter/material.dart';
import '../../../core/services/personal_learning_plan_service.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/data/models/personal_learning_plan_model.dart';
import '../../../core/data/models/mastery_state_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class LearningPlanDashboard extends StatefulWidget {
  final String studentId;
  final PersonalLearningPlanService planService;
  final MasteryGraphService masteryService;

  const LearningPlanDashboard({
    super.key,
    required this.studentId,
    required this.planService,
    required this.masteryService,
  });

  @override
  State<LearningPlanDashboard> createState() => _LearningPlanDashboardState();
}

class _LearningPlanDashboardState extends State<LearningPlanDashboard> {
  PersonalLearningPlan? _plan;
  List<MasteryState> _weakTopics = [];
  List<String> _atRiskTopicIds = [];
  List<String> _readyToAdvanceTopicIds = [];
  Map<String, dynamic>? _snapshot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final planResult = await widget.planService.generatePlan(widget.studentId);
    if (planResult.isSuccess) {
      setState(() => _plan = planResult.data);
    }

    final weakResult = await widget.masteryService.getWeakTopics(widget.studentId);
    if (weakResult.isSuccess) {
      setState(() => _weakTopics = weakResult.data!);
    }

    final atRiskResult = await widget.planService.getAtRiskTopicIds(widget.studentId);
    if (atRiskResult.isSuccess) {
      setState(() => _atRiskTopicIds = atRiskResult.data!);
    }

    final readyResult = await widget.planService.getReadyToAdvanceTopicIds(widget.studentId);
    if (readyResult.isSuccess) {
      setState(() => _readyToAdvanceTopicIds = readyResult.data!);
    }

    final snapshotResult = await widget.masteryService.getMasterySnapshot(widget.studentId);
    if (snapshotResult.isSuccess) {
      setState(() => _snapshot = snapshotResult.data);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayPlanSection(context),
            const SizedBox(height: 24),
            _buildAtRiskTopicsSection(context),
            const SizedBox(height: 24),
            _buildReadyToAdvanceSection(context),
            const SizedBox(height: 24),
            _buildMasteryOverview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPlanSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayPlan = _plan?.dailyPlans.isNotEmpty == true ? _plan!.dailyPlans.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.todaysPlan,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (todayPlan != null && !todayPlan.isRestDay) ...[
              const Divider(),
              if (todayPlan.focus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    label: Text(todayPlan.focus!),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              Row(
                children: [
                  _buildMetricChip(Icons.help_outline, l10n.questionsCountMetric(todayPlan.targetQuestions)),
                  const SizedBox(width: 8),
                  _buildMetricChip(Icons.timer, l10n.minutesCountMetric(todayPlan.targetMinutes)),
                ],
              ),
              const SizedBox(height: 12),
              ...todayPlan.priorityTopics.map((topic) => _buildTopicTile(topic)),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.noStudyPlanToday),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTopicTile(PlannedTopic topic) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _getPriorityColor(topic.priority).withValues(alpha: 0.2),
        child: Icon(
          Icons.school,
          color: _getPriorityColor(topic.priority),
        ),
      ),
      title: Text(topic.topicTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topic.reason,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (topic.reasons.isNotEmpty)
            Wrap(
              spacing: 4,
              children: topic.reasons.take(2).map((r) => Chip(
                label: Text(r, style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUrgencyIndicator(topic.reviewUrgency),
          const SizedBox(width: 4),
          Text('${topic.estimatedQuestions} Q', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildUrgencyIndicator(double urgency) {
    Color color;
    if (urgency > 0.7) {
      color = Colors.red;
    } else if (urgency > 0.4) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getPriorityColor(double priority) {
    if (priority > 2.0) return Colors.red;
    if (priority > 1.0) return Colors.orange;
    return Colors.green;
  }

  Widget _buildAtRiskTopicsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.atRiskTopics,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_atRiskTopicIds.isNotEmpty)
                  Chip(
                    label: Text('${_atRiskTopicIds.length}'),
                    backgroundColor: Colors.red.shade100,
                  ),
              ],
            ),
            const Divider(),
            if (_weakTopics.isEmpty && _atRiskTopicIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.noAtRiskTopics),
              )
            else
              ..._weakTopics.take(5).map((state) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _buildMasteryIcon(state.masteryLevel),
                title: Text(state.topicId),
                subtitle: Text(l10n.accuracyLabel('${(state.accuracy * 100).toStringAsFixed(0)}%')),
                trailing: _buildUrgencyIndicator(state.reviewUrgency),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryIcon(MasteryLevel level) {
    IconData icon;
    Color color;

    switch (level) {
      case MasteryLevel.novice:
        icon = Icons.star_border;
        color = Colors.grey;
        break;
      case MasteryLevel.browsing:
        icon = Icons.star_half;
        color = Colors.blue;
        break;
      case MasteryLevel.developing:
        icon = Icons.star;
        color = Colors.orange;
        break;
      case MasteryLevel.proficient:
        icon = Icons.stars;
        color = Colors.green;
        break;
      case MasteryLevel.expert:
        icon = Icons.military_tech;
        color = Colors.purple;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildReadyToAdvanceSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.readyToAdvance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_readyToAdvanceTopicIds.isNotEmpty)
                  Chip(
                    label: Text('${_readyToAdvanceTopicIds.length}'),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
            const Divider(),
            if (_readyToAdvanceTopicIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.keepPracticingToUnlock),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _readyToAdvanceTopicIds.map((topicId) => Chip(
                  avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  label: Text(topicId),
                  backgroundColor: Colors.green.shade50,
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryOverview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalTopics = _snapshot?['totalTopics'] ?? 0;
    final masteredTopics = _snapshot?['masteredTopics'] ?? 0;
    final weakTopics = _snapshot?['weakTopics'] ?? 0;
    final avgAccuracy = _snapshot?['averageAccuracy'] ?? 0.0;
    final avgReadiness = _snapshot?['avgReadiness'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 24),
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
                Expanded(child: _buildOverviewStat(l10n.totalTopicsLabel, totalTopics.toString())),
                Expanded(child: _buildOverviewStat(l10n.masteredLabel, masteredTopics.toString())),
                Expanded(child: _buildOverviewStat(l10n.weakLabel, weakTopics.toString())),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: avgAccuracy,
              backgroundColor: Colors.grey.shade200,
              color: _getProgressColor(avgAccuracy),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.avgAccuracyLabel('${(avgAccuracy * 100).toStringAsFixed(0)}%')),
                Text(l10n.avgReadinessLabel('${(avgReadiness * 100).toStringAsFixed(0)}%')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _getProgressColor(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.orange;
    return Colors.red;
  }
}