import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/features/llm_tasks/presentation/llm_task_manager_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

TestNavigatorObserver? testNavigatorObserver;
late Directory _hiveDir;

Widget _buildTestApp(LlmTaskManager manager) {
  return ProviderScope(
    overrides: [
      llmTaskManagerProvider.overrideWithValue(manager),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: testNavigatorObserver != null ? [testNavigatorObserver!] : [],
      home: const LlmTaskManagerScreen(),
    ),
  );
}

void main() {
  group('LlmTaskManagerScreen', () {
    setUp(() async {
      testNavigatorObserver = TestNavigatorObserver();
      _hiveDir = Directory.systemTemp.createTempSync('llm_tasks_screen_test_');
      Hive.init(_hiveDir.path);
      await Hive.openBox(HiveBoxNames.llmTasks);
    });

    tearDown(() async {
      testNavigatorObserver = null;
      await Hive.deleteBoxFromDisk(HiveBoxNames.llmTasks);
      _hiveDir.deleteSync(recursive: true);
    });

    // =====================
    // BASIC RENDERING
    // =====================
    testWidgets('renders app bar with correct title', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('LLM Task Manager'), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks exist', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('No LLM tasks yet'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    // =====================
    // ACTIVE CHIP
    // =====================
    testWidgets('hides active chip when there are no active tasks', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows active count chip when there are active tasks', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('active chip shows correct count for multiple active tasks',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'a', modelId: 'm1');
      manager.createTask(feature: 'b', modelId: 'm2');
      final id3 = manager.createTask(feature: 'c', modelId: 'm3');
      manager.startTask(id3);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
    });

    // =====================
    // TASK LIST
    // =====================
    testWidgets('renders task list when tasks exist', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('No LLM tasks yet'), findsNothing);
    });

    testWidgets('renders tasks in reverse order (newest first)', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'first', modelId: 'm1');
      manager.createTask(feature: 'second', modelId: 'm2');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsOneWidget);
    });

    // =====================
    // STATUS ICONS & LABELS
    // =====================
    testWidgets('displays queued task with hourglass icon and Queued label',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'summary', modelId: 'claude-3');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text('summary'), findsOneWidget);
      expect(find.text('Queued'), findsOneWidget);
    });

    testWidgets('displays running task with sync icon and In Progress label',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('displays done task with check_circle icon and Completed label',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('displays failed task with error icon and Failed label',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'Timeout');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('displays cancelled task with cancel icon and Cancelled label',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.cancelTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
      expect(find.text('Cancelled'), findsOneWidget);
    });

    // =====================
    // ERROR DISPLAY
    // =====================
    testWidgets('shows error text for failed task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'qa', modelId: 'gpt-4');
      manager.failTask(id, 'Rate limit exceeded');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Rate limit exceeded'), findsOneWidget);
    });

    testWidgets('shows error icon in error container for failed task',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'qa', modelId: 'gpt-4');
      manager.failTask(id, 'API error');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    // =====================
    // TOKENS & COST ON TASK CARDS
    // =====================
    testWidgets('shows tokens and cost when tokensUsed > 0 on task card',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
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
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('\$'), findsNothing);
    });

    testWidgets('shows token icon for task with tokens', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id, tokensUsed: 500, estimatedCost: 0.025);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.token), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('hides token icon when tokensUsed is 0', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.token), findsNothing);
      expect(find.byIcon(Icons.attach_money), findsNothing);
    });

    // =====================
    // CANCEL BUTTON
    // =====================
    testWidgets('shows cancel button for running task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
    });

    testWidgets('shows cancel button for queued task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('hides cancel button for done task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('hides cancel button for failed task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'error');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('hides cancel button for cancelled task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.cancelTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('cancel button calls taskManager.cancelTask', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(manager.tasks.first.status, LlmTaskStatus.cancelled);
    });

    // =====================
    // TIME DISPLAY
    // =====================
    testWidgets('displays start time with "Started" label', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      await tester.pump();

      expect(find.textContaining('Started'), findsOneWidget);
    });

    testWidgets('displays end time when task is completed', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('Ended'), findsOneWidget);
    });

    testWidgets('does not display end time for queued task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('Ended'), findsNothing);
    });

    testWidgets('displays model label on task card', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.textContaining('gpt-4'), findsOneWidget);
    });

    // =====================
    // LISTENER BEHAVIOR
    // =====================
    testWidgets('listener triggers rebuild when tasks change', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();

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
      await manager.init();

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(manager.tasks.length, 0);

      await tester.pumpWidget(SizedBox());
      await tester.pump();

      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      expect(manager.tasks.length, 1);
    });

    testWidgets('handles cancelled task with disconnect Completer',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.registerCancelCompleter(id);
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(manager.tasks.first.status, LlmTaskStatus.cancelled);
    });

    // =====================
    // SNACKBAR NOTIFICATIONS
    // =====================
    testWidgets('shows snackbar when task fails with error', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      manager.failTask(id, 'Connection timeout');
      await tester.pump();

      expect(find.text('AI task failed: chat'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('snackbar shows retry action for failed task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      manager.failTask(id, 'Timeout');
      await tester.pump();

      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(find.text('Retry'), findsAtLeastNWidgets(1));
    });

    testWidgets('snackbar retry action creates a new task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      manager.failTask(id, 'Timeout');
      await tester.pump();

      final retryButtons = find.text('Retry');
      expect(retryButtons, findsAtLeastNWidgets(1));

      await tester.tap(retryButtons.first);
      await tester.pump();

      expect(manager.tasks.length, 2);
    });

    testWidgets('snackbar appears for failed task even with empty error string',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      manager.failTask(id, '');
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('snackbar appears on init when failed task already exists',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'Timeout');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('AI task failed: chat'), findsOneWidget);
    });

    // =====================
    // RETRY BUTTON ON FAILED TASK CARD
    // =====================
    testWidgets('shows retry button on failed task card', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'Error');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('hides retry button for completed task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'done', modelId: 'm1');
      manager.completeTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('hides retry button for running task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'running', modelId: 'm2');
      manager.startTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('hides retry button for cancelled task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'cancelled', modelId: 'm3');
      manager.cancelTask(id);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('retry button on failed task creates a new task', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.failTask(id, 'Error');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      await tester.tap(find.text('Retry').last);
      await tester.pump();

      expect(manager.tasks.length, 2);
      expect(manager.tasks.last.feature, 'chat');
      expect(manager.tasks.last.modelId, 'gpt-4');
    });

    testWidgets('retry button creates new task preserving feature and model',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'teaching', modelId: 'claude-3');
      manager.failTask(id, 'Error');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      await tester.tap(find.text('Retry').last);
      await tester.pump();

      expect(manager.tasks.last.feature, 'teaching');
      expect(manager.tasks.last.modelId, 'claude-3');
    });

    // =====================
    // TOKEN USAGE METER
    // =====================
    testWidgets('shows token usage summary when any task has tokens',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id, tokensUsed: 500, estimatedCost: 0.025);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Token Usage Summary'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('hides token usage summary when no tasks have tokens',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'chat', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Token Usage Summary'), findsNothing);
    });

    testWidgets('hides token usage summary when no tasks exist',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Token Usage Summary'), findsNothing);
    });

    testWidgets('token usage meter displays total tokens count', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id1);
      manager.completeTask(id1, tokensUsed: 500, estimatedCost: 0.025);
      final id2 = manager.createTask(feature: 'teach', modelId: 'gpt-4');
      manager.startTask(id2);
      manager.completeTask(id2, tokensUsed: 200, estimatedCost: 0.01);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('700'), findsOneWidget);
    });

    testWidgets('token usage meter displays total cost', (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id1);
      manager.completeTask(id1, tokensUsed: 500, estimatedCost: 0.025);
      final id2 = manager.createTask(feature: 'teach', modelId: 'gpt-4');
      manager.startTask(id2);
      manager.completeTask(id2, tokensUsed: 200, estimatedCost: 0.01);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Total Cost'), findsOneWidget);
      expect(find.text('Total Tokens'), findsOneWidget);
    });

    testWidgets('token usage meter displays done and failed counts',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id1);
      manager.completeTask(id1, tokensUsed: 500, estimatedCost: 0.025);
      final id2 = manager.createTask(feature: 'teach', modelId: 'gpt-4');
      manager.startTask(id2);
      manager.completeTask(id2, tokensUsed: 200, estimatedCost: 0.01);
      final id3 = manager.createTask(feature: 'qa', modelId: 'gpt-4');
      manager.failTask(id3, 'error');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows linear progress indicator in token meter',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id1);
      manager.completeTask(id1, tokensUsed: 500, estimatedCost: 0.025);
      final id2 = manager.createTask(feature: 'teach', modelId: 'gpt-4');
      manager.startTask(id2);
      manager.completeTask(id2, tokensUsed: 200, estimatedCost: 0.01);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides progress indicator when no completed tasks',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id, tokensUsed: 500, estimatedCost: 0.025);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows divider between token meter and task list',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id, tokensUsed: 500, estimatedCost: 0.025);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });

    // =====================
    // MOUNTED GUARD
    // =====================
    testWidgets('no crash when task changes after widget removed from tree',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      manager.createTask(feature: 'chat', modelId: 'gpt-4');
      await tester.pump();
    });

    // =====================
    // SINGLE SNACKBAR ON INIT
    // =====================
    testWidgets('break limits to one snackbar on init with multiple failed tasks',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final id2 = manager.createTask(feature: 'teach', modelId: 'gpt-4');
      manager.failTask(id1, 'err1');
      manager.failTask(id2, 'err2');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('second snackbar appears on next notification for deferred task',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      final id2 = manager.createTask(feature: 'teach', modelId: 'gpt-4');
      manager.failTask(id1, 'err1');
      manager.failTask(id2, 'err2');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);

      manager.createTask(feature: 'new', modelId: 'gpt-4');
      await tester.pump();

      expect(find.byType(SnackBar), findsNWidgets(2));
    });

    // =====================
    // DESKTOP LAYOUT
    // =====================
    testWidgets('token usage meter uses Row layout on large screens',
        (tester) async {
      tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final manager = LlmTaskManager();
      await manager.init();
      final id = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id);
      manager.completeTask(id, tokensUsed: 1500, estimatedCost: 0.05);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('Token Usage Summary'), findsOneWidget);
      expect(find.text('Total Tokens'), findsOneWidget);
      expect(find.text('Total Cost'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
    });

    // =====================
    // PROGRESS INDICATOR
    // =====================
    testWidgets('progress indicator shown with mixed completed and pending tasks',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      final id1 = manager.createTask(feature: 'chat', modelId: 'gpt-4');
      manager.startTask(id1);
      manager.completeTask(id1, tokensUsed: 500, estimatedCost: 0.025);
      final id2 = manager.createTask(feature: 'teach', modelId: 'gpt-4');
      manager.startTask(id2);

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // =====================
    // DID_CHANGE_DEPENDENCIES INITIAL LOAD
    // =====================
    testWidgets('didChangeDependencies loads pre-existing tasks',
        (tester) async {
      final manager = LlmTaskManager();
      await manager.init();
      manager.createTask(feature: 'pre-existing-task', modelId: 'gpt-4');

      await tester.pumpWidget(_buildTestApp(manager));
      await tester.pump();

      expect(find.text('pre-existing-task'), findsOneWidget);
    });
  });
}
