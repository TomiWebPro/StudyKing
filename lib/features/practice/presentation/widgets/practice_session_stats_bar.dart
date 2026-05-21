import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PracticeSessionStatsBar extends StatelessWidget {
  final String? elapsedTime;
  final int correctAnswers;
  final int currentIndex;

  const PracticeSessionStatsBar({
    super.key,
    required this.elapsedTime,
    required this.correctAnswers,
    required this.currentIndex,
  });

  Color _getColorForScore(BuildContext context, double score) {
    final cs = Theme.of(context).colorScheme;
    if (score >= 0.8) return cs.primary;
    if (score >= 0.5) return cs.tertiary;
    return cs.error;
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scoreValue = currentIndex > 0 ? formatPercent(correctAnswers / (currentIndex + 1) * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0) : formatPercent(0, l10n.localeName, minFractionDigits: 0);
    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Semantics(
            label: '${l10n.time}: $elapsedTime',
            child: _buildMiniStat(context, l10n.time, elapsedTime ?? '0:00', Icons.access_time, Theme.of(context).colorScheme.primary),
          ),
          Semantics(
            label: '${l10n.score}: $scoreValue',
            child: _buildMiniStat(context, l10n.score, scoreValue, Icons.star, _getColorForScore(context, currentIndex > 0 ? correctAnswers / (currentIndex + 1) : 0)),
          ),
          Semantics(
            label: '${l10n.correct}: ${formatDecimal(correctAnswers.toDouble(), l10n.localeName)}',
            child: _buildMiniStat(context, l10n.correct, formatDecimal(correctAnswers.toDouble(), l10n.localeName), Icons.check_circle, Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
