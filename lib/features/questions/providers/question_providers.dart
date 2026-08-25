import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show selectedModelProvider;
import 'package:studyking/core/providers/llm_providers.dart'
    show llmServiceProvider;
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return SourceRepository();
});

/// Service that generates and links LLM-produced variants of a question and
/// selects them for adaptive retry during practice.
final questionVariantServiceProvider = Provider<QuestionVariantService>((ref) {
  final questionRepo = ref.watch(questionRepositoryProvider);
  final llmService = ref.watch(llmServiceProvider);
  final modelId = ref.watch(selectedModelProvider);
  return QuestionVariantService(
    questionRepo: questionRepo,
    llmService: llmService,
    modelId: modelId,
  );
});
