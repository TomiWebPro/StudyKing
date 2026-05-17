import 'package:flutter/material.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class WeakAreasCard extends StatelessWidget {
  final List<MasteryState> allMastery;
  final String Function(String) resolveTopicName;

  const WeakAreasCard({
    super.key,
    required this.allMastery,
    required this.resolveTopicName,
  });

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.weakAreasAccuracy,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
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
                      resolveTopicName(state.topicId),
                      style: Theme.of(context).textTheme.bodyMedium,
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
                    onPressed: () => _practiceWeakArea(context, state.topicId),
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
                    onPressed: () => _practiceAllWeakAreas(context),
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

  void _practiceWeakArea(BuildContext context, String topicId) {
    if (topicId.isEmpty) return;
    Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(subjectId: '', topicId: topicId),
    );
  }

  void _practiceAllWeakAreas(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.practiceSession,
      arguments: PracticeSessionArgs(subjectId: ''),
    );
  }
}
