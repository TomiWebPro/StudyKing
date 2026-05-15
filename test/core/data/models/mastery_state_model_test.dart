import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/core/services/mastery_calculation_service.dart';

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
  late MasteryCalculationService calculationService;

  setUp(() {
    calculationService = MasteryCalculationService();
  });

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

    group('MasteryCalculationService.recordAttempt', () {
      test('records first correct attempt', () {
        final state = _createTestState('s1', 't1');
        final result = calculationService.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );

        expect(result.totalAttempts, 1);
        expect(result.correctAttempts, 1);
        expect(result.currentStreak, 1);
        expect(result.bestStreak, 1);
        expect(result.averageTimeMs, 5000);
        expect(result.recentConfidence, [4]);
        expect(result.recentAccuracy, [1.0]);
        expect(result.masteryLevel, MasteryLevel.browsing);
      });

      test('records first incorrect attempt', () {
        final state = _createTestState('s1', 't1');
        final result = calculationService.recordAttempt(
          current: state,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 10000,
        );

        expect(result.totalAttempts, 1);
        expect(result.correctAttempts, 0);
        expect(result.currentStreak, 0);
        expect(result.bestStreak, 0);
        expect(result.masteryLevel, MasteryLevel.browsing);
      });

      test('increments streak on consecutive correct', () {
        final state = _createTestState('s1', 't1');
        final first = calculationService.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        final result = calculationService.recordAttempt(
          current: first,
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 3000,
        );

        expect(result.totalAttempts, 2);
        expect(result.currentStreak, 2);
        expect(result.bestStreak, 2);
      });

      test('resets streak on incorrect', () {
        final state = _createTestState('s1', 't1');
        final first = calculationService.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 5000,
        );
        final second = calculationService.recordAttempt(
          current: first,
          isCorrect: true,
          confidence: 5,
          timeSpentMs: 3000,
        );
        final result = calculationService.recordAttempt(
          current: second,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 8000,
        );

        expect(result.currentStreak, 0);
        expect(result.bestStreak, 2);
      });

      test('computes accuracy correctly', () {
        final state = _createTestState('s1', 't1');
        var current = state;
        current = calculationService.recordAttempt(current: current, isCorrect: true, confidence: 4, timeSpentMs: 1000);
        current = calculationService.recordAttempt(current: current, isCorrect: false, confidence: 3, timeSpentMs: 1000);
        current = calculationService.recordAttempt(current: current, isCorrect: true, confidence: 5, timeSpentMs: 1000);
        current = calculationService.recordAttempt(current: current, isCorrect: true, confidence: 4, timeSpentMs: 1000);

        expect(current.totalAttempts, 4);
        expect(current.correctAttempts, 3);
        expect(current.accuracy, 0.75);
      });

      test('updates average time', () {
        final state = _createTestState('s1', 't1');
        final first = calculationService.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 2000,
        );
        final result = calculationService.recordAttempt(
          current: first,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 4000,
        );

        expect(result.averageTimeMs, 3000);
      });

      test('recentConfidence capped at 20', () {
        final state = _createTestState('s1', 't1');
        var current = state;
        for (int i = 0; i < 25; i++) {
          current = calculationService.recordAttempt(
            current: current,
            isCorrect: i % 2 == 0,
            confidence: 3,
            timeSpentMs: 1000,
          );
        }
        expect(current.recentConfidence.length, 20);
        expect(current.recentAccuracy.length, 20);
      });

      test('reaches expert level', () {
        final state = _createTestState('s1', 't1');
        var current = state;
        for (int i = 0; i < 10; i++) {
          current = calculationService.recordAttempt(
            current: current,
            isCorrect: true,
            confidence: 5,
            timeSpentMs: 1000,
          );
        }
        expect(current.totalAttempts, 10);
        expect(current.currentStreak, 10);
        expect(current.accuracy, 1.0);
        expect(current.masteryLevel, MasteryLevel.expert);
      });

      test('reaches developing level', () {
        final state = _createTestState('s1', 't1');
        var current = state;
        current = calculationService.recordAttempt(current: current, isCorrect: true, confidence: 4, timeSpentMs: 1000);
        current = calculationService.recordAttempt(current: current, isCorrect: true, confidence: 3, timeSpentMs: 1000);
        current = calculationService.recordAttempt(current: current, isCorrect: false, confidence: 2, timeSpentMs: 1000);

        expect(current.totalAttempts, 3);
        expect(current.accuracy, 2 / 3);
      });

      test('adds weak subtopic on incorrect', () {
        final state = _createTestState('s1', 't1');
        final result = calculationService.recordAttempt(
          current: state,
          isCorrect: false,
          confidence: 2,
          timeSpentMs: 1000,
          subtopicId: 'subtopic-1',
        );
        expect(result.weakSubtopics, ['subtopic-1']);
      });

      test('does not add weak subtopic on correct', () {
        final state = _createTestState('s1', 't1');
        final result = calculationService.recordAttempt(
          current: state,
          isCorrect: true,
          confidence: 4,
          timeSpentMs: 1000,
          subtopicId: 'subtopic-1',
        );
        expect(result.weakSubtopics, isEmpty);
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

    group('equality', () {
      test('uses identity-based equality', () {
        final a = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now);
        final b = MasteryState(studentId: 's2', topicId: 't2', lastAttempt: now, lastUpdated: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now);
        expect(obj.toString(), contains('MasteryState'));
      });
    });

    group('fromJson edge cases', () {
      test('throws on null lastAttempt', () {
        final json = {
          'studentId': 's1',
          'topicId': 't1',
          'lastUpdated': now.toIso8601String(),
        };
        expect(() => MasteryState.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws on null lastUpdated', () {
        final json = {
          'studentId': 's1',
          'topicId': 't1',
          'lastAttempt': now.toIso8601String(),
        };
        expect(() => MasteryState.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws on malformed lastAttempt timestamp', () {
        final json = {
          'studentId': 's1',
          'topicId': 't1',
          'lastAttempt': 'not-a-date',
          'lastUpdated': now.toIso8601String(),
        };
        expect(() => MasteryState.fromJson(json), throwsA(isA<FormatException>()));
      });
    });
  });
}
