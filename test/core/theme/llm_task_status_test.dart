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
        containsAll([LlmTaskStatus.queued, LlmTaskStatus.running, LlmTaskStatus.done, LlmTaskStatus.failed, LlmTaskStatus.cancelled]),
      );
    });
  });
}
