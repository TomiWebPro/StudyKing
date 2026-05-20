import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

class TopicDetailArgs {
  final String topicId;
  final String studentId;

  const TopicDetailArgs({
    required this.topicId,
    required this.studentId,
  });
}

class TopicDetailScreen extends ConsumerWidget {
  final String topicId;
  final String studentId;

  const TopicDetailScreen({
    super.key,
    required this.topicId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final allMasteryAsync = ref.watch(dashboardAllMasteryProvider(studentId));
    final topicNamesAsync = ref.watch(dashboardTopicNamesProvider(studentId));
    final topicName = topicNamesAsync.valueOrNull?[topicId] ?? topicId;

    return Scaffold(
      appBar: AppBar(
        title: Text(topicName),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: l10n.practiceThisTopic,
            onPressed: () => _startPractice(context, ref),
          ),
        ],
      ),
      body: allMasteryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (allMastery) {
          final state = allMastery.where((s) => s.topicId == topicId).firstOrNull;
          if (state == null) {
            return Center(
              child: Text(
                l10n.noTopicDataYet,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return _TopicDetailBody(
            state: state,
            topicName: topicName,
            onPractice: () => _startPractice(context, ref),
          );
        },
      ),
    );
  }

  void _startPractice(BuildContext context, WidgetRef ref) async {
    final masteryService = ref.read(masteryGraphServiceProvider);
    await masteryService.init();
    final allMastery = await ref.read(dashboardAllMasteryProvider(studentId).future);
    final state = allMastery.where((s) => s.topicId == topicId).firstOrNull;
    if (state == null) return;
    final questionRepo = ref.read(questionRepositoryProvider);
    final allQuestions = (await questionRepo.getAll()).data ?? [];
    final topicQuestions = allQuestions.where((q) => q.topicId == topicId).toList();
    if (topicQuestions.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noQuestionsAvailable)),
      );
      return;
    }
    final scorer = ref.read(readinessScorerProvider);
    final scored = await scorer.scoreQuestions(topicQuestions);
    final orderedIds = scored.map((s) => s.question.id).toList();
    if (!context.mounted) return;
    await Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(
        subjectId: topicQuestions.first.subjectId,
        topicId: topicId,
        orderedQuestionIds: orderedIds,
        questionCount: orderedIds.length,
      ),
    );
  }
}

class _TopicDetailBody extends StatelessWidget {
  final MasteryState state;
  final String topicName;
  final VoidCallback onPractice;

  const _TopicDetailBody({
    required this.state,
    required this.topicName,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: ResponsiveUtils.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(context, l10n.accuracy,
              formatPercent(state.accuracy * 100, l10n.localeName, minFractionDigits: 0),
              _accuracyColor(state.accuracy, context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(context, l10n.totalQuestions, '${state.totalAttempts}',
                  _levelColor(state.masteryLevel, context))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(context, l10n.correctAnswers, '${state.correctAttempts}',
                  cs.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(context, l10n.masteryLevel,
                  _masteryLevelLabel(l10n, state.masteryLevel),
                  _levelColor(state.masteryLevel, context))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(context, l10n.currentStreak, '${state.currentStreak}',
                  cs.tertiary)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(context, l10n.bestStreak, '${state.bestStreak}',
                  cs.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(context, l10n.readiness,
                  formatPercent((state.readinessScore * 100).roundToDouble(), l10n.localeName, minFractionDigits: 0),
                  cs.tertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(context, l10n.confidence,
                  formatPercent((state.confidenceTrend * 100).roundToDouble(), l10n.localeName, minFractionDigits: 0),
                  cs.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(context, l10n.forgettingRisk,
                  formatPercent((state.forgettingRisk * 100).roundToDouble(), l10n.localeName, minFractionDigits: 0),
                  cs.error)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBox(context, l10n.reviewUrgency,
                  formatPercent((state.reviewUrgency * 100).roundToDouble(), l10n.localeName, minFractionDigits: 0),
                  state.reviewUrgency > 0.7 ? cs.error : cs.tertiary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context, l10n.lastAttempted,
              formatDate(state.lastAttempt, l10n: l10n)),
          const SizedBox(height: 4),
          _buildInfoRow(context, l10n.lastUpdated,
              formatDate(state.lastUpdated, l10n: l10n)),
          if (state.recentAccuracy.length >= 2) ...[
            const SizedBox(height: 16),
            Text(l10n.accuracyTrend, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildTrendChart(context),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPractice,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.practiceThisTopic),
            ),
          ),
        ],
      ),
    );
  }

  Color _accuracyColor(double accuracy, BuildContext context) {
    return AppTheme.progressColor(accuracy, context);
  }

  Color _levelColor(MasteryLevel level, BuildContext context) {
    return AppTheme.masteryColor(_masteryValue(level), context);
  }

  double _masteryValue(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.novice:
      case MasteryLevel.browsing:
        return 0.0;
      case MasteryLevel.developing:
        return 0.4;
      case MasteryLevel.proficient:
        return 0.7;
      case MasteryLevel.expert:
        return 1.0;
    }
  }

  String _masteryLevelLabel(AppLocalizations l10n, MasteryLevel level) {
    switch (level) {
      case MasteryLevel.novice: return l10n.masteryLevelNovice;
      case MasteryLevel.browsing: return l10n.masteryLevelBrowsing;
      case MasteryLevel.developing: return l10n.masteryLevelDeveloping;
      case MasteryLevel.proficient: return l10n.masteryLevelProficient;
      case MasteryLevel.expert: return l10n.masteryLevelExpert;
    }
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            )),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        )),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final data = state.recentAccuracy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _DetailSparklinePainter(data: data, color: AppTheme.progressColor(state.accuracy, context)),
          ),
        ),
      ),
    );
  }
}

class _DetailSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _DetailSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (data.length - 1);
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DetailSparklinePainter oldDelegate) => data != oldDelegate.data;
}
