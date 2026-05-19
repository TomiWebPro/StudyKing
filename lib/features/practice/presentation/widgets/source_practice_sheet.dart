import 'package:flutter/material.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/routes/app_router.dart';
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
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            Text(
              l10n.practiceBySource,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
            Text(
              l10n.practiceBySourceDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
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
                    final cs = Theme.of(context).colorScheme;
                    final statusColor = source.status == ProcessingStatus.completed
                        ? cs.primary
                        : source.status == ProcessingStatus.failed
                            ? cs.error
                            : cs.tertiary;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          source.status == ProcessingStatus.failed
                              ? Icons.error_outline
                              : Icons.source,
                          color: source.status == ProcessingStatus.failed
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(source.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _statusLabel(source.status, l10n),
                                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (source.questionCount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  l10n.questionsCount(source.questionCount),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing:                           PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'view_details') {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.sourceDetail, arguments: source.id);
                          } else if (value == 'select') {
                            Navigator.pop(context);
                            onSourceSelected(source.id, source.title);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'select',
                            child: Text(l10n.practiceAction),
                          ),
                          PopupMenuItem(
                            value: 'view_details',
                            child: Text(l10n.viewDetailsAction),
                          ),
                        ],
                      ),
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

String _statusLabel(ProcessingStatus status, AppLocalizations l10n) {
  switch (status) {
    case ProcessingStatus.pending:
      return l10n.pending;
    case ProcessingStatus.extracting:
      return l10n.extracting;
    case ProcessingStatus.classifying:
      return l10n.processing;
    case ProcessingStatus.generatingQuestions:
      return l10n.generatingQuestions;
    case ProcessingStatus.validating:
      return l10n.validating;
    case ProcessingStatus.completed:
      return l10n.completed;
    case ProcessingStatus.failed:
      return l10n.failed;
  }
}

class SourceItemData {
  final String id;
  final String title;
  final int questionCount;
  final ProcessingStatus status;

  const SourceItemData({
    required this.id,
    required this.title,
    required this.questionCount,
    this.status = ProcessingStatus.completed,
  });
}
