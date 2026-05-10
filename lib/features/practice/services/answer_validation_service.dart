import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/services/answer_validator.dart';

/// A comprehensive answer validation service for PracticeSession
class AnswerValidationService {
  final QuestionAnswerValidator _validator;

  AnswerValidationService(this._validator);

  /// Validates a user's answer and returns validation result
  ValidationResult validateAnswer(Question question, String answer) {
    return _validator.validate(answer, question.type);
  }

  /// Validates MCQ answer (single or multiple choice)
  ValidationResult validateMCQAnswer(String answer, QuestionType type) {
    return _validator.validateMCQAnswer(answer, type);
  }
}
