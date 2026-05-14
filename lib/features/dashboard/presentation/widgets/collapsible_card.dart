import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/dashboard/providers/dashboard_data_providers.dart';

class CollapsibleCard extends ConsumerWidget {
  final String cardId;
  final Widget title;
  final Widget body;
  final Widget? loadingSkeleton;
  final Widget? errorWidget;
  final AsyncValue? asyncValue;
  final VoidCallback? onRetry;

  const CollapsibleCard({
    super.key,
    required this.cardId,
    required this.title,
    required this.body,
    this.loadingSkeleton,
    this.errorWidget,
    this.asyncValue,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(dashboardLayoutPreferencesProvider);
    final isCollapsed = prefs.isCollapsed(cardId);

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
                  'Something went wrong',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
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
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                ref.read(dashboardLayoutPreferencesProvider.notifier).toggleCollapsed(cardId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: title),
                  Icon(
                    isCollapsed ? Icons.expand_more : Icons.expand_less,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ],
        ],
      ),
    );
  }
}
