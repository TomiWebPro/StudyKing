import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class NotFoundScreen extends StatelessWidget {
  final String? message;
  final VoidCallback? onGoToDashboard;

  const NotFoundScreen({super.key, this.message, this.onGoToDashboard});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.search_off,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                headingLevel: 1,
                child: Text(
                  l10n.pageNotFound,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? l10n.pageNotFoundDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onGoToDashboard ?? () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    navigator.pushNamedAndRemoveUntil(
                      AppRoutes.dashboard,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.dashboard),
                label: Text(l10n.goToDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
