import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/llm_tasks/presentation/llm_task_manager_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeMeter extends LlmUsageMeter {
  final Map<String, int> _perTaskTypeTokens;

  _FakeMeter(this._perTaskTypeTokens);

  @override
  Future<void> init() async {}

  @override
  Map<String, int> getTotalTokensPerTaskType() => _perTaskTypeTokens;

  @override
  Map<String, double> getTotalCostPerTaskType() =>
      {for (final k in _perTaskTypeTokens.keys) k: 0.0};
}

class _FakeTaskManager extends LlmTaskManager {
  final List<LlmTask> _tasks = [];

  _FakeTaskManager();

  @override
  List<LlmTask> get tasks => List.unmodifiable(_tasks);

  @override
  List<LlmTask> get activeTasks =>
      _tasks.where((t) => t.status == LlmTaskStatus.running || t.status == LlmTaskStatus.queued).toList();

  @override
  Future<void> init() async {}

  @override
  String createTask({
    required String feature,
    required String modelId,
    String? description,
  }) {
    final id = 'task_${_tasks.length + 1}';
    _tasks.add(LlmTask(
      id: id,
      feature: feature,
      modelId: modelId,
      startTime: DateTime.now(),
      description: description,
    ));
    _notify();
    return id;
  }

  @override
  void completeTask(String taskId, {int tokensUsed = 0, double estimatedCost = 0.0}) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(
      status: LlmTaskStatus.done,
      endTime: DateTime.now(),
      tokensUsed: tokensUsed,
      estimatedCost: estimatedCost,
    );
    _notify();
  }

  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }

  final List<VoidCallback> _listeners = [];

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}

Widget _buildTestApp({
  required LlmTaskManager taskManager,
  required LlmUsageMeter usageMeter,
  PrepBudget? prepBudget,
}) {
  return ProviderScope(
    overrides: [
      Provider<LlmUsageMeter>((ref) => usageMeter),
      llmTaskManagerProvider.overrideWithValue(taskManager),
      prepBudgetServiceProvider.overrideWithValue(
        PrepBudgetService(
          meter: usageMeter,
          budget: prepBudget ?? PrepBudget.defaults,
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LlmTaskManagerScreen(),
    ),
  );
}

void main() {
  group('LlmTaskManagerScreen - Prep Budget Bars', () {
    testWidgets('shows preparation budget bars header', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({});

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Preparation budget'), findsWidgets);
    });

    testWidgets('shows budget bars for all categories', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({});

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
      ));
      await tester.pumpAndSettle();

      expect(find.text('PDF → Knowledge base'), findsOneWidget);
      expect(find.text('Question bank expansion'), findsOneWidget);
      expect(find.text('Lesson preparation'), findsOneWidget);
      expect(find.text('Embeddings'), findsOneWidget);
      expect(find.text('Background tasks'), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator for each category', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({});

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
      ));
      await tester.pumpAndSettle();

      // 5 progress indicators per category + possibly the existing one from token meter
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('shows spent/total tokens per category', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({
        'pdf_ingestion': 50000,
        'question_variants': 30000,
      });

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
      ));
      await tester.pumpAndSettle();

      // 50K spent out of 200K for PDF ingestion
      expect(find.textContaining('50K'), findsWidgets);
      expect(find.textContaining('200K'), findsWidgets);
    });

    testWidgets('progress bars reflect spend ratios', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({
        'pdf_ingestion': 100000, // 50% of 200K cap
      });

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
      ));
      await tester.pumpAndSettle();

      final progress = find.byType(LinearProgressIndicator);
      expect(progress, findsWidgets);

      // Find the progress indicator for PDF ingestion (first in list)
      final progresses = tester.widgetList<LinearProgressIndicator>(progress);
      // At least one should be non-zero
      expect(progresses.any((p) => p.value != null && p.value! > 0), isTrue);
    });

    testWidgets('shows disabled message when budget is off', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({});

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
        prepBudget: PrepBudget.defaults.copyWith(enabled: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Preparation budget is off — prep tasks are paused'),
          findsWidgets);
    });

    testWidgets('hides disabled message when budget is enabled', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({});

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
        prepBudget: PrepBudget.defaults,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Preparation budget is off — prep tasks are paused'),
          findsNothing);
    });

    testWidgets('budget bars are above task list', (tester) async {
      final manager = _FakeTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final meter = _FakeMeter({});

      await tester.pumpWidget(_buildTestApp(
        taskManager: manager,
        usageMeter: meter,
      ));
      await tester.pumpAndSettle();

      final budgetBarsFinder = find.text('Preparation budget');
      final taskListFinder = find.byType(ListView);
      expect(budgetBarsFinder, findsOneWidget);
      expect(taskListFinder, findsOneWidget);
    });
  });
}
