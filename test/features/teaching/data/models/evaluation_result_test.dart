import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';

void main() {
  group('EvaluationResult', () {
    test('creates with required fields', () {
      final result = EvaluationResult(
        score: 0.85,
        explanation: 'Good understanding shown.',
      );
      expect(result.score, 0.85);
      expect(result.explanation, 'Good understanding shown.');
      expect(result.partialCredit, isNull);
      expect(result.conceptBreakdown, isNull);
    });

    test('creates with all fields', () {
      final result = EvaluationResult(
        score: 0.6,
        explanation: 'Partial understanding.',
        partialCredit: 0.5,
        conceptBreakdown: {'Algebra': 0.8, 'Calculus': 0.3},
      );
      expect(result.score, 0.6);
      expect(result.partialCredit, 0.5);
      expect(result.conceptBreakdown!.length, 2);
      expect(result.conceptBreakdown!['Algebra'], 0.8);
    });

    test('serializes to JSON and back', () {
      final result = EvaluationResult(
        score: 0.75,
        explanation: 'Good but needs improvement.',
        partialCredit: 0.25,
        conceptBreakdown: {'Concept A': 0.9, 'Concept B': 0.5},
      );
      final json = result.toJson();
      final restored = EvaluationResult.fromJson(json);
      expect(restored.score, result.score);
      expect(restored.explanation, result.explanation);
      expect(restored.partialCredit, result.partialCredit);
      expect(restored.conceptBreakdown!['Concept A'], 0.9);
      expect(restored.conceptBreakdown!['Concept B'], 0.5);
    });

    test('toJson omits null optional fields', () {
      final result = EvaluationResult(
        score: 0.5,
        explanation: 'Average.',
      );
      final json = result.toJson();
      expect(json.containsKey('partialCredit'), isFalse);
      expect(json.containsKey('conceptBreakdown'), isFalse);
      expect(json['score'], 0.5);
      expect(json['explanation'], 'Average.');
    });

    test('fromJson handles missing fields with defaults', () {
      final result = EvaluationResult.fromJson({});
      expect(result.score, 0.5);
      expect(result.explanation, '');
      expect(result.partialCredit, isNull);
      expect(result.conceptBreakdown, isNull);
    });

    test('fromJson handles int values for score and partialCredit', () {
      final result = EvaluationResult.fromJson({
        'score': 8,
        'explanation': 'Int score',
        'partialCredit': 2,
      });
      expect(result.score, 8.0);
      expect(result.partialCredit, 2.0);
    });

    test('fromJson handles int values in conceptBreakdown', () {
      final result = EvaluationResult.fromJson({
        'score': 0.8,
        'explanation': 'Good',
        'conceptBreakdown': {'A': 90, 'B': 50},
      });
      expect(result.conceptBreakdown!['A'], 90.0);
      expect(result.conceptBreakdown!['B'], 50.0);
    });

    test('fromJson handles null conceptBreakdown', () {
      final result = EvaluationResult.fromJson({
        'score': 0.7,
        'explanation': 'OK',
        'conceptBreakdown': null,
      });
      expect(result.conceptBreakdown, isNull);
    });

    test('score bounds are preserved', () {
      final result = EvaluationResult(
        score: 0.0,
        explanation: 'No understanding.',
      );
      expect(result.score, 0.0);

      final result2 = EvaluationResult(
        score: 1.0,
        explanation: 'Perfect.',
      );
      expect(result2.score, 1.0);
    });

    test('creates with correctAnswer', () {
      final result = EvaluationResult(
        score: 1.0,
        explanation: 'Perfect.',
        correctAnswer: '42',
      );
      expect(result.correctAnswer, '42');
    });

    test('creates with options', () {
      final result = EvaluationResult(
        score: 1.0,
        explanation: 'Correct.',
        options: ['A', 'B', 'C', 'D'],
      );
      expect(result.options, ['A', 'B', 'C', 'D']);
    });

    test('creates with exerciseType', () {
      final result = EvaluationResult(
        score: 0.8,
        explanation: 'Good.',
        exerciseType: 'multiple_choice',
      );
      expect(result.exerciseType, 'multiple_choice');
    });

    test('toJson includes correctAnswer when set', () {
      final result = EvaluationResult(
        score: 1.0,
        explanation: 'Perfect.',
        correctAnswer: '42',
      );
      final json = result.toJson();
      expect(json['correctAnswer'], '42');
    });

    test('toJson includes options when set', () {
      final result = EvaluationResult(
        score: 1.0,
        explanation: 'Correct.',
        options: ['A', 'B'],
      );
      final json = result.toJson();
      expect(json['options'], ['A', 'B']);
    });

    test('toJson includes exerciseType when set', () {
      final result = EvaluationResult(
        score: 0.8,
        explanation: 'Good.',
        exerciseType: 'multiple_choice',
      );
      final json = result.toJson();
      expect(json['exerciseType'], 'multiple_choice');
    });

    test('fromJson parses options list', () {
      final result = EvaluationResult.fromJson({
        'score': 0.9,
        'explanation': 'Great.',
        'options': ['Alpha', 'Beta', 'Gamma'],
      });
      expect(result.options, ['Alpha', 'Beta', 'Gamma']);
    });

    test('fromJson parses exerciseType from type key', () {
      final result = EvaluationResult.fromJson({
        'score': 0.7,
        'explanation': 'OK',
        'type': 'essay',
      });
      expect(result.exerciseType, 'essay');
    });

    test('fromJson parses exerciseType from exerciseType key when type is absent', () {
      final result = EvaluationResult.fromJson({
        'score': 0.7,
        'explanation': 'OK',
        'exerciseType': 'short_answer',
      });
      expect(result.exerciseType, 'short_answer');
    });

    test('fromJson prefers type key over exerciseType key', () {
      final result = EvaluationResult.fromJson({
        'score': 0.7,
        'explanation': 'OK',
        'type': 'essay',
        'exerciseType': 'short_answer',
      });
      expect(result.exerciseType, 'essay');
    });

    test('roundtrip with all optional fields', () {
      final original = EvaluationResult(
        score: 0.95,
        explanation: 'Excellent.',
        partialCredit: 0.5,
        conceptBreakdown: {'Topic A': 1.0, 'Topic B': 0.9},
        correctAnswer: 'Paris',
        options: ['London', 'Paris', 'Berlin', 'Madrid'],
        exerciseType: 'multiple_choice',
      );
      final json = original.toJson();
      final restored = EvaluationResult.fromJson(json);
      expect(restored.score, original.score);
      expect(restored.explanation, original.explanation);
      expect(restored.partialCredit, original.partialCredit);
      expect(restored.correctAnswer, original.correctAnswer);
      expect(restored.options, original.options);
      expect(restored.exerciseType, original.exerciseType);
      expect(restored.conceptBreakdown!['Topic A'], 1.0);
    });

    test('fromJson handles options as empty list', () {
      final result = EvaluationResult.fromJson({
        'score': 0.5,
        'explanation': 'Half',
        'options': <String>[],
      });
      expect(result.options, isEmpty);
    });

    test('fromJson handles options as non-List type gracefully', () {
      final result = EvaluationResult.fromJson({
        'score': 0.5,
        'explanation': 'Half',
        'options': 'not a list',
      });
      expect(result.options, isNull);
    });

    test('fromJson handles null options', () {
      final result = EvaluationResult.fromJson({
        'score': 0.5,
        'explanation': 'Half',
        'options': null,
      });
      expect(result.options, isNull);
    });

    test('fromJson handles correctAnswer', () {
      final result = EvaluationResult.fromJson({
        'score': 1.0,
        'explanation': 'Perfect.',
        'correctAnswer': 'Berlin',
      });
      expect(result.correctAnswer, 'Berlin');
    });

    test('fromJson handles null correctAnswer', () {
      final result = EvaluationResult.fromJson({
        'score': 0.5,
        'explanation': 'Half',
        'correctAnswer': null,
      });
      expect(result.correctAnswer, isNull);
    });
  });
}
