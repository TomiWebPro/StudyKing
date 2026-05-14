import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/presentation/llm_task_manager_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(LlmTaskManager manager) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: LlmTaskManagerScreen(taskManager: manager),
  );
}
void main() {
  group('LlmTask model', () {
    test('constructor sets fields correctly', () {
      final now = DateTime.now();
      final task = LlmTask(
        id: 't1',
        feature: 'chat',
        modelId: 'gpt-4',
        startTime: now,
      );

      expect(task.id, 't1');
      expect(task.feature, 'chat');
      expect(task.modelId, 'gpt-4');
      expect(task.status, LlmTaskStatus.queued);
      expect(task.startTime, now);
      expect(task.endTime, isNull);
      expect(task.tokensUsed, 0);
      expect(task.estimatedCost, 0.0);
      expect(task.error, isNull);
      expect(task.cancelCompleter, isNull);
    });

    test('copyWith updates specified fields', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1));
      final task = LlmTask(
        id: 't1',
        feature: 'chat',
        modelId: 'gpt-4',
        startTime: now,
      );

      final copied = task.copyWith(
        status: LlmTaskStatus.done,
        endTime: later,
        tokensUsed: 150,
        estimatedCost: 0.03,
        error: null,
      );

      expect(copied.id, 't1');
      expect(copied.feature, 'chat');
      expect(copied.modelId, 'gpt-4');
      expect(copied.status, LlmTaskStatus.done);
      expect(copied.startTime, now);
      expect(copied.endTime, later);
      expect(copied.tokensUsed, 150);
      expect(copied.estimatedCost, 0.03);
      expect(copied.error, isNull);
    });

    test('copyWith retains unspecified fields', () {
      final now = DateTime.now();
      final task = LlmTask(
        id: 't1',
        feature: 'chat',
        modelId: 'gpt-4',
        startTime: now,
        status: LlmTaskStatus.running,
        tokensUsed: 50,
        estimatedCost: 0.01,
        error: 'something went wrong',
      );

      final copied = task.copyWith(status: LlmTaskStatus.done);

      expect(copied.status, LlmTaskStatus.done);
      expect(copied.id, 't1');
      expect(copied.feature, 'chat');
      expect(copied.modelId, 'gpt-4');
      expect(copied.startTime, now);
      expect(copied.tokensUsed, 50);
      expect(copied.estimatedCost, 0.01);
      expect(copied.error, 'something went wrong');
    });

    test('copyWith preserves cancelCompleter', () {
      final now = DateTime.now();
      final task = LlmTask(
        id: 't1',
        feature: 'chat',
        modelId: 'gpt-4',
        startTime: now,
      );

      final copied = task.copyWith(status: LlmTaskStatus.running);

      expect(copied.cancelCompleter, isNull);
    });
  });

  group('LlmTaskManager', () {
    late LlmTaskManager manager;

    setUp(() {
      manager = LlmTaskManager();
    });

    test('initial state has no tasks', () {
      expect(manager.tasks, isEmpty);
      expect(manager.activeTasks, isEmpty);
    });

    test('createTask adds a task and returns an id', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(id, startsWith('task_'));
      expect(manager.tasks.length, 1);
      expect(manager.tasks.first.feature, 'chat');
      expect(manager.tasks.first.modelId, 'gpt-4');
      expect(manager.tasks.first.status, LlmTaskStatus.queued);
    });

    test('createTask increments counter', () {
      final id1 = manager.createTask(feature: 'a', modelId: 'm1');
      final id2 = manager.createTask(feature: 'b', modelId: 'm2');

      expect(manager.tasks.length, 2);
      expect(id1, isNot(id2));
    });

    test('startTask changes status to running', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);

      expect(manager.tasks.first.status, LlmTaskStatus.running);
    });

    test('startTask does nothing for non-existent task', () {
      manager.startTask('nonexistent');
      expect(manager.tasks, isEmpty);
    });

    test('completeTask changes status to done and sets endTime/tokens/cost', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id, tokensUsed: 200, estimatedCost: 0.05);

      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.done);
      expect(task.endTime, isNotNull);
      expect(task.tokensUsed, 200);
      expect(task.estimatedCost, 0.05);
    });

    test('completeTask does nothing for non-existent task', () {
      manager.completeTask('nonexistent');
      expect(manager.tasks, isEmpty);
    });

    test('failTask changes status to failed and sets error', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'API error');

      final task = manager.tasks.first;
      expect(task.status, LlmTaskStatus.failed);
      expect(task.endTime, isNotNull);
      expect(task.error, 'API error');
    });

    test('failTask does nothing for non-existent task', () {
      manager.failTask('nonexistent', 'error');
      expect(manager.tasks, isEmpty);
    });

    test('cancelTask cancels a running task', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.cancelTask(id);

      expect(manager.tasks.first.status, LlmTaskStatus.cancelled);
      expect(manager.tasks.first.endTime, isNotNull);
    });

    test('cancelTask cancels a queued task', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.cancelTask(id);

      expect(manager.tasks.first.status, LlmTaskStatus.cancelled);
    });

    test('cancelTask does nothing for done task', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id);
      manager.cancelTask(id);

      expect(manager.tasks.first.status, LlmTaskStatus.done);
    });

    test('cancelTask does nothing for failed task', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'error');
      manager.cancelTask(id);

      expect(manager.tasks.first.status, LlmTaskStatus.failed);
    });

    test('cancelTask does nothing for non-existent task', () {
      manager.cancelTask('nonexistent');
      expect(manager.tasks, isEmpty);
    });

    test('activeTasks returns only running and queued tasks', () {
      final id1 = manager.createTask(feature: 'a', modelId: 'm1');
      final id2 = manager.createTask(feature: 'b', modelId: 'm2');
      manager.startTask(id1);
      final id3 = manager.createTask(feature: 'c', modelId: 'm3');
      manager.startTask(id2);
      manager.completeTask(id2);

      expect(manager.activeTasks.length, 2);
      expect(manager.activeTasks.any((t) => t.id == id1), isTrue);
      expect(manager.activeTasks.any((t) => t.id == id3), isTrue);
    });

    test('tasks is unmodifiable', () {
      manager.createTask(feature: 'a', modelId: 'm1');

      expect(() => manager.tasks.add(manager.tasks.first), throwsA(isA<Error>()));
    });

    test('addListener and removeListener work', () {
      int callCount = 0;
      void listener() {
        callCount++;
      }

      manager.addListener(listener);
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(callCount, 1);

      manager.removeListener(listener);
      manager.createTask(feature: 'chat2', modelId: 'gpt-4');

      expect(callCount, 1);
    });

    test('registerCancelCompleter returns a completer and stores it', () {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final completer = manager.registerCancelCompleter(id);

      expect(completer, isNotNull);
      expect(manager.tasks.first.cancelCompleter, isNotNull);
    });

    test('registerCancelCompleter returns null for non-existent task', () {
      final completer = manager.registerCancelCompleter('nonexistent');
      expect(completer, isNull);
    });

    test('cancelTask completes the cancelCompleter', () async {
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final completer = manager.registerCancelCompleter(id);

      manager.startTask(id);
      manager.cancelTask(id);

      await expectLater(completer!.future, completes);
    });
  });

  group('LlmTaskManagerScreen', () {
    testWidgets('renders app bar with correct title', (tester) async {
      await tester.pumpWidget(_buildTestApp(LlmTaskManager()));
      await tester.pump();

      expect(find.text('LLM Task Manager'), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks exist', (tester) async {
      await tester.pumpWidget(_buildTestApp(LlmTaskManager()));
      await tester.pump();

      expect(find.text('No LLM tasks yet'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('hides active chip when there are no active tasks', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows active count chip when there are active tasks', (tester) async {
      final manager = LlmTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('active chip shows correct count for multiple active tasks', (tester) async {
      final manager = LlmTaskManager();
      manager.createTask(feature: 'a', modelId: 'm1');
      manager.createTask(feature: 'b', modelId: 'm2');
      final id3 = manager.createTask(feature: 'c', modelId: 'm3');
      manager.startTask(id3);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('renders task list when tasks exist', (tester) async {
      final manager = LlmTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('No LLM tasks yet'), findsNothing);
    });

    testWidgets('displays queued task with correct icon and colors', (tester) async {
      final manager = LlmTaskManager();
      manager.createTask(feature: 'summary', modelId: 'claude-3');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text('summary'), findsOneWidget);
      expect(find.text('queued'), findsOneWidget);
    });

    testWidgets('displays running task with sync icon', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
    });

    testWidgets('displays done task with check_circle icon', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('displays failed task with error icon', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'Timeout');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('failed'), findsOneWidget);
    });

    testWidgets('displays cancelled task with cancel icon', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.cancelTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
      expect(find.text('cancelled'), findsOneWidget);
    });

    testWidgets('shows error text for failed task', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'qa', modelId: 'gpt-4');
      manager.failTask(id, 'Rate limit exceeded');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Rate limit exceeded'), findsOneWidget);
    });

    testWidgets('shows tokens and cost when tokensUsed > 0', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id, tokensUsed: 500, estimatedCost: 0.025);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('500'), findsOneWidget);
      expect(find.textContaining('\$0.0250'), findsOneWidget);
    });

    testWidgets('hides tokens and cost when tokensUsed is 0', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('\$'), findsNothing);
    });

    testWidgets('shows cancel button for running task', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
    });

    testWidgets('shows cancel button for queued task', (tester) async {
      final manager = LlmTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('hides cancel button for done task', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('hides cancel button for failed task', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'error');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('hides cancel button for cancelled task', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.cancelTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('cancel button calls taskManager.cancelTask', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(manager.tasks.first.status, LlmTaskStatus.cancelled);
    });

    testWidgets('displays end time when available', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('Ended'), findsOneWidget);
    });

    testWidgets('displays model label', (tester) async {
      final manager = LlmTaskManager();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('gpt-4'), findsOneWidget);
    });

    testWidgets('renders tasks in reverse order (newest first)', (tester) async {
      final manager = LlmTaskManager();
      manager.createTask(feature: 'first', modelId: 'm1');
      manager.createTask(feature: 'second', modelId: 'm2');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsOneWidget);
    });

    testWidgets('listener triggers rebuild when tasks change', (tester) async {
      final manager = LlmTaskManager();

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('No LLM tasks yet'), findsOneWidget);

      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      await tester.pump();

      expect(find.text('chat'), findsOneWidget);
      expect(find.text('No LLM tasks yet'), findsNothing);
    });

    testWidgets('disposes listener correctly', (tester) async {
      final manager = LlmTaskManager();

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      final beforeCount = manager.tasks.length;
      expect(beforeCount, 0);

      await tester.pumpWidget(SizedBox());
      await tester.pump();

      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(manager.tasks.length, 1);
    });

    testWidgets('shows start time formatted correctly', (tester) async {
      final manager = LlmTaskManager();

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      await tester.pump();

      expect(find.textContaining('Started'), findsOneWidget);
    });

    testWidgets('handles cancelled task with disconnect Completer', (tester) async {
      final manager = LlmTaskManager();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.registerCancelCompleter(id);
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(manager.tasks.first.status, LlmTaskStatus.cancelled);
    });
  });
}
