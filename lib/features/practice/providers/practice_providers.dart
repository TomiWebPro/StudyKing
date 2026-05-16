import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/cross_feature_integrator.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/difficulty_adapter.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

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
  final srEngine = ref.read(spacedRepetitionEngineProvider);
  return SpacedRepetitionService(
    questionRepo: questionRepo,
    attemptRepo: attemptRepo,
    srEngine: srEngine,
  );
});

final spacedRepetitionEngineProvider = Provider<SpacedRepetitionEngine>((ref) {
  return SpacedRepetitionEngine();
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

final masteryRecorderProvider = Provider<MasteryRecorder>((ref) {
  return MasteryRecorder(
    masteryGraphService: ref.read(masteryGraphServiceProvider),
    srEngine: ref.read(spacedRepetitionEngineProvider),
    attemptRepo: ref.read(attemptRepositoryProvider),
    questionMasteryRepo: ref.read(questionMasteryStateRepositoryProvider),
    questionRepo: ref.read(questionRepositoryProvider),
  );
});

final readinessScorerProvider = Provider<ReadinessScorer>((ref) {
  return ReadinessScorer();
});

final difficultyAdapterProvider = Provider<DifficultyAdapter>((ref) {
  return DifficultyAdapter();
});

final examSessionServiceProvider = Provider<ExamSessionService>((ref) {
  return ExamSessionService(
    sessionRepo: ref.read(sessionRepositoryProvider),
    studentIdService: ref.read(studentIdServiceProvider),
  );
});

final mistakeReviewServiceProvider = Provider<MistakeReviewService>((ref) {
  return MistakeReviewService(
    attemptRepo: ref.read(attemptRepositoryProvider),
    questionRepo: ref.read(questionRepositoryProvider),
  );
});

final crossFeatureIntegratorProvider = Provider<CrossFeatureIntegrator>((ref) {
  return CrossFeatureIntegrator(
    sessionRepo: ref.read(sessionRepositoryProvider),
    studentIdService: ref.read(studentIdServiceProvider),
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
