import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'loading_indicator.dart';

class SplashScreen extends StatelessWidget {
  final String? message;

  const SplashScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.appTitle ?? 'StudyKing',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.tagline ?? 'AI-Native Learning Companion',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            const LoadingIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
