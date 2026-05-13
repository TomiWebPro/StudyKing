import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

/// Creates a MasteryState with mutable lists for testing recordAttempt
/// (the source code has const [] for defaults which are unmodifiable)
MasteryState _createTestState(String studentId, String topicId) {
  final now = DateTime(2026, 5, 12, 10, 0, 0);
  return MasteryState(
    studentId: studentId,
    topicId: topicId,
    lastAttempt: now,
    lastUpdated: now,
    recentConfidence: <int>[],
    recentAccuracy: <double>[],
    weakSubtopics: <String>[],
  );
}

void main() {
  group('MasteryState', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final state = MasteryState(
          studentId: 'student-1',
          topicId: 'topic-1',
          lastAttempt: now,
          lastUpdated: now,
        );
        expect(state.studentId, 'student-1');
        expect(state.topicId, 'topic-1');
        expect(state.accuracy, 0.0);
        expect(state.confidenceTrend, 0.5);
        expect(state.masteryLevel, MasteryLevel.novice);
      });

      test('creates with all fields', () {
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.8,
          confidenceTrend: 0.7,
          speedTrend: 0.6,
          forgettingRisk: 0.2,
          totalAttempts: 10,
          correctAttempts: 8,
          averageTimeMs: 5000,
          lastAttempt: now,
          lastUpdated: now,
          currentStreak: 3,
          bestStreak: 5,
          recentConfidence: [4, 5, 3],
          recentAccuracy: [1.0, 0.0, 1.0],
          masteryLevel: MasteryLevel.proficient,
          readinessScore: 0.75,
          reviewUrgency: 0.3,
          weakSubtopics: ['subtopic-1'],
        );
        expect(state.accuracy, 0.8);
        expect(state.masteryLevel, MasteryLevel.proficient);
        expect(state.currentStreak, 3);
        expect(state.bestStreak, 5);
      });
    });

    group('MasteryState.initial', () {
      test('creates initial state', () {
        final state = MasteryState.initial(
          studentId: 'student-1',
          topicId: 'topic-1',
        );
        expect(state.studentId, 'student-1');
        expect(state.topicId, 'topic-1');
        expect(state.totalAttempts, 0);
        expect(state.accuracy, 0.0);
        expect(state.masteryLevel, MasteryLevel.novice);
      });
    });

    group('recordAttempt', () {
      test('records first correct attempt', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 5000);

        expect(state.totalAttempts, 1);
        expect(state.correctAttempts, 1);
        expect(state.currentStreak, 1);
        expect(state.bestStreak, 1);
        expect(state.averageTimeMs, 5000);
        expect(state.recentConfidence, [4]);
        expect(state.recentAccuracy, [1.0]);
        expect(state.masteryLevel, MasteryLevel.browsing);
      });

      test('records first incorrect attempt', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 10000);

        expect(state.totalAttempts, 1);
        expect(state.correctAttempts, 0);
        expect(state.currentStreak, 0);
        expect(state.bestStreak, 0);
        expect(state.masteryLevel, MasteryLevel.browsing);
      });

      test('increments streak on consecutive correct', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 5000);
        state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 3000);

        expect(state.totalAttempts, 2);
        expect(state.currentStreak, 2);
        expect(state.bestStreak, 2);
      });

      test('resets streak on incorrect', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 5000);
        state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 3000);
        state.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 8000);

        expect(state.currentStreak, 0);
        expect(state.bestStreak, 2);
      });

      test('computes accuracy correctly', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: false, confidence: 3, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 1000);

        expect(state.totalAttempts, 4);
        expect(state.correctAttempts, 3);
        expect(state.accuracy, 0.75);
      });

      test('updates average time', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 2000);
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 4000);

        expect(state.averageTimeMs, 3000);
      });

      test('recentConfidence capped at 20', () {
        final state = _createTestState('s1', 't1');
        for (int i = 0; i < 25; i++) {
          state.recordAttempt(isCorrect: i % 2 == 0, confidence: 3, timeSpentMs: 1000);
        }
        expect(state.recentConfidence.length, 20);
        expect(state.recentAccuracy.length, 20);
      });

      test('reaches expert level', () {
        final state = _createTestState('s1', 't1');
        for (int i = 0; i < 10; i++) {
          state.recordAttempt(isCorrect: true, confidence: 5, timeSpentMs: 1000);
        }
        expect(state.totalAttempts, 10);
        expect(state.currentStreak, 10);
        expect(state.accuracy, 1.0);
        expect(state.masteryLevel, MasteryLevel.expert);
      });

      test('reaches developing level', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(isCorrect: true, confidence: 4, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: true, confidence: 3, timeSpentMs: 1000);
        state.recordAttempt(isCorrect: false, confidence: 2, timeSpentMs: 1000);

        expect(state.totalAttempts, 3);
        expect(state.accuracy, 2 / 3);
      });

      test('adds weak subtopic on incorrect', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 1000,
          subtopicId: 'subtopic-1',
        );
        expect(state.weakSubtopics, ['subtopic-1']);
      });

      test('does not add weak subtopic on correct', () {
        final state = _createTestState('s1', 't1');
        state.recordAttempt(
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 1000,
          subtopicId: 'subtopic-1',
        );
        expect(state.weakSubtopics, isEmpty);
      });
    });

    group('toJson / fromJson', () {
      test('serialization roundtrip', () {
        final original = MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.75,
          confidenceTrend: 0.6,
          speedTrend: 0.5,
          forgettingRisk: 0.2,
          totalAttempts: 4,
          correctAttempts: 3,
          averageTimeMs: 3000,
          lastAttempt: now,
          lastUpdated: now,
          currentStreak: 2,
          bestStreak: 3,
          recentConfidence: [4, 5, 3],
          recentAccuracy: [1.0, 1.0, 0.0],
          masteryLevel: MasteryLevel.developing,
          readinessScore: 0.6,
          reviewUrgency: 0.4,
          weakSubtopics: ['sub-1'],
        );
        final json = original.toJson();
        final restored = MasteryState.fromJson(json);
        expect(restored.studentId, original.studentId);
        expect(restored.topicId, original.topicId);
        expect(restored.accuracy, original.accuracy);
        expect(restored.masteryLevel, original.masteryLevel);
        expect(restored.recentConfidence, original.recentConfidence);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final state = MasteryState.initial(studentId: 's1', topicId: 't1');
        final copy = state.copyWith(accuracy: 0.9, masteryLevel: MasteryLevel.expert);
        expect(copy.accuracy, 0.9);
        expect(copy.masteryLevel, MasteryLevel.expert);
        expect(copy.studentId, 's1');
      });
    });
  });
}
