import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SourcePracticeSheet extends StatelessWidget {
  final List<SourceItemData> sources;
  final void Function(String sourceId, String sourceTitle) onSourceSelected;

  const SourcePracticeSheet({
    super.key,
    required this.sources,
    required this.onSourceSelected,
  });

  static void show(
    BuildContext context, {
    required List<SourceItemData> sources,
    required void Function(String sourceId, String sourceTitle) onSourceSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppTheme.bottomSheetShape,
      builder: (context) => SourcePracticeSheet(
        sources: sources,
        onSourceSelected: onSourceSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.practiceBySource,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.practiceBySourceDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (sources.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.noSourcesAvailable,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: sources.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.source,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(source.title),
                      subtitle: Text(
                        l10n.questionsCount(source.questionCount),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        onSourceSelected(source.id, source.title);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SourceItemData {
  final String id;
  final String title;
  final int questionCount;

  const SourceItemData({
    required this.id,
    required this.title,
    required this.questionCount,
  });
}
