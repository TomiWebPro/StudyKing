import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Input signals used to estimate how many lessons remain before a single
/// topic is considered mastered.
class RemainingLessonsTopicInput {
  final MasteryLevel masteryLevel;
  final double accuracy;
  final double reviewUrgency;
  final double forgettingRisk;
  final int weakSubtopics;
  final int dueQuestionCount;

  const RemainingLessonsTopicInput({
    required this.masteryLevel,
    this.accuracy = 0.0,
    this.reviewUrgency = 0.0,
    this.forgettingRisk = 0.0,
    this.weakSubtopics = 0,
    this.dueQuestionCount = 0,
  });

  factory RemainingLessonsTopicInput.fromMasteryState(
    MasteryState state, {
    int dueQuestionCount = 0,
  }) {
    return RemainingLessonsTopicInput(
      masteryLevel: state.masteryLevel,
      accuracy: state.accuracy,
      reviewUrgency: state.reviewUrgency,
      forgettingRisk: state.forgettingRisk,
      weakSubtopics: state.weakSubtopics.length,
      dueQuestionCount: dueQuestionCount,
    );
  }
}

/// Result of a remaining-lessons estimation for a topic or a whole subject.
class RemainingLessonsEstimate {
  /// Whole number of lessons still required to reach mastery.
  final int lessonsRemaining;

  /// How close the student already is to mastery, in the range 0.0..1.0.
  final double masteryProgress;

  const RemainingLessonsEstimate(this.lessonsRemaining, this.masteryProgress);

  @override
  bool operator ==(Object other) =>
      other is RemainingLessonsEstimate &&
      other.lessonsRemaining == lessonsRemaining &&
      other.masteryProgress == masteryProgress;

  @override
  int get hashCode => Object.hash(lessonsRemaining, masteryProgress);
}

/// Deterministic estimator for the relative number of lessons remaining until
/// a topic or subject reaches mastery.
///
/// The estimate is derived from three independent signal families:
///  1. current [MasteryLevel] (how many level transitions are still ahead),
///  2. spaced-repetition / weak signals (due questions, weak subtopics,
///     low accuracy, high review urgency, high forgetting risk),
///  3. syllabus coverage (topics that have no mastery record yet).
///
/// Because the formula is purely arithmetic over its inputs it is fully
/// deterministic: identical inputs always produce an identical estimate.
class MasteryRemainingLessonsEstimator {
  static final Logger _logger =
      const Logger('MasteryRemainingLessonsEstimator');

  /// Baseline lessons assumed for each mastery-level transition.
  static const int lessonsPerMasteryLevel = 4;

  /// Lessons added per weak subtopic that still needs consolidation.
  static const int lessonsPerWeakSubtopic = 1;

  /// Spaced-repetition questions that map onto one review lesson.
  static const int questionsPerLesson = 5;

  static const int correctiveLessonsForLowAccuracy = 2;
  static const int correctiveLessonsForHighReviewUrgency = 1;
  static const int correctiveLessonsForHighForgettingRisk = 1;

  /// Index of the fully-mastered level ([MasteryLevel.expert]).
  static const int maxMasteryIndex = 4;

  MasteryRemainingLessonsEstimator();

  /// Estimate the lessons remaining for a single topic.
  static Result<RemainingLessonsEstimate> estimateForTopic(
      RemainingLessonsTopicInput input) {
    try {
      final levelIndex = input.masteryLevel.index;
      if (levelIndex < 0 || levelIndex > maxMasteryIndex) {
        return Result.failure(
          'MasteryRemainingLessonsEstimator.estimateForTopic: '
          'invalid mastery level index $levelIndex',
        );
      }

      final remainingLevels =
          (maxMasteryIndex - levelIndex).clamp(0, maxMasteryIndex);
      final baseLessons = remainingLevels * lessonsPerMasteryLevel;

      final weakLessons =
          (input.weakSubtopics < 0 ? 0 : input.weakSubtopics) *
              lessonsPerWeakSubtopic;
      final dueLessons = _safeLessonsFromQuestions(input.dueQuestionCount);
      final lowAccuracyLessons = (input.accuracy > 0.0 && input.accuracy < 0.6)
          ? correctiveLessonsForLowAccuracy
          : 0;
      final reviewLessons = input.reviewUrgency > 0.7
          ? correctiveLessonsForHighReviewUrgency
          : 0;
      final forgettingLessons = input.forgettingRisk > 0.7
          ? correctiveLessonsForHighForgettingRisk
          : 0;

      final corrective = weakLessons +
          dueLessons +
          lowAccuracyLessons +
          reviewLessons +
          forgettingLessons;

      // An already-mastered topic only needs corrective (review) lessons;
      // everything below expert needs the full level progression plus any
      // corrective lessons identified above.
      final lessonsRemaining = levelIndex >= maxMasteryIndex
          ? corrective
          : baseLessons + corrective;

      final progress = _computeProgress(levelIndex, input.accuracy);

      return Result.success(
        RemainingLessonsEstimate(lessonsRemaining, progress),
      );
    } catch (e) {
      _logger.w('Failed to estimate topic remaining lessons', e);
      return Result.failure(
        'MasteryRemainingLessonsEstimator.estimateForTopic: $e',
      );
    }
  }

  /// Estimate the lessons remaining across a whole subject.
  ///
  /// [syllabusTopicCount] lets the estimator account for syllabus coverage:
  /// topics that have no mastery record yet are counted as uncovered and
  /// assumed to start from [MasteryLevel.novice].
  static Result<RemainingLessonsEstimate> estimateForSubject(
    List<RemainingLessonsTopicInput> topics, {
    int syllabusTopicCount = 0,
  }) {
    try {
      var total = 0;
      var progressSum = 0.0;

      for (final topic in topics) {
        final result = estimateForTopic(topic);
        if (result.isFailure) return Result.failure(result.error);
        total += result.data!.lessonsRemaining;
        progressSum += result.data!.masteryProgress;
      }

      final covered = topics.length;
      final uncovered =
          (syllabusTopicCount - covered).clamp(0, 1 << 30);
      // Each uncovered topic starts at novice, so it needs the full climb.
      total += uncovered * (maxMasteryIndex * lessonsPerMasteryLevel);

      final progressDenominator =
          syllabusTopicCount > 0 ? syllabusTopicCount : covered;
      final avgProgress = progressDenominator > 0
          ? (progressSum / progressDenominator).clamp(0.0, 1.0)
          : (covered == 0 ? 0.0 : 1.0);

      return Result.success(RemainingLessonsEstimate(total, avgProgress));
    } catch (e) {
      _logger.w('Failed to estimate subject remaining lessons', e);
      return Result.failure(
        'MasteryRemainingLessonsEstimator.estimateForSubject: $e',
      );
    }
  }

  static int _safeLessonsFromQuestions(int count) {
    if (count <= 0) return 0;
    return (count / questionsPerLesson).ceil();
  }

  static double _computeProgress(int levelIndex, double accuracy) {
    final safeAccuracy = accuracy.clamp(0.0, 1.0);
    // Blend the discrete level with within-level accuracy so progress is
    // smooth rather than jumping only at level thresholds.
    final raw = (levelIndex + safeAccuracy) / (maxMasteryIndex + 1);
    return raw.clamp(0.0, 1.0);
  }
}
