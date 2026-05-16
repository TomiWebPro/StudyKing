import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository();
});

final attemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

final masteryStateRepositoryProvider = Provider<MasteryStateRepository>((ref) {
  return MasteryStateRepository();
});

final questionMasteryStateRepositoryProvider = Provider<QuestionMasteryStateRepository>((ref) {
  return QuestionMasteryStateRepository();
});

final topicDependencyRepositoryProvider = Provider<TopicDependencyRepository>((ref) {
  return TopicDependencyRepository();
});

final questionEvaluationRepositoryProvider = Provider<QuestionEvaluationRepository>((ref) {
  return QuestionEvaluationRepository();
});

final spacedRepetitionRepositoryProvider = Provider<SpacedRepetitionRepository>((ref) {
  final questionRepo = ref.read(questionRepositoryProvider);
  final attemptRepo = ref.read(attemptRepositoryProvider);
  return SpacedRepetitionRepository(
    questionRepo: questionRepo,
    attemptRepo: attemptRepo,
  );
});

final spacedRepetitionServiceProvider = Provider<SpacedRepetitionService>((ref) {
  final questionRepo = ref.read(questionRepositoryProvider);
  final attemptRepo = ref.read(attemptRepositoryProvider);
  return SpacedRepetitionService(
    questionRepo: questionRepo,
    attemptRepo: attemptRepo,
  );
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

final masteryGraphServiceProvider = Provider<MasteryGraphService>((ref) {
  return MasteryGraphService(
    masteryStateRepo: ref.read(masteryStateRepositoryProvider),
    questionMasteryRepo: ref.read(questionMasteryStateRepositoryProvider),
    topicDependencyRepo: ref.read(topicDependencyRepositoryProvider),
    questionEvaluationRepo: ref.read(questionEvaluationRepositoryProvider),
  );
});

final practiceDataServiceProvider = Provider<PracticeDataService>((ref) {
  return PracticeDataService(
    srService: ref.read(spacedRepetitionServiceProvider),
    questionRepo: ref.read(questionRepositoryProvider),
    subjectRepo: ref.read(subjectRepositoryProvider),
    studentIdService: ref.read(studentIdServiceProvider),
  );
});
