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

/// Hand-written fake meter: returns an injected per-task-type token map so the
/// prep-vs-live split is deterministic, with no Hive I/O (per AGENTS.md).
class _FakeMeter extends LlmUsageMeter {
  final Map<String, int> _perTaskType;
  final Map<String, double> _perTaskTypeCost;

  _FakeMeter(this._perTaskType, [Map<String, double>? cost])
      : _perTaskTypeCost = cost ??
            {for (final k in _perTaskType.keys) k: 0.0};

  @override
  Future<void> init() async {}

  @override
  Map<String, int> getTotalTokensPerTaskType() => _perTaskType;

  @override
  Map<String, double> getTotalCostPerTaskType() => _perTaskTypeCost;
}

/// Minimal hand-written task manager fake exposing a pre-seeded task list.
class _FakeTaskManager extends LlmTaskManager {
  final List<LlmTask> _tasks = [];
  final List<VoidCallback> _listeners = [];
  int _counter = 0;

  _FakeTaskManager();

  void addCompleted({
    required String feature,
    required int tokensUsed,
    String? taskType,
  }) {
    _tasks.add(LlmTask(
      id: 'task_${++_counter}',
      feature: feature,
      modelId: 'gpt-4o',
      status: LlmTaskStatus.done,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      tokensUsed: tokensUsed,
      taskType: taskType,
    ));
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  @override
  List<LlmTask> get tasks => List.unmodifiable(_tasks);

  @override
  List<LlmTask> get activeTasks => _tasks
      .where((t) =>
          t.status == LlmTaskStatus.running ||
          t.status == LlmTaskStatus.queued)
      .toList();

  @override
  Future<void> init() async {}

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}

Widget _buildApp({
  required _FakeMeter meter,
  required _FakeTaskManager manager,
  PrepBudget? budget,
}) {
  return ProviderScope(
    overrides: [
      Provider<LlmUsageMeter>((ref) => meter),
      llmTaskManagerProvider.overrideWithValue(manager),
      prepBudgetServiceProvider.overrideWithValue(
        PrepBudgetService(
          meter: meter,
          budget: budget ?? PrepBudget.defaults,
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LlmTaskManagerScreen(),
    ),
  );
}

void main() {
  group('LlmTaskManagerScreen - Token allocation', () {
    testWidgets('shows prep-vs-live ratio with prep-dominant badge',
        (tester) async {
      final manager = _FakeTaskManager();
      // One completed task with tokens => hasTokenData true => meter renders.
      manager.addCompleted(feature: 'tutor', tokensUsed: 2500);
      final meter = _FakeMeter(
        const {'pdf_ingestion': 7500, 'teaching': 2500},
      );

      await tester.pumpWidget(_buildApp(meter: meter, manager: manager));
      await tester.pumpAndSettle();

      expect(find.text('Token allocation'), findsOneWidget);
      // prep = 7500 / 10000 = 75%, live = 2500 / 10000 = 25%
      expect(find.textContaining('75%'), findsOneWidget);
      expect(find.textContaining('25%'), findsOneWidget);
      expect(find.text('Prep dominates'), findsOneWidget);
    });

    testWidgets('shows live-dominant badge when live exceeds prep',
        (tester) async {
      final manager = _FakeTaskManager();
      manager.addCompleted(feature: 'tutor', tokensUsed: 9000);
      final meter = _FakeMeter(
        const {'pdf_ingestion': 1000, 'teaching': 4000},
      );

      await tester.pumpWidget(_buildApp(meter: meter, manager: manager));
      await tester.pumpAndSettle();

      expect(find.text('Live dominates'), findsOneWidget);
      // live = 4000 / 5000 = 80%, prep = 1000 / 5000 = 20%
      expect(find.textContaining('80%'), findsOneWidget);
      expect(find.textContaining('20%'), findsOneWidget);
    });

    testWidgets('hides allocation row when the meter has no tokens',
        (tester) async {
      final manager = _FakeTaskManager();
      manager.addCompleted(feature: 'tutor', tokensUsed: 500);
      final meter = _FakeMeter(const {});

      await tester.pumpWidget(_buildApp(meter: meter, manager: manager));
      await tester.pumpAndSettle();

      expect(find.text('Token allocation'), findsNothing);
      expect(find.text('Prep dominates'), findsNothing);
      expect(find.text('Live dominates'), findsNothing);
    });

    testWidgets('percentages partition to 100 across the prep/live split',
        (tester) async {
      final manager = _FakeTaskManager();
      manager.addCompleted(feature: 'tutor', tokensUsed: 100);
      final meter = _FakeMeter(const {
        'lesson_prep': 4000,
        'embeddings': 4000,
        'teaching': 1000,
        'mentor': 1000,
      });

      await tester.pumpWidget(_buildApp(meter: meter, manager: manager));
      await tester.pumpAndSettle();

      // prep = 8000 / 10000 = 80%, live = 2000 / 10000 = 20%
      expect(find.textContaining('80%'), findsOneWidget);
      expect(find.textContaining('20%'), findsOneWidget);
      expect(find.text('Token allocation'), findsOneWidget);
    });
  });
}
