import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_edit_dialog.dart';
import 'package:studyking/features/subjects/presentation/dialogs/topic_dependency_dialog.dart';

class SubjectTopicsTab extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectTopicsTab({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectTopicsTab> createState() => _SubjectTopicsTabState();
}

class _SubjectTopicsTabState extends ConsumerState<SubjectTopicsTab> {
  List<Topic> _topics = [];
  List<TopicDependency> _dependencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    try {
      final topicRepo = ref.read(topicRepositoryProvider);
      await topicRepo.init();
      final topicsResult = await topicRepo.getBySubject(widget.subjectId);
      final topics = topicsResult.data ?? [];

      List<TopicDependency> deps = [];
      final allResult = await topicRepo.getAll();
      if (allResult.isSuccess) {
        deps = allResult.data!
            .whereType<TopicDependency>()
            .where((d) => topics.any((t) => t.id == d.topicId))
            .toList();
      }

      if (mounted) {
        setState(() {
          _topics = topics;
          _dependencies = deps;
          _isLoading = false;
        });
      }
    } catch (e) {
      const Logger('SubjectTopicsTab').e('Failed to load topics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTopic() async {
    final result = await showDialog<Topic>(
      context: context,
      builder: (ctx) => TopicEditDialog(
        title: 'Add Topic',
        existingTopics: _topics,
        existingDependencies: _dependencies,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final topicRepo = ref.read(topicRepositoryProvider);
      await topicRepo.create(result);

      final subjectRepoResult = await ref.read(subjectsRepositoryProvider.future);
      await subjectRepoResult.addTopicToSubject(widget.subjectId, result.id);

      await _loadTopics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Topic "${result.title}" created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create topic: $e')),
        );
      }
    }
  }

  Future<void> _editTopic(Topic topic) async {
    final result = await showDialog<Topic>(
      context: context,
      builder: (ctx) => TopicEditDialog(
        title: 'Edit Topic',
        topic: topic,
        existingTopics: _topics,
        existingDependencies: _dependencies,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final topicRepo = ref.read(topicRepositoryProvider);
      await topicRepo.create(result);
      await _loadTopics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Topic "${result.title}" updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update topic: $e')),
        );
      }
    }
  }

  Future<void> _editDependencies(Topic topic) async {
    final dep = _dependencies.where((d) => d.topicId == topic.id).firstOrNull;
    final result = await showDialog<TopicDependency>(
      context: context,
      builder: (ctx) => TopicDependencyDialog(
        topic: topic,
        allTopics: _topics,
        dependency: dep,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final depBox = await Hive.openBox(HiveBoxNames.topics);
      await depBox.put(result.topicId, result);
      _updateDownstreamDeps(topic.id, result.prerequisites);
      await _loadTopics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dependencies updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update dependencies: $e')),
        );
      }
    }
  }

  Future<void> _updateDownstreamDeps(String topicId, List<String> newPrereqs) async {
    final depBox = await Hive.openBox(HiveBoxNames.topics);
    final allItems = depBox.values.toList();
    final existingDeps = allItems.whereType<TopicDependency>().toList();

    for (final otherId in _topics.map((t) => t.id)) {
      if (otherId == topicId) continue;
      final existingDep = existingDeps.where((d) => d.topicId == otherId).firstOrNull;
      if (existingDep == null) continue;

      List<String> updatedDownstream = existingDep.downstreamTopics;
      if (newPrereqs.contains(otherId)) {
        if (!updatedDownstream.contains(topicId)) {
          updatedDownstream = [...updatedDownstream, topicId];
        }
      } else {
        updatedDownstream = updatedDownstream.where((id) => id != topicId).toList();
      }
      if (updatedDownstream.length != existingDep.downstreamTopics.length ||
          !updatedDownstream.every((id) => existingDep.downstreamTopics.contains(id))) {
        await depBox.put(otherId, existingDep.copyWith(downstreamTopics: updatedDownstream));
      }
    }
  }

  Future<void> _deleteTopic(Topic topic) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Delete "${topic.title}"?\nThis will remove it from all dependency lists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final topicRepo = ref.read(topicRepositoryProvider);
      await topicRepo.delete(topic.id);

      final depBox = await Hive.openBox(HiveBoxNames.topics);
      final allItems = depBox.values.toList();
      final existingDeps = allItems.whereType<TopicDependency>().toList();

      for (final other in _topics) {
        if (other.id == topic.id) continue;
        final existingDep = existingDeps.where((d) => d.topicId == other.id).firstOrNull;
        if (existingDep == null) continue;
        final updated = existingDep.copyWith(
          prerequisites: existingDep.prerequisites.where((id) => id != topic.id).toList(),
          downstreamTopics: existingDep.downstreamTopics.where((id) => id != topic.id).toList(),
        );
        await depBox.put(other.id, updated);
      }

      final subjectRepoResult = await ref.read(subjectsRepositoryProvider.future);
      await subjectRepoResult.removeTopicFromSubject(widget.subjectId, topic.id);

      await _loadTopics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete topic: $e')),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final topic = _topics.removeAt(oldIndex);
      _topics.insert(newIndex, topic);
    });
    _saveTopicOrder();
  }

  Future<void> _saveTopicOrder() async {
    try {
      final topicRepo = ref.read(topicRepositoryProvider);
      for (var i = 0; i < _topics.length; i++) {
        final updated = _topics[i].copyWith(sortOrder: i);
        await topicRepo.create(updated);
      }
    } catch (e) {
      const Logger('SubjectTopicsTab').e('Failed to save topic order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_topics.length} topics',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Topic',
                onPressed: _addTopic,
              ),
            ],
          ),
        ),
        if (_topics.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.topic, size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(l10n.noTopicsAvailable,
                    style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addTopic),
                    onPressed: _addTopic,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _topics.length,
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final dep = _dependencies.where((d) => d.topicId == topic.id).firstOrNull;
                final prereqCount = dep?.prerequisites.length ?? 0;
                final downstreamCount = dep?.downstreamTopics.length ?? 0;

                final subtitleParts = <String>[];
                if (prereqCount > 0) subtitleParts.add('$prereqCount prerequisites');
                if (downstreamCount > 0) subtitleParts.add('$downstreamCount downstream');
                if (topic.parentId != null) subtitleParts.add('Has parent');

                return Card(
                  key: ValueKey(topic.id),
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(topic.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      )),
                    subtitle: subtitleParts.isNotEmpty
                        ? Text(subtitleParts.join(' · '), style: theme.textTheme.bodySmall)
                        : null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editTopic(topic);
                            break;
                          case 'dependencies':
                            _editDependencies(topic);
                            break;
                          case 'delete':
                            _deleteTopic(topic);
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, size: 18),
                            title: Text('Edit Topic'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(value: 'dependencies',
                          child: ListTile(
                            leading: Icon(Icons.account_tree, size: 18),
                            title: Text('Dependencies'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 18,
                              color: theme.colorScheme.error),
                            title: Text('Delete',
                              style: TextStyle(color: theme.colorScheme.error)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
