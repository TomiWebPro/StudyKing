import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/difficulty_controller.dart';

void main() {
  group('DifficultyController', () {
    test('starts at default difficulty 1', () {
      final adapter = DifficultyController();
      expect(adapter.currentDifficulty, 1);
    });

    test('starts at custom initial difficulty', () {
      final adapter = DifficultyController(initialDifficulty: 3);
      expect(adapter.currentDifficulty, 3);
    });

    test('increases difficulty after correct streak threshold', () {
      final adapter = DifficultyController(
        initialDifficulty: 2,
        correctStreakThreshold: 3,
      );

      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.recordResult(true);

      final next = adapter.suggestNextDifficulty();
      expect(next, 3);
    });

    test('decreases difficulty after incorrect streak threshold', () {
      final adapter = DifficultyController(
        initialDifficulty: 3,
        incorrectStreakThreshold: 2,
      );

      adapter.recordResult(false);
      adapter.recordResult(false);

      final next = adapter.suggestNextDifficulty();
      expect(next, 2);
    });

    test('does not change difficulty below threshold', () {
      final adapter = DifficultyController(
        initialDifficulty: 2,
        correctStreakThreshold: 3,
        incorrectStreakThreshold: 2,
      );

      adapter.recordResult(true);
      adapter.recordResult(true);

      final next = adapter.suggestNextDifficulty();
      expect(next, 2);
    });

    test('correct after incorrect resets incorrect streak', () {
      final adapter = DifficultyController(
        initialDifficulty: 3,
        correctStreakThreshold: 3,
        incorrectStreakThreshold: 2,
      );

      adapter.recordResult(false);
      adapter.recordResult(true);
      adapter.recordResult(false);

      final next = adapter.suggestNextDifficulty();
      expect(next, 3);
    });

    test('clamps to min difficulty', () {
      final adapter = DifficultyController(
        initialDifficulty: 1,
        minDifficulty: 1,
        incorrectStreakThreshold: 1,
      );

      adapter.recordResult(false);
      final next = adapter.suggestNextDifficulty();
      expect(next, 1);
    });

    test('clamps to max difficulty', () {
      final adapter = DifficultyController(
        initialDifficulty: 5,
        maxDifficulty: 5,
        correctStreakThreshold: 1,
      );

      adapter.recordResult(true);
      final next = adapter.suggestNextDifficulty();
      expect(next, 5);
    });

    test('reset restores difficulty state', () {
      final adapter = DifficultyController(initialDifficulty: 2);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.suggestNextDifficulty();
      expect(adapter.currentDifficulty, 3);

      adapter.reset();
      expect(adapter.currentDifficulty, 1);
    });

    test('reset with custom difficulty', () {
      final adapter = DifficultyController(initialDifficulty: 2);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.suggestNextDifficulty();

      adapter.reset(initialDifficulty: 4);
      expect(adapter.currentDifficulty, 4);
    });

    test('recordResult resets opposite streak', () {
      final adapter = DifficultyController(incorrectStreakThreshold: 1);

      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 1);
      adapter.recordResult(false);

      expect(adapter.currentDifficulty, 1);
    });

    test('suggestNextDifficulty returns current difficulty', () {
      final adapter = DifficultyController(initialDifficulty: 3);
      expect(adapter.suggestNextDifficulty(), 3);
    });

    group('error-state: edge cases', () {
      test('zero thresholds do not cause division by zero', () {
        final adapter = DifficultyController(
          initialDifficulty: 3,
          correctStreakThreshold: 0,
          incorrectStreakThreshold: 0,
        );
        adapter.recordResult(true);
        expect(adapter.suggestNextDifficulty(), 3);
        adapter.recordResult(false);
        expect(adapter.suggestNextDifficulty(), 3);
      });

      test('negative thresholds are handled gracefully', () {
        final adapter = DifficultyController(
          initialDifficulty: 3,
          correctStreakThreshold: -1,
          incorrectStreakThreshold: -1,
        );
        adapter.recordResult(true);
        adapter.recordResult(false);
        expect(adapter.suggestNextDifficulty(), 3);
      });

      test('very large threshold never triggers change', () {
        final adapter = DifficultyController(
          initialDifficulty: 3,
          correctStreakThreshold: 9999,
          incorrectStreakThreshold: 9999,
        );
        for (var i = 0; i < 100; i++) {
          adapter.recordResult(true);
        }
        expect(adapter.suggestNextDifficulty(), 3);
      });

      test('maxDifficulty less than minDifficulty clamps correctly', () {
        final adapter = DifficultyController(
          initialDifficulty: 5,
          minDifficulty: 5,
          maxDifficulty: 1,
          correctStreakThreshold: 1,
        );
        adapter.recordResult(true);
        final next = adapter.suggestNextDifficulty();
        expect(next, inInclusiveRange(1, 5));
      });

      test('recordResult with alternating results resets streaks', () {
        final adapter = DifficultyController(
          initialDifficulty: 3,
          correctStreakThreshold: 2,
          incorrectStreakThreshold: 2,
        );
        adapter.recordResult(true);
        adapter.recordResult(false);
        adapter.recordResult(true);
        adapter.recordResult(false);
        expect(adapter.suggestNextDifficulty(), 3);
      });

      test('reset does not throw when called with extreme values', () {
        final adapter = DifficultyController();
        adapter.reset(initialDifficulty: -100);
        expect(adapter.currentDifficulty, 1);
        adapter.reset(initialDifficulty: 9999);
        expect(adapter.currentDifficulty, 5);
      });
    });
  });

  group('DifficultyController - coverage gaps', () {
    test('reset with value above max clamps to max', () {
      final adapter = DifficultyController(
        maxDifficulty: 5,
        initialDifficulty: 3,
      );
      adapter.reset(initialDifficulty: 10);
      expect(adapter.currentDifficulty, 5);
    });

    test('reset with value below min clamps to min', () {
      final adapter = DifficultyController(
        minDifficulty: 1,
        initialDifficulty: 3,
      );
      adapter.reset(initialDifficulty: -5);
      expect(adapter.currentDifficulty, 1);
    });

    test('custom min and max boundaries', () {
      final adapter = DifficultyController(
        minDifficulty: 2,
        maxDifficulty: 4,
        initialDifficulty: 3,
        correctStreakThreshold: 1,
        incorrectStreakThreshold: 1,
      );

      adapter.recordResult(true);
      expect(adapter.suggestNextDifficulty(), 4);

      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 3);
    });

    test('consecutive correct after incorrect resets streak', () {
      final adapter = DifficultyController(
        initialDifficulty: 3,
        correctStreakThreshold: 2,
        incorrectStreakThreshold: 2,
      );

      adapter.recordResult(false);
      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 2);

      adapter.recordResult(true);
      adapter.recordResult(true);
      expect(adapter.suggestNextDifficulty(), 3);
    });

    test('suggestNextDifficulty does not change when streaks below thresholds',
        () {
      final adapter = DifficultyController(
        initialDifficulty: 3,
        correctStreakThreshold: 3,
        incorrectStreakThreshold: 3,
      );

      adapter.recordResult(true);
      adapter.recordResult(true);
      expect(adapter.suggestNextDifficulty(), 3);

      adapter.recordResult(false);
      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 3);
    });
  });
}
