import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/models/drawing_models.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/questions/presentation/painters/drawing_painter.dart';
import 'package:studyking/features/questions/presentation/painters/grid_painter.dart';
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
  });
}
