import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/practice/presentation/screens/practice_screen.dart';

/// True when the local zone observes the 2026-03-29 spring-forward
/// (a 23h day), e.g. Europe/Berlin. The DST regression tests below
/// can only reproduce the elapsed-time bug under such a zone; in
/// zones without the transition they are skipped.
bool _zoneObservesBerlinSpringForward() {
  return DateTime(2026, 3, 30).difference(DateTime(2026, 3, 29)) ==
      const Duration(hours: 23);
}

/// True when the local zone observes the 2026-10-25 fall-back
/// (a 25h day), e.g. Europe/Berlin.
bool _zoneObservesBerlinFallBack() {
  return DateTime(2026, 10, 26).difference(DateTime(2026, 10, 25)) ==
      const Duration(hours: 25);
}

Session _sessionOn(int day, {bool completed = true}) => Session(
      id: 's$day',
      studentId: 'student',
      startTime: DateTime(2026, 3, day, 10, 0),
      completed: completed,
    );

MasteryState _masteryOn(int day) => MasteryState(
      studentId: 'student',
      topicId: 't$day',
      lastAttempt: DateTime(2026, 3, day, 10, 0),
      lastUpdated: DateTime(2026, 3, day, 10, 0),
    );

void main() {
  group('computePracticeStreak', () {
    test('counts activity on the spring-forward transition day', () {
      // Europe/Berlin springs forward on 2026-03-29, so that
      // calendar day is 23h long. Walking back from the 2026-03-31
      // midnight with elapsed-time arithmetic (Duration(days: i))
      // lands on 2026-03-28 23:00 for i = 2, so the transition
      // day was never tested and the streak broke one day early
      // (reported 2 instead of 3).
      if (!_zoneObservesBerlinSpringForward()) return;
      final sessions = [
        for (final day in [29, 30, 31]) _sessionOn(day),
      ];
      expect(
        computePracticeStreak(
          now: DateTime(2026, 3, 31, 12, 0),
          sessions: sessions,
          allMastery: const [],
        ),
        3,
      );
    });

    test('does not count through the spring-forward day when it had no activity',
        () {
      // The reverse direction: activity on 2026-03-28 but NOT on the
      // transition day. The correct streak is 2 (03-31, 03-30). The
      // elapsed-time walk landed i = 2 on 2026-03-28 23:00, matched
      // the 03-28 session, and overcounted to 3.
      if (!_zoneObservesBerlinSpringForward()) return;
      final sessions = [
        _sessionOn(28),
        _sessionOn(30),
        _sessionOn(31),
      ];
      expect(
        computePracticeStreak(
          now: DateTime(2026, 3, 31, 12, 0),
          sessions: sessions,
          allMastery: const [],
        ),
        2,
      );
    });

    test('counts mastery attempts as activity across the transition', () {
      if (!_zoneObservesBerlinSpringForward()) return;
      final allMastery = [
        for (final day in [29, 30, 31]) _masteryOn(day),
      ];
      expect(
        computePracticeStreak(
          now: DateTime(2026, 3, 31, 12, 0),
          sessions: const [],
          allMastery: allMastery,
        ),
        3,
      );
    });

    test('counts activity on the fall-back transition day', () {
      // Europe/Berlin falls back on 2026-10-25 (25h day). The
      // elapsed-time walk happens to land on 01:00 of the intended
      // day there, but the calendar walk must keep counting it too.
      if (!_zoneObservesBerlinFallBack()) return;
      final sessions = [
        for (final day in [25, 26, 27])
          Session(
            id: 's$day',
            studentId: 'student',
            startTime: DateTime(2026, 10, day, 10, 0),
            completed: true,
          ),
      ];
      expect(
        computePracticeStreak(
          now: DateTime(2026, 10, 27, 12, 0),
          sessions: sessions,
          allMastery: const [],
        ),
        3,
      );
    });

    test('breaks the streak on the first day without activity', () {
      final sessions = [_sessionOn(30), _sessionOn(31)];
      expect(
        computePracticeStreak(
          now: DateTime(2026, 3, 31, 12, 0),
          sessions: sessions,
          allMastery: const [],
        ),
        2,
      );
    });

    test('today-only streak is 1', () {
      final sessions = [_sessionOn(31)];
      expect(
        computePracticeStreak(
          now: DateTime(2026, 3, 31, 12, 0),
          sessions: sessions,
          allMastery: const [],
        ),
        1,
      );
    });

    test('no activity yields 0', () {
      expect(
        computePracticeStreak(
          now: DateTime(2026, 3, 31, 12, 0),
          sessions: const [],
          allMastery: const [],
        ),
        0,
      );
    });

    test('incomplete sessions do not count', () {
      final sessions = [_sessionOn(31, completed: false)];
      expect(
        computePracticeStreak(
          now: DateTime(2026, 3, 31, 12, 0),
          sessions: sessions,
          allMastery: const [],
        ),
        0,
      );
    });
  });
}
