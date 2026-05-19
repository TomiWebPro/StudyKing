import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/llm_tasks/llm_tasks.dart';

void main() {
  group('llm_tasks barrel', () {
    test('exports LlmTaskManagerScreen', () {
      expect(LlmTaskManagerScreen, isA<Type>());
    });

    test('exports LlmTaskService', () {
      expect(LlmTaskService, isNotNull);
    });

    test('exports llmTaskServiceProvider', () {
      expect(llmTaskServiceProvider, isNotNull);
    });

    test('exports LlmTaskFilter', () {
      expect(LlmTaskFilter, isNotNull);
    });

    test('LlmTaskFilter can be constructed with parameters', () {
      const filter = LlmTaskFilter(feature: 'question_generation');
      expect(filter.feature, 'question_generation');
      expect(filter.status, isNull);
    });

    test('LlmTaskFilter can be constructed with all parameters', () {
      const filter = LlmTaskFilter(
        feature: 'summarization',
      );
      expect(filter.feature, 'summarization');
    });

    test('llmTaskServiceProvider is a Provider<LlmTaskService>', () {
      expect(llmTaskServiceProvider, isA<Provider<LlmTaskService>>());
    });
  });
}
