import '../errors/result.dart';
import 'package:studyking/core/data/repositories/mastery_state_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'mastery_calculation_service.dart';

/// Orchestrates mastery recording (recordAttempt, recordTopicAttempt,
/// recordQuestionAttempt). Remaining public methods are pass-through
/// delegations to the injected repositories — prefer calling the
/// repositories directly when adding new functionality.
class MasteryGraphService {
  final MasteryStateRepository masteryStateRepo;
  final QuestionMasteryStateRepository questionMasteryRepo;
  final TopicDependencyRepository topicDependencyRepo;
  final QuestionEvaluationRepository questionEvaluationRepo;
  final MasteryCalculationService _calculationService;

  MasteryGraphService({
    MasteryStateRepository? masteryStateRepo,
    QuestionMasteryStateRepository? questionMasteryRepo,
    TopicDependencyRepository? topicDependencyRepo,
    QuestionEvaluationRepository? questionEvaluationRepo,
    MasteryCalculationService? calculationService,
  })  : masteryStateRepo = masteryStateRepo ?? MasteryStateRepository(),
        questionMasteryRepo = questionMasteryRepo ?? QuestionMasteryStateRepository(),
        topicDependencyRepo = topicDependencyRepo ?? TopicDependencyRepository(),
        questionEvaluationRepo = questionEvaluationRepo ?? QuestionEvaluationRepository(),
        _calculationService = calculationService ?? MasteryCalculationService();

  Future<void> init() async {
    await masteryStateRepo.init();
    await questionMasteryRepo.init();
    await topicDependencyRepo.init();
    await questionEvaluationRepo.init();
  }

  Future<Result<void>> recordTopicAttempt({
    required String studentId,
    required String topicId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) async {
    final topicMasteryResult =
        await masteryStateRepo.getMasteryState(studentId, topicId);
    if (topicMasteryResult.isFailure) {
      return Result.failure(topicMasteryResult.error);
    }

    final updatedTopicMastery = _calculationService.recordAttempt(
      current: topicMasteryResult.data!,
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
      subtopicId: subtopicId,
    );

    return masteryStateRepo.updateMasteryState(updatedTopicMastery);
  }

  Future<Result<void>> recordQuestionAttempt({
    required String studentId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
  }) async {
    final questionMasteryResult =
        await questionMasteryRepo.getQuestionMasteryState(
            studentId, questionId);
    if (questionMasteryResult.isFailure) {
      return Result.failure(questionMasteryResult.error);
    }

    final questionMastery = questionMasteryResult.data!;
    final updated = questionMastery.recordAttempt(
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
      now: DateTime.now(),
    );

    return questionMasteryRepo.updateQuestionMasteryState(updated);
  }

  /// Thin wrapper that calls [recordTopicAttempt] and [recordQuestionAttempt]
  /// sequentially. Note: these are NOT transactionally atomic — if the topic
  /// attempt succeeds but the question attempt fails, the topic state will
  /// already have been updated.
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String topicId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) async {
    final topicResult = await recordTopicAttempt(
      studentId: studentId,
      topicId: topicId,
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
      subtopicId: subtopicId,
    );
    if (topicResult.isFailure) return topicResult;

    return recordQuestionAttempt(
      studentId: studentId,
      questionId: questionId,
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
    );
  }

  // proxy: delegates to masteryStateRepo.getMasteryState
  Future<Result<MasteryState>> getTopicMastery(
      String studentId, String topicId) {
    return masteryStateRepo.getMasteryState(studentId, topicId);
  }

  // proxy: delegates to questionMasteryRepo.getQuestionMasteryState
  Future<Result<QuestionMasteryState>> getQuestionMastery(
      String studentId, String questionId) {
    return questionMasteryRepo.getQuestionMasteryState(studentId, questionId);
  }

  // proxy: delegates to questionMasteryRepo.getAllForStudent
  Future<Result<List<QuestionMasteryState>>> getAllQuestionMastery(
      String studentId) {
    return questionMasteryRepo.getAllForStudent(studentId);
  }

  // proxy: delegates to questionMasteryRepo.getDueQuestions
  Future<Result<List<QuestionMasteryState>>> getQuestionsDueForReview(
    String studentId, {
    DateTime? asOf,
  }) {
    return questionMasteryRepo.getDueQuestions(studentId, asOf: asOf);
  }

  // proxy: delegates to questionMasteryRepo.getAtRiskQuestions
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) {
    return questionMasteryRepo.getAtRiskQuestions(
        studentId, threshold: threshold);
  }

  // proxy: delegates to masteryStateRepo.getTopicsNeedingReview
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(
      String studentId) {
    return masteryStateRepo.getTopicsNeedingReview(studentId);
  }

  // proxy: delegates to masteryStateRepo.getWeakTopics
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) {
    return masteryStateRepo.getWeakTopics(studentId);
  }

  // proxy: delegates to masteryStateRepo.getMasterySnapshot
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) {
    return masteryStateRepo.getMasterySnapshot(studentId);
  }

  // proxy: delegates to questionEvaluationRepo.migrateFromLegacy
  Future<Result<void>> migrateLegacyQuestion({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) {
    return questionEvaluationRepo.migrateFromLegacy(
      questionId: questionId,
      markscheme: markscheme,
      correctAnswer: correctAnswer,
      options: options,
      explanation: explanation,
    );
  }

  // proxy: delegates to questionEvaluationRepo.saveEvaluation
  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) {
    return questionEvaluationRepo.saveEvaluation(evaluation);
  }

  // proxy: delegates to masteryStateRepo.getAllMasteryStates
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) {
    return masteryStateRepo.getAllMasteryStates(studentId);
  }

  // proxy: delegates to masteryStateRepo.getMasteryState
  Future<Result<double>> getReadinessScore(
      String studentId, String topicId) async {
    final result =
        await masteryStateRepo.getMasteryState(studentId, topicId);
    if (result.isFailure) return Result.failure(result.error);
    return Result.success(result.data!.readinessScore);
  }

  // proxy: delegates to masteryStateRepo.getMasteryState
  Future<Result<double>> getReviewUrgency(
      String studentId, String topicId) async {
    final result =
        await masteryStateRepo.getMasteryState(studentId, topicId);
    if (result.isFailure) return Result.failure(result.error);
    return Result.success(result.data!.reviewUrgency);
  }
}
