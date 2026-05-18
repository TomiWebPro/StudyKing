import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class TopicDependencyDialog extends StatefulWidget {
  final Topic topic;
  final List<Topic> allTopics;
  final TopicDependency? dependency;

  const TopicDependencyDialog({
    super.key,
    required this.topic,
    required this.allTopics,
    this.dependency,
  });

  @override
  State<TopicDependencyDialog> createState() => _TopicDependencyDialogState();
}

class _TopicDependencyDialogState extends State<TopicDependencyDialog> {
  late List<String> _selectedPrerequisites;
  late double _masteryThreshold;
  late bool _isRequired;
  late double _syllabusWeight;

  @override
  void initState() {
    super.initState();
    _selectedPrerequisites = List.from(widget.dependency?.prerequisites ?? []);
    _masteryThreshold = widget.dependency?.masteryThreshold ?? 0.8;
    _isRequired = widget.dependency?.isRequired ?? true;
    _syllabusWeight = widget.dependency?.syllabusWeight ?? 1.0;
  }

  List<Topic> get _availablePrerequisites =>
      widget.allTopics.where((t) => t.id != widget.topic.id).toList();

  TopicDependency _buildDependency() {
    return TopicDependency(
      topicId: widget.topic.id,
      prerequisites: _selectedPrerequisites,
      downstreamTopics: widget.dependency?.downstreamTopics ?? [],
      masteryThreshold: _masteryThreshold,
      isRequired: _isRequired,
      syllabusWeight: _syllabusWeight,
      sortOrder: widget.dependency?.sortOrder ?? widget.topic.sortOrder,
      parentTopicId: widget.topic.parentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('${widget.topic.title} — Dependencies'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prerequisites',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_availablePrerequisites.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No other topics available for prerequisites.',
                    style: theme.textTheme.bodySmall),
                )
              else
                ..._availablePrerequisites.map((t) => CheckboxListTile(
                  dense: true,
                  title: Text(t.title, style: theme.textTheme.bodyMedium),
                  subtitle: Text(t.description.isNotEmpty ? t.description : 'No description',
                    style: theme.textTheme.bodySmall),
                  value: _selectedPrerequisites.contains(t.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedPrerequisites.add(t.id);
                      } else {
                        _selectedPrerequisites.remove(t.id);
                      }
                    });
                  },
                )),
              const Divider(),
              Text('Mastery Threshold: ${(_masteryThreshold * 100).round()}%',
                style: theme.textTheme.bodyMedium),
              Slider(
                value: _masteryThreshold,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(_masteryThreshold * 100).round()}%',
                onChanged: (v) => setState(() => _masteryThreshold = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                dense: true,
                title: const Text('Required Topic'),
                subtitle: Text(_isRequired
                  ? 'Student must master this topic'
                  : 'Optional topic — can be skipped',
                  style: theme.textTheme.bodySmall),
                value: _isRequired,
                onChanged: (v) => setState(() => _isRequired = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Syllabus Weight: ${_syllabusWeight.toStringAsFixed(1)}',
                      style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              Slider(
                value: _syllabusWeight,
                min: 0.1,
                max: 3.0,
                divisions: 29,
                label: _syllabusWeight.toStringAsFixed(1),
                onChanged: (v) => setState(() => _syllabusWeight = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _buildDependency()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
