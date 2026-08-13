import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';
import 'package:studyking/features/flashcards/services/flashcard_generator.dart';
import 'package:studyking/features/flashcards/services/flashcard_review_service.dart';
import 'package:studyking/features/flashcards/services/study_guide_generator.dart';
import 'package:studyking/features/flashcards/services/concept_map_generator.dart';
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;

final flashcardRepoProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository();
});

final studyGuideRepoProvider = Provider<StudyGuideRepository>((ref) {
  return StudyGuideRepository();
});

final conceptMapRepoProvider = Provider<ConceptMapRepository>((ref) {
  return ConceptMapRepository();
});

final flashcardGeneratorProvider = Provider<FlashcardGenerator>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final flashcardRepo = ref.watch(flashcardRepoProvider);
  return FlashcardGenerator(
    llmService: llmService,
    flashcardRepository: flashcardRepo,
  );
});

final flashcardReviewServiceProvider = Provider<FlashcardReviewService>((ref) {
  final flashcardRepo = ref.watch(flashcardRepoProvider);
  return FlashcardReviewService(flashcardRepository: flashcardRepo);
});

final studyGuideGeneratorProvider = Provider<StudyGuideGenerator>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final repo = ref.watch(studyGuideRepoProvider);
  return StudyGuideGenerator(llmService: llmService, repository: repo);
});

final conceptMapGeneratorProvider = Provider<ConceptMapGenerator>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final repo = ref.watch(conceptMapRepoProvider);
  return ConceptMapGenerator(llmService: llmService, repository: repo);
});
