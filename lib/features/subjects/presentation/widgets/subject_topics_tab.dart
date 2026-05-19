import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show topicDependencyRepositoryProvider;
import 'package:studyking/core/widgets/widgets.dart';
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
      final depRepo = ref.read(topicDependencyRepositoryProvider);
      await depRepo.init();
      final depsResult = await depRepo.getAllDependencies();
      if (depsResult.isSuccess) {
        deps = depsResult.data!
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
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Topic>(
      context: context,
      builder: (ctx) => TopicEditDialog(
        title: l10n.addTopicTitle,
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
          SnackBar(content: Text(l10n.topicCreated(result.title))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.topicCreateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _editTopic(Topic topic) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Topic>(
      context: context,
      builder: (ctx) => TopicEditDialog(
        title: l10n.editTopicTitle,
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
          SnackBar(content: Text(l10n.topicUpdated(result.title))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.topicUpdateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _editDependencies(Topic topic) async {
    final l10n = AppLocalizations.of(context)!;
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
      final depRepo = ref.read(topicDependencyRepositoryProvider);
      await depRepo.updateTopicDependency(result);
      _updateDownstreamDeps(topic.id, result.prerequisites);
      await _loadTopics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dependenciesUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dependenciesUpdateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateDownstreamDeps(String topicId, List<String> newPrereqs) async {
    final depRepo = ref.read(topicDependencyRepositoryProvider);
    final depsResult = await depRepo.getAllDependencies();
    final existingDeps = depsResult.data ?? [];

    for (final otherId in _topics.map((t) => t.id)) {
      if (otherId == topicId) continue;
      final existingDep = existingDeps.where((d) => d.topicId == otherId).firstOrNull;
      if (existingDep == null) {
        final defaultDep = TopicDependency(topicId: otherId);
        await depRepo.updateTopicDependency(defaultDep);
        continue;
      }

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
        await depRepo.updateTopicDependency(
          existingDep.copyWith(downstreamTopics: updatedDownstream),
        );
      }
    }
  }

  Future<void> _deleteTopic(Topic topic) async {
    final l10n = AppLocalizations.of(context)!;

    final dep = _dependencies.where((d) => d.topicId == topic.id).firstOrNull;
    final downstreamCount = dep?.downstreamTopics.length ?? 0;

    String warning = l10n.deleteTopicConfirm(topic.title);
    if (downstreamCount > 0) {
      warning += '\n\n${l10n.downstreamTopicWarning(downstreamCount)}';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTopicTitle),
        content: Text(warning),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final topicRepo = ref.read(topicRepositoryProvider);
      await topicRepo.delete(topic.id);

      final depRepo = ref.read(topicDependencyRepositoryProvider);
      final depsResult = await depRepo.getAllDependencies();
      final existingDeps = depsResult.data ?? [];

      for (final other in _topics) {
        if (other.id == topic.id) continue;
        final existingDep = existingDeps.where((d) => d.topicId == other.id).firstOrNull;
        if (existingDep == null) continue;
        final updated = existingDep.copyWith(
          prerequisites: existingDep.prerequisites.where((id) => id != topic.id).toList(),
          downstreamTopics: existingDep.downstreamTopics.where((id) => id != topic.id).toList(),
        );
        await depRepo.updateTopicDependency(updated);
      }

      final subjectRepoResult = await ref.read(subjectsRepositoryProvider.future);
      await subjectRepoResult.removeTopicFromSubject(widget.subjectId, topic.id);

      await _loadTopics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.topicDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.topicDeleteFailed(e.toString()))),
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
      return const LoadingIndicator();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.topicCountTemplate(_topics.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l10n.addTopicTooltip,
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
                if (prereqCount > 0) subtitleParts.add(l10n.prerequisitesCount(prereqCount));
                if (downstreamCount > 0) subtitleParts.add(l10n.downstreamCount(downstreamCount));
                if (topic.parentId != null) subtitleParts.add(l10n.hasParent);

                final indentation = dep != null && dep.prerequisites.isNotEmpty
                    ? dep.prerequisites.length
                    : 0;

                return Card(
                  key: ValueKey(topic.id),
                  margin: EdgeInsets.only(bottom: 4, left: indentation * 16.0),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dep != null && dep.prerequisites.isNotEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: Icon(Icons.subdirectory_arrow_right,
                                size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                            ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    ),
                    title: Row(
                      children: [
                        if (dep != null && dep.prerequisites.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: Icon(Icons.lock_outline, size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          ),
                        Flexible(
                          child: Text(topic.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            )),
                        ),
                      ],
                    ),
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
                        PopupMenuItem(value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, size: 18),
                            title: Text(l10n.editTopicTitle),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(value: 'dependencies',
                          child: ListTile(
                            leading: Icon(Icons.account_tree, size: 18),
                            title: Text(l10n.dependenciesNav),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 18,
                              color: theme.colorScheme.error),
                            title: Text(l10n.delete,
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
