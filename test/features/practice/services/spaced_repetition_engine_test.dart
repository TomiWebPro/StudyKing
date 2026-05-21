import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';

void main() {
  group('SpacedRepetitionEngine', () {
    late SpacedRepetitionEngine engine;

    setUp(() {
      engine = SpacedRepetitionEngine();
    });

    group('scheduleReview - SM-2 algorithm', () {
      test('grade >= 3 with 0 repetitions sets 1-day interval', () {
        final now = DateTime(2026, 5, 16);
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 3,
          currentData: const QuestionSRData(),
          now: now,
        );

        expect(result.updatedData.repetitions, 1);
        expect(result.updatedData.easeFactor, closeTo(2.36, 0.01));
        expect(
          result.nextReview.difference(now).inDays,
          1,
        );
      });

      test('grade >= 3 with 1 repetition sets 6-day interval', () {
        final previousData = const QuestionSRData(
          repetitions: 1,
          easeFactor: 2.5,
          previousInterval: Duration(days: 1),
        );

        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 4,
          currentData: previousData,
        );

        expect(result.updatedData.repetitions, 2);
        expect(
          result.nextReview.difference(DateTime.now()).inDays,
          greaterThanOrEqualTo(5),
        );
      });

      test('grade >= 3 with 2+ repetitions multiplies by ease factor', () {
        final previousData = QuestionSRData(
          repetitions: 2,
          easeFactor: 2.5,
          previousInterval: const Duration(days: 6),
        );

        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 4,
          currentData: previousData,
        );

        expect(result.updatedData.repetitions, 3);
        final expectedInterval = (6 * 2.5).round();
        expect(
          result.nextReview.difference(DateTime.now()).inDays,
          greaterThanOrEqualTo(expectedInterval - 1),
        );
      });

      test('grade < 3 resets repetitions to 0', () {
        final previousData = QuestionSRData(
          repetitions: 5,
          easeFactor: 2.5,
          previousInterval: const Duration(days: 30),
        );

        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 1,
          currentData: previousData,
        );

        expect(result.updatedData.repetitions, 0);
        expect(
          result.nextReview.difference(DateTime.now()).inDays,
          lessThanOrEqualTo(2),
        );
      });

      test('grade < 3 sets 1-day interval', () {
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 0,
          currentData: const QuestionSRData(),
        );

        expect(result.updatedData.repetitions, 0);
        expect(
          result.nextReview.difference(DateTime.now()).inDays,
          lessThanOrEqualTo(2),
        );
      });

      test('ease factor never goes below 1.3', () {
        final previousData = QuestionSRData(
          repetitions: 0,
          easeFactor: 1.3,
        );

        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 0,
          currentData: previousData,
        );

        expect(result.updatedData.easeFactor, greaterThanOrEqualTo(1.3));
      });

      test('grade 5 increases ease factor', () {
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 5,
          currentData: const QuestionSRData(easeFactor: 2.5),
        );

        expect(result.updatedData.easeFactor, greaterThan(2.5));
      });

      test('grade 0 decreases ease factor', () {
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 0,
          currentData: const QuestionSRData(easeFactor: 2.5),
        );

        expect(result.updatedData.easeFactor, lessThan(2.5));
      });

      test('review log stores all entries', () {
        final previousData = QuestionSRData(
          repetitions: 1,
          easeFactor: 2.5,
          previousInterval: const Duration(days: 1),
        );

        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 4,
          currentData: previousData,
        );

        expect(result.updatedData.reviewLog, hasLength(1));
        expect(result.updatedData.reviewLog.last.grade, 4);
        expect(result.updatedData.reviewLog.last.questionId, 'q1');
      });

      test('grade clamped to 0-5 range', () {
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 10,
        );

        expect(result.updatedData.reviewLog.last.grade, 5);

        final result2 = engine.scheduleReview(
          questionId: 'q1',
          grade: -1,
        );

        expect(result2.updatedData.reviewLog.last.grade, 0);
      });
    });

    group('migrateFromLegacy', () {
      test('converts legacy 7-day interval to SM-2', () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 7));

        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 5,
          accuracy: 0.9,
          now: now,
        );

        expect(result.updatedData.repetitions, greaterThanOrEqualTo(3));
        expect(result.updatedData.easeFactor, 2.5);
      });

      test('handles null legacy next review', () {
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: null,
          legacyLastReview: null,
          totalAttempts: 0,
          accuracy: 0.0,
        );

        expect(result.updatedData.repetitions, 0);
        expect(result.updatedData.easeFactor, 2.5);
      });

      test('resets repetitions for low accuracy', () {
        final legacyNextReview =
            DateTime.now().add(const Duration(days: 7));

        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: DateTime.now().subtract(const Duration(days: 1)),
          totalAttempts: 10,
          accuracy: 0.3,
        );

        expect(result.updatedData.repetitions, 0);
      });
    });

    group('mapConfidenceToGrade', () {
      test('correct with high confidence maps to grade 5', () {
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 5), 5);
      });

      test('correct with medium confidence maps to grade 4', () {
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 3), 4);
      });

      test('correct with low confidence maps to grade 3', () {
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 1), 3);
      });

      test('incorrect with low confidence maps to grade 0', () {
        expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 1), 0);
      });

      test('incorrect with medium confidence maps to grade 1', () {
        expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 3), 1);
      });

      test('incorrect with high confidence maps to grade 2', () {
        expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 5), 2);
      });
    });

    group('computeRecallProbability', () {
      test('returns 1.0 for data with no last review', () {
        final prob = engine.computeRecallProbability(
          data: const QuestionSRData(),
        );
        expect(prob, 1.0);
      });

      test('returns high probability for recent review', () {
        final data = QuestionSRData(
          lastReview: DateTime.now(),
          previousInterval: const Duration(days: 7),
        );
        final prob = engine.computeRecallProbability(data: data);
        expect(prob, greaterThan(0.8));
      });

      test('returns low probability for old review', () {
        final data = QuestionSRData(
          lastReview: DateTime.now().subtract(const Duration(days: 30)),
          previousInterval: const Duration(days: 1),
        );
        final prob = engine.computeRecallProbability(data: data);
        expect(prob, lessThan(0.1));
      });
    });

    group('edge cases', () {
      test('handles grade 3 exactly (barely passing)', () {
        final result = engine.scheduleReview(questionId: 'q1', grade: 3);
        expect(result.updatedData.repetitions, 1);
      });

      test('handles grade 2 exactly (barely failing)', () {
        final result = engine.scheduleReview(questionId: 'q1', grade: 2);
        expect(result.updatedData.repetitions, 0);
      });

      test('ease factor floors correctly', () {
        final data = QuestionSRData(easeFactor: 1.3);
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 0,
          currentData: data,
        );
        expect(result.updatedData.easeFactor, 1.3);
      });

      test('reviewLog toJson roundtrip', () {
        final entry = ReviewLogEntry(
          questionId: 'q1',
          timestamp: DateTime(2026, 1, 1),
          grade: 4,
          easeFactor: 2.5,
          interval: const Duration(days: 6),
          nextReview: DateTime(2026, 1, 7),
        );

        final json = entry.toJson();
        final restored = ReviewLogEntry.fromJson(json);

        expect(restored.questionId, 'q1');
        expect(restored.grade, 4);
        expect(restored.easeFactor, 2.5);
      });
    });
  });

  group('SpacedRepetitionEngine - coverage gaps', () {
    late SpacedRepetitionEngine engine;

    setUp(() {
      engine = SpacedRepetitionEngine();
    });

    group('mapConfidenceToGrade complete coverage', () {
      test('correct confidence 2 maps to grade 3', () {
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 2), 3);
      });

      test('correct confidence 4 maps to grade 5', () {
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 4), 5);
      });

      test('incorrect confidence 2 maps to grade 0', () {
        expect(
            engine.mapConfidenceToGrade(isCorrect: false, confidence: 2), 0);
      });

      test('incorrect confidence 4 maps to grade 2', () {
        expect(
            engine.mapConfidenceToGrade(isCorrect: false, confidence: 4), 2);
      });

      test('default confidence returns fallback grade', () {
        // For correct with out-of-range confidence, default is 4
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 99), 4);
        // For incorrect with confidence <= 2, grade is 0 (not the default branch)
        expect(
            engine.mapConfidenceToGrade(isCorrect: false, confidence: 0), 0);
      });
    });

    group('QuestionSRData copyWith', () {
      test('copyWith with clearPreviousInterval clears the field', () {
        const data = QuestionSRData(
          previousInterval: Duration(days: 6),
          lastReview: null,
        );
        final updated = data.copyWith(clearPreviousInterval: true);
        expect(updated.previousInterval, isNull);
      });

      test('copyWith with explicit previousInterval overrides', () {
        const data = QuestionSRData(previousInterval: Duration(days: 6));
        final updated =
            data.copyWith(previousInterval: const Duration(days: 10));
        expect(updated.previousInterval, const Duration(days: 10));
      });

      test('copyWith with null previousInterval keeps original', () {
        const data = QuestionSRData(previousInterval: Duration(days: 6));
        final updated = data.copyWith();
        expect(updated.previousInterval, const Duration(days: 6));
      });

      test('copyWith reviewLog replacement', () {
        const data = QuestionSRData(reviewLog: []);
        final entry = ReviewLogEntry(
          questionId: 'q1',
          timestamp: DateTime(2026, 1, 1),
          grade: 4,
          easeFactor: 2.5,
          interval: const Duration(days: 1),
          nextReview: DateTime(2026, 1, 2),
        );
        final updated = data.copyWith(reviewLog: [entry]);
        expect(updated.reviewLog, hasLength(1));
        expect(updated.reviewLog.first.grade, 4);
      });
    });

    group('computeRecallProbability edges', () {
      test('returns 1.0 when interval is zero', () {
        final data = QuestionSRData(
          lastReview: DateTime.now().subtract(const Duration(days: 30)),
          previousInterval: Duration.zero,
        );
        expect(engine.computeRecallProbability(data: data), 1.0);
      });

      test('returns 1.0 when lastReview is null', () {
        const data = QuestionSRData(previousInterval: Duration(days: 7));
        expect(engine.computeRecallProbability(data: data), 1.0);
      });

      test('returns 1.0 when previousInterval is null', () {
        final data = QuestionSRData(lastReview: DateTime.now());
        expect(engine.computeRecallProbability(data: data), 1.0);
      });
    });

    group('scheduleReview edge cases', () {
      test('handles null currentData by using defaults', () {
        final result = engine.scheduleReview(questionId: 'q1', grade: 4);
        expect(result.updatedData.repetitions, 1);
        expect(result.updatedData.easeFactor, closeTo(2.5, 0.01));
      });

      test('review log accumulates across calls', () {
        final data = QuestionSRData(
          repetitions: 1,
          easeFactor: 2.5,
          previousInterval: const Duration(days: 1),
          reviewLog: [
            ReviewLogEntry(
              questionId: 'q1',
              timestamp: DateTime(2026, 1, 1),
              grade: 4,
              easeFactor: 2.5,
              interval: const Duration(days: 1),
              nextReview: DateTime(2026, 1, 2),
            ),
          ],
        );
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 4,
          currentData: data,
        );
        expect(result.updatedData.reviewLog, hasLength(2));
      });
    });

    group('migrateFromLegacy branch coverage', () {
      test('legacy interval 3-7 days sets repetitions to max(2, ~attempts/2)',
          () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 4));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 5,
          accuracy: 0.9,
          now: now,
        );
        expect(result.updatedData.repetitions,
            greaterThanOrEqualTo(2));
        expect(result.updatedData.easeFactor, 2.2);
      });

      test('legacy interval 1-3 days sets repetitions to max(1, ~attempts/3)',
          () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 2));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 6,
          accuracy: 0.9,
          now: now,
        );
        expect(result.updatedData.repetitions,
            greaterThanOrEqualTo(1));
        expect(result.updatedData.easeFactor, 2.0);
      });

      test('legacy interval < 1 day resets to 0', () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(hours: 12));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 10,
          accuracy: 0.9,
          now: now,
        );
        expect(result.updatedData.repetitions, 0);
      });
    });
  });
}
