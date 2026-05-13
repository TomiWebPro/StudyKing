import '../../core/data/enums.dart';
import '../data/models/markscheme_model.dart';
import '../data/models/question_evaluation_model.dart';
import '../data/models/question_model.dart';

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

class AnswerValidationService {
  final Map<String, QuestionAnswerValidator> _cache = {};
  final Map<String, String> _cacheSignatures = {};

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

  ValidationResult validateAnswer(String answer, QuestionType questionType, String questionId, Markscheme markscheme) {
    final validator = _getValidator(questionId, markscheme);
    return validator.validate(answer, questionType);
  }

  ValidationResult validateWithMarkscheme(String answer, QuestionType questionType, Markscheme? markscheme) {
    return QuestionAnswerValidator.validateStatic(answer, questionType, markscheme);
  }

  ValidationResult validateAnswerForQuestion(Question question, String answer) {
    final markscheme = question.markscheme;
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available for this question',
      );
    }
    final validator = _getValidator(question.id, markscheme);
    return validator.validate(answer, question.type);
  }

  ValidationResult validateWithEvaluation(QuestionEvaluation evaluation, String userAnswer) {
    final answer = userAnswer.toLowerCase().trim();
    final correct = evaluation.correctAnswer.toLowerCase().trim();
    final isExactMatch = answer == correct;

    bool isMatch = isExactMatch;
    if (!isMatch) {
      for (final acceptable in evaluation.acceptableAnswers) {
        if (acceptable.toLowerCase().trim() == answer) {
          isMatch = true;
          break;
        }
      }
    }

    if (!isMatch && evaluation.evaluationType == EvaluationType.fuzzyMatch) {
      isMatch = _isSimilar(answer, correct);
    }

    if (!isMatch && evaluation.evaluationType == EvaluationType.stepBased && evaluation.steps != null && evaluation.steps!.isNotEmpty) {
      final answerLower = userAnswer.toLowerCase();
      isMatch = evaluation.steps!.every((step) => answerLower.contains(step.requiredAnswer.toLowerCase()));
    }

    double score;
    String feedback;

    if (isMatch) {
      score = evaluation.maxPoints ?? 1.0;
      feedback = evaluation.explanation ?? 'Correct!';
    } else {
      score = 0.0;
      feedback = evaluation.explanation != null
          ? 'Incorrect. ${evaluation.explanation}'
          : 'Incorrect. The correct answer was: ${evaluation.correctAnswer}';
    }

    if (evaluation.steps != null && evaluation.steps!.isNotEmpty) {
      score = _calculateStepScore(evaluation.steps!, userAnswer);
      feedback = _generateStepFeedback(evaluation.steps!, userAnswer);
    }

    return ValidationResult(
      isCorrect: isMatch,
      score: score,
      feedback: feedback,
      explanation: evaluation.explanation ?? '',
    );
  }

  double _calculateStepScore(List<EvaluationStep> steps, String userAnswer) {
    if (steps.isEmpty) return 1.0;
    final userAnswerLower = userAnswer.toLowerCase();
    var matchedSteps = 0;
    for (final step in steps) {
      if (userAnswerLower.contains(step.requiredAnswer.toLowerCase())) {
        matchedSteps++;
      }
    }
    final totalPoints = steps.fold(0.0, (sum, step) => sum + step.points);
    if (totalPoints == 0) return matchedSteps / steps.length;
    return (matchedSteps / steps.length) * (totalPoints / steps.length);
  }

  String _generateStepFeedback(List<EvaluationStep> steps, String userAnswer) {
    final userAnswerLower = userAnswer.toLowerCase();
    final matchedCount = steps.where((s) => userAnswerLower.contains(s.requiredAnswer.toLowerCase())).length;
    if (matchedCount == steps.length) {
      return 'All ${steps.length} steps identified correctly!';
    } else if (matchedCount > 0) {
      return 'Identified $matchedCount of ${steps.length} steps. Missing: ${steps.where((s) => !userAnswerLower.contains(s.requiredAnswer.toLowerCase())).map((s) => s.requiredAnswer).join(", ")}';
    } else {
      return 'No required steps found in your answer. Key steps to include: ${steps.map((s) => s.requiredAnswer).join(", ")}';
    }
  }

  bool _isSimilar(String answer, String correct) {
    final answerWords = answer.split(' ');
    final correctWords = correct.split(' ');
    if (answerWords.length >= correctWords.length * 0.8) {
      final matchingRatio = answerWords.where((word) => correctWords.contains(word)).length / correctWords.length;
      return matchingRatio > 0.7;
    }
    return false;
  }
}

class QuestionAnswerValidator {
  final Markscheme? _markscheme;

  QuestionAnswerValidator(this._markscheme);

  ValidationResult validate(String answer, QuestionType questionType) {
    return validateStatic(answer, questionType, _markscheme);
  }

  static ValidationResult validateStatic(String answer, QuestionType questionType, Markscheme? markscheme) {
    switch (questionType) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        return validateMCQAnswer(answer, questionType, markscheme);
      case QuestionType.typedAnswer:
        return validateTypedAnswer(answer, markscheme);
      case QuestionType.mathExpression:
        return validateMathExpression(answer, markscheme);
      case QuestionType.essay:
        return validateEssayAnswer(answer, markscheme);
      case QuestionType.canvas:
        return validateCanvasDrawing([], markscheme);
      case QuestionType.stepByStep:
        return validateStepByStep(answer, markscheme);
      case QuestionType.graphDrawing:
      case QuestionType.fileUpload:
      case QuestionType.audioRecording:
        return ValidationResult(
          isCorrect: false,
          explanation: 'This question type requires special handling',
        );
    }
  }

  static ValidationResult validateTypedAnswer(String userAnswer, Markscheme? markscheme) {
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

  static ValidationResult validateMCQAnswer(String userAnswer, QuestionType type, Markscheme? markscheme) {
    if (markscheme == null) {
      return ValidationResult(isCorrect: false, explanation: 'No markscheme available');
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
        final userAnswers = userAnswer.split(',').map((a) => a.trim().toLowerCase()).toList();
        final correctAnswers = markscheme.correctAnswer.split(',').map((a) => a.trim().toLowerCase()).toList();
        final isAllCorrect = userAnswers.every((a) => correctAnswers.contains(a)) &&
            correctAnswers.every((a) => userAnswers.contains(a));
        return ValidationResult(
          isCorrect: isAllCorrect,
          explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'Some answers are incorrect',
        );
      default:
        return validateTypedAnswer(userAnswer, markscheme);
    }
  }

  static ValidationResult validateMathExpression(String userAnswer, Markscheme? markscheme) {
    if (markscheme == null) {
      return ValidationResult(isCorrect: false, explanation: 'No markscheme available');
    }
    final normalizedUser = _normalizeMathExpression(userAnswer);
    final normalizedCorrect = _normalizeMathExpression(markscheme.correctAnswer);
    return ValidationResult(
      isCorrect: normalizedUser == normalizedCorrect,
      explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'The correct answer is: ${markscheme.correctAnswer}',
    );
  }

  static String _normalizeMathExpression(String expr) {
    return expr.replaceAll(' ', '').toLowerCase().replaceAll(r'x', '*');
  }

  static ValidationResult validateEssayAnswer(String userAnswer, Markscheme? markscheme) {
    if (userAnswer.trim().isEmpty) {
      return ValidationResult(isCorrect: false, explanation: 'Please provide an answer');
    }
    if (userAnswer.trim().length < 10) {
      return ValidationResult(isCorrect: false, explanation: 'Answer is too short. Please provide more details.');
    }
    return ValidationResult(
      isCorrect: userAnswer.trim().length > 50,
      explanation: userAnswer.trim().length > 50
          ? 'Good response length. Essays require AI-based grading (placeholder).'
          : 'Answer too short for full credit.',
    );
  }

  static ValidationResult validateCanvasDrawing(List<Map<String, dynamic>> canvasData, Markscheme? markscheme) {
    if (canvasData.isEmpty) {
      return ValidationResult(isCorrect: false, explanation: 'No drawing detected. Please draw something on the canvas.');
    }
    for (final point in canvasData) {
      if (point.isEmpty) {
        return ValidationResult(isCorrect: false, explanation: 'Invalid drawing data detected. Please redraw.');
      }
    }
    return ValidationResult(isCorrect: true, explanation: 'Drawing detected');
  }

  static ValidationResult validateStepByStep(String answer, Markscheme? markscheme) {
    if (markscheme == null) {
      return ValidationResult(isCorrect: false, explanation: 'No markscheme available');
    }
    final hasRequiredSteps = markscheme.steps.every((step) {
      return answer.toLowerCase().contains(step.requiredAnswer.toLowerCase());
    });
    return ValidationResult(
      isCorrect: hasRequiredSteps,
      explanation: hasRequiredSteps ? 'All required steps identified' : 'Some required steps missing',
    );
  }
}
