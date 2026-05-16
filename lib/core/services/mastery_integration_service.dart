import '../errors/result.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'mastery_graph_service.dart';

class MasteryIntegrationService {
  final MasteryGraphService _masteryService;

  static const List<double> _intervalMultipliers = [1.0, 1.5, 2.0, 3.0, 5.0, 8.0];

  MasteryGraphService get masteryService => _masteryService;

  MasteryIntegrationService({
    MasteryGraphService? masteryService,
    MasteryGraphRepository? repository,
  })  : _masteryService = masteryService ?? MasteryGraphService();

  Future<void> initialize() async {
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
    return _masteryService.recordAttempt(
      studentId: studentId,
      topicId: topicId,
      questionId: questionId,
      isCorrect: isCorrect,
      confidence: confidence,
      timeSpentMs: timeSpentMs,
      subtopicId: subtopicId,
    );
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
    final difficulty = _recommendedDifficulty(
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
    final interval = _calculateReviewInterval(
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

  int _recommendedDifficulty({
    required double currentAccuracy,
    required int currentStreak,
  }) {
    if (currentAccuracy < 0.6) {
      return 0;
    } else if (currentAccuracy > 0.9 && currentStreak >= 5) {
      return 2;
    }
    return 1;
  }

  double _calculateReviewInterval({
    required int correctCount,
    required int incorrectCount,
    required double averageConfidence,
  }) {
    final totalAttempts = correctCount + incorrectCount;
    if (totalAttempts == 0) return 1.0;

    final accuracy = correctCount / totalAttempts;
    final strength = (accuracy * 2 + averageConfidence / 5) / 3;

    final intervalIndex = (strength.clamp(0.0, 1.0) * (_intervalMultipliers.length - 1)).ceil().clamp(0, _intervalMultipliers.length - 1);
    return _intervalMultipliers[intervalIndex];
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