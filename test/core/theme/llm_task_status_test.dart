import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/theme/llm_task_status.dart';

void main() {
  group('LlmTaskStatus', () {
    test('has queued value', () {
      expect(LlmTaskStatus.queued, isA<LlmTaskStatus>());
    });

    test('has running value', () {
      expect(LlmTaskStatus.running, isA<LlmTaskStatus>());
    });

    test('has done value', () {
      expect(LlmTaskStatus.done, isA<LlmTaskStatus>());
    });

    test('has failed value', () {
      expect(LlmTaskStatus.failed, isA<LlmTaskStatus>());
    });

    test('has cancelled value', () {
      expect(LlmTaskStatus.cancelled, isA<LlmTaskStatus>());
    });

    test('contains all expected values', () {
      expect(LlmTaskStatus.values, hasLength(5));
      expect(
        LlmTaskStatus.values,
        containsAll([
          LlmTaskStatus.queued,
          LlmTaskStatus.running,
          LlmTaskStatus.done,
          LlmTaskStatus.failed,
          LlmTaskStatus.cancelled,
        ]),
      );
    });

    test('values are in expected order', () {
      expect(LlmTaskStatus.values[0], LlmTaskStatus.queued);
      expect(LlmTaskStatus.values[1], LlmTaskStatus.running);
      expect(LlmTaskStatus.values[2], LlmTaskStatus.done);
      expect(LlmTaskStatus.values[3], LlmTaskStatus.failed);
      expect(LlmTaskStatus.values[4], LlmTaskStatus.cancelled);
    });

    test('queued has index 0', () {
      expect(LlmTaskStatus.queued.index, 0);
    });

    test('running has index 1', () {
      expect(LlmTaskStatus.running.index, 1);
    });

    test('done has index 2', () {
      expect(LlmTaskStatus.done.index, 2);
    });

    test('failed has index 3', () {
      expect(LlmTaskStatus.failed.index, 3);
    });

    test('cancelled has index 4', () {
      expect(LlmTaskStatus.cancelled.index, 4);
    });

    test('values are unique', () {
      expect(
        LlmTaskStatus.values.toSet().length,
        LlmTaskStatus.values.length,
      );
    });

    test('name returns correct string representation', () {
      expect(LlmTaskStatus.queued.name, 'queued');
      expect(LlmTaskStatus.running.name, 'running');
      expect(LlmTaskStatus.done.name, 'done');
      expect(LlmTaskStatus.failed.name, 'failed');
      expect(LlmTaskStatus.cancelled.name, 'cancelled');
    });
  });
}
