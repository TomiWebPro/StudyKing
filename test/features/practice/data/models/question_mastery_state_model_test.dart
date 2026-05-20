import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';

void main() {
  group('QuestionMasteryState', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final now = DateTime(2026, 5, 12);
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
        );

        expect(state.studentId, 's1');
        expect(state.questionId, 'q1');
        expect(state.lastAttempt, now);
        expect(state.correctCount, 0);
        expect(state.incorrectCount, 0);
        expect(state.masteryLevel, 0.0);
        expect(state.reviewUrgency, 1.0);
      });

      test('accepts all optional fields', () {
        final now = DateTime(2026, 5, 12);
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 8,
          incorrectCount: 2,
          currentStreak: 5,
          bestStreak: 8,
          averageTimeMs: 30000.0,
          confidenceHistory: [3, 4, 5],
          lastAttempt: now,
          lastCorrect: now.subtract(const Duration(hours: 1)),
          lastIncorrect: now.subtract(const Duration(hours: 24)),
          nextReview: now.add(const Duration(days: 3)),
          masteryLevel: 0.8,
          reviewUrgency: 0.2,
          totalTimeMs: 300000,
        );

        expect(state.correctCount, 8);
        expect(state.incorrectCount, 2);
        expect(state.currentStreak, 5);
        expect(state.bestStreak, 8);
        expect(state.averageTimeMs, 30000.0);
        expect(state.confidenceHistory, [3, 4, 5]);
        expect(state.lastCorrect, now.subtract(const Duration(hours: 1)));
        expect(state.lastIncorrect, now.subtract(const Duration(hours: 24)));
        expect(state.nextReview, now.add(const Duration(days: 3)));
        expect(state.masteryLevel, 0.8);
        expect(state.reviewUrgency, 0.2);
        expect(state.totalTimeMs, 300000);
      });
    });

    group('QuestionMasteryState.initial', () {
      test('creates initial state with given ids', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final state = QuestionMasteryState.initial(
          studentId: 's1',
          questionId: 'q1',
          now: DateTime.now(),
        );
        final after = DateTime.now().add(const Duration(seconds: 1));

        expect(state.studentId, 's1');
        expect(state.questionId, 'q1');
        expect(state.correctCount, 0);
        expect(state.incorrectCount, 0);
        expect(state.masteryLevel, 0.0);
        expect(state.reviewUrgency, 1.0);
        expect(state.lastAttempt.isAfter(before), isTrue);
        expect(state.lastAttempt.isBefore(after), isTrue);
        expect(state.nextReview, isNotNull);
      });
    });

    group('computed getters', () {
      group('totalAttempts', () {
        test('returns sum of correct and incorrect counts', () {
          final state = QuestionMasteryState(
            studentId: 's1',
            questionId: 'q1',
            correctCount: 7,
            incorrectCount: 3,
            lastAttempt: DateTime(2026, 5, 12),
          );

          expect(state.totalAttempts, 10);
        });

        test('returns 0 when no attempts', () {
          final state = QuestionMasteryState.initial(
            studentId: 's1',
            questionId: 'q1',
            now: DateTime.now(),
          );

          expect(state.totalAttempts, 0);
        });
      });

      group('accuracy', () {
        test('returns correct ratio', () {
          final state = QuestionMasteryState(
            studentId: 's1',
            questionId: 'q1',
            correctCount: 7,
            incorrectCount: 3,
            lastAttempt: DateTime(2026, 5, 12),
          );

          expect(state.accuracy, 0.7);
        });

        test('returns 0.0 when no attempts', () {
          final state = QuestionMasteryState.initial(
            studentId: 's1',
            questionId: 'q1',
            now: DateTime.now(),
          );

          expect(state.accuracy, 0.0);
        });

        test('returns 1.0 when perfect score', () {
          final state = QuestionMasteryState(
            studentId: 's1',
            questionId: 'q1',
            correctCount: 10,
            incorrectCount: 0,
            lastAttempt: DateTime(2026, 5, 12),
          );

          expect(state.accuracy, 1.0);
        });
      });

      group('averageConfidence', () {
        test('returns average of confidence history', () {
          final state = QuestionMasteryState(
            studentId: 's1',
            questionId: 'q1',
            confidenceHistory: [3, 4, 5],
            lastAttempt: DateTime(2026, 5, 12),
          );

          expect(state.averageConfidence, 4.0);
        });

        test('returns 3.0 when no confidence history', () {
          final state = QuestionMasteryState.initial(
            studentId: 's1',
            questionId: 'q1',
            now: DateTime.now(),
          );

          expect(state.averageConfidence, 3.0);
        });

        test('handles single entry', () {
          final state = QuestionMasteryState(
            studentId: 's1',
            questionId: 'q1',
            confidenceHistory: [5],
            lastAttempt: DateTime(2026, 5, 12),
          );

          expect(state.averageConfidence, 5.0);
        });
      });
    });

    group('recordAttempt', () {
      test('returns new instance with updated counts on correct answer', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();

        final result = state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 30000, now: now);

        expect(result.correctCount, 1);
        expect(result.incorrectCount, 0);
        expect(result.currentStreak, 1);
        expect(result.bestStreak, 1);
        expect(result.totalTimeMs, 30000);
        expect(result.lastCorrect, now);
        expect(identical(state, result), isFalse);
      });

      test('returns new instance with updated counts and resets streak on incorrect answer', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();
        var current = state;

        current = current.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 15000, now: now);
        current = current.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 20000, now: now);

        expect(current.correctCount, 2);
        expect(current.incorrectCount, 1);
        expect(current.currentStreak, 0);
        expect(current.bestStreak, 2);
        expect(current.totalTimeMs, 45000);
        expect(current.lastIncorrect, now);
      });

      test('tracks best streak correctly with new instances', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();
        var current = state;

        current = current.recordAttempt(isCorrect: true, confidence: 3, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 10000, now: now);

        expect(current.bestStreak, 3);
        expect(current.currentStreak, 2);
      });

      test('accumulates totalTimeMs and updates averageTimeMs', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();
        var current = state;

        current = current.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 30000, now: now);
        current = current.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 60000, now: now);

        expect(current.totalTimeMs, 90000);
        expect(current.averageTimeMs, 45000.0);
      });

      test('limits confidence history to 20 entries', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();
        var current = state;

        for (int i = 0; i < 25; i++) {
          current = current.recordAttempt(isCorrect: true, confidence: 3, timeSpentMs: 1000, now: now);
        }

        expect(current.confidenceHistory.length, 20);
      });

      test('updates mastery level after attempt', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );

        final result = state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 10000, now: DateTime.now());

        expect(result.masteryLevel, greaterThan(0.0));
      });

      test('updates review urgency after attempt', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );

        final result = state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 10000, now: DateTime.now());

        expect(result.reviewUrgency, lessThan(1.0));
      });

      test('calculates next review after attempt', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();

        final result = state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 10000, now: now);

        expect(result.nextReview, isNotNull);
        expect(result.nextReview!.isAfter(now), isTrue);
      });

      test('sets low review urgency when streak >= 3', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();
        var current = state;

        for (int i = 0; i < 3; i++) {
          current = current.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 10000, now: now);
        }

        final mastery = current.masteryLevel;
        final expectedUrgency = ((1 - mastery) * 0.5).clamp(0.0, 1.0);
        expect(current.reviewUrgency, expectedUrgency);
        expect(current.currentStreak, 3);
      });

      test('increases review urgency when incorrect exceeds correct', () {
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          confidenceHistory: <int>[],
          lastAttempt: DateTime.now(),
          nextReview: DateTime.now(),
        );
        final now = DateTime.now();
        var current = state;

        current = current.recordAttempt(isCorrect: true, confidence: 3, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 10000, now: now);
        current = current.recordAttempt(isCorrect: false, confidence: 1, timeSpentMs: 10000, now: now);

        expect(current.incorrectCount, greaterThan(current.correctCount));
        final mastery = current.masteryLevel;
        final expectedUrgency = ((1 - mastery) * 1.2).clamp(0.0, 1.0);
        expect(current.reviewUrgency, expectedUrgency);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final now = DateTime(2026, 5, 12);
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 8,
          incorrectCount: 2,
          currentStreak: 5,
          bestStreak: 8,
          averageTimeMs: 30000.0,
          confidenceHistory: [3, 4, 5],
          lastAttempt: now,
          lastCorrect: now.subtract(const Duration(hours: 1)),
          lastIncorrect: now.subtract(const Duration(hours: 24)),
          nextReview: now.add(const Duration(days: 3)),
          masteryLevel: 0.8,
          reviewUrgency: 0.2,
          totalTimeMs: 300000,
        );

        final json = state.toJson();
        expect(json['studentId'], 's1');
        expect(json['questionId'], 'q1');
        expect(json['correctCount'], 8);
        expect(json['incorrectCount'], 2);
        expect(json['currentStreak'], 5);
        expect(json['bestStreak'], 8);
        expect(json['averageTimeMs'], 30000.0);
        expect(json['confidenceHistory'], [3, 4, 5]);
        expect(json['lastAttempt'], now.toIso8601String());
        expect(json['lastCorrect'], now.subtract(const Duration(hours: 1)).toIso8601String());
        expect(json['lastIncorrect'], now.subtract(const Duration(hours: 24)).toIso8601String());
        expect(json['nextReview'], now.add(const Duration(days: 3)).toIso8601String());
        expect(json['masteryLevel'], 0.8);
        expect(json['reviewUrgency'], 0.2);
        expect(json['totalTimeMs'], 300000);
      });

      test('handles null optional dates', () {
        final now = DateTime(2026, 5, 12);
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
        );

        final json = state.toJson();
        expect(json['lastCorrect'], isNull);
        expect(json['lastIncorrect'], isNull);
        expect(json['nextReview'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'studentId': 's1',
          'questionId': 'q1',
          'correctCount': 8,
          'incorrectCount': 2,
          'currentStreak': 5,
          'bestStreak': 8,
          'averageTimeMs': 30000.0,
          'confidenceHistory': [3, 4, 5],
          'lastAttempt': now.toIso8601String(),
          'lastCorrect': now.subtract(const Duration(hours: 1)).toIso8601String(),
          'lastIncorrect': now.subtract(const Duration(hours: 24)).toIso8601String(),
          'nextReview': now.add(const Duration(days: 3)).toIso8601String(),
          'masteryLevel': 0.8,
          'reviewUrgency': 0.2,
          'totalTimeMs': 300000,
        };

        final state = QuestionMasteryState.fromJson(json);
        expect(state.studentId, 's1');
        expect(state.questionId, 'q1');
        expect(state.masteryLevel, 0.8);
        expect(state.reviewUrgency, 0.2);
        expect(state.lastAttempt, now);
      });

      test('handles missing optional fields', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'studentId': 's1',
          'questionId': 'q1',
          'lastAttempt': now.toIso8601String(),
        };

        final state = QuestionMasteryState.fromJson(json);
        expect(state.correctCount, 0);
        expect(state.incorrectCount, 0);
        expect(state.masteryLevel, 0.0);
        expect(state.reviewUrgency, 1.0);
        expect(state.confidenceHistory, []);
        expect(state.lastCorrect, isNull);
      });
    });

    group('json round-trip', () {
      test('preserves all fields', () {
        final now = DateTime(2026, 5, 12);
        final original = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 8,
          incorrectCount: 2,
          currentStreak: 5,
          bestStreak: 8,
          averageTimeMs: 30000.0,
          confidenceHistory: [3, 4, 5],
          lastAttempt: now,
          lastCorrect: now.subtract(const Duration(hours: 1)),
          lastIncorrect: now.subtract(const Duration(hours: 24)),
          nextReview: now.add(const Duration(days: 3)),
          masteryLevel: 0.8,
          reviewUrgency: 0.2,
          totalTimeMs: 300000,
        );

        final restored = QuestionMasteryState.fromJson(original.toJson());
        expect(restored.studentId, original.studentId);
        expect(restored.questionId, original.questionId);
        expect(restored.masteryLevel, original.masteryLevel);
        expect(restored.reviewUrgency, original.reviewUrgency);
      });
    });

    group('copyWith', () {
      test('changes specified fields', () {
        final state = QuestionMasteryState.initial(
          studentId: 's1',
          questionId: 'q1',
          now: DateTime.now(),
        );

        final updated = state.copyWith(
          correctCount: 5,
          masteryLevel: 0.7,
        );

        expect(updated.correctCount, 5);
        expect(updated.masteryLevel, 0.7);
        expect(updated.studentId, 's1');
        expect(updated.questionId, 'q1');
      });

      test('keeps unchanged fields when null', () {
        final now = DateTime(2026, 5, 12);
        final state = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          correctCount: 5,
          incorrectCount: 2,
          lastAttempt: now,
        );

        final updated = state.copyWith(correctCount: 10);
        expect(updated.correctCount, 10);
        expect(updated.incorrectCount, 2);
        expect(updated.studentId, 's1');
      });
    });
  });
}
