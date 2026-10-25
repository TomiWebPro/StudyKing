import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/llm_providers.dart'
    show llmTaskManagerProvider, llmUsageMeterProvider, systemMonitorServiceProvider;
import 'package:studyking/core/providers/prep_budget_providers.dart'
    show prepBudgetServiceProvider, prepBudgetSettingsProvider;
import 'package:studyking/core/services/llm_agent/idle_executor.dart';

/// The single off-period preparation queue (Vision Next-Term §4.1–§4.3).
///
/// Every prep producer shares this one [IdleExecutor]:
/// - bulk ingestion of uploaded materials ([bulkIngestionServiceProvider]),
/// - prep tools the mentor defers through `AgentLoop` (PDF → knowledge base,
///   question variants, lesson pre-generation, mastery refresh),
/// - post-lesson work enqueued by the tutor.
///
/// Sharing one queue is what makes Vision Next-Term §4.2 true: "All prep jobs
/// are visible tasks (queued → running → done/failed, retry/cancel) — the
/// existing task-manager portal is the UI." With per-owner executors, prep
/// enqueued by the agent lived in a queue the portal could never read, so
/// deferred work was invisible (issue: prep-deferred-jobs-invisible-in-portal).
///
/// Quiet-hours and per-subject opt-in predicates come from the persisted
/// [PrepBudget], and [PrepBudgetService] is injected so the executor can defer
/// over-budget prep before creating a parent `LlmTask` (§4.2/§4.4).
final idleExecutorProvider = Provider<IdleExecutor>((ref) {
  final taskManager = ref.watch(llmTaskManagerProvider);
  final systemMonitor = ref.watch(systemMonitorServiceProvider);
  final prepBudget = ref.watch(prepBudgetSettingsProvider);
  final prepBudgetService = ref.watch(prepBudgetServiceProvider);
  final usageMeter = ref.watch(llmUsageMeterProvider);
  final executor = IdleExecutor(
    llmTaskManager: taskManager,
    studentId: 'default',
    systemMonitor: systemMonitor,
    shouldDeferForQuietHours: (now) => prepBudget.shouldDeferForQuietHours(now),
    isPrepEnabledForSubject: (subjectId) =>
        prepBudget.isPrepEnabledForSubject(subjectId),
    usageMeter: usageMeter,
    prepBudgetService: prepBudgetService,
  );
  executor.init();
  executor.startIdleMonitoring();
  ref.onDispose(executor.dispose);
  return executor;
});
