import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';

void main() {
  group('Session', () {
    late DateTime now;
    late Session baseSession;

    setUp(() {
      now = DateTime(2026, 5, 14, 10, 30);
      baseSession = Session(
        id: 'test-1',
        studentId: 'student-1',
        startTime: now,
      );
    });

    group('constructor', () {
      test('creates with required fields and default values', () {
        final session = Session(
          id: 's1',
          studentId: 's1',
          startTime: now,
        );

        expect(session.id, 's1');
        expect(session.studentId, 's1');
        expect(session.startTime, now);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.type, SessionType.practice);
        expect(session.endTime, isNull);
        expect(session.plannedDurationMinutes, isNull);
        expect(session.actualDurationMs, 0);
        expect(session.questionsAnswered, 0);
        expect(session.correctAnswers, 0);
        expect(session.completed, false);
        expect(session.sourceId, isNull);
        expect(session.tags, isEmpty);
        expect(session.createdAt, isNotNull);
      });

      test('creates with all fields', () {
        final session = Session(
          id: 's2',
          studentId: 's2',
          subjectId: 'subj-1',
          topicId: 'topic-1',
          type: SessionType.focus,
          startTime: now,
          endTime: now.add(const Duration(minutes: 30)),
          plannedDurationMinutes: 30,
          actualDurationMs: 1800000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['tag1', 'tag2'],
          createdAt: now,
        );

        expect(session.id, 's2');
        expect(session.subjectId, 'subj-1');
        expect(session.topicId, 'topic-1');
        expect(session.type, SessionType.focus);
        expect(session.endTime, now.add(const Duration(minutes: 30)));
        expect(session.plannedDurationMinutes, 30);
        expect(session.actualDurationMs, 1800000);
        expect(session.questionsAnswered, 10);
        expect(session.correctAnswers, 8);
        expect(session.completed, true);
        expect(session.sourceId, 'source-1');
        expect(session.tags, ['tag1', 'tag2']);
      });
    });

    group('computed properties', () {
      test('isActive returns true when not completed and no endTime', () {
        expect(baseSession.isActive, isTrue);
      });

      test('isActive returns false when completed', () {
        final session = baseSession.copyWith(completed: true);
        expect(session.isActive, isFalse);
      });

      test('isActive returns false when endTime is set', () {
        final session = baseSession.copyWith(endTime: now);
        expect(session.isActive, isFalse);
      });

      test('actualDuration returns correct Duration from ms', () {
        final session = baseSession.copyWith(actualDurationMs: 3661000);
        expect(session.actualDuration, const Duration(milliseconds: 3661000));
      });

      test('plannedDuration returns null when not set', () {
        expect(baseSession.plannedDuration, isNull);
      });

      test('plannedDuration returns correct Duration when set', () {
        final session = baseSession.copyWith(plannedDurationMinutes: 25);
        expect(session.plannedDuration, const Duration(minutes: 25));
      });
    });

    group('copyWith', () {
      test('returns identical session with no arguments', () {
        final copy = baseSession.copyWith();
        expect(copy.id, baseSession.id);
        expect(copy.studentId, baseSession.studentId);
        expect(copy.startTime, baseSession.startTime);
      });

      test('updates specified fields', () {
        final updated = baseSession.copyWith(
          endTime: now.add(const Duration(minutes: 25)),
          actualDurationMs: 1500000,
          completed: true,
          subjectId: 'subj-math',
          type: SessionType.focus,
        );

        expect(updated.endTime, now.add(const Duration(minutes: 25)));
        expect(updated.actualDurationMs, 1500000);
        expect(updated.completed, true);
        expect(updated.subjectId, 'subj-math');
        expect(updated.type, SessionType.focus);
        expect(updated.id, baseSession.id);
      });

      test('clearEndTime sets endTime to null', () {
        final session = baseSession.copyWith(endTime: now);
        final cleared = session.copyWith(clearEndTime: true);
        expect(cleared.endTime, isNull);
      });

      test('clearSubjectId sets subjectId to null', () {
        final session = baseSession.copyWith(subjectId: 'subj');
        final cleared = session.copyWith(clearSubjectId: true);
        expect(cleared.subjectId, isNull);
      });

      test('clearPlannedDuration sets plannedDurationMinutes to null', () {
        final session = baseSession.copyWith(plannedDurationMinutes: 30);
        final cleared = session.copyWith(clearPlannedDuration: true);
        expect(cleared.plannedDurationMinutes, isNull);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final session = Session(
          id: 'json-1',
          studentId: 'student-1',
          subjectId: 'subj-1',
          topicId: 'topic-1',
          type: SessionType.focus,
          startTime: now,
          endTime: now.add(const Duration(minutes: 30)),
          plannedDurationMinutes: 30,
          actualDurationMs: 1800000,
          questionsAnswered: 10,
          correctAnswers: 8,
          completed: true,
          sourceId: 'source-1',
          tags: ['tag1'],
          createdAt: now,
        );

        final json = session.toJson();

        expect(json['id'], 'json-1');
        expect(json['studentId'], 'student-1');
        expect(json['subjectId'], 'subj-1');
        expect(json['topicId'], 'topic-1');
        expect(json['type'], 'focus');
        expect(json['startTime'], now.toIso8601String());
        expect(json['endTime'], now.add(const Duration(minutes: 30)).toIso8601String());
        expect(json['plannedDurationMinutes'], 30);
        expect(json['actualDurationMs'], 1800000);
        expect(json['questionsAnswered'], 10);
        expect(json['correctAnswers'], 8);
        expect(json['completed'], true);
        expect(json['sourceId'], 'source-1');
        expect(json['tags'], ['tag1']);
        expect(json['createdAt'], now.toIso8601String());
      });

      test('fromJson creates correct session', () {
        final json = {
          'id': 'json-2',
          'studentId': 'student-2',
          'subjectId': 'subj-2',
          'topicId': 'topic-2',
          'type': 'practice',
          'startTime': now.toIso8601String(),
          'endTime': now.add(const Duration(minutes: 15)).toIso8601String(),
          'plannedDurationMinutes': 15,
          'actualDurationMs': 900000,
          'questionsAnswered': 5,
          'correctAnswers': 4,
          'completed': true,
          'sourceId': null,
          'tags': [],
          'createdAt': now.toIso8601String(),
        };

        final session = Session.fromJson(json);

        expect(session.id, 'json-2');
        expect(session.studentId, 'student-2');
        expect(session.subjectId, 'subj-2');
        expect(session.topicId, 'topic-2');
        expect(session.type, SessionType.practice);
        expect(session.startTime, now);
        expect(session.endTime, now.add(const Duration(minutes: 15)));
        expect(session.plannedDurationMinutes, 15);
        expect(session.actualDurationMs, 900000);
        expect(session.questionsAnswered, 5);
        expect(session.correctAnswers, 4);
        expect(session.completed, true);
        expect(session.createdAt, now);
      });

      test('fromJson handles null values', () {
        final json = {
          'id': 'json-3',
          'studentId': 'student-3',
          'startTime': now.toIso8601String(),
          'createdAt': now.toIso8601String(),
        };

        final session = Session.fromJson(json);

        expect(session.endTime, isNull);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.type, SessionType.practice);
        expect(session.actualDurationMs, 0);
        expect(session.questionsAnswered, 0);
        expect(session.correctAnswers, 0);
        expect(session.completed, false);
        expect(session.tags, isEmpty);
      });

      test('JSON round-trip preserves data', () {
        final original = Session(
          id: 'roundtrip-1',
          studentId: 'student-1',
          subjectId: 'subj-math',
          topicId: 'topic-algebra',
          type: SessionType.focus,
          startTime: now,
          endTime: now.add(const Duration(minutes: 45)),
          plannedDurationMinutes: 45,
          actualDurationMs: 2700000,
          questionsAnswered: 20,
          correctAnswers: 18,
          completed: true,
          sourceId: 'source-1',
          tags: ['exam', 'review'],
          createdAt: now,
        );

        final json = original.toJson();
        final restored = Session.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.studentId, original.studentId);
        expect(restored.subjectId, original.subjectId);
        expect(restored.topicId, original.topicId);
        expect(restored.type, original.type);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
        expect(restored.plannedDurationMinutes, original.plannedDurationMinutes);
        expect(restored.actualDurationMs, original.actualDurationMs);
        expect(restored.questionsAnswered, original.questionsAnswered);
        expect(restored.correctAnswers, original.correctAnswers);
        expect(restored.completed, original.completed);
        expect(restored.sourceId, original.sourceId);
        expect(restored.tags, original.tags);
        expect(restored.createdAt, original.createdAt);
      });
    });

    group('equality', () {
      test('sessions with same id are equal', () {
        final s1 = Session(id: 's1', studentId: 's1', startTime: now);
        final s2 = Session(id: 's1', studentId: 's2', startTime: now.add(const Duration(hours: 1)));
        expect(s1 == s2, isTrue);
        expect(s1.hashCode, s2.hashCode);
      });

      test('sessions with different ids are not equal', () {
        final s1 = Session(id: 's1', studentId: 's1', startTime: now);
        final s2 = Session(id: 's2', studentId: 's1', startTime: now);
        expect(s1 == s2, isFalse);
      });
    });
  });
}
