import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';

/// Result of evaluating a rich answer (graph drawing, file upload, audio).
class EvaluationResult {
  final bool isCorrect;
  final double score;
  final String feedback;
  final bool needsManualReview;

  const EvaluationResult({
    required this.isCorrect,
    required this.score,
    required this.feedback,
    this.needsManualReview = false,
  });
}

/// Structured evaluation returned by a multimodal LLM.
class LlmEvaluation {
  final bool isCorrect;
  final double score;
  final String feedback;
  final double confidence;

  const LlmEvaluation({
    required this.isCorrect,
    required this.score,
    required this.feedback,
    required this.confidence,
  });
}

/// Abstraction over a multimodal LLM capable of grading media (images/files).
abstract class MultimodalLlmClient {
  Future<Result<LlmEvaluation>> evaluate({
    required String prompt,
    required String mediaBase64,
    required String mediaType,
  });
}

/// Abstraction over an audio transcription service.
abstract class TranscriptionService {
  Future<Result<String>> transcribe(String audioData);
}

/// Default client used when no real LLM integration is wired up. It reports
/// failure so the evaluator can gracefully flag the answer for manual review
/// instead of silently auto-grading.
class UnavailableMultimodalLlmClient extends MultimodalLlmClient {
  @override
  Future<Result<LlmEvaluation>> evaluate({
    required String prompt,
    required String mediaBase64,
    required String mediaType,
  }) async {
    return Result.failure('Multimodal LLM client is not configured');
  }
}

/// Default transcription service used when none is wired up.
class UnavailableTranscriptionService extends TranscriptionService {
  @override
  Future<Result<String>> transcribe(String audioData) async {
    return Result.failure('Transcription service is not configured');
  }
}

/// Evaluates rich question types (graph drawing, file upload, audio recording)
/// using an injectable multimodal LLM client and transcription service.
///
/// When the underlying client is unavailable or returns a low-confidence result,
/// the evaluator flags the answer for manual review rather than silently marking
/// it correct. All public methods return [Result] and never throw.
class LlmAnswerEvaluator {
  static final Logger _logger = const Logger('LlmAnswerEvaluator');

  final MultimodalLlmClient _llmClient;
  final TranscriptionService _transcriptionService;
  final ValidationMessagesForEvaluator _messages;
  final double lowConfidenceThreshold;

  LlmAnswerEvaluator({
    required MultimodalLlmClient llmClient,
    required TranscriptionService transcriptionService,
    required ValidationMessagesForEvaluator messages,
    this.lowConfidenceThreshold = 0.5,
  })  : _llmClient = llmClient,
        _transcriptionService = transcriptionService,
        _messages = messages;

  Future<Result<EvaluationResult>> evaluateGraphDrawing(
    String drawingBase64,
    Markscheme? markscheme,
  ) async {
    if (drawingBase64.trim().isEmpty) {
      return Result.success(EvaluationResult(
        isCorrect: false,
        score: 0.0,
        feedback: _messages.noDrawingDetected,
      ));
    }

    final prompt = _buildPrompt('hand-drawn graph', markscheme);
    final llmResult = await _llmClient.evaluate(
      prompt: prompt,
      mediaBase64: drawingBase64,
      mediaType: 'image/png',
    );

    if (llmResult.isFailure) {
      _logger.w('Graph drawing LLM evaluation failed; flagging manual review', llmResult.error);
      return Result.success(_manualReview(_messages.specialHandlingRequired));
    }

    return Result.success(_fromLlm(llmResult.data!));
  }

  Future<Result<EvaluationResult>> evaluateFileUpload(
    String fileData,
    Markscheme? markscheme,
  ) async {
    if (fileData.trim().isEmpty) {
      return Result.success(EvaluationResult(
        isCorrect: false,
        score: 0.0,
        feedback: _messages.pleaseProvideAnswer,
      ));
    }

    final prompt = _buildPrompt('uploaded file', markscheme);
    final llmResult = await _llmClient.evaluate(
      prompt: prompt,
      mediaBase64: fileData,
      mediaType: _inferMediaType(fileData),
    );

    if (llmResult.isFailure) {
      _logger.w('File upload LLM evaluation failed; flagging manual review', llmResult.error);
      return Result.success(_manualReview(_messages.specialHandlingRequired));
    }

    return Result.success(_fromLlm(llmResult.data!));
  }

  Future<Result<EvaluationResult>> evaluateAudioRecording(
    String audioData,
    Markscheme? markscheme,
  ) async {
    if (audioData.trim().isEmpty) {
      return Result.success(EvaluationResult(
        isCorrect: false,
        score: 0.0,
        feedback: _messages.pleaseProvideAnswer,
      ));
    }

    final transcriptResult = await _transcriptionService.transcribe(audioData);
    if (transcriptResult.isFailure) {
      _logger.w('Audio transcription failed; flagging manual review', transcriptResult.error);
      return Result.success(_manualReview(_messages.specialHandlingRequired));
    }

    final transcript = transcriptResult.data!;
    if (markscheme == null) {
      _logger.w('Audio evaluation has no markscheme; flagging manual review');
      return Result.success(_manualReview(_messages.markschemeUnavailable));
    }

    final isMatch = _isTypedMatch(transcript, markscheme);
    return Result.success(EvaluationResult(
      isCorrect: isMatch,
      score: isMatch ? 1.0 : 0.0,
      feedback: isMatch ? _messages.correct : _messages.incorrect,
    ));
  }

  EvaluationResult _fromLlm(LlmEvaluation ev) {
    final needsReview = ev.confidence < lowConfidenceThreshold;
    return EvaluationResult(
      isCorrect: ev.isCorrect,
      score: ev.score,
      feedback: ev.feedback,
      needsManualReview: needsReview,
    );
  }

  EvaluationResult _manualReview(String feedback) {
    return EvaluationResult(
      isCorrect: false,
      score: 0.0,
      feedback: feedback,
      needsManualReview: true,
    );
  }

  bool _isTypedMatch(String userAnswer, Markscheme markscheme) {
    if (markscheme.correctAnswer.trim().isEmpty) return false;
    if (userAnswer.normalized == markscheme.correctAnswer.normalized) return true;
    for (final acceptable in markscheme.acceptableAnswers) {
      if (userAnswer.normalized == acceptable.normalized) return true;
    }
    return false;
  }

  String _buildPrompt(String kind, Markscheme? markscheme) {
    final buffer = StringBuffer();
    buffer.writeln('You are grading a student\'s $kind for a practice question.');
    if (markscheme != null) {
      buffer.writeln('Expected / correct answer: ${markscheme.correctAnswer}');
      if (markscheme.acceptableAnswers.isNotEmpty) {
        buffer.writeln('Acceptable answers: ${markscheme.acceptableAnswers.join(', ')}');
      }
      if (markscheme.explanation != null && markscheme.explanation!.isNotEmpty) {
        buffer.writeln('Grading criteria: ${markscheme.explanation}');
      }
    }
    buffer.writeln('Decide whether the student response is correct, assign a score '
        'between 0 and 1, and report your confidence between 0 and 1.');
    return buffer.toString();
  }

  String _inferMediaType(String fileData) {
    final lower = fileData.toLowerCase();
    if (lower.contains('pdf') || lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.contains('doc') || lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.contains('png') || lower.endsWith('.png')) return 'image/png';
    if (lower.contains('jpeg') || lower.contains('jpg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}

/// Minimal set of messages the evaluator needs. Kept separate from
/// [ValidationMessages] to avoid a circular dependency with
/// `answer_validation_service.dart`.
class ValidationMessagesForEvaluator {
  final String noDrawingDetected;
  final String pleaseProvideAnswer;
  final String specialHandlingRequired;
  final String markschemeUnavailable;
  final String correct;
  final String incorrect;

  const ValidationMessagesForEvaluator({
    this.noDrawingDetected = 'No drawing detected. Please draw something.',
    this.pleaseProvideAnswer = 'Please provide an answer',
    this.specialHandlingRequired = 'This question type requires special handling.',
    this.markschemeUnavailable = 'No markscheme available',
    this.correct = 'Correct!',
    this.incorrect = 'Incorrect.',
  });

  static const ValidationMessagesForEvaluator english = ValidationMessagesForEvaluator();
}
