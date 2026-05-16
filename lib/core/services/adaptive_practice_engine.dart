import '../data/models/question_model.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';
import '../../l10n/generated/app_localizations.dart';

class _QuestionState {
  int correctCount = 0;
  int incorrectCount = 0;
  int streak = 0;
  int totalTimeSpentMs = 0;
  double averageConfidence = 0.0;
  int attemptCount = 0;
}

class AdaptivePracticeEngine {
  final List<double> _intervalMultipliers = [1.0, 1.5, 2.0, 3.0, 5.0, 8.0];
  final AppLocalizations? _l10n;
  final Map<String, _QuestionState> _questionStates = {};

  AdaptivePracticeEngine({AppLocalizations? l10n})
      : _l10n = l10n;

  void updateQuestionState({
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
  }) {
    final state = _questionStates.putIfAbsent(questionId, () => _QuestionState());
    if (isCorrect) {
      state.correctCount++;
      state.streak++;
    } else {
      state.incorrectCount++;
      state.streak = 0;
    }
    state.averageConfidence = ((state.averageConfidence * state.attemptCount) + confidence) / (state.attemptCount + 1);
    state.attemptCount++;
    state.totalTimeSpentMs += timeSpentMs;
  }

  Future<List<Question>> getNextPracticeQuestions({
    required List<Question> availableQuestions,
    required Map<String, TopicProgress> topicProgress,
    int maxQuestions = 10,
  }) async {
    final topicWeakness = <String, double>{};
    topicProgress.forEach((topicId, progress) {
      final weakness = 1.0 - progress.accuracy;
      topicWeakness[topicId] = weakness;
    });

    final sortedQuestions = availableQuestions..sort((a, b) {
      final weaknessA = topicWeakness.containsKey(a.topicId) 
          ? topicWeakness[a.topicId]! 
          : 0.0;
      final weaknessB = topicWeakness.containsKey(b.topicId) 
          ? topicWeakness[b.topicId]! 
          : 0.0;
      return weaknessB.compareTo(weaknessA);
    });

    return sortedQuestions.take(maxQuestions).toList();
  }

  double calculateReviewInterval({
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
  int getRecommendedDifficulty({
    required String topicId,
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

  List<String> generateQuestionVariants(String originalQuestionId, int count) {
    return List.generate(count, (i) => 'variant_${originalQuestionId}_$i');
  }

  Map<String, dynamic> getTopicRecommendations(String topicId, TopicProgress progress) {
    final accuracy = progress.accuracy;
    final totalAttempts = progress.questionsAnswered;

    final Map<String, dynamic> recommendations = {};

    if (accuracy < 0.6) {
      recommendations['focus'] = 'fundamentals';
      recommendations['suggestion'] = _l10n?.adapSuggestionFundamentals ?? 'Review basic concepts first';
    } else if (accuracy < 0.8) {
      recommendations['focus'] = 'practice';
      recommendations['suggestion'] = _l10n?.adapSuggestionMorePractice ?? 'More practice questions recommended';
    } else {
      recommendations['focus'] = 'mastery';
      recommendations['suggestion'] = _l10n?.adapSuggestionAdvancedTopics ?? 'Ready for advanced topics';
    }

    recommendations['timeToReview'] = calculateReviewInterval(
      correctCount: progress.correctAnswers,
      incorrectCount: totalAttempts - progress.correctAnswers,
      averageConfidence: 3.0,
    ).toInt();

    return recommendations;
  }
}
