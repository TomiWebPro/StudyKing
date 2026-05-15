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

    test('exports QuestionCardWidget', () {
      expect(QuestionCardWidget, isA<Type>());
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
  });
}
