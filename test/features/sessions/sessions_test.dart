import 'package:flutter_test/flutter_test.dart';
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
  });
}
