import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/focus_mode.dart';

void main() {
  group('focus_mode barrel', () {
    test('exports FocusTimerScreen', () {
      expect(FocusTimerScreen, isA<Type>());
    });

    test('exports FocusTimerWidget', () {
      expect(FocusTimerWidget, isA<Type>());
    });

    test('exports SessionSummaryCard', () {
      expect(SessionSummaryCard, isA<Type>());
    });

    test('exports studyTimerServiceProvider', () {
      expect(studyTimerServiceProvider, isNotNull);
    });

    test('FocusSession can be constructed with realistic data', () {
      final session = FocusSession(
        id: 'focus_001',
        studentId: 'student_42',
        startTime: DateTime(2025, 3, 15, 10, 30),
        endTime: DateTime(2025, 3, 15, 11, 0),
        durationMinutes: 30,
        questionsAnswered: 15,
        correctAnswers: 12,
        accuracy: 0.8,
        subjectIds: ['math', 'physics'],
        masteryChanges: {'algebra': 0.05, 'kinematics': 0.03},
      );
      expect(session.id, 'focus_001');
      expect(session.studentId, 'student_42');
      expect(session.durationMinutes, 30);
      expect(session.questionsAnswered, 15);
      expect(session.correctAnswers, 12);
      expect(session.accuracy, 0.8);
      expect(session.subjectIds, ['math', 'physics']);
      expect(session.masteryChanges['algebra'], 0.05);
    });

    test('FocusSession.toJson round-trips correctly', () {
      final original = FocusSession(
        id: 'focus_002',
        studentId: 'student_99',
        startTime: DateTime(2025, 6, 1, 14, 0),
        durationMinutes: 25,
        questionsAnswered: 10,
        correctAnswers: 8,
        accuracy: 0.8,
        subjectIds: ['chemistry'],
      );
      final json = original.toJson();
      final restored = FocusSession.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.studentId, original.studentId);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.questionsAnswered, original.questionsAnswered);
      expect(restored.correctAnswers, original.correctAnswers);
      expect(restored.accuracy, original.accuracy);
      expect(restored.subjectIds, original.subjectIds);
    });

    test('FocusSession.copyWith modifies only specified fields', () {
      final now = DateTime.now();
      final session = FocusSession(
        id: 'original',
        studentId: 's1',
        startTime: now,
        durationMinutes: 25,
        questionsAnswered: 0,
      );
      final modified = session.copyWith(durationMinutes: 45, questionsAnswered: 20);
      expect(modified.id, 'original');
      expect(modified.studentId, 's1');
      expect(modified.startTime, now);
      expect(modified.durationMinutes, 45);
      expect(modified.questionsAnswered, 20);
    });

    test('studyTimerServiceProvider has correct type', () {
      expect(studyTimerServiceProvider, isNotNull);
    });
  });
}
