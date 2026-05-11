import '../../../core/data/enums.dart';
import '../models/markscheme_model.dart';

/// Question answer validator service
/// 
/// Validates user answers against markschemes for different question types
class QuestionAnswerValidator {
  final Markscheme? _markscheme;

  QuestionAnswerValidator(this._markscheme);

  /// Validate a typed answer against markscheme
  ValidationResult validateTypedAnswer(String userAnswer) {
    if (_markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available for validation',
      );
    }
    
    // STRICT VALIDATION: Answer must not be empty or only whitespace
    if (userAnswer.trim().isEmpty) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'Please provide an answer',
      );
    }
    
    final normalizedUserAnswer = userAnswer.trim().toLowerCase();
    final normalizedCorrectAnswer = _markscheme.correctAnswer.trim().toLowerCase();
    
    // Check if exact match
    if (normalizedUserAnswer == normalizedCorrectAnswer) {
      return ValidationResult(
        isCorrect: true,
        explanation: (_markscheme.explanation?.isNotEmpty ?? false) ? _markscheme.explanation! : 'Correct!',
      );
    }
    
    // Check if in acceptable answers
    for (final acceptable in _markscheme.acceptableAnswers) {
      if (normalizedUserAnswer == acceptable.trim().toLowerCase()) {
        return ValidationResult(
          isCorrect: true,
          explanation: (_markscheme.explanation?.isNotEmpty ?? false) ? _markscheme.explanation! : 'Correct!',
        );
      }
    }
    
    return ValidationResult(
      isCorrect: false,
      explanation: (_markscheme.explanation?.isNotEmpty ?? false) ? _markscheme.explanation! : 'Incorrect',
    );
  }

  /// Validate MCQ answer (single or multiple choice)
  ValidationResult validateMCQAnswer(String userAnswer, QuestionType type) {
    if (_markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available',
      );
    }

    switch (type) {
      case QuestionType.singleChoice:
        return _validateSingleChoice(userAnswer);
      
      case QuestionType.multiChoice:
        return _validateMultiChoice(userAnswer);
      
      default:
        return validateTypedAnswer(userAnswer);
    }
  }

  ValidationResult _validateSingleChoice(String userAnswer) {
    final markscheme = _markscheme!;
    final normalizedCorrect = markscheme.correctAnswer.trim().toLowerCase();
    final normalizedUser = userAnswer.trim().toLowerCase();
    
    return ValidationResult(
      isCorrect: normalizedUser == normalizedCorrect,
      explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 'Incorrect',
    );
  }

  ValidationResult _validateMultiChoice(String userAnswer) {
    final markscheme = _markscheme!;
    // Parse user answer (comma-separated or similar)
    final userAnswers = userAnswer
        .split(',')
        .map((a) => a.trim().toLowerCase())
        .toList();
    
    final correctAnswers = markscheme.correctAnswer
        .split(',')
        .map((a) => a.trim().toLowerCase())
        .toList();
    
    // All user answers must be in correct answers and vice versa
    final isAllCorrect = userAnswers.every((a) => correctAnswers.contains(a)) &&
        correctAnswers.every((a) => userAnswers.contains(a));

    return ValidationResult(
      isCorrect: isAllCorrect,
      explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : 
          'Some answers are incorrect',
    );
  }

  /// Validate math expression (basic string comparison for now)
  ValidationResult validateMathExpression(String userAnswer) {
    if (_markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available',
      );
    }

    // For math, we might want to use symbolic evaluation
    // For now, simple normalization and comparison
    final normalizedUser = _normalizeMathExpression(userAnswer);
    final normalizedCorrect = _normalizeMathExpression(_markscheme.correctAnswer);

    return ValidationResult(
      isCorrect: normalizedUser == normalizedCorrect,
      explanation: (_markscheme.explanation?.isNotEmpty ?? false) ? _markscheme.explanation! : 
          'The correct answer is: ${_markscheme.correctAnswer}',
    );
  }

  String _normalizeMathExpression(String expr) {
    // Remove spaces, normalize common abbreviations
    return expr
        .replaceAll(' ', '')
        .toLowerCase()
        .replaceAll(r'x', '*');
  }

  /// Validate essay answer (requires AI grading - placeholder)
  ValidationResult validateEssayAnswer(String userAnswer) {
    // STRICT VALIDATION: Check for at least meaningful content
    // Must not be empty, whitespace only, or too short
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
    
    // In a real implementation, this would use AI grading
    // For now, return basic validation
    return ValidationResult(
      isCorrect: userAnswer.trim().length > 50, // Minimum length for full credit
      explanation: userAnswer.trim().length > 50 
          ? 'Good response length. Essays require AI-based grading (placeholder).' 
          : 'Answer too short for full credit.',
    );
  }

  /// Validate canvas drawing (requires pattern matching - advanced)
  ValidationResult validateCanvasDrawing(List<Map<String, dynamic>> canvasData) {
    // Canvas data validation is complex
    // For now, check if canvas has content
    if (canvasData.isEmpty) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No drawing detected. Please draw something on the canvas.',
      );
    }
    
    // Additional strict validation: points must have valid coordinates
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

  /// Generic validation method
  ValidationResult validate(String answer, QuestionType questionType) {
    switch (questionType) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        return validateMCQAnswer(answer, questionType);
      
      case QuestionType.typedAnswer:
        return validateTypedAnswer(answer);
      
      case QuestionType.mathExpression:
        return validateMathExpression(answer);
      
      case QuestionType.essay:
        return validateEssayAnswer(answer);
      
      case QuestionType.canvas:
        return validateCanvasDrawing([]); // Canvas data would be passed
      
      case QuestionType.stepByStep:
        return validateStepByStepAnswer(answer);
      
      case QuestionType.graphDrawing:
      case QuestionType.fileUpload:
      case QuestionType.audioRecording:
        return ValidationResult(
          isCorrect: false,
          explanation: 'This question type requires special handling',
        );
    }
  }

  ValidationResult validateStepByStepAnswer(String answer) {
    // For step-by-step questions, check if key steps are included
    if (_markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available',
      );
    }

    // Check if answer contains required steps
    final hasRequiredSteps = _markscheme.steps.every((step) {
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
