import '../data/models/mastery_state_model.dart';
import '../data/models/question_mastery_state_model.dart';
import '../data/repositories/mastery_graph_repository.dart';
import 'mastery_graph_service.dart';
import 'adaptive_practice_engine.dart';

class MasteryIntegrationService {
  final MasteryGraphService _masteryService;
  final MasteryGraphRepository _repository;
  final AdaptivePracticeEngine _adaptiveEngine;

  MasteryGraphService get masteryService => _masteryService;

  MasteryIntegrationService({
    MasteryGraphService? masteryService,
    MasteryGraphRepository? repository,
    AdaptivePracticeEngine? adaptiveEngine,
  })  : _masteryService = masteryService ?? MasteryGraphService(),
        _repository = repository ?? MasteryGraphRepository(),
        _adaptiveEngine = adaptiveEngine ?? AdaptivePracticeEngine();

  Future<Result<void>> initialize() async {
    return _masteryService.init();
  }

  Future<Result<void>> recordAttemptWithMasteryUpdate({
    required String studentId,
    required String topicId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) async {
    final result = await _masteryService.recordAttempt(
      studentId: studentId,
      topicId: topicId,
      questionId: questionId,
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
      subtopicId: subtopicId,
    );

    _adaptiveEngine.updateQuestionState(
      questionId: questionId,
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
    );

    final masteryResult = await _masteryService.getQuestionMastery(studentId, questionId);
    if (masteryResult.isSuccess && masteryResult.data != null) {
      await _repository.updateQuestionMasteryState(masteryResult.data!);
    }

    return result;
  }

  Future<Result<Map<String, dynamic>>> getAdaptiveRecommendation({
    required String studentId,
    required String topicId,
    int maxQuestions = 10,
  }) async {
    final masteryResult = await _masteryService.getTopicMastery(studentId, topicId);
    if (masteryResult.isFailure) {
      return Result.failure(masteryResult.error);
    }

    final mastery = masteryResult.data!;
    final difficulty = _adaptiveEngine.getRecommendedDifficulty(
      topicId: topicId,
      currentAccuracy: mastery.accuracy,
      currentStreak: mastery.currentStreak,
    );

    return Result.success({
      'difficulty': difficulty,
      'masteryLevel': mastery.masteryLevel,
      'readinessScore': mastery.readinessScore,
      'suggestedFocus': _getSuggestedFocus(mastery),
    });
  }

  String _getSuggestedFocus(MasteryState mastery) {
    if (mastery.accuracy < 0.6) return 'Review fundamentals';
    if (mastery.reviewUrgency > 0.7) return 'Review at-risk topics';
    if (mastery.currentStreak < 3) return 'Build consistency';
    if (mastery.readinessScore > 0.8) return 'Challenge advanced problems';
    return 'Practice and reinforce';
  }

  Future<Result<double>> calculateSpacedRepetitionInterval({
    required String studentId,
    required String questionId,
  }) async {
    final masteryResult = await _masteryService.getQuestionMastery(studentId, questionId);
    if (masteryResult.isFailure) {
      return Result.failure(masteryResult.error);
    }

    final mastery = masteryResult.data!;
    final interval = _adaptiveEngine.calculateReviewInterval(
      correctCount: mastery.correctCount,
      incorrectCount: mastery.incorrectCount,
      averageConfidence: mastery.averageConfidence,
    );

    return Result.success(interval);
  }

  Future<Result<List<String>>> getPrioritizedQuestionIds({
    required String studentId,
    required List<String> availableQuestionIds,
    int limit = 10,
  }) async {
    try {
      final questionMasteryList = <(String, QuestionMasteryState, double)>[];

      for (final qId in availableQuestionIds) {
        final result = await _masteryService.getQuestionMastery(studentId, qId);
        if (result.isSuccess && result.data != null) {
          final priority = 1 - result.data!.reviewUrgency + result.data!.masteryLevel * 0.5;
          questionMasteryList.add((qId, result.data!, priority));
        }
      }

      questionMasteryList.sort((a, b) => b.$3.compareTo(a.$3));

      return Result.success(questionMasteryList.take(limit).map((t) => t.$1).toList());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) {
    return _masteryService.getMasterySnapshot(studentId);
  }

  Future<Result<List<MasteryState>>> getTopicMasteries(String studentId) {
    return _masteryService.getAllTopicMastery(studentId);
  }

  Future<Result<MasteryState>> getTopicMastery(String studentId, String topicId) {
    return _masteryService.getTopicMastery(studentId, topicId);
  }

  Future<Result<void>> migrateLegacyQuestion({
    required String questionId,
    String? markscheme,
    String? correctAnswer,
    List<String>? options,
    String? explanation,
  }) {
    return _masteryService.migrateLegacyQuestion(
      questionId: questionId,
      markscheme: markscheme,
      correctAnswer: correctAnswer,
      options: options,
      explanation: explanation,
    );
  }
}