import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class DueReviewsCard extends StatelessWidget {
  final DueReviewsData data;

  const DueReviewsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            headingLevel: 3,
            child: Row(
              children: [
                Icon(Icons.autorenew, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  children: [
                    TextSpan(
                      text: formatDecimal(
                        data.totalDue.toDouble(),
                        l10n.localeName,
                        minFractionDigits: 0,
                      ),
                    ),
                    WidgetSpan(
                      child: Text(
                        ' ${l10n.dueForReview}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
          if (data.subjectBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...data.subjectBreakdown
                .where((s) => s.dueCount > 0)
                .take(5)
                .map((subject) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8,
                              color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subject.subjectName,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            l10n.dueQuestionsCount(subject.dueCount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ],
      ),
    );
  }
}
