import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart' show databaseProvider, localeProvider, planOrchestratorProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider, spacedRepetitionServiceProvider;
import 'package:studyking/core/providers/llm_agent_providers.dart' show longTermMemoryProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider, modelRouterProvider, llmTaskManagerProvider, llmUsageMeterProvider;
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart' show prepBudgetServiceProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart'
    show plannerServiceProvider;
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';
import 'package:studyking/features/teaching/services/lesson_recap_service.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_recap_repository.dart';
import 'package:studyking/features/mentor/services/tools/pre_generate_lesson_tool.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart' show lessonAgentServiceProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart' show topicRepositoryProvider;

final teachingModelIdProvider = Provider<String>((ref) {
  return ref.watch(modelRouterProvider).resolve(LlmTaskType.tutor);
});

/// Model selected for exercise/answer evaluation (balanced capability).
final evaluationModelIdProvider = Provider<String>((ref) {
  return ref.watch(modelRouterProvider).resolve(LlmTaskType.evaluation);
});

/// Model selected for long-context summarization work.
final summarizationModelIdProvider = Provider<String>((ref) {
  return ref.watch(modelRouterProvider).resolve(LlmTaskType.summarization);
});

final clockProvider = Provider<Clock>((ref) => SystemClock());

final exerciseEvaluatorProvider = Provider<ExerciseEvaluator>((ref) {
  final locale = ref.watch(localeProvider);
  return ExerciseEvaluator(
    llmService: ref.watch(llmServiceProvider),
    modelId: ref.watch(evaluationModelIdProvider),
    localeName: locale.languageCode,
  );
});

/// Pre-generate lesson tool wired into TutorService so that post-lesson prep
/// produces real structured lesson blocks (slides, examples, exercises, recap)
/// instead of a one-line placeholder (Vision Next-Term §4.1, §4.3).
///
/// Returns null when no API key is configured — the TutorService falls back
/// to a minimal placeholder in that case, matching the null-agent guard
/// pattern used by `llmAgentProvider`.
final preGenerateLessonToolProvider = Provider<PreGenerateLessonTool?>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  if (llmService.config.apiKey.isEmpty) return null;
  return PreGenerateLessonTool(
    lessonAgentService: ref.watch(lessonAgentServiceProvider),
    taskManager: ref.watch(llmTaskManagerProvider),
    usageMeter: ref.watch(llmUsageMeterProvider),
    budgetService: ref.watch(prepBudgetServiceProvider),
  );
});

final tutorServiceProvider = Provider<TutorService>((ref) {
  final database = ref.watch(databaseProvider);
  return TutorService(
    database: database,
    llmService: ref.watch(llmServiceProvider),
    masteryService: ref.watch(masteryGraphServiceProvider),
    spacedRepetitionService: ref.watch(spacedRepetitionServiceProvider),
    modelId: ref.watch(teachingModelIdProvider),
    exerciseEvaluator: ref.watch(exerciseEvaluatorProvider),
    conversationRepository: database.conversationRepository,
    voiceService: ref.watch(voiceServiceProvider),
    planOrchestrator: ref.watch(planOrchestratorProvider),
    plannerService: ref.watch(plannerServiceProvider),
    longTermMemory: ref.watch(longTermMemoryProvider),
    feedbackRepository: ref.watch(lessonFeedbackRepositoryProvider),
    clock: ref.watch(clockProvider),
    preGenerateLessonTool: ref.watch(preGenerateLessonToolProvider),
    topicRepository: ref.watch(topicRepositoryProvider),
  );
});

final lessonRecapRepositoryProvider = Provider<LessonRecapRepository>((ref) {
  return LessonRecapRepository();
});

final lessonRecapServiceProvider = Provider<LessonRecapService>((ref) {
  final repo = ref.watch(lessonRecapRepositoryProvider);
  return LessonRecapService(
    llmService: ref.watch(llmServiceProvider),
    modelId: ref.watch(summarizationModelIdProvider),
    repository: repo,
    localeName: ref.watch(localeProvider).languageCode,
  );
});
