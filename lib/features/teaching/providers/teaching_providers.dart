import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart' show defaultModelForProvider;
import 'package:studyking/core/providers/app_providers.dart' show databaseProvider, localeProvider, llmProviderProvider, selectedModelProvider, engagementMasteryServiceProvider;
import 'package:studyking/core/providers/llm_agent_providers.dart' show longTermMemoryProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/teaching/services/exercise_evaluator.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';

final teachingModelIdProvider = Provider<String>((ref) {
  final savedModel = ref.watch(selectedModelProvider);
  if (savedModel.isNotEmpty) return savedModel;
  final provider = ref.watch(llmProviderProvider);
  return defaultModelForProvider(provider);
});

final clockProvider = Provider<Clock>((ref) => SystemClock());

final exerciseEvaluatorProvider = Provider<ExerciseEvaluator>((ref) {
  final locale = ref.watch(localeProvider);
  return ExerciseEvaluator(
    llmService: ref.watch(llmServiceProvider),
    modelId: ref.watch(teachingModelIdProvider),
    localeName: locale.languageCode,
  );
});

final tutorServiceProvider = Provider<TutorService>((ref) {
  final database = ref.watch(databaseProvider);
  return TutorService(
    database: database,
    llmService: ref.watch(llmServiceProvider),
    masteryService: ref.watch(engagementMasteryServiceProvider),
    modelId: ref.watch(teachingModelIdProvider),
    exerciseEvaluator: ref.watch(exerciseEvaluatorProvider),
    conversationRepository: database.conversationRepository,
    voiceService: ref.watch(voiceServiceProvider),
    longTermMemory: ref.watch(longTermMemoryProvider),
    clock: ref.watch(clockProvider),
  );
});
