import 'package:flutter/material.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class BadgesCard extends StatelessWidget {
  final List<BadgeDisplay> badges;

  const BadgesCard({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (badges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.noBadgesYet,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.keepPracticingToUnlock,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Semantics(
              headingLevel: 3,
              child: Text(l10n.achievements, style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: badges.map((badge) {
            return Chip(
              avatar: Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary, size: 18),
              label: Text(badge.name),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
      ],
    );
  }
}
