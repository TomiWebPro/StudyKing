/// E2E traces for the 7 agent tools previously missing from the fake-mode
/// agentic suite (see `issues/open/e2e-missing-tool-trace-coverage.md`).
///
/// Each test feeds a realistic student utterance through the real [AgentLoop]
/// parser with the **real** mentor tool registered — not a generic stub —
/// and asserts the correct tool name, parsed arguments, and result feedback.
///
/// File placement: `test/integration/agentic_e2e/` (integration-level,
/// separate from unit and widget tests per AGENTS.md).
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_loop.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/mentor/services/tools/create_practice_session_tool.dart';
import 'package:studyking/features/mentor/services/tools/enqueue_question_variants_tool.dart';
import 'package:studyking/features/mentor/services/tools/generate_lesson_blocks_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_adherence_trends_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_lesson_history_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_syllabus_structure_tool.dart';
import 'package:studyking/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart';
import 'package:studyking/features/mentor/services/tools/modify_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/pre_generate_lesson_tool.dart';
import 'package:studyking/features/mentor/services/tools/refresh_mastery_tool.dart';
import 'package:studyking/features/mentor/services/tools/search_questions_tool.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

import '../../helpers/hive_init_helper.dart';
import '../../helpers/fakes.dart';
import '../../features/mentor/services/tools/test_helpers.dart' as tool_fakes;
import 'fakes.dart';

// ---------------------------------------------------------------------------
// Hand-written fakes for prep-tool e2e traces (no mockito/mocktail).
// ---------------------------------------------------------------------------

/// Fake [QuestionVariantService] that returns canned variants without calling
/// the LLM or persisting — used to isolate prep-tool trace coverage.
class FakeQuestionVariantService extends QuestionVariantService {
  Future<Result<List<Question>>> Function(Question source, {int? count})?
      onGenerate;

  FakeQuestionVariantService()
      : super(
          questionRepo: tool_fakes.FakeQuestionRepository(),
          llmService: LlmService(
            config: const LlmConfiguration(
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
  }) async {
    if (onGenerate != null) return onGenerate!(source, count: count);
    return Result.success([]);
  }
}

/// Fake [QuestionRepository] that supports [get] by ID (the base
/// [FakeQuestionRepository] does not override get since it requires a Hive box).
class FakeQuestionRepoWithGet extends tool_fakes.FakeQuestionRepository {
  final Map<String, Question> _byId = {};

  FakeQuestionRepoWithGet([Map<String, Question>? byId]) {
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

/// Fake [LessonAgentService] that returns a canned lesson without calling the
/// LLM or persisting — used to isolate prep-tool trace coverage.
class FakeLessonAgentServicePrep extends LessonAgentService {
  Future<Lesson?> Function({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    String localeName,
  })? onGenerateLesson;

  FakeLessonAgentServicePrep()
      : super(
          llmService: LlmService(
            config: const LlmConfiguration(
              provider: LlmProvider.openAI,
              apiKey: 'test',
            ),
          ),
          modelId: 'test',
          lessonRepository: tool_fakes.FakeLessonRepository(),
          database: DatabaseService(
            topicRepository: tool_fakes.FakeTopicRepository(),
            questionRepository: tool_fakes.FakeQuestionRepository(),
            attemptRepository: tool_fakes.FakeAttemptRepository(),
            lessonRepository: tool_fakes.FakeLessonRepository(),
            sessionRepository: tool_fakes.FakeSessionRepository(),
            subjectRepository: tool_fakes.FakeSubjectRepository(),
            conversationRepository: ConversationRepository(),
            tutorSessionRepository: tool_fakes.FakeTutorSessionRepository(),
          ),
        );

  @override
  Future<Lesson?> generateLesson({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    String localeName = 'en',
  }) async {
    if (onGenerateLesson != null) {
      return onGenerateLesson!(
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        localeName: localeName,
      );
    }
    return null;
  }
}

void main() {
  setUpAll(() async {
    await initializeHiveForIntegrationTests();
  });

  group('AgentLoop with additional mentor tools (coverage gap fix)', () {
    group('SearchQuestionsTool', () {
      test('reachable through AgentLoop from "search for fraction questions"',
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: search_questions\nARGUMENTS: {"keyword": "fractions", "subjectId": "math", "limit": 5}',
          'Found 3 questions about fractions.',
        ]);

        final questionRepo = FakeQuestionRepository(seed: [
          Question(
            id: 'q1',
            text: 'What is 1/2 + 1/4?',
            type: QuestionType.singleChoice,
            difficulty: 1,
            subjectId: 'math',
            topicId: 'fractions',
            topic: 'Fractions',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        final tool = SearchQuestionsTool(questionRepo: questionRepo);
        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Search for fraction questions',
          studentId: 'search-student',
          systemPrompt: 'You are a mentor with access to a question bank.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'search_questions');
        expect(response.toolCalls.first.arguments['keyword'], 'fractions');
        expect(response.toolCalls.first.arguments['subjectId'], 'math');
        expect(response.toolCalls.first.arguments['limit'], 5);
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['count'], 1);
      });
    });

    group('GenerateLessonBlocksTool', () {
      test('reachable through AgentLoop from "generate lesson blocks for Atoms"',
          () async {
        // The fake LLM serves three chat() calls in order:
        // 1. AgentLoop: TOOL_CALL directive
        // 2. LessonAgentService.generateLesson: JSON lesson blocks
        // 3. AgentLoop: final assistant response
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: generate_lesson_blocks\n'
          'ARGUMENTS: {"subjectId": "chem", "topicId": "chem-atoms", "topicTitle": "Atoms"}',
          '[{"type":"text","content":"Atoms are the basic building blocks of matter.","order":0}]',
          'I generated lesson blocks for the Atoms topic. You can review the lesson now.',
        ]);

        final taskManager = LlmTaskManager();
        final lessonRepo = LessonRepository();
        await lessonRepo.init();

        final lessonAgentService = LessonAgentService(
          llmService: fakeLlm,
          modelId: 'test-model',
          lessonRepository: lessonRepo,
          database: DatabaseService(
            topicRepository: TopicRepository(),
            questionRepository: QuestionRepository(),
            attemptRepository: AttemptRepository(),
            lessonRepository: lessonRepo,
            sessionRepository: SessionRepository(),
            subjectRepository: SubjectRepository(),
            conversationRepository: ConversationRepository(),
            tutorSessionRepository: TutorSessionRepository(),
          ),
          taskManager: taskManager,
        );

        final tool = GenerateLessonBlocksTool(
          lessonAgentService: lessonAgentService,
          localeName: 'en',
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
          taskManager: taskManager,
        );

        final response = await loop.run(
          userMessage: 'Generate lesson blocks for my Chemistry Atoms topic',
          studentId: 'lesson-blocks-student',
          systemPrompt: 'You are a mentor that prepares lessons ahead of time.',
          feature: 'mentor',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'generate_lesson_blocks');
        expect(response.toolCalls.first.arguments['subjectId'], 'chem');
        expect(response.toolCalls.first.arguments['topicId'], 'chem-atoms');
        expect(response.toolCalls.first.arguments['topicTitle'], 'Atoms');
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['blockCount'], 1);

        // Three chat() calls: AgentLoop (tool call), AgentLoop (tool result
        // feedback is not a chat call), LessonAgentService (lesson generation),
        // AgentLoop (final response).
        // FakeAgentLlmService records each chat message — 3 calls is expected.
        expect(fakeLlm.chatMessages, hasLength(3));
      });
    });

    group('ModifyPlanTool', () {
      test('reachable through AgentLoop from "extend my plan by 30 days"',
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: modify_plan\nARGUMENTS: {"action": "extend", "extendDays": 30}',
          'I extended your study plan by 30 days. Your new plan now covers the remaining topics with more time for review.',
        ]);

        final plan = tool_fakes.sampleLearningPlan(studentId: 'modify-student');
        final plannerService = tool_fakes.FakePlannerService(plan);

        final tool = ModifyPlanTool(
          plannerService: plannerService,
          localeName: 'en',
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Extend my plan by 30 days',
          studentId: 'modify-student',
          systemPrompt: 'You are a mentor that adjusts study plans.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'modify_plan');
        expect(response.toolCalls.first.arguments['action'], 'extend');
        expect(response.toolCalls.first.arguments['extendDays'], 30);
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['addedDays'], 30);
        expect(resultMap['newTotalDays'], greaterThan(30));
      });
    });

    group('GetAdherenceTrendsTool', () {
      test('reachable through AgentLoop from "how am I doing with my plan?"',
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: get_adherence_trends\nARGUMENTS: {"days": 14}',
          'You have no adherence data yet. Keep studying to build a trend analysis.',
        ]);

        final idService = FakeStudentIdService()
          ..setStudentId('adherence-student');

        final fakeRepo = tool_fakes.FakePlanAdherenceRepository([]);
        final orchestrator =
            tool_fakes.FakePlanAdherenceOrchestrator(fakeRepo);

        final tool = GetAdherenceTrendsTool(
          orchestrator: orchestrator,
          studentIdService: idService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'How am I doing with my study plan?',
          studentId: 'adherence-student',
          systemPrompt: 'You are a mentor that tracks study adherence.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'get_adherence_trends');
        expect(response.toolCalls.first.arguments['days'], 14);
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['totalDays'], 0);
        expect(resultMap['trend'], 'insufficient_data');
      });
    });

    group('GetLessonHistoryTool', () {
      test('reachable through AgentLoop from "show me my lesson history"',
          () async {
        final now = DateTime.now();
        final lesson = Lesson(
          id: 'lesson-1',
          subjectId: 'math',
          title: 'Introduction to Fractions',
          topicId: 'fractions',
          createdAt: now,
        );

        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: get_lesson_history\nARGUMENTS: {}',
          'You have 1 lesson in your history. The most recent was "Introduction to Fractions".',
        ]);

        final idService = FakeStudentIdService()
          ..setStudentId('history-student');

        final lessonRepo = tool_fakes.FakeLessonRepository([lesson]);
        final tutorRepo = tool_fakes.FakeTutorSessionRepository([]);

        final tool = GetLessonHistoryTool(
          lessonRepository: lessonRepo,
          tutorSessionRepository: tutorRepo,
          studentIdService: idService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Show me my lesson history',
          studentId: 'history-student',
          systemPrompt: 'You are a mentor that reviews lesson history.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'get_lesson_history');
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['totalFound'], 1);
      });
    });

    group('CreatePracticeSessionTool', () {
      test('reachable through AgentLoop from "create a practice session"',
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: create_practice_session\n'
          'ARGUMENTS: {"mode": "weak_areas", "subjectId": "math", "questionCount": 10}',
          'I created a practice session targeting your weak areas in math. No weak topics detected yet — keep up the great work!',
        ]);

        final idService = FakeStudentIdService()
          ..setStudentId('practice-student');

        final questionRepo = FakeQuestionRepository();
        final masteryService = tool_fakes.FakeMasteryGraphService(weakTopics: []);
        final srService = tool_fakes.FakeSpacedRepetitionService([]);
        final scorer = tool_fakes.FakeReadinessScorer();
        final examService = tool_fakes.FakeExamSessionService([]);

        final tool = CreatePracticeSessionTool(
          questionRepo: questionRepo,
          srService: srService,
          masteryService: masteryService,
          scorer: scorer,
          examSessionService: examService,
          studentIdService: idService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Create a practice session on my weak topics',
          studentId: 'practice-student',
          systemPrompt: 'You are a mentor that creates practice sessions.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'create_practice_session');
        expect(response.toolCalls.first.arguments['mode'], 'weak_areas');
        expect(response.toolCalls.first.arguments['subjectId'], 'math');
        expect(response.toolCalls.first.arguments['questionCount'], 10);
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['mode'], 'weak_areas');
      });
    });

    group('GetSyllabusStructureTool', () {
      test('reachable through AgentLoop from "show me my syllabus structure"',
          () async {
        final subject = Subject(
          id: 'subj-math',
          name: 'Mathematics',
        );
        final topic = Topic(
          id: 'topic-algebra',
          subjectId: 'subj-math',
          title: 'Algebra',
          description: 'Linear equations and functions',
          syllabusText: 'linear equations, functions',
        );

        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: get_syllabus_structure\nARGUMENTS: {}',
          'You have 1 subject in your syllabus: Mathematics with 1 topic: Algebra.',
        ]);

        final idService = FakeStudentIdService()
          ..setStudentId('syllabus-student');

        final subjectRepo = tool_fakes.FakeSubjectRepository([subject]);
        final topicRepo = tool_fakes.FakeTopicRepository([topic]);
        final masteryService = tool_fakes.FakeMasteryGraphService(allMastery: []);
        final depRepo = tool_fakes.FakeTopicDependencyRepository([]);

        final tool = GetSyllabusStructureTool(
          subjectRepo: subjectRepo,
          topicRepo: topicRepo,
          masteryService: masteryService,
          dependencyRepo: depRepo,
          studentIdService: idService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Show me my syllabus structure',
          studentId: 'syllabus-student',
          systemPrompt: 'You are a mentor that explores syllabus structure.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'get_syllabus_structure');
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['subjectCount'], 1);
      });
    });

    group('IngestPdfToKbTool', () {
      test('reachable through AgentLoop from "parse my Chemistry textbook"',
          () async {
        final fakeLlm = FakeAgentLlmService([
          // 1. AgentLoop parses the TOOL_CALL directive
          'TOOL_CALL: ingest_pdf_to_kb\n'
          r'ARGUMENTS: {"textContent": "Chemistry textbook content about atomic structure and chemical bonding.", "subjectId": "chem", "topicId": "atoms"}',
          // 2. Tool's _parseText calls chat() for chunk parsing
          '[{"heading":"Atoms","content":"Atoms are the basic units of matter."}]',
          // 3. AgentLoop final response
          "I've parsed your Chemistry textbook into knowledge-base chunks"
          ' for the Atoms topic.',
        ]);

        final tool = IngestPdfToKbTool(
          llmService: fakeLlm,
          modelId: 'test-model',
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Parse my Chemistry textbook into a knowledge base',
          studentId: 'ingest-student',
          systemPrompt: 'You are a mentor that processes study materials.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'ingest_pdf_to_kb');
        expect(response.toolCalls.first.arguments['subjectId'], 'chem');
        expect(response.toolCalls.first.arguments['topicId'], 'atoms');
        expect(
          response.toolCalls.first.arguments['textContent'],
          contains('Chemistry'),
        );
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['chunkCount'], 1);
        expect(resultMap['subjectId'], 'chem');
        expect(resultMap['topicId'], 'atoms');
      });

      test('budget-denied path surfaces when prep budget is disabled',
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: ingest_pdf_to_kb\n'
          'ARGUMENTS: {"textContent": "Some content", "subjectId": "chem"}',
          'Your preparation budget is exhausted. The PDF ingestion is deferred.',
        ]);

        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: const PrepBudget(enabled: false, caps: {}),
        );

        final tool = IngestPdfToKbTool(
          llmService: fakeLlm,
          modelId: 'test-model',
          budgetService: budget,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Parse my textbook',
          studentId: 'ingest-budget-student',
          systemPrompt: 'You are a mentor that processes study materials.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'ingest_pdf_to_kb');

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isFalse);
        expect(resultMap['deferrable'], isTrue);
      });
    });

    group('EnqueueQuestionVariantsTool', () {
      Question buildTestQuestion(String id) {
        return Question(
          id: id,
          text: 'What is $id?',
          type: QuestionType.singleChoice,
          difficulty: 1,
          subjectId: 'math',
          topicId: 'arithmetic',
          markscheme: Markscheme(
            questionId: id,
            correctAnswer: '4',
            acceptableAnswers: const [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      test('reachable through AgentLoop from "generate variants"', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: enqueue_question_variants\n'
          'ARGUMENTS: {"questionId": "q1", "count": 3}',
          'I generated 3 question variants for question q1.',
        ]);

        final questionRepo = FakeQuestionRepoWithGet({'q1': buildTestQuestion('q1')});

        final variantService = FakeQuestionVariantService();
        final generatedVariantIds = <String>[];
        variantService.onGenerate = (source, {int? count}) async {
          final c = count ?? 3;
          generatedVariantIds.clear();
          final variants = <Question>[];
          for (var i = 1; i <= c; i++) {
            final v = buildTestQuestion('v$i');
            variants.add(v);
            generatedVariantIds.add(v.id);
          }
          return Result.success(variants);
        };

        final tool = EnqueueQuestionVariantsTool(
          variantService: variantService,
          questionRepo: questionRepo,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Generate 3 variants for question q1',
          studentId: 'variant-student',
          systemPrompt:
              'You are a mentor that generates question variants.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'enqueue_question_variants');
        expect(response.toolCalls.first.arguments['questionId'], 'q1');
        expect(response.toolCalls.first.arguments['count'], 3);
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['variantCount'], 3);
        expect(resultMap['sourceQuestionId'], 'q1');
        expect(resultMap['variantIds'], containsAll(generatedVariantIds));
      });

      test('reports failure when question is not found', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: enqueue_question_variants\n'
          'ARGUMENTS: {"questionId": "nonexistent", "count": 2}',
          'I could not find that question. Please check the question ID and try again.',
        ]);

        final variantService = FakeQuestionVariantService();
        final tool = EnqueueQuestionVariantsTool(
          variantService: variantService,
          questionRepo: FakeQuestionRepoWithGet(),
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Generate variants for nonexistent question',
          studentId: 'variant-fail-student',
          systemPrompt:
              'You are a mentor that generates question variants.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'enqueue_question_variants');

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isFalse);
        expect(resultMap['error'], contains('not found'));
      });
    });

    group('PreGenerateLessonTool', () {
      test("reachable through AgentLoop from \"pre-build tomorrow's lesson\"",
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: pre_generate_lesson\n'
          'ARGUMENTS: {"subjectId": "math", "topicId": "algebra", "topicTitle": "Algebra Basics"}',
          "I pre-generated your Algebra Basics lesson. It'll be ready"
          ' when you start the lesson.',
        ]);

        final lessonAgentService = FakeLessonAgentServicePrep();
        lessonAgentService.onGenerateLesson = ({
          required String subjectId,
          required String topicId,
          required String topicTitle,
          String localeName = 'en',
        }) async {
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
                content: 'Algebra is the study of variables.',
                order: 0,
              ),
            ],
            generatedBy: GeneratedBy.ai,
            createdAt: DateTime.now(),
          );
        };

        final tool = PreGenerateLessonTool(
          lessonAgentService: lessonAgentService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: "Pre-build tomorrow's lesson on Algebra Basics",
          studentId: 'pregen-student',
          systemPrompt:
              'You are a mentor that pre-generates lesson content.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'pre_generate_lesson');
        expect(response.toolCalls.first.arguments['subjectId'], 'math');
        expect(response.toolCalls.first.arguments['topicId'], 'algebra');
        expect(
          response.toolCalls.first.arguments['topicTitle'],
          'Algebra Basics',
        );
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['lessonId'], 'lesson-123');
        expect(resultMap['blockCount'], 1);
        expect(resultMap['title'], 'Algebra Basics');
      });

      test('reports failure when generation returns null', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: pre_generate_lesson\n'
          'ARGUMENTS: {"subjectId": "chem", "topicId": "atoms", "topicTitle": "Atoms"}',
          'I could not pre-generate the lesson for Atoms. The topic may'
          ' not have enough material yet.',
        ]);

        final lessonAgentService = FakeLessonAgentServicePrep();
        // onGenerateLesson not set → returns null

        final tool = PreGenerateLessonTool(
          lessonAgentService: lessonAgentService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Pre-build tomorrow\'s Atoms lesson',
          studentId: 'pregen-fail-student',
          systemPrompt:
              'You are a mentor that pre-generates lesson content.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'pre_generate_lesson');

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isFalse);
        expect(resultMap['message'], contains('Failed to generate lesson'));
      });
    });

    group('RefreshMasteryTool', () {
      test('reachable through AgentLoop from "refresh my mastery"', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: refresh_mastery\nARGUMENTS: {}',
          'I refreshed your mastery analysis. 2 topics need review and'
          ' 1 question is at risk.',
        ]);

        final mastery = tool_fakes.FakeMasteryGraphService(
          weakTopics: [
            MasteryState.initial(
              studentId: 'mastery-student',
              topicId: 't1',
            ).copyWith(
              accuracy: 0.4,
              reviewUrgency: 0.8,
              readinessScore: 0.3,
            ),
            MasteryState.initial(
              studentId: 'mastery-student',
              topicId: 't2',
            ).copyWith(
              accuracy: 0.5,
              reviewUrgency: 0.7,
              readinessScore: 0.4,
            ),
          ],
          atRisk: [
            QuestionMasteryState.initial(
              studentId: 'mastery-student',
              questionId: 'q1',
              now: DateTime.now(),
            ),
          ],
        );
        final studentIdService =
            tool_fakes.FakeStudentIdService('mastery-student');

        final tool = RefreshMasteryTool(
          masteryService: mastery,
          studentIdService: studentIdService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: "Refresh my mastery after today's practice",
          studentId: 'mastery-student',
          systemPrompt:
              'You are a mentor that refreshes mastery data.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'refresh_mastery');
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['studentId'], 'mastery-student');
        expect(resultMap['weakTopicCount'], 2);
        expect(resultMap['atRiskQuestionCount'], 1);
        expect(resultMap['needsReviewTopics'], 2);
      });
    });

    group('multi-tool scenario trace', () {
      test(
          'get_syllabus_structure → create_practice_session → get_lesson_history '
          'scenario trace', () async {
        final fakeLlm = FakeAgentLlmService([
          // Step 1: explore syllabus
          'TOOL_CALL: get_syllabus_structure\nARGUMENTS: {"subjectId": "subj-math"}',
          // Step 2: create practice session
          'TOOL_CALL: create_practice_session\n'
          'ARGUMENTS: {"mode": "weak_areas", "subjectId": "subj-math", "questionCount": 5}',
          // Step 3: check lesson history
          'TOOL_CALL: get_lesson_history\nARGUMENTS: {}',
          // Final response
          'Your syllabus covers Algebra. I created a practice session targeting your weak areas. '
          'You have 0 past lessons so far. Let\'s start building your study history!',
        ]);

        final idService = FakeStudentIdService()..setStudentId('multi-student');

        // Syllabus structure tool dependencies
        final subject = Subject(id: 'subj-math', name: 'Mathematics');
        final topic = Topic(
          id: 'topic-algebra',
          subjectId: 'subj-math',
          title: 'Algebra',
          description: '',
          syllabusText: '',
        );

        final syllabusTool = GetSyllabusStructureTool(
          subjectRepo: tool_fakes.FakeSubjectRepository([subject]),
          topicRepo: tool_fakes.FakeTopicRepository([topic]),
          masteryService: tool_fakes.FakeMasteryGraphService(allMastery: []),
          dependencyRepo: tool_fakes.FakeTopicDependencyRepository([]),
          studentIdService: idService,
        );

        // Practice session tool dependencies
        final practiceTool = CreatePracticeSessionTool(
          questionRepo: FakeQuestionRepository(),
          srService: tool_fakes.FakeSpacedRepetitionService([]),
          masteryService: tool_fakes.FakeMasteryGraphService(weakTopics: []),
          scorer: tool_fakes.FakeReadinessScorer(),
          examSessionService: tool_fakes.FakeExamSessionService([]),
          studentIdService: idService,
        );

        // Lesson history tool dependencies
        final historyTool = GetLessonHistoryTool(
          lessonRepository: tool_fakes.FakeLessonRepository([]),
          tutorSessionRepository: tool_fakes.FakeTutorSessionRepository([]),
          studentIdService: idService,
        );

        final registry = ToolRegistry()
          ..register(syllabusTool)
          ..register(practiceTool)
          ..register(historyTool);

        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Explore my math syllabus, create a weak-area '
              'practice session, and show my lesson history.',
          studentId: 'multi-student',
          systemPrompt: 'You are a comprehensive academic mentor.',
          feature: 'mentor',
        );

        // All three tools were called in order.
        expect(response.toolCalls, hasLength(3));
        expect(response.toolCalls[0].toolName, 'get_syllabus_structure');
        expect(response.toolCalls[1].toolName, 'create_practice_session');
        expect(response.toolCalls[2].toolName, 'get_lesson_history');

        // Each tool produced a result.
        expect(response.toolCalls[0].result, isNotNull);
        expect(response.toolCalls[1].result, isNotNull);
        expect(response.toolCalls[2].result, isNotNull);

        // Final content references all actions.
        expect(response.content, contains('Algebra'));
        expect(response.content, contains('practice session'));
        expect(response.content, contains('lesson'));
      });
    });

    group('LlmUsageMeter + LlmTaskManager audit', () {
      test('all 17 agent tools are traced across the suite', () async {
        final allToolNames = <String>{};

        // Tools traced in other files (create_plan, schedule_lesson,
        // get_student_stats, get_weak_topics).
        allToolNames.addAll([
          'create_plan',
          'get_student_stats',
          'get_weak_topics',
          'schedule_lesson',
        ]);

        // Tools traced in this file — 13 interactive mentor tools (including
        // schedule_rest_day and wellbeing_adjust_schedule) + 4 off-period prep
        // tools registered in llmAgentToolsProvider.
        allToolNames.addAll([
          'search_questions',
          'schedule_rest_day',
          'wellbeing_adjust_schedule',
          'generate_lesson_blocks',
          'modify_plan',
          'get_adherence_trends',
          'get_lesson_history',
          'create_practice_session',
          'get_syllabus_structure',
          'ingest_pdf_to_kb',
          'enqueue_question_variants',
          'pre_generate_lesson',
          'refresh_mastery',
        ]);

        // All 17 tools from llmAgentToolsProvider are traced.
        expect(allToolNames, hasLength(17));

        // Cross-check against the canonical registered tool-name set from
        // fakes.dart (single source of truth mirroring llmAgentToolsProvider).
        expect(allToolNames, equals(registeredToolNames));
        expect(registeredToolNames, hasLength(17));
      });
    });
  });
}
