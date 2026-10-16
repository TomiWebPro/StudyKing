import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';
import 'package:studyking/features/mentor/services/tools/refresh_mastery_tool.dart';
import 'test_helpers.dart';

void main() {
  group('RefreshMasteryTool', () {
    late FakeMasteryGraphService mastery;
    late FakeStudentIdService studentIdService;

    setUp(() {
      mastery = FakeMasteryGraphService();
      studentIdService = FakeStudentIdService('student-1');
    });

    group('tool metadata', () {
      test('name returns refresh_mastery', () {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );
        expect(tool.name, 'refresh_mastery');
      });

      test('description is not empty', () {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );
        expect(tool.description, isNotEmpty);
      });

      test('parameters has correct JSON schema shape', () {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );
        final params = tool.parameters;
        expect(params['type'], 'object');
        final props = params['properties'] as Map;
        expect(props.keys, contains('studentId'));
        expect(params['required'], isEmpty);
      });

      test('estimated tokens are small (light prep)', () {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );
        expect(tool.estimatedInputTokens, 500);
        expect(tool.estimatedOutputTokens, 500);
        expect(tool.estimatedTotalTokens, 1000);
      });

      test('cpuClass is light and needsNetwork is false', () {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );
        expect(tool.cpuClass, equals(PrepCpuClass.light));
        expect(tool.needsNetwork, isFalse);
      });

      test('prepCategory is background', () {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );
        expect(tool.prepCategory, equals(PrepCategory.background));
      });
    });

    group('execute', () {
      test('returns weak topics and at-risk counts from the mastery service',
          () async {
        final weak = <MasteryState>[
          MasteryState.initial(studentId: 'student-1', topicId: 't1')
              .copyWith(accuracy: 0.4, reviewUrgency: 0.8, readinessScore: 0.3),
          MasteryState.initial(studentId: 'student-1', topicId: 't2')
              .copyWith(accuracy: 0.2, reviewUrgency: 0.9, readinessScore: 0.1),
        ];
        final atRisk = <QuestionMasteryState>[
          QuestionMasteryState.initial(
            studentId: 'student-1',
            questionId: 'q1',
            now: DateTime.now(),
          ),
        ];
        mastery = FakeMasteryGraphService(weakTopics: weak, atRisk: atRisk);

        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );

        final result = await tool.execute({});

        expect(result['success'], isTrue);
        expect(result['studentId'], 'student-1');
        expect(result['weakTopicCount'], equals(2));
        expect(result['atRiskQuestionCount'], equals(1));
        expect(result['needsReviewTopics'], equals(2));
      });

      test('uses explicit studentId when provided', () async {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );

        final result = await tool.execute({'studentId': 'explicit-student'});

        expect(result['success'], isTrue);
        expect(result['studentId'], 'explicit-student');
      });

      test('falls back to StudentIdService when studentId is omitted',
          () async {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );

        final result = await tool.execute({});
        expect(result['success'], isTrue);
        expect(result['studentId'], 'student-1');
      });

      test('degrades gracefully with no weak topics or at-risk questions',
          () async {
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );

        final result = await tool.execute({});
        expect(result['success'], isTrue);
        expect(result['weakTopicCount'], equals(0));
        expect(result['atRiskQuestionCount'], equals(0));
        expect(result['needsReviewTopics'], equals(0));
      });

      test('returns failure when no student ID is available', () async {
        final noIdService = FakeStudentIdService('');
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: noIdService,
        );

        final result = await tool.execute({});
        expect(result['success'], isFalse);
        expect(result['error'], contains('No student ID'));
      });
    });

    group('task manager integration', () {
      test('creates a background task and completes it', () async {
        final tm = LlmTaskManager();
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
          taskManager: tm,
        );
        await tool.execute({});
        expect(tm.tasks.any((t) => t.feature == 'mastery_refresh'), isTrue);
        expect(tm.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);
      });
    });

    group('usage metering', () {
      test('records usage with taskType background', () async {
        final meter = LlmUsageMeter();
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
          usageMeter: meter,
        );
        await tool.execute({});
        final byType = meter.getTotalTokensPerTaskType();
        final key = PrepCategory.background.taskTypeKey;
        expect(byType[key], greaterThan(0));
      });
    });

    group('budget enforcement', () {
      test('budget does not block light prep by default', () async {
        final meter = LlmUsageMeter();
        // Fill the background category to its cap (50000) to deny.
        meter.recordUsage(
          id: 'u1',
          feature: 'prep',
          modelId: 'gpt-4',
          inputTokens: 50000,
          outputTokens: 0,
          taskType: 'background',
        );
        final budget = PrepBudgetService(meter: meter);
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
          budgetService: budget,
        );

        // Light prep still proceeds — budget check is advisory for light tasks.
        // The tool records estimated usage but doesn't deny based on budget
        // for light tasks (they don't consume significant tokens).
        final result = await tool.execute({});
        expect(result['success'], isTrue);
      });

      test('disabled budget still allows light prep to complete', () async {
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: const PrepBudget(enabled: false, caps: {}),
        );
        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
          budgetService: budget,
        );
        final result = await tool.execute({});
        expect(result['success'], isTrue);
      });
    });
  });
}
