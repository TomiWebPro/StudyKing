import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

void main() {
  group('MasteryState', () {
    final baseTime = DateTime(2025, 1, 15, 10, 0, 0);

    test('initial factory creates state with defaults', () {
      final state = MasteryState.initial(
        studentId: 'stu1',
        topicId: 'topic1',
      );
      expect(state.studentId, 'stu1');
      expect(state.topicId, 'topic1');
      expect(state.accuracy, 0.0);
      expect(state.masteryLevel, MasteryLevel.novice);
      expect(state.totalAttempts, 0);
      expect(state.correctAttempts, 0);
    });

    test('toJson and fromJson round-trip', () {
      final state = MasteryState(
        studentId: 'stu1',
        topicId: 'topic1',
        accuracy: 0.85,
        confidenceTrend: 0.7,
        speedTrend: 0.6,
        forgettingRisk: 0.1,
        totalAttempts: 20,
        correctAttempts: 17,
        averageTimeMs: 30000,
        lastAttempt: baseTime,
        lastUpdated: baseTime,
        currentStreak: 5,
        bestStreak: 8,
        recentConfidence: [3, 4, 5],
        recentAccuracy: [0.8, 0.9, 1.0],
        masteryLevel: MasteryLevel.proficient,
        readinessScore: 0.75,
        reviewUrgency: 0.3,
        weakSubtopics: ['algebra'],
      );

      final json = state.toJson();
      final restored = MasteryState.fromJson(json);

      expect(restored.studentId, state.studentId);
      expect(restored.topicId, state.topicId);
      expect(restored.accuracy, state.accuracy);
      expect(restored.confidenceTrend, state.confidenceTrend);
      expect(restored.speedTrend, state.speedTrend);
      expect(restored.forgettingRisk, state.forgettingRisk);
      expect(restored.totalAttempts, state.totalAttempts);
      expect(restored.correctAttempts, state.correctAttempts);
      expect(restored.averageTimeMs, state.averageTimeMs);
      expect(restored.lastAttempt, state.lastAttempt);
      expect(restored.lastUpdated, state.lastUpdated);
      expect(restored.currentStreak, state.currentStreak);
      expect(restored.bestStreak, state.bestStreak);
      expect(restored.recentConfidence, state.recentConfidence);
      expect(restored.recentAccuracy, state.recentAccuracy);
      expect(restored.masteryLevel, state.masteryLevel);
      expect(restored.readinessScore, state.readinessScore);
      expect(restored.reviewUrgency, state.reviewUrgency);
      expect(restored.weakSubtopics, state.weakSubtopics);
    });

    test('toJson and fromJson round-trip with defaults', () {
      final state = MasteryState.initial(
        studentId: 'stu1',
        topicId: 'topic1',
      );
      final json = state.toJson();
      final restored = MasteryState.fromJson(json);

      expect(restored.studentId, 'stu1');
      expect(restored.topicId, 'topic1');
      expect(restored.accuracy, 0.0);
      expect(restored.masteryLevel, MasteryLevel.novice);
    });

    test('copyWith updates specified fields', () {
      final state = MasteryState.initial(
        studentId: 'stu1',
        topicId: 'topic1',
      );

      final updated = state.copyWith(
        accuracy: 0.9,
        masteryLevel: MasteryLevel.expert,
      );

      expect(updated.accuracy, 0.9);
      expect(updated.masteryLevel, MasteryLevel.expert);
      expect(updated.studentId, 'stu1');
    });

    test('copyWith retains unspecified fields', () {
      final state = MasteryState.initial(
        studentId: 'stu1',
        topicId: 'topic1',
      );

      final updated = state.copyWith(accuracy: 0.5);
      expect(updated.studentId, 'stu1');
      expect(updated.topicId, 'topic1');
      expect(updated.masteryLevel, MasteryLevel.novice);
    });

    test('MasteryLevel enum has correct ordering', () {
      expect(MasteryLevel.novice.index, 0);
      expect(MasteryLevel.browsing.index, 1);
      expect(MasteryLevel.developing.index, 2);
      expect(MasteryLevel.proficient.index, 3);
      expect(MasteryLevel.expert.index, 4);
    });
  });
}
