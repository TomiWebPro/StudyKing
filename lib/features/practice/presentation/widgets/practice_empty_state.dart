import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

class PracticeEmptyState extends StatelessWidget {
  final VoidCallback? onAddSubject;

  const PracticeEmptyState({super.key, this.onAddSubject});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: l10n.noPracticeSessionsYet,
              excludeSemantics: true,
              child: Icon(
                Icons.book_online_outlined,
                size: ResponsiveUtils.emptyStateIconSize(context),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noPracticeSessionsYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addSubjectsAndQuestionsToStartPracticing,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: l10n.addSubject,
              child: ElevatedButton.icon(
                onPressed: onAddSubject ?? () {
                  Navigator.pushNamed(context, AppRoutes.subjectSelection);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addSubject),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.upload);
              },
              child: Text(l10n.uploadMaterial),
            ),
          ],
        ),
      ),
    );
  }
}
