import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/llm_tasks/llm_tasks.dart';

void main() {
  group('llm_tasks barrel', () {
    test('exports LlmTaskManagerScreen', () {
      expect(LlmTaskManagerScreen, isA<Type>());
    });
  });
}
