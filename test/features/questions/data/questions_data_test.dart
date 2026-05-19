import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/questions_data.dart';

void main() {
  group('questions_data barrel', () {
    test('QuestionEvaluation can be constructed with required fields', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1',
        correctAnswer: 'Paris',
      );
      expect(evaluation.questionId, 'q1');
      expect(evaluation.correctAnswer, 'Paris');
      expect(evaluation.acceptableAnswers, isEmpty);
      expect(evaluation.evaluationType, EvaluationType.exactMatch);
    });

    test('QuestionEvaluation supports toJson/fromJson round-trip', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1',
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'Paris, France'],
        evaluationType: EvaluationType.acceptableMatch,
        explanation: 'Paris is the capital',
        maxPoints: 1.0,
      );
      final json = evaluation.toJson();
      final restored = QuestionEvaluation.fromJson(json);
      expect(restored.questionId, 'q1');
      expect(restored.correctAnswer, 'Paris');
      expect(restored.acceptableAnswers, ['paris', 'Paris, France']);
      expect(restored.maxPoints, 1.0);
    });

    test('registerQuestionAdapters can be called without throwing', () {
      expect(() => registerQuestionAdapters(), returnsNormally);
    });
  });
}
