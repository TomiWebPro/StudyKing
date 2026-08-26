import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Displays per-syllabus progress. When [selectedSubjectId] is provided it
/// shows only that syllabus' breakdown; otherwise it lists every syllabus.
class SyllabusBreakdownCard extends StatelessWidget {
  final List<SyllabusBreakdown> breakdowns;
  final String? selectedSubjectId;

  const SyllabusBreakdownCard({
    super.key,
    required this.breakdowns,
    this.selectedSubjectId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (breakdowns.isEmpty) return const SizedBox.shrink();

    final visible = selectedSubjectId == null
        ? breakdowns
        : breakdowns.where((b) => b.subjectId == selectedSubjectId).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          headingLevel: 3,
          child: Text(
            l10n.syllabusBreakdownTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        ...visible.map((b) => _buildRow(context, l10n, b)).toList(),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    AppLocalizations l10n,
    SyllabusBreakdown b,
  ) {
    final theme = Theme.of(context);
    final completion = b.completionPercent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.subjectTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatPercent(completion * 100, l10n.localeName,
                    minFractionDigits: 0, maxFractionDigits: 0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.progressColor(completion, context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.progressColor(completion, context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _metric(context, l10n.syllabusCompletion,
                  '${(completion * 100).round()}%'),
              _metric(
                context,
                l10n.accuracy,
                formatPercent(b.accuracy * 100, l10n.localeName,
                    minFractionDigits: 0, maxFractionDigits: 0),
              ),
              _metric(context, l10n.syllabusWeakCount, '${b.weakTopics}'),
              _metric(
                context,
                l10n.studyTime,
                formatHours(b.studyHours * 3600, l10n.localeName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
