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

/// Drains the [PrepBudgetSettingsController] async load so the executor
/// provider is built with the seeded budget instead of the defaults.
Future<void> _drainBudgetLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
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

/// Builds a container whose persisted budget is already loaded, so the queue
/// provider wires the seeded gates (providers are lazy: the settings
/// controller must be read before draining its async load).
Future<ProviderContainer> _readyContainer(PrepBudget budget) async {
  final container = _container(budget);
  container.read(prepBudgetSettingsProvider);
  await _drainBudgetLoad();
  return container;
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
      // ignore: avoid_print
      print('DBG1 exec=${identityHashCode(executor)} container=${identityHashCode(container)}');
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

      final executor = container.read(idleExecutorProvider);
      // The provider opens the queue's persistence box fire-and-forget; wait for
      // it so the restore cannot race this enqueue.
      await executor.initComplete;
      // ignore: avoid_print
      print('DBG2 exec=${identityHashCode(executor)} container=${identityHashCode(container)}');
      await executor.enqueuePrepTool(
        'prep chemistry lesson',
        () async => {'success': true},
        requiresHeavy: false,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
        subjectId: 'chemistry',
      );

      // ignore: avoid_print
      print('DBG2 budgetEnabled=${container.read(prepBudgetSettingsProvider).isPrepEnabledForSubject('chemistry')} '
          'same=${identical(container.read(idleExecutorProvider), executor)} '
          'len=${executor.queue.length} running=${executor.queue.map((t) => t.isRunning)} '
          'completed=${executor.queue.map((t) => t.isCompleted)} '
          'reason=${executor.queue.map((t) => t.deferredReason)}');
      expect(
        executor.queuedTasks.single.deferredReason,
        PrepDeferralReason.subjectDisabled,
        reason: 'per-subject opt-in must defer prep for a paused syllabus',
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
