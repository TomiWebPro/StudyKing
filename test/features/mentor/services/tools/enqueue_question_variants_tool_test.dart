import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/mentor/services/tools/enqueue_question_variants_tool.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'test_helpers.dart';

/// Hand-written fake [QuestionVariantService] that returns canned variants.
/// When [meter] is provided, it records simulated LLM usage on the meter
/// (mirroring what the real QuestionVariantService does via LlmService.chat
/// → _recordCompletion), so tests can verify token attribution without
/// double-counting.
class FakeQuestionVariantService extends QuestionVariantService {
  Future<Result<List<Question>>> Function(Question source, {int? count, String? taskType})? onGenerate;
  String? lastTaskType;
  final LlmUsageMeter? meter;

  FakeQuestionVariantService({this.meter})
      : super(
          questionRepo: FakeQuestionRepository(),
          llmService: LlmService(
            config: LlmConfiguration(
              provider: LlmProvider.openAI,
              apiKey: 'test',
            ),
          ),
          modelId: 'test',
        );

  @override
  Future<Result<List<Question>>> generateVariants(
    Question source, {
    int count = 3,
    String? taskType,
  }) async {
    lastTaskType = taskType ?? LlmTaskType.fromFeature('question_variants')?.name;
    // Simulate _recordCompletion: record actual tokens on the meter.
    meter?.recordUsage(
      id: 'qv_fake_${DateTime.now().millisecondsSinceEpoch}',
      feature: 'question_variants',
      modelId: 'variant_generation',
      inputTokens: 500,
      outputTokens: 300,
      taskType: lastTaskType,
    );
    if (onGenerate != null) {
      return onGenerate!(source, count: count, taskType: taskType);
    }
    return Result.success([]);
  }
}

/// Fake repository that supports [get] by ID (the base [FakeQuestionRepository]
/// does not override get since it requires a Hive box).
class _FakeQuestionRepoWithGet extends FakeQuestionRepository {
  final Map<String, Question> _byId = {};

  _FakeQuestionRepoWithGet([Map<String, Question>? byId]) {
    if (byId != null) {
      _byId.addAll(byId);
      setQuestions(byId.values.toList());
    }
  }

  void setQuestionById(String id, Question question) {
    _byId[id] = question;
    setQuestions(_byId.values.toList());
  }

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.success(_byId[key]);
}

Question _buildTestQuestion(String id) {
  return Question(
    id: id,
    text: 'What is 2+2?',
    type: QuestionType.singleChoice,
    difficulty: 1,
    subjectId: 'math',
    topicId: 'arithmetic',
    options: ['4', '3', '5'],
    markscheme: Markscheme(
      questionId: id,
      correctAnswer: '4',
      acceptableAnswers: const [],
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('EnqueueQuestionVariantsTool', () {
    late FakeQuestionVariantService fakeVariantService;

    setUp(() {
      fakeVariantService = FakeQuestionVariantService();
    });

    group('tool metadata', () {
      test('name returns enqueue_question_variants', () {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );
        expect(tool.name, 'enqueue_question_variants');
      });

      test('description is not empty', () {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );
        expect(tool.description, isNotEmpty);
      });

      test('parameters has correct JSON schema shape', () {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );
        final params = tool.parameters;
        expect(params['type'], 'object');
        final props = params['properties'] as Map;
        expect(props.keys, containsAll(['questionId', 'count']));
        expect(props['count']['type'], 'integer');
        expect(props['count']['default'], 3);
        expect(params['required'], ['questionId']);
      });

      test('estimated tokens are positive', () {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );
        expect(tool.estimatedInputTokens, greaterThan(0));
        expect(tool.estimatedOutputTokens, greaterThan(0));
        expect(tool.estimatedTotalTokens,
            equals(tool.estimatedInputTokens + tool.estimatedOutputTokens));
      });

      test('cpuClass is heavy and needsNetwork is true', () {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );
        expect(tool.cpuClass, equals(PrepCpuClass.heavy));
        expect(tool.needsNetwork, isTrue);
      });

      test('prepCategory is questionVariants', () {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );
        expect(tool.prepCategory, equals(PrepCategory.questionVariants));
      });
    });

    group('execute', () {
      test('returns success with variant count when generation succeeds',
          () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        fakeVariantService.onGenerate = (source, {count = 3, String? taskType}) async {
          return Result.success([
            _buildTestQuestion('v1'),
            _buildTestQuestion('v2'),
            _buildTestQuestion('v3'),
          ]);
        };

        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
        );

        final result = await tool.execute({
          'questionId': 'q1',
          'count': 3,
        });

        expect(result['success'], isTrue);
        expect(result['variantCount'], 3);
        expect(result['sourceQuestionId'], 'q1');
        final variantIds = result['variantIds'] as List;
        expect(variantIds, containsAll(['v1', 'v2', 'v3']));
      });

      test('returns failure when questionId is empty', () async {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );

        final result = await tool.execute({'questionId': ''});

        expect(result['success'], isFalse);
        expect(result['error'], contains('questionId'));
      });

      test('returns failure when questionId is missing', () async {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );

        final result = await tool.execute({});

        expect(result['success'], isFalse);
      });

      test('returns failure when question is not found', () async {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );

        final result = await tool.execute({'questionId': 'nonexistent'});

        expect(result['success'], isFalse);
        expect(result['error'], contains('not found'));
      });

      test('parses stringified count argument without throwing', () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        var capturedCount = 0;
        fakeVariantService.onGenerate = (source, {count = 3, String? taskType}) async {
          capturedCount = count ?? 3;
          return Result.success([]);
        };

        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
        );

        await tool.execute({'questionId': 'q1', 'count': '5'});

        expect(capturedCount, 5);
      });

      test('uses default count of 3 when count is omitted', () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        var capturedCount = 0;
        fakeVariantService.onGenerate = (source, {count = 3, String? taskType}) async {
          capturedCount = count ?? 3;
          return Result.success([]);
        };

        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
        );

        await tool.execute({'questionId': 'q1'});

        expect(capturedCount, 3);
      });

      test('returns failure when count is zero or negative', () async {
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
        );

        final result = await tool.execute({'questionId': 'q1', 'count': 0});

        expect(result['success'], isFalse);
        expect(result['error'], contains('count'));
      });
    });

    group('budget enforcement', () {
      test('denies when prep budget is disabled', () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: const PrepBudget(enabled: false, caps: {}),
        );

        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
          budgetService: budget,
        );

        final result = await tool.execute({'questionId': 'q1'});

        expect(result['success'], isFalse);
        expect(result['error'], contains('budget'));
        expect(result['deferrable'], isTrue);
        // Service should not have been called.
        expect(fakeVariantService.onGenerate != null, isFalse);
      });

      test('allows when budget is enabled', () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        fakeVariantService.onGenerate = (source, {count = 3, String? taskType}) async {
          return Result.success([_buildTestQuestion('v1')]);
        };

        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(meter: meter);

        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
          budgetService: budget,
        );

        final result = await tool.execute({'questionId': 'q1'});

        expect(result['success'], isTrue);
        expect(result['variantCount'], 1);
      });
    });

    group('task manager integration', () {
      test('creates, starts, and completes an LlmTask on success', () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        fakeVariantService.onGenerate = (source, {count = 3, String? taskType}) async {
          return Result.success([_buildTestQuestion('v1')]);
        };

        final tm = LlmTaskManager();
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
          taskManager: tm,
        );

        await tool.execute({'questionId': 'q1'});

        expect(tm.tasks.any((t) => t.feature == 'question_variants'), isTrue);
        expect(tm.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);
      });

      test('does not create a task when question is not found', () async {
        // The question is fetched before task creation so that a
        // not-found question returns a failure without registering a
        // spurious failed task on the task manager.
        final tm = LlmTaskManager();
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: _FakeQuestionRepoWithGet(),
          taskManager: tm,
        );

        final result = await tool.execute({'questionId': 'nonexistent'});

        expect(result['success'], isFalse);
        expect(result['error'], contains('not found'));
        expect(tm.tasks, isEmpty);
      });
    });

    group('per-subject opt-in enforcement', () {
      // Vision §4.2: "per-syllabus opt-in." A student who toggles a subject
      // off must not have tokens spent on it. Mirrors the enforcement in
      // IngestPdfToKbTool and PreGenerateLessonTool.

      test(
          'skips variant generation and records no tokens when subject is disabled',
          () async {
        var variantServiceCalled = false;
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: PrepBudget.defaults.copyWith(disabledSubjects: {'math'}),
        );
        // If the subject gate fails, this should never be invoked.
        fakeVariantService.onGenerate = (source, {count = 3, String? taskType}) async {
          variantServiceCalled = true;
          return Result.success([]);
        };

        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
          budgetService: budget,
          usageMeter: meter,
        );

        final result = await tool.execute({'questionId': 'q1'});

        // Vision §4.2: a paused syllabus must never invoke the variant
        // service or record tokens.
        expect(result['success'], isFalse);
        expect(result['error'], contains('disabled by student'));
        expect(result['deferrable'], isTrue);
        expect(variantServiceCalled, isFalse,
            reason: 'Variant service must not be called for a disabled subject');
        expect(meter.getTotalTokens(), equals(0));
      });

      test('does not register a disabled-subject task on LlmTaskManager',
          () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: PrepBudget.defaults.copyWith(disabledSubjects: {'math'}),
        );

        final tm = LlmTaskManager();
        final tool = EnqueueQuestionVariantsTool(
          variantService: fakeVariantService,
          questionRepo: repo,
          taskManager: tm,
          budgetService: budget,
          usageMeter: meter,
        );

        await tool.execute({'questionId': 'q1'});

        expect(
          tm.tasks,
          isEmpty,
          reason: 'Disabled-subject task must never reach the task manager',
        );
      });

      test('proceeds for an enabled subject within budget', () async {
        final question = _buildTestQuestion('q1'); // subjectId == 'math' by default
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        final meter = LlmUsageMeter();
        final service = FakeQuestionVariantService(meter: meter);
        service.onGenerate = (source, {count = 3, String? taskType}) async {
          return Result.success([_buildTestQuestion('v1')]);
        };
        final budget = PrepBudgetService(
          meter: meter,
          budget: PrepBudget.defaults.copyWith(disabledSubjects: {'other'}),
        );

        final tool = EnqueueQuestionVariantsTool(
          variantService: service,
          questionRepo: repo,
          budgetService: budget,
          usageMeter: meter,
        );

        final result = await tool.execute({'questionId': 'q1'});

        expect(result['success'], isTrue);
        expect(result['variantCount'], 1);
        expect(service.lastTaskType, equals(PrepCategory.questionVariants.taskTypeKey));
        expect(
          meter.getTotalTokensPerTaskType()['question_variants'],
          greaterThan(0),
        );
      });
    });

    group('usage metering', () {
      test('records actual usage under question_variants taskType (no double-count)', () async {
        final question = _buildTestQuestion('q1');
        final repo = _FakeQuestionRepoWithGet({'q1': question});
        final meter = LlmUsageMeter();
        // Wire the meter into the fake service so it records actual tokens
        // under the taskType override (simulating LlmService._recordCompletion).
        final service = FakeQuestionVariantService(meter: meter);
        service.onGenerate = (source, {count = 3, String? taskType}) async {
          return Result.success([_buildTestQuestion('v1')]);
        };

        final tool = EnqueueQuestionVariantsTool(
          variantService: service,
          questionRepo: repo,
          usageMeter: meter,
        );

        await tool.execute({'questionId': 'q1'});

        // The PrepTool passed taskType: 'question_variants' to generateVariants,
        // so the fake recorded actual tokens under 'question_variants' — not
        // 'background' (the fromFeature fallback).
        expect(service.lastTaskType, equals(PrepCategory.questionVariants.taskTypeKey));
        final byType = meter.getTotalTokensPerTaskType();
        final key = PrepCategory.questionVariants.taskTypeKey;
        expect(byType[key], greaterThan(0));
        // No double-counting: 'background' must be empty for this call.
        expect(byType['background'], isNull);
        final budget = PrepBudgetService(meter: meter);
        expect(budget.totalPrepTokens(), equals(byType[key]));
      });
    });
  });
}
