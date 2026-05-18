import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/data/focus_session_model.dart';

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
  });
}
