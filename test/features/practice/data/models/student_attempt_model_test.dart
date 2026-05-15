import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';

void main() {
  group('StudentAttempt', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: now,
        );

        expect(attempt.id, 'a1');
        expect(attempt.studentId, 's1');
        expect(attempt.questionId, 'q1');
        expect(attempt.subjectId, 'sub1');
        expect(attempt.timestamp, now);
      });

      test('uses default values for optional fields', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: now,
        );

        expect(attempt.isCorrect, isFalse);
        expect(attempt.timeSpentMs, 0);
        expect(attempt.confidence, 3);
        expect(attempt.userAnswer, '');
        expect(attempt.markschemeMatch, isNull);
        expect(attempt.lastDueDate, isNull);
      });

      test('accepts custom values for optional fields', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: true,
          timeSpentMs: 30000,
          confidence: 5,
          timestamp: now,
          userAnswer: 'Paris',
          markschemeMatch: 'exact',
          lastDueDate: now.add(const Duration(days: 7)),
        );

        expect(attempt.isCorrect, isTrue);
        expect(attempt.timeSpentMs, 30000);
        expect(attempt.confidence, 5);
        expect(attempt.userAnswer, 'Paris');
        expect(attempt.markschemeMatch, 'exact');
        expect(attempt.lastDueDate, now.add(const Duration(days: 7)));
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: true,
          timeSpentMs: 30000,
          confidence: 5,
          timestamp: now,
          userAnswer: 'Paris',
          markschemeMatch: 'exact',
          lastDueDate: now.add(const Duration(days: 7)),
        );

        final json = attempt.toJson();
        expect(json['id'], 'a1');
        expect(json['studentId'], 's1');
        expect(json['questionId'], 'q1');
        expect(json['subjectId'], 'sub1');
        expect(json['isCorrect'], isTrue);
        expect(json['timeSpentMs'], 30000);
        expect(json['confidence'], 5);
        expect(json['timestamp'], now.toIso8601String());
        expect(json['userAnswer'], 'Paris');
        expect(json['markschemeMatch'], 'exact');
        expect(json['lastDueDate'], now.add(const Duration(days: 7)).toIso8601String());
      });

      test('handles null optional fields', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: now,
        );

        final json = attempt.toJson();
        expect(json['markschemeMatch'], isNull);
        expect(json['lastDueDate'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'id': 'a1',
          'studentId': 's1',
          'questionId': 'q1',
          'subjectId': 'sub1',
          'isCorrect': true,
          'timeSpentMs': 30000,
          'confidence': 5,
          'timestamp': now.toIso8601String(),
          'userAnswer': 'Paris',
          'markschemeMatch': 'exact',
          'lastDueDate': now.add(const Duration(days: 7)).toIso8601String(),
        };

        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.id, 'a1');
        expect(attempt.studentId, 's1');
        expect(attempt.isCorrect, isTrue);
        expect(attempt.confidence, 5);
        expect(attempt.markschemeMatch, 'exact');
        expect(attempt.lastDueDate, now.add(const Duration(days: 7)));
      });

      test('handles missing optional fields', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'id': 'a1',
          'studentId': 's1',
          'questionId': 'q1',
          'subjectId': 'sub1',
          'timestamp': now.toIso8601String(),
        };

        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.isCorrect, isFalse);
        expect(attempt.timeSpentMs, 0);
        expect(attempt.confidence, 3);
        expect(attempt.userAnswer, '');
        expect(attempt.markschemeMatch, isNull);
        expect(attempt.lastDueDate, isNull);
      });

      test('handles null markschemeMatch and lastDueDate', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'id': 'a1',
          'studentId': 's1',
          'questionId': 'q1',
          'subjectId': 'sub1',
          'timestamp': now.toIso8601String(),
          'markschemeMatch': null,
          'lastDueDate': null,
        };

        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.markschemeMatch, isNull);
        expect(attempt.lastDueDate, isNull);
      });
    });

    group('json round-trip', () {
      test('preserves all fields', () {
        final now = DateTime(2026, 5, 12);
        final original = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: true,
          timeSpentMs: 30000,
          confidence: 5,
          timestamp: now,
          userAnswer: 'Paris',
          markschemeMatch: 'exact',
          lastDueDate: now.add(const Duration(days: 7)),
        );

        final restored = StudentAttempt.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.questionId, original.questionId);
        expect(restored.subjectId, original.subjectId);
        expect(restored.isCorrect, original.isCorrect);
        expect(restored.timeSpentMs, original.timeSpentMs);
        expect(restored.confidence, original.confidence);
        expect(restored.timestamp, original.timestamp);
        expect(restored.userAnswer, original.userAnswer);
        expect(restored.markschemeMatch, original.markschemeMatch);
        expect(restored.lastDueDate, original.lastDueDate);
      });
    });

    group('copyWith', () {
      test('changes specified fields', () {
        final now = DateTime(2026, 5, 12);
        final later = DateTime(2026, 5, 13);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: now,
        );

        final updated = attempt.copyWith(
          isCorrect: true,
          confidence: 5,
          timestamp: later,
        );

        expect(updated.isCorrect, isTrue);
        expect(updated.confidence, 5);
        expect(updated.timestamp, later);
        expect(updated.id, 'a1');
        expect(updated.studentId, 's1');
      });

      test('keeps unchanged fields when null', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: true,
          confidence: 5,
          timestamp: now,
        );

        final updated = attempt.copyWith(isCorrect: false);
        expect(updated.isCorrect, isFalse);
        expect(updated.confidence, 5);
        expect(updated.studentId, 's1');
      });
    });
  });
}
