import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';

void main() {
  group('FocusSession', () {
    final now = DateTime(2026, 5, 18);
    const id = 'focus-1';
    const studentId = 'student-1';

    test('creates instance with required fields', () {
      final session = FocusSession(id: id, studentId: studentId, startTime: now);
      expect(session.id, id);
      expect(session.studentId, studentId);
      expect(session.startTime, now);
      expect(session.durationMinutes, 25);
      expect(session.questionsAnswered, 0);
      expect(session.accuracy, 0.0);
    });

    test('serializes and deserializes', () {
      final session = FocusSession(
        id: id, studentId: studentId, startTime: now,
        durationMinutes: 30, questionsAnswered: 10, correctAnswers: 7,
        accuracy: 0.7, subjectIds: ['subj-1'],
      );
      final json = session.toJson();
      final restored = FocusSession.fromJson(json);
      expect(restored.durationMinutes, 30);
      expect(restored.questionsAnswered, 10);
      expect(restored.correctAnswers, 7);
      expect(restored.accuracy, 0.7);
      expect(restored.subjectIds, ['subj-1']);
    });

    test('copyWith preserves fields', () {
      final session = FocusSession(id: id, studentId: studentId, startTime: now);
      final copy = session.copyWith(durationMinutes: 45, questionsAnswered: 5);
      expect(copy.durationMinutes, 45);
      expect(copy.questionsAnswered, 5);
      expect(copy.id, id);
    });

    group('edge cases', () {
      test('handles null endTime', () {
        final session = FocusSession(id: id, studentId: studentId, startTime: now);
        expect(session.endTime, isNull);
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'id': id,
          'studentId': studentId,
          'startTime': now.toIso8601String(),
          'endTime': null,
        };
        final restored = FocusSession.fromJson(json);
        expect(restored.endTime, isNull);
        expect(restored.durationMinutes, 25);
        expect(restored.questionsAnswered, 0);
      });

      test('handles extreme value for durationMinutes', () {
        final session = FocusSession(
          id: id, studentId: studentId, startTime: now,
          durationMinutes: 999999,
        );
        expect(session.durationMinutes, 999999);
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
    });
  });
}
