import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart';

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

final spacedRepetitionServiceProvider = Provider<SpacedRepetitionService>((ref) {
  final questionRepo = ref.watch(questionRepositoryProvider);
  final attemptRepo = ref.watch(attemptRepositoryProvider);
  final srEngine = ref.watch(spacedRepetitionEngineProvider);
  return SpacedRepetitionService(
    questionRepo: questionRepo,
    attemptRepo: attemptRepo,
    srEngine: srEngine,
  );
});

final spacedRepetitionEngineProvider = Provider<SpacedRepetitionEngine>((ref) {
  return SpacedRepetitionEngine();
});

final masteryGraphServiceProvider = Provider<MasteryGraphService>((ref) {
  return MasteryGraphService(
    masteryStateRepo: ref.watch(masteryStateRepositoryProvider),
    questionMasteryRepo: ref.watch(questionMasteryStateRepositoryProvider),
    topicDependencyRepo: ref.watch(topicDependencyRepositoryProvider),
    questionEvaluationRepo: ref.watch(questionEvaluationRepositoryProvider),
  );
});

final masteryRecorderProvider = Provider<MasteryRecorder>((ref) {
  return MasteryRecorder(
    masteryGraphService: ref.watch(masteryGraphServiceProvider),
    srEngine: ref.watch(spacedRepetitionEngineProvider),
    attemptRepo: ref.watch(attemptRepositoryProvider),
    questionMasteryRepo: ref.watch(questionMasteryStateRepositoryProvider),
    questionRepo: ref.watch(questionRepositoryProvider),
  );
});

final readinessScorerProvider = Provider<ReadinessScorer>((ref) {
  final masteryService = ref.watch(masteryGraphServiceProvider);
  final studentIdService = ref.watch(studentIdServiceProvider);
  return ReadinessScorer(
    masteryService: masteryService,
    studentIdService: studentIdService,
  );
});

final examSessionServiceProvider = Provider<ExamSessionService>((ref) {
  return ExamSessionService(
    sessionRepo: ref.watch(sessionRepositoryProvider),
    studentIdService: ref.watch(studentIdServiceProvider),
  );
});

final mistakeReviewServiceProvider = Provider<MistakeReviewService>((ref) {
  return MistakeReviewService(
    attemptRepo: ref.watch(attemptRepositoryProvider),
    questionRepo: ref.watch(questionRepositoryProvider),
  );
});


