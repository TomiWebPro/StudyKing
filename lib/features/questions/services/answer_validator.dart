import '../../../core/data/enums.dart';
import '../models/markscheme_model.dart';

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
    return AnswerValidationService.validateWithMarkscheme(
      answer,
      questionType,
      _markscheme,
    );
  }

  ValidationResult validateTypedAnswer(String userAnswer) {
    return AnswerValidationService.validateTypedAnswerWithMarkscheme(
      userAnswer,
      _markscheme,
    );
  }

  ValidationResult validateMCQAnswer(String userAnswer, QuestionType type) {
    return AnswerValidationService.validateMCQAnswerWithMarkscheme(
      userAnswer,
      type,
      _markscheme,
    );
  }

  ValidationResult validateMathExpression(String userAnswer) {
    return AnswerValidationService.validateMathExpressionWithMarkscheme(
      userAnswer,
      _markscheme,
    );
  }

  ValidationResult validateEssayAnswer(String userAnswer) {
    return AnswerValidationService.validateEssayAnswerWithMarkscheme(
      userAnswer,
      _markscheme,
    );
  }

  ValidationResult validateCanvasDrawing(List<Map<String, dynamic>> canvasData) {
    return AnswerValidationService.validateCanvasDrawingWithMarkscheme(
      canvasData,
      _markscheme,
    );
  }

  ValidationResult validateStepByStepAnswer(String answer) {
    return AnswerValidationService.validateStepByStepWithMarkscheme(
      answer,
      _markscheme,
    );
  }
}

class AnswerValidationService {
  static final Map<String, QuestionAnswerValidator> _cache = {};
  static final Map<String, String> _cacheSignatures = {};

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
    return validator;
  }

  ValidationResult validateAnswerWithMarkscheme(
    String answer,
    QuestionType questionType,
    Markscheme? markscheme,
  ) {
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available for validation',
      );
    }
    return _validate(answer, questionType, markscheme);
  }

  ValidationResult validateAnswer(String answer, QuestionType questionType, String questionId, Markscheme markscheme) {
    final validator = _getValidator(questionId, markscheme);
    return validator.validate(answer, questionType);
  }

  static ValidationResult validateWithMarkscheme(
    String answer,
    QuestionType questionType,
    Markscheme? markscheme,
  ) {
    return _validate(answer, questionType, markscheme);
  }

  static ValidationResult _validate(
    String answer,
    QuestionType questionType,
    Markscheme? markscheme,
  ) {
    switch (questionType) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        return _validateMCQAnswer(answer, questionType, markscheme);
      case QuestionType.typedAnswer:
        return _validateTypedAnswer(answer, markscheme);
      case QuestionType.mathExpression:
        return _validateMathExpression(answer, markscheme);
      case QuestionType.essay:
        return _validateEssayAnswer(answer, markscheme);
      case QuestionType.canvas:
        return _validateCanvasDrawing([], markscheme);
      case QuestionType.stepByStep:
        return _validateStepByStep(answer, markscheme);
      case QuestionType.graphDrawing:
      case QuestionType.fileUpload:
      case QuestionType.audioRecording:
        return ValidationResult(
          isCorrect: false,
          explanation: 'This question type requires special handling',
        );
    }
  }

  static ValidationResult validateTypedAnswerWithMarkscheme(
    String userAnswer,
    Markscheme? markscheme,
  ) {
    return _validateTypedAnswer(userAnswer, markscheme);
  }

  static ValidationResult _validateTypedAnswer(String userAnswer, Markscheme? markscheme) {
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available for validation',
      );
    }

    if (userAnswer.trim().isEmpty) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'Please provide an answer',
      );
    }

    final normalizedUserAnswer = userAnswer.trim().toLowerCase();
    final normalizedCorrectAnswer = markscheme.correctAnswer.trim().toLowerCase();

    if (normalizedUserAnswer == normalizedCorrectAnswer) {
      return ValidationResult(
        isCorrect: true,
        explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'Correct!',
      );
    }

    for (final acceptable in markscheme.acceptableAnswers) {
      if (normalizedUserAnswer == acceptable.trim().toLowerCase()) {
        return ValidationResult(
          isCorrect: true,
          explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'Correct!',
        );
      }
    }

    return ValidationResult(
      isCorrect: false,
      explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'Incorrect',
    );
  }

  static ValidationResult validateMCQAnswerWithMarkscheme(
    String userAnswer,
    QuestionType type,
    Markscheme? markscheme,
  ) {
    return _validateMCQAnswer(userAnswer, type, markscheme);
  }

  static ValidationResult _validateMCQAnswer(
    String userAnswer,
    QuestionType type,
    Markscheme? markscheme,
  ) {
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available',
      );
    }

    switch (type) {
      case QuestionType.singleChoice:
        final normalizedCorrect = markscheme.correctAnswer.trim().toLowerCase();
        final normalizedUser = userAnswer.trim().toLowerCase();
        return ValidationResult(
          isCorrect: normalizedUser == normalizedCorrect,
          explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'Incorrect',
        );
      case QuestionType.multiChoice:
        final userAnswers = userAnswer
            .split(',')
            .map((a) => a.trim().toLowerCase())
            .toList();
        final correctAnswers = markscheme.correctAnswer
            .split(',')
            .map((a) => a.trim().toLowerCase())
            .toList();
        final isAllCorrect = userAnswers.every((a) => correctAnswers.contains(a)) &&
            correctAnswers.every((a) => userAnswers.contains(a));
        return ValidationResult(
          isCorrect: isAllCorrect,
          explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'Some answers are incorrect',
        );
      default:
        return _validateTypedAnswer(userAnswer, markscheme);
    }
  }

  static ValidationResult validateMathExpressionWithMarkscheme(
    String userAnswer,
    Markscheme? markscheme,
  ) {
    return _validateMathExpression(userAnswer, markscheme);
  }

  static ValidationResult _validateMathExpression(String userAnswer, Markscheme? markscheme) {
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available',
      );
    }

    final normalizedUser = _normalizeMathExpression(userAnswer);
    final normalizedCorrect = _normalizeMathExpression(markscheme.correctAnswer);

    return ValidationResult(
      isCorrect: normalizedUser == normalizedCorrect,
      explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'The correct answer is: ${markscheme.correctAnswer}',
    );
  }

  static String _normalizeMathExpression(String expr) {
    return expr
        .replaceAll(' ', '')
        .toLowerCase()
        .replaceAll(r'x', '*');
  }

  static ValidationResult validateEssayAnswerWithMarkscheme(
    String userAnswer,
    Markscheme? markscheme,
  ) {
    return _validateEssayAnswer(userAnswer, markscheme);
  }

  static ValidationResult _validateEssayAnswer(String userAnswer, Markscheme? markscheme) {
    if (userAnswer.trim().isEmpty) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'Please provide an answer',
      );
    }

    if (userAnswer.trim().length < 10) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'Answer is too short. Please provide more details.',
      );
    }

    return ValidationResult(
      isCorrect: userAnswer.trim().length > 50,
      explanation: userAnswer.trim().length > 50
          ? 'Good response length. Essays require AI-based grading (placeholder).'
          : 'Answer too short for full credit.',
    );
  }

  static ValidationResult validateCanvasDrawingWithMarkscheme(
    List<Map<String, dynamic>> canvasData,
    Markscheme? markscheme,
  ) {
    return _validateCanvasDrawing(canvasData, markscheme);
  }

  static ValidationResult _validateCanvasDrawing(
    List<Map<String, dynamic>> canvasData,
    Markscheme? markscheme,
  ) {
    if (canvasData.isEmpty) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No drawing detected. Please draw something on the canvas.',
      );
    }

    for (final point in canvasData) {
      if (point.isEmpty) {
        return ValidationResult(
          isCorrect: false,
          explanation: 'Invalid drawing data detected. Please redraw.',
        );
      }
    }

    return ValidationResult(
      isCorrect: true,
      explanation: 'Drawing detected',
    );
  }

  static ValidationResult validateStepByStepWithMarkscheme(
    String answer,
    Markscheme? markscheme,
  ) {
    return _validateStepByStep(answer, markscheme);
  }

  static ValidationResult _validateStepByStep(String answer, Markscheme? markscheme) {
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available',
      );
    }

    final hasRequiredSteps = markscheme.steps.every((step) {
      return answer.toLowerCase().contains(step.requiredAnswer.toLowerCase());
    });

    return ValidationResult(
      isCorrect: hasRequiredSteps,
      explanation: hasRequiredSteps
          ? 'All required steps identified'
          : 'Some required steps missing',
    );
  }
}
