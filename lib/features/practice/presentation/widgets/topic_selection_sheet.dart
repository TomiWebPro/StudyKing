import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

class TopicSelectionSheet extends StatelessWidget {
  final List<String> topics;
  final void Function(String) onTopicSelected;

  const TopicSelectionSheet({
    super.key,
    required this.topics,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectTopic,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topics.map((topic) => Semantics(
              label: '${l10n.selectTopic} $topic',
              child: ListTile(
                leading: const Icon(Icons.topic),
                title: Text(topic),
                onTap: () {
                  Navigator.pop(context);
                  onTopicSelected(topic);
                },
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, {
    required List<String> topics,
    required void Function(String) onTopicSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TopicSelectionSheet(
        topics: topics,
        onTopicSelected: onTopicSelected,
      ),
    );
  }
}
