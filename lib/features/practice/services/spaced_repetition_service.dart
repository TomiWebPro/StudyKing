import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Static utility queries for spaced repetition.
/// These operate on a [Box<Question>] directly for testability.
class SpacedRepetitionQueries {
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

  static List<Question> getQuestionsDueAfter(
      Box<Question> box, DateTime asOf) {
    final cutover = asOf.subtract(const Duration(minutes: 30));
    return box.values
        .where((q) => (q.nextReview ?? DateTime.now()).isBefore(cutover))
        .toList();
  }

  static bool isQuestionDueForReview(Question question, {DateTime? asOf}) {
    final reviewDate = asOf ?? DateTime.now();
    final dueWindow = reviewDate.subtract(const Duration(minutes: 5));
    return (question.nextReview ?? DateTime.now()).isBefore(dueWindow);
  }

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

/// Service layer for spaced repetition logic.
/// Uses [SpacedRepetitionEngine] (proper SM-2) for all interval calculations.
class SpacedRepetitionService {
  final Logger _logger = const Logger('SpacedRepetitionService');
  final QuestionRepository _questionRepo;
  final AttemptRepository _attemptRepo;
  final SpacedRepetitionEngine _srEngine;

  SpacedRepetitionService({
    required QuestionRepository questionRepo,
    required AttemptRepository attemptRepo,
    SpacedRepetitionEngine? srEngine,
  })  : _questionRepo = questionRepo,
        _attemptRepo = attemptRepo,
        _srEngine = srEngine ?? SpacedRepetitionEngine();

  /// Get questions due for review based on next_review date
  List<Question> getQuestionsDueForReview({DateTime? asOf}) {
    final reviewDate = asOf ?? DateTime.now();
    final cutover = reviewDate.subtract(const Duration(hours: 1));
    final all = _questionRepo.box.values.toList();
    all.sort((a, b) =>
        (a.nextReview ?? DateTime.now())
            .compareTo(b.nextReview ?? DateTime.now()));
    return all
        .where((q) => (q.nextReview ?? DateTime.now()).isBefore(cutover))
        .toList();
  }

  /// Check if a question is due for review
  bool isQuestionDueForReview(Question question, {DateTime? asOf}) {
    final reviewDate = asOf ?? DateTime.now();
    final dueWindow = reviewDate.subtract(const Duration(minutes: 5));
    return (question.nextReview ?? DateTime.now()).isBefore(dueWindow);
  }

  /// Get questions due for review with proper error handling
  Future<Result<List<Question>>> getQuestionsDue({DateTime? asOf}) async {
    try {
      if (!_questionRepo.box.isOpen) {
        return Result.failure('Question box is not open');
      }
      final dueQuestions = getQuestionsDueForReview(asOf: asOf);
      return Result.success(dueQuestions);
    } catch (e) {
      _logger.e('Error getting due questions', e);
      return Result.failure('Failed to get due questions: ${e.toString()}');
    }
  }

  /// Update next_review date for a question using SM-2 engine.
  /// Maps masteryLevel (0.0–1.0) to an SM-2 grade and delegates to
  /// [SpacedRepetitionEngine.scheduleReview] for proper interval calculation.
  /// Stores serialized SM-2 state on the [Question] for progressive tracking.
  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    try {
      final question = await _questionRepo.get(questionId);
      if (question == null) {
        return Result.failure('Question not found: $questionId');
      }

      final grade = _masteryLevelToGrade(masteryLevel);
      final srData = _deserializeSrData(question.srDataJson);

      final srResult = _srEngine.scheduleReview(
        questionId: questionId,
        grade: grade,
        currentData: srData,
      );

      final updated = question.copyWith(
        nextReview: srResult.nextReview,
        srDataJson: _serializeSrData(srResult.updatedData),
      );
      await _questionRepo.save(questionId, updated);

      return Result.success(null);
    } catch (e) {
      _logger.e('Error updating next review date', e);
      return Result.failure(
          'Failed to update next review date: ${e.toString()}');
    }
  }

  int _masteryLevelToGrade(double masteryLevel) {
    if (masteryLevel >= 0.9) return 5;
    if (masteryLevel >= 0.7) return 4;
    if (masteryLevel >= 0.5) return 3;
    if (masteryLevel >= 0.3) return 2;
    return 1;
  }

  QuestionSRData _deserializeSrData(String? json) {
    if (json == null || json.isEmpty) return const QuestionSRData();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return QuestionSRData(
        repetitions: map['r'] as int? ?? 0,
        easeFactor: (map['ef'] as num?)?.toDouble() ?? 2.5,
        previousInterval: map['pi'] != null
            ? Duration(milliseconds: map['pi'] as int)
            : null,
        lastReview: map['lr'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lr'] as int)
            : null,
      );
    } catch (_) {
      return const QuestionSRData();
    }
  }

  String _serializeSrData(QuestionSRData data) {
    return jsonEncode({
      'r': data.repetitions,
      'ef': data.easeFactor,
      if (data.previousInterval != null) 'pi': data.previousInterval!.inMilliseconds,
      if (data.lastReview != null) 'lr': data.lastReview!.millisecondsSinceEpoch,
    });
  }

  /// Get question due history
  Future<Result<List<DateTime>>> getQuestionDueTimes(
      String questionId) async {
    try {
      final attempt = await _attemptRepo.get(questionId);
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
      if (!_questionRepo.box.isOpen) {
        return Result.failure('Question box is not open');
      }

      final all = _questionRepo.box.values.toList();
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

  /// Get topic questions due for tracking
  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async {
    try {
      if (!_questionRepo.box.isOpen) {
        return Result.failure('Question box is not open');
      }

      final all = _questionRepo.box.values.toList();
      final topicQuestions = all.where((q) => q.topicId == topicId);

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
      await _questionRepo.delete(questionId);
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
      if (!_questionRepo.box.isOpen) {
        return Result.failure('Question box is not open');
      }

      final all = _questionRepo.box.values.toList();
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
