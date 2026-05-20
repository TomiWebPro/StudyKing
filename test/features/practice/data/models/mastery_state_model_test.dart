import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

void main() {
  group('MasteryLevel', () {
    test('has correct enum values in order', () {
      expect(MasteryLevel.values, [
        MasteryLevel.novice,
        MasteryLevel.browsing,
        MasteryLevel.developing,
        MasteryLevel.proficient,
        MasteryLevel.expert,
      ]);
    });

    test('novice has index 0', () {
      expect(MasteryLevel.novice.index, 0);
    });

    test('expert has index 4', () {
      expect(MasteryLevel.expert.index, 4);
    });
  });

  group('MasteryState', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final now = DateTime(2026, 5, 12);
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: now,
          lastUpdated: now,
        );

        expect(state.studentId, 's1');
        expect(state.topicId, 't1');
        expect(state.lastAttempt, now);
        expect(state.lastUpdated, now);
        expect(state.accuracy, 0.0);
        expect(state.totalAttempts, 0);
        expect(state.masteryLevel, MasteryLevel.novice);
      });

      test('accepts all optional fields', () {
        final now = DateTime(2026, 5, 12);
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.85,
          confidenceTrend: 0.75,
          speedTrend: 0.65,
          forgettingRisk: 0.1,
          totalAttempts: 20,
          correctAttempts: 17,
          averageTimeMs: 45000.0,
          lastAttempt: now,
          lastUpdated: now,
          currentStreak: 5,
          bestStreak: 8,
          recentConfidence: [3, 4, 5],
          recentAccuracy: [0.8, 0.9, 0.85],
          masteryLevel: MasteryLevel.proficient,
          readinessScore: 0.9,
          reviewUrgency: 0.2,
          weakSubtopics: ['subtopic_a'],
        );

        expect(state.accuracy, 0.85);
        expect(state.confidenceTrend, 0.75);
        expect(state.speedTrend, 0.65);
        expect(state.forgettingRisk, 0.1);
        expect(state.totalAttempts, 20);
        expect(state.correctAttempts, 17);
        expect(state.averageTimeMs, 45000.0);
        expect(state.currentStreak, 5);
        expect(state.bestStreak, 8);
        expect(state.recentConfidence, [3, 4, 5]);
        expect(state.recentAccuracy, [0.8, 0.9, 0.85]);
        expect(state.masteryLevel, MasteryLevel.proficient);
        expect(state.readinessScore, 0.9);
        expect(state.reviewUrgency, 0.2);
        expect(state.weakSubtopics, ['subtopic_a']);
      });
    });

    group('MasteryState.initial', () {
      test('creates initial state with given ids', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final state = MasteryState.initial(studentId: 's1', topicId: 't1');
        final after = DateTime.now().add(const Duration(seconds: 1));

        expect(state.studentId, 's1');
        expect(state.topicId, 't1');
        expect(state.accuracy, 0.0);
        expect(state.totalAttempts, 0);
        expect(state.correctAttempts, 0);
        expect(state.currentStreak, 0);
        expect(state.bestStreak, 0);
        expect(state.masteryLevel, MasteryLevel.novice);
        expect(state.readinessScore, 0.0);
        expect(state.reviewUrgency, 0.0);
        expect(state.weakSubtopics, []);
        expect(state.lastAttempt.isAfter(before), isTrue);
        expect(state.lastAttempt.isBefore(after), isTrue);
        expect(state.lastUpdated.isAfter(before), isTrue);
        expect(state.lastUpdated.isBefore(after), isTrue);
      });

      test('creates independent instances', () {
        final state1 = MasteryState.initial(studentId: 's1', topicId: 't1');
        final state2 = MasteryState.initial(studentId: 's2', topicId: 't2');

        expect(state1.studentId, 's1');
        expect(state2.studentId, 's2');
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final now = DateTime(2026, 5, 12);
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.85,
          confidenceTrend: 0.75,
          speedTrend: 0.65,
          forgettingRisk: 0.1,
          totalAttempts: 20,
          correctAttempts: 17,
          averageTimeMs: 45000.0,
          lastAttempt: now,
          lastUpdated: now,
          currentStreak: 5,
          bestStreak: 8,
          recentConfidence: [3, 4, 5],
          recentAccuracy: [0.8, 0.9, 0.85],
          masteryLevel: MasteryLevel.proficient,
          readinessScore: 0.9,
          reviewUrgency: 0.2,
          weakSubtopics: ['subtopic_a'],
        );

        final json = state.toJson();
        expect(json['studentId'], 's1');
        expect(json['topicId'], 't1');
        expect(json['accuracy'], 0.85);
        expect(json['confidenceTrend'], 0.75);
        expect(json['speedTrend'], 0.65);
        expect(json['forgettingRisk'], 0.1);
        expect(json['totalAttempts'], 20);
        expect(json['correctAttempts'], 17);
        expect(json['averageTimeMs'], 45000.0);
        expect(json['lastAttempt'], now.toIso8601String());
        expect(json['lastUpdated'], now.toIso8601String());
        expect(json['currentStreak'], 5);
        expect(json['bestStreak'], 8);
        expect(json['recentConfidence'], [3, 4, 5]);
        expect(json['recentAccuracy'], [0.8, 0.9, 0.85]);
        expect(json['masteryLevel'], MasteryLevel.proficient.index);
        expect(json['readinessScore'], 0.9);
        expect(json['reviewUrgency'], 0.2);
        expect(json['weakSubtopics'], ['subtopic_a']);
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'studentId': 's1',
          'topicId': 't1',
          'accuracy': 0.85,
          'confidenceTrend': 0.75,
          'speedTrend': 0.65,
          'forgettingRisk': 0.1,
          'totalAttempts': 20,
          'correctAttempts': 17,
          'averageTimeMs': 45000.0,
          'lastAttempt': now.toIso8601String(),
          'lastUpdated': now.toIso8601String(),
          'currentStreak': 5,
          'bestStreak': 8,
          'recentConfidence': [3, 4, 5],
          'recentAccuracy': [0.8, 0.9, 0.85],
          'masteryLevel': MasteryLevel.proficient.index,
          'readinessScore': 0.9,
          'reviewUrgency': 0.2,
          'weakSubtopics': ['subtopic_a'],
        };

        final state = MasteryState.fromJson(json);
        expect(state.studentId, 's1');
        expect(state.topicId, 't1');
        expect(state.accuracy, 0.85);
        expect(state.confidenceTrend, 0.75);
        expect(state.speedTrend, 0.65);
        expect(state.forgettingRisk, 0.1);
        expect(state.totalAttempts, 20);
        expect(state.correctAttempts, 17);
        expect(state.averageTimeMs, 45000.0);
        expect(state.lastAttempt, now);
        expect(state.lastUpdated, now);
        expect(state.currentStreak, 5);
        expect(state.bestStreak, 8);
        expect(state.recentConfidence, [3, 4, 5]);
        expect(state.recentAccuracy, [0.8, 0.9, 0.85]);
        expect(state.masteryLevel, MasteryLevel.proficient);
        expect(state.readinessScore, 0.9);
        expect(state.reviewUrgency, 0.2);
        expect(state.weakSubtopics, ['subtopic_a']);
      });

      test('handles missing optional fields', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'studentId': 's1',
          'topicId': 't1',
          'lastAttempt': now.toIso8601String(),
          'lastUpdated': now.toIso8601String(),
        };

        final state = MasteryState.fromJson(json);
        expect(state.accuracy, 0.0);
        expect(state.confidenceTrend, 0.5);
        expect(state.speedTrend, 0.5);
        expect(state.forgettingRisk, 0.0);
        expect(state.totalAttempts, 0);
        expect(state.correctAttempts, 0);
        expect(state.masteryLevel, MasteryLevel.novice);
        expect(state.weakSubtopics, []);
      });
    });

    group('json round-trip', () {
      test('preserves all fields', () {
        final now = DateTime(2026, 5, 12);
        final original = MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.85,
          confidenceTrend: 0.75,
          speedTrend: 0.65,
          forgettingRisk: 0.1,
          totalAttempts: 20,
          correctAttempts: 17,
          averageTimeMs: 45000.0,
          lastAttempt: now,
          lastUpdated: now,
          currentStreak: 5,
          bestStreak: 8,
          recentConfidence: [3, 4, 5],
          recentAccuracy: [0.8, 0.9, 0.85],
          masteryLevel: MasteryLevel.proficient,
          readinessScore: 0.9,
          reviewUrgency: 0.2,
          weakSubtopics: ['subtopic_a'],
        );

        final restored = MasteryState.fromJson(original.toJson());
        expect(restored.studentId, original.studentId);
        expect(restored.topicId, original.topicId);
        expect(restored.accuracy, original.accuracy);
        expect(restored.masteryLevel, original.masteryLevel);
        expect(restored.weakSubtopics, original.weakSubtopics);
      });
    });

    group('copyWith', () {
      test('changes specified fields', () {
        final now = DateTime(2026, 5, 12);
        final later = DateTime(2026, 5, 13);
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: now,
          lastUpdated: now,
        );

        final updated = state.copyWith(
          accuracy: 0.9,
          totalAttempts: 10,
          correctAttempts: 9,
          masteryLevel: MasteryLevel.proficient,
          lastUpdated: later,
        );

        expect(updated.accuracy, 0.9);
        expect(updated.totalAttempts, 10);
        expect(updated.correctAttempts, 9);
        expect(updated.masteryLevel, MasteryLevel.proficient);
        expect(updated.lastUpdated, later);
        expect(updated.studentId, 's1');
        expect(updated.topicId, 't1');
        expect(updated.lastAttempt, now);
      });

      test('keeps unchanged fields when null', () {
        final now = DateTime(2026, 5, 12);
        final state = MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.5,
          lastAttempt: now,
          lastUpdated: now,
        );

        final updated = state.copyWith(accuracy: 0.8);
        expect(updated.accuracy, 0.8);
        expect(updated.topicId, 't1');
        expect(updated.studentId, 's1');
        expect(updated.totalAttempts, 0);
      });
    });
  });
}
