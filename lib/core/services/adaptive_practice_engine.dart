import '../data/models/question_model.dart';
import '../data/models/topic_progress_model.dart';

class AdaptivePracticeEngine {
  /// Interval multipliers for spaced repetition
  final List<double> _intervalMultipliers = [1.0, 1.5, 2.0, 3.0, 5.0, 8.0];

  /// Track question knowledge state
  final Map<String, _QuestionState> _questionStates = {};

  /// Get next question to practice based on weak areas
  Future<List<Question>> getNextPracticeQuestions({
    required List<Question> availableQuestions,
    required Map<String, TopicProgress> topicProgress,
    int maxQuestions = 10,
  }) async {
    // Calculate weakness scores for each topic
    final topicWeakness = <String, double>{};
    
    topicProgress.forEach((topicId, progress) {
      final weakness = 1.0 - progress.accuracy;
      topicWeakness[topicId] = weakness;
    });

    // Sort questions by topic weakness
    final sortedQuestions = availableQuestions..sort((a, b) {
      final weaknessA = topicWeakness.containsKey(a.topicId) 
          ? topicWeakness[a.topicId]! 
          : 0.0;
      final weaknessB = topicWeakness.containsKey(b.topicId) 
          ? topicWeakness[b.topicId]! 
          : 0.0;
      return weaknessB.compareTo(weaknessA);
    });

    // Also consider question recency and difficulty
    final practiced = _questionStates.values
        .where((s) => s.lastPracticed.isBefore(DateTime.now().subtract(const Duration(hours: 24))))
        .map((s) => s.questionId);

    final unpracticed = sortedQuestions.where((q) => !practiced.contains(q.id));
    final recentlyPracticed = sortedQuestions.where((q) => practiced.contains(q.id));

    // Combine unpracticed weak questions with some recently practiced ones
    final result = <Question>[];
    result.addAll(unpracticed.take(maxQuestions ~/ 2));
    result.addAll(recentlyPracticed.take(maxQuestions - (result.length)));

    return result.take(maxQuestions).toList();
  }

  /// Get optimal review interval for a question
  double calculateReviewInterval({
    required int correctCount,
    required int incorrectCount,
    required double averageConfidence,
  }) {
    final totalAttempts = correctCount + incorrectCount;
    if (totalAttempts == 0) return 1.0; // Review immediately

    final accuracy = correctCount / totalAttempts;
    final strength = (accuracy * 2 + averageConfidence / 5) / 3;

    // Higher strength = longer interval
    final intervalIndex = (strength.clamp(0.0, 1.0) * (_intervalMultipliers.length - 1)).ceil().clamp(0, _intervalMultipliers.length - 1);
    
    return _intervalMultipliers[intervalIndex];
  }

  /// Update question state after attempt
  void updateQuestionState({
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
  }) {
    if (!_questionStates.containsKey(questionId)) {
      _questionStates[questionId] = _QuestionState(questionId: questionId);
    }

    final state = _questionStates[questionId]!;
    state.totalAttempts++;
    
    if (isCorrect) {
      state.correctAttempts++;
      state.streak++;
      state.lastCorrect = DateTime.now();
    } else {
      state.streak = 0;
      state.lastIncorrect = DateTime.now();
    }

    // Update confidence tracking
    state.confidenceHistory.add(confidence);
    if (state.confidenceHistory.length > 20) {
      state.confidenceHistory.removeAt(0);
    }

    state.lastPracticed = DateTime.now();
    state.timeSpentMs = timeSpentMs;
  }

  /// Get recommended difficulty for next question
  int getRecommendedDifficulty({
    required String topicId,
    required double currentAccuracy,
    required int currentStreak,
  }) {
    // Adjust difficulty based on performance
    if (currentAccuracy < 0.6) {
      // Struggling - reduce difficulty
      return 0;
    } else if (currentAccuracy > 0.9 && currentStreak >= 5) {
      // Doing well - increase difficulty
      return 2;
    }
    return 1; // Stay at current level
  }

  /// Generate variant of existing question for reinforcement
  List<String> generateQuestionVariants(String originalQuestionId, int count) {
    return List.generate(count, (i) => 'variant_${originalQuestionId}_$i');
  }

  /// Get practice recommendations for a topic
  Map<String, dynamic> getTopicRecommendations(String topicId, TopicProgress progress) {
    final accuracy = progress.accuracy;
    final totalAttempts = progress.questionsAnswered;

    Map<String, dynamic> recommendations = {};

    if (accuracy < 0.6) {
      recommendations['focus'] = 'fundamentals';
      recommendations['suggestion'] = 'Review basic concepts first';
    } else if (accuracy < 0.8) {
      recommendations['focus'] = 'practice';
      recommendations['suggestion'] = 'More practice questions recommended';
    } else {
      recommendations['focus'] = 'mastery';
      recommendations['suggestion'] = 'Ready for advanced topics';
    }

    recommendations['timeToReview'] = calculateReviewInterval(
      correctCount: progress.correctAnswers,
      incorrectCount: totalAttempts - progress.correctAnswers,
      averageConfidence: 3.0, // Would need confidence history
    ).toInt();

    return recommendations;
  }
}

class _QuestionState {
  final String questionId;
  int totalAttempts = 0;
  int correctAttempts = 0;
  int streak = 0;
  DateTime lastPracticed = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? lastCorrect;
  DateTime? lastIncorrect;
  List<int> confidenceHistory = [];
  int timeSpentMs = 0;

  double get accuracy => totalAttempts == 0 ? 0.0 : correctAttempts / totalAttempts;

  double get averageConfidence => confidenceHistory.isEmpty 
      ? 3.0 
      : confidenceHistory.reduce((a, b) => a + b) / confidenceHistory.length;

  _QuestionState({required this.questionId});
}
