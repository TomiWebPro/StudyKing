import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';

final spacedRepetitionRepositoryProvider = Provider<SpacedRepetitionRepository>((ref) {
  return SpacedRepetitionRepository();
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

final masteryGraphServiceProvider = Provider<MasteryGraphService>((ref) {
  return MasteryGraphService();
});
