import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';

void main() {
  group('QuestionMasteryState', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
        );
        expect(state.studentId, 's1');
        expect(state.questionId, 'q1');
        expect(state.correctCount, 0);
        expect(state.incorrectCount, 0);
        expect(state.masteryLevel, 0.0);
        expect(state.reviewUrgency, 1.0);
      });

      test('creates with all fields', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 5,
          incorrectCount: 2,
          currentStreak: 3,
          bestStreak: 5,
          averageTimeMs: 5000,
          confidenceHistory: [4, 5, 3],
          lastAttempt: now,
          lastCorrect: now,
          lastIncorrect: now,
          nextReview: now,
          masteryLevel: 0.8,
          reviewUrgency: 0.3,
          totalTimeMs: 35000,
        );
        expect(state.correctCount, 5);
        expect(state.totalAttempts, 7);
        expect(state.averageConfidence, 4.0);
        expect(state.totalTimeMs, 35000);
      });
    });

    group('QuestionMasteryState.initial', () {
      test('creates initial state', () {
        final state = QuestionMasteryState.initial(studentId: 's1', questionId: 'q1');
        expect(state.studentId, 's1');
        expect(state.questionId, 'q1');
        expect(state.totalAttempts, 0);
        expect(state.accuracy, 0.0);
        expect(state.nextReview, isNotNull);
      });
    });

    group('getters', () {
      test('totalAttempts returns sum', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 3,
          incorrectCount: 2,
          lastAttempt: now,
        );
        expect(state.totalAttempts, 5);
      });

      test('accuracy returns correct ratio', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 7,
          incorrectCount: 3,
          lastAttempt: now,
        );
        expect(state.accuracy, 0.7);
      });

      test('accuracy returns 0 when no attempts', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
        );
        expect(state.accuracy, 0.0);
      });

      test('averageConfidence returns average', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: [3, 4, 5],
          lastAttempt: now,
        );
        expect(state.averageConfidence, 4.0);
      });

      test('averageConfidence returns default when empty', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
        );
        expect(state.averageConfidence, 3.0);
      });
    });

    group('recordAttempt', () {
      final now2 = DateTime(2026, 5, 12, 10, 0, 0);

      /// Creates a test state with mutable confidenceHistory to work around const [] default
      QuestionMasteryState createState(String studentId, String questionId) {
        return QuestionMasteryState(
          studentId: studentId,
          questionId: questionId,
          lastAttempt: now2,
          confidenceHistory: <int>[],
        );
      }

      test('records correct attempt', () {
        final state = createState('s1', 'q1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 5000);

        expect(state.correctCount, 1);
        expect(state.currentStreak, 1);
        expect(state.bestStreak, 1);
        expect(state.confidenceHistory, [4]);
        expect(state.totalTimeMs, 5000);
      });

      test('records incorrect attempt', () {
        final state = createState('s1', 'q1');
        state.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 10000);

        expect(state.incorrectCount, 1);
        expect(state.currentStreak, 0);
        expect(state.bestStreak, 0);
      });

      test('updates streaks correctly', () {
        final state = createState('s1', 'q1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 1000);

        expect(state.correctCount, 3);
        expect(state.incorrectCount, 1);
        expect(state.currentStreak, 1);
        expect(state.bestStreak, 2);
      });

      test('calculates average time', () {
        final state = createState('s1', 'q1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 2000);
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 4000);

        expect(state.totalTimeMs, 6000);
      });
    });

    group('toJson / fromJson', () {
      test('serialization roundtrip', () {
        final original = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 3,
          incorrectCount: 1,
          currentStreak: 2,
          bestStreak: 3,
          averageTimeMs: 3000,
          confidenceHistory: [4, 5, 3],
          lastAttempt: now,
          lastCorrect: now,
          lastIncorrect: now,
          nextReview: now,
          masteryLevel: 0.75,
          reviewUrgency: 0.4,
          totalTimeMs: 12000,
        );
        final json = original.toJson();
        final restored = QuestionMasteryState.fromJson(json);
        expect(restored.studentId, original.studentId);
        expect(restored.questionId, original.questionId);
        expect(restored.correctCount, original.correctCount);
        expect(restored.masteryLevel, original.masteryLevel);
        expect(restored.reviewUrgency, original.reviewUrgency);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
        );
        final copy = state.copyWith(correctCount: 5, masteryLevel: 0.9);
        expect(copy.correctCount, 5);
        expect(copy.masteryLevel, 0.9);
        expect(copy.studentId, 's1');
      });
    });
  });
}
