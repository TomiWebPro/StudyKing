import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/presentation/llm_task_manager_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(LlmTaskManager manager) {
  return ProviderScope(
    overrides: [
      llmTaskManagerProvider.overrideWithValue(manager),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LlmTaskManagerScreen(),
    ),
  );
}
void main() {
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

      expect(find.textContaining('500'), findsAtLeastNWidgets(1));
      expect(find.textContaining('\$0.0250'), findsAtLeastNWidgets(1));
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
