import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class WeakAreasCard extends ConsumerWidget {
  static final Logger _logger = const Logger('WeakAreasCard');
  final List<MasteryState> allMastery;
  final String Function(String) resolveTopicName;
  final void Function(String topicId)? onTopicTap;

  const WeakAreasCard({
    super.key,
    required this.allMastery,
    required this.resolveTopicName,
    this.onTopicTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final weakStates = allMastery.where((s) => s.accuracy < 0.6).toList();
    if (weakStates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            l10n.noWeakAreasFound,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              headingLevel: 3,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.weakAreasAccuracy,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
            const Divider(),
            ...weakStates.take(5).map((state) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onTopicTap != null ? () => onTopicTap!(state.topicId) : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        resolveTopicName(state.topicId),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  Text(
                    formatPercent(state.accuracy * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    tooltip: l10n.practiceThisTopic,
                    onPressed: () => _practiceWeakArea(context, ref, state.topicId),
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
                    onPressed: () => _practiceAllWeakAreas(context, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.practiceAllWeakAreas),
                    style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  void _practiceWeakArea(BuildContext context, WidgetRef ref, String topicId) async {
    if (topicId.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final questionRepo = ref.read(questionRepositoryProvider);
      final allQResult = await questionRepo.getAll();
      final allQuestions = allQResult.data ?? [];
      final topicQuestions = allQuestions.where((q) => q.topicId == topicId).toList();
      if (topicQuestions.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noQuestionsAvailable)));
        return;
      }
      final scorer = ref.read(readinessScorerProvider);
      final scored = await scorer.scoreQuestions(topicQuestions);
      final orderedIds = scored.map((s) => s.question.id).toList();
      final subjectId = topicQuestions.first.subjectId;
      if (!context.mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.practiceSession,
        arguments: PracticeSessionArgs(
          subjectId: subjectId,
          topicId: topicId,
          orderedQuestionIds: orderedIds,
          questionCount: orderedIds.length,
        ),
      );
    } catch (e) {
      _logger.w('Failed to practice weak area', e);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.somethingWentWrong)));
    }
  }

  void _practiceAllWeakAreas(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final questionRepo = ref.read(questionRepositoryProvider);
      final allQResult = await questionRepo.getAll();
      final allQuestions = allQResult.data ?? [];
      final weakTopicIds = allMastery
          .where((s) => s.accuracy < 0.6)
          .map((s) => s.topicId)
          .toSet();
      final weakQuestions = allQuestions
          .where((q) => weakTopicIds.contains(q.topicId))
          .toList();
      if (weakQuestions.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noWeakAreasQuestions)));
        return;
      }
      final scorer = ref.read(readinessScorerProvider);
      final scored = await scorer.scoreQuestions(weakQuestions);
      final orderedIds = scored.map((s) => s.question.id).toList();
      final subjectId = weakQuestions.first.subjectId;
      if (!context.mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.practiceSession,
        arguments: PracticeSessionArgs(
          subjectId: subjectId,
          orderedQuestionIds: orderedIds,
          questionCount: orderedIds.length,
        ),
      );
    } catch (e) {
      _logger.w('Failed to practice weak areas', e);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.somethingWentWrong)));
    }
  }
}
