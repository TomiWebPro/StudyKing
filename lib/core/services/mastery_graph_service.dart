import '../errors/result.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'mastery_calculation_service.dart';

class MasteryGraphService {
  final MasteryStateRepository masteryStateRepo;
  final QuestionMasteryStateRepository questionMasteryRepo;
  final TopicDependencyRepository topicDependencyRepo;
  final QuestionEvaluationRepository questionEvaluationRepo;
  final MasteryGraphRepository _repository;
  final MasteryCalculationService _calculationService;

  MasteryGraphService({
    MasteryGraphRepository? repository,
    MasteryStateRepository? masteryStateRepo,
    QuestionMasteryStateRepository? questionMasteryRepo,
    TopicDependencyRepository? topicDependencyRepo,
    QuestionEvaluationRepository? questionEvaluationRepo,
    MasteryCalculationService? calculationService,
  })  : _repository = repository ?? MasteryGraphRepository(
          masteryStateRepo: masteryStateRepo,
          questionMasteryRepo: questionMasteryRepo,
          topicDependencyRepo: topicDependencyRepo,
          questionEvaluationRepo: questionEvaluationRepo,
        ),
        masteryStateRepo = masteryStateRepo ?? MasteryStateRepository(),
        questionMasteryRepo = questionMasteryRepo ?? QuestionMasteryStateRepository(),
        topicDependencyRepo = topicDependencyRepo ?? TopicDependencyRepository(),
        questionEvaluationRepo = questionEvaluationRepo ?? QuestionEvaluationRepository(),
        _calculationService = calculationService ?? MasteryCalculationService();

  Future<void> init() => _repository.init();

  Future<Result<void>> recordAttempt({
    required String studentId,
    required String topicId,
    required String questionId,
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

    final updateResult =
        await masteryStateRepo.updateMasteryState(updatedTopicMastery);
    if (updateResult.isFailure) {
      return updateResult;
    }

    final questionMasteryResult =
        await questionMasteryRepo.getQuestionMasteryState(
            studentId, questionId);
    if (questionMasteryResult.isFailure) {
      return Result.failure(questionMasteryResult.error);
    }

    final questionMastery = questionMasteryResult.data!;
    questionMastery.recordAttempt(
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
    );

    return questionMasteryRepo.updateQuestionMasteryState(questionMastery);
  }

  Future<Result<MasteryState>> getTopicMastery(
      String studentId, String topicId) {
    return masteryStateRepo.getMasteryState(studentId, topicId);
  }

  Future<Result<QuestionMasteryState>> getQuestionMastery(
      String studentId, String questionId) {
    return questionMasteryRepo.getQuestionMasteryState(studentId, questionId);
  }

  Future<Result<List<QuestionMasteryState>>> getQuestionsDueForReview(
    String studentId, {
    DateTime? asOf,
  }) {
    return questionMasteryRepo.getDueQuestions(studentId, asOf: asOf);
  }

  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) {
    return questionMasteryRepo.getAtRiskQuestions(
        studentId, threshold: threshold);
  }

  Future<Result<List<MasteryState>>> getTopicsNeedingReview(
      String studentId) {
    return masteryStateRepo.getTopicsNeedingReview(studentId);
  }

  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) {
    return masteryStateRepo.getWeakTopics(studentId);
  }

  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) {
    return masteryStateRepo.getMasterySnapshot(studentId);
  }

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

  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) {
    return questionEvaluationRepo.saveEvaluation(evaluation);
  }

  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) {
    return masteryStateRepo.getAllMasteryStates(studentId);
  }

  Future<Result<double>> getReadinessScore(
      String studentId, String topicId) async {
    final result =
        await masteryStateRepo.getMasteryState(studentId, topicId);
    if (result.isFailure) return Result.failure(result.error);
    return Result.success(result.data!.readinessScore);
  }

  Future<Result<double>> getReviewUrgency(
      String studentId, String topicId) async {
    final result =
        await masteryStateRepo.getMasteryState(studentId, topicId);
    if (result.isFailure) return Result.failure(result.error);
    return Result.success(result.data!.reviewUrgency);
  }
}
