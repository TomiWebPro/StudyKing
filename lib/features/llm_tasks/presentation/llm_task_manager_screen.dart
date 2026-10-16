import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/llm_tasks/services/llm_task_service.dart';
import 'package:studyking/core/constants/timeouts.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../providers/llm_task_providers.dart';

class LlmTaskManagerScreen extends ConsumerStatefulWidget {
  const LlmTaskManagerScreen({super.key});

  @override
  ConsumerState<LlmTaskManagerScreen> createState() => _LlmTaskManagerScreenState();
}

class _LlmTaskManagerScreenState extends ConsumerState<LlmTaskManagerScreen> {
  LlmTaskService? _taskService;
  final Set<String> _notifiedFailedTaskIds = {};
  bool _inDidChangeDependencies = false;
  String? _selectedTaskType;

  @override
  void initState() {
    super.initState();
    _taskService = ref.read(llmTaskServiceProvider);
    _taskService!.addListener(_onTasksChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inDidChangeDependencies = true;
    _onTasksChanged();
    _inDidChangeDependencies = false;
  }

  @override
  void dispose() {
    _taskService?.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    if (!mounted) return;
    setState(() {});
    final taskService = ref.read(llmTaskServiceProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    for (final task in taskService.getAllTasks()) {
      if (task.status == LlmTaskStatus.failed &&
          task.error != null &&
          _notifiedFailedTaskIds.add(task.id)) {
        if (_inDidChangeDependencies) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final l10n = AppLocalizations.of(context);
            if (l10n == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.aiTaskFailedNotification(task.feature)),
                duration: Timeouts.animationMedium,
                action: SnackBarAction(
                  label: l10n.retry,
                  onPressed: () => taskService.retryTask(task.id),
                ),
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.aiTaskFailedNotification(task.feature)),
              duration: Timeouts.animationMedium,
              action: SnackBarAction(
                label: l10n.retry,
                onPressed: () => taskService.retryTask(task.id),
              ),
            ),
          );
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taskService = ref.watch(llmTaskServiceProvider);
    final tasks = taskService.getAllTasks();
    final activeTasks = taskService.getActiveTasks();
    final hasTokenData = tasks.any((t) => t.tokensUsed > 0);
    final taskManager = ref.watch(llmTaskManagerProvider);
    final budgetService = ref.watch(prepBudgetServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.llmTaskManager),
        actions: [
          // Task-type filter dropdown (Vision Next-Term §4.2)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: _TaskTypeFilterDropdown(
              taskType: _selectedTaskType,
              onChanged: (String? newValue) {
                setState(() => _selectedTaskType = newValue);
              },
              allTasks: tasks,
            ),
          ),
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
                _buildPrepBudgetBars(context, l10n, budgetService),
                const Divider(height: 1),
                if (hasTokenData) _buildTokenUsageMeter(context, tasks, l10n),
                if (hasTokenData) const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: ResponsiveUtils.listPadding(context),
                    itemCount: _filteredTasks(tasks).length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks(tasks)[_filteredTasks(tasks).length - 1 - index];
                      return _buildTaskCard(context, task, l10n, taskManager);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Filters the task list by the selected task-type, if any.
  List<LlmTask> _filteredTasks(List<LlmTask> tasks) {
    if (_selectedTaskType == null) return tasks;
    return tasks.where((t) => t.taskType == _selectedTaskType).toList();
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
                  child: _buildUsageStat(context, l10n.totalCost, formatCurrency(totalCost, l10n.localeName, minFractionDigits: 2, maxFractionDigits: 2)),
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
                Expanded(child: _buildUsageStat(context, l10n.totalTokens, _formatTokens(totalTokens, l10n.localeName))),
                const SizedBox(width: 16),
                Expanded(child: _buildUsageStat(context, l10n.totalCost, formatCurrency(totalCost, l10n.localeName, minFractionDigits: 2, maxFractionDigits: 2))),
                const SizedBox(width: 16),
                Expanded(child: _buildUsageStat(context, l10n.done, '$completedTasks')),
                const SizedBox(width: 16),
                Expanded(child: _buildUsageStat(context, l10n.failed, '$failedTasks')),
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
    return Column(
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
    );
  }

  String _formatTokens(int tokens, String localeName) {
    return formatCompactNumber(tokens, localeName);
  }

  Widget _buildPrepBudgetBars(
    BuildContext context,
    AppLocalizations l10n,
    PrepBudgetService service,
  ) {
    final budget = service.budget;
    final spending = service.spendingByCategory();
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree,
                  size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                l10n.preparationBudget,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (!budget.enabled)
                Icon(Icons.pause, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          if (!budget.enabled) ...[
            Text(
              l10n.prepBudgetDisabled,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ] else ...[
            ...PrepCategory.values.map((category) => _buildBudgetBar(
                context,
                l10n,
                category,
                budget,
                spending[category] ?? 0,
                service.remainingFor(category))),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetBar(
    BuildContext context,
    AppLocalizations l10n,
    PrepCategory category,
    PrepBudget budget,
    int spent,
    int remaining,
  ) {
    final cap = budget.caps[category] ?? 0;
    final spentRatio = cap > 0 ? (spent / cap).clamp(0.0, 1.0) : 0.0;
    final color = spent >= cap
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _prepCategoryLabel(category, l10n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${formatCompactNumber(spent, l10n.localeName)} / ${formatCompactNumber(cap, l10n.localeName)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: spentRatio,
              minHeight: 6,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  String _prepCategoryLabel(PrepCategory category, AppLocalizations l10n) {
    switch (category) {
      case PrepCategory.pdfIngestion:
        return l10n.prepCategoryPdfIngestion;
      case PrepCategory.questionVariants:
        return l10n.prepCategoryQuestionVariants;
      case PrepCategory.lessonPrep:
        return l10n.prepCategoryLessonPrep;
      case PrepCategory.embeddings:
        return l10n.prepCategoryEmbeddings;
      case PrepCategory.background:
        return l10n.prepCategoryBackground;
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.feature,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.taskType != null)
                        Text(
                          'Type: ${task.taskType}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _llmTaskStatusLabel(task.status, l10n),
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
                        formatCurrency(task.estimatedCost, l10n.localeName, minFractionDigits: 2, maxFractionDigits: 4),
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
    return DateFormat.jm(l10n.localeName).format(dt);
  }

  String _llmTaskStatusLabel(LlmTaskStatus status, AppLocalizations l10n) {
    switch (status) {
      case LlmTaskStatus.queued:
        return l10n.llmStatusQueued;
      case LlmTaskStatus.running:
        return l10n.inProgress;
      case LlmTaskStatus.done:
        return l10n.completed;
      case LlmTaskStatus.failed:
        return l10n.failed;
      case LlmTaskStatus.cancelled:
        return l10n.llmStatusCancelled;
    }
  }
}

/// Dropdown to filter the task list by [LlmTask.taskType].
/// Shows "All types" plus one entry per distinct taskType present in [allTasks].
class _TaskTypeFilterDropdown extends StatelessWidget {
  final String? taskType;
  final void Function(String?) onChanged;
  final List<LlmTask> allTasks;

  const _TaskTypeFilterDropdown({
    required this.taskType,
    required this.onChanged,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context) {
    final distinctTypes = allTasks
        .where((t) => t.taskType != null)
        .map((t) => t.taskType!)
        .toSet()
        .toList()
      ..sort();

    final items = <DropdownMenuEntry<String>>[
      const DropdownMenuEntry(value: 'all', label: 'All types'),
      ...distinctTypes.map(
        (t) => DropdownMenuEntry(value: t, label: t),
      ),
    ];

    return DropdownMenu<String>(
      label: const Text('Filter'),
      initialSelection: taskType ?? 'all',
      onSelected: (String? newValue) => onChanged(newValue == 'all' ? null : newValue),
      dropdownMenuEntries: items,
      leadingIcon: const Icon(Icons.filter_alt, size: 20),
    );
  }
}
