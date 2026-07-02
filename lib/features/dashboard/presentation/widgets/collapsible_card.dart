import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// A plain [Card] wrapper that handles async loading/error/data states.
///
/// Unlike the previous collapsible version, this widget has no title header,
/// no expand/collapse toggle, and no Hive-backed collapse preferences.
/// Each body widget is expected to provide its own heading if needed.
class DashboardCard extends StatelessWidget {
  final Widget body;
  final Widget? loadingSkeleton;
  final Widget? errorWidget;
  final AsyncValue? asyncValue;
  final VoidCallback? onRetry;

  const DashboardCard({
    super.key,
    required this.body,
    this.loadingSkeleton,
    this.errorWidget,
    this.asyncValue,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (asyncValue != null) {
      content = asyncValue!.when(
        loading: () => loadingSkeleton ?? const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => errorWidget ?? Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.somethingWentWrong,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(AppLocalizations.of(context)!.retry),
                  ),
              ],
            ),
          ),
        ),
        data: (_) => body,
      );
    } else {
      content = body;
    }

    return Card(
      child: Padding(
        padding: ResponsiveUtils.cardPadding(context),
        child: content,
      ),
    );
  }
}
