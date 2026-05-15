import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

final spacedRepetitionRepositoryProvider = Provider<SpacedRepetitionRepository>((ref) {
  return SpacedRepetitionRepository();
});

final spacedRepetitionServiceProvider = Provider<SpacedRepetitionService>((ref) {
  return SpacedRepetitionService();
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

final masteryGraphServiceProvider = Provider<MasteryGraphService>((ref) {
  return MasteryGraphService();
});

final practiceDataServiceProvider = Provider<PracticeDataService>((ref) {
  return PracticeDataService(
    srService: ref.read(spacedRepetitionServiceProvider),
    questionRepo: ref.read(questionRepositoryProvider),
    subjectRepo: SubjectRepository(),
  );
});
