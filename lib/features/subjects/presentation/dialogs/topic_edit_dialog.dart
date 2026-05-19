import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class TopicEditDialog extends StatefulWidget {
  final String title;
  final Topic? topic;
  final List<Topic> existingTopics;
  final List<TopicDependency> existingDependencies;

  const TopicEditDialog({
    super.key,
    required this.title,
    this.topic,
    required this.existingTopics,
    required this.existingDependencies,
  });

  @override
  State<TopicEditDialog> createState() => _TopicEditDialogState();
}

class _TopicEditDialogState extends State<TopicEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _syllabusController;
  late String _parentId;
  late int _sortOrder;

  bool get _isEditing => widget.topic != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic?.title ?? '');
    _descriptionController = TextEditingController(text: widget.topic?.description ?? '');
    _syllabusController = TextEditingController(text: widget.topic?.syllabusText ?? '');
    _parentId = widget.topic?.parentId ?? '';
    _sortOrder = widget.topic?.sortOrder ?? widget.existingTopics.length;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _syllabusController.dispose();
    super.dispose();
  }

  Topic _buildTopic() {
    return Topic(
      id: _isEditing ? widget.topic!.id : IdGenerator.generate('topic'),
      subjectId: _isEditing ? widget.topic!.subjectId : '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      syllabusText: _syllabusController.text.trim(),
      parentId: _parentId.isNotEmpty ? _parentId : null,
      sortOrder: _sortOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.topicTitleLabel,
                hintText: l10n.topicTitleHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.topicDescriptionLabel,
                hintText: l10n.topicDescriptionHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _syllabusController,
              decoration: InputDecoration(
                labelText: l10n.syllabusTextLabel,
                hintText: l10n.syllabusTextHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (widget.existingTopics.any((t) => t.parentId == null && t.id != widget.topic?.id)) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _parentId.isEmpty ? null : _parentId,
                decoration: InputDecoration(
                  labelText: l10n.parentTopic,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(l10n.rootTopic)),
                  ...widget.existingTopics
                    .where((t) => t.id != widget.topic?.id)
                    .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.title),
                    )),
                ],
                onChanged: (v) => setState(() => _parentId = v ?? ''),
              ),
            ],
            if (_isEditing) ...[
              const SizedBox(height: 16),
              Text(l10n.sortOrderValue(_sortOrder),
                style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(context, _buildTopic());
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
