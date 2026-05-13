import 'package:flutter/material.dart';
import '../../../core/services/llm_task_manager.dart';
import '../../../l10n/generated/app_localizations.dart';

class LlmTaskManagerScreen extends StatefulWidget {
  final LlmTaskManager taskManager;

  const LlmTaskManagerScreen({super.key, required this.taskManager});

  @override
  State<LlmTaskManagerScreen> createState() => _LlmTaskManagerScreenState();
}

class _LlmTaskManagerScreenState extends State<LlmTaskManagerScreen> {
  @override
  void initState() {
    super.initState();
    widget.taskManager.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    widget.taskManager.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = widget.taskManager.tasks;
    final activeTasks = widget.taskManager.activeTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.llmTaskManager),
        actions: [
          if (activeTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(l10n.activeCount(activeTasks.length)),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(l10n.noLlmTasksYet,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[tasks.length - 1 - index];
                return _buildTaskCard(context, task);
              },
            ),
    );
  }

  Widget _buildTaskCard(BuildContext context, LlmTask task) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = switch (task.status) {
      LlmTaskStatus.running => Colors.blue,
      LlmTaskStatus.done => Colors.green,
      LlmTaskStatus.failed => Colors.red,
      LlmTaskStatus.cancelled => Colors.orange,
      LlmTaskStatus.queued => Colors.grey,
    };

    final statusIcon = switch (task.status) {
      LlmTaskStatus.running => Icons.sync,
      LlmTaskStatus.done => Icons.check_circle,
      LlmTaskStatus.failed => Icons.error,
      LlmTaskStatus.cancelled => Icons.cancel,
      LlmTaskStatus.queued => Icons.hourglass_empty,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.feature,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status.name,
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.modelLabel(task.modelId),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(l10n.startedLabel(_formatTime(task.startTime)),
                style: Theme.of(context).textTheme.bodySmall),
            if (task.endTime != null)
              Text(l10n.endedLabel(_formatTime(task.endTime!)),
                  style: Theme.of(context).textTheme.bodySmall),
            if (task.tokensUsed > 0)
              Text(l10n.tokensAndCost(task.tokensUsed, '\$${task.estimatedCost.toStringAsFixed(4)}'),
                  style: Theme.of(context).textTheme.bodySmall),
            if (task.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(task.error!,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error)),
              ),
            if (task.status == LlmTaskStatus.running || task.status == LlmTaskStatus.queued)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => widget.taskManager.cancelTask(task.id),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: Text(l10n.cancelTask),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
