import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/llm_agent_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/prep_budget_repository.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';
import 'package:studyking/features/mentor/services/tools/add_subject_to_plan_tool.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'package:studyking/features/mentor/services/tools/get_syllabus_structure_tool.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/features/planner/data/repositories/roadmap_repository.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/planner/services/syllabus_resolver.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider, questionVariantServiceProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

MasteryGraphService _buildMasteryGraphService() {
  return MasteryGraphService(
    masteryStateRepo: MasteryStateRepository(),
    questionMasteryRepo: QuestionMasteryStateRepository(),
    topicDependencyRepo: TopicDependencyRepository(),
    questionEvaluationRepo: QuestionEvaluationRepository(),
  );
}

PersonalLearningPlanService _buildPlanService(MasteryGraphService mastery) {
  return PersonalLearningPlanService(
    masteryService: mastery,
    repository: MasteryGraphRepository(),
    topicRepository: TopicRepository(),
    planRepository: PlanRepository(),
    adherenceRepository: PlanAdherenceRepository(),
    roadmapRepository: RoadmapRepository(),
    questionRepository: QuestionRepository(),
  );
}

PlannerService _buildPlannerService(MasteryGraphService mastery) {
  final planService = _buildPlanService(mastery);
  return PlannerService(
    planRepo: PlanRepository(),
    masteryService: mastery,
    topicRepository: TopicRepository(),
    roadmapRepo: RoadmapRepository(),
    planService: planService,
    sessionRepo: SessionRepository(),
    pendingActionRepo: PendingActionRepository(),
    planOrchestrator: PlanAdherenceOrchestrator(
      adherenceRepository: PlanAdherenceRepository(),
      planRepository: PlanRepository(),
      planService: planService,
      masteryService: mastery,
    ),
    syllabusResolver: SyllabusResolver(),
    adherenceRepo: PlanAdherenceRepository(),
  );
}

StudyProgressTracker _buildProgressTracker(MasteryGraphService mastery) {
  return StudyProgressTracker(
    attemptRepo: AttemptRepository(),
    masteryService: mastery,
    sessionRepo: SessionRepository(),
    l10n: lookupAppLocalizations(const Locale('en')),
  );
}

LessonAgentService _buildLessonAgentService() {
  return LessonAgentService(
    llmService: LlmService(
      config: LlmConfiguration(
        provider: LlmProvider.openRouter,
        apiKey: 'test-key',
      ),
    ),
    modelId: 'test-model',
    lessonRepository: LessonRepository(),
    database: DatabaseService(
      topicRepository: TopicRepository(),
      questionRepository: QuestionRepository(),
      attemptRepository: AttemptRepository(),
      lessonRepository: LessonRepository(),
      sessionRepository: SessionRepository(),
      subjectRepository: SubjectRepository(),
      conversationRepository: ConversationRepository(),
      tutorSessionRepository: TutorSessionRepository(),
    ),
  );
}

/// In-memory substitute for [PrepBudgetRepository] so the
/// [PrepBudgetSettingsController] spawned transitively by [llmAgentProvider]
/// never touches the Hive settings box. Its `init()` resolves as a cheap
/// microtask (no disk I/O), mirroring the Hive-free intent of the rest of
/// [ProviderContainer] overrides in this file.
class _FakePrepBudgetRepository extends PrepBudgetRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Result<PrepBudget> load() => Result.success(PrepBudget.defaults);

  @override
  Future<Result<void>> save(PrepBudget budget) async => Result.success(null);
}

/// Drains enough microtask cycles for
/// [PrepBudgetSettingsController._load] — which `await`s `repo.init()` then
/// assigns `state` synchronously — to finish before a synchronous test body
/// reaches `container.dispose()`. Without this the post-`await` `state =`
/// fires after the StateNotifier is disposed ("Tried to use … after dispose").
Future<void> _drainBudgetLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future.delayed(Duration.zero);
  }
}

ProviderContainer _createContainer({
  String apiKey = '',
}) {
  final mastery = _buildMasteryGraphService();
  return ProviderContainer(
    overrides: [
      plannerServiceProvider.overrideWith((ref) => _buildPlannerService(mastery)),
      questionRepositoryProvider.overrideWith((ref) => QuestionRepository()),
      mentorProgressTrackerProvider.overrideWith(
        (ref) => _buildProgressTracker(mastery),
      ),
      masteryGraphServiceProvider.overrideWith((ref) => mastery),
      lessonAgentServiceProvider.overrideWith((ref) => _buildLessonAgentService()),
      llmServiceProvider.overrideWith(
        (ref) => LlmService(
          config: LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: apiKey,
          ),
        ),
      ),
      mentorModelIdProvider.overrideWith((ref) => 'test-model'),
      llmTaskManagerProvider.overrideWith((ref) => LlmTaskManager()),
      // Hand-written in-memory fakes for the prep toolbox dependencies so the
      // provider test stays Hive-free (no settings box / usage box open).
      llmUsageMeterProvider.overrideWith((ref) => LlmUsageMeter()),
      prepBudgetServiceProvider.overrideWith(
        (ref) => PrepBudgetService(
          meter: ref.watch(llmUsageMeterProvider),
          budget: PrepBudget.defaults,
        ),
      ),
      // llmAgentProvider reads prepBudgetSettingsProvider (quiet-hours /
      // per-subject predicates) before the apiKey guard, which spawns a
      // PrepBudgetSettingsController with an async _load() (Hive I/O on the
      // settings box). When Hive is init'd in setUp that _load() is real
      // async I/O which races with container disposal - override the
      // repository with an in-memory fake so _load() is a cheap microtask
      // the tests can drain. Keeps these provider tests Hive-free for the
      // settings box (idle-tasks box is still opened by setUp for the
      // persistence tests). Mirrors prep_budget_providers_test.dart.
      prepBudgetRepositoryProvider.overrideWith(
        (ref) => _FakePrepBudgetRepository(),
      ),
      questionVariantServiceProvider.overrideWith((ref) => QuestionVariantService(
        questionRepo: ref.watch(questionRepositoryProvider),
        llmService: ref.watch(llmServiceProvider),
        modelId: ref.watch(mentorModelIdProvider),
      )),
    ],
  );
}

void main() {
  group('llmAgentToolsProvider', () {
    test('returns list of AgentTool instances', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      expect(tools, isA<List<AgentTool>>());
      expect(tools.length, greaterThanOrEqualTo(6));
      expect(tools.every((t) => t.name.isNotEmpty), isTrue);
    });

    test('tools have unique names', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      final names = tools.map((t) => t.name).toSet();
      expect(names.length, equals(tools.length));
    });

    test('registers wellbeing_adjust_schedule tool', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      final names = tools.map((t) => t.name).toSet();
      expect(names, contains('wellbeing_adjust_schedule'));
    });

    test('registers add_subject_to_plan tool wired to the planner', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      final names = tools.map((t) => t.name).toSet();
      expect(names, contains('add_subject_to_plan'));

      final addTool = tools
          .where((t) => t.name == 'add_subject_to_plan')
          .cast<AgentTool>()
          .single;
      expect(addTool, isA<AddSubjectToPlanTool>());
      expect(addTool.parameters['required'], contains('subjectId'));
    });

    test('registers get_syllabus_structure tool with required dependencies', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      final syllabusTool = tools
          .where((t) => t.name == 'get_syllabus_structure')
          .cast<AgentTool>()
          .single;
      expect(syllabusTool, isA<GetSyllabusStructureTool>());

      final params = (syllabusTool as GetSyllabusStructureTool).parameters;
      final props = params['properties'] as Map;
      expect(props.containsKey('subjectId'), isTrue);
      expect(props.containsKey('topicId'), isTrue);
      expect(props.containsKey('includePrerequisites'), isTrue);
      expect(props.containsKey('includeProgress'), isTrue);
    });

    test('registers the four off-period prep tools wired to prep categories', () {
      final container = _createContainer();
      addTearDown(() => container.dispose());

      final tools = container.read(llmAgentToolsProvider);
      final names = tools.map((t) => t.name).toSet();

      // Vision Next-Term §4.3: the four prep tools must be reachable by the
      // agent. Previously they existed but were never registered in
      // [llmAgentToolsProvider], so off-period prep was dead code and its
      // spend was never attributed to a [PrepCategory].
      expect(names, containsAll(<String>[
        'ingest_pdf_to_kb',
        'enqueue_question_variants',
        'pre_generate_lesson',
        'refresh_mastery',
      ]));

      final prepTools = tools.whereType<PrepTool>().toList();
      expect(prepTools.length, 4);

      // Each tool attributes spend to the taskTypeKey that
      // [PrepBudgetService.spendingByCategory] reads live — the exact
      // disconnect called out in the issue: a tool must stamp a key the budget
      // service actually listens to, not the generic 'background'/'idle_executor'
      // stamp the IdleExecutor used to apply.
      final categoryByKey = <String, String>{
        for (final t in prepTools) t.name: t.prepCategory.taskTypeKey,
      };
      expect(categoryByKey['ingest_pdf_to_kb'], PrepCategory.pdfIngestion.taskTypeKey);
      expect(categoryByKey['enqueue_question_variants'], PrepCategory.questionVariants.taskTypeKey);
      expect(categoryByKey['pre_generate_lesson'], PrepCategory.lessonPrep.taskTypeKey);
      expect(categoryByKey['refresh_mastery'], PrepCategory.background.taskTypeKey);

      // The live meter the tools stamp to is the same meter the budget service
      // reads, so recording under a category key is reflected in live counters
      // — proving the production disconnect is closed.
      final meter = container.read(llmUsageMeterProvider);
      final budgetService = container.read(prepBudgetServiceProvider);
      meter.recordUsage(
        id: 'prep-attr',
        feature: 'pdf_ingestion',
        modelId: 'test-model',
        inputTokens: 100,
        outputTokens: 50,
        taskType: PrepCategory.pdfIngestion.taskTypeKey,
      );
      expect(budgetService.spendingByCategory()[PrepCategory.pdfIngestion], 150);
    });
  });

  group('llmAgentProvider', () {
    late String hivePath;

    setUp(() async {
      // create() calls IdleExecutor.init(), which opens the idle-tasks Hive box.
      // Initialise it per-test so init() is clean (no "box not open" warnings)
      // and persistence tests are deterministic.
      hivePath =
          (await Directory.systemTemp.createTemp('sk_llmagent_provider_')).path;
      Hive.init(hivePath);
      await Hive.openBox(HiveBoxNames.idleTasks);
      await Hive.box(HiveBoxNames.idleTasks).clear();
    });

    tearDown(() async {
      await Future.delayed(const Duration(milliseconds: 5));
      await Hive.close();
      try {
        await Directory(hivePath).delete(recursive: true);
      } catch (_) {
        // Best-effort temp cleanup.
      }
    });

    test('returns null when apiKey is empty', () async {
      final container = _createContainer(apiKey: '');
      addTearDown(() => container.dispose());

      final agent = container.read(llmAgentProvider('student-1'));
      await _drainBudgetLoad();
      expect(agent, isNull);
    });

    test('returns LlmAgent when apiKey is provided', () async {
      final container = _createContainer(apiKey: 'test-key');
      addTearDown(() => container.dispose());

      final agent = container.read(llmAgentProvider('student-1'));
      await _drainBudgetLoad();
      expect(agent, isA<LlmAgent>());
      expect(agent!.toolRegistry.toolNames.length, greaterThanOrEqualTo(6));
    });

    test('different student IDs produce different agents', () async {
      final container = _createContainer(apiKey: 'test-key');
      addTearDown(() => container.dispose());

      final agent1 = container.read(llmAgentProvider('student-1'));
      final agent2 = container.read(llmAgentProvider('student-2'));
      await _drainBudgetLoad();
      expect(agent1, isA<LlmAgent>());
      expect(agent2, isA<LlmAgent>());
    });

    test(
        'provider starts idle monitoring on read and cancels the timer when '
        'the scope is torn down', () async {
      final container = _createContainer(apiKey: 'test-key');

      final agent = container.read(llmAgentProvider('student-1'));
      expect(agent, isNotNull);
      // create() calls startIdleMonitoring() -> a periodic polling timer.
      await agent!.idleExecutor.initComplete;
      expect(agent.idleExecutor.isMonitoring, isTrue,
          reason: 'AgentFactory.create must start idle monitoring');

      // Vision Next-Term §4.3/§4.4: tearing down the scope runs
      // ref.onDispose -> IdleExecutor.dispose -> stopIdleMonitoring, cancelling
      // the timer (and flushing the queue). Without the onDispose wiring the
      // 30s timer leaks for the lifetime of the process.
      container.dispose();
      await agent.idleExecutor.persistenceComplete;
      expect(agent.idleExecutor.isMonitoring, isFalse,
          reason: 'onDispose must cancel the idle monitoring timer');
    });

    test(
        'post-lesson prep tasks enqueued via the provider survive a simulated '
        'app restart (init + restore on relaunch)', () async {
      // End-to-end through the real provider: endLesson -> enqueuePrepTask ->
      // IdleExecutor.enqueuePrepTool. The agent's IdleExecutor must init() in
      // the provider so the tasks are persisted and restored on relaunch.
      final container = _createContainer(apiKey: 'test-key');

      final agent = container.read(llmAgentProvider('student-1'))!;
      // create() already fired idleExecutor.init() (fire-and-forget); await
      // its completion via initComplete rather than masking the bug with an
      // explicit test-side init() call - the box is only opened by create()'s
      // init(), so persistence is verified here.
      await agent.idleExecutor.initComplete;
      await agent.enqueuePrepTask(
        'post-lesson adherence check',
        () async => {'success': true},
        requiresHeavy: true,
        feature: 'background',
        taskType: 'background',
      );
      await agent.enqueuePrepTask(
        'next-topic lesson pre-generation',
        () async => {'success': true},
        requiresHeavy: true,
        feature: 'lesson_prep',
        taskType: 'lesson_prep',
        subjectId: 'chemistry',
        estimatedInputTokens: 8000,
        estimatedOutputTokens: 2000,
      );

      expect(agent.idleExecutor.queue.length, equals(2));
      await agent.idleExecutor.persistenceComplete;

      // Simulate process termination: scope teardown runs onDispose -> dispose
      // (flush + cancel timer).
      container.dispose();
      await agent.idleExecutor.persistenceComplete;

      // Simulate app relaunch: a fresh scope reads the provider again; the new
      // agent's IdleExecutor.init() restores tasks from the box.
      final restarted = _createContainer(apiKey: 'test-key');
      final restored = restarted.read(llmAgentProvider('student-1'))!;
      // On relaunch create() re-ran init(); await its completion so the box
      // is open and restored tasks are read before asserting queue length.
      // If create() stopped calling init(), initComplete resolves immediately
      // (never-started future) but the box stays unopened -> queue is empty
      // -> the length assertion below fails (fix-proving).
      await restored.idleExecutor.initComplete;

      expect(restored.idleExecutor.queue.length, equals(2),
          reason: 'init() must restore queued prep tasks across a restart');

      final prep = restored.idleExecutor.queue
          .firstWhere((t) => t.feature == 'lesson_prep');
      expect(prep.subjectId, equals('chemistry'));
      expect(prep.taskType, equals('lesson_prep'));
      expect(prep.estimatedInputTokens, equals(8000));
      expect(prep.estimatedOutputTokens, equals(2000));
      expect(prep.taskFn, isNull,
          reason: 'restored tasks must carry no executable closure');

      restarted.dispose();
      await restored.idleExecutor.persistenceComplete;
    });
  });
}
