import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/idle_executor_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/llm_tasks/presentation/llm_task_manager_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeMeter extends LlmUsageMeter {
  @override
  Future<void> init() async {}

  @override
  Map<String, int> getTotalTokensPerTaskType() => {};

  @override
  Map<String, double> getTotalCostPerTaskType() => {};
}

class _FakeTaskManager extends LlmTaskManager {
  final List<LlmTask> _tasks = [];

  @override
  List<LlmTask> get tasks => List.unmodifiable(_tasks);

  @override
  List<LlmTask> get activeTasks => _tasks
      .where((t) =>
          t.status == LlmTaskStatus.running || t.status == LlmTaskStatus.queued)
      .toList();

  @override
  Future<void> init() async {}

  @override
  String createTask({
    required String feature,
    required String modelId,
    String? description,
    String? sessionId,
    String? taskType,
  }) {
    final id = 'task_${_tasks.length + 1}';
    _tasks.add(LlmTask(
      id: id,
      feature: feature,
      modelId: modelId,
      startTime: DateTime.now(),
      description: description,
      taskType: taskType,
    ));
    return id;
  }
}

/// Widget-level proof of the Vision Next-Term §4.2 requirement that deferred
/// prep is visible in the task portal ("queued → running → done/failed,
/// retry/cancel") — the inverse of the old behaviour where a deferred job left
/// no trace because no [LlmTask] existed yet.
void main() {
  testWidgets('shows a deferred prep job with its reason and cancel action',
      (tester) async {
    final executor = IdleExecutor(shouldDeferForQuietHours: (_) => true);
    addTearDown(executor.dispose);
    await executor.enqueue('nightly chemistry pdf parse', () async {});

    await tester.pumpWidget(_app(executor: executor));

    expect(find.text('Queued preparation'), findsOneWidget);
    expect(find.text('nightly chemistry pdf parse'), findsOneWidget);
    expect(find.text('Waiting for quiet hours to end'), findsOneWidget);
    expect(find.text('No LLM tasks yet'), findsNothing,
        reason: 'queued prep alone must not show the empty state');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('nightly chemistry pdf parse'), findsNothing);
    expect(executor.queuedTasks, isEmpty);
    expect(find.text('No LLM tasks yet'), findsOneWidget);
  });

  testWidgets('try now runs the deferred job when the gate clears',
      (tester) async {
    var quietHours = true;
    final executor = IdleExecutor(
      shouldDeferForQuietHours: (_) => quietHours,
    );
    addTearDown(executor.dispose);
    await executor.enqueue('pre-generate organic chemistry lesson', () async {});

    await tester.pumpWidget(_app(executor: executor));
    expect(find.text('Waiting for quiet hours to end'), findsOneWidget);

    quietHours = false;
    await tester.tap(find.text('Try now'));
    await tester.pumpAndSettle();

    expect(executor.queuedTasks, isEmpty);
    expect(find.text('Queued preparation'), findsNothing);
  });

  testWidgets('explains budget exhaustion for a paused prep job',
      (tester) async {
    final budget = PrepBudgetService(
      meter: _FakeMeter(),
      budget: const PrepBudget(
        enabled: true,
        caps: {},
      ),
    );
    final executor = IdleExecutor(prepBudgetService: _ExhaustedBudget());
    addTearDown(executor.dispose);

    await executor.enqueuePrepTool(
      'expand chemistry question bank',
      () async => {'success': true},
      requiresHeavy: false,
      feature: 'question_variants',
      taskType: 'question_variants',
      estimatedInputTokens: 4000,
      estimatedOutputTokens: 1000,
    );

    await tester.pumpWidget(_app(executor: executor, budget: budget));

    expect(find.text('expand chemistry question bank'), findsOneWidget);
    expect(
      find.text("Paused — this category's preparation budget is used up"),
      findsOneWidget,
    );
  });
}

Widget _app({required IdleExecutor executor, PrepBudgetService? budget}) {
  final meter = _FakeMeter();
  return ProviderScope(
    overrides: [
      idleExecutorProvider.overrideWithValue(executor),
      llmTaskManagerProvider.overrideWithValue(_FakeTaskManager()),
      prepBudgetServiceProvider.overrideWithValue(
        budget ?? PrepBudgetService(meter: meter, budget: PrepBudget.defaults),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LlmTaskManagerScreen(),
    ),
  );
}

/// Hand-written fake budget gate that always refuses spend, so the executor
/// defers prep with [PrepDeferralReason.budgetExhausted].
class _ExhaustedBudget extends PrepBudgetService {
  _ExhaustedBudget()
      : super(
          meter: _FakeMeter(),
          budget: const PrepBudget(enabled: true, caps: {}),
        );

  @override
  bool canSpend(PrepCategory category, int tokens) => false;

  @override
  int remainingFor(PrepCategory category) => 0;
}
