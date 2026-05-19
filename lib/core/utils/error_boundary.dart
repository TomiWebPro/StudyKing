import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return child;
      },
    );
  }
}

class AppErrorWidgetBuilder {
  static Widget build(FlutterErrorDetails details) {
    return _AppErrorWidget(details: details);
  }
}

class _AppErrorWidget extends StatefulWidget {
  final FlutterErrorDetails details;

  const _AppErrorWidget({required this.details});

  @override
  State<_AppErrorWidget> createState() => _AppErrorWidgetState();
}

class _AppErrorWidgetState extends State<_AppErrorWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.somethingWentWrong ?? 'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.errorWithMessage('') ?? 'An unexpected error occurred.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
