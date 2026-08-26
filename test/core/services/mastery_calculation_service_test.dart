import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/services/mastery_calculation_service.dart';

void main() {
  group('MasteryCalculationService', () {
    late MasteryCalculationService service;

    setUp(() {
      service = MasteryCalculationService();
    });

    MasteryState initialState(String topicId) {
      return MasteryState(
        studentId: 's1',
        topicId: topicId,
        lastAttempt: DateTime(2024, 1, 1),
        lastUpdated: DateTime(2024, 1, 1),
      );
    }

    group('recordAttempt', () {
      test('increments totalAttempts and correctAttempts on correct answer', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );

        expect(updated.totalAttempts, 1);
        expect(updated.correctAttempts, 1);
      });

      test('increments only totalAttempts on incorrect answer', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 45000,
        );

        expect(updated.totalAttempts, 1);
        expect(updated.correctAttempts, 0);
      });

      test('updates accuracy correctly', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 20000,
        );

        expect(updated.accuracy, 1.0);
      });

      test('updates accuracy to 0.5 after one correct and one incorrect', () {
        final state = initialState('t1');
        final afterCorrect = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 20000,
        );
        final afterIncorrect = service.recordAttempt(
          current: afterCorrect,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 40000,
        );

        expect(afterIncorrect.accuracy, 0.5);
      });

      test('updates averageTimeMs correctly', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 3,
          timeSpentMs: 60000,
        );

        expect(updated.averageTimeMs, 60000);
      });

      test('updates currentStreak on consecutive correct answers', () {
        final state = initialState('t1');
        final first = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );
        expect(first.currentStreak, 1);

        final second = service.recordAttempt(
          current: first,
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 25000,
        );
        expect(second.currentStreak, 2);
      });

      test('resets currentStreak on incorrect answer', () {
        final state = initialState('t1');
        final first = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );
        final second = service.recordAttempt(
          current: first,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 35000,
        );

        expect(second.currentStreak, 0);
      });

      test('updates bestStreak correctly', () {
        final state = initialState('t1');
        var current = state;
        for (int i = 0; i < 3; i++) {
          current = service.recordAttempt(
            current: current,
            isCorrect: true,
            confidence: 4,
            timeSpentMs: 30000,
          );
        }
        expect(current.bestStreak, 3);

        current = service.recordAttempt(
          current: current,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 35000,
        );
        expect(current.currentStreak, 0);
        expect(current.bestStreak, 3);
      });

      test('adds weak subtopics for incorrect attempts', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: false,
          confidence: 1,
          timeSpentMs: 50000,
          subtopicId: 'algebra-basics',
        );

        expect(updated.weakSubtopics, contains('algebra-basics'));
      });

      test('does not add duplicate weak subtopics', () {
        final state = initialState('t1');
        final first = service.recordAttempt(
          current: state,
          isCorrect: false,
          confidence: 1,
          timeSpentMs: 50000,
          subtopicId: 'algebra-basics',
        );
        final second = service.recordAttempt(
          current: first,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 45000,
          subtopicId: 'algebra-basics',
        );

        expect(second.weakSubtopics.length, 1);
      });

      test('updates mastery level after multiple correct attempts', () {
        var state = initialState('t1');
        for (int i = 0; i < 5; i++) {
          state = service.recordAttempt(
            current: state,
            isCorrect: true,
            confidence: 5,
            timeSpentMs: 20000,
          );
        }

        expect(state.masteryLevel.index, greaterThan(MasteryLevel.novice.index));
      });

      test('updates lastAttempt and lastUpdated timestamps', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 3,
          timeSpentMs: 30000,
        );

        expect(updated.lastAttempt.isAfter(state.lastAttempt), isTrue);
        expect(updated.lastUpdated.isAfter(state.lastUpdated), isTrue);
      });

      test('handles zero confidence gracefully', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 0,
          timeSpentMs: 0,
        );

        expect(updated.totalAttempts, 1);
        expect(updated.correctAttempts, 1);
      });
    });

    group('error handling', () {
      test('handles zero timeSpentMs gracefully', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 3,
          timeSpentMs: 0,
        );
        expect(updated.averageTimeMs, 0.0);
        expect(updated.totalAttempts, 1);
      });

      test('handles zero confidence without crashing', () {
        final state = initialState('t1');
        final updated = service.recordAttempt(
          current: state,
          isCorrect: false,
          confidence: 0,
          timeSpentMs: 10000,
        );
        expect(updated.recentConfidence, contains(0));
      });

      test('updateAccuracy with zero totalAttempts returns 0.0', () {
        final state = initialState('t1');
        expect(state.accuracy, 0.0);
      });

      test('confidenceTrend defaults to 0.5 with no recent data', () {
        final state = initialState('t1');
        expect(state.confidenceTrend, 0.5);
      });
    });

    group('decay / time-based metrics', () {
      test('forgettingRisk and reviewUrgency rise when days pass since lastAttempt', () {
        final past = DateTime.now().subtract(const Duration(days: 10));
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: past,
          lastUpdated: past,
          correctAttempts: 9,
          totalAttempts: 10,
        );

        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );

        final freshState = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: DateTime.now(),
          lastUpdated: DateTime.now(),
          correctAttempts: 9,
          totalAttempts: 10,
        );
        final freshUpdated = service.recordAttempt(
          current: freshState,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );

        expect(updated.forgettingRisk, greaterThan(freshUpdated.forgettingRisk));
        expect(updated.reviewUrgency, greaterThan(freshUpdated.reviewUrgency));
      });

      test('readiness recencyScore is < 1.0 when gap > 0 days', () {
        final past = DateTime.now().subtract(const Duration(days: 5));
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: past,
          lastUpdated: past,
          correctAttempts: 10,
          totalAttempts: 10,
        );

        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 20000,
        );

        expect(updated.readinessScore, lessThan(1.0));
      });

      test('no regression in accuracy and masteryLevel', () {
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: DateTime.now().subtract(const Duration(days: 20)),
          lastUpdated: DateTime.now().subtract(const Duration(days: 20)),
          correctAttempts: 9,
          totalAttempts: 10,
        );

        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 20000,
        );

        expect(updated.accuracy, 10 / 11);
        expect(updated.masteryLevel, MasteryLevel.proficient);
      });
    });

    group('initial state transitions', () {
      test('novice with no attempts', () {
        final state = initialState('t1');
        expect(state.masteryLevel, MasteryLevel.novice);
        expect(state.accuracy, 0.0);
        expect(state.totalAttempts, 0);
      });
    });
  });
}
