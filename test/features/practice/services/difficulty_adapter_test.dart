import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/services/difficulty_adapter.dart';

void main() {
  group('DifficultyAdapter', () {
    test('starts at default difficulty 1', () {
      final adapter = DifficultyAdapter();
      expect(adapter.currentDifficulty, 1);
    });

    test('starts at custom initial difficulty', () {
      final adapter = DifficultyAdapter(initialDifficulty: 3);
      expect(adapter.currentDifficulty, 3);
    });

    test('increases difficulty after correct streak threshold', () {
      final adapter = DifficultyAdapter(
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
      final adapter = DifficultyAdapter(
        initialDifficulty: 3,
        incorrectStreakThreshold: 2,
      );

      adapter.recordResult(false);
      adapter.recordResult(false);

      final next = adapter.suggestNextDifficulty();
      expect(next, 2);
    });

    test('does not change difficulty below threshold', () {
      final adapter = DifficultyAdapter(
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
      final adapter = DifficultyAdapter(
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
      final adapter = DifficultyAdapter(
        initialDifficulty: 1,
        minDifficulty: 1,
        incorrectStreakThreshold: 1,
      );

      adapter.recordResult(false);
      final next = adapter.suggestNextDifficulty();
      expect(next, 1);
    });

    test('clamps to max difficulty', () {
      final adapter = DifficultyAdapter(
        initialDifficulty: 5,
        maxDifficulty: 5,
        correctStreakThreshold: 1,
      );

      adapter.recordResult(true);
      final next = adapter.suggestNextDifficulty();
      expect(next, 5);
    });

    test('reset restores difficulty state', () {
      final adapter = DifficultyAdapter(initialDifficulty: 2);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.suggestNextDifficulty();
      expect(adapter.currentDifficulty, 3);

      adapter.reset();
      expect(adapter.currentDifficulty, 1);
    });

    test('reset with custom difficulty', () {
      final adapter = DifficultyAdapter(initialDifficulty: 2);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.recordResult(true);
      adapter.suggestNextDifficulty();

      adapter.reset(initialDifficulty: 4);
      expect(adapter.currentDifficulty, 4);
    });

    test('recordResult resets opposite streak', () {
      final adapter = DifficultyAdapter(incorrectStreakThreshold: 1);

      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 1);
      adapter.recordResult(false);

      expect(adapter.currentDifficulty, 1);
    });

    test('suggestNextDifficulty returns current difficulty', () {
      final adapter = DifficultyAdapter(initialDifficulty: 3);
      expect(adapter.suggestNextDifficulty(), 3);
    });
  });
}
