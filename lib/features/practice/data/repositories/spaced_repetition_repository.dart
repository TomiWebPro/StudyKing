import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Spaced repetition queries for studyKing
class SpacedRepetitionQueries {
  /// Get questions due for review based on next_review date
  static List<Question> getQuestionsDueForReview(Box<Question> box,
      {DateTime? asOf}) {
    final reviewDate = asOf ?? DateTime.now();
    final cutover = reviewDate.subtract(const Duration(hours: 1));
    final all = box.values.toList();
    all.sort((a, b) =>
        (a.nextReview ?? DateTime.now())
            .compareTo(b.nextReview ?? DateTime.now()));
    return all
        .where((q) => (q.nextReview ?? DateTime.now()).isBefore(cutover))
        .toList();
  }

  /// Get questions due after specific threshold
  static List<Question> getQuestionsDueAfter(
      Box<Question> box, DateTime asOf) {
    final cutover = asOf.subtract(const Duration(minutes: 30));
    return box.values
        .where((q) => (q.nextReview ?? DateTime.now()).isBefore(cutover))
        .toList();
  }

  /// Check if a question is due for review
  static bool isQuestionDueForReview(Question question, {DateTime? asOf}) {
    final reviewDate = asOf ?? DateTime.now();
    final dueWindow = reviewDate.subtract(const Duration(minutes: 5));
    return (question.nextReview ?? DateTime.now()).isBefore(dueWindow);
  }

  /// Get questions with their due status
  static Map<String, String> mapQuestionsToStatus(Box<Question> box,
      {DateTime? asOf}) {
    final reviewDate = asOf ?? DateTime.now();
    final cutover = reviewDate.subtract(const Duration(hours: 1));
    return {
      for (final q in box.values)
        q.id:
            (q.nextReview ?? DateTime.now()).isBefore(cutover)
                ? 'due'
                : 'not-due',
    };
  }
}

/// Spaced repetition repository for studyKing
class SpacedRepetitionRepository extends Repository<Question> {
  final Logger _logger = const Logger('SpacedRepetitionRepository');
  late Box<StudentAttempt> _attemptBox;

  Future<void> init() async {
    try {
      await openBox(HiveBoxNames.questions);
      _attemptBox = await Hive.openBox<StudentAttempt>(HiveBoxNames.attempts);
    } catch (e) {
      _logger.e('Error initializing spaced repetition repository', e);
      rethrow;
    }
  }

  /// Get questions due for immediate review
  Future<Result<List<Question>>> getQuestionsDueForReview(
      {DateTime? asOf}) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question box is not open');
      }
      final dueQuestions =
          SpacedRepetitionQueries.getQuestionsDueForReview(box, asOf: asOf);
      return Result.success(dueQuestions);
    } catch (e) {
      _logger.e('Error getting due questions', e);
      return Result.failure('Failed to get due questions: ${e.toString()}');
    }
  }

  /// Update next_review date for a question based on practice result
  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    try {
      final question = await get(questionId);
      if (question == null) {
        return Result.failure('Question not found: $questionId');
      }

      double newInterval;
      if (masteryLevel >= 0.9) {
        newInterval = 7 * 24 * 60 * 60 * 1000; // 7 days
      } else if (masteryLevel >= 0.7) {
        newInterval = 3 * 24 * 60 * 60 * 1000; // 3 days
      } else if (masteryLevel >= 0.5) {
        newInterval = 1 * 24 * 60 * 60 * 1000; // 1 day
      } else if (masteryLevel >= 0.3) {
        newInterval = 12 * 60 * 60 * 1000; // 12 hours
      } else {
        newInterval = 30 * 60 * 1000; // 30 minutes
      }

      final newReviewDate =
          DateTime.now().add(Duration(milliseconds: newInterval.toInt()));
      final updated = question.copyWith(nextReview: newReviewDate);
      await save(questionId, updated);

      return Result.success(null);
    } catch (e) {
      _logger.e('Error updating next review date', e);
      return Result.failure(
          'Failed to update next review date: ${e.toString()}');
    }
  }

  /// Get question due history for a specific question
  Future<Result<List<DateTime>>> getQuestionDueTimes(
      String questionId) async {
    try {
      final attempt = _attemptBox.get(questionId);
      if (attempt == null) {
        return Result.failure(
            'No attempts found for question: $questionId');
      }

      final timestamps = attempt.lastDueDate != null
          ? [attempt.lastDueDate!]
          : <DateTime>[];

      return Result.success(timestamps);
    } catch (e) {
      _logger.e('Error getting question due times', e);
      return Result.failure(
          'Failed to get question due times: ${e.toString()}');
    }
  }

  /// Get all practice questions for a subject
  Future<Result<List<Question>>> getPracticeQuestions(
      String subjectId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question box is not open');
      }

      final all = box.values.toList();
      final practiceQuestions = all.where((q) =>
          (q.nextReview ?? DateTime.now()).isBefore(DateTime.now()) &&
          q.subjectId == subjectId);

      return Result.success(practiceQuestions.toList());
    } catch (e) {
      _logger.e('Error getting practice questions', e);
      return Result.failure(
          'Failed to get practice questions: ${e.toString()}');
    }
  }

  /// Get topic due times for tracking
  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question box is not open');
      }

      final all = box.values.toList();
      final topicQuestions =
          all.where((q) => q.topicId == topicId);

      return Result.success(topicQuestions.toList());
    } catch (e) {
      _logger.e('Error getting topic time due questions', e);
      return Result.failure(
          'Failed to get topic time due questions: ${e.toString()}');
    }
  }

  /// Remove questions that are due for review (after completion)
  Future<Result<void>> removeDueQuestions(String questionId) async {
    try {
      await delete(questionId);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error removing question', e);
      return Result.failure(
          'Failed to remove question: ${e.toString()}');
    }
  }

  /// Get subject due count
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    try {
      if (!box.isOpen) {
        return Result.failure('Question box is not open');
      }

      final all = box.values.toList();
      final dueCount = all
          .where((q) =>
              q.subjectId == subjectId &&
              (q.nextReview ?? DateTime.now()).isBefore(DateTime.now()))
          .length;

      return Result.success(dueCount);
    } catch (e) {
      _logger.e('Error getting subject due count', e);
      return Result.failure(
          'Failed to get subject due count: ${e.toString()}');
    }
  }
}
