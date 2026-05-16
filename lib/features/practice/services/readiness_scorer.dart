import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';

class ScoredQuestion {
  final Question question;
  final double score;
  final MasteryState? topicMastery;
  final QuestionMasteryState? questionMastery;

  ScoredQuestion({
    required this.question,
    required this.score,
    this.topicMastery,
    this.questionMastery,
  });
}

class ReadinessScorer {
  final Map<String, MasteryState> _topicMasteryMap;
  final Map<String, QuestionMasteryState> _questionMasteryMap;

  static const double urgencyWeight = 0.4;
  static const double readinessInverseWeight = 0.3;
  static const double daysSinceLastAttemptWeight = 0.2;
  static const double confidenceGapWeight = 0.1;

  ReadinessScorer({
    Map<String, MasteryState>? topicMasteryMap,
    Map<String, QuestionMasteryState>? questionMasteryMap,
  })  : _topicMasteryMap = topicMasteryMap ?? {},
        _questionMasteryMap = questionMasteryMap ?? {};

  List<ScoredQuestion> scoreQuestions(List<Question> questions) {
    if (questions.isEmpty) return [];

    final scored = questions.map((q) {
      final topicMastery = _topicMasteryMap[q.topicId];
      final questionMastery = _questionMasteryMap[q.id];

      final score = _computeScore(
        question: q,
        topicMastery: topicMastery,
        questionMastery: questionMastery,
      );

      return ScoredQuestion(
        question: q,
        score: score,
        topicMastery: topicMastery,
        questionMastery: questionMastery,
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  double _computeScore({
    required Question question,
    MasteryState? topicMastery,
    QuestionMasteryState? questionMastery,
  }) {
    final now = DateTime.now();
    double score = 0.0;

    if (topicMastery != null) {
      score += topicMastery.reviewUrgency * urgencyWeight;
      score += (1.0 - topicMastery.readinessScore) * readinessInverseWeight;
    } else {
      score += 0.8 * urgencyWeight;
      score += 0.5 * readinessInverseWeight;
    }

    if (questionMastery != null) {
      final daysSinceLastAttempt =
          now.difference(questionMastery.lastAttempt).inDays.toDouble();
      final daysNorm = (daysSinceLastAttempt / 30.0).clamp(0.0, 1.0);
      score += daysNorm * daysSinceLastAttemptWeight;

      if (questionMastery.confidenceHistory.isNotEmpty) {
        final avgConfidence = questionMastery.confidenceHistory
                .reduce((a, b) => a + b) /
            questionMastery.confidenceHistory.length;
        final confidenceGap = (5.0 - avgConfidence) / 5.0;
        score += confidenceGap * confidenceGapWeight;
      } else {
        score += 0.5 * confidenceGapWeight;
      }
    } else {
      score += 0.7 * daysSinceLastAttemptWeight;
      score += 0.5 * confidenceGapWeight;
    }

    final difficultyNorm = (question.difficulty - 1) / 4.0;
    score += difficultyNorm * 0.05;

    return score.clamp(0.0, 1.0);
  }
}
