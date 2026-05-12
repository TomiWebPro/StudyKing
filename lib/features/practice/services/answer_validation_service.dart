import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/models/markscheme_model.dart';
import 'package:studyking/features/questions/services/answer_validator.dart' as consolidated;

class AnswerValidationService {
  final Map<String, consolidated.QuestionAnswerValidator> _cache = {};
  final Map<String, String> _cacheSignatures = {};

  String _signatureFor(Markscheme markscheme) {
    return '${markscheme.correctAnswer}::${markscheme.acceptableAnswers.join('|')}::${markscheme.explanation}';
  }

  consolidated.QuestionAnswerValidator _getValidator(String questionId, Markscheme markscheme) {
    final signature = _signatureFor(markscheme);
    final cachedSignature = _cacheSignatures[questionId];

    if (cachedSignature == signature && _cache.containsKey(questionId)) {
      return _cache[questionId]!;
    }

    final validator = consolidated.QuestionAnswerValidator(markscheme);
    _cache[questionId] = validator;
    _cacheSignatures[questionId] = signature;
    return validator;
  }

  consolidated.ValidationResult validateAnswer(Question question, String answer) {
    final markscheme = question.markscheme;
    if (markscheme == null) {
      return consolidated.ValidationResult(
        isCorrect: false,
        explanation: 'No markscheme available for this question',
      );
    }

    final validator = _getValidator(question.id, markscheme);
    return validator.validate(answer, question.type);
  }
}
