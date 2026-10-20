import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/mentor/services/tools/pre_generate_lesson_tool.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'test_helpers.dart';

/// Hand-written fake that mirrors the existing FakeLessonAgentService
/// pattern so we don't depend on another test file's fakes.
class FakeLessonAgentServicePrep extends LessonAgentService {
  String lastFeature = 'lesson_agent';
  String? lastTaskType;
  final LlmUsageMeter? meter;

  Future<Lesson?> Function({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    String localeName,
    String feature,
    String? taskType,
  })? onGenerateLesson;

  FakeLessonAgentServicePrep({this.meter})
      : super(
          llmService: LlmService(
            config: LlmConfiguration(
              provider: LlmProvider.openAI,
              apiKey: 'test',
            ),
          ),
          modelId: 'test',
          lessonRepository: FakeLessonRepository(),
          database: DatabaseService(
            topicRepository: FakeTopicRepository(),
            questionRepository: FakeQuestionRepository(),
            attemptRepository: FakeAttemptRepository(),
            lessonRepository: FakeLessonRepository(),
            sessionRepository: FakeSessionRepository(),
            subjectRepository: FakeSubjectRepository(),
            conversationRepository: ConversationRepository(),
            tutorSessionRepository: FakeTutorSessionRepository(),
          ),
        );

  @override
  Future<Lesson?> generateLesson({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    String localeName = 'en',
    String feature = 'lesson_agent',
    String? taskType,
  }) async {
    lastFeature = feature;
    lastTaskType = taskType ?? LlmTaskType.fromFeature(feature)?.name;
    // Simulate _recordCompletion: record actual tokens on the meter.
    meter?.recordUsage(
      id: 'lesson_prep_fake_${DateTime.now().millisecondsSinceEpoch}',
      feature: feature,
      modelId: 'gpt-4o',
      inputTokens: 1000,
      outputTokens: 500,
      taskType: lastTaskType,
    );
    if (onGenerateLesson != null) {
      return onGenerateLesson!(
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        localeName: localeName,
        feature: feature,
        taskType: taskType,
      );
    }
    return null;
  }
}

Lesson _buildTestLesson({
  required String subjectId,
  required String topicId,
  required String topicTitle,
}) {
  return Lesson(
    id: 'lesson-123',
    subjectId: subjectId,
    title: topicTitle,
    topicId: topicId,
    blocks: [
      LessonBlock(
        id: 'b1',
        subjectId: subjectId,
        lessonId: '',
        type: LessonBlockType.text,
        content: 'Hello',
        order: 0,
      ),
    ],
    generatedBy: GeneratedBy.ai,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('PreGenerateLessonTool', () {
    late FakeLessonAgentServicePrep fakeService;

    setUp(() {
      fakeService = FakeLessonAgentServicePrep();
    });

    group('tool metadata', () {
      test('name returns pre_generate_lesson', () {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        expect(tool.name, 'pre_generate_lesson');
      });

      test('description is not empty', () {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        expect(tool.description, isNotEmpty);
      });

      test('parameters has correct JSON schema shape', () {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        final params = tool.parameters;
        expect(params['type'], 'object');
        final props = params['properties'] as Map;
        expect(props.keys, containsAll(['subjectId', 'topicId', 'topicTitle', 'localeName']));
        expect(props['localeName']['default'], equals('en'));
        expect(params['required'], ['subjectId', 'topicId', 'topicTitle']);
      });

      test('estimated tokens are positive', () {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        expect(tool.estimatedInputTokens, greaterThan(0));
        expect(tool.estimatedOutputTokens, greaterThan(0));
        expect(tool.estimatedTotalTokens,
            equals(tool.estimatedInputTokens + tool.estimatedOutputTokens));
      });

      test('cpuClass is heavy and needsNetwork is true', () {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        expect(tool.cpuClass, equals(PrepCpuClass.heavy));
        expect(tool.needsNetwork, isTrue);
      });

      test('prepCategory is lessonPrep', () {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        expect(tool.prepCategory, equals(PrepCategory.lessonPrep));
      });
    });

    group('execute', () {
      test('returns success with lesson data when generation succeeds', () async {
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          return _buildTestLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
        };

        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(result['success'], isTrue);
        expect(result['lessonId'], 'lesson-123');
        expect(result['blockCount'], 1);
        expect(result['title'], 'Algebra Basics');
      });

      test('returns failure message when lesson generation returns null',
          () async {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(result['success'], isFalse);
        expect(result['message'], 'Failed to generate lesson');
      });

      test('returns failure when required parameters are missing', () async {
        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        final result = await tool.execute({
          'subjectId': '',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(result['success'], isFalse);
        expect(result['error'], contains('required'));
      });

      test('passes default locale when localeName is omitted', () async {
        String? capturedLocale;
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          capturedLocale = localeName;
          return null;
        };

        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(capturedLocale, 'en');
      });

      test('passes custom locale when localeName is provided', () async {
        String? capturedLocale;
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          capturedLocale = localeName;
          return null;
        };

        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
          'localeName': 'es',
        });

        expect(capturedLocale, 'es');
      });

      // Vision §0 token principle + §4.1: when PreGenerateLessonTool runs as
      // an off-period prep task, the underlying LessonAgentService.generateLesson
      // call must receive feature='lesson_prep' so LlmTaskType.fromFeature maps
      // it to LlmTaskType.background (a prep category) — not 'generation'
      // (a live category). This prevents actual lesson-prep tokens from leaking
      // into PrepBudgetService.totalLiveTokens() (issue: prep-lesson-prep-tokens
      // misattributed-as-live).
      test('passes feature: lesson_prep to LessonAgentService', () async {
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          return _buildTestLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
        };

        final tool = PreGenerateLessonTool(lessonAgentService: fakeService);
        await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(fakeService.lastFeature, 'lesson_prep');
        expect(fakeService.lastTaskType, PrepCategory.lessonPrep.taskTypeKey);
      });
    });

    group('budget enforcement', () {
      test('denies when prep budget is disabled', () async {
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: const PrepBudget(enabled: false, caps: {}),
        );
        final tool = PreGenerateLessonTool(
          lessonAgentService: fakeService,
          budgetService: budget,
        );
        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(result['success'], isFalse);
        expect(result['error'], contains('budget'));
        expect(result['deferrable'], isTrue);
      });

      test('allows when budget is enabled', () async {
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          return _buildTestLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
        };

        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(meter: meter);
        final tool = PreGenerateLessonTool(
          lessonAgentService: fakeService,
          budgetService: budget,
        );
        final result = await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(result['success'], isTrue);
      });
    });

    group('task manager integration', () {
      test('creates, starts, and completes an LlmTask on success', () async {
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          return _buildTestLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
        };

        final tm = LlmTaskManager();
        final tool = PreGenerateLessonTool(
          lessonAgentService: fakeService,
          taskManager: tm,
        );
        await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(tm.tasks.any((t) => t.feature == 'lesson_prep'), isTrue);
        expect(tm.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);
      });

      test('completes task even when generation returns null', () async {
        final tm = LlmTaskManager();
        final tool = PreGenerateLessonTool(
          lessonAgentService: fakeService,
          taskManager: tm,
        );
        await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(tm.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);
      });
    });

    group('usage metering', () {
      test('records actual usage under lesson_prep taskType (no double-count)', () async {
        final meter = LlmUsageMeter();
        final service = FakeLessonAgentServicePrep(meter: meter);
        service.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          return _buildTestLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
        };

        final tool = PreGenerateLessonTool(
          lessonAgentService: service,
          usageMeter: meter,
        );
        await tool.execute({
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        // The PrepTool passed taskType: 'lesson_prep' so the fake recorded
        // actual tokens under 'lesson_prep' — not 'background' (fromFeature).
        expect(service.lastTaskType, equals(PrepCategory.lessonPrep.taskTypeKey));
        final byType = meter.getTotalTokensPerTaskType();
        final key = PrepCategory.lessonPrep.taskTypeKey;
        expect(byType[key], greaterThan(0));
        // No double-counting: 'background' must be empty for this call.
        expect(byType['background'], isNull);
        final budget = PrepBudgetService(meter: meter);
        expect(budget.totalPrepTokens(), equals(byType[key]));
      });
    });

    group('per-subject opt-in enforcement', () {
      test(
          'skips LLM and records no tokens when subject is disabled', () async {
        var llmCalled = false;
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          llmCalled = true;
          return _buildTestLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
        };

        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: PrepBudget.defaults
              .copyWith(disabledSubjects: {'disabled-subj'}),
        );
        final tool = PreGenerateLessonTool(
          lessonAgentService: fakeService,
          budgetService: budget,
          usageMeter: meter,
        );
        final result = await tool.execute({
          'subjectId': 'disabled-subj',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        // Vision §4.2: a paused syllabus must never invoke the LLM or spend
        // tokens — the tool returns a deferrable failure instead.
        expect(result['success'], isFalse);
        expect(result['deferrable'], isTrue);
        expect(llmCalled, isFalse);
        expect(meter.getTotalTokens(), equals(0));
      });

      test('proceeds for an enabled subject within the budget', () async {
        fakeService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
          String feature = 'lesson_agent',
          String? taskType,
        }) async {
          return _buildTestLesson(
            subjectId: subjectId,
            topicId: topicId,
            topicTitle: topicTitle,
          );
        };

        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: PrepBudget.defaults.copyWith(disabledSubjects: {'blocked'}),
        );
        final tool = PreGenerateLessonTool(
          lessonAgentService: fakeService,
          budgetService: budget,
          usageMeter: meter,
        );
        final result = await tool.execute({
          'subjectId': 'enabled-subj',
          'topicId': 'topic-1',
          'topicTitle': 'Algebra Basics',
        });

        expect(result['success'], isTrue);
        expect(result['lessonId'], 'lesson-123');
        // Prep actually ran and was metered under the lesson_prep bucket.
        expect(
          meter.getTotalTokensPerTaskType()['lesson_prep'],
          greaterThan(0),
        );
      });
    });
  });
}
