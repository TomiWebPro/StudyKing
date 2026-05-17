import 'dart:convert';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class MasteryRecorder {
  final Logger _logger = const Logger('MasteryRecorder');
  final MasteryGraphService _masteryGraphService;
  final SpacedRepetitionEngine _srEngine;
  final AttemptRepository _attemptRepo;
  final QuestionMasteryStateRepository _questionMasteryRepo;
  final QuestionRepository _questionRepo;

  MasteryRecorder({
    required MasteryGraphService masteryGraphService,
    required SpacedRepetitionEngine srEngine,
    required AttemptRepository attemptRepo,
    required QuestionMasteryStateRepository questionMasteryRepo,
    required QuestionRepository questionRepo,
  })  : _masteryGraphService = masteryGraphService,
        _srEngine = srEngine,
        _attemptRepo = attemptRepo,
        _questionMasteryRepo = questionMasteryRepo,
        _questionRepo = questionRepo;

  Future<Result<void>> recordAttempt({
    required String studentId,
    required String questionId,
    required String subjectId,
    required String topicId,
    required bool isCorrect,
    required int timeSpentMs,
    required int confidence,
    required String userAnswer,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();

    try {
      final questionResult = await _questionRepo.get(questionId);
      final question = questionResult.data;
      if (question == null) {
        return Result.failure('Question_not_found: $questionId');
      }

      final grade = _srEngine.mapConfidenceToGrade(
        isCorrect: isCorrect,
        confidence: confidence,
      );
      final currentSrData = _deserializeSrData(question.srDataJson);
      final srResult = _srEngine.scheduleReview(
        questionId: questionId,
        grade: grade,
        currentData: currentSrData,
        now: now,
      );

      final attempt = StudentAttempt(
        id: '${questionId}_${now.millisecondsSinceEpoch}',
        studentId: studentId,
        questionId: questionId,
        subjectId: subjectId,
        isCorrect: isCorrect,
        timeSpentMs: timeSpentMs,
        confidence: confidence,
        timestamp: now,
        userAnswer: userAnswer,
      );
      await _attemptRepo.create(attempt);

      final masteryResult = await _masteryGraphService.recordAttempt(
        studentId: studentId,
        topicId: topicId,
        questionId: questionId,
        isCorrect: isCorrect,
        confidence: confidence,
        timeSpentMs: timeSpentMs,
      );
      if (masteryResult.isFailure) {
        _logger.w('MasteryGraphService.recordAttempt failed: ${masteryResult.error}');
      }

      final updatedQuestion = question.copyWith(
        nextReview: srResult.nextReview,
        srDataJson: _serializeSrData(srResult.updatedData),
      );
      await _questionRepo.save(questionId, updatedQuestion);

      final questionMasteryResult = await _questionMasteryRepo.getQuestionMasteryState(
        studentId,
        questionId,
      );
      if (questionMasteryResult.isSuccess && questionMasteryResult.data != null) {
        final updatedQM = questionMasteryResult.data!.recordAttempt(
          isCorrect: isCorrect,
          confidence: confidence,
          timeSpentMs: timeSpentMs,
          now: now,
          sm2NextReview: srResult.nextReview,
        );
        await _questionMasteryRepo.updateQuestionMasteryState(updatedQM);
      }

      return Result.success(null);
    } catch (e) {
      _logger.e('MasteryRecorder.recordAttempt failed', e);
      return Result.failure(e.toString());
    }
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
      _logger.e('Failed to deserialize SR data', e);
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
}
