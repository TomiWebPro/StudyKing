import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class EmptyDashboardChecklist extends StatelessWidget {
  final ChecklistProgress progress;

  const EmptyDashboardChecklist({super.key, this.progress = const ChecklistProgress()});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final items = <_ChecklistData>[
      _ChecklistData(
        icon: Icons.library_add,
        title: l10n.addSubject,
        subtitle: l10n.addSubjectDesc,
        onTap: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
        completed: progress.hasSubjects,
      ),
      _ChecklistData(
        icon: Icons.upload_file,
        title: l10n.uploadMaterial,
        subtitle: l10n.uploadMaterialDesc,
        onTap: () => Navigator.pushNamed(context, AppRoutes.upload),
        completed: progress.hasSources,
      ),
      _ChecklistData(
        icon: Icons.quiz,
        title: l10n.takePracticeQuiz,
        subtitle: l10n.takePracticeQuizDesc,
        onTap: () => Navigator.pushNamed(context, AppRoutes.practiceSession,
            arguments: const PracticeSessionArgs(subjectId: '', questionCount: 10)),
        completed: progress.hasPracticeSessions,
      ),
      _ChecklistData(
        icon: Icons.smart_toy,
        title: l10n.scheduleAiTutor,
        subtitle: l10n.scheduleAiTutorDesc,
        onTap: () => Navigator.pushNamed(context, AppRoutes.planner),
        completed: progress.hasScheduledLessons,
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
                Expanded(
                  child: Text(
                    l10n.gettingStarted,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!progress.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${progress.completedCount} / ${progress.totalCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
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
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: item.completed ? null : item.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: item.completed ? 0.6 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: item.completed
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.completed ? Icons.check_circle : item.icon,
                                color: item.completed
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
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
                                      decoration: item.completed ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.completed ? l10n.completed : item.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: item.completed
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!item.completed)
                              Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ChecklistData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool completed;

  const _ChecklistData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.completed = false,
  });
}
