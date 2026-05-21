import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';

void main() {
  group('QuestionMasteryState', () {
    final baseTime = DateTime(2025, 1, 15, 10, 0, 0);

    test('initial factory creates state with defaults', () {
      final state = QuestionMasteryState.initial(
        studentId: 'stu1',
        questionId: 'q1',
        now: baseTime,
      );
      expect(state.studentId, 'stu1');
      expect(state.questionId, 'q1');
      expect(state.correctCount, 0);
      expect(state.incorrectCount, 0);
      expect(state.masteryLevel, 0.0);
    });

    test('totalAttempts returns sum of correct and incorrect', () {
      final state = QuestionMasteryState(
        studentId: 'stu1',
        questionId: 'q1',
        correctCount: 5,
        incorrectCount: 3,
        lastAttempt: baseTime,
      );
      expect(state.totalAttempts, 8);
    });

    test('accuracy returns correct ratio', () {
      final state = QuestionMasteryState(
        studentId: 'stu1',
        questionId: 'q1',
        correctCount: 7,
        incorrectCount: 3,
        lastAttempt: baseTime,
      );
      expect(state.accuracy, closeTo(0.7, 0.001));
    });

    test('accuracy returns 0 when no attempts', () {
      final state = QuestionMasteryState.initial(
        studentId: 'stu1',
        questionId: 'q1',
        now: baseTime,
      );
      expect(state.accuracy, 0.0);
    });

    test('averageConfidence returns mean of history', () {
      final state = QuestionMasteryState(
        studentId: 'stu1',
        questionId: 'q1',
        confidenceHistory: [3, 4, 5],
        lastAttempt: baseTime,
      );
      expect(state.averageConfidence, 4.0);
    });

    test('averageConfidence defaults to 3.0 when history empty', () {
      final state = QuestionMasteryState.initial(
        studentId: 'stu1',
        questionId: 'q1',
        now: baseTime,
      );
      expect(state.averageConfidence, 3.0);
    });

    group('recordAttempt', () {
      test('records a correct attempt', () {
        final state = QuestionMasteryState.initial(
          studentId: 'stu1',
          questionId: 'q1',
          now: baseTime,
        );

        final updated = state.recordAttempt(
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
          now: baseTime.add(const Duration(minutes: 5)),
        );

        expect(updated.correctCount, 1);
        expect(updated.incorrectCount, 0);
        expect(updated.currentStreak, 1);
        expect(updated.bestStreak, 1);
      });

      test('records an incorrect attempt', () {
        final state = QuestionMasteryState.initial(
          studentId: 'stu1',
          questionId: 'q1',
          now: baseTime,
        );

        final updated = state.recordAttempt(
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 45000,
          now: baseTime.add(const Duration(minutes: 5)),
        );

        expect(updated.correctCount, 0);
        expect(updated.incorrectCount, 1);
        expect(updated.currentStreak, 0);
      });

      test('resets streak on incorrect', () {
        final state = QuestionMasteryState(
          studentId: 'stu1',
          questionId: 'q1',
          correctCount: 3,
          currentStreak: 3,
          bestStreak: 5,
          lastAttempt: baseTime,
        );

        final updated = state.recordAttempt(
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 20000,
          now: baseTime.add(const Duration(minutes: 5)),
        );

        expect(updated.currentStreak, 0);
        expect(updated.bestStreak, 5);
      });

      test('updates averageTimeMs correctly', () {
        final state = QuestionMasteryState.initial(
          studentId: 'stu1',
          questionId: 'q1',
          now: baseTime,
        );

        final updated = state.recordAttempt(
          isCorrect: true,
          confidence: 3,
          timeSpentMs: 60000,
          now: baseTime.add(const Duration(minutes: 5)),
        );

        expect(updated.averageTimeMs, 60000);
        expect(updated.totalTimeMs, 60000);
      });

      test('updates mastery level on correct attempt', () {
        final state = QuestionMasteryState.initial(
          studentId: 'stu1',
          questionId: 'q1',
          now: baseTime,
        );

        final updated = state.recordAttempt(
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 10000,
          now: baseTime.add(const Duration(seconds: 30)),
        );

        expect(updated.masteryLevel, greaterThan(0.0));
      });

      test('accepts sm2NextReview parameter', () {
        final state = QuestionMasteryState.initial(
          studentId: 'stu1',
          questionId: 'q1',
          now: baseTime,
        );

        final futureDate = baseTime.add(const Duration(days: 7));
        final updated = state.recordAttempt(
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 15000,
          now: baseTime.add(const Duration(minutes: 2)),
          sm2NextReview: futureDate,
        );

        expect(updated.nextReview, futureDate);
      });
    });

    group('serialization', () {
      test('toJson and fromJson round-trip', () {
        final state = QuestionMasteryState(
          studentId: 'stu1',
          questionId: 'q1',
          correctCount: 10,
          incorrectCount: 2,
          currentStreak: 5,
          bestStreak: 8,
          averageTimeMs: 25000,
          confidenceHistory: [3, 4, 5, 4],
          lastAttempt: baseTime,
          lastCorrect: baseTime.add(const Duration(hours: 1)),
          lastIncorrect: baseTime.add(const Duration(hours: 2)),
          nextReview: baseTime.add(const Duration(days: 3)),
          masteryLevel: 0.85,
          reviewUrgency: 0.2,
          totalTimeMs: 300000,
        );

        final json = state.toJson();
        final restored = QuestionMasteryState.fromJson(json);

        expect(restored.studentId, state.studentId);
        expect(restored.questionId, state.questionId);
        expect(restored.correctCount, state.correctCount);
        expect(restored.incorrectCount, state.incorrectCount);
        expect(restored.currentStreak, state.currentStreak);
        expect(restored.bestStreak, state.bestStreak);
        expect(restored.averageTimeMs, state.averageTimeMs);
        expect(restored.confidenceHistory, state.confidenceHistory);
        expect(restored.lastAttempt, state.lastAttempt);
        expect(restored.lastCorrect, state.lastCorrect);
        expect(restored.lastIncorrect, state.lastIncorrect);
        expect(restored.nextReview, state.nextReview);
        expect(restored.masteryLevel, state.masteryLevel);
        expect(restored.reviewUrgency, state.reviewUrgency);
        expect(restored.totalTimeMs, state.totalTimeMs);
      });

      test('toJson and fromJson round-trip with null optionals', () {
        final state = QuestionMasteryState.initial(
          studentId: 'stu1',
          questionId: 'q1',
          now: baseTime,
        );

        final json = state.toJson();
        final restored = QuestionMasteryState.fromJson(json);

        expect(restored.studentId, 'stu1');
        expect(restored.correctCount, 0);
        expect(restored.lastCorrect, isNull);
        expect(restored.lastIncorrect, isNull);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final state = QuestionMasteryState.initial(
          studentId: 'stu1',
          questionId: 'q1',
          now: baseTime,
        );

        final updated = state.copyWith(
          correctCount: 5,
          masteryLevel: 0.9,
        );

        expect(updated.correctCount, 5);
        expect(updated.masteryLevel, 0.9);
        expect(updated.studentId, 'stu1');
      });

      test('retains unspecified fields', () {
        final state = QuestionMasteryState(
          studentId: 'stu1',
          questionId: 'q1',
          correctCount: 3,
          incorrectCount: 1,
          lastAttempt: baseTime,
        );

        final updated = state.copyWith(correctCount: 5);
        expect(updated.incorrectCount, 1);
        expect(updated.lastAttempt, baseTime);
      });
    });
  });
}
