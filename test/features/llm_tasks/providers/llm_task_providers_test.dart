import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/features/llm_tasks/providers/llm_task_providers.dart';

void main() {
  group('LlmTaskService provider', () {
    test('allTasksProvider returns empty list', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) {
            final manager = LlmTaskManager();
            return manager;
          }),
        ],
      );
      addTearDown(() => container.dispose());
      final tasks = container.read(allTasksProvider);
      expect(tasks, isEmpty);
    });

    test('activeTasksProvider returns empty list', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) => LlmTaskManager()),
        ],
      );
      addTearDown(() => container.dispose());
      final tasks = container.read(activeTasksProvider);
      expect(tasks, isEmpty);
    });

    test('totalTaskTokensProvider returns 0', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) => LlmTaskManager()),
        ],
      );
      addTearDown(() => container.dispose());
      final tokens = container.read(totalTaskTokensProvider);
      expect(tokens, 0);
    });

    test('totalTaskCostProvider returns 0.0', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) => LlmTaskManager()),
        ],
      );
      addTearDown(() => container.dispose());
      final cost = container.read(totalTaskCostProvider);
      expect(cost, 0.0);
    });
  });
}
