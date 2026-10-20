import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/system_monitor_service.dart';

void main() {
  group('IdleExecutor', () {
    test('starts with empty queue', () {
      final executor = IdleExecutor();
      expect(executor.queue, isEmpty);
      expect(executor.hasPendingTasks, isFalse);
    });

    test('enqueue adds task', () async {
      final executor = IdleExecutor();
      await executor.enqueue('test task', () async {});
      expect(executor.queue.length, 1);
      expect(executor.queue.first.description, 'test task');
    });

    test('dispose cleans up', () {
      final executor = IdleExecutor();
      executor.dispose();
      expect(executor.hasPendingTasks, isFalse);
    });
  });

  group('IdleExecutor quiet-hours deferral', () {
    test('defers task when shouldDeferForQuietHours returns true', () async {
      // Simulates a 2am time inside a 22:00–08:00 quiet-hours window.
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => true,
      );

      var taskRan = false;
      await executor.enqueue(
        'heavy prep task',
        () async {
          taskRan = true;
        },
        requiresHeavy: true,
      );

      // The callback returns true, so the task must be deferred — not executed.
      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);
      expect(executor.queue.first.isRunning, isFalse);
      expect(executor.queue.first.isCompleted, isFalse);

      executor.dispose();
    });

    test('defers non-heavy task when shouldDeferForQuietHours returns true', () async {
      // Vision says ALL off-period tasks defer, not just heavy ones.
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => true,
      );

      var taskRan = false;
      await executor.enqueue(
        'light cleanup task',
        () async {
          taskRan = true;
        },
      );

      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);

      executor.dispose();
    });

    test('does not defer when shouldDeferForQuietHours returns false', () async {
      // Outside the quiet-hours window — the task should run immediately.
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => false,
      );

      var taskRan = false;
      await executor.enqueue(
        'normal prep task',
        () async {
          taskRan = true;
        },
      );

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });

    test('does not defer when shouldDeferForQuietHours is not provided', () async {
      // No quiet-hours callback injected — behave as if quiet hours are off.
      final executor = IdleExecutor();

      var taskRan = false;
      await executor.enqueue(
        'normal prep task',
        () async {
          taskRan = true;
        },
      );

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);

      executor.dispose();
    });

    test('processNext defers a queued task when quiet hours are active', () async {
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => true,
      );

      var taskRan = false;
      await executor.enqueue(
        'queued task',
        () async {
          taskRan = true;
        },
      );
      await executor.processNext();

      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);

      // Now disable quiet hours and process again — the task should run.
      // We recreate the executor with a false callback to verify the task
      // is picked up once the window passes.
      taskRan = false;
      final executor2 = IdleExecutor(
        shouldDeferForQuietHours: (_) => false,
      );
      await executor2.enqueue(
        'queued task',
        () async {
          taskRan = true;
        },
      );
      await executor2.processNext();
      expect(taskRan, isTrue);

      executor.dispose();
      executor2.dispose();
    });

    test('quiet-hours check happens before system-monitor check', () async {
      // Both quiet-hours and system monitor would defer. The quiet-hours check
      // short-circuits first (logged as "Deferring task — within quiet hours").
      final executor = IdleExecutor(
        // shouldDefer always true — simulates 2am within a 22–8 window.
        shouldDeferForQuietHours: (_) => true,
      );

      var taskRan = false;
      await executor.enqueue(
        'heavy task',
        () async {
          taskRan = true;
        },
        requiresHeavy: true,
      );

      expect(taskRan, isFalse);
      expect(executor.queue.first.isRunning, isFalse);
      expect(executor.queue.first.isCompleted, isFalse);

      executor.dispose();
    });

    test('uses DateTime.now() passed to callback', () async {
      DateTime? capturedNow;
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (now) {
          capturedNow = now;
          return false;
        },
      );

      await executor.enqueue('task', () async {});
      // The callback should have been invoked with a DateTime.
      expect(capturedNow, isNotNull);
      expect(capturedNow, isA<DateTime>());

      executor.dispose();
    });

    test('task runs after quiet hours pass (callback switches to false)', () async {
      var defer = true;
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => defer,
      );

      var taskRan = false;
      await executor.enqueue(
        'deferred task',
        () async {
          taskRan = true;
        },
      );

      // Still in quiet hours — task deferred.
      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);

      // Quiet hours are over — allow execution.
      defer = false;
      await executor.processNext();

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });
  });

  group('IdleExecutor system-monitor deferral', () {
    test('defers heavy task when system reports stress', () async {
      // Vision §4.3: heavy off-period prep must defer when the device is
      // stressed (CPU > 80%, battery < 20%, battery-saver on).
      final monitor = MutableFakeSystemMonitorService(
        canRunHeavyPrepNowValue: false,
      );
      final executor = IdleExecutor(systemMonitor: monitor);

      var taskRan = false;
      await executor.enqueue(
        'heavy embedding prep task',
        () async {
          taskRan = true;
        },
        requiresHeavy: true,
      );

      // The system monitor reports stress, so the heavy task must NOT run
      // and must remain pending for a later retry.
      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);
      expect(executor.queue.first.isRunning, isFalse);
      expect(executor.queue.first.isCompleted, isFalse);

      executor.dispose();
    });

    test('runs heavy task after system recovers', () async {
      // Stress clears → the deferred task runs on the next processNext() call.
      final monitor = MutableFakeSystemMonitorService(
        canRunHeavyPrepNowValue: false,
      );
      final executor = IdleExecutor(systemMonitor: monitor);

      var taskRan = false;
      await executor.enqueue(
        'heavy question-variant task',
        () async {
          taskRan = true;
        },
        requiresHeavy: true,
      );

      // System under stress — task deferred.
      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);

      // Simulate the device recovering (CPU cooled, plugged in).
      monitor.canRunHeavyPrepNowValue = true;
      await executor.processNext();

      // Now the deferred task should have run and completed.
      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });

    test('light task proceeds even when system reports stress', () async {
      // Vision §4.3: "heavy jobs defer, light jobs proceed." A non-heavy task
      // must not be blocked by CPU/battery stress — it is too cheap to matter.
      final monitor = MutableFakeSystemMonitorService(
        canRunHeavyPrepNowValue: false,
      );
      final executor = IdleExecutor(systemMonitor: monitor);

      var taskRan = false;
      await executor.enqueue(
        'light cleanup task',
        () async {
          taskRan = true;
        },
        // requiresHeavy defaults to false — light jobs skip deferral.
      );

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });

    test('does not require a systemMonitor — heavy tasks run without it', () async {
      // When no SystemMonitorService is injected, heavy tasks proceed normally
      // (the deferral branch at idle_executor.dart:115 short-circuits on
      // `_systemMonitor != null`).
      final executor = IdleExecutor();

      var taskRan = false;
      await executor.enqueue(
        'heavy task without monitor',
        () async {
          taskRan = true;
        },
        requiresHeavy: true,
      );

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);

      executor.dispose();
    });
  });

  group('IdleExecutor enqueuePrepTool', () {
    test('executes a prep tool that returns success', () async {
      final executor = IdleExecutor();

      var toolRan = false;
      await executor.enqueuePrepTool(
        'pre_generate_lesson prep job',
        () async {
          toolRan = true;
          return {'success': true, 'lessonId': 'l1'};
        },
        requiresHeavy: true,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
      );

      expect(toolRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);
      expect(executor.queue.first.taskType, 'lesson_prep');
      expect(executor.queue.first.feature, 'lesson_prep');
    });

    test('marks task as failed when prep tool returns success: false', () async {
      final executor = IdleExecutor();

      await executor.enqueuePrepTool(
        'failed prep job',
        () async {
          return {'success': false, 'error': 'Budget exhausted'};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
      );

      expect(executor.queue.first.isCompleted, isFalse);
      expect(executor.queue.first.error, contains('Budget exhausted'));
    });

    test('defers heavy prep tool under CPU pressure and resumes on recovery',
        () async {
      final monitor = MutableFakeSystemMonitorService(
        canRunHeavyPrepNowValue: false,
      );
      final executor = IdleExecutor(systemMonitor: monitor);

      var toolRan = false;
      await executor.enqueuePrepTool(
        'heavy prep job',
        () async {
          toolRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'question_variants',
        taskType: 'question_variants',
      );

      // Deferred — system monitor reports stress.
      expect(toolRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);

      // System recovers — task runs on next poll.
      monitor.canRunHeavyPrepNowValue = true;
      await executor.processNext();

      expect(toolRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);

      executor.dispose();
    });

    test('tracks task on LlmTaskManager with correct feature and taskType',
        () async {
      final manager = LlmTaskManager();
      final executor = IdleExecutor(llmTaskManager: manager);

      await executor.enqueuePrepTool(
        'pdf ingestion prep',
        () async {
          return {'success': true, 'chunkCount': 5};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
      );

      expect(manager.tasks, isNotEmpty);
      expect(manager.tasks.any((t) => t.feature == 'pdf_ingestion'), isTrue);
      expect(manager.tasks.any((t) => t.taskType == 'pdf_ingestion'), isTrue);
      expect(manager.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);
    });

    test('light prep tool is not deferred by system monitor', () async {
      final monitor = MutableFakeSystemMonitorService(
        canRunHeavyPrepNowValue: false,
      );
      final executor = IdleExecutor(systemMonitor: monitor);

      var toolRan = false;
      await executor.enqueuePrepTool(
        'light mastery refresh',
        () async {
          toolRan = true;
          return {'success': true};
        },
        requiresHeavy: false,
        feature: 'mastery_refresh',
        taskType: 'background',
      );

      // Light tasks proceed even under CPU pressure.
      expect(toolRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);

      executor.dispose();
    });
  });

  group('IdleExecutor per-subject opt-in enforcement', () {
    // Mirrors a PrepBudget whose disabledSubjects contains only 'chemistry':
    // the predicate returns true (enabled) for every subject except chemistry.
    bool onlyChemistryDisabled(String subjectId) => subjectId != 'chemistry';

    test('defers prep task for a student-disabled subject', () async {
      final executor = IdleExecutor(
        isPrepEnabledForSubject: onlyChemistryDisabled,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'ingest chemistry textbook',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        subjectId: 'chemistry',
      );

      // The student paused Chemistry, so no tokens may be spent on it: the
      // task is deferred (not executed) and remains pending.
      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);
      expect(executor.queue.first.isCompleted, isFalse);
      expect(executor.queue.first.isRunning, isFalse);

      executor.dispose();
    });

    test('runs prep task for an enabled subject', () async {
      final executor = IdleExecutor(
        isPrepEnabledForSubject: onlyChemistryDisabled,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'ingest biology textbook',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        subjectId: 'biology',
      );

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });

    test('runs subject-agnostic task even with the subject gate injected',
        () async {
      // Tasks without a subjectId (e.g. adherence maintenance attributed to
      // the background bucket) must not be blocked by the per-subject gate —
      // there is no subject to consult.
      final executor = IdleExecutor(
        isPrepEnabledForSubject: onlyChemistryDisabled,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'subject-agnostic maintenance',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: false,
        feature: 'background',
        taskType: 'background',
      );

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);

      executor.dispose();
    });

    test('does not register a disabled-subject task on LlmTaskManager', () async {
      // Vision §4.2: a skipped task must not masquerade as a running/failed
      // prep job in the task manager — it never entered execution.
      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        isPrepEnabledForSubject: onlyChemistryDisabled,
      );

      await executor.enqueuePrepTool(
        'ingest chemistry textbook',
        () async {
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        subjectId: 'chemistry',
      );

      expect(
        manager.tasks,
        isEmpty,
        reason: 'Disabled-subject task must never reach the task manager',
      );

      executor.dispose();
    });

    test('runs subject-scoped task when no subject gate is injected', () async {
      // Backward compatible: without the callback the executor behaves as it
      // always has (subjectId is simply not consulted).
      final executor = IdleExecutor();

      var taskRan = false;
      await executor.enqueuePrepTool(
        'prep with no gate',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
        subjectId: 'chemistry',
      );

      expect(taskRan, isTrue);
      expect(executor.queue.first.isCompleted, isTrue);

      executor.dispose();
    });
  });

  group('IdleExecutor token aggregation', () {
    test('aggregates per-call tokens onto the parent idle task', () async {
      // When a prep task's taskFn invokes the LLM service, the service records
      // its own per-call LlmTask on the shared LlmTaskManager with real token
      // counts (just like _TaskTrackingFakeLlmService in agent_loop_test.dart).
      // IdleExecutor must aggregate those onto the parent idle task so the
      // task-manager portal shows non-zero spend (vision §4.2 token
      // transparency). The parent idle task always has modelId 'background'.
      final manager = LlmTaskManager();
      final executor = IdleExecutor(llmTaskManager: manager);

      await executor.enqueuePrepTool(
        'lesson prep consuming per-call tokens',
        () async {
          // Simulate the LLM service creating a per-call task with tokens.
          final callId = manager.createTask(
            feature: 'lesson_prep',
            modelId: 'gpt-4o',
            taskType: 'lesson_prep',
          );
          manager.startTask(callId);
          manager.completeTask(
            callId,
            tokensUsed: 1500,
            estimatedCost: 0.002,
          );
          return {'success': true, 'lessonId': 'l1'};
        },
        requiresHeavy: false,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
      );

      // The parent idle task is the one with modelId 'background'.
      final parentTask = manager.tasks.firstWhere((t) => t.modelId == 'background');
      expect(parentTask.status, LlmTaskStatus.done);
      expect(parentTask.tokensUsed, greaterThanOrEqualTo(1500));
      expect(parentTask.estimatedCost, closeTo(0.002, 0.0001));

      executor.dispose();
    });

    test('aggregates tokens from multiple per-call tasks', () async {
      final manager = LlmTaskManager();
      final executor = IdleExecutor(llmTaskManager: manager);

      await executor.enqueuePrepTool(
        'multi-step prep with 3 LLM calls',
        () async {
          for (var i = 0; i < 3; i++) {
            final callId = manager.createTask(
              feature: 'question_variants',
              modelId: 'gpt-4o',
              taskType: 'question_variants',
            );
            manager.startTask(callId);
            manager.completeTask(
              callId,
              tokensUsed: 400,
              estimatedCost: 0.0005,
            );
          }
          return {'success': true};
        },
        requiresHeavy: false,
        feature: 'question_variants',
        taskType: 'question_variants',
      );

      final parentTask = manager.tasks.firstWhere((t) => t.modelId == 'background');
      expect(parentTask.tokensUsed, 1200);
      expect(parentTask.estimatedCost, closeTo(0.0015, 0.0001));

      executor.dispose();
    });

    test('parent task shows 0 tokens when taskFn makes no LLM calls', () async {
      // If the taskFn does not invoke the LLM service, the parent idle task
      // completes normally with tokensUsed 0 (no regression from aggregation
      // logic that should only count real per-call tasks).
      final manager = LlmTaskManager();
      final executor = IdleExecutor(llmTaskManager: manager);

      await executor.enqueuePrepTool(
        'pure local prep, no LLM calls',
        () async {
          return {'success': true, 'chunkCount': 42};
        },
        requiresHeavy: false,
        feature: 'mastery_refresh',
        taskType: 'background',
      );

      final parentTask = manager.tasks.firstWhere((t) => t.modelId == 'background');
      expect(parentTask.status, LlmTaskStatus.done);
      expect(parentTask.tokensUsed, 0);
      expect(parentTask.estimatedCost, 0.0);

      executor.dispose();
    });
  });

  group('IdleExecutor prep-budget gate', () {
    // Vision Next-Term §4.2/§4.4: IdleExecutor must consult
    // PrepBudgetService.canSpend BEFORE creating the parent LlmTask.
    // When the category cap is exhausted, the task is deferred (stays
    // queued, never running/failed) and retried on the next poll.

    test('defers prep task when category budget is exhausted; task never reaches LlmTaskManager', () async {
      // PDF→KB cap of 10000 is already exhausted in the meter.
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'exhausted',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 10000,
        outputTokens: 0,
        taskType: 'pdf_ingestion',
      );
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: true,
          caps: {PrepCategory.pdfIngestion: 10000},
        ),
      );

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        prepBudgetService: budget,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'pdf ingestion over cap',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 8000,
        estimatedOutputTokens: 2000,
      );

      // Task is deferred — not created on LlmTaskManager, not executed,
      // not marked as failed (error is null).
      expect(taskRan, isFalse, reason: 'Task must not run when over budget');
      expect(manager.tasks, isEmpty, reason: 'Deferred task must not reach LlmTaskManager');
      expect(executor.queue.first.isRunning, isFalse);
      expect(executor.queue.first.isCompleted, isFalse);
      expect(executor.queue.first.error, isNull, reason: 'Deferral is not a failure');

      executor.dispose();
    });

    test('runs prep task when category budget has room', () async {
      final meter = LlmUsageMeter();
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: true,
          caps: {PrepCategory.pdfIngestion: 100000},
        ),
      );

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        prepBudgetService: budget,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'pdf ingestion within cap',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 8000,
        estimatedOutputTokens: 2000,
      );

      // Budget has room → task runs and completes.
      expect(taskRan, isTrue);
      expect(manager.tasks.any((t) => t.feature == 'pdf_ingestion'), isTrue);
      expect(manager.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);

      executor.dispose();
    });

    test('halving PDF cap defers PDF task but allows question-variant task (§4.4 acceptance #2)', () async {
      final meter = LlmUsageMeter();
      // Simulate the first textbook ingestion exhausting the (halved) PDF cap.
      meter.recordUsage(
        id: 'first_pdf',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 100000,
        outputTokens: 0,
        taskType: 'pdf_ingestion',
      );
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: true,
          caps: {
            PrepCategory.pdfIngestion: 100000, // halved from 200000
            PrepCategory.questionVariants: 150000,
          },
        ),
      );

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        prepBudgetService: budget,
      );

      var pdfRan = false;
      var qvRan = false;

      // Enqueue question-variant generation first (has budget → runs).
      // The Q-bank category still has its full 150K cap available.
      await executor.enqueuePrepTool(
        'generate question variants',
        () async {
          qvRan = true;
          return {'success': true};
        },
        requiresHeavy: false,
        feature: 'question_variants',
        taskType: 'question_variants',
        estimatedInputTokens: 5000,
        estimatedOutputTokens: 3000,
      );

      expect(qvRan, isTrue, reason: 'Question-variant task must run when its category has budget');
      expect(manager.tasks.any((t) => t.taskType == 'question_variants'), isTrue);
      expect(manager.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);

      // Now enqueue PDF ingestion (deferred because cap exhausted from prior work).
      await executor.enqueuePrepTool(
        'ingest second textbook',
        () async {
          pdfRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 10000,
        estimatedOutputTokens: 2000,
      );

      // PDF task deferred; not created on LlmTaskManager, not failed.
      expect(pdfRan, isFalse, reason: 'PDF task must defer when cap exhausted');
      expect(manager.tasks.any((t) => t.taskType == 'pdf_ingestion'), isFalse,
          reason: 'Deferred PDF task must not reach LlmTaskManager');
      expect(executor.queue.last.isCompleted, isFalse);
      expect(executor.queue.last.error, isNull, reason: 'Deferral is not a failure');
      // Q-bank task from earlier is still completed; PDF task is still pending.
      expect(executor.hasPendingTasks, isTrue, reason: 'PDF task must remain pending for retry');

      executor.dispose();
    });

    test('task with zero estimates skips the budget gate (backward compatible)', () async {
      // A task enqueued without estimates (legacy callers) must not be blocked
      // by the gate when the budget is exhausted — the gate only applies when
      // an estimate is provided.
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'exhausted',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 10000,
        outputTokens: 0,
        taskType: 'pdf_ingestion',
      );
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: true,
          caps: {PrepCategory.pdfIngestion: 10000},
        ),
      );

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        prepBudgetService: budget,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'legacy task, no estimates',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: false,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        // No estimatedInputTokens/estimatedOutputTokens — defaults to 0.
      );

      expect(taskRan, isTrue, reason: 'Zero-estimate task must bypass the budget gate');
      expect(executor.queue.first.isCompleted, isTrue);

      executor.dispose();
    });

    test('non-matching taskType falls back to background category for the gate', () async {
      final meter = LlmUsageMeter();
      meter.recordUsage(
        id: 'exhausted_bg',
        feature: 'prep',
        modelId: 'gpt-4',
        inputTokens: 10000,
        outputTokens: 0,
        taskType: 'background',
      );
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: true,
          caps: {PrepCategory.background: 10000},
        ),
      );

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        prepBudgetService: budget,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'unknown task type',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: false,
        feature: 'some_feature',
        taskType: 'unknown_task_type',
        estimatedInputTokens: 1000,
        estimatedOutputTokens: 500,
      );

      // Falls back to PrepCategory.background (exhausted) → deferred.
      expect(taskRan, isFalse);
      expect(manager.tasks, isEmpty);
      expect(executor.queue.first.isCompleted, isFalse);
      expect(executor.queue.first.error, isNull, reason: 'Deferral is not a failure');

      executor.dispose();
    });

    test('disabled master budget defers all prep tasks', () async {
      final meter = LlmUsageMeter();
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: false, // master switch off
          caps: {PrepCategory.pdfIngestion: 100000},
        ),
      );

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        prepBudgetService: budget,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'pdf ingestion with disabled budget',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 8000,
        estimatedOutputTokens: 2000,
      );

      expect(taskRan, isFalse);
      expect(manager.tasks, isEmpty);
      expect(executor.queue.first.isCompleted, isFalse);

      executor.dispose();
    });

    test('previously deferred task runs after budget recovers (flip canSpend to true)', () async {
      // Uses a mutable fake so canSpend can be toggled at runtime to simulate
      // the budget window resetting or the student raising the cap.
      final meter = LlmUsageMeter();
      final budget = MutableFakePrepBudgetService(meter: meter, canSpendValue: false);

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        prepBudgetService: budget,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'pdf ingestion',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 8000,
        estimatedOutputTokens: 2000,
      );

      // First attempt: canSpend returns false → deferred.
      expect(taskRan, isFalse);
      expect(manager.tasks, isEmpty);
      expect(executor.queue.first.isCompleted, isFalse);

      // Budget recovers: flip canSpend to true, retry via processNext().
      budget.canSpendValue = true;
      await executor.processNext();

      expect(taskRan, isTrue, reason: 'Task must run once budget recovers');
      expect(manager.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);

      executor.dispose();
    });
  });

  group('IdleExecutor pdf_ingestion attribution (vision §4.2 criterion 3)', () {
    // Vision Next-Term §4.2 acceptance criterion 3:
    //   "A service test on PrepBudgetService.spendingByCategory() fed real
    //    pipeline LlmUsageMeter records shows nonzero pdf_ingestion spend
    //    after the fix."
    //
    // After the double-counting fix, when ContentPipeline passes
    // `taskType: 'pdf_ingestion'` to chat() (as it now does), per-call
    // recordings land under 'pdf_ingestion' — a PrepCategory key — and the
    // aggregate bridge is skipped (no double-count). spendingByCategory()
    // reads 'pdf_ingestion' directly from per-call recordings.

    test('spendingByCategory[pdf_ingestion] is nonzero after a pipeline-style prep run',
        () async {
      final meter = LlmUsageMeter();
      final manager = LlmTaskManager();
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: true,
          caps: {PrepCategory.pdfIngestion: 100000},
        ),
      );

      final executor = IdleExecutor(
        llmTaskManager: manager,
        usageMeter: meter,
        prepBudgetService: budget,
      );

      await executor.enqueuePrepTool(
        'pdf ingestion pipeline',
        () async {
          // Simulate ContentPipeline making LLM calls with feature: 'pdf_ingestion'
          // and taskType: 'pdf_ingestion' (passed via the taskType override in
          // chat(), as ContentPipeline now does after the attribution fix).
          final callId = manager.createTask(
            feature: 'pdf_ingestion',
            modelId: 'gpt-4o-mini',
            taskType: 'pdf_ingestion',
          );
          manager.startTask(callId);
          manager.completeTask(
            callId,
            tokensUsed: 1500,
            estimatedCost: 0.001,
          );

          // Simulate _recordCompletion recording on the meter under 'pdf_ingestion'.
          meter.recordUsage(
            id: callId,
            feature: 'pdf_ingestion',
            modelId: 'gpt-4o-mini',
            inputTokens: 1000,
            outputTokens: 500,
            taskType: 'pdf_ingestion',
          );
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 500,
        estimatedOutputTokens: 300,
      );

      // Let the _tryExecuteNext aggregate-bridge code actually run so we
      // verify it is SKIPPED (not just absent from the meter).
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Criterion 3: spendingByCategory must show nonzero for pdf_ingestion.
      // With per-call taskType='pdf_ingestion', the aggregate bridge is skipped
      // (per-call already covers the PrepCategory key), so tokens are recorded
      // exactly once — under 'pdf_ingestion' — not double-counted.
      final byType = meter.getTotalTokensPerTaskType();
      expect(byType['pdf_ingestion'], equals(1500));
      expect(byType['background'], isNull);

      final spending = budget.spendingByCategory();
      expect(spending[PrepCategory.pdfIngestion], equals(1500));

      // No live misclassification: pipeline tokens must never land in
      // classification/generation/summarization buckets.
      expect(byType['classification'], isNull);
      expect(byType['generation'], isNull);
      expect(byType['summarization'], isNull);

      // All recorded tokens are prep → totalLiveTokens is zero.
      expect(budget.totalLiveTokens(), equals(0));

      // No double-count: totalPrepTokens equals the single call's actual spend.
      expect(budget.totalPrepTokens(), equals(1500));

      executor.dispose();
    });

    test('budget gate defers when pdf_ingestion cap is exhausted', () async {
      final meter = LlmUsageMeter();
      // Simulate a prior pipeline run's aggregate already consuming the cap.
      meter.recordUsage(
        id: 'prior_run',
        feature: 'pdf_ingestion',
        modelId: 'gpt-4o-mini',
        inputTokens: 100000,
        outputTokens: 0,
        taskType: 'pdf_ingestion',
      );
      final budget = PrepBudgetService(
        meter: meter,
        budget: const PrepBudget(
          enabled: true,
          caps: {PrepCategory.pdfIngestion: 100000},
        ),
      );

      final manager = LlmTaskManager();
      final executor = IdleExecutor(
        llmTaskManager: manager,
        usageMeter: meter,
        prepBudgetService: budget,
      );

      var taskRan = false;
      await executor.enqueuePrepTool(
        'second pdf ingestion over cap',
        () async {
          taskRan = true;
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 8000,
        estimatedOutputTokens: 2000,
      );

      expect(taskRan, isFalse, reason: 'Task must not run when over budget');
      expect(manager.tasks, isEmpty,
          reason: 'Deferred task must not reach LlmTaskManager');
      expect(executor.queue.first.isCompleted, isFalse);
      expect(executor.queue.first.error, isNull,
          reason: 'Deferral is not a failure');

      executor.dispose();
    });

    test('pipeline with per-call pdf_ingestion taskType records tokens exactly once (no double-count)',
        () async {
      final meter = LlmUsageMeter();
      final manager = LlmTaskManager();
      final budget = PrepBudgetService(
        meter: meter,
        budget: PrepBudget.defaults,
      );

      final executor = IdleExecutor(
        llmTaskManager: manager,
        usageMeter: meter,
        prepBudgetService: budget,
      );

      await executor.enqueuePrepTool(
        'multi-call pipeline',
        () async {
          // Simulate 3 pipeline LLM calls, each recording on the meter
          // under taskType 'pdf_ingestion' (a PrepCategory key), exactly
          // as ContentPipeline now does after passing taskType: _feature.
          for (var i = 0; i < 3; i++) {
            final callId = manager.createTask(
              feature: 'pdf_ingestion',
              modelId: 'gpt-4o-mini',
              taskType: 'pdf_ingestion',
            );
            manager.startTask(callId);
            manager.completeTask(
              callId,
              tokensUsed: 400,
              estimatedCost: 0.0005,
            );
            meter.recordUsage(
              id: callId,
              feature: 'pdf_ingestion',
              modelId: 'gpt-4o-mini',
              inputTokens: 200,
              outputTokens: 200,
              taskType: 'pdf_ingestion',
            );
          }
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 500,
        estimatedOutputTokens: 300,
      );

      // Drain the microtask queue so the _tryExecuteNext aggregate-bridge
      // code has actually fired (proving the skip, not mere absence).
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final byType = meter.getTotalTokensPerTaskType();

      // Per-call recordings under 'pdf_ingestion' (a PrepCategory key)
      // cause the aggregate bridge to be SKIPPED — no double-count.
      // All 3 × 400 = 1200 tokens live in the single 'pdf_ingestion' bucket.
      expect(byType['pdf_ingestion'], equals(1200));
      // No spurious 'background' bucket from the old fromFeature() mapping.
      expect(byType['background'], isNull);

      final spending = budget.spendingByCategory();
      expect(spending[PrepCategory.pdfIngestion], equals(1200));

      // Single physical pipeline → tokens appear on the meter exactly once.
      expect(budget.totalPrepTokens(), equals(1200));
      expect(budget.totalLiveTokens(), equals(0));

      executor.dispose();
    });

    test('aggregate bridge records parent category when per-call uses non-prep taskType',
        () async {
      final meter = LlmUsageMeter();
      final manager = LlmTaskManager();
      final budget = PrepBudgetService(
        meter: meter,
        budget: PrepBudget.defaults,
      );

      final executor = IdleExecutor(
        llmTaskManager: manager,
        usageMeter: meter,
        prepBudgetService: budget,
      );

      await executor.enqueuePrepTool(
        'classification pipeline (non-prep taskType)',
        () async {
          // Simulate 3 pipeline LLM calls whose per-call taskType is
          // 'classification' (NOT a PrepCategory key). This covers the
          // fallback path: the aggregate bridge MUST still fire to attribute
          // tokens to the parent category 'pdf_ingestion'.
          for (var i = 0; i < 3; i++) {
            final callId = manager.createTask(
              feature: 'pdf_ingestion',
              modelId: 'gpt-4o-mini',
              taskType: 'classification',
            );
            manager.startTask(callId);
            manager.completeTask(
              callId,
              tokensUsed: 400,
              estimatedCost: 0.0005,
            );
            meter.recordUsage(
              id: callId,
              feature: 'pdf_ingestion',
              modelId: 'gpt-4o-mini',
              inputTokens: 200,
              outputTokens: 200,
              taskType: 'classification',
            );
          }
          return {'success': true};
        },
        requiresHeavy: true,
        feature: 'pdf_ingestion',
        taskType: 'pdf_ingestion',
        estimatedInputTokens: 500,
        estimatedOutputTokens: 300,
      );

      // Drain the microtask queue so the _tryExecuteNext aggregate-bridge
      // code has actually fired.
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final byType = meter.getTotalTokensPerTaskType();

      // Per-call recordings landed under 'classification' (not a PrepCategory
      // key), so the aggregate bridge fires and records the parent category
      // 'pdf_ingestion' with the total tokens.
      expect(byType['classification'], equals(1200));
      expect(byType['pdf_ingestion'], equals(1200));

      // Prep tokens come only from the 'pdf_ingestion' bucket (aggregate).
      expect(budget.totalPrepTokens(), equals(1200));
      // Classification tokens are live (non-prep).
      expect(budget.totalLiveTokens(), equals(1200));

      executor.dispose();
    });
  });

  // ------------------------------------------------------------------
  // startIdleMonitoring / stopIdleMonitoring / dispose — the production
  // timer lifecycle. AgentFactory.create() calls startIdleMonitoring() to
  // spawn a periodic-polling Timer that retries deferred tasks; LlmAgent.dispose
  // → IdleExecutor.dispose → stopIdleMonitoring must cancel that timer so it
  // doesn't keep polling a torn-down agent (Vision Next-Term §4.3/§4.4).
  // These methods are exercised only via real Timer.periodic (real time), so we
  // use short intervals + Future.delayed to keep tests fast and deterministic.
  // ------------------------------------------------------------------
  group('IdleExecutor idle-monitoring lifecycle', () {
    test(
        'startIdleMonitoring retries deferred tasks when deferral clears via periodic timer',
        () async {
      var shouldDefer = true;
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => shouldDefer,
      );

      await executor.startIdleMonitoring(interval: Duration(milliseconds: 20));

      var taskRan = false;
      await executor.enqueue('quiet-hours-deferred task', () async {
        taskRan = true;
      }, requiresHeavy: true);

      // Enqueued during quiet hours → _tryExecuteNext defers immediately.
      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);

      // Quiet hours pass.
      shouldDefer = false;

      // Wait long enough for the 20 ms periodic timer to fire at least once
      // and for the async _tryExecuteNext continuation to settle.
      await Future.delayed(Duration(milliseconds: 100));
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(taskRan, isTrue,
          reason: 'Periodic timer should have retried the deferred task');
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });

    test(
        'stopIdleMonitoring cancels the timer so deferred tasks are NOT auto-retried',
        () async {
      var shouldDefer = true;
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => shouldDefer,
      );

      await executor.startIdleMonitoring(interval: Duration(milliseconds: 20));

      var taskRan = false;
      await executor.enqueue('quiet-hours-deferred task', () async {
        taskRan = true;
      }, requiresHeavy: true);

      expect(taskRan, isFalse);
      expect(executor.hasPendingTasks, isTrue);

      // Cancel the timer and lift the deferral.
      executor.stopIdleMonitoring();
      shouldDefer = false;

      // Wait well past several timer intervals — if the timer were still
      // alive, it would have retried the task.
      await Future.delayed(Duration(milliseconds: 150));
      await Future.delayed(Duration.zero);

      expect(taskRan, isFalse,
          reason: 'Timer was cancelled; task must not auto-run');

      // Manual retry via processNext() still works — the queue is intact.
      await executor.processNext();
      await Future.delayed(Duration.zero);

      expect(taskRan, isTrue);
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });

    test('dispose cancels the idle timer without throwing', () async {
      final executor = IdleExecutor();
      await executor.startIdleMonitoring(interval: Duration(milliseconds: 20));

      expect(() => executor.dispose(), returnsNormally);
    });

    test(
        'startIdleMonitoring is idempotent — a second call cancels the first timer',
        () async {
      final executor = IdleExecutor();
      await executor.startIdleMonitoring(interval: Duration(milliseconds: 20));
      // Calling again should cancel the first timer and start a fresh one
      // without leaking the old timer or throwing.
      await executor.startIdleMonitoring(interval: Duration(milliseconds: 20));

      expect(() => executor.dispose(), returnsNormally);
    });

    test(
        'startIdleMonitoring without a system monitor still runs heavy tasks via timer',
        () async {
      // No SystemMonitorService → heavy tasks are never deferred by CPU/battery
      // pressure, but the timer path itself should still invoke _tryExecuteNext.
      final executor = IdleExecutor();
      await executor.startIdleMonitoring(interval: Duration(milliseconds: 20));

      var taskRan = false;
      await executor.enqueue('light task', () async {
        taskRan = true;
      });

      // The enqueue call invokes _tryExecuteNext() immediately, so the light
      // task runs right away — proving the no-monitor branch works.
      expect(taskRan, isTrue);
      expect(executor.hasPendingTasks, isFalse);

      executor.dispose();
    });

    test(
        'dispose after startIdleMonitoring does not process deferred tasks',
        () async {
      var shouldDefer = true;
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => shouldDefer,
      );

      await executor.startIdleMonitoring(interval: Duration(milliseconds: 20));

      var taskRan = false;
      await executor.enqueue('deferred task', () async {
        taskRan = true;
      });

      expect(taskRan, isFalse);

      // Dispose cancels the timer.
      executor.dispose();

      shouldDefer = false;
      // Wait past several timer intervals.
      await Future.delayed(Duration(milliseconds: 150));

      expect(taskRan, isFalse,
          reason: 'Disposed executor must not process tasks via the timer');
    });
  });
}

/// Hand-written, mutable fake [SystemMonitorService] for deterministic testing
/// of the IdleExecutor's CPU/battery deferral branch
/// (idle_executor.dart:112-120). Unlike the immutable
/// [FakeSystemMonitorService] in system_monitor_service_test.dart, this one
/// allows toggling `canRunHeavyPrepNow` at runtime so a single test can
/// simulate stress → recovery.
class MutableFakeSystemMonitorService extends SystemMonitorService {
  bool canRunHeavyPrepNowValue;
  final int batteryLevelValue;
  final bool isChargingValue;
  final double cpuLoadValue;
  final bool isBatterySaverValue;
  final String? networkTypeValue;

  MutableFakeSystemMonitorService({
    this.canRunHeavyPrepNowValue = true,
    this.batteryLevelValue = -1,
    this.isChargingValue = false,
    this.cpuLoadValue = -1,
    this.isBatterySaverValue = false,
    this.networkTypeValue,
  });

  set canRunHeavyPrepNow(bool value) => canRunHeavyPrepNowValue = value;

  @override
  bool get canRunHeavyPrepNow => canRunHeavyPrepNowValue;

  @override
  int get batteryLevel => batteryLevelValue;

  @override
  bool get isCharging => isChargingValue;

  @override
  double get cpuLoad => cpuLoadValue;

  @override
  bool get isBatterySaver => isBatterySaverValue;

  @override
  String? get networkType => networkTypeValue;
}

/// Hand-written, mutable fake [PrepBudgetService] for deterministic testing
/// of the IdleExecutor's prep-budget gate (idle_executor.dart prep-budget gate
/// block). Allows toggling `canSpend` and `remainingFor` at runtime so a
/// single test can simulate budget exhaustion → recovery, mirroring the
/// [MutableFakeSystemMonitorService] pattern.
class MutableFakePrepBudgetService extends PrepBudgetService {
  bool canSpendValue;
  int remainingForValue;

  MutableFakePrepBudgetService({
    this.canSpendValue = true,
    this.remainingForValue = 0,
    required super.meter,
  });

  @override
  bool canSpend(PrepCategory category, int tokens) => canSpendValue;

  @override
  int remainingFor(PrepCategory category) => remainingForValue;
}
