import 'dart:convert';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/services/llm_answer_evaluator.dart';

class RichAttemptOutcome {
  final bool isCorrect;
  final bool needsManualReview;
  final double? score;
  final String? feedback;

  const RichAttemptOutcome({
    required this.isCorrect,
    required this.needsManualReview,
    this.score,
    this.feedback,
  });
}

class MasteryRecorder {
  static final Logger _logger = const Logger('MasteryRecorder');
  final MasteryGraphService _masteryGraphService;
  final SpacedRepetitionEngine _srEngine;
  final AttemptRepository _attemptRepo;
  final QuestionMasteryStateRepository _questionMasteryRepo;
  final QuestionRepository _questionRepo;
  final LlmAnswerEvaluator? _evaluator;

  MasteryRecorder({
    required MasteryGraphService masteryGraphService,
    required SpacedRepetitionEngine srEngine,
    required AttemptRepository attemptRepo,
    required QuestionMasteryStateRepository questionMasteryRepo,
    required QuestionRepository questionRepo,
    LlmAnswerEvaluator? evaluator,
  })  : _masteryGraphService = masteryGraphService,
        _srEngine = srEngine,
        _attemptRepo = attemptRepo,
        _questionMasteryRepo = questionMasteryRepo,
        _questionRepo = questionRepo,
        _evaluator = evaluator;

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
    return _persistAttempt(
      studentId: studentId,
      questionId: questionId,
      subjectId: subjectId,
      topicId: topicId,
      isCorrect: isCorrect,
      timeSpentMs: timeSpentMs,
      confidence: confidence,
      userAnswer: userAnswer,
      timestamp: timestamp,
    );
  }

  /// Records an attempt for a rich question type (graph drawing, file upload,
  /// audio recording). The answer is graded by the injected [LlmAnswerEvaluator]
  /// when available. When the evaluator is unavailable or returns a low-confidence
  /// result, the attempt is flagged for manual review rather than silently graded
  /// correct. Returns a [RichAttemptOutcome] describing the result.
  Future<Result<RichAttemptOutcome>> recordRichAttempt({
    required String studentId,
    required Question question,
    required String userAnswer,
    required int timeSpentMs,
    required int confidence,
    DateTime? timestamp,
  }) async {
    final type = question.type;
    if (!_isRichType(type)) {
      return Result.failure('recordRichAttempt called for non-rich type: ${type.name}');
    }

    EvaluationResult evaluation;
    if (_evaluator != null) {
      final evalResult = await _evaluateRich(type, userAnswer, question.markscheme);
      if (evalResult.isSuccess) {
        evaluation = evalResult.data!;
      } else {
        _logger.w('Rich evaluation unavailable; flagging manual review', evalResult.error);
        evaluation = EvaluationResult(
          isCorrect: false,
          score: 0.0,
          feedback: 'Evaluation unavailable; flagged for manual review.',
          needsManualReview: true,
        );
      }
    } else {
      _logger.w('No evaluator configured; rich answer flagged for manual review');
      evaluation = EvaluationResult(
        isCorrect: false,
        score: 0.0,
        feedback: 'No automated evaluation available; flagged for manual review.',
        needsManualReview: true,
      );
    }

    final recordResult = await _persistAttempt(
      studentId: studentId,
      questionId: question.id,
      subjectId: question.subjectId,
      topicId: question.topicId,
      isCorrect: evaluation.isCorrect,
      timeSpentMs: timeSpentMs,
      confidence: confidence,
      userAnswer: userAnswer,
      timestamp: timestamp,
    );
    if (recordResult.isFailure) {
      return Result.failure(recordResult.error);
    }

    return Result.success(RichAttemptOutcome(
      isCorrect: evaluation.isCorrect,
      needsManualReview: evaluation.needsManualReview,
      score: evaluation.score,
      feedback: evaluation.feedback,
    ));
  }

  bool _isRichType(QuestionType type) =>
      type == QuestionType.graphDrawing ||
      type == QuestionType.fileUpload ||
      type == QuestionType.audioRecording;

  Future<Result<EvaluationResult>> _evaluateRich(
    QuestionType type,
    String userAnswer,
    Markscheme? markscheme,
  ) {
    switch (type) {
      case QuestionType.graphDrawing:
        return _evaluator!.evaluateGraphDrawing(userAnswer, markscheme);
      case QuestionType.fileUpload:
        return _evaluator!.evaluateFileUpload(userAnswer, markscheme);
      case QuestionType.audioRecording:
        return _evaluator!.evaluateAudioRecording(userAnswer, markscheme);
      default:
        return Future.value(Result<EvaluationResult>.failure('Not a rich question type'));
    }
  }

  Future<Result<void>> _persistAttempt({
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
      _logger.w('MasteryRecorder.recordAttempt failed', e);
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
      _logger.w('Failed to deserialize SR data', e);
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
