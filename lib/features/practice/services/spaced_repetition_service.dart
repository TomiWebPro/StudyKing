import 'dart:convert';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/errors/spaced_repetition_error_codes.dart';
import 'package:studyking/core/utils/logger.dart';

/// Tolerance window used for strict "due" checks (not for session selection).
/// Questions whose [Question.nextReview] falls within this window before
/// the review cutoff are considered "due" for badge counting but may be
/// excluded from session loading to avoid edge-case thrashing.
/// Set to [Duration.zero] for exact matching.
Duration dueWindowTolerance = Timeouts.hour;

/// Service layer for spaced repetition logic.
/// Uses [SpacedRepetitionEngine] (proper SM-2) for all interval calculations.
class SpacedRepetitionService {
  static final Logger _logger = const Logger('SpacedRepetitionService');
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

  /// Get questions due for review based on next_review date.
  /// Uses the global [dueWindowTolerance] as the cutoff precision.
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async {
    try {
      final reviewDate = asOf ?? DateTime.now();
      final cutover = reviewDate.subtract(dueWindowTolerance);
      final all = _questionRepo.box.values.toList();
      all.sort((a, b) =>
          (a.nextReview ?? DateTime.now())
              .compareTo(b.nextReview ?? DateTime.now()));
      final due = all
          .where((q) => (q.nextReview ?? DateTime.now()).isBefore(cutover))
          .toList();
      return Result.success(due);
    } catch (e) {
      _logger.w('getQuestionsDueForReview failed', e);
      return Result.failure(e.toString());
    }
  }

  /// Check if a question is due for review
  Future<Result<bool>> isQuestionDueForReview(Question question, {DateTime? asOf}) async {
    try {
      final reviewDate = asOf ?? DateTime.now();
      final dueWindow = reviewDate.subtract(Timeouts.fiveMinutes);
      final isDue = (question.nextReview ?? DateTime.now()).isBefore(dueWindow);
      return Result.success(isDue);
    } catch (e) {
      _logger.w('isQuestionDueForReview failed', e);
      return Result.failure(e.toString());
    }
  }

  /// Get questions due for review with proper error handling
  Future<Result<List<Question>>> getQuestionsDue({DateTime? asOf}) async {
    try {
      if (!_questionRepo.box.isOpen) {
        return Result.failure(SpacedRepetitionErrorCode.boxClosed.name);
      }
      final dueQuestionsResult = await getQuestionsDueForReview(asOf: asOf);
      final dueQuestions = dueQuestionsResult.data ?? [];
      return Result.success(dueQuestions);
    } catch (e) {
      _logger.w('Error getting due questions', e);
      return Result.failure(e.toString());
    }
  }

  /// Update next_review date for a question using SM-2 engine.
  /// Maps masteryLevel (0.0–1.0) to an SM-2 grade and delegates to
  /// [SpacedRepetitionEngine.scheduleReview] for proper interval calculation.
  /// Stores serialized SM-2 state on the [Question] for progressive tracking.
  ///
  /// Prefer calling [MasteryRecorder.recordAttempt] instead, which preserves
  /// the user's full confidence rating through [SpacedRepetitionEngine.mapConfidenceToGrade].
  /// This method uses a simplified masteryLevel → grade mapping that discards
  /// nuanced confidence data.
  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    try {
      final questionResult = await _questionRepo.get(questionId);
      final question = questionResult.data;
      if (question == null) {
        return Result.failure(SpacedRepetitionErrorCode.notFound.name);
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
      _logger.w('Error updating next review date', e);
      return Result.failure(e.toString());
    }
  }

  /// Deprecated: binary masteryLevel (0.8/0.2) loses confidence nuance.
  /// Use [SpacedRepetitionEngine.mapConfidenceToGrade] via [MasteryRecorder] instead.
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
    } catch (e) {
      _logger.w('Error deserializing SR data', e);
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
      final attemptResult = await _attemptRepo.get(questionId);
      final attempt = attemptResult.data;
      if (attempt == null) {
        return Result.failure(SpacedRepetitionErrorCode.notFound.name);
      }

      final timestamps = attempt.lastDueDate != null
          ? [attempt.lastDueDate!]
          : <DateTime>[];

      return Result.success(timestamps);
    } catch (e) {
      _logger.w('Error getting question due times', e);
      return Result.failure(e.toString());
    }
  }

  /// Get all practice questions for a subject
  Future<Result<List<Question>>> getPracticeQuestions(
      String subjectId) async {
    try {
      if (!_questionRepo.box.isOpen) {
        return Result.failure(SpacedRepetitionErrorCode.boxClosed.name);
      }

      final all = _questionRepo.box.values.toList();
      final practiceQuestions = all.where((q) =>
          (q.nextReview ?? DateTime.now()).isBefore(DateTime.now()) &&
          q.subjectId == subjectId);

      return Result.success(practiceQuestions.toList());
    } catch (e) {
      _logger.w('Error getting practice questions', e);
      return Result.failure(e.toString());
    }
  }

  /// Get topic questions due for tracking
  Future<Result<List<Question>>> getTopicTimeDue(String topicId) async {
    try {
      if (!_questionRepo.box.isOpen) {
        return Result.failure(SpacedRepetitionErrorCode.boxClosed.name);
      }

      final all = _questionRepo.box.values.toList();
      final topicQuestions = all.where((q) => q.topicId == topicId);

      return Result.success(topicQuestions.toList());
    } catch (e) {
      _logger.w('Error getting topic time due questions', e);
      return Result.failure(e.toString());
    }
  }

  /// Remove questions that are due for review (after completion)
  Future<Result<void>> removeDueQuestions(String questionId) async {
    try {
      await _questionRepo.delete(questionId);
      return Result.success(null);
    } catch (e) {
      _logger.w('Error removing question', e);
      return Result.failure(e.toString());
    }
  }

  /// Get subject due count
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    try {
      if (!_questionRepo.box.isOpen) {
        return Result.failure(SpacedRepetitionErrorCode.boxClosed.name);
      }

      final all = _questionRepo.box.values.toList();
      final dueCount = all
          .where((q) =>
              q.subjectId == subjectId &&
              (q.nextReview ?? DateTime.now()).isBefore(DateTime.now()))
          .length;

      return Result.success(dueCount);
    } catch (e) {
      _logger.w('Error getting subject due count', e);
      return Result.failure(e.toString());
    }
  }
}
