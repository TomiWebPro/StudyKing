import 'dart:convert';

import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../core/data/enums.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
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

  final ValidationMessages _messages;

  AnswerValidationService({ValidationMessages? messages})
      : _messages = messages ?? ValidationMessages.english;

  QuestionAnswerValidator _getValidator(String questionId, Markscheme markscheme) {
    final signature = _signatureFor(markscheme);
    final cachedSignature = _cacheSignatures[questionId];

    if (cachedSignature == signature && _cache.containsKey(questionId)) {
      return _cache[questionId]!;
    }

    final validator = QuestionAnswerValidator(markscheme, messages: _messages);
    _cache[questionId] = validator;
    _cacheSignatures[questionId] = signature;
    return validator;
  }

  ValidationResult validateAnswer(String answer, QuestionType questionType, String questionId, Markscheme markscheme) {
    final validator = _getValidator(questionId, markscheme);
    return validator.validate(answer, questionType);
  }

  ValidationResult validateWithMarkscheme(String answer, QuestionType questionType, Markscheme? markscheme, {ValidationMessages? messages}) {
    return QuestionAnswerValidator.validateStatic(answer, questionType, markscheme, messages: messages);
  }

  ValidationResult validateAnswerForQuestion(Question question, String answer, {String? noMarkschemeMessage}) {
    final markscheme = question.markscheme;
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: noMarkschemeMessage ?? _messages.markschemeUnavailable,
      );
    }
    final validator = _getValidator(question.id, markscheme);
    return validator.validate(answer, question.type);
  }

  ValidationResult validateWithEvaluation(QuestionEvaluation evaluation, String userAnswer, {
    String? correctLabel,
    String? incorrectPrefix,
  }) {
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
      feedback = evaluation.explanation ?? (correctLabel ?? _messages.correct);
    } else {
      score = 0.0;
      final prefix = incorrectPrefix ?? '${_messages.incorrect}.';
      feedback = evaluation.explanation != null
          ? '$prefix ${evaluation.explanation}'
          : '$prefix ${_messages.correctAnswerIs(evaluation.correctAnswer)}';
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

  String _generateStepFeedback(List<EvaluationStep> steps, String userAnswer, {
    String? allStepsFormat,
    String? partialStepsFormat,
    String? noStepsFormat,
  }) {
    final userAnswerLower = userAnswer.toLowerCase();
    final matchedCount = steps.where((s) => userAnswerLower.contains(s.requiredAnswer.toLowerCase())).length;
    final missingSteps = steps.where((s) => !userAnswerLower.contains(s.requiredAnswer.toLowerCase())).map((s) => s.requiredAnswer).join(', ');
    if (matchedCount == steps.length) {
      return allStepsFormat ?? _messages.allStepsFormat(steps.length);
    } else if (matchedCount > 0) {
      return partialStepsFormat ?? _messages.partialStepsFormat(matchedCount, steps.length, missingSteps);
    } else {
      return noStepsFormat ?? _messages.noStepsFormat(steps.map((s) => s.requiredAnswer).join(', '));
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

class ValidationMessages {
  final String markschemeUnavailable;
  final String pleaseProvideAnswer;
  final String correct;
  final String incorrect;
  final String answerTooShort;
  final String goodResponseLength;
  final String answerTooShortForCredit;
  final String noDrawingDetected;
  final String invalidDrawingData;
  final String drawingDetected;
  final String allStepsIdentified;
  final String specialHandlingRequired;
  final AppLocalizations? _l10n;

  static const ValidationMessages english = ValidationMessages._english();

  const ValidationMessages._english()
      : markschemeUnavailable = 'No markscheme available',
        pleaseProvideAnswer = 'Please provide an answer',
        correct = 'Correct!',
        incorrect = 'Incorrect.',
        answerTooShort = 'Answer is too short. Please provide more details.',
        goodResponseLength = 'Good response length.',
        answerTooShortForCredit = 'Answer too short for full credit.',
        noDrawingDetected = 'No drawing detected. Please draw something.',
        invalidDrawingData = 'Invalid drawing data. Please redraw.',
        drawingDetected = 'Drawing detected.',
        allStepsIdentified = 'All required steps identified.',
        specialHandlingRequired = 'This question type requires special handling.',
        _l10n = null;

  const ValidationMessages({
    this.markschemeUnavailable = '',
    this.pleaseProvideAnswer = '',
    this.correct = '',
    this.incorrect = '',
    this.answerTooShort = '',
    this.goodResponseLength = '',
    this.answerTooShortForCredit = '',
    this.noDrawingDetected = '',
    this.invalidDrawingData = '',
    this.drawingDetected = '',
    this.allStepsIdentified = '',
    this.specialHandlingRequired = '',
  }) : _l10n = null;

  ValidationMessages._({
    required this.markschemeUnavailable,
    required this.pleaseProvideAnswer,
    required this.correct,
    required this.incorrect,
    required this.answerTooShort,
    required this.goodResponseLength,
    required this.answerTooShortForCredit,
    required this.noDrawingDetected,
    required this.invalidDrawingData,
    required this.drawingDetected,
    required this.allStepsIdentified,
    required this.specialHandlingRequired,
    required AppLocalizations l10n,
  }) : _l10n = l10n;

  factory ValidationMessages.fromLocalizations(AppLocalizations l10n) {
    return ValidationMessages._(
      l10n: l10n,
      markschemeUnavailable: l10n.markschemeUnavailable,
      pleaseProvideAnswer: l10n.addAnswerBeforeSubmitting,
      correct: l10n.correctFeedback,
      incorrect: l10n.incorrectFeedback,
      answerTooShort: l10n.answerTooShort,
      goodResponseLength: l10n.goodResponseLength,
      answerTooShortForCredit: l10n.answerTooShortForCredit,
      noDrawingDetected: l10n.noDrawingDetected,
      invalidDrawingData: l10n.invalidDrawingData,
      drawingDetected: l10n.drawingSubmitted,
      allStepsIdentified: l10n.allStepsIdentified,
      specialHandlingRequired: l10n.specialHandlingRequired,
    );
  }

  String someAnswersIncorrect(String explanation) {
    if (_l10n != null) return _l10n.someAnswersIncorrect;
    return explanation.isNotEmpty ? explanation : 'Some answers are incorrect';
  }

  String correctAnswerIs(String answer) {
    if (_l10n != null) return _l10n.correctAnswerIs(answer);
    return 'The correct answer is: $answer';
  }

  String allStepsFormat(int count) {
    if (_l10n != null) return _l10n.allStepsFormat(count);
    return 'All $count steps identified correctly!';
  }

  String partialStepsFormat(int matched, int total, String missing) {
    if (_l10n != null) return _l10n.partialStepsFormat(matched, total, missing);
    return 'Identified $matched of $total steps. Missing: $missing';
  }

  String noStepsFormat(String steps) {
    if (_l10n != null) return _l10n.noStepsFormat(steps);
    return 'No required steps found in your answer. Key steps to include: $steps';
  }

  String allRequiredStepsMissing() {
    if (_l10n != null) return _l10n.allRequiredStepsMissing;
    return 'Some required steps missing';
  }
}

class QuestionAnswerValidator {
  final Markscheme? _markscheme;
  final ValidationMessages _messages;

  QuestionAnswerValidator(this._markscheme, {ValidationMessages? messages})
      : _messages = messages ?? ValidationMessages.english;

  ValidationResult validate(String answer, QuestionType questionType) {
    return validateStatic(answer, questionType, _markscheme, messages: _messages);
  }

  static ValidationResult validateStatic(String answer, QuestionType questionType, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    switch (questionType) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        return validateMCQAnswer(answer, questionType, markscheme, messages: msgs);
      case QuestionType.typedAnswer:
        return validateTypedAnswer(answer, markscheme, messages: msgs);
      case QuestionType.mathExpression:
        return validateMathExpression(answer, markscheme, messages: msgs);
      case QuestionType.essay:
        return validateEssayAnswer(answer, markscheme, messages: msgs);
      case QuestionType.canvas:
        return validateCanvasDrawing([], markscheme, messages: msgs);
      case QuestionType.stepByStep:
        return validateStepByStep(answer, markscheme, messages: msgs);
      case QuestionType.graphDrawing:
        return validateGraphDrawing(answer, markscheme, messages: msgs);
      case QuestionType.fileUpload:
        return validateFileUpload(answer, markscheme, messages: msgs);
      case QuestionType.audioRecording:
        return validateAudioRecording(answer, markscheme, messages: msgs);
    }
  }

  static ValidationResult validateTypedAnswer(String userAnswer, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: msgs.markschemeUnavailable,
      );
    }
    if (userAnswer.trim().isEmpty) {
      return ValidationResult(
        isCorrect: false,
        explanation: msgs.pleaseProvideAnswer,
      );
    }
    final normalizedUserAnswer = userAnswer.trim().toLowerCase();
    final normalizedCorrectAnswer = markscheme.correctAnswer.trim().toLowerCase();
    if (normalizedUserAnswer == normalizedCorrectAnswer) {
      return ValidationResult(
        isCorrect: true,
        explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : msgs.correct,
      );
    }
    for (final acceptable in markscheme.acceptableAnswers) {
      if (normalizedUserAnswer == acceptable.trim().toLowerCase()) {
        return ValidationResult(
          isCorrect: true,
          explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : msgs.correct,
        );
      }
    }
    return ValidationResult(
      isCorrect: false,
      explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : msgs.incorrect,
    );
  }

  static ValidationResult validateMCQAnswer(String userAnswer, QuestionType type, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (markscheme == null) {
      return ValidationResult(isCorrect: false, explanation: msgs.markschemeUnavailable);
    }
    switch (type) {
      case QuestionType.singleChoice:
        final normalizedCorrect = markscheme.correctAnswer.trim().toLowerCase();
        final normalizedUser = userAnswer.trim().toLowerCase();
        return ValidationResult(
          isCorrect: normalizedUser == normalizedCorrect,
          explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : msgs.incorrect,
        );
      case QuestionType.multiChoice:
        final userAnswers = userAnswer.split(',').map((a) => a.trim().toLowerCase()).toList();
        final correctAnswers = markscheme.correctAnswer.split(',').map((a) => a.trim().toLowerCase()).toList();
        final isAllCorrect = userAnswers.every((a) => correctAnswers.contains(a)) &&
            correctAnswers.every((a) => userAnswers.contains(a));
        return ValidationResult(
          isCorrect: isAllCorrect,
          explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : msgs.someAnswersIncorrect(''),
        );
      default:
        return validateTypedAnswer(userAnswer, markscheme, messages: msgs);
    }
  }

  static ValidationResult validateMathExpression(String userAnswer, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (markscheme == null) {
      return ValidationResult(isCorrect: false, explanation: msgs.markschemeUnavailable);
    }
    final normalizedUser = _normalizeMathExpression(userAnswer);
    final normalizedCorrect = _normalizeMathExpression(markscheme.correctAnswer);
    return ValidationResult(
      isCorrect: normalizedUser == normalizedCorrect,
      explanation: (markscheme.explanation?.isNotEmpty ?? false) ? markscheme.explanation! : msgs.correctAnswerIs(markscheme.correctAnswer),
    );
  }

  static String _normalizeMathExpression(String expr) {
    return expr.replaceAll(' ', '').toLowerCase().replaceAll(r'x', '*');
  }

  static ValidationResult validateEssayAnswer(String userAnswer, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (userAnswer.trim().isEmpty) {
      return ValidationResult(isCorrect: false, explanation: msgs.pleaseProvideAnswer);
    }
    if (userAnswer.trim().length < 10) {
      return ValidationResult(isCorrect: false, explanation: msgs.answerTooShort);
    }
    return ValidationResult(
      isCorrect: userAnswer.trim().length > 50,
      explanation: userAnswer.trim().length > 50
          ? msgs.goodResponseLength
          : msgs.answerTooShortForCredit,
    );
  }

  static ValidationResult validateCanvasDrawing(List<Map<String, dynamic>> canvasData, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (canvasData.isEmpty) {
      return ValidationResult(isCorrect: false, explanation: msgs.noDrawingDetected);
    }
    for (final point in canvasData) {
      if (point.isEmpty) {
        return ValidationResult(isCorrect: false, explanation: msgs.invalidDrawingData);
      }
    }
    return ValidationResult(isCorrect: true, explanation: msgs.drawingDetected);
  }

  static ValidationResult validateStepByStep(String answer, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (markscheme == null) {
      return ValidationResult(
        isCorrect: false,
        explanation: msgs.markschemeUnavailable,
      );
    }
    final hasRequiredSteps = markscheme.steps.every((step) {
      return answer.toLowerCase().contains(step.requiredAnswer.toLowerCase());
    });
    return ValidationResult(
      isCorrect: hasRequiredSteps,
      explanation: hasRequiredSteps ? msgs.allStepsIdentified : msgs.allRequiredStepsMissing(),
    );
  }

  static ValidationResult validateGraphDrawing(String answer, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (answer.trim().isEmpty) {
      return ValidationResult(isCorrect: false, explanation: msgs.noDrawingDetected);
    }
    try {
      final decoded = base64Decode(answer);
      if (decoded.isEmpty) {
        return ValidationResult(isCorrect: false, explanation: msgs.noDrawingDetected);
      }
      final jsonStr = utf8.decode(decoded);
      final data = jsonDecode(jsonStr);
      if (data is! List || data.isEmpty) {
        return ValidationResult(isCorrect: false, explanation: msgs.noDrawingDetected);
      }
      return ValidationResult(isCorrect: true, explanation: msgs.drawingDetected);
    } catch (_) {
      return ValidationResult(isCorrect: false, explanation: msgs.invalidDrawingData);
    }
  }

  static ValidationResult validateFileUpload(String answer, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (answer.trim().isEmpty) {
      return ValidationResult(isCorrect: false, explanation: msgs.pleaseProvideAnswer);
    }
    return ValidationResult(isCorrect: true, explanation: msgs.correct);
  }

  static ValidationResult validateAudioRecording(String answer, Markscheme? markscheme, {ValidationMessages? messages}) {
    final msgs = messages ?? ValidationMessages.english;
    if (answer.trim().isEmpty) {
      return ValidationResult(isCorrect: false, explanation: msgs.pleaseProvideAnswer);
    }
    return ValidationResult(isCorrect: true, explanation: msgs.correct);
  }
}
