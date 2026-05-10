import '../services/answer_validator.dart';
import '../models/question_model.dart';

/// A comprehensive answer validation service for PracticeSession
class AnswerValidationService {
  final QuestionAnswerValidator _validator;
  
  AnswerValidationService(this._validator);

  /// Validates a user's answer and returns validation result
  ValidationResult validateAnswer(Question question, String answer) {
    // Use the appropriate markscheme
    final markscheme = question.markscheme;
    
    _validator = QuestionAnswerValidator(Markscheme(
      correctAnswer: markscheme ?? '',
      acceptableAnswers: [],
      explanation: '',
      steps: [],
    ));
    
    return _validator.validate(answer, question.type);
  }
}
