import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class EmptyDashboardChecklist extends StatelessWidget {
  const EmptyDashboardChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final items = [
      ChecklistItem(
        icon: Icons.library_add,
        title: l10n.addSubject,
        subtitle: l10n.addSubjectDesc,
      ),
      ChecklistItem(
        icon: Icons.upload_file,
        title: l10n.uploadMaterial,
        subtitle: l10n.uploadMaterialDesc,
      ),
      ChecklistItem(
        icon: Icons.quiz,
        title: l10n.takePracticeQuiz,
        subtitle: l10n.takePracticeQuizDesc,
      ),
      ChecklistItem(
        icon: Icons.smart_toy,
        title: l10n.scheduleAiTutor,
        subtitle: l10n.scheduleAiTutorDesc,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n.gettingStarted,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.gettingStartedDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: i < items.length - 1 ? 16 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ChecklistItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const ChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
