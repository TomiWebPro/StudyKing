import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';

final spacedRepetitionRepositoryProvider = Provider<SpacedRepetitionRepository>((ref) {
  return SpacedRepetitionRepository();
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});
