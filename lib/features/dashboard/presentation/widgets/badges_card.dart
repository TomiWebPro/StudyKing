import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class BadgesCard extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const BadgesCard({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (badges.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.achievements, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges.map((badge) {
                return Chip(
                  avatar: Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary, size: 18),
                  label: Text(badge['name'] as String? ?? ''),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
