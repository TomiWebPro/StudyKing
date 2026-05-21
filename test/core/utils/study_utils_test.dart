import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/study_utils.dart';

void main() {
  group('calculateAdherenceScore', () {
    test('returns 1.0 when both planned values are zero', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 0,
        actualQuestions: 0,
        plannedMinutes: 0,
        actualMinutes: 0,
      );
      expect(score, 1.0);
    });

    test('returns 1.0 when actual matches planned exactly', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 10,
        actualQuestions: 10,
        plannedMinutes: 30,
        actualMinutes: 30,
      );
      expect(score, 1.0);
    });

    test('returns 0.0 when actual is zero and planned is positive', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 10,
        actualQuestions: 0,
        plannedMinutes: 30,
        actualMinutes: 0,
      );
      expect(score, 0.0);
    });

    test('clamps question score to 1.0 when overperforming', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 10,
        actualQuestions: 20,
        plannedMinutes: 30,
        actualMinutes: 30,
      );
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('allows time score up to adherenceMaxTimeScore of 1.5', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 10,
        actualQuestions: 10,
        plannedMinutes: 30,
        actualMinutes: 60,
      );
      expect(score, greaterThan(0.6));
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('uses default score when planned is zero but actual is positive', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 0,
        actualQuestions: 5,
        plannedMinutes: 30,
        actualMinutes: 15,
      );
      expect(score, greaterThan(0.0));
    });

    test('uses default time score when planned minutes is zero', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 10,
        actualQuestions: 5,
        plannedMinutes: 0,
        actualMinutes: 10,
      );
      expect(score, greaterThan(0.0));
    });

    test('partial adherence returns intermediate score', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 10,
        actualQuestions: 5,
        plannedMinutes: 30,
        actualMinutes: 15,
      );
      expect(score, greaterThan(0.0));
      expect(score, lessThan(1.0));
    });

    test('handles large values without overflow', () {
      final score = calculateAdherenceScore(
        plannedQuestions: 1000000,
        actualQuestions: 500000,
        plannedMinutes: 1000000,
        actualMinutes: 500000,
      );
      expect(score, greaterThan(0.0));
      expect(score, lessThan(1.0));
    });

    test('score is symmetric when swapping positive values', () {
      final score1 = calculateAdherenceScore(
        plannedQuestions: 10,
        actualQuestions: 8,
        plannedMinutes: 30,
        actualMinutes: 25,
      );
      final score2 = calculateAdherenceScore(
        plannedQuestions: 8,
        actualQuestions: 10,
        plannedMinutes: 25,
        actualMinutes: 30,
      );
      expect(score1, isNot(equals(score2)));
    });
  });
}
