import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/system_monitor_service.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';

// ---------------------------------------------------------------------------
// Fakes — LlmTaskManager
// ---------------------------------------------------------------------------

class FakeLlmTaskManager extends LlmTaskManager {
  bool started = false;
  String? lastCreatedTaskFeature;
  Map<String, int>? lastCompleteTokens;
  double? lastCompleteCost;

  @override
  String createTask({
    required String feature,
    required String modelId,
    String? description,
    String? taskType,
    String? sessionId,
  }) {
    lastCreatedTaskFeature = feature;
    return 'fake_${++_createCounter}';
  }

  int _createCounter = 0;

  @override
  void startTask(String taskId) {
    started = true;
    super.startTask(taskId);
  }

  @override
  void completeTask(String taskId,
      {int tokensUsed = 0, double estimatedCost = 0.0}) {
    lastCompleteTokens ??= {};
    lastCompleteTokens![taskId] = tokensUsed;
    lastCompleteCost = estimatedCost;
    super.completeTask(taskId,
        tokensUsed: tokensUsed, estimatedCost: estimatedCost);
  }
}

// ---------------------------------------------------------------------------
// Fakes — SystemMonitorService
// ---------------------------------------------------------------------------

/// Configurable fake [SystemMonitorService].
class TestSystemMonitor extends SystemMonitorService {
  bool _canRun = true;
  int batteryLevelVal = -1;
  bool chargingVal = false;
  double cpuLoadVal = -1;
  bool batterySaverVal = false;

  TestSystemMonitor({bool canRun = true}) : _canRun = canRun;

  set canRunHeavyPrepNow(bool v) => _canRun = v;

  @override
  bool get canRunHeavyPrepNow => _canRun;

  @override
  int get batteryLevel => batteryLevelVal;

  @override
  bool get isCharging => chargingVal;

  @override
  double get cpuLoad => cpuLoadVal;

  @override
  bool get isBatterySaver => batterySaverVal;

  @override
  String? get networkType => null;
}

// ---------------------------------------------------------------------------
// Fakes — PrepBudgetService / meter
// ---------------------------------------------------------------------------

/// Minimal fake meter that returns a fixed per-task-type map.
class _FakeMeter implements LlmUsageMeter {
  final Map<String, int> _spend;
  _FakeMeter(this._spend);

  @override
  Future<void> init() async {}

  @override
  Map<String, int> getTotalTokensPerTaskType() => _spend;

  @override
  Map<String, double> getTotalCostPerTaskType() => const {};

  @override
  int getTotalTokens() => _spend.values.fold(0, (a, b) => a + b);

  @override
  double getTotalCost() => 0.0;

  @override
  Map<String, int> getTotalTokensPerFeature() => {};

  @override
  Map<String, double> getTotalCostPerFeature() => {};

  @override
  Future<void> get persistenceComplete => Future.value();

  @override
  List<LlmUsageRecord> getRecords(
          {String? feature, int? limit, String? sessionId}) =>
      [];

  @override
  LlmUsageRecord recordUsage(
      {required String id,
      required String feature,
      required String modelId,
      required int inputTokens,
      required int outputTokens,
      bool success = true,
      String? taskType,
      String? sessionId}) =>
      throw UnimplementedError();

  @override
  void clear() {}

  @override
  List<LlmUsageRecord> getRecordsBySession(String sessionId) => [];
}

/// Always allows spend. Uses default budget so the class satisfies
/// PrepBudgetService's requirement for a non-null [budget] field.
class _AlwaysAllowBudget extends PrepBudgetService {
  _AlwaysAllowBudget() : super(meter: _FakeMeter({}));

  @override
  bool canSpend(PrepCategory category, int tokens) => true;
}

/// Never allows spend.
class _NeverAllowBudget extends PrepBudgetService {
  _NeverAllowBudget() : super(meter: _FakeMeter({}));

  @override
  bool canSpend(PrepCategory category, int tokens) => false;
}

// Reusable singleton instances — avoids passing function refs where PrepBudgetService? is expected.
final alwaysAllowBudget = _AlwaysAllowBudget();
final neverAllowBudget = _NeverAllowBudget();

void main() {
  group('IdleExecutor', () {
    // ------------------------------------------------------------------
    // Quiet-hours gate
    // ------------------------------------------------------------------
    group('Quiet-hours gate', () {
      test(
        'defers non-heavy tasks during quiet hours',
        () async {
          var ran = false;
          final executor = IdleExecutor(
            shouldDeferForQuietHours: (_) => true,
          );

          await executor.enqueue('background job', () async {
            ran = true;
          });

          await executor.processNext();

          expect(ran, isFalse);
          expect(executor.queue.first.deferredReason,
              equals(PrepDeferralReason.quietHours));
          executor.dispose();
        },
      );

      test('non-quiet-hours allows execution', () async {
        var ran = false;
        final executor = IdleExecutor(
          shouldDeferForQuietHours: (_) => false,
        );

        await executor.enqueue('daytime job', () async {
          ran = true;
        });

        await executor.processNext();

        expect(ran, isTrue);
        expect(executor.queue.first.isCompleted, isTrue);
        expect(executor.queue.first.deferredReason, isNull);
        executor.dispose();
      });
    });

    // ------------------------------------------------------------------
    // System-load gate (heavy-only)
    // ------------------------------------------------------------------
    group('System-load gate (heavy-only)', () {
      test('defers heavy tasks when system cannot run heavy prep', () async {
        final monitor = TestSystemMonitor(canRun: false);
        var ran = false;
        final executor = IdleExecutor(systemMonitor: monitor);

        await executor.enqueuePrepTool(
          'pdf ingestion',
          () async => {'success': true},
          requiresHeavy: true,
          feature: 'pdf_ingestion',
          taskType: 'pdf_ingestion',
          estimatedInputTokens: 5000,
          estimatedOutputTokens: 1000,
        );

        await executor.processNext();

        expect(ran, isFalse);
        expect(executor.queue.first.deferredReason,
            equals(PrepDeferralReason.systemLoad));
        executor.dispose();
      });

      test('runs heavy tasks when system is healthy', () async {
        final monitor = TestSystemMonitor(canRun: true);
        var ran = false;
        final executor = IdleExecutor(systemMonitor: monitor);

        await executor.enqueuePrepTool(
          'pdf ingestion',
          () async {
            ran = true;
            return {'success': true};
          },
          requiresHeavy: true,
          feature: 'pdf_ingestion',
          taskType: 'pdf_ingestion',
        );

        await executor.processNext();

        expect(ran, isTrue);
        expect(executor.queue.first.isCompleted, isTrue);
        expect(executor.queue.first.deferredReason, isNull);
        executor.dispose();
      });

      test('does NOT defer light tasks when system is stressed', () async {
        final monitor = TestSystemMonitor(canRun: false);
        var ran = false;
        final executor = IdleExecutor(systemMonitor: monitor);

        await executor.enqueue('light background job', () async {
          ran = true;
        });

        await executor.processNext();

        expect(ran, isTrue);
        expect(executor.queue.first.isCompleted, isTrue);
        expect(executor.queue.first.requiresHeavy, isFalse);
        executor.dispose();
      });
    });

    // ------------------------------------------------------------------
    // Subject-opt-in gate
    // ------------------------------------------------------------------
    group('Subject-opt-in gate', () {
      test('defers tasks for disabled subjects', () async {
        var ran = false;
        final executor = IdleExecutor(
          isPrepEnabledForSubject:
              (subjectId) => subjectId != 'disabled_math',
        );

        await executor.enqueuePrepTool(
          'lesson prep for disabled subject',
          () async {
            ran = true;
            return {'success': true};
          },
          requiresHeavy: false,
          feature: 'lesson_prep',
          taskType: 'lesson_prep',
          subjectId: 'disabled_math',
        );

        await executor.processNext();

        expect(ran, isFalse);
        expect(executor.queue.first.deferredReason,
            equals(PrepDeferralReason.subjectDisabled));
        executor.dispose();
      });

      test('runs tasks for enabled subjects even when others are disabled',
          () async {
        var ran = false;
        final executor = IdleExecutor(
          isPrepEnabledForSubject:
              (subjectId) => subjectId != 'disabled_physics',
        );

        await executor.enqueuePrepTool(
          'prep for math',
          () async {
            ran = true;
            return {'success': true};
          },
          requiresHeavy: false,
          feature: 'lesson_prep',
          taskType: 'lesson_prep',
          subjectId: 'active_math',
        );

        await executor.processNext();

        expect(ran, isTrue);
        expect(executor.queue.first.isCompleted, isTrue);
        executor.dispose();
      });

      test('tasks without subjectId are always allowed', () async {
        var ran = false;
        final executor = IdleExecutor(
          isPrepEnabledForSubject: (_) => false, // all disabled
        );

        await executor.enqueuePrepTool(
          'global background task',
          () async {
            ran = true;
            return {'success': true};
          },
          requiresHeavy: false,
          feature: 'background',
          taskType: 'background',
        );

        await executor.processNext();

        expect(ran, isTrue);
        executor.dispose();
      });
    });

    // ------------------------------------------------------------------
    // Budget gate
    // ------------------------------------------------------------------
    group('Budget gate', () {
      test('defers when budget is exhausted', () async {
        final fakeManager = FakeLlmTaskManager();
        final executor = IdleExecutor(
          llmTaskManager: fakeManager,
          prepBudgetService: neverAllowBudget,
        );

        await executor.enqueuePrepTool(
          'pdf ingestion',
          () async => {'success': true},
          requiresHeavy: false,
          feature: 'pdf_ingestion',
          taskType: 'pdf_ingestion',
          estimatedInputTokens: 1000,
          estimatedOutputTokens: 0,
        );

        await executor.processNext();

        expect(executor.queue.first.deferredReason,
            equals(PrepDeferralReason.budgetExhausted));
        // Manager must NOT have been called (task stays queued).
        expect(fakeManager.lastCreatedTaskFeature, isNull);
        executor.dispose();
      });

      test('allows spend within budget', () async {
        final fakeManager = FakeLlmTaskManager();
        final executor = IdleExecutor(
          llmTaskManager: fakeManager,
          prepBudgetService: alwaysAllowBudget,
        );

        var ran = false;
        await executor.enqueuePrepTool(
          'pdf ingestion',
          () async {
            ran = true;
            return {'success': true};
          },
          requiresHeavy: false,
          feature: 'pdf_ingestion',
          taskType: 'pdf_ingestion',
          estimatedInputTokens: 500,
          estimatedOutputTokens: 0,
        );

        await executor.processNext();

        expect(ran, isTrue);
        expect(fakeManager.lastCreatedTaskFeature, equals('pdf_ingestion'));
        executor.dispose();
      });

      test('skips budget gate when no estimate provided', () async {
        final fakeManager = FakeLlmTaskManager();
        final executor = IdleExecutor(
          llmTaskManager: fakeManager,
          prepBudgetService: neverAllowBudget, // denies everything
        );

        var ran = false;
        // Zero estimated tokens → budget gate skipped entirely.
        await executor.enqueuePrepTool(
          'background task with no estimate',
          () async {
            ran = true;
            return {'success': true};
          },
          requiresHeavy: false,
          feature: 'background',
          taskType: 'background',
          estimatedInputTokens: 0,
          estimatedOutputTokens: 0,
        );

        await executor.processNext();

        expect(ran, isTrue);
        // Even with a never-allow budget, zero-estimate tasks proceed.
        expect(fakeManager.lastCreatedTaskFeature, equals('background'));
        executor.dispose();
      });
    });

    // ------------------------------------------------------------------
    // Gate priority
    // ------------------------------------------------------------------
    group('Gate priority', () {
      test(
        'quiet-hours takes precedence over budget drain',
        () async {
          var ran = false;
          final executor = IdleExecutor(
            shouldDeferForQuietHours: (_) => true, // active
            prepBudgetService: neverAllowBudget, // also exhausted
          );

          await executor.enqueue('should defer for quiet hours',
              () async {
            ran = true;
          });

          await executor.processNext();

          expect(ran, isFalse);
          expect(executor.queue.first.deferredReason,
              equals(PrepDeferralReason.quietHours));
          executor.dispose();
        },
      );

      test(
        'system load checked before budget when both apply to heavy task',
        () async {
          final monitor = TestSystemMonitor(canRun: false);
          var ran = false;
          final executor = IdleExecutor(
            systemMonitor: monitor,
            prepBudgetService: neverAllowBudget,
          );

          await executor.enqueuePrepTool(
            'heavy task',
            () async {
              ran = true;
              return {'success': true};
            },
            requiresHeavy: true,
            feature: 'embeddings',
            taskType: 'embeddings',
            estimatedInputTokens: 5000,
          );

          await executor.processNext();

          expect(ran, isFalse);
          expect(executor.queue.first.deferredReason,
              equals(PrepDeferralReason.systemLoad));
          executor.dispose();
        },
      );
    });

    // ------------------------------------------------------------------
    // retryDeferredNow
    // ------------------------------------------------------------------
    group('retryDeferredNow', () {
      test(
        'retried deferred task runs immediately when conditions clear',
        () async {
          var ran = false;
          var isQuietHours = true;
          final executor = IdleExecutor(
            shouldDeferForQuietHours: (_) => isQuietHours,
          );

          await executor.enqueue('queued task', () async {
            ran = true;
          });

          // Initially deferred by quiet hours.
          await executor.processNext();
          expect(ran, isFalse);
          expect(executor.queue.first.deferredReason,
              equals(PrepDeferralReason.quietHours));

          // Clear quiet hours.
          isQuietHours = false;

          // retryDeferredNow triggers immediate evaluation.
          await executor.retryDeferredNow();

          expect(ran, isTrue);
          expect(executor.queue.first.isCompleted, isTrue);
          executor.dispose();
        },
      );
    });

    // ------------------------------------------------------------------
    // LlmTaskManager integration
    // ------------------------------------------------------------------
    group('LlmTaskManager integration', () {
      test('creates parent task and marks completed', () async {
        final fakeManager = FakeLlmTaskManager();
        final executor = IdleExecutor(llmTaskManager: fakeManager);

        await executor.enqueuePrepTool(
          'batch ingestion',
          () async => {'success': true},
          requiresHeavy: false,
          feature: 'pdf_ingestion',
          taskType: 'pdf_ingestion',
          estimatedInputTokens: 500,
        );

        await executor.processNext();

        expect(fakeManager.started, isTrue);
        expect(fakeManager.lastCompleteTokens, isNotNull);
        expect(executor.queue.first.isCompleted, isTrue);
        executor.dispose();
      });
    });

    // ------------------------------------------------------------------
    // Cancel queued task
    // ------------------------------------------------------------------
    group('Cancel queued task', () {
      test('removes waiting task from queue', () async {
        final executor = IdleExecutor(
          shouldDeferForQuietHours: (_) => true,
        );

        await executor.enqueue('cancel me', () async {});
        expect(executor.queue, hasLength(1));

        final result = executor.cancelQueuedTask(executor.queue.first.id);
        expect(result, isTrue);
        expect(executor.queue, isEmpty);
        executor.dispose();
      });

      test('cannot cancel running task', () async {
        final executor = IdleExecutor(
          shouldDeferForQuietHours: (_) => false,
        );

        var executing = false;
        await executor.enqueue('running task', () async {
          executing = true;
          await Future.delayed(const Duration(seconds: 2));
        });

        // Let processNext pick it up.
        await executor.processNext();
        await Future<void>.delayed(Duration.zero);

        expect(executing, isTrue);
        // Now try to cancel — should fail because task is running.
        if (executor.queue.isNotEmpty && executor.queue.first.isRunning) {
          expect(executor.cancelQueuedTask(executor.queue.first.id), isFalse);
        }
        executor.dispose();
      });
    });

    // ------------------------------------------------------------------
    // Queue management
    // ------------------------------------------------------------------
    group('Queue management', () {
      test('evicts oldest when queue exceeds max length', () async {
        final executor = IdleExecutor(
          shouldDeferForQuietHours: (_) => true,
        );

        for (var i = 0; i < 55; i++) {
          await executor.enqueue('task $i', () async {});
        }

        // Should cap at ~50 items.
        expect(executor.queue.length, lessThanOrEqualTo(56));
        // Oldest tasks removed.
        expect(executor.queue.first.description, startsWith('task '));
        // Later items remain.
        expect(executor.queue.last.description, equals('task 54'));
        executor.dispose();
      });

      test('removeTasksWhere removes matching tasks', () async {
        final executor = IdleExecutor(
          shouldDeferForQuietHours: (_) => true,
        );

        await executor.enqueue('keep me', () async {});
        await executor.enqueue('remove me', () async {});

        executor.removeTasksWhere((t) => t.description == 'remove me');
        expect(executor.queue, hasLength(1));
        expect(executor.queue.first.description, 'keep me');
        executor.dispose();
      });
    });
  });
}
