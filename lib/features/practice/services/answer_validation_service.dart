import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/services/answer_validator.dart';

class AnswerValidationService {
  final Map<String, QuestionAnswerValidator> _cache = {};

  QuestionAnswerValidator _getValidator(String questionId, Markscheme markscheme) {
    return _cache.putIfAbsent(questionId, () => QuestionAnswerValidator(markscheme));
  }

  ValidationResult validateAnswer(Question question, String answer) {
    final markscheme = Markscheme(
      correctAnswer: question.markscheme ?? '',
      acceptableAnswers: question.options,
      explanation: question.explanation ?? '',
    );
    final validator = _getValidator(question.id, markscheme);
    return validator.validate(answer, question.type);
  }
}
