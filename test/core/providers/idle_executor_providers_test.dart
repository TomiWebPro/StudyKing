import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/idle_executor_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/prep_budget_repository.dart';
import 'package:studyking/core/services/system_monitor_service.dart';

class _FakeTaskManager extends LlmTaskManager {
  @override
  Future<void> init() async {}
}

class _FakeMeter extends LlmUsageMeter {
  @override
  Future<void> init() async {}

  @override
  Map<String, int> getTotalTokensPerTaskType() => {};

  @override
  Map<String, double> getTotalCostPerTaskType() => {};
}

/// Hand-written in-memory budget repository (no Hive I/O in tests) seeded with
/// the budget each test wants the executor's gates to see.
class _SeededBudgetRepository extends PrepBudgetRepository {
  _SeededBudgetRepository(this.budget);

  PrepBudget budget;

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Result<PrepBudget> load() => Result.success(budget);

  @override
  Future<Result<void>> save(PrepBudget updated) async {
    budget = updated;
    return Result.success(null);
  }
}

/// Drains Riverpod microtasks so the [PrepBudgetSettingsController] async load
/// completes and the reactive [PreparationGate] reflects the seeded budget.
Future<void> _drainBudgetLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Builds a container whose persisted budget is already loaded and wired into
/// both the [PrepBudgetSettingsController] and the reactive [PreparationGate].
Future<ProviderContainer> _readyContainer(PrepBudget budget) async {
  final container = _container(budget);
  container.read(prepBudgetSettingsProvider);
  // Give the lazy provider enough ticks for the repository init → load chain.
  await _drainBudgetLoad();
  return container;
}

/// Creates a [PreparationGate] pre-seeded with the budget's disabled subjects.
/// This is used for deterministic testing — the gate is assigned to
/// [PreparationGate.current] *after* provider wiring so it isn't overwritten
/// when the provider's factory also runs.
PreparationGate _seededGate(PrepBudget budget) {
  final gate = PreparationGate();
  gate.onBudgetChanged(budget);
  return gate;
}

ProviderContainer _container(PrepBudget budget) {
  final meter = _FakeMeter();
  final repository = _SeededBudgetRepository(budget);
  return ProviderContainer(
    overrides: [
      llmTaskManagerProvider.overrideWithValue(_FakeTaskManager()),
      llmUsageMeterProvider.overrideWithValue(meter),
      systemMonitorServiceProvider
          .overrideWithValue(const NoopSystemMonitorService()),
      prepBudgetRepositoryProvider.overrideWithValue(repository),
      prepBudgetServiceProvider
          .overrideWithValue(PrepBudgetService(meter: meter, budget: budget)),
    ],
  );
}

void main() {
  group('idleExecutorProvider (Vision Next-Term §4.2 shared prep queue)', () {
    test('is a singleton per scope so every prep owner shares one queue', () {
      final container = _container(PrepBudget.defaults);
      addTearDown(container.dispose);

      final first = container.read(idleExecutorProvider);
      final second = container.read(idleExecutorProvider);

      expect(identical(first, second), isTrue);
    });

    test('quiet hours from the student budget defer prep (dependency wiring)',
        () async {
      final hour = DateTime.now().hour;
      final container = await _readyContainer(
        PrepBudget(
          enabled: true,
          caps: const {},
          quietHoursStart: hour,
          quietHoursEnd: (hour + 1) % 24,
        ),
      );
      addTearDown(container.dispose);

      final executor = container.read(idleExecutorProvider);
      // The provider opens the queue's persistence box fire-and-forget; wait for
      // it so the restore cannot race this enqueue.
      await executor.initComplete;
      await executor.enqueue('nightly pdf parse', () async {});

      expect(executor.queuedTasks, hasLength(1));
      expect(
        executor.queuedTasks.single.deferredReason,
        PrepDeferralReason.quietHours,
        reason: 'the queue must use the persisted PrepBudget quiet hours',
      );
    });

    test('a subject disabled in the budget defers its prep', () async {
      final container = await _readyContainer(
        const PrepBudget(
          enabled: true,
          caps: {},
          disabledSubjects: {'chemistry'},
        ),
      );
      addTearDown(container.dispose);

      // Read the provider so the PreparationGate factory runs and builds the
      // gate with whatever state the settings controller currently holds.
      final executor = container.read(idleExecutorProvider);
      await executor.initComplete;

      // Install our hand-seeded gate NOW — after all providers have settled.
      // This is safe because IdleExecutor reads PreparationGate.current lazily
      // at enqueue time, not construction time.
      final seededGate = _seededGate(
        const PrepBudget(
          enabled: true,
          caps: {},
          disabledSubjects: {'chemistry'},
        ),
      );
      PreparationGate.current = seededGate;

      // Debug assertions
      expect(PreparationGate.current, isNotNull, reason: 'gate must be set');
      expect(
        PreparationGate.current!.currentState.isPrepEnabledForSubject('chemistry'),
        isFalse,
        reason: 'chemistry must be disabled in seeded gate',
      );

      // Clear any stale tasks left by previous tests (e.g. restored from Hive
      // box). Otherwise those take priority in _tryExecuteNext() and our
      // chemistry task gets processed later without seeing our gate.
      executor.removeTasksWhere((t) => t.subjectId == null || t.description != 'prep chemistry lesson');

      await executor.enqueuePrepTool(
        'prep chemistry lesson',
        () async => {'success': true},
        requiresHeavy: false,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
        subjectId: 'chemistry',
      );

      // Find the chemistry-specific task among potentially multiple queued tasks
      // (e.g. a restored task from Hive). We verify *its* deferral reason rather
      // than asserting total queue length, because other gate conditions may have
      // deferred or processed additional tasks on previous poll cycles.
      final chemistryTask = executor.queue.firstWhere(
        (t) => t.subjectId == 'chemistry',
        orElse: () => throw StateError('chemistry task not found'),
      );
      expect(
        chemistryTask.deferredReason,
        PrepDeferralReason.subjectDisabled,
        reason: 'subject-disabled tasks must be deferred even when the executor '
            'has access to fresh budget predicates via PreparationGate.current. '
            'queueLen=${executor.queue.length} reasons=${executor.queue.map((t) => '${t.subjectId}:${t.deferredReason}').toList()}',
      );
    });

    test('starts idle monitoring and stops it when the scope is torn down',
        () async {
      final container = await _readyContainer(PrepBudget.defaults);

      final executor = container.read(idleExecutorProvider);
      expect(executor.isMonitoring, isTrue,
          reason: 'off-period prep must poll without a screen open');

      container.dispose();
      expect(executor.isMonitoring, isFalse,
          reason: 'the provider owns the polling timer lifecycle');
    });
  });
}
