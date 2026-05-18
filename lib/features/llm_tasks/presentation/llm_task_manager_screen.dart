import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/llm_providers.dart';
import '../../../core/services/llm_task_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/number_format_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/generated/app_localizations.dart';

class LlmTaskManagerScreen extends ConsumerStatefulWidget {
  const LlmTaskManagerScreen({super.key});

  @override
  ConsumerState<LlmTaskManagerScreen> createState() => _LlmTaskManagerScreenState();
}

class _LlmTaskManagerScreenState extends ConsumerState<LlmTaskManagerScreen> {
  LlmTaskManager? _taskManager;

  @override
  void initState() {
    super.initState();
    _taskManager = ref.read(llmTaskManagerProvider);
    _taskManager!.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    _taskManager?.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taskManager = ref.watch(llmTaskManagerProvider);
    final tasks = taskManager.tasks;
    final activeTasks = taskManager.activeTasks;
    final hasTokenData = tasks.any((t) => t.tokensUsed > 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.llmTaskManager),
        actions: [
          if (activeTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
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
          : Column(
              children: [
                if (hasTokenData) _buildTokenUsageMeter(context, tasks, l10n),
                if (hasTokenData) const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: ResponsiveUtils.listPadding(context),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[tasks.length - 1 - index];
                      return _buildTaskCard(context, task, l10n, taskManager);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTokenUsageMeter(
      BuildContext context, List<LlmTask> tasks, AppLocalizations l10n) {
    final totalTokens =
        tasks.fold<int>(0, (sum, t) => sum + (t.tokensUsed > 0 ? t.tokensUsed : 0));
    final totalCost = tasks.fold<double>(
        0, (sum, t) => sum + (t.estimatedCost > 0 ? t.estimatedCost : 0));
    final completedTasks = tasks.where((t) => t.status == LlmTaskStatus.done).length;
    final failedTasks = tasks.where((t) => t.status == LlmTaskStatus.failed).length;

    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.tokenUsageSummary,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ResponsiveUtils.breakpointOf(context).isMobile)
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width -
                      ResponsiveUtils.cardPadding(context).horizontal - 32) / 2,
                  child: _buildUsageStat(context, l10n.totalTokens, _formatTokens(totalTokens, l10n.localeName)),
                ),
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width -
                      ResponsiveUtils.cardPadding(context).horizontal - 32) / 2,
                  child: _buildUsageStat(context, l10n.totalCost, formatCurrency(totalCost, l10n.localeName, minFractionDigits: 4, maxFractionDigits: 4)),
                ),
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width -
                      ResponsiveUtils.cardPadding(context).horizontal - 32) / 2,
                  child: _buildUsageStat(context, l10n.done, '$completedTasks'),
                ),
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width -
                      ResponsiveUtils.cardPadding(context).horizontal - 32) / 2,
                  child: _buildUsageStat(context, l10n.failed, '$failedTasks'),
                ),
              ],
            )
          else
            Row(
              children: [
                _buildUsageStat(context, l10n.totalTokens, _formatTokens(totalTokens, l10n.localeName)),
                const SizedBox(width: 16),
                _buildUsageStat(context, l10n.totalCost, formatCurrency(totalCost, l10n.localeName, minFractionDigits: 4, maxFractionDigits: 4)),
                const SizedBox(width: 16),
                _buildUsageStat(context, l10n.done, '$completedTasks'),
                const SizedBox(width: 16),
                _buildUsageStat(context, l10n.failed, '$failedTasks'),
              ],
            ),
          if (totalTokens > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completedTasks > 0
                    ? completedTasks / tasks.length
                    : 0,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageStat(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatTokens(int tokens, String localeName) {
    return formatCompactNumber(tokens, localeName);
  }

  Widget _buildTaskCard(BuildContext context, LlmTask task, AppLocalizations l10n, LlmTaskManager taskManager) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = AppTheme.statusColor(task.status, context);

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
        padding: ResponsiveUtils.cardPadding(context),
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.memory, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l10n.modelLabel(task.modelId),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(l10n.startedLabel(_formatTime(task.startTime)),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (task.endTime != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.access_time_filled, size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(l10n.endedLabel(_formatTime(task.endTime!)),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
            if (task.tokensUsed > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.token, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.tokensLabel(_formatTokens(task.tokensUsed, l10n.localeName)),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.primary),
                    ),
                    if (task.estimatedCost > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.attach_money, size: 14, color: cs.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        formatCurrency(task.estimatedCost, l10n.localeName, minFractionDigits: 4, maxFractionDigits: 4),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.tertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (task.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 14, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(task.error!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            if (task.status == LlmTaskStatus.failed)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => _retryTask(task, taskManager),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.retry),
                ),
              ),
            if (task.status == LlmTaskStatus.running || task.status == LlmTaskStatus.queued)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => taskManager.cancelTask(task.id),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: Text(l10n.cancelTask),
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _retryTask(LlmTask task, LlmTaskManager taskManager) {
    taskManager.retryTask(task.id);
  }

  String _formatTime(DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    return DateFormat.Hms(l10n.localeName).format(dt);
  }
}
