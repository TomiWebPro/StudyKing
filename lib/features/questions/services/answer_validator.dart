import 'package:studyking/core/services/answer_validation_service.dart' as core;
import '../../../core/data/enums.dart';
import '../../../core/data/models/markscheme_model.dart';

class ValidationResult {
  final bool isCorrect;
  final String explanation;
  final double? score;
  final String? feedback;

  ValidationResult({
    required this.isCorrect,
    required this.explanation,
    this.score,
    this.feedback,
  });
}

class QuestionAnswerValidator {
  final Markscheme? _markscheme;

  QuestionAnswerValidator(this._markscheme);

  ValidationResult validate(String answer, QuestionType questionType) {
    final result = core.QuestionAnswerValidator.validateStatic(answer, questionType, _markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }
}

class AnswerValidationService {
  static const int _maxCacheSize = 100;
  static final Map<String, QuestionAnswerValidator> _cache = <String, QuestionAnswerValidator>{};
  static final Map<String, String> _cacheSignatures = <String, String>{};

  String _signatureFor(Markscheme markscheme) {
    return '${markscheme.correctAnswer}::${markscheme.acceptableAnswers.join('|')}::${markscheme.explanation}';
  }

  QuestionAnswerValidator _getValidator(String questionId, Markscheme markscheme) {
    final signature = _signatureFor(markscheme);
    final cachedSignature = _cacheSignatures[questionId];

    if (cachedSignature == signature && _cache.containsKey(questionId)) {
      return _cache[questionId]!;
    }

    final validator = QuestionAnswerValidator(markscheme);
    _cache[questionId] = validator;
    _cacheSignatures[questionId] = signature;
    _evictIfNeeded();
    return validator;
  }

  static void _evictIfNeeded() {
    while (_cache.length > _maxCacheSize) {
      final eldestKey = _cache.keys.first;
      _cache.remove(eldestKey);
      _cacheSignatures.remove(eldestKey);
    }
  }

  static void clearCache() {
    _cache.clear();
    _cacheSignatures.clear();
  }

  ValidationResult validateAnswer(String answer, QuestionType questionType, String questionId, Markscheme markscheme) {
    final validator = _getValidator(questionId, markscheme);
    return validator.validate(answer, questionType);
  }

  ValidationResult validateWithMarkschemeInstance(String answer, QuestionType questionType, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateStatic(answer, questionType, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }

  static ValidationResult validateWithMarkscheme(String answer, QuestionType questionType, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateStatic(answer, questionType, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }

  static ValidationResult validateTypedAnswerWithMarkscheme(String userAnswer, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateTypedAnswer(userAnswer, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }

  static ValidationResult validateMCQAnswerWithMarkscheme(String userAnswer, QuestionType type, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateMCQAnswer(userAnswer, type, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }

  static ValidationResult validateMathExpressionWithMarkscheme(String userAnswer, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateMathExpression(userAnswer, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }

  static ValidationResult validateEssayAnswerWithMarkscheme(String userAnswer, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateEssayAnswer(userAnswer, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }

  static ValidationResult validateCanvasDrawingWithMarkscheme(List<Map<String, dynamic>> canvasData, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateCanvasDrawing(canvasData, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }

  static ValidationResult validateStepByStepWithMarkscheme(String answer, Markscheme? markscheme) {
    final result = core.QuestionAnswerValidator.validateStepByStep(answer, markscheme);
    return ValidationResult(
      isCorrect: result.isCorrect,
      explanation: result.explanation,
      score: result.score,
      feedback: result.feedback,
    );
  }
}
