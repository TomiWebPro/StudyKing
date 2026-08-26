import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';

void main() {
  group('SpacedRepetitionEngine.scheduleReview', () {
    const engine = SpacedRepetitionEngine();
    final now = DateTime(2026, 1, 1, 12, 0);

    test('a correct first review sets a 1-day interval and increments repetitions',
        () {
      final result = engine.scheduleReview(
        questionId: 'q1',
        grade: 5,
        now: now,
      );

      expect(result.updatedData.repetitions, 1);
      expect(result.updatedData.easeFactor, greaterThan(2.5));
      expect(result.updatedData.previousInterval,
          SpacedRepetitionEngine.initialInterval);
      expect(result.nextReview,
          now.add(SpacedRepetitionEngine.initialInterval));
      expect(result.nextReview.isAfter(now), isTrue);
    });

    test('an incorrect review resets repetitions to 0 and lowers ease factor',
        () {
      final correct = engine.scheduleReview(
        questionId: 'q1',
        grade: 5,
        now: now,
      );
      final easeAfterCorrect = correct.updatedData.easeFactor;

      final incorrect = engine.scheduleReview(
        questionId: 'q1',
        grade: 0,
        currentData: correct.updatedData,
        now: now,
      );

      expect(incorrect.updatedData.repetitions, 0);
      expect(incorrect.updatedData.easeFactor, lessThan(easeAfterCorrect));
      expect(incorrect.updatedData.easeFactor,
          greaterThanOrEqualTo(SpacedRepetitionEngine.minEaseFactor));
    });

    test('ease factor never drops below the configured minimum', () {
      QuestionSRData data = const QuestionSRData(easeFactor: 1.3);
      for (var i = 0; i < 5; i++) {
        data = engine
            .scheduleReview(
              questionId: 'q1',
              grade: 0,
              currentData: data,
              now: now,
            )
            .updatedData;
      }
      expect(data.easeFactor, SpacedRepetitionEngine.minEaseFactor);
    });

    test('correct reviews grow the interval via SM-2 after the second repetition',
        () {
      final first = engine.scheduleReview(
        questionId: 'q1',
        grade: 5,
        now: now,
      );
      expect(first.updatedData.previousInterval,
          SpacedRepetitionEngine.initialInterval);

      final second = engine.scheduleReview(
        questionId: 'q1',
        grade: 5,
        currentData: first.updatedData,
        now: now,
      );
      expect(second.updatedData.previousInterval,
          SpacedRepetitionEngine.secondInterval);
      expect(second.updatedData.repetitions, 2);

      final third = engine.scheduleReview(
        questionId: 'q1',
        grade: 5,
        currentData: second.updatedData,
        now: now,
      );
      // interval = prevInterval * easeFactor (> prevInterval since ease > 1)
      final expectedMs = (SpacedRepetitionEngine.secondInterval.inMilliseconds *
              second.updatedData.easeFactor)
          .round();
      expect(third.updatedData.previousInterval!.inMilliseconds, expectedMs);
      expect(third.updatedData.previousInterval!.inMilliseconds,
          greaterThan(SpacedRepetitionEngine.secondInterval.inMilliseconds));
    });

    test('grades are clamped to the 0-5 range', () {
      final low = engine.scheduleReview(
        questionId: 'q1',
        grade: -10,
        now: now,
      );
      final high = engine.scheduleReview(
        questionId: 'q1',
        grade: 99,
        now: now,
      );
      expect(low.updatedData.repetitions, 0);
      expect(high.updatedData.repetitions, 1);
      expect(low.updatedData.reviewLog.single.grade, 0);
      expect(high.updatedData.reviewLog.single.grade, 5);
    });

    test('a just-reviewed item is not due today', () {
      final result = engine.scheduleReview(
        questionId: 'q1',
        grade: 5,
        now: now,
      );
      expect(engine.isConceptDue([result.updatedData], now: now), isFalse);
    });
  });

  group('SpacedRepetitionEngine.computeRecallProbability', () {
    const engine = SpacedRepetitionEngine();
    final now = DateTime(2026, 1, 1, 12, 0);

    test('returns 1.0 when there is no scheduling data yet', () {
      expect(
          engine.computeRecallProbability(
              data: const QuestionSRData(), now: now),
          1.0);
    });

    test('recall is ~1.0 immediately after review and ~0.5 at the interval', () {
      final data = QuestionSRData(
        repetitions: 1,
        easeFactor: 2.5,
        previousInterval: const Duration(days: 1),
        lastReview: now,
      );
      expect(engine.computeRecallProbability(data: data, now: now), closeTo(1.0, 0.001));

      final elapsed = now.add(const Duration(days: 1));
      expect(engine.computeRecallProbability(data: data, now: elapsed),
          closeTo(0.5, 0.01));
    });
  });

  group('SpacedRepetitionEngine.mapConfidenceToGrade', () {
    const engine = SpacedRepetitionEngine();

    test('maps a correct, high-confidence answer to the top grade', () {
      expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 4), 5);
      expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 5), 5);
    });

    test('maps an incorrect, low-confidence answer to the bottom grade', () {
      expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 1), 0);
      expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 2), 0);
    });
  });

  group('SpacedRepetitionEngine.migrateFromLegacy', () {
    const engine = SpacedRepetitionEngine();
    final now = DateTime(2026, 1, 1, 12, 0);

    test('a far-future legacy next review seeds a strong schedule', () {
      final result = engine.migrateFromLegacy(
        questionId: 'q1',
        legacyNextReview: now.add(const Duration(days: 10)),
        legacyLastReview: now.subtract(const Duration(days: 2)),
        totalAttempts: 3,
        accuracy: 0.9,
        now: now,
      );
      expect(result.updatedData.repetitions, greaterThanOrEqualTo(3));
      expect(result.updatedData.easeFactor, 2.5);
      expect(result.nextReview.isAfter(now), isTrue);
    });

    test('low legacy accuracy resets the schedule', () {
      final result = engine.migrateFromLegacy(
        questionId: 'q1',
        legacyNextReview: now.add(const Duration(days: 10)),
        legacyLastReview: now.subtract(const Duration(days: 2)),
        totalAttempts: 5,
        accuracy: 0.2,
        now: now,
      );
      expect(result.updatedData.repetitions, 0);
      expect(result.updatedData.previousInterval, isNull);
    });
  });

  group('ReviewLogEntry serialization', () {
    test('round-trips through JSON', () {
      final entry = ReviewLogEntry(
        questionId: 'q1',
        timestamp: DateTime(2026, 1, 1),
        grade: 4,
        easeFactor: 2.6,
        interval: const Duration(days: 6),
        nextReview: DateTime(2026, 1, 7),
      );
      final json = entry.toJson();
      final restored = ReviewLogEntry.fromJson(json);
      expect(restored.questionId, entry.questionId);
      expect(restored.grade, entry.grade);
      expect(restored.easeFactor, entry.easeFactor);
      expect(restored.interval, entry.interval);
      expect(restored.nextReview, entry.nextReview);
    });
  });
}
