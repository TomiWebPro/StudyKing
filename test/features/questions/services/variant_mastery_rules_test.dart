import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/questions/services/variant_mastery_rules.dart';

QuestionMasteryState buildMastery({
  required String questionId,
  int correctCount = 0,
  int incorrectCount = 0,
  double masteryLevel = 0.0,
}) {
  final now = DateTime(2026, 1, 1);
  return QuestionMasteryState(
    studentId: 's1',
    questionId: questionId,
    correctCount: correctCount,
    incorrectCount: incorrectCount,
    currentStreak: correctCount,
    bestStreak: correctCount,
    lastAttempt: now,
    masteryLevel: masteryLevel,
  );
}

void main() {
  group('VariantMasteryRules.isConceptMastered', () {
    test('false when no variants attempted', () {
      final masteries = [
        buildMastery(questionId: 'q1'),
        buildMastery(questionId: 'q2'),
      ];
      expect(VariantMasteryRules.isConceptMastered(masteries), isFalse);
    });

    test('false when only one variant attempted', () {
      final masteries = [
        buildMastery(questionId: 'q1', correctCount: 2, incorrectCount: 0),
        buildMastery(questionId: 'q2'),
      ];
      expect(VariantMasteryRules.isConceptMastered(masteries), isFalse);
    });

    test('true when >=2 distinct variants attempted with at least one correct',
        () {
      final masteries = [
        buildMastery(questionId: 'q1', correctCount: 2, incorrectCount: 0),
        buildMastery(questionId: 'q2', correctCount: 1, incorrectCount: 1),
      ];
      expect(VariantMasteryRules.isConceptMastered(masteries), isTrue);
    });

    test('false when two variants attempted but none correct', () {
      final masteries = [
        buildMastery(questionId: 'q1', incorrectCount: 3),
        buildMastery(questionId: 'q2', incorrectCount: 3),
      ];
      expect(VariantMasteryRules.isConceptMastered(masteries), isFalse);
    });

    test('respects custom requiredVariantAttempts', () {
      final masteries = [
        buildMastery(questionId: 'q1', correctCount: 1),
        buildMastery(questionId: 'q2', correctCount: 1),
      ];
      expect(
        VariantMasteryRules.isConceptMastered(
          masteries,
          requiredVariantAttempts: 3,
        ),
        isFalse,
      );
    });
  });

  group('VariantMasteryRules.conceptMasteryLevel', () {
    test('returns 0 when nothing attempted', () {
      final masteries = [buildMastery(questionId: 'q1')];
      expect(VariantMasteryRules.conceptMasteryLevel(masteries), 0.0);
    });

    test('averages attempted variants only', () {
      final masteries = [
        buildMastery(questionId: 'q1', correctCount: 1, masteryLevel: 1.0),
        buildMastery(questionId: 'q2', correctCount: 1, masteryLevel: 0.0),
        buildMastery(questionId: 'q3'),
      ];
      // attempted = q1, q2 -> average 0.5
      expect(
        VariantMasteryRules.conceptMasteryLevel(masteries),
        closeTo(0.5, 1e-9),
      );
    });
  });

  group('VariantMasteryRules.attemptedVariantCount', () {
    test('counts distinct attempted variants', () {
      final masteries = [
        buildMastery(questionId: 'q1', correctCount: 1),
        buildMastery(questionId: 'q2', incorrectCount: 1),
        buildMastery(questionId: 'q3'),
      ];
      expect(
        VariantMasteryRules.attemptedVariantCount(masteries),
        2,
      );
    });
  });
}
