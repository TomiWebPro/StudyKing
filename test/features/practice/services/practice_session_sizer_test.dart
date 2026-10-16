import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/services/practice_session_sizer.dart';

void main() {
  group('PracticeSessionSizer', () {
    group('cappedCount', () {
      test('caps a large backlog at the default cap', () {
        // Reproduces the headline repro from the issue: 200 due questions
        // must not yield a 200-question session.
        expect(PracticeSessionSizer.cappedCount(200), 20);
      });

      test('leaves small totals unchanged', () {
        expect(PracticeSessionSizer.cappedCount(5), 5);
        expect(PracticeSessionSizer.cappedCount(20), 20);
      });

      test('returns 0 when there is nothing to load', () {
        expect(PracticeSessionSizer.cappedCount(0), 0);
        expect(PracticeSessionSizer.cappedCount(-3), 0);
      });

      test('honors an explicit preferred count below the cap', () {
        expect(PracticeSessionSizer.cappedCount(200, preferredCount: 10), 10);
      });

      test('clamps an explicit preferred count to the cap', () {
        expect(PracticeSessionSizer.cappedCount(200, preferredCount: 50), 20);
      });

      test('does not exceed the available total', () {
        expect(PracticeSessionSizer.cappedCount(3, preferredCount: 20), 3);
      });

      test('honors a custom cap', () {
        expect(PracticeSessionSizer.cappedCount(200, cap: 30), 30);
        expect(
          PracticeSessionSizer.cappedCount(200, preferredCount: 25, cap: 30),
          25,
        );
      });
    });

    group('overflowCount', () {
      test('returns the queued remainder for a large backlog', () {
        expect(PracticeSessionSizer.overflowCount(200, 20), 180);
      });

      test('returns 0 when the session took everything', () {
        expect(PracticeSessionSizer.overflowCount(5, 5), 0);
      });

      test('returns 0 when the backlog is smaller than the cap', () {
        expect(PracticeSessionSizer.overflowCount(3, 20), 0);
      });
    });
  });
}
