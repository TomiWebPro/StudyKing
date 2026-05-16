import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_sheet_template.dart';

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
    return PracticeSheetTemplate(
      title: l10n.selectTopic,
      children: topics.map((topic) => Semantics(
        label: '${l10n.selectTopic} $topic',
        child: ListTile(
          leading: const Icon(Icons.topic),
          title: Text(topic),
          onTap: () {
            Navigator.pop(context);
            onTopicSelected(topic);
          },
        ),
      )).toList(),
    );
  }

  static Future<void> show(BuildContext context, {
    required List<String> topics,
    required void Function(String) onTopicSelected,
  }) {
    return PracticeSheetTemplate.show(
      context,
      title: AppLocalizations.of(context)!.selectTopic,
      children: topics.map((topic) => Semantics(
        label: '${AppLocalizations.of(context)!.selectTopic} $topic',
        child: ListTile(
          leading: const Icon(Icons.topic),
          title: Text(topic),
          onTap: () {
            Navigator.pop(context);
            onTopicSelected(topic);
          },
        ),
      )).toList(),
    );
  }
}
