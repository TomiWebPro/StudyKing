import '../errors/result.dart';
import '../utils/study_utils.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'mastery_graph_service.dart';

class MasteryIntegrationService {
  final MasteryGraphService _masteryService;

  static const List<double> _intervalMultipliers = [1.0, 1.5, 2.0, 3.0, 5.0, 8.0];

  @Deprecated('Use MasteryGraphService directly')

  MasteryGraphService get masteryService => _masteryService;

  MasteryIntegrationService({
    MasteryGraphService? masteryService,
    MasteryGraphRepository? repository,
  })  : _masteryService = masteryService ?? MasteryGraphService();

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
    if (mastery.accuracy < masteryLowAccuracy) return 'Review fundamentals';
    if (mastery.reviewUrgency > masteryReviewUrgencyThreshold) return 'Review at-risk topics';
    if (mastery.currentStreak < masteryStreakConsistency) return 'Build consistency';
    if (mastery.readinessScore > masteryChallengeReadiness) return 'Challenge advanced problems';
    return 'Practice and reinforce';
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
          final priority = 1 - result.data!.reviewUrgency + result.data!.masteryLevel * adherenceDefaultScore;
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
    if (currentAccuracy < masteryLowAccuracy) {
      return 0;
    } else if (currentAccuracy > masteryHighAccuracy && currentStreak >= masteryStreakHigh) {
      return 2;
    }
    return 1;
  }

  Future<Result<double>> calculateSpacedRepetitionInterval({
    required String studentId,
    required String questionId,
  }) async {
    final result = await _masteryService.getQuestionMastery(studentId, questionId);
    if (result.isFailure) {
      return Result.failure(result.error);
    }
    final qm = result.data!;
    final avgConfidence = qm.confidenceHistory.isNotEmpty
        ? qm.confidenceHistory.reduce((a, b) => a + b) / qm.confidenceHistory.length
        : 0.0;
    return Result.success(_calculateReviewInterval(
      correctCount: qm.correctCount,
      incorrectCount: qm.incorrectCount,
      averageConfidence: avgConfidence,
    ));
  }

  Future<Result<void>> initialize() async {
    await _masteryService.init();
    return Result.success(null);
  }

  Future<Result<void>> recordAttemptWithMasteryUpdate({
    required String studentId,
    required String topicId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) {
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
}