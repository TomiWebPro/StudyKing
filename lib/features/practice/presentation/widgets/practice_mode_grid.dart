import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_card.dart';

class PracticeModeGrid extends StatelessWidget {
  final bool isLoadingDueCounts;
  final Map<String, int> dueCounts;
  final bool hasSubjects;
  final int totalQuestionCount;
  final VoidCallback onQuickPractice;
  final VoidCallback onSpacedRepetition;
  final VoidCallback onTopicFocus;
  final VoidCallback onWeakAreas;

  const PracticeModeGrid({
    super.key,
    required this.isLoadingDueCounts,
    required this.dueCounts,
    required this.hasSubjects,
    this.totalQuestionCount = 0,
    required this.onQuickPractice,
    required this.onSpacedRepetition,
    required this.onTopicFocus,
    required this.onWeakAreas,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.practiceModes,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveUtils.gridCrossAxisCount(context),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: (1.2 / MediaQuery.textScalerOf(context).scale(1.0)).clamp(0.8, 1.5),
          children: [
            PracticeModeCard(
              icon: Icons.flash_on,
              title: l10n.quickPractice,
              subtitle: _getQuickPracticeSubtitle(l10n),
              color: Theme.of(context).colorScheme.primary,
              onTap: totalQuestionCount > 0 ? onQuickPractice : null,
            ),
            PracticeModeCard(
              icon: Icons.schedule,
              title: l10n.spacedRepetition,
              subtitle: _getSpacedRepetitionSubtitle(l10n),
              color: Theme.of(context).colorScheme.tertiary,
              onTap: dueCounts.values.any((c) => c > 0) ? onSpacedRepetition : null,
              badge: () {
                final total = dueCounts.values.fold(0, (a, b) => a + b);
                return total > 0 ? total : null;
              }(),
            ),
            PracticeModeCard(
              icon: Icons.category,
              title: l10n.topicFocus,
              subtitle: l10n.practiceSpecificTopics,
              color: Theme.of(context).colorScheme.secondary,
              onTap: onTopicFocus,
            ),
            PracticeModeCard(
              icon: Icons.bar_chart,
              title: l10n.weakAreas,
              subtitle: l10n.focusOnMistakes,
              color: Theme.of(context).colorScheme.error,
              onTap: hasSubjects ? onWeakAreas : null,
            ),
          ],
        ),
      ],
    );
  }

  String _getQuickPracticeSubtitle(AppLocalizations l10n) {
    if (totalQuestionCount == 0) return l10n.uploadMaterialsToCreateQuestions;
    if (totalQuestionCount < 10) return l10n.questionsCount(totalQuestionCount);
    return l10n.randomQuestions(10);
  }

  String _getSpacedRepetitionSubtitle(AppLocalizations l10n) {
    final totalDue = dueCounts.values.fold(0, (a, b) => a + b);
    if (isLoadingDueCounts) return l10n.comingSoon;
    if (totalDue == 0) return l10n.noReviewsScheduled;
    return l10n.dueQuestionsCount(totalDue);
  }
}
