import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm_agent/llm_agent.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/long_term_memory.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/mentor/services/tools/schedule_lesson_tool.dart';
import 'package:studyking/features/mentor/services/tools/search_questions_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_student_stats_tool.dart';
import 'package:studyking/features/mentor/services/tools/generate_lesson_blocks_tool.dart';
import 'package:studyking/features/mentor/services/tools/create_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/modify_plan_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_weak_topics_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_adherence_trends_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_lesson_history_tool.dart';
import 'package:studyking/features/mentor/services/tools/create_practice_session_tool.dart';
import 'package:studyking/features/mentor/services/tools/get_syllabus_structure_tool.dart';
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

  return [
    ScheduleLessonTool(plannerService: plannerService, localeName: localeName),
    SearchQuestionsTool(questionRepo: questionRepo),
    GetStudentStatsTool(
      progressTracker: progressTracker,
      studentIdService: studentIdService,
    ),
    GenerateLessonBlocksTool(lessonAgentService: lessonAgentService, localeName: localeName),
    CreatePlanTool(plannerService: plannerService, localeName: localeName),
    ModifyPlanTool(plannerService: plannerService, localeName: localeName),
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
  ];
});

final llmAgentProvider = Provider.family<LlmAgent?, String>((ref, studentId) {
  final llmService = ref.watch(llmServiceProvider);
  final modelId = ref.watch(mentorModelIdProvider);
  final taskManager = ref.watch(llmTaskManagerProvider);
  final tools = ref.watch(llmAgentToolsProvider);

  if (llmService.config.apiKey.isEmpty) return null;

  return AgentFactory.create(
    llmService: llmService,
    modelId: modelId,
    studentId: studentId,
    taskManager: taskManager,
    tools: tools,
  );
});

final longTermMemoryProvider = Provider<LongTermMemory>((ref) {
  return LongTermMemory();
});
