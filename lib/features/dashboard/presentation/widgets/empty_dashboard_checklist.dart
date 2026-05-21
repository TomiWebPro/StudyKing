import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class EmptyDashboardChecklist extends StatefulWidget {
  final ChecklistProgress progress;

  const EmptyDashboardChecklist({super.key, this.progress = const ChecklistProgress()});

  @override
  State<EmptyDashboardChecklist> createState() => _EmptyDashboardChecklistState();
}

class _EmptyDashboardChecklistState extends State<EmptyDashboardChecklist> {
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    if (widget.progress.isComplete) {
      _showCelebration = true;
    }
  }

  @override
  void didUpdateWidget(EmptyDashboardChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.progress.isComplete && widget.progress.isComplete) {
      setState(() => _showCelebration = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_showCelebration) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.celebration, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.setupCompleteTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupCompleteDesc,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.suggestedNextActions,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _buildSuggestionChip(context, Icons.quiz, l10n.suggestedPrompts),
              const SizedBox(height: 8),
              _buildSuggestionChip(context, Icons.smart_toy, l10n.scheduleAiTutorDesc),
              const SizedBox(height: 8),
              _buildSuggestionChip(context, Icons.auto_awesome, l10n.mentor),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => setState(() => _showCelebration = false),
                child: Text(l10n.getStarted),
              ),
            ],
          ),
        ),
      );
    }

    final items = <_ChecklistData>[
      _ChecklistData(
        icon: Icons.library_add,
        title: l10n.addSubject,
        subtitle: l10n.addSubjectDesc,
        stepNumber: 1,
        onTap: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
        completed: widget.progress.hasSubjects,
      ),
      _ChecklistData(
        icon: Icons.upload_file,
        title: l10n.uploadMaterial,
        subtitle: l10n.uploadMaterialDesc,
        hint: l10n.configureApiKey,
        stepNumber: 2,
        onTap: () => Navigator.pushNamed(context, AppRoutes.upload),
        completed: widget.progress.hasSources,
      ),
      _ChecklistData(
        icon: Icons.quiz,
        title: l10n.startPracticing,
        subtitle: l10n.takePracticeQuizDesc,
        hint: l10n.uploadMaterial,
        stepNumber: 3,
        onTap: () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
        completed: widget.progress.hasPracticeSessions,
      ),
      _ChecklistData(
        icon: Icons.smart_toy,
        title: l10n.scheduleAiTutor,
        subtitle: l10n.scheduleAiTutorDesc,
        hint: l10n.generatePlan,
        stepNumber: 4,
        onTap: () => Navigator.pushNamed(context, AppRoutes.planner),
        completed: widget.progress.hasScheduledLessons,
      ),
    ];

    final firstIncompleteIndex = items.indexWhere((item) => !item.completed);

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
                if (!widget.progress.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.progress.completedCount} / ${widget.progress.totalCount}',
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
              final isFirstIncomplete = i == firstIncompleteIndex;
              final showStepNumber = item.completed;
              final showHint = !item.completed && item.hint != null && isFirstIncomplete;

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
                      child: Container(
                        decoration: isFirstIncomplete
                            ? BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        padding: EdgeInsets.all(isFirstIncomplete ? 8 : 4),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: item.completed
                                    ? theme.colorScheme.primaryContainer
                                    : isFirstIncomplete
                                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                        : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.completed ? Icons.check_circle : item.icon,
                                color: item.completed
                                    ? theme.colorScheme.primary
                                    : isFirstIncomplete
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (showStepNumber)
                                        Padding(
                                          padding: const EdgeInsetsDirectional.only(end: 6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${item.stepNumber}',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Flexible(
                                        child: Text(
                                          item.title,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            decoration: item.completed ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (isFirstIncomplete)
                                        Padding(
                                          padding: const EdgeInsetsDirectional.only(end: 6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              l10n.nextStep,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          item.completed ? l10n.completed : item.subtitle,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: item.completed
                                                ? theme.colorScheme.primary
                                                : isFirstIncomplete
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (showHint && item.hint != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              item.hint!,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
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
                                color: isFirstIncomplete
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
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

  Widget _buildSuggestionChip(BuildContext context, IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? hint;
  final int stepNumber;
  final VoidCallback onTap;
  final bool completed;

  const _ChecklistData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hint,
    required this.stepNumber,
    required this.onTap,
    this.completed = false,
  });
}
