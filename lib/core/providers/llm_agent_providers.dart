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
import 'package:studyking/features/mentor/services/tools/get_weak_topics_tool.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';

final llmAgentToolsProvider = Provider<List<AgentTool>>((ref) {
  final plannerService = ref.watch(plannerServiceProvider);
  final questionRepo = ref.watch(questionRepositoryProvider);
  final progressTracker = ref.watch(mentorProgressTrackerProvider);
  final masteryService = ref.watch(masteryGraphServiceProvider);
  final studentIdService = StudentIdService();
  final lessonAgentService = ref.watch(lessonAgentServiceProvider);
  final locale = ref.watch(localeProvider);
  final localeName = locale.languageCode;

  return [
    ScheduleLessonTool(plannerService: plannerService, localeName: localeName),
    SearchQuestionsTool(questionRepo: questionRepo),
    GetStudentStatsTool(
      progressTracker: progressTracker,
      studentIdService: studentIdService,
    ),
    GenerateLessonBlocksTool(lessonAgentService: lessonAgentService, localeName: localeName),
    CreatePlanTool(plannerService: plannerService, localeName: localeName),
    GetWeakTopicsTool(
      masteryService: masteryService,
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
