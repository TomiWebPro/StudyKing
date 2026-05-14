import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';

void main() {
  group('FocusSession', () {
    late DateTime now;
    late FocusSession baseSession;

    setUp(() {
      now = DateTime(2026, 5, 14, 10, 30);
      baseSession = FocusSession(
        id: 'test-1',
        startTime: now,
        plannedDurationMinutes: 25,
      );
    });

    group('constructor', () {
      test('creates with required fields and default values', () {
        final session = FocusSession(
          id: 's1',
          startTime: now,
          plannedDurationMinutes: 25,
        );

        expect(session.id, 's1');
        expect(session.startTime, now);
        expect(session.plannedDurationMinutes, 25);
        expect(session.endTime, isNull);
        expect(session.actualDurationSeconds, 0);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.completed, false);
        expect(session.createdAt, isNotNull);
      });

      test('creates with all fields', () {
        final session = FocusSession(
          id: 's2',
          startTime: now,
          endTime: now.add(const Duration(minutes: 25)),
          plannedDurationMinutes: 30,
          actualDurationSeconds: 1500,
          subjectId: 'subj-1',
          topicId: 'topic-1',
          completed: true,
          createdAt: now,
        );

        expect(session.id, 's2');
        expect(session.endTime, now.add(const Duration(minutes: 25)));
        expect(session.actualDurationSeconds, 1500);
        expect(session.subjectId, 'subj-1');
        expect(session.topicId, 'topic-1');
        expect(session.completed, true);
      });
    });

    group('computed properties', () {
      test('actualDuration returns correct Duration', () {
        final session = FocusSession(
          id: 's1',
          startTime: now,
          plannedDurationMinutes: 25,
          actualDurationSeconds: 3661,
        );
        expect(session.actualDuration, const Duration(seconds: 3661));
      });

      test('plannedDuration returns correct Duration', () {
        expect(baseSession.plannedDuration, const Duration(minutes: 25));
      });

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

      test('isActive returns false when both completed and endTime set', () {
        final session = baseSession.copyWith(
          completed: true,
          endTime: now,
        );
        expect(session.isActive, isFalse);
      });
    });

    group('copyWith', () {
      test('returns identical session with no arguments', () {
        final copy = baseSession.copyWith();
        expect(copy.id, baseSession.id);
        expect(copy.startTime, baseSession.startTime);
        expect(copy.endTime, baseSession.endTime);
        expect(copy.plannedDurationMinutes, baseSession.plannedDurationMinutes);
        expect(copy.actualDurationSeconds, baseSession.actualDurationSeconds);
        expect(copy.subjectId, baseSession.subjectId);
        expect(copy.topicId, baseSession.topicId);
        expect(copy.completed, baseSession.completed);
      });

      test('updates specified fields', () {
        final updated = baseSession.copyWith(
          endTime: now.add(const Duration(minutes: 25)),
          actualDurationSeconds: 1500,
          completed: true,
          subjectId: 'subj-math',
        );

        expect(updated.endTime, now.add(const Duration(minutes: 25)));
        expect(updated.actualDurationSeconds, 1500);
        expect(updated.completed, true);
        expect(updated.subjectId, 'subj-math');
        expect(updated.id, baseSession.id);
        expect(updated.plannedDurationMinutes, 25);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final session = FocusSession(
          id: 'json-1',
          startTime: now,
          endTime: now.add(const Duration(minutes: 30)),
          plannedDurationMinutes: 30,
          actualDurationSeconds: 1800,
          subjectId: 'subj-1',
          topicId: 'topic-1',
          completed: true,
          createdAt: now,
        );

        final json = session.toJson();

        expect(json['id'], 'json-1');
        expect(json['startTime'], now.toIso8601String());
        expect(json['endTime'], now.add(const Duration(minutes: 30)).toIso8601String());
        expect(json['plannedDurationMinutes'], 30);
        expect(json['actualDurationSeconds'], 1800);
        expect(json['subjectId'], 'subj-1');
        expect(json['topicId'], 'topic-1');
        expect(json['completed'], true);
        expect(json['createdAt'], now.toIso8601String());
      });

      test('fromJson creates correct session', () {
        final json = {
          'id': 'json-2',
          'startTime': now.toIso8601String(),
          'endTime': now.add(const Duration(minutes: 15)).toIso8601String(),
          'plannedDurationMinutes': 15,
          'actualDurationSeconds': 900,
          'subjectId': 'subj-2',
          'topicId': 'topic-2',
          'completed': true,
          'createdAt': now.toIso8601String(),
        };

        final session = FocusSession.fromJson(json);

        expect(session.id, 'json-2');
        expect(session.startTime, now);
        expect(session.endTime, now.add(const Duration(minutes: 15)));
        expect(session.plannedDurationMinutes, 15);
        expect(session.actualDurationSeconds, 900);
        expect(session.subjectId, 'subj-2');
        expect(session.topicId, 'topic-2');
        expect(session.completed, true);
        expect(session.createdAt, now);
      });

      test('fromJson handles null endTime', () {
        final json = {
          'id': 'json-3',
          'startTime': now.toIso8601String(),
          'plannedDurationMinutes': 25,
          'actualDurationSeconds': null,
          'subjectId': null,
          'topicId': null,
          'completed': null,
          'createdAt': now.toIso8601String(),
        };

        final session = FocusSession.fromJson(json);

        expect(session.endTime, isNull);
        expect(session.actualDurationSeconds, 0);
        expect(session.subjectId, isNull);
        expect(session.topicId, isNull);
        expect(session.completed, false);
      });

      test('toJson handles null fields', () {
        final json = baseSession.toJson();

        expect(json['endTime'], isNull);
        expect(json['subjectId'], isNull);
        expect(json['topicId'], isNull);
      });

      test('JSON round-trip preserves data', () {
        final original = FocusSession(
          id: 'roundtrip-1',
          startTime: now,
          endTime: now.add(const Duration(minutes: 45)),
          plannedDurationMinutes: 45,
          actualDurationSeconds: 2700,
          subjectId: 'subj-math',
          topicId: 'topic-algebra',
          completed: true,
          createdAt: now,
        );

        final json = original.toJson();
        final restored = FocusSession.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
        expect(restored.plannedDurationMinutes, original.plannedDurationMinutes);
        expect(restored.actualDurationSeconds, original.actualDurationSeconds);
        expect(restored.subjectId, original.subjectId);
        expect(restored.topicId, original.topicId);
        expect(restored.completed, original.completed);
      });
    });
  });
}
