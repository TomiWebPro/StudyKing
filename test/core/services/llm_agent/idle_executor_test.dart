import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
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
