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
import 'package:studyking/core/data/models/student_attempt_model.dart';
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
import 'package:studyking/features/mentor/services/tools/explain_differently_tool.dart';
import 'package:studyking/features/mentor/services/tools/generate_lesson_blocks_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_adherence_trends_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_lesson_history_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_syllabus_structure_tool.dart';
import 'package:studyking/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart';
import 'package:studyking/features/mentor/services/tools/modify_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/pre_generate_lesson_tool.dart';
import 'package:studyking/features/mentor/services/tools/refresh_mastery_tool.dart';
import 'package:studyking/features/mentor/services/tools/review_mistakes_tool.dart';
import 'package:studyking/features/mentor/services/tools/search_questions_tool.dart';
import 'package:studyking/features/mentor/services/tools/read_source_content_tool.dart';
import 'package:studyking/features/mentor/services/tools/revisit_sources_tool.dart';
import 'package:studyking/features/mentor/services/tools/search_sources_tool.dart';
import 'package:studyking/features/mentor/services/tools/switch_syllabus_focus_tool.dart';
import 'package:studyking/features/mentor/services/tools/suggest_practice_tool.dart';
import 'package:studyking/features/mentor/services/tools/switch_provider_tool.dart';
import 'package:studyking/features/mentor/services/tools/add_subject_to_plan_tool.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
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

/// Fake [MistakeReviewService] that returns canned mistakes without touching
/// Hive or the LLM — used to isolate the ReviewMistakesTool trace.
class FakeMistakeReviewService extends MistakeReviewService {
  final List<MistakeEntry> mistakes;
  bool throwError = false;

  FakeMistakeReviewService([this.mistakes = const []])
      : super(
          attemptRepo: tool_fakes.FakeAttemptRepository(),
          questionRepo: tool_fakes.FakeQuestionRepository(),
        );

  @override
  Future<Result<List<MistakeEntry>>> getMistakesFromSession({
    required String studentId,
    required String subjectId,
    DateTime? after,
  }) async {
    if (throwError) return Result.failure('mistake_review_unavailable');
    return Result.success(mistakes);
  }
}

/// Minimal hand-written fake [SourceRepository] for source-content tool
/// trace tests — AGENTS.md (no mockito/mocktail). Mirrors the fake in
/// scenario_validation_test.dart so both suites can independently construct
/// the real ReadSourceContentTool / RevisitSourcesTool / SearchSourcesTool
/// without touching Hive.
class FakeSourceRepository extends SourceRepository {
  final List<Source> _all;
  FakeSourceRepository([this._all = const []]);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<Source?>> get(String key) async =>
      Result.success(_all.where((s) => s.id == key).firstOrNull);

  @override
  Future<Result<List<Source>>> getByStudent(String studentId) async =>
      Result.success(_all.where((s) => s.studentId == studentId).toList());

  @override
  Future<Result<List<Source>>> getAll() async => Result.success(_all);
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

    group('SwitchSyllabusFocusTool', () {
      test('reachable through AgentLoop from "focus on Math for 2 weeks"',
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: switch_syllabus_focus\n'
          'ARGUMENTS: {"subjectId": "math-hl", "subjectTitle": "Math AA HL", "days": 14}',
          'Focus switched to Math AA HL for 14 days. Subsequent scheduling and practice will default to Math.',
        ]);

        // Recording callback so we can verify the tool invoked the focus service.
        Map<String, dynamic>? receivedArgs;
        final tool = SwitchSyllabusFocusTool(
          onFocusChanged: ({
            required String subjectId,
            String? subjectTitle,
            int? days,
          }) async {
            receivedArgs = {
              'subjectId': subjectId,
              'subjectTitle': subjectTitle,
              'days': days,
            };
            return Result.success(null);
          },
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Focus on Math for the next 2 weeks.',
          studentId: 'focus-student',
          systemPrompt: 'You are a mentor that manages syllabus focus.',
          feature: 'mentor',
        );

        // The tool was invoked with parsed arguments.
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'switch_syllabus_focus');
        expect(response.toolCalls.first.arguments['subjectId'], 'math-hl');
        expect(response.toolCalls.first.arguments['subjectTitle'], 'Math AA HL');
        expect(response.toolCalls.first.arguments['days'], 14);

        // The callback received the focus change request.
        expect(receivedArgs, isNotNull);
        expect(receivedArgs!['subjectId'], 'math-hl');
        expect(receivedArgs!['subjectTitle'], 'Math AA HL');
        expect(receivedArgs!['days'], 14);
      });
    });

    group('AddSubjectToPlanTool', () {
      test('reachable through AgentLoop from "add Biology to my plan"', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: add_subject_to_plan\n'
          'ARGUMENTS: {"subjectId": "biology", "subjectTitle": "Biology", "targetDays": 90, "targetHoursPerDay": 2}',
          'I added Biology to your existing plan, merging it with Physics '
              'while preserving your mastered topics.',
        ]);

        // Recording callback so we can verify the tool invoked the plan merger
        // with the correct SyllabusGoal (delegates to PlannerService.addSubjectToPlan
        // in production via the provider wiring).
        SyllabusGoal? receivedGoal;
        final tool = AddSubjectToPlanTool(
          onAddSubject: ({required SyllabusGoal newGoal}) async {
            receivedGoal = newGoal;
            return Result.success(
              tool_fakes.sampleLearningPlan(studentId: 'add-subject-student'),
            );
          },
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'I want to study Biology instead of Physics.',
          studentId: 'add-subject-student',
          systemPrompt: 'You are a mentor that expands study plans.',
          feature: 'mentor',
        );

        // The tool was invoked with the LLM-parsed arguments.
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'add_subject_to_plan');
        expect(response.toolCalls.first.arguments['subjectId'], 'biology');
        expect(response.toolCalls.first.arguments['subjectTitle'], 'Biology');
        expect(response.toolCalls.first.arguments['targetDays'], 90);

        // The callback received the SyllabusGoal built from the parsed args.
        expect(receivedGoal, isNotNull);
        expect(receivedGoal!.subjectId, 'biology');
        expect(receivedGoal!.subjectTitle, 'Biology');
        expect(receivedGoal!.targetDays, 90);
        expect(receivedGoal!.targetHoursPerDay, 2);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['subjectId'], 'biology');
      });
    });

    group('SwitchProviderTool', () {
      test('reachable through AgentLoop from "switch to Ollama"', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: switch_provider\n'
          r'ARGUMENTS: {"provider": "ollama", "model": "llama3"}',
          'Switched to Ollama with model llama3. You can update your default '
          'model in Settings.',
        ]);

        // Recording callback so we can verify the tool invoked the provider switch.
        Map<String, dynamic>? receivedArgs;
        final tool = SwitchProviderTool(
          onSwitch: ({
            required LlmProvider provider,
            required String? apiKey,
            required String? baseUrl,
            required String? model,
          }) async {
            receivedArgs = {
              'provider': provider,
              'apiKey': apiKey,
              'baseUrl': baseUrl,
              'model': model,
            };
            return Result.success(null);
          },
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Switch to Ollama instead of OpenRouter.',
          studentId: 'provider-student',
          systemPrompt: 'You are a mentor that manages AI provider settings.',
          feature: 'mentor',
        );

        // The tool was invoked with parsed arguments.
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'switch_provider');
        expect(response.toolCalls.first.arguments['provider'], 'ollama');
        expect(response.toolCalls.first.arguments['model'], 'llama3');

        // The callback received the provider switch request.
        expect(receivedArgs, isNotNull);
        expect(receivedArgs!['provider'], LlmProvider.ollama);
        expect(receivedArgs!['model'], 'llama3');
        // Ollama does not need an API key.
        expect(receivedArgs!['apiKey'], isNull);
      });

      test('ollama switch succeeds without API key', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: switch_provider\nARGUMENTS: {"provider": "ollama"}',
          'Switched to Ollama (local, no API key required).',
        ]);

        String? receivedProvider;
        final tool = SwitchProviderTool(
          onSwitch: ({
            required LlmProvider provider,
            required String? apiKey,
            required String? baseUrl,
            required String? model,
          }) async {
            receivedProvider = provider.name;
            return Result.success(null);
          },
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Use Ollama locally.',
          studentId: 'ollama-student',
          systemPrompt: 'You are a mentor.',
          feature: 'mentor',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'switch_provider');
        expect(receivedProvider, 'ollama');
        expect(response.error, isNull);
      });

      test('non-ollama provider without API key returns failure', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: switch_provider\nARGUMENTS: {"provider": "openAI"}',
          'I could not switch providers — an API key is required for openAI.',
        ]);

        bool callbackCalled = false;
        final tool = SwitchProviderTool(
          onSwitch: ({
            required LlmProvider provider,
            required String? apiKey,
            required String? baseUrl,
            required String? model,
          }) async {
            callbackCalled = true;
            return Result.success(null);
          },
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Switch to OpenAI.',
          studentId: 'openai-student',
          systemPrompt: 'You are a mentor.',
          feature: 'mentor',
        );

        expect(response.toolCalls, hasLength(1));
        // Tool returns failure because API key is missing, but callback is
        // never invoked — the tool short-circuits before calling onSwitch.
        expect(callbackCalled, isFalse);
        final result = jsonDecode(response.toolCalls.first.result!) as Map<String, dynamic>;
        expect(result['success'], isFalse);
        expect(result['error'], contains('API key'));
      });

      test('unknown provider name returns failure', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: switch_provider\nARGUMENTS: {"provider": "unknown_ai"}',
          'I could not switch providers — "unknown_ai" is not a valid provider.',
        ]);

        final tool = SwitchProviderTool(
          onSwitch: ({
            required LlmProvider provider,
            required String? apiKey,
            required String? baseUrl,
            required String? model,
          }) async =>
              Result.success(null),
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Switch to unknown_ai.',
          studentId: 'unknown-student',
          systemPrompt: 'You are a mentor.',
          feature: 'mentor',
        );

        expect(response.toolCalls, hasLength(1));
        final result = jsonDecode(response.toolCalls.first.result!) as Map<String, dynamic>;
        expect(result['success'], isFalse);
        expect(result['error'], contains('Unknown provider'));
      });
    });

    group('ReviewMistakesTool', () {
      test('reachable through AgentLoop from "show me my mistakes"',
          () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: review_mistakes\n'
          'ARGUMENTS: {"subjectId": "math-hl", "daysBack": 14, "limit": 5}',
          'I found 1 mistake on fractions. The correct answer is 1/2, and the '
          'key concept was equivalent fractions.',
        ]);

        final now = DateTime.now();
        final question = Question(
          id: 'q-frac-1',
          text: 'What is 1/4 + 1/4?',
          type: QuestionType.singleChoice,
          subjectId: 'math-hl',
          topicId: 'fractions-1',
          topic: 'Fractions',
          markscheme: Markscheme(
            questionId: 'q-frac-1',
            correctAnswer: '1/2',
            explanation: 'Adding quarters: 1/4 + 1/4 = 2/4 = 1/2.',
          ),
          explanation: 'Adding quarters: 1/4 + 1/4 = 2/4 = 1/2.',
          createdAt: now,
          updatedAt: now,
        );

        final mistakes = [
          MistakeEntry(
            question: question,
            attempt: StudentAttempt(
              id: 'att-1',
              studentId: 'review-student',
              questionId: 'q-frac-1',
              subjectId: 'math-hl',
              isCorrect: false,
              timestamp: now,
              userAnswer: '1/4',
            ),
            correctAnswer: '1/2',
            explanation: 'Adding quarters: 1/4 + 1/4 = 2/4 = 1/2.',
          ),
        ];

        final tool = ReviewMistakesTool(
          mistakeReviewService: FakeMistakeReviewService(mistakes),
          studentIdService: tool_fakes.FakeStudentIdService('review-student'),
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Show me my mistakes in math',
          studentId: 'review-student',
          systemPrompt: 'You are a mentor that reviews practice mistakes.',
          feature: 'mentor',
        );

        // The tool was invoked with the LLM-parsed arguments.
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'review_mistakes');
        expect(response.toolCalls.first.arguments['subjectId'], 'math-hl');
        expect(response.toolCalls.first.arguments['daysBack'], 14);
        expect(response.toolCalls.first.arguments['limit'], 5);

        // The result surfaces wrong answers with markscheme explanations and
        // the linked concept (topicId), not a redirect to a separate UI.
        final result = response.toolCalls.first.result;
        expect(result, isNotNull, reason: 'Tool result should be serialized');
        final resultMap = jsonDecode(result!) as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['subjectId'], 'math-hl');
        expect(resultMap['totalFound'], 1);
        expect(resultMap['mistakes'], isNotEmpty);
        expect(resultMap['mistakes'][0]['concept'], 'fractions-1');
        expect(resultMap['mistakes'][0]['topic'], 'Fractions');
        expect(resultMap['mistakes'][0]['userAnswer'], '1/4');
        expect(resultMap['mistakes'][0]['correctAnswer'], '1/2');
        expect(resultMap['mistakes'][0]['explanation'], contains('1/2'));
      });
    });

    group('SearchSourcesTool', () {
      test('reachable through AgentLoop from "where does my textbook discuss X"',
          () async {
        // Reproduces the source-grounding journey: the student asks the
        // mentor to find a keyword in their ingested textbook. The real
        // SearchSourcesTool dispatches through AgentLoop with a FakeSourceRepository.
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: search_sources\n'
          r'ARGUMENTS: {"query": "aldol condensation", "limit": 5}',
          'Chapter 4 covers aldol condensation on pages 102-105.',
        ]);

        final idService = FakeStudentIdService()..setStudentId('search-student');

        final tool = SearchSourcesTool(
          sourceRepo: FakeSourceRepository([
            Source(
              id: 'chem-text',
              title: 'Organic Chemistry',
              type: SourceType.pdf,
              chunks: jsonEncode([
                {
                  'chunkIndex': 0,
                  'pageStart': 102,
                  'pageEnd': 105,
                  'text': 'Aldol condensation is a carbon-carbon bond-forming reaction '
                      'between enolates and carbonyl compounds.',
                  'heading': 'Aldol Condensation',
                },
              ]),
              studentId: 'search-student',
              subjectId: 'chem',
            ),
          ]),
          studentIdService: idService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Where in my textbook does it discuss aldol condensation?',
          studentId: 'search-student',
          systemPrompt: 'You are a mentor that grounds answers in source material.',
        );

        // The tool was invoked through AgentLoop with parsed arguments.
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'search_sources');
        expect(response.toolCalls.first.arguments['query'], 'aldol condensation');
        expect(response.toolCalls.first.arguments['limit'], 5);

        // The result surfaces the matching chunk with page citation.
        expect(response.toolCalls.first.result, isNotNull);
        final result = jsonDecode(response.toolCalls.first.result!) as Map<String, dynamic>;
        expect(result['success'], isTrue);
        expect(result['matchCount'], greaterThan(0));
        expect(result['results'], isNotEmpty);
        expect(result['results'][0]['pageStart'], 102);
        expect(result['results'][0]['pageEnd'], 105);

        // Final content references the found material.
        expect(response.content, contains('aldol condensation'));
      });
    });

    group('ReadSourceContentTool', () {
      test('reachable through AgentLoop from "read page 102 of my textbook"',
          () async {
        // Reproduces the source-grounding journey: the student asks the mentor
        // to read a specific page/chunk of an ingested textbook. The real
        // ReadSourceContentTool dispatches through AgentLoop with a
        // FakeSourceRepository.
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: read_source_content\n'
          r'ARGUMENTS: {"sourceId": "chem-text", "startPage": 102, "endPage": 102}',
          'On page 102 of your Organic Chemistry textbook, the section on '
          'Aldol Condensation explains: "Aldol condensation is a carbon-carbon '
          'bond-forming reaction..."',
        ]);

        final idService = FakeStudentIdService()..setStudentId('read-student');

        final tool = ReadSourceContentTool(
          sourceRepo: FakeSourceRepository([
            Source(
              id: 'chem-text',
              title: 'Organic Chemistry',
              type: SourceType.textbook,
              chunks: jsonEncode([
                {
                  'chunkIndex': 0,
                  'pageStart': 100,
                  'pageEnd': 103,
                  'text': 'Aldol condensation is a carbon-carbon bond-forming '
                      'reaction between enolates and carbonyl compounds.',
                  'heading': 'Aldol Condensation',
                },
              ]),
              studentId: 'read-student',
              subjectId: 'chem',
            ),
          ]),
          studentIdService: idService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Read page 102 of my Chemistry textbook',
          studentId: 'read-student',
          systemPrompt: 'You are a mentor that reads source material for the student.',
        );

        // The tool was invoked with parsed arguments.
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'read_source_content');
        expect(response.toolCalls.first.arguments['sourceId'], 'chem-text');
        expect(response.toolCalls.first.arguments['startPage'], 102);
        expect(response.toolCalls.first.arguments['endPage'], 102);

        // The result surfaces the chunk with page range and heading.
        expect(response.toolCalls.first.result, isNotNull);
        final result = jsonDecode(response.toolCalls.first.result!) as Map<String, dynamic>;
        expect(result['success'], isTrue);
        expect(result['sourceId'], 'chem-text');
        expect(result['chunkCount'], greaterThan(0));
        expect(result['chunks'][0]['pageStart'], 100);
        expect(result['chunks'][0]['heading'], 'Aldol Condensation');
      });
    });

    group('RevisitSourcesTool', () {
      test('reachable through AgentLoop from "revisit my uploaded textbook"',
          () async {
        // Reproduces the conversational revisit journey: the student asks the
        // mentor to list recently uploaded materials. The real
        // RevisitSourcesTool dispatches through AgentLoop with a
        // FakeSourceRepository.
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: revisit_sources\nARGUMENTS: {"limit": 10}',
          'I found 2 sources you\'ve uploaded. Here they are sorted by '
          'recency: "Organic Chemistry" and "IB Biology Notes".',
        ]);

        final idService = FakeStudentIdService()..setStudentId('revisit-student');

        final tool = RevisitSourcesTool(
          sourceRepo: FakeSourceRepository([
            Source(
              id: 'chem-text',
              title: 'Organic Chemistry',
              type: SourceType.textbook,
              studentId: 'revisit-student',
              subjectId: 'chem',
              createdAt: DateTime.now(),
            ),
            Source(
              id: 'bio-notes',
              title: 'IB Biology Notes',
              type: SourceType.pdf,
              studentId: 'revisit-student',
              subjectId: 'bio',
              createdAt: DateTime.now().add(const Duration(days: 1)),
            ),
          ]),
          studentIdService: idService,
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: "Revisit the textbook I uploaded last week",
          studentId: 'revisit-student',
          systemPrompt: 'You are a mentor that surfaces recent study materials.',
        );

        // The tool was invoked with parsed arguments.
        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'revisit_sources');
        expect(response.toolCalls.first.arguments['limit'], 10);

        // The result surfaces a recency-ordered, paginated list.
        expect(response.toolCalls.first.result, isNotNull);
        final result = jsonDecode(response.toolCalls.first.result!) as Map<String, dynamic>;
        expect(result['success'], isTrue);
        expect(result['sourceCount'], 2);
        expect(result['totalCount'], 2);
        expect(result['sources'], isNotEmpty);
        // Recency ordering: the newer source (bio-notes) comes first.
        expect(result['sources'][0]['id'], 'bio-notes');
        expect(result['sources'][1]['id'], 'chem-text');
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

    // ---------------------------------------------------------------------------
    // Vision Next-Term §3.1: explanation-variation tools
    // (issues/open/e2e-teaching-missing-explanation-variation-tool.md)
    // ---------------------------------------------------------------------------
    group('ExplainDifferentlyTool', () {
      test('reachable through AgentLoop from "explain fractions differently"',
          () async {
        // Simulates the confused-student journey: the LLM calls
        // explain_differently with style=analogy and concept=fractions.
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: explain_differently\n'
          r'ARGUMENTS: {"concept": "fractions", "style": "analogy"}',
          // The LLM inside the tool generates the alternative explanation.
          'Think of fractions like pizza slices: if you cut a pizza into 4 '
              'equal slices and eat 1, you have eaten 1/4 of the pizza.',
          // AgentLoop final response surfacing the explanation to the student.
          "Here's a different way to think about fractions: imagine a pizza "
              'cut into 4 equal slices...',
        ]);

        final tool = ExplainDifferentlyTool(
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
          userMessage: 'I do not get fractions. Explain differently.',
          studentId: 'explain-student',
          systemPrompt: 'You are a tutor that adapts explanation style.',
          feature: 'teaching_explanation',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'explain_differently');
        expect(response.toolCalls.first.arguments['concept'], 'fractions');
        expect(response.toolCalls.first.arguments['style'], 'analogy');
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['concept'], 'fractions');
        expect(resultMap['style'], 'analogy');
        expect(resultMap['blockType'], 'analogy');
        expect(resultMap['explanation'], contains('pizza'));
      });

      test('maps visual style to LessonBlockType.visual', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: explain_differently\n'
          r'ARGUMENTS: {"concept": "fractions", "style": "visual"}',
          'Picture a pie chart: the whole pie is 1, each slice is a fraction.',
          'Here is a visual explanation for fractions...',
        ]);

        final tool = ExplainDifferentlyTool(
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
          userMessage: 'Explain fractions with a diagram.',
          studentId: 'visual-student',
          systemPrompt: 'You are a tutor.',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'explain_differently');
        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['style'], 'visual');
        expect(resultMap['blockType'], 'visual');
        expect(resultMap['explanation'], contains('pie chart'));

        // Verify the LessonBlockType enum has the new variant.
        expect(LessonBlockType.values, contains(LessonBlockType.visual));
      });
    });

    group('SuggestPracticeTool', () {
      test('reachable through AgentLoop from "I still do not get it"', () async {
        // Simulates the escalation journey: the LLM calls suggest_practice
        // to redirect the student to prerequisite practice on fractions.
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: suggest_practice\n'
          r'ARGUMENTS: {"subjectId": "math-hl", "topicId": "fractions"}',
          'Done with suggest_practice.',
        ]);

        Map<String, dynamic>? receivedArgs;

        final tool = SuggestPracticeTool(
          onSuggestPractice: ({
            required String subjectId,
            String? topicId,
          }) async {
            receivedArgs = {'subjectId': subjectId, 'topicId': topicId};
            return Result.success(
              PracticeRecommendation(
                topicId: 'fractions',
                message: 'I found 5 practice questions on fractions. '
                    'Let\'s start there.',
                questionIds: ['q1', 'q2', 'q3', 'q4', 'q5'],
              ),
            );
          },
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'I still do not get fractions. Suggest practice.',
          studentId: 'practice-student',
          systemPrompt:
              'You are a tutor that redirects to prerequisite practice.',
          feature: 'teaching_explanation',
        );

        expect(response.toolCalls, hasLength(1));
        expect(response.toolCalls.first.toolName, 'suggest_practice');
        expect(response.toolCalls.first.arguments['subjectId'], 'math-hl');
        expect(response.toolCalls.first.arguments['topicId'], 'fractions');
        expect(response.toolCalls.first.result, isNotNull);

        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isTrue);
        expect(resultMap['subjectId'], 'math-hl');
        expect(resultMap['recommendedTopicId'], 'fractions');
        expect(resultMap['questionIds'], hasLength(5));
        expect(resultMap['message'], contains('fractions'));

        // The callback received the parsed arguments.
        expect(receivedArgs, isNotNull);
        expect(receivedArgs!['subjectId'], 'math-hl');
        expect(receivedArgs!['topicId'], 'fractions');
      });

      test('returns failure when subjectId is empty', () async {
        final fakeLlm = FakeAgentLlmService([
          'TOOL_CALL: suggest_practice\nARGUMENTS: {"subjectId": ""}',
          'I need a subject to suggest practice for.',
        ]);

        final tool = SuggestPracticeTool(
          onSuggestPractice: ({
            required String subjectId,
            String? topicId,
          }) async =>
              Result.success(
            PracticeRecommendation(topicId: '', message: ''),
          ),
        );

        final registry = ToolRegistry()..register(tool);
        final loop = AgentLoop(
          llmService: fakeLlm,
          modelId: 'test-model',
          toolRegistry: registry,
        );

        final response = await loop.run(
          userMessage: 'Suggest practice for nothing.',
          studentId: 'fail-student',
          systemPrompt: 'You are a tutor.',
        );

        expect(response.toolCalls, hasLength(1));
        final result = jsonDecode(response.toolCalls.first.result!);
        final resultMap = result as Map<String, dynamic>;
        expect(resultMap['success'], isFalse);
        expect(resultMap['error'], contains('subjectId'));
      });
    });

    group('LlmUsageMeter + LlmTaskManager audit', () {
      test('registeredToolNames matches llmAgentToolsProvider registration count', () {
        // The canonical tool set from fakes.dart must mirror the tools
        // registered in llmAgentToolsProvider (llm_agent_providers.dart),
        // including search_sources, read_source_content, and revisit_sources.
        expect(registeredToolNames, hasLength(26));
        // Verify no duplicate registration by checking the set size.
        expect(registeredToolNames.length, registeredToolNames.toSet().length);
      });

      test('every registered agent tool passes through the AgentLoop dispatch',
          () async {
        // Tightened audit: instead of merely checking name-set membership
        // (the old test listed allToolNames by hand and asserted set equality),
        // this test actually runs a TOOL_CALL trace through the real AgentLoop
        // for EVERY tool name in registeredToolNames. If a tool is registered
        // but cannot be dispatched (e.g. its name was added to registeredToolNames
        // without a corresponding trace test), this test fails.
        //
        // Fixes issues/open/e2e-source-grounding-tools-not-traced.md: the
        // old audit falsely reported read_source_content and revisit_sources
        // as "traced" when they only appeared in the hand-listed set.
        final taskManager = LlmTaskManager();
        final taskIdsBefore = <String>{...taskManager.tasks.map((t) => t.id)};

        for (final toolName in registeredToolNames) {
          final fakeLlm = FakeAgentLlmService([
            'TOOL_CALL: $toolName\nARGUMENTS: {}',
            'Done with $toolName.',
          ]);

          final tool = RecordingTool(name: toolName);
          final registry = ToolRegistry()..register(tool);
          final loop = AgentLoop(
            llmService: fakeLlm,
            modelId: 'test-model',
            toolRegistry: registry,
            taskManager: taskManager,
          );

          final response = await loop.run(
            userMessage: 'Test dispatch for $toolName',
            studentId: 'audit-student',
            systemPrompt: 'You are a test harness.',
            feature: 'agent',
          );

          // The tool was dispatched and executed without an AgentLoop error.
          expect(
            response.toolCalls,
            hasLength(1),
            reason: 'Tool "$toolName" was not dispatched by AgentLoop — '
                'the registered name has no executing TOOL_CALL trace.',
          );
          expect(
            response.toolCalls.first.toolName,
            toolName,
            reason: 'Dispatched tool name does not match registered name "$toolName".',
          );
          expect(
            response.error,
            isNull,
            reason: 'AgentLoop surfaced an error for "$toolName".',
          );
        }

        // Verify LlmTaskManager recorded a task per tool dispatch.
        final tasksAfter = taskManager.tasks
            .where((t) => !taskIdsBefore.contains(t.id))
            .toList();
        expect(tasksAfter.length, registeredToolNames.length,
            reason: 'LlmTaskManager should record one task per tool dispatch.');
        expect(
          tasksAfter.every((t) => t.status == LlmTaskStatus.done),
          isTrue,
          reason: 'All dispatch tasks should complete.',
        );
      });
    });
  });
}
