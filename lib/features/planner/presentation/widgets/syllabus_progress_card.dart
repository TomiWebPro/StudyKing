import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SyllabusProgressCard extends StatelessWidget {
  final String studentId;
  final SyllabusGoal goal;
  final List<MasteryState>? masteryStatesOverride;
  final int? totalTopicsOverride;

  const SyllabusProgressCard({
    super.key,
    required this.studentId,
    required this.goal,
    this.masteryStatesOverride,
    this.totalTopicsOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (masteryStatesOverride != null && totalTopicsOverride != null) {
      return _buildContent(context, masteryStatesOverride!, totalTopicsOverride!);
    }
    return FutureBuilder<_ProgressData>(
      future: _loadProgress(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(l10n);
        }
        final data = snapshot.data;
        if (data == null) {
          return _buildEmpty(context);
        }
        return _buildContent(context, data.masteryStates, data.totalTopics);
      },
    );
  }

  Future<_ProgressData> _loadProgress() async {
    final topicRepo = TopicRepository();
    await topicRepo.init();
    final topicsResult = await topicRepo.getBySubject(goal.subjectId);
    final allTopics = topicsResult.data ?? [];
    final totalTopics = allTopics.length;

    final masteryRepo = MasteryGraphRepository();
    await masteryRepo.init();
    final masteryResult = await masteryRepo.getAllMasteryStates(studentId);
    final states = masteryResult.data ?? [];

    return _ProgressData(masteryStates: states, totalTopics: totalTopics);
  }

  Widget _buildLoading(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.loadingSyllabusProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppLocalizations.of(context)!.noDataUploaded,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<MasteryState> masteryStates, int totalTopics) {
    final l10n = AppLocalizations.of(context)!;
    final subjectMasteryStates = masteryStates.where((s) => s.topicId.isNotEmpty).toList();

    final masteredCount = subjectMasteryStates
        .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index)
        .length;

    final progress = totalTopics > 0 ? masteredCount / totalTopics : 0.0;

    return Card(
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.subjectTitle.isNotEmpty
                        ? '${goal.subjectTitle} ${l10n.syllabusLabel}'
                        : l10n.syllabusLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    masteredCount == 0
                        ? 'No progress yet'
                        : '${l10n.mastered} $masteredCount / $totalTopics',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  formatPercent(progress * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(context, progress),
                ),
              ),
            ),
            if (masteredCount == 0 && totalTopics > 0) ...[
              const SizedBox(height: 12),
              Text(
                'You haven\'t practiced ${goal.subjectTitle} yet. '
                'Start by uploading materials or scheduling a lesson.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.upload_file, size: 16),
                    label: Text(l10n.uploadMaterials),
                    onPressed: () {},
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.quiz, size: 16),
                    label: const Text('Practice Questions'),
                    onPressed: () {},
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.school, size: 16),
                    label: const Text('Start Lesson'),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(BuildContext context, double value) {
    if (value >= 0.8) return Theme.of(context).colorScheme.primary;
    if (value >= 0.5) return Theme.of(context).colorScheme.tertiary;
    return Theme.of(context).colorScheme.error;
  }
}

class _ProgressData {
  final List<MasteryState> masteryStates;
  final int totalTopics;

  const _ProgressData({required this.masteryStates, required this.totalTopics});
}
