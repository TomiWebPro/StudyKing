import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PracticeEmptyState extends StatelessWidget {
  final VoidCallback? onAddSubject;

  const PracticeEmptyState({super.key, this.onAddSubject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.book_online_outlined,
                size: ResponsiveUtils.emptyStateIconSize(context),
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              headingLevel: 1,
              child: Text(
                l10n.noPracticeSessionsYet,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addSubjectsAndQuestionsToStartPracticing,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Step 1: Add a subject (primary action)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddSubject ??
                    () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
                icon: const Icon(Icons.add),
                label: Text(l10n.addSubject),
              ),
            ),
            const SizedBox(height: 8),
            // Step 2: Upload materials (secondary action)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
                icon: const Icon(Icons.upload),
                label: Text(l10n.uploadMaterial),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
