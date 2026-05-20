import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import '../../../../helpers/hive_test_utils.dart';

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

      test('preserves nullable fields when copyWith null is passed', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: now,
          markschemeMatch: 'partial',
          lastDueDate: now,
        );

        final updated = attempt.copyWith(
          isCorrect: true,
        );

        expect(updated.markschemeMatch, 'partial');
        expect(updated.lastDueDate, now);
        expect(updated.id, 'a1');
        expect(updated.studentId, 's1');
      });

      test('uses original value when copyWith parameter is not specified', () {
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

        final updated = attempt.copyWith(timeSpentMs: 10000);

        expect(updated.isCorrect, isTrue);
        expect(updated.confidence, 5);
        expect(updated.timeSpentMs, 10000);
      });

      test('can set all fields at once', () {
        final now = DateTime(2026, 5, 12);
        final later = DateTime(2026, 5, 20);
        final attempt = StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timestamp: now,
        );

        final updated = attempt.copyWith(
          id: 'a2',
          studentId: 's2',
          questionId: 'q2',
          subjectId: 'sub2',
          isCorrect: true,
          timeSpentMs: 50000,
          confidence: 4,
          timestamp: later,
          userAnswer: 'Berlin',
          markschemeMatch: 'full',
          lastDueDate: later.add(const Duration(days: 3)),
        );

        expect(updated.id, 'a2');
        expect(updated.studentId, 's2');
        expect(updated.questionId, 'q2');
        expect(updated.subjectId, 'sub2');
        expect(updated.isCorrect, isTrue);
        expect(updated.timeSpentMs, 50000);
        expect(updated.confidence, 4);
        expect(updated.timestamp, later);
        expect(updated.userAnswer, 'Berlin');
        expect(updated.markschemeMatch, 'full');
        expect(updated.lastDueDate, later.add(const Duration(days: 3)));
      });
    });

    group('edge case values', () {
      test('toJson handles zero timeSpentMs and minimum confidence', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a-edge',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timeSpentMs: 0,
          confidence: 1,
          timestamp: now,
        );

        final json = attempt.toJson();
        expect(json['timeSpentMs'], 0);
        expect(json['confidence'], 1);
      });

      test('toJson handles maximum confidence', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a-max',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          confidence: 5,
          timestamp: now,
        );

        final json = attempt.toJson();
        expect(json['confidence'], 5);
      });

      test('toJson handles large timeSpentMs', () {
        final now = DateTime(2026, 5, 12);
        final attempt = StudentAttempt(
          id: 'a-big',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          timeSpentMs: 999999999,
          timestamp: now,
        );

        final json = attempt.toJson();
        expect(json['timeSpentMs'], 999999999);
      });

      test('fromJson handles negative values gracefully', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'id': 'a-neg',
          'studentId': 's1',
          'questionId': 'q1',
          'subjectId': 'sub1',
          'isCorrect': true,
          'timeSpentMs': -100,
          'confidence': 0,
          'timestamp': now.toIso8601String(),
          'userAnswer': 'neg',
        };

        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.timeSpentMs, -100);
        expect(attempt.confidence, 0);
      });

      test('fromJson handles empty strings for fields', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'id': 'a-empty',
          'studentId': '',
          'questionId': '',
          'subjectId': '',
          'timestamp': now.toIso8601String(),
          'userAnswer': '',
        };

        final attempt = StudentAttempt.fromJson(json);
        expect(attempt.studentId, '');
        expect(attempt.questionId, '');
        expect(attempt.subjectId, '');
        expect(attempt.userAnswer, '');
      });

      test('fromJson restores nullable fields from null JSON values', () {
        final now = DateTime(2026, 5, 12);
        final json = {
          'id': 'a-null',
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
  });

  group('StudentAttemptAdapter', () {
    test('has correct typeId', () {
      final adapter = StudentAttemptAdapter();
      expect(adapter.typeId, 24);
    });

    test('is a TypeAdapter<StudentAttempt>', () {
      final adapter = StudentAttemptAdapter();
      expect(adapter, isA<TypeAdapter<StudentAttempt>>());
    });

    test('read and write round-trips with all fields', () {
      final adapter = StudentAttemptAdapter();
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

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, attempt);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, attempt.id);
      expect(restored.studentId, attempt.studentId);
      expect(restored.questionId, attempt.questionId);
      expect(restored.subjectId, attempt.subjectId);
      expect(restored.isCorrect, attempt.isCorrect);
      expect(restored.timeSpentMs, attempt.timeSpentMs);
      expect(restored.confidence, attempt.confidence);
      expect(restored.timestamp, attempt.timestamp);
      expect(restored.userAnswer, attempt.userAnswer);
      expect(restored.markschemeMatch, attempt.markschemeMatch);
      expect(restored.lastDueDate, attempt.lastDueDate);
    });

    test('read and write round-trips with default values', () {
      final adapter = StudentAttemptAdapter();
      final now = DateTime(2026, 5, 12);
      final attempt = StudentAttempt(
        id: 'a-default',
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        timestamp: now,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, attempt);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.isCorrect, isFalse);
      expect(restored.timeSpentMs, 0);
      expect(restored.confidence, 3);
      expect(restored.userAnswer, '');
      expect(restored.markschemeMatch, isNull);
      expect(restored.lastDueDate, isNull);
    });

    test('read and write round-trips with null optional fields', () {
      final adapter = StudentAttemptAdapter();
      final now = DateTime(2026, 5, 12);
      final attempt = StudentAttempt(
        id: 'a-nullable',
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        timestamp: now,
        markschemeMatch: null,
        lastDueDate: null,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, attempt);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.markschemeMatch, isNull);
      expect(restored.lastDueDate, isNull);
      expect(restored.id, 'a-nullable');
    });

    test('hashCode is consistent', () {
      final adapter1 = StudentAttemptAdapter();
      final adapter2 = StudentAttemptAdapter();

      expect(adapter1.hashCode, adapter2.hashCode);
    });

    test('== operator works correctly', () {
      final adapter1 = StudentAttemptAdapter();
      final adapter2 = StudentAttemptAdapter();
      final adapter3 = StudentAttemptAdapter();

      expect(adapter1 == adapter2, isTrue);
      expect(adapter1 == adapter3, isTrue);
      expect(adapter1 == Object(), isFalse);
      expect(adapter1 == adapter1, isTrue);
    });
  });
}
