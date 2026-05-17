import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/questions.dart';

void main() {
  group('questions barrel export', () {
    test('exports QuestionRepository', () {
      expect(QuestionRepository, isA<Type>());
    });

    test('exports QuestionWithMarkscheme', () {
      expect(QuestionWithMarkscheme, isA<Type>());
    });

    test('exports Markscheme', () {
      expect(Markscheme, isA<Type>());
    });

    test('exports MarkSchemeStep', () {
      expect(MarkSchemeStep, isA<Type>());
    });

    test('exports SingleAnswerWidget', () {
      expect(SingleAnswerWidget, isA<Type>());
    });

    test('exports CanvasDrawingWidget', () {
      expect(CanvasDrawingWidget, isA<Type>());
    });

    test('exports MathExpressionWidget', () {
      expect(MathExpressionWidget, isA<Type>());
    });

    test('exports DrawingPainter', () {
      expect(DrawingPainter, isA<Type>());
    });

    test('exports GridPainter', () {
      expect(GridPainter, isA<Type>());
    });

    test('exports DrawingPoint', () {
      expect(DrawingPoint, isA<Type>());
    });

    test('exports Stroke', () {
      expect(Stroke, isA<Type>());
    });

    test('exports QuestionEvaluation', () {
      expect(QuestionEvaluation, isA<Type>());
    });

    test('exports EvaluationStep', () {
      expect(EvaluationStep, isA<Type>());
    });

    test('exports EvaluationType', () {
      expect(EvaluationType, isA<Type>());
    });

    test('can construct Markscheme', () {
      final markscheme = Markscheme(questionId: 'q1', correctAnswer: 'Paris');
      expect(markscheme.questionId, 'q1');
      expect(markscheme.correctAnswer, 'Paris');
    });

    test('can construct QuestionEvaluation', () {
      final evaluation = QuestionEvaluation(
        questionId: 'q1',
        correctAnswer: 'Paris',
      );
      expect(evaluation.questionId, 'q1');
      expect(evaluation.correctAnswer, 'Paris');
    });

    test('can construct EvaluationStep', () {
      final step = EvaluationStep(stepNumber: '1', requiredAnswer: 'A', points: 2);
      expect(step.stepNumber, '1');
      expect(step.requiredAnswer, 'A');
      expect(step.points, 2);
    });
  });
}
