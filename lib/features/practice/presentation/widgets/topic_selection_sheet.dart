import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_sheet_template.dart';

class TopicSelectionSheet extends StatelessWidget {
  final Map<String, String> topics;
  final void Function(String topicId) onTopicSelected;

  const TopicSelectionSheet({
    super.key,
    required this.topics,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PracticeSheetTemplate(
      title: l10n.selectTopic,
      children: topics.entries.map((entry) => Semantics(
        label: '${l10n.selectTopic} ${entry.value}',
        child: ListTile(
          leading: const Icon(Icons.topic),
          title: Text(entry.value),
          onTap: () {
            Navigator.pop(context);
            onTopicSelected(entry.key);
          },
        ),
      )).toList(),
    );
  }

  static Future<void> show(BuildContext context, {
    required Map<String, String> topics,
    required void Function(String topicId) onTopicSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: AppTheme.bottomSheetShape,
      builder: (_) => TopicSelectionSheet(
        topics: topics,
        onTopicSelected: onTopicSelected,
      ),
    );
  }
}
