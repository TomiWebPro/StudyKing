import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/sessions.dart';

void main() {
  group('sessions barrel', () {
    test('exports SessionRepository', () {
      expect(SessionRepository, isA<Type>());
    });

    test('exports sessionRepositoryProvider', () {
      expect(sessionRepositoryProvider, isNotNull);
    });

    test('exports allSessionsProvider', () {
      expect(allSessionsProvider, isNotNull);
    });

    test('exports todayStatsProvider', () {
      expect(todayStatsProvider, isNotNull);
    });

    test('exports SessionHistoryScreen', () {
      expect(SessionHistoryScreen, isA<Type>());
    });

    test('exports SessionTrackerScreen', () {
      expect(SessionTrackerScreen, isA<Type>());
    });

    test('exports SessionAnalyticsWidget', () {
      expect(SessionAnalyticsWidget, isA<Type>());
    });

    test('exports SessionExportService', () {
      expect(SessionExportService, isA<Type>());
    });

    test('exports StudyTimerService', () {
      expect(StudyTimerService, isA<Type>());
    });

    test('exports SessionMigrationService', () {
      expect(SessionMigrationService, isA<Type>());
    });

    test('SessionExportService.sessionsToCSV produces valid CSV', () {
      final sessions = [
        Session(
          id: 's1',
          studentId: 'stu1',
          subjectId: 'subj1',
          type: SessionType.practice,
          startTime: DateTime(2025, 1, 15, 10, 0),
          endTime: DateTime(2025, 1, 15, 10, 30),
          actualDurationMs: 1800000,
          questionsAnswered: 10,
          correctAnswers: 8,
        ),
      ];
      final csv = SessionExportService.sessionsToCSV(sessions);
      expect(csv, contains('s1'));
      expect(csv, contains('stu1'));
      expect(csv, contains('subj1'));
      expect(csv, contains('10'));
      expect(csv, contains('8'));
      expect(csv, contains('80.0'));
    });

    test('SessionExportService.sessionsToJSON produces correct output', () {
      final now = DateTime(2025, 1, 15, 10, 0);
      final sessions = [
        Session(
          id: 's1',
          studentId: 'stu1',
          startTime: now,
        ),
      ];
      final json = SessionExportService.sessionsToJSON(sessions);
      expect(json, hasLength(1));
      expect(json[0]['id'], 's1');
      expect(json[0]['studentId'], 'stu1');
    });

    test('StudyTimerService initial state', () {
      final repo = SessionRepository();
      final timer = StudyTimerService(repository: repo);
      expect(timer.hasActiveSession, false);
      expect(timer.elapsedMs, 0);
      expect(timer.isPaused, false);
      expect(timer.currentSession, isNull);
    });

    test('Session can be constructed', () {
      final session = Session(
        id: 'test_1',
        studentId: 'stu1',
        startTime: DateTime(2025, 1, 15),
        type: SessionType.focus,
        plannedDurationMinutes: 25,
      );
      expect(session.id, 'test_1');
      expect(session.type, SessionType.focus);
      expect(session.plannedDurationMinutes, 25);
    });

    test('Session.isActive is true for incomplete session', () {
      final session = Session(
        id: 'active_1',
        studentId: 'stu1',
        startTime: DateTime(2025, 1, 15),
      );
      expect(session.isActive, true);
    });

    test('Session.isActive is false for completed session', () {
      final session = Session(
        id: 'completed_1',
        studentId: 'stu1',
        startTime: DateTime(2025, 1, 15),
        endTime: DateTime(2025, 1, 15, 0, 30),
        completed: true,
      );
      expect(session.isActive, false);
    });
  });
}
