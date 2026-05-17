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
  });
}
