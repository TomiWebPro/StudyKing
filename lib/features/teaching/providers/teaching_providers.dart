import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart' show database, defaultModelForProvider, llmProviderProvider, selectedModelProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/teaching/services/tutor_service.dart';
import '../services/prompts/prompts.dart';

final teachingModelIdProvider = Provider<String>((ref) {
  final savedModel = ref.watch(selectedModelProvider);
  if (savedModel.isNotEmpty) return savedModel;
  final provider = ref.watch(llmProviderProvider);
  return defaultModelForProvider(provider);
});

final tutorServiceProvider = Provider<TutorService>((ref) {
  return TutorService(
    database: database,
    llmService: ref.watch(llmServiceProvider),
    masteryService: ref.watch(masteryGraphServiceProvider),
    modelId: ref.watch(teachingModelIdProvider),
  );
});

final promptTemplatesProvider = Provider<PromptTemplates>((ref) {
  return PromptTemplates.defaultTemplates;
});
