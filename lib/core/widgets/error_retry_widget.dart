import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

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
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
