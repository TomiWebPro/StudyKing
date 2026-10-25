import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/system_monitor_service.dart';
import 'package:studyking/features/llm_tasks/services/prep_queue_service.dart';

void main() {
  group('PrepQueueService', () {
    // Vision Next-Term §4.2: deferred prep jobs must be visible in the task
    // portal as queued work with a reason, and the student must be able to
    // cancel or try them now. These tests exercise the bridge that feeds the
    // portal from the real IdleExecutor queue.

    test('exposes a deferred task with its reason', () async {
      final executor = IdleExecutor(shouldDeferForQuietHours: (_) => true);
      addTearDown(executor.dispose);
      final service = PrepQueueService(executors: [executor]);
      addTearDown(service.dispose);

      await executor.enqueue('ingest chemistry pdf', () async {});

      expect(service.queuedTasks, hasLength(1));
      expect(service.queuedTasks.single.description, 'ingest chemistry pdf');
      expect(
        service.queuedTasks.single.deferredReason,
        PrepDeferralReason.quietHours,
      );
    });

    test('merges several executors without duplicating a shared queue',
        () async {
      final quiet = IdleExecutor(shouldDeferForQuietHours: (_) => true);
      final loaded = IdleExecutor(systemMonitor: _BlockedMonitor());
      addTearDown(quiet.dispose);
      addTearDown(loaded.dispose);
      final service = PrepQueueService(executors: [quiet, loaded, quiet]);
      addTearDown(service.dispose);

      await quiet.enqueue('quiet-hours job', () async {});
      await loaded.enqueue('heavy job', () async {}, requiresHeavy: true);

      final tasks = service.queuedTasks;
      expect(tasks.map((t) => t.description).toSet(),
          {'quiet-hours job', 'heavy job'});
      expect(tasks, hasLength(2), reason: 'a shared queue must not render twice');
      expect(
        tasks.map((t) => t.deferredReason).toSet(),
        {PrepDeferralReason.quietHours, PrepDeferralReason.systemLoad},
      );
    });

    test('notifies listeners when the queue changes', () async {
      final executor = IdleExecutor(shouldDeferForQuietHours: (_) => true);
      addTearDown(executor.dispose);
      final service = PrepQueueService(executors: [executor]);
      addTearDown(service.dispose);

      var notifications = 0;
      service.addListener(() => notifications++);

      await executor.enqueue('prep variants', () async {});
      expect(notifications, greaterThanOrEqualTo(1));

      final queued = service.queuedTasks.single;
      expect(service.cancel(queued.id), isTrue);
      expect(notifications, greaterThanOrEqualTo(2));
      expect(service.queuedTasks, isEmpty);
    });

    test('cancel removes only waiting work and reports unknown ids', () async {
      final executor = IdleExecutor(shouldDeferForQuietHours: (_) => true);
      addTearDown(executor.dispose);
      final service = PrepQueueService(executors: [executor]);
      addTearDown(service.dispose);

      var ran = false;
      await executor.enqueue('cancel me', () async {
        ran = true;
      });

      expect(service.cancel('does-not-exist'), isFalse);
      expect(service.cancel(service.queuedTasks.single.id), isTrue);
      expect(service.queuedTasks, isEmpty);
      expect(executor.queue, isEmpty);
      expect(ran, isFalse);
    });

    test('try now runs deferred work once the gate clears', () async {
      var quietHours = true;
      var ran = false;
      final executor = IdleExecutor(
        shouldDeferForQuietHours: (_) => quietHours,
      );
      addTearDown(executor.dispose);
      final service = PrepQueueService(executors: [executor]);
      addTearDown(service.dispose);

      await executor.enqueue('pre-generate lesson', () async {
        ran = true;
      });
      expect(service.queuedTasks, hasLength(1));

      quietHours = false;
      await service.retryNow();

      expect(ran, isTrue);
      expect(service.queuedTasks, isEmpty,
          reason: 'a running task leaves the queued section');
    });

    test('dispose stops listening to the executors', () async {
      final executor = IdleExecutor(shouldDeferForQuietHours: (_) => true);
      addTearDown(executor.dispose);
      final service = PrepQueueService(executors: [executor]);

      var notifications = 0;
      service.addListener(() => notifications++);
      service.dispose();

      // A later queue mutation must not reach the disposed service's listeners.
      await executor.enqueue('after dispose', () async {});
      expect(notifications, 0);
    });
  });
}

/// Hand-written fake device monitor that always reports pressure, so heavy
/// prep is deferred with [PrepDeferralReason.systemLoad].
class _BlockedMonitor extends NoopSystemMonitorService {
  const _BlockedMonitor();

  @override
  bool get canRunHeavyPrepNow => false;
}
