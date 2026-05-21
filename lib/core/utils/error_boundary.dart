import 'package:flutter/material.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails details)? fallbackBuilder;

  const ErrorBoundary({super.key, required this.child, this.fallbackBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  static final Logger _logger = const Logger('ErrorBoundary');
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    _error = null;
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(_error!);
      }
      return _AppErrorWidget(
        details: _error!,
        onRetry: () => setState(() => _error = null),
      );
    }
    return FlutterErrorOnBuildWidget(
      onError: (details) {
        _logger.w('Error caught by ErrorBoundary', details.exception);
        setState(() => _error = details);
      },
      child: widget.child,
    );
  }
}

class FlutterErrorOnBuildWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<FlutterErrorDetails> onError;

  const FlutterErrorOnBuildWidget({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<FlutterErrorOnBuildWidget> createState() => _FlutterErrorOnBuildWidgetState();
}

class _FlutterErrorOnBuildWidgetState extends State<FlutterErrorOnBuildWidget> {
  @override
  Widget build(BuildContext context) {
    try {
      return widget.child;
    } catch (e, stack) {
      final details = FlutterErrorDetails(exception: e, stack: stack);
      widget.onError(details);
      return const SizedBox.shrink();
    }
  }
}

class AppErrorWidgetBuilder {
  static Widget build(FlutterErrorDetails details) {
    return _AppErrorWidget(details: details);
  }
}

class _AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  final VoidCallback? onRetry;

  const _AppErrorWidget({required this.details, this.onRetry});

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
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
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
