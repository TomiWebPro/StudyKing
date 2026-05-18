import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';

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
}
