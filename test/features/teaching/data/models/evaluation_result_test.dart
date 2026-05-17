import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/data/models/evaluation_result.dart';

void main() {
  group('EvaluationResult', () {
    test('creates with required fields', () {
      final result = EvaluationResult(
        score: 0.85,
        explanation: 'Good understanding shown.',
      );
      expect(result.score, equals(0.85));
      expect(result.explanation, equals('Good understanding shown.'));
      expect(result.partialCredit, isNull);
      expect(result.conceptBreakdown, isNull);
    });

    test('creates with all fields', () {
      final result = EvaluationResult(
        score: 0.6,
        explanation: 'Partial understanding.',
        partialCredit: 0.5,
        conceptBreakdown: {
          'Algebra': 0.8,
          'Calculus': 0.3,
        },
      );
      expect(result.score, equals(0.6));
      expect(result.partialCredit, equals(0.5));
      expect(result.conceptBreakdown!.length, equals(2));
      expect(result.conceptBreakdown!['Algebra'], equals(0.8));
    });

    test('serializes to JSON and back', () {
      final result = EvaluationResult(
        score: 0.75,
        explanation: 'Good but needs improvement.',
        partialCredit: 0.25,
        conceptBreakdown: {
          'Concept A': 0.9,
          'Concept B': 0.5,
        },
      );
      final json = result.toJson();
      final restored = EvaluationResult.fromJson(json);
      expect(restored.score, equals(result.score));
      expect(restored.explanation, equals(result.explanation));
      expect(restored.partialCredit, equals(result.partialCredit));
      expect(restored.conceptBreakdown!['Concept A'], equals(0.9));
      expect(restored.conceptBreakdown!['Concept B'], equals(0.5));
    });

    test('fromJson handles missing fields with defaults', () {
      final result = EvaluationResult.fromJson({});
      expect(result.score, equals(0.5));
      expect(result.explanation, equals(''));
      expect(result.partialCredit, isNull);
      expect(result.conceptBreakdown, isNull);
    });

    test('score bounds are preserved', () {
      final result = EvaluationResult(
        score: 0.0,
        explanation: 'No understanding.',
      );
      expect(result.score, equals(0.0));

      final result2 = EvaluationResult(
        score: 1.0,
        explanation: 'Perfect.',
      );
      expect(result2.score, equals(1.0));
    });
  });
}
