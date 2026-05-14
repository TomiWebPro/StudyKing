import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SubjectPracticeTab extends StatelessWidget {
  final VoidCallback onStartPractice;
  final VoidCallback onStartSpacedRepetition;

  const SubjectPracticeTab({
    super.key,
    required this.onStartPractice,
    required this.onStartSpacedRepetition,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: ResponsiveUtils.screenPadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow, size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text(
            l10n.practiceMode,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.practiceModes,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Semantics(
            label: l10n.startPractice,
            child: FilledButton.icon(
              onPressed: onStartPractice,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startPractice),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: l10n.practiceMode,
            child: OutlinedButton.icon(
              onPressed: onStartSpacedRepetition,
              icon: const Icon(Icons.repeat),
              label: Text(l10n.practiceMode),
            ),
          ),
        ],
      ),
    );
  }
}
