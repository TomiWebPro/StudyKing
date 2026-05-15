import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';

void main() {
  group('SessionType', () {
    test('has expected values', () {
      expect(SessionType.values, [
        SessionType.practice,
        SessionType.focus,
        SessionType.tutoring,
        SessionType.manual,
      ]);
    });
  });

  group('Session', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
      test('creates with required fields', () {
        final session = Session(
          id: 'session-1',
          studentId: 'student-1',
          startTime: now,
        );
        expect(session.id, 'session-1');
        expect(session.studentId, 'student-1');
        expect(session.startTime, now);
        expect(session.type, SessionType.practice);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.endTime, isNull);
        expect(session.plannedDurationMinutes, isNull);
        expect(session.actualDurationMs, 0);
        expect(session.questionsAnswered, 0);
        expect(session.correctAnswers, 0);
        expect(session.completed, isFalse);
        expect(session.sourceId, isNull);
        expect(session.tags, isEmpty);
      });

      test('creates with all fields', () {
        final session = Session(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'subject-1',
          topicId: 'topic-1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          plannedDurationMinutes: 60,
          actualDurationMs: 3600000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['important'],
          createdAt: now,
        );
        expect(session.subjectId, 'subject-1');
        expect(session.topicId, 'topic-1');
        expect(session.type, SessionType.tutoring);
        expect(session.endTime, now.add(const Duration(hours: 1)));
        expect(session.plannedDurationMinutes, 60);
        expect(session.actualDurationMs, 3600000);
        expect(session.questionsAnswered, 10);
        expect(session.correctAnswers, 8);
        expect(session.completed, isTrue);
        expect(session.sourceId, 'source-1');
        expect(session.tags, ['important']);
        expect(session.createdAt, now);
      });

      test('defaults createdAt to now', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final session = Session(
          id: 's1',
          studentId: 's1',
          startTime: now,
        );
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(session.createdAt.isAfter(before), isTrue);
        expect(session.createdAt.isBefore(after), isTrue);
      });
    });

    group('isActive', () {
      test('returns true when not completed and no endTime', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        expect(session.isActive, isTrue);
      });

      test('returns false when completed', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          completed: true,
        );
        expect(session.isActive, isFalse);
      });

      test('returns false when endTime is set', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          endTime: now,
        );
        expect(session.isActive, isFalse);
      });
    });

    group('actualDuration', () {
      test('returns Duration from actualDurationMs', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          actualDurationMs: 5000,
        );
        expect(session.actualDuration, const Duration(milliseconds: 5000));
      });
    });

    group('plannedDuration', () {
      test('returns Duration when plannedDurationMinutes set', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          plannedDurationMinutes: 45,
        );
        expect(session.plannedDuration, const Duration(minutes: 45));
      });

      test('returns null when plannedDurationMinutes is null', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        expect(session.plannedDuration, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final session = Session(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'subject-1',
          topicId: 'topic-1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          plannedDurationMinutes: 60,
          actualDurationMs: 3600000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['important'],
          createdAt: now,
        );
        final json = session.toJson();
        expect(json['id'], 'session-1');
        expect(json['studentId'], 'student-1');
        expect(json['subjectId'], 'subject-1');
        expect(json['topicId'], 'topic-1');
        expect(json['type'], 'tutoring');
        expect(json['startTime'], now.toIso8601String());
        expect(json['endTime'], now.add(const Duration(hours: 1)).toIso8601String());
        expect(json['plannedDurationMinutes'], 60);
        expect(json['actualDurationMs'], 3600000);
        expect(json['questionsAnswered'], 10);
        expect(json['correctAnswers'], 8);
        expect(json['completed'], isTrue);
        expect(json['sourceId'], 'source-1');
        expect(json['tags'], ['important']);
        expect(json['createdAt'], now.toIso8601String());
      });

      test('serializes with null optionals', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final json = session.toJson();
        expect(json['subjectId'], isNull);
        expect(json['topicId'], isNull);
        expect(json['endTime'], isNull);
        expect(json['plannedDurationMinutes'], isNull);
        expect(json['sourceId'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': 'session-1',
          'studentId': 'student-1',
          'subjectId': 'subject-1',
          'topicId': 'topic-1',
          'type': 'tutoring',
          'startTime': now.toIso8601String(),
          'endTime': now.add(const Duration(hours: 1)).toIso8601String(),
          'plannedDurationMinutes': 60,
          'actualDurationMs': 3600000,
          'questionsAnswered': 10,
          'correctAnswers': 8,
          'completed': true,
          'sourceId': 'source-1',
          'tags': ['important'],
          'createdAt': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.id, 'session-1');
        expect(session.studentId, 'student-1');
        expect(session.subjectId, 'subject-1');
        expect(session.type, SessionType.tutoring);
        expect(session.endTime, now.add(const Duration(hours: 1)));
        expect(session.plannedDurationMinutes, 60);
        expect(session.questionsAnswered, 10);
        expect(session.completed, isTrue);
        expect(session.tags, ['important']);
      });

      test('deserializes with missing optionals', () {
        final json = {
          'id': 'session-1',
          'studentId': 'student-1',
          'startTime': now.toIso8601String(),
        };
        final session = Session.fromJson(json);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.type, SessionType.practice);
        expect(session.endTime, isNull);
        expect(session.plannedDurationMinutes, isNull);
        expect(session.actualDurationMs, 0);
        expect(session.completed, isFalse);
        expect(session.tags, isEmpty);
      });

      test('handles null type defaults to practice', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'type': null,
        };
        final session = Session.fromJson(json);
        expect(session.type, SessionType.practice);
      });

      test('handles invalid type string defaults to practice', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'type': 'unknown_type',
        };
        final session = Session.fromJson(json);
        expect(session.type, SessionType.practice);
      });

      test('handles null tags defaults to empty list', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'tags': null,
        };
        final session = Session.fromJson(json);
        expect(session.tags, isEmpty);
      });

      test('handles all session types by name', () {
        for (final type in SessionType.values) {
          final json = {
            'id': 's1',
            'studentId': 's1',
            'startTime': now.toIso8601String(),
            'type': type.name,
          };
          final session = Session.fromJson(json);
          expect(session.type, type);
        }
      });

      test('throws on malformed startTime', () {
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': 'not-a-date',
        };
        expect(() => Session.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('handles null createdAt defaults to now', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final json = {
          'id': 's1',
          'studentId': 's1',
          'startTime': now.toIso8601String(),
          'createdAt': null,
        };
        final session = Session.fromJson(json);
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(session.createdAt.isAfter(before), isTrue);
        expect(session.createdAt.isBefore(after), isTrue);
      });
    });

    group('serialization roundtrip', () {
      test('toJson then fromJson preserves data', () {
        final original = Session(
          id: 'session-1',
          studentId: 'student-1',
          subjectId: 'subject-1',
          topicId: 'topic-1',
          type: SessionType.tutoring,
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          plannedDurationMinutes: 60,
          actualDurationMs: 3600000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['important'],
          createdAt: now,
        );
        final json = original.toJson();
        final restored = Session.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.type, original.type);
        expect(restored.startTime, original.startTime);
        expect(restored.questionsAnswered, original.questionsAnswered);
        expect(restored.correctAnswers, original.correctAnswers);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          subjectId: 'sub', topicId: 'topic',
          type: SessionType.tutoring, endTime: now,
          plannedDurationMinutes: 45, actualDurationMs: 1000,
          questionsAnswered: 5, correctAnswers: 4, completed: true,
          sourceId: 'src', tags: ['tag'], createdAt: now,
        );
        final copy = session.copyWith();
        expect(copy.id, session.id);
        expect(copy.studentId, session.studentId);
        expect(copy.subjectId, session.subjectId);
        expect(copy.topicId, session.topicId);
        expect(copy.type, session.type);
        expect(copy.startTime, session.startTime);
        expect(copy.endTime, session.endTime);
        expect(copy.plannedDurationMinutes, session.plannedDurationMinutes);
        expect(copy.actualDurationMs, session.actualDurationMs);
        expect(copy.questionsAnswered, session.questionsAnswered);
        expect(copy.correctAnswers, session.correctAnswers);
        expect(copy.completed, session.completed);
        expect(copy.sourceId, session.sourceId);
        expect(copy.tags, session.tags);
        expect(copy.createdAt, session.createdAt);
      });

      test('updates specified fields', () {
        final session = Session(id: 's1', studentId: 's1', startTime: now);
        final copy = session.copyWith(
          completed: true,
          questionsAnswered: 10,
          correctAnswers: 8,
        );
        expect(copy.completed, isTrue);
        expect(copy.questionsAnswered, 10);
        expect(copy.correctAnswers, 8);
        expect(copy.id, 's1');
      });

      test('clearEndTime sets endTime to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          endTime: now,
        );
        final copy = session.copyWith(clearEndTime: true);
        expect(copy.endTime, isNull);
      });

      test('clearSubjectId sets subjectId to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          subjectId: 'sub',
        );
        final copy = session.copyWith(clearSubjectId: true);
        expect(copy.subjectId, isNull);
      });

      test('clearTopicId sets topicId to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          topicId: 'topic',
        );
        final copy = session.copyWith(clearTopicId: true);
        expect(copy.topicId, isNull);
      });

      test('clearSourceId sets sourceId to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          sourceId: 'src',
        );
        final copy = session.copyWith(clearSourceId: true);
        expect(copy.sourceId, isNull);
      });

      test('clearPlannedDuration sets plannedDurationMinutes to null', () {
        final session = Session(
          id: 's1', studentId: 's1', startTime: now,
          plannedDurationMinutes: 45,
        );
        final copy = session.copyWith(clearPlannedDuration: true);
        expect(copy.plannedDurationMinutes, isNull);
      });
    });

    group('equality', () {
      test('uses id-based equality', () {
        final a = Session(id: 's1', studentId: 's1', startTime: now);
        final b = Session(id: 's2', studentId: 's2', startTime: now);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('equal when same id', () {
        final a = Session(id: 's1', studentId: 's1', startTime: now);
        final b = Session(id: 's1', studentId: 's2', startTime: now);
        expect(a == b, isTrue);
      });

      test('hashCode is id-based', () {
        final a = Session(id: 's1', studentId: 's1', startTime: now);
        final b = Session(id: 's1', studentId: 's2', startTime: now);
        expect(a.hashCode, b.hashCode);
      });

      test('hashCode is consistent', () {
        final obj = Session(id: 's1', studentId: 's1', startTime: now);
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = Session(id: 's1', studentId: 's1', startTime: now);
        expect(obj.toString(), contains('Session'));
      });
    });
  });
}
