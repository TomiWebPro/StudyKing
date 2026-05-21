import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/features/llm_tasks/providers/llm_task_providers.dart';
import 'package:studyking/features/llm_tasks/services/llm_task_service.dart';

class _FakeLlmTaskManager extends LlmTaskManager {
  final List<LlmTask> _seededTasks;
  bool shouldThrow = false;

  _FakeLlmTaskManager(this._seededTasks);

  @override
  Future<void> init() async {}

  @override
  List<LlmTask> get tasks {
    if (shouldThrow) throw Exception('Manager error');
    return List.unmodifiable(_seededTasks);
  }

  @override
  List<LlmTask> get activeTasks {
    if (shouldThrow) throw Exception('Manager error');
    return _seededTasks
        .where((t) =>
            t.status == LlmTaskStatus.running || t.status == LlmTaskStatus.queued)
        .toList();
  }
}

LlmTask _task({
  required String id,
  required String feature,
  LlmTaskStatus status = LlmTaskStatus.done,
  int tokensUsed = 0,
  double estimatedCost = 0.0,
}) {
  return LlmTask(
    id: id,
    feature: feature,
    modelId: 'test-model',
    status: status,
    startTime: DateTime.now(),
    tokensUsed: tokensUsed,
    estimatedCost: estimatedCost,
  );
}

void main() {
  group('LlmTaskService provider', () {
    test('allTasksProvider returns empty list when no tasks', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) => _FakeLlmTaskManager([])),
        ],
      );
      addTearDown(() => container.dispose());
      final tasks = container.read(allTasksProvider);
      expect(tasks, isEmpty);
    });

    test('activeTasksProvider returns empty list when no tasks', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) => _FakeLlmTaskManager([])),
        ],
      );
      addTearDown(() => container.dispose());
      final tasks = container.read(activeTasksProvider);
      expect(tasks, isEmpty);
    });

    test('totalTaskTokensProvider returns 0 when no tasks', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) => _FakeLlmTaskManager([])),
        ],
      );
      addTearDown(() => container.dispose());
      final tokens = container.read(totalTaskTokensProvider);
      expect(tokens, 0);
    });

    test('totalTaskCostProvider returns 0.0 when no tasks', () {
      final container = ProviderContainer(
        overrides: [
          llmTaskManagerProvider.overrideWith((ref) => _FakeLlmTaskManager([])),
        ],
      );
      addTearDown(() => container.dispose());
      final cost = container.read(totalTaskCostProvider);
      expect(cost, 0.0);
    });

    group('with seeded data', () {
      late List<LlmTask> seededTasks;
      late _FakeLlmTaskManager fakeManager;

      setUp(() {
        seededTasks = [
          _task(id: 't1', feature: 'chat', tokensUsed: 100, estimatedCost: 0.002),
          _task(id: 't2', feature: 'chat', tokensUsed: 200, estimatedCost: 0.004,
              status: LlmTaskStatus.running),
          _task(id: 't3', feature: 'teaching', tokensUsed: 500, estimatedCost: 0.01),
          _task(id: 't4', feature: 'teaching', tokensUsed: 0, estimatedCost: 0.0,
              status: LlmTaskStatus.queued),
          _task(id: 't5', feature: 'practice', tokensUsed: 300, estimatedCost: 0.006,
              status: LlmTaskStatus.failed),
        ];
        fakeManager = _FakeLlmTaskManager(seededTasks);
      });

      test('allTasksProvider returns all seeded tasks', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        final tasks = container.read(allTasksProvider);
        expect(tasks.length, 5);
        expect(tasks.map((t) => t.id), containsAll(['t1', 't2', 't3', 't4', 't5']));
      });

      test('activeTasksProvider returns only running and queued tasks', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        final active = container.read(activeTasksProvider);
        expect(active.length, 2);
        expect(active.map((t) => t.id), containsAll(['t2', 't4']));
      });

      test('totalTaskTokensProvider sums tokens across all tasks', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        final total = container.read(totalTaskTokensProvider);
        expect(total, 1100);
      });

      test('totalTaskCostProvider sums cost across all tasks', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        final total = container.read(totalTaskCostProvider);
        expect(total, closeTo(0.022, 0.0001));
      });

      test('taskTokenUsageProvider returns per-feature token breakdown', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        final usage = container.read(taskTokenUsageProvider);
        expect(usage['chat'], 300);
        expect(usage['teaching'], 500);
        expect(usage['practice'], 300);
      });

      test('taskCostProvider returns per-feature cost breakdown', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        final cost = container.read(taskCostProvider);
        expect(cost['chat'], closeTo(0.006, 0.0001));
        expect(cost['teaching'], closeTo(0.01, 0.0001));
        expect(cost['practice'], closeTo(0.006, 0.0001));
      });
    });

    group('filteredTasksProvider', () {
      late List<LlmTask> seededTasks;
      late _FakeLlmTaskManager fakeManager;

      setUp(() {
        seededTasks = [
          _task(id: 't1', feature: 'chat', status: LlmTaskStatus.done),
          _task(id: 't2', feature: 'chat', status: LlmTaskStatus.running),
          _task(id: 't3', feature: 'teaching', status: LlmTaskStatus.done),
          _task(id: 't4', feature: 'teaching', status: LlmTaskStatus.queued),
        ];
        fakeManager = _FakeLlmTaskManager(seededTasks);
      });

      test('filters by feature', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        final chatTasks = container.read(
          filteredTasksProvider(const LlmTaskFilter(feature: 'chat')),
        );
        expect(chatTasks.length, 2);
        expect(chatTasks.every((t) => t.feature == 'chat'), isTrue);
      });

      test('filters by status', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        const filter = LlmTaskFilter(status: LlmTaskStatus.done);
        final doneTasks = container.read(filteredTasksProvider(filter));
        expect(doneTasks.length, 2);
        expect(doneTasks.every((t) => t.status == LlmTaskStatus.done), isTrue);
      });

      test('filters by both feature and status', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        const filter = LlmTaskFilter(feature: 'teaching', status: LlmTaskStatus.queued);
        final result = container.read(filteredTasksProvider(filter));
        expect(result.length, 1);
        expect(result.single.id, 't4');
      });

      test('returns empty when no tasks match filter', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fakeManager),
          ],
        );
        addTearDown(() => container.dispose());

        const filter = LlmTaskFilter(feature: 'practice');
        final result = container.read(filteredTasksProvider(filter));
        expect(result, isEmpty);
      });
    });

    group('error propagation', () {
      test('allTasksProvider propagates manager error', () {
        final throwing = _FakeLlmTaskManager([])..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => throwing),
          ],
        );
        addTearDown(() => container.dispose());

        expect(() => container.read(allTasksProvider), throwsException);
      });

      test('activeTasksProvider propagates manager error', () {
        final throwing = _FakeLlmTaskManager([])..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => throwing),
          ],
        );
        addTearDown(() => container.dispose());

        expect(() => container.read(activeTasksProvider), throwsException);
      });

      test('totalTaskTokensProvider propagates manager error', () {
        final throwing = _FakeLlmTaskManager([])..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => throwing),
          ],
        );
        addTearDown(() => container.dispose());

        expect(() => container.read(totalTaskTokensProvider), throwsException);
      });

      test('totalTaskCostProvider propagates manager error', () {
        final throwing = _FakeLlmTaskManager([])..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => throwing),
          ],
        );
        addTearDown(() => container.dispose());

        expect(() => container.read(totalTaskCostProvider), throwsException);
      });

      test('taskTokenUsageProvider propagates manager error', () {
        final throwing = _FakeLlmTaskManager([])..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => throwing),
          ],
        );
        addTearDown(() => container.dispose());

        expect(() => container.read(taskTokenUsageProvider), throwsException);
      });

      test('taskCostProvider propagates manager error', () {
        final throwing = _FakeLlmTaskManager([])..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => throwing),
          ],
        );
        addTearDown(() => container.dispose());

        expect(() => container.read(taskCostProvider), throwsException);
      });

      test('filteredTasksProvider propagates manager error', () {
        final throwing = _FakeLlmTaskManager([])..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => throwing),
          ],
        );
        addTearDown(() => container.dispose());

        const filter = LlmTaskFilter(feature: 'chat');
        expect(() => container.read(filteredTasksProvider(filter)), throwsException);
      });
    });

    group('override wiring', () {
      test('overriding llmTaskManagerProvider affects all downstream providers',
          () async {
        final seeded = [
          _task(id: 't1', feature: 'chat', tokensUsed: 50, estimatedCost: 0.001),
        ];
        final fake = _FakeLlmTaskManager(seeded);

        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fake),
          ],
        );
        addTearDown(() => container.dispose());

        expect(container.read(allTasksProvider).length, 1);
        expect(container.read(totalTaskTokensProvider), 50);
        expect(container.read(totalTaskCostProvider), closeTo(0.001, 0.0001));
        expect(container.read(taskTokenUsageProvider)['chat'], 50);
      });
    });

    group('llmTaskServiceProvider', () {
      test('returns a LlmTaskService instance', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => _FakeLlmTaskManager([])),
          ],
        );
        addTearDown(() => container.dispose());

        final service = container.read(llmTaskServiceProvider);
        expect(service, isA<LlmTaskService>());
      });

      test('service delegates to the overridden manager', () {
        final seeded = [
          _task(id: 't1', feature: 'chat', tokensUsed: 100, estimatedCost: 0.002),
        ];
        final fake = _FakeLlmTaskManager(seeded);
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => fake),
          ],
        );
        addTearDown(() => container.dispose());

        final service = container.read(llmTaskServiceProvider);
        expect(service.getAllTasks(), hasLength(1));
        expect(service.getAllTasks().single.id, 't1');
        expect(service.totalTokenUsage, 100);
      });

      test('service reflects empty state from manager', () {
        final container = ProviderContainer(
          overrides: [
            llmTaskManagerProvider.overrideWith((ref) => _FakeLlmTaskManager([])),
          ],
        );
        addTearDown(() => container.dispose());

        final service = container.read(llmTaskServiceProvider);
        expect(service.getAllTasks(), isEmpty);
        expect(service.totalTokenUsage, 0);
        expect(service.totalEstimatedCost, 0.0);
      });
    });
  });

  group('LlmTaskFilter', () {
    test('default constructor sets both fields to null', () {
      const filter = LlmTaskFilter();
      expect(filter.feature, isNull);
      expect(filter.status, isNull);
    });

    test('constructor with only feature sets status to null', () {
      const filter = LlmTaskFilter(feature: 'chat');
      expect(filter.feature, 'chat');
      expect(filter.status, isNull);
    });

    test('constructor with only status sets feature to null', () {
      const filter = LlmTaskFilter(status: LlmTaskStatus.running);
      expect(filter.feature, isNull);
      expect(filter.status, LlmTaskStatus.running);
    });

    test('constructor with both fields sets both', () {
      const filter = LlmTaskFilter(
        feature: 'teaching',
        status: LlmTaskStatus.done,
      );
      expect(filter.feature, 'teaching');
      expect(filter.status, LlmTaskStatus.done);
    });

    test('uses identity equality (non-const different instances are not equal)', () {
      final a = LlmTaskFilter(feature: 'chat', status: LlmTaskStatus.done);
      final b = LlmTaskFilter(feature: 'chat', status: LlmTaskStatus.done);
      expect(a == b, isFalse);
      expect(identical(a, b), isFalse);
    });

    test('can be used as a family provider argument', () {
      const filter = LlmTaskFilter(feature: 'practice', status: LlmTaskStatus.failed);
      expect(filter.feature, 'practice');
      expect(filter.status, LlmTaskStatus.failed);
    });
  });
}
