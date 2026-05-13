import '../errors/result.dart';
import '../data/repositories/mastery_graph_repository.dart';
import '../data/models/mastery_state_model.dart';
import '../data/models/question_mastery_state_model.dart';
import '../data/models/question_evaluation_model.dart';
import 'answer_validation_service.dart';
import 'mastery_calculation_service.dart';

class MasteryGraphService {
  final MasteryGraphRepository _repository;
  final MasteryCalculationService _calculationService;

  MasteryGraphService({
    MasteryGraphRepository? repository,
    MasteryCalculationService? calculationService,
  })  : _repository = repository ?? MasteryGraphRepository(),
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
    final topicMasteryResult = await _repository.getMasteryState(studentId, topicId);
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

    final updateResult = await _repository.updateMasteryState(updatedTopicMastery);
    if (updateResult.isFailure) {
      return updateResult;
    }

    final questionMasteryResult = await _repository.getQuestionMasteryState(studentId, questionId);
    if (questionMasteryResult.isFailure) {
      return Result.failure(questionMasteryResult.error);
    }

    final questionMastery = questionMasteryResult.data!;
    questionMastery.recordAttempt(
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
    );

    return _repository.updateQuestionMasteryState(questionMastery);
  }

  Future<Result<MasteryState>> getTopicMastery(String studentId, String topicId) {
    return _repository.getMasteryState(studentId, topicId);
  }

  Future<Result<QuestionMasteryState>> getQuestionMastery(String studentId, String questionId) {
    return _repository.getQuestionMasteryState(studentId, questionId);
  }

  Future<Result<List<QuestionMasteryState>>> getQuestionsDueForReview(
    String studentId, {
    DateTime? asOf,
  }) {
    return _repository.getDueQuestions(studentId, asOf: asOf);
  }

  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) {
    return _repository.getAtRiskQuestions(studentId, threshold: threshold);
  }

  Future<Result<List<MasteryState>>> getTopicsNeedingReview(String studentId) {
    return _repository.getTopicsNeedingReview(studentId);
  }

  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) {
    return _repository.getWeakTopics(studentId);
  }

  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) {
    return _repository.getMasterySnapshot(studentId);
  }

  Future<Result<void>> migrateLegacyQuestion({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) {
    return _repository.migrateFromLegacy(
      questionId: questionId,
      markscheme: markscheme,
      correctAnswer: correctAnswer,
      options: options,
      explanation: explanation,
    );
  }

  Future<Result<QuestionEvaluation>> evaluateAnswer(String questionId, String userAnswer) async {
    final evalResult = await _repository.getEvaluation(questionId);
    if (evalResult.isFailure) {
      return Result.failure(evalResult.error);
    }

    final evaluation = evalResult.data!;
    final validationService = AnswerValidationService();
    final result = validationService.validateWithEvaluation(evaluation, userAnswer);

    return Result.success(evaluation.copyWith(
      metadata: {
        ...?evaluation.metadata,
        'lastEvaluation': DateTime.now().toIso8601String(),
        'matched': result.isCorrect,
      },
    ));
  }

  Future<Result<void>> saveEvaluation(QuestionEvaluation evaluation) {
    return _repository.saveEvaluation(evaluation);
  }

  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) {
    return _repository.getAllMasteryStates(studentId);
  }

  Future<Result<double>> getReadinessScore(String studentId, String topicId) async {
    final result = await _repository.getMasteryState(studentId, topicId);
    if (result.isFailure) return Result.failure(result.error);
    return Result.success(result.data!.readinessScore);
  }

  Future<Result<double>> getReviewUrgency(String studentId, String topicId) async {
    final result = await _repository.getMasteryState(studentId, topicId);
    if (result.isFailure) return Result.failure(result.error);
    return Result.success(result.data!.reviewUrgency);
  }
}