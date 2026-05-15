import 'package:studyking/core/data/enums.dart';

class PracticeAnswerRecord {
  final String questionId;
  final QuestionType questionType;
  final bool isCorrect;
  final Duration timeSpent;
  final String userAnswer;

  PracticeAnswerRecord({
    required this.questionId,
    required this.questionType,
    required this.isCorrect,
    required this.timeSpent,
    required this.userAnswer,
  });
}

class PracticeSessionResult {
  final int questionsAnswered;
  final int correctAnswers;

  PracticeSessionResult({required this.questionsAnswered, required this.correctAnswers});
}
