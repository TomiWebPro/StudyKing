import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/idle_executor_providers.dart'
    show idleExecutorProvider;
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/settings_service.dart';
import 'package:studyking/core/services/long_term_memory.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider, questionVariantServiceProvider,
        sourceRepositoryProvider;
import 'package:studyking/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart';
import 'package:studyking/features/mentor/services/tools/explain_differently_tool.dart';
import 'package:studyking/features/mentor/services/tools/reconstruct_chart_tool.dart';
import 'package:studyking/features/mentor/services/tools/enqueue_question_variants_tool.dart';
import 'package:studyking/features/mentor/services/tools/pre_generate_lesson_tool.dart';
import 'package:studyking/features/mentor/services/tools/refresh_mastery_tool.dart';
import 'package:studyking/features/mentor/services/tools/schedule_lesson_tool.dart';
import 'package:studyking/features/mentor/services/tools/schedule_rest_day_tool.dart';
import 'package:studyking/features/mentor/services/tools/wellbeing_adjust_schedule_tool.dart';
import 'package:studyking/features/mentor/services/tools/switch_syllabus_focus_tool.dart';
import 'package:studyking/features/mentor/services/tools/search_questions_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_student_stats_tool.dart';
import 'package:studyking/features/mentor/services/tools/generate_lesson_blocks_tool.dart';
import 'package:studyking/features/mentor/services/tools/create_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/modify_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/add_subject_to_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_weak_topics_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_adherence_trends_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_lesson_history_tool.dart';
import 'package:studyking/features/mentor/services/tools/create_practice_session_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_syllabus_structure_tool.dart';
import 'package:studyking/features/mentor/services/tools/read_source_content_tool.dart';
import 'package:studyking/features/mentor/services/tools/search_sources_tool.dart';
import 'package:studyking/features/mentor/services/tools/revisit_sources_tool.dart';
import 'package:studyking/features/mentor/services/tools/review_mistakes_tool.dart';
import 'package:studyking/features/mentor/services/tools/suggest_practice_tool.dart';
import 'package:studyking/features/mentor/services/tools/switch_provider_tool.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart' show LlmProvider;
import 'package:studyking/features/mentor/providers/mentor_providers.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';

final llmAgentToolsProvider = Provider<List<AgentTool>>((ref) {
  final plannerService = ref.watch(plannerServiceProvider);
  final questionRepo = ref.watch(questionRepositoryProvider);
  final progressTracker = ref.watch(mentorProgressTrackerProvider);
  final masteryService = ref.watch(masteryGraphServiceProvider);
  final planOrchestrator = ref.watch(planOrchestratorProvider);
  final studentIdService = StudentIdService();
  final lessonAgentService = ref.watch(lessonAgentServiceProvider);
  final lessonRepository = ref.watch(lessonRepositoryProvider);
  final tutorSessionRepository = ref.watch(tutorSessionRepositoryProvider);
  final locale = ref.watch(localeProvider);
  final localeName = locale.languageCode;
  final srService = ref.watch(spacedRepetitionServiceProvider);
  final scorer = ref.watch(readinessScorerProvider);
  final examSessionService = ref.watch(examSessionServiceProvider);
  final subjectRepo = ref.watch(subjectRepositoryProvider);
  final topicRepo = ref.watch(topicRepositoryProvider);
  final sourceRepo = ref.watch(sourceRepositoryProvider);

  // Vision Next-Term §4.3 LLM prep toolbox dependencies. These are watched so
  // the prep tools can record spend against the correct [PrepCategory.taskTypeKey]
  // and consult [PrepBudgetService.canSpend] before spending — closing the
  // production disconnect where off-period prep was always stamped as 'background'.
  final llmService = ref.watch(llmServiceProvider);
  final modelId = ref.watch(mentorModelIdProvider);
  final taskManager = ref.watch(llmTaskManagerProvider);
  final usageMeter = ref.watch(llmUsageMeterProvider);
  final budgetService = ref.watch(prepBudgetServiceProvider);
  final systemMonitor = ref.watch(systemMonitorServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final questionVariantService = ref.watch(questionVariantServiceProvider);
  final focusService = ref.watch(syllabusFocusServiceProvider);
  final mistakeReviewService = ref.watch(mistakeReviewServiceProvider);

  // Vision Next-Term §3.1 (scenario_confused_student_fractions): teaching-mode
  // explanation-variation tools. explain_differently is LLM-backed (generates an
  // alternative explanation); suggest_practice is callback-based (delegates to
  // MasteryGraphService + QuestionRepository for a weak-topic-driven practice
  // recommendation). Both are now registered so the agent can invoke them via
  // the AgentLoop tool-calling infrastructure.
  return [
    ExplainDifferentlyTool(llmService: llmService, modelId: modelId),
    // Vision Next-Term §24 / agent_must_read.md §24: reconstruct described charts
    // and diagrams into renderable Mermaid specs so lessons can surface visual
    // content even when the original figure bytes are unavailable.
    ReconstructChartTool(llmService: llmService, modelId: modelId),
    SuggestPracticeTool(
      onSuggestPractice: ({
        required String subjectId,
        String? topicId,
      }) async {
        final sid = studentIdService.getStudentId().data ?? '';
        await masteryService.init();
        final weakResult = await masteryService.getWeakTopics(
          sid,
          subjectId: subjectId,
        );
        final weakTopics = weakResult.data ?? [];

        if (weakTopics.isEmpty) {
          return Result.success(PracticeRecommendation(
            topicId: topicId ?? '',
            message: 'No weak areas detected in $subjectId — great job! '
                'Keep practicing to build mastery.',
            questionIds: [],
          ));
        }

        final selected = topicId != null
            ? weakTopics.where((t) => t.topicId == topicId).toList()
            : weakTopics;
        final target =
            (selected.isNotEmpty ? selected : weakTopics).first;

        final questionsResult = await questionRepo.getBySubject(subjectId);
        final topicQuestions = (questionsResult.data ?? [])
            .where((q) => q.topicId == target.topicId)
            .toList();
        final questionIds = topicQuestions
            .take(10)
            .map((q) => q.id)
            .toList();

        final topicLabel = target.topicId;
        return Result.success(PracticeRecommendation(
          topicId: target.topicId,
          questionIds: questionIds,
          message: 'I found $questionIds.length practice questions on '
              '$topicLabel ($subjectId). Let\'s start there.',
        ));
      },
    ),
    ScheduleLessonTool(plannerService: plannerService, localeName: localeName),
    ScheduleRestDayTool(plannerService: plannerService, localeName: localeName),
    WellbeingAdjustScheduleTool(
      localeName: localeName,
      onAdjust: ({
        required String reminderType,
        required String time,
        required bool enabled,
        String? note,
      }) async {
        final ok = await SettingsService.saveWellbeingReminder({
          'reminderType': reminderType,
          'time': time,
          'enabled': enabled,
          if (note != null) 'note': note,
        });
        return ok
            ? Result.success(null)
            : Result.failure('Failed to persist wellbeing reminder');
      },
    ),
    SearchQuestionsTool(questionRepo: questionRepo),
    GetStudentStatsTool(
      progressTracker: progressTracker,
      studentIdService: studentIdService,
    ),
    GenerateLessonBlocksTool(lessonAgentService: lessonAgentService, localeName: localeName),
    CreatePlanTool(plannerService: plannerService, localeName: localeName),
    ModifyPlanTool(plannerService: plannerService, localeName: localeName),
    // Vision Next-Term §3.1 (scenario_longterm_user_accelerates Step 2): add a
    // new subject to the student's existing plan. The callback loads the active
    // plan and delegates to PlannerService.addSubjectToPlan, which merges the
    // SyllabusGoal list, regenerates the plan, and preserves the plan id and
    // prior date ranges (carrying forward mastered topics and relevant plan
    // fragments). Failure when no existing plan exists, directing the student to
    // create_plan first.
    AddSubjectToPlanTool(
      onAddSubject: ({required SyllabusGoal newGoal}) async {
        final existingResult = await plannerService.loadExistingPlan();
        final existingPlan = existingResult.data;
        if (existingPlan == null) {
          return Result.failure(
            'No existing plan found. Use create_plan first to establish a study plan.',
          );
        }
        return plannerService.addSubjectToPlan(
          newGoal: newGoal,
          existingPlan: existingPlan,
        );
      },
    ),
    // Vision Next-Term §3.1: explicit syllabus focus so the mentor can honor a
    // "switch focus to Math" request from the student and scope subsequent tool
    // calls. The callback writes to the shared SyllabusFocusService that
    // MentorContextBuilder reads on the next context rebuild.
    SwitchSyllabusFocusTool(
      onFocusChanged: ({
        required String subjectId,
        String? subjectTitle,
        int? days,
      }) async {
        focusService.setFocus(
          subjectId,
          subjectTitle: subjectTitle,
          days: days,
        );
        return Result.success(null);
      },
    ),
    // Vision Next-Term §3.1 (scenario_longterm_user_accelerates Step 3):
    // the mentor agent can switch AI provider at runtime. The callback updates
    // the Riverpod StateProviders so the new config takes effect for subsequent
    // LlmService reads, and persists via SettingsController.
    SwitchProviderTool(
      onSwitch: ({
        required LlmProvider provider,
        required String? apiKey,
        required String? baseUrl,
        required String? model,
      }) async {
        ref.read(llmProviderProvider.notifier).state = provider;
        if (apiKey != null && apiKey.isNotEmpty) {
          ref.read(apiKeyProvider.notifier).state = apiKey;
        }
        if (baseUrl != null && baseUrl.isNotEmpty) {
          ref.read(apiBaseUrlProvider.notifier).state = baseUrl;
        }
        if (model != null && model.isNotEmpty) {
          ref.read(selectedModelProvider.notifier).state = model;
        }
        return Result.success(null);
      },
    ),
    GetWeakTopicsTool(
      masteryService: masteryService,
      studentIdService: studentIdService,
    ),
    GetAdherenceTrendsTool(
      orchestrator: planOrchestrator,
      studentIdService: studentIdService,
    ),
    GetLessonHistoryTool(
      lessonRepository: lessonRepository,
      tutorSessionRepository: tutorSessionRepository,
      studentIdService: studentIdService,
    ),
    CreatePracticeSessionTool(
      questionRepo: questionRepo,
      srService: srService,
      masteryService: masteryService,
      scorer: scorer,
      examSessionService: examSessionService,
      studentIdService: studentIdService,
    ),
    GetSyllabusStructureTool(
      subjectRepo: subjectRepo,
      topicRepo: topicRepo,
      masteryService: masteryService,
      dependencyRepo: ref.watch(topicDependencyRepositoryProvider),
      studentIdService: studentIdService,
    ),
    // Off-period preparation toolbox (Vision Next-Term §4.3). Previously these
    // four tools existed but were never registered, so the mentor agent could
    // not invoke them and their spend was never attributed to a prep category.
    // Now the agent can call them and they stamp the correct taskTypeKey that
    // [PrepBudgetService.spendingByCategory] reads live.
    IngestPdfToKbTool(
      llmService: llmService,
      modelId: modelId,
      taskManager: taskManager,
      usageMeter: usageMeter,
      budgetService: budgetService,
      systemMonitor: systemMonitor,
    ),
    EnqueueQuestionVariantsTool(
      variantService: questionVariantService,
      questionRepo: questionRepo,
      taskManager: taskManager,
      usageMeter: usageMeter,
      budgetService: budgetService,
    ),
    PreGenerateLessonTool(
      lessonAgentService: lessonAgentService,
      taskManager: taskManager,
      usageMeter: usageMeter,
      budgetService: budgetService,
      notificationService: notificationService,
    ),
    RefreshMasteryTool(
      masteryService: masteryService,
      studentIdService: studentIdService,
      taskManager: taskManager,
      usageMeter: usageMeter,
      budgetService: budgetService,
    ),
    // Vision Next-Term §3.1 / §4.1: source-content reader. Lets the mentor agent
    // open an ingested source and read its page-cited chunks so lessons and
    // question banks are grounded in the student's material, not metadata alone.
    ReadSourceContentTool(
      sourceRepo: sourceRepo,
      studentIdService: studentIdService,
    ),
    // Vision Next-Term §3.1 / scenario_ingestion_pdf_to_knowledge_base Step 3:
    // conversational search across ingested source chunks so the mentor can
    // answer "where does my textbook discuss X?" with page-cited results.
    SearchSourcesTool(
      sourceRepo: sourceRepo,
      studentIdService: studentIdService,
    ),
    // Vision Next-Term §3.1 / scenario_ingestion_pdf_to_knowledge_base Step 5:
    // paged, recency-ordered revisit of ingested materials so the mentor can
    // surface "the sources you uploaded last week" conversationally.
    RevisitSourcesTool(
      sourceRepo: sourceRepo,
      studentIdService: studentIdService,
    ),
    // Vision Next-Term §3.1 (scenario_practice_mistake_review /
    // scenario_practice_review_adaptive): exposes recent wrong answers with
    // markscheme explanations and linked concepts so the mentor can review
    // mistakes conversationally instead of redirecting to a separate UI.
    ReviewMistakesTool(
      mistakeReviewService: mistakeReviewService,
      studentIdService: studentIdService,
      focusService: focusService,
    ),
  ];
});

final llmAgentProvider = Provider.family<LlmAgent?, String>((ref, studentId) {
  final llmService = ref.watch(llmServiceProvider);
  final modelId = ref.watch(mentorModelIdProvider);
  final tools = ref.watch(llmAgentToolsProvider);
  final systemMonitor = ref.watch(systemMonitorServiceProvider);
  final prepBudget = ref.watch(prepBudgetSettingsProvider);

  if (llmService.config.apiKey.isEmpty) return null;

  final taskManager = ref.watch(llmTaskManagerProvider);
  final usageMeter = ref.watch(llmUsageMeterProvider);
  
  // Vision §4.2: quiet-hours + per-subject opt-in — the shared off-period
  // prep queue (idleExecutorProvider) defers prep tasks when (a) the student
  // has configured a quiet window (e.g. 22:00–08:00) or (b) a syllabus has
  // been paused via the per-subject prep toggle. Both predicates are derived
  // from the persisted [PrepBudget] so the executor stays free of a direct
  // budget-model dependency at the service layer (mirrors the existing
  // quiet-hours injection pattern).
  // The PrepBudgetService is also injected so the IdleExecutor can consult
  // canSpend() before creating the parent LlmTask (Vision Next-Term §4.2/§4.4),
  // deferring over-budget prep instead of starting it and failing at the tool level.
  //
  // Vision Next-Term §4.2: the queue is SHARED with bulk ingestion and with
  // the task-manager portal, so prep the mentor defers through AgentLoop is
  // visible as queued → running → done/failed instead of vanishing into a
  // private executor. The provider owns the queue's lifecycle
  // (init/monitor/dispose); the agent must not dispose it.
  final agent = AgentFactory.create(
    llmService: llmService,
    modelId: modelId,
    studentId: studentId,
    taskManager: taskManager,
    tools: tools,
    systemMonitor: systemMonitor,
    shouldDeferForQuietHours: (now) => prepBudget.shouldDeferForQuietHours(now),
    isPrepEnabledForSubject: (subjectId) =>
        prepBudget.isPrepEnabledForSubject(subjectId),
    usageMeter: usageMeter,
    prepBudgetService: ref.watch(prepBudgetServiceProvider),
    idleExecutor: ref.watch(idleExecutorProvider),
  );

  return agent;
});

final longTermMemoryProvider = Provider<LongTermMemory>((ref) {
  return LongTermMemory();
});
