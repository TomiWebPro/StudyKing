import 'package:flutter/material.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/widgets/metric_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PracticePerformanceCard extends StatelessWidget {
  final FocusSession session;
  final bool compact;

  const PracticePerformanceCard({
    super.key,
    required this.session,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accuracyPercent = session.accuracy * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_outlined, size: compact ? 16 : 18, color: cs.secondary),
            const SizedBox(width: 6),
            Text(
              l10n.practice,
              style: (compact ? theme.textTheme.labelSmall : theme.textTheme.titleSmall)?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        if (compact)
          _buildCompactMetrics(context, cs, l10n, accuracyPercent)
        else
          _buildFullMetrics(context, cs, l10n, accuracyPercent),
        if (session.topicBreakdown.isNotEmpty) ...[
          SizedBox(height: compact ? 8 : 12),
          Text(
            l10n.topicBreakdown,
            style: (compact ? theme.textTheme.labelSmall : theme.textTheme.titleSmall)?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          ...session.topicBreakdown.entries.map((entry) {
            final tp = entry.value;
            final color = tp.accuracyPercent >= 80 ? cs.primary : cs.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: compact ? 6 : 8, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tp.correct}/${tp.total} (${formatPercent(tp.accuracyPercent, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)})',
                      style: compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (tp.masteryDelta != 0.0)
                    Text(
                      '${tp.masteryDelta >= 0 ? "+" : ""}${formatDecimal(tp.masteryDelta * 100, l10n.localeName, minFractionDigits: 1, maxFractionDigits: 1)}%',
                      style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodySmall)?.copyWith(
                        color: tp.masteryDelta >= 0 ? cs.primary : cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
        if (session.masteryChanges.isNotEmpty && !compact) ...[
          SizedBox(height: 8),
          Text(
            l10n.masteryDelta,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          ...session.masteryChanges.entries.map((entry) {
            final delta = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${entry.key}: ${delta >= 0 ? "+" : ""}${formatDecimal(delta * 100, l10n.localeName, minFractionDigits: 1, maxFractionDigits: 1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: delta >= 0 ? cs.primary : cs.error,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildCompactMetrics(BuildContext context, ColorScheme cs, AppLocalizations l10n, double accuracyPercent) {
    return Row(
      children: [
        Expanded(
          child: _miniMetric(context,
            icon: Icons.quiz_outlined,
            value: '${session.questionsAnswered}',
            label: l10n.questionsLabel,
            color: cs.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniMetric(context,
            icon: Icons.check_circle_outline,
            value: '${session.correctAnswers}/${session.questionsAnswered}',
            label: l10n.correct,
            color: accuracyPercent >= 80 ? cs.primary : cs.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniMetric(context,
            icon: Icons.trending_up,
            value: formatPercent(accuracyPercent, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
            label: l10n.accuracy,
            color: accuracyPercent >= 80 ? cs.primary : cs.error,
          ),
        ),
      ],
    );
  }

  Widget _buildFullMetrics(BuildContext context, ColorScheme cs, AppLocalizations l10n, double accuracyPercent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: narrow ? (constraints.maxWidth - 12) / 2 : 140),
              child: MetricCard(
                icon: Icons.quiz_outlined,
                value: '${session.questionsAnswered}',
                label: l10n.questionsLabel,
                accent: cs.secondary,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: narrow ? (constraints.maxWidth - 12) / 2 : 140),
              child: MetricCard(
                icon: Icons.check_circle_outline,
                value: '${session.correctAnswers}/${session.questionsAnswered}',
                label: l10n.correct,
                accent: accuracyPercent >= 80 ? cs.primary : cs.error,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: narrow ? (constraints.maxWidth - 12) / 2 : 140),
              child: MetricCard(
                icon: Icons.trending_up,
                value: formatPercent(accuracyPercent, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                label: l10n.accuracy,
                accent: accuracyPercent >= 80 ? cs.primary : cs.error,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _miniMetric(BuildContext context, {required IconData icon, required String value, required String label, required Color color}) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
