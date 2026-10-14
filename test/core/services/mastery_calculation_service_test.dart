import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/services/mastery_calculation_service.dart';
import 'package:studyking/core/utils/clock.dart';

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

    group('DST calendar-day arithmetic', () {
      test('reviewUrgency and forgettingRisk count calendar days, not '
          'elapsed 24h periods, across a spring-forward-like 23h span', () {
        // Fri 2026-03-27 23:00 -> Sat 2026-03-28 22:00 spans 23h
        // when a DST spring-forward (a 23h calendar day) falls inside
        // the window: 1 calendar day, but 0 elapsed days. Elapsed-time
        // inDays would treat the attempt as if it happened today.
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: DateTime(2026, 3, 27, 23),
          lastUpdated: DateTime(2026, 3, 27, 23),
        );
        final service = MasteryCalculationService(
          clock: _FixedClock(DateTime(2026, 3, 28, 22)),
        );
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );

        // 1 calendar day since the last attempt: urgency bucket 1 (0.3),
        // not the same-day bucket (0.1).
        expect(updated.reviewUrgency, closeTo(0.3, 1e-9));
        // Forgetting-risk decay runs over 1 calendar day, not 0:
        // accuracy is 1.0, so the risk is 1 - (1 - 1/30) = 1/30.
        expect(updated.forgettingRisk, closeTo(1 / 30, 1e-9));
      });

      test('day counts use calendar days across a spring-forward-like '
          '49h span', () {
        // Fri 2026-03-27 23:00 -> Mon 2026-03-30 01:00 spans 49h
        // with a spring-forward inside the window: 3 calendar days,
        // but only 2 elapsed days.
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: DateTime(2026, 3, 27, 23),
          lastUpdated: DateTime(2026, 3, 27, 23),
        );
        final service = MasteryCalculationService(
          clock: _FixedClock(DateTime(2026, 3, 30, 1)),
        );
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );

        // 3 calendar days: forgetting risk 1 - (1 - 3/30) = 0.1,
        // urgency bucket <= 3: 0.5 + 0.1 * 0.2 = 0.52.
        expect(updated.forgettingRisk, closeTo(0.1, 1e-9));
        expect(updated.reviewUrgency, closeTo(0.52, 1e-9));
      });

      test('day counts use calendar days across a fall-back-like 51h span',
          () {
        // Sat 2026-10-24 23:00 -> Mon 2026-10-27 01:00 spans 51h
        // with a fall-back (a 25h calendar day) inside the window:
        // still 3 calendar days, 2 elapsed days.
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: DateTime(2026, 10, 24, 23),
          lastUpdated: DateTime(2026, 10, 24, 23),
        );
        final service = MasteryCalculationService(
          clock: _FixedClock(DateTime(2026, 10, 27, 1)),
        );
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );

        expect(updated.forgettingRisk, closeTo(0.1, 1e-9));
        expect(updated.reviewUrgency, closeTo(0.52, 1e-9));
      });

      test('same calendar day counts as zero days', () {
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: DateTime(2026, 3, 28, 8),
          lastUpdated: DateTime(2026, 3, 28, 8),
        );
        final service = MasteryCalculationService(
          clock: _FixedClock(DateTime(2026, 3, 28, 22)),
        );
        final updated = service.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 30000,
        );

        expect(updated.reviewUrgency, closeTo(0.1, 1e-9));
        expect(updated.forgettingRisk, 0.0);
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

class _FixedClock implements Clock {
  _FixedClock(this.fixed);

  final DateTime fixed;

  @override
  DateTime now() => fixed;
}
