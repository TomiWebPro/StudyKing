import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/dashboard/providers/dashboard_layout_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: !isCollapsed,
            hint: isCollapsed
                ? AppLocalizations.of(context)!.tapToExpand
                : AppLocalizations.of(context)!.tapToCollapse,
            child: InkWell(
              onTap: () =>
                  ref.read(dashboardLayoutPreferencesProvider.notifier).toggleCollapsed(cardId),
              child: Padding(
                padding: ResponsiveUtils.cardPadding(context),
                child: Row(
                  children: [
                    Expanded(child: title),
                    Tooltip(
                      message: isCollapsed
                          ? AppLocalizations.of(context)!.tapToExpand
                          : AppLocalizations.of(context)!.tapToCollapse,
                      child: Icon(
                        isCollapsed ? Icons.expand_more : Icons.expand_less,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: isCollapsed
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: ResponsiveUtils.cardPadding(context),
                        child: content,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
