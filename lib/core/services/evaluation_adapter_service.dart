import '../data/models/question_evaluation_model.dart';
import '../data/models/question_model.dart';
import '../data/models/markscheme_model.dart' as legacy;

class EvaluationAdapterService {
  QuestionEvaluation convertFromQuestion(Question question) {
    return QuestionEvaluation.fromLegacy(
      questionId: question.id,
      markscheme: question.markscheme,
      correctAnswer: question.correctAnswer,
      options: question.options,
      explanation: question.explanation,
    );
  }

  QuestionEvaluation convertFromLegacyMarkscheme(String questionId, legacy.Markscheme markscheme) {
    final steps = markscheme.steps.isNotEmpty
        ? markscheme.steps.asMap().entries.map((e) => EvaluationStep(
                  stepNumber: '${e.key + 1}',
                  requiredAnswer: e.value,
                  points: 1.0,
                )).toList()
        : null;

    return QuestionEvaluation(
      questionId: questionId,
      correctAnswer: markscheme.correctAnswer,
      acceptableAnswers: markscheme.acceptableAnswers,
      evaluationType: steps != null ? EvaluationType.stepBased : EvaluationType.exactMatch,
      explanation: markscheme.explanation,
      steps: steps,
      version: 1,
    );
  }

  QuestionEvaluation convertFromMarkschemeModel(
    String questionId,
    String correctAnswer, {
    List<String>? acceptableAnswers,
    String? explanation,
    List<String>? steps,
  }) {
    final evalSteps = steps?.asMap().entries.map((e) => EvaluationStep(
          stepNumber: '${e.key + 1}',
          requiredAnswer: e.value,
          points: 1.0,
        )).toList();

    return QuestionEvaluation(
      questionId: questionId,
      correctAnswer: correctAnswer,
      acceptableAnswers: acceptableAnswers ?? [],
      evaluationType: evalSteps != null ? EvaluationType.stepBased : EvaluationType.exactMatch,
      explanation: explanation,
      steps: evalSteps,
    );
  }

  EvaluationResult validateWithEvaluation(QuestionEvaluation evaluation, String userAnswer) {
    final isMatch = evaluation.isMatch(userAnswer);

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

    return EvaluationResult(
      isCorrect: isMatch,
      score: score,
      feedback: feedback,
      explanation: evaluation.explanation,
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

    return (matchedSteps / steps.length) * (steps.first.points * steps.length);
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

  Map<String, dynamic> toLegacyFormat(QuestionEvaluation evaluation) {
    return {
      'questionId': evaluation.questionId,
      'correctAnswer': evaluation.correctAnswer,
      'acceptableAnswers': evaluation.acceptableAnswers,
      'explanation': evaluation.explanation,
      'steps': evaluation.steps?.map((s) => s.toJson()).toList(),
      'markschemePoints': evaluation.maxPoints,
    };
  }
}

class EvaluationResult {
  final bool isCorrect;
  final double score;
  final String feedback;
  final String? explanation;

  EvaluationResult({
    required this.isCorrect,
    required this.score,
    required this.feedback,
    this.explanation,
  });
}