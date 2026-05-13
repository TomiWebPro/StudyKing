import 'package:studyking/core/data/models/question_evaluation_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';

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

class EvaluationAdapterService {
  QuestionEvaluation convertFromQuestion(Question question) {
    return QuestionEvaluation(
      questionId: question.id,
      correctAnswer: question.markscheme?.correctAnswer ?? '',
    );
  }

  QuestionEvaluation convertFromFeatureMarkscheme(
    String questionId,
    Markscheme markscheme,
  ) {
    return QuestionEvaluation(
      questionId: questionId,
      correctAnswer: markscheme.correctAnswer,
      evaluationType: markscheme.steps.isNotEmpty
          ? EvaluationType.stepBased
          : EvaluationType.exactMatch,
      steps: markscheme.steps.isNotEmpty
          ? markscheme.steps
              .map((s) => EvaluationStep(
                    stepNumber: s.stepNumber,
                    requiredAnswer: s.requiredAnswer,
                    points: s.points,
                  ))
              .toList()
          : null,
    );
  }

  QuestionEvaluation convertFromMarkschemeModel(
    String questionId,
    String correctAnswer, {
    List<String>? acceptableAnswers,
    String? explanation,
    List<String>? steps,
  }) {
    return QuestionEvaluation(
      questionId: questionId,
      correctAnswer: correctAnswer,
      acceptableAnswers: acceptableAnswers ?? [],
      evaluationType: steps != null && steps.isNotEmpty
          ? EvaluationType.stepBased
          : EvaluationType.exactMatch,
      explanation: explanation,
      steps: steps?.asMap().entries.map((e) => EvaluationStep(
            stepNumber: '${e.key + 1}',
            requiredAnswer: e.value,
            points: 1.0,
          )).toList(),
    );
  }

  EvaluationResult validateWithEvaluation(
    QuestionEvaluation evaluation,
    String answer,
  ) {
    final isCorrect = evaluation.correctAnswer.toLowerCase() == answer.toLowerCase() ||
        evaluation.acceptableAnswers
            .any((a) => a.toLowerCase() == answer.toLowerCase());

    if (evaluation.evaluationType == EvaluationType.stepBased &&
        evaluation.steps != null) {
      final matchedSteps = evaluation.steps!
          .where((s) => answer.toLowerCase().contains(s.requiredAnswer.toLowerCase()))
          .toList();
      if (matchedSteps.isEmpty) {
        return EvaluationResult(
          isCorrect: false,
          score: 0.0,
          feedback: 'No required steps found',
          explanation: evaluation.explanation,
        );
      }
      final score = matchedSteps.length / evaluation.steps!.length;
      final allMatched = matchedSteps.length == evaluation.steps!.length;
      return EvaluationResult(
        isCorrect: allMatched,
        score: score,
        feedback: allMatched
            ? (evaluation.explanation ?? 'Correct')
            : 'Missing ${evaluation.steps!.length - matchedSteps.length} step(s)',
        explanation: evaluation.explanation,
      );
    }

    return EvaluationResult(
      isCorrect: isCorrect,
      score: isCorrect ? 1.0 : 0.0,
      feedback: isCorrect
          ? (evaluation.explanation ?? 'Correct')
          : 'Incorrect. Expected: ${evaluation.correctAnswer}',
      explanation: evaluation.explanation,
    );
  }

  Map<String, dynamic> toLegacyFormat(QuestionEvaluation evaluation) {
    return {
      'questionId': evaluation.questionId,
      'correctAnswer': evaluation.correctAnswer,
      'explanation': evaluation.explanation,
      'markschemePoints': evaluation.maxPoints,
      if (evaluation.steps != null) 'steps': evaluation.steps!.map((s) => s.toJson()).toList(),
    };
  }
}
