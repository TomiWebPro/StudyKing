import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';

void main() {
  group('FocusSession', () {
    final now = DateTime(2026, 5, 18);
    final endTime = DateTime(2026, 5, 18, 0, 30);
    const id = 'focus-1';
    const studentId = 'student-1';

    test('creates instance with required fields', () {
      final session = FocusSession(id: id, studentId: studentId, startTime: now);
      expect(session.id, id);
      expect(session.studentId, studentId);
      expect(session.startTime, now);
      expect(session.endTime, isNull);
      expect(session.durationMinutes, 25);
      expect(session.questionsAnswered, 0);
      expect(session.correctAnswers, 0);
      expect(session.accuracy, 0.0);
      expect(session.subjectIds, isEmpty);
      expect(session.masteryChanges, isEmpty);
    });

    test('creates instance with all fields', () {
      final session = FocusSession(
        id: id,
        studentId: studentId,
        startTime: now,
        endTime: endTime,
        durationMinutes: 45,
        questionsAnswered: 20,
        correctAnswers: 15,
        accuracy: 0.75,
        subjectIds: ['subj-1', 'subj-2'],
        masteryChanges: {'subj-1': 0.1},
      );
      expect(session.id, id);
      expect(session.studentId, studentId);
      expect(session.startTime, now);
      expect(session.endTime, endTime);
      expect(session.durationMinutes, 45);
      expect(session.questionsAnswered, 20);
      expect(session.correctAnswers, 15);
      expect(session.accuracy, 0.75);
      expect(session.subjectIds, ['subj-1', 'subj-2']);
      expect(session.masteryChanges, {'subj-1': 0.1});
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now, endTime: endTime,
          durationMinutes: 30, questionsAnswered: 10, correctAnswers: 7,
          accuracy: 0.7, subjectIds: ['subj-1'],
          masteryChanges: {'subj-1': 0.05},
        );
        final json = session.toJson();
        expect(json['id'], id);
        expect(json['studentId'], studentId);
        expect(json['startTime'], now.toIso8601String());
        expect(json['endTime'], endTime.toIso8601String());
        expect(json['durationMinutes'], 30);
        expect(json['questionsAnswered'], 10);
        expect(json['correctAnswers'], 7);
        expect(json['accuracy'], 0.7);
        expect(json['subjectIds'], ['subj-1']);
        expect(json['masteryChanges'], {'subj-1': 0.05});
      });

      test('serializes null endTime as null', () {
        final session = FocusSession(id: id, studentId: studentId, startTime: now);
        final json = session.toJson();
        expect(json['endTime'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes with all fields', () {
        final json = {
          'id': id,
          'studentId': studentId,
          'startTime': now.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'durationMinutes': 30,
          'questionsAnswered': 10,
          'correctAnswers': 7,
          'accuracy': 0.7,
          'subjectIds': ['subj-1'],
          'masteryChanges': <String, double>{'subj-1': 0.05},
        };
        final restored = FocusSession.fromJson(json);
        expect(restored.id, id);
        expect(restored.studentId, studentId);
        expect(restored.startTime, now);
        expect(restored.endTime, endTime);
        expect(restored.durationMinutes, 30);
        expect(restored.questionsAnswered, 10);
        expect(restored.correctAnswers, 7);
        expect(restored.accuracy, 0.7);
        expect(restored.subjectIds, ['subj-1']);
        expect(restored.masteryChanges, {'subj-1': 0.05});
      });

      test('deserializes with null endTime', () {
        final json = {
          'id': id,
          'studentId': studentId,
          'startTime': now.toIso8601String(),
          'endTime': null,
        };
        final restored = FocusSession.fromJson(json);
        expect(restored.endTime, isNull);
      });

      test('applies defaults for missing optional fields', () {
        final json = {
          'id': id,
          'studentId': studentId,
          'startTime': now.toIso8601String(),
          'endTime': null,
        };
        final restored = FocusSession.fromJson(json);
        expect(restored.durationMinutes, 25);
        expect(restored.questionsAnswered, 0);
        expect(restored.correctAnswers, 0);
        expect(restored.accuracy, 0.0);
        expect(restored.subjectIds, isEmpty);
        expect(restored.masteryChanges, isEmpty);
      });

      test('handles integer accuracy value (num coerced to double)', () {
        final json = {
          'id': id,
          'studentId': studentId,
          'startTime': now.toIso8601String(),
          'accuracy': 5,
        };
        final restored = FocusSession.fromJson(json);
        expect(restored.accuracy, 5.0);
      });

      test('deserializes subjectIds and masteryChanges when present', () {
        final json = {
          'id': id,
          'studentId': studentId,
          'startTime': now.toIso8601String(),
          'subjectIds': ['a', 'b'],
          'masteryChanges': {'a': 0.1, 'b': -0.05},
        };
        final restored = FocusSession.fromJson(json);
        expect(restored.subjectIds, ['a', 'b']);
        expect(restored.masteryChanges, {'a': 0.1, 'b': -0.05});
      });

      test('handles round-trip serialization and deserialization', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now, endTime: endTime,
          durationMinutes: 30, questionsAnswered: 10, correctAnswers: 7,
          accuracy: 0.7, subjectIds: ['subj-1'],
          masteryChanges: {'subj-1': 0.05},
        );
        final json = session.toJson();
        final restored = FocusSession.fromJson(json);
        expect(restored.id, session.id);
        expect(restored.studentId, session.studentId);
        expect(restored.startTime, session.startTime);
        expect(restored.endTime, session.endTime);
        expect(restored.durationMinutes, session.durationMinutes);
        expect(restored.questionsAnswered, session.questionsAnswered);
        expect(restored.correctAnswers, session.correctAnswers);
        expect(restored.accuracy, session.accuracy);
        expect(restored.subjectIds, session.subjectIds);
        expect(restored.masteryChanges, session.masteryChanges);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no arguments given', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          endTime: endTime, durationMinutes: 45, questionsAnswered: 20,
          correctAnswers: 15, accuracy: 0.75,
          subjectIds: ['subj-1'], masteryChanges: {'subj-1': 0.1},
        );
        final copy = session.copyWith();
        expect(copy.id, session.id);
        expect(copy.studentId, session.studentId);
        expect(copy.startTime, session.startTime);
        expect(copy.endTime, session.endTime);
        expect(copy.durationMinutes, session.durationMinutes);
        expect(copy.questionsAnswered, session.questionsAnswered);
        expect(copy.correctAnswers, session.correctAnswers);
        expect(copy.accuracy, session.accuracy);
        expect(copy.subjectIds, session.subjectIds);
        expect(copy.masteryChanges, session.masteryChanges);
      });

      test('overrides single field at a time', () {
        final session = FocusSession(id: id, studentId: studentId, startTime: now);

        expect(session.copyWith(durationMinutes: 99).durationMinutes, 99);
        expect(session.copyWith(questionsAnswered: 50).questionsAnswered, 50);
        expect(session.copyWith(correctAnswers: 40).correctAnswers, 40);
        expect(session.copyWith(accuracy: 0.5).accuracy, 0.5);
        expect(session.copyWith(endTime: endTime).endTime, endTime);
        expect(session.copyWith(subjectIds: ['x']).subjectIds, ['x']);
        expect(
          session.copyWith(masteryChanges: {'x': 0.2}).masteryChanges,
          {'x': 0.2},
        );
        expect(session.copyWith(id: 'new-id').id, 'new-id');
        expect(session.copyWith(studentId: 'new-stu').studentId, 'new-stu');
        expect(
          session.copyWith(startTime: DateTime(2025)).startTime,
          DateTime(2025),
        );
      });

      test('preserves unchanged fields when overriding others', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          durationMinutes: 25, accuracy: 0.0,
        );
        final copy = session.copyWith(durationMinutes: 60, questionsAnswered: 10);
        expect(copy.id, id);
        expect(copy.studentId, studentId);
        expect(copy.startTime, now);
        expect(copy.endTime, isNull);
        expect(copy.durationMinutes, 60);
        expect(copy.questionsAnswered, 10);
        expect(copy.correctAnswers, 0);
        expect(copy.accuracy, 0.0);
      });

      test('overrides all fields at once', () {
        final session = FocusSession(id: id, studentId: studentId, startTime: now);
        final copy = session.copyWith(
          id: 'new-id',
          studentId: 'new-stu',
          startTime: DateTime(2025),
          endTime: DateTime(2025, 1, 1, 1),
          durationMinutes: 99,
          questionsAnswered: 100,
          correctAnswers: 90,
          accuracy: 0.9,
          subjectIds: ['new-subj'],
          masteryChanges: {'new-subj': 0.5},
        );
        expect(copy.id, 'new-id');
        expect(copy.studentId, 'new-stu');
        expect(copy.startTime, DateTime(2025));
        expect(copy.endTime, DateTime(2025, 1, 1, 1));
        expect(copy.durationMinutes, 99);
        expect(copy.questionsAnswered, 100);
        expect(copy.correctAnswers, 90);
        expect(copy.accuracy, 0.9);
        expect(copy.subjectIds, ['new-subj']);
        expect(copy.masteryChanges, {'new-subj': 0.5});
      });
    });

    group('edge cases', () {
      test('handles null endTime', () {
        final session = FocusSession(id: id, studentId: studentId, startTime: now);
        expect(session.endTime, isNull);
      });

      test('handles extreme value for durationMinutes', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          durationMinutes: 999999,
        );
        expect(session.durationMinutes, 999999);
      });

      test('handles zero durationMinutes', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          durationMinutes: 0,
        );
        expect(session.durationMinutes, 0);
      });

      test('handles negative accuracy', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          accuracy: -1.0,
        );
        expect(session.accuracy, -1.0);
      });

      test('handles extreme accuracy values', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          accuracy: 1.7976931348623157e+308,
        );
        expect(session.accuracy, 1.7976931348623157e+308);
      });

      test('handles empty subjectIds', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          subjectIds: [],
        );
        expect(session.subjectIds, isEmpty);
      });

      test('handles empty masteryChanges', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          masteryChanges: {},
        );
        expect(session.masteryChanges, isEmpty);
      });

      test('handles large number of subjectIds', () {
        final subjects = List.generate(100, (i) => 'subj-$i');
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          subjectIds: subjects,
        );
        expect(session.subjectIds.length, 100);
      });

      test('handles large masteryChanges map', () {
        final changes = {for (int i = 0; i < 100; i++) 'subj-$i': i * 0.01};
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          masteryChanges: changes,
        );
        expect(session.masteryChanges.length, 100);
      });
    });
  });
}
