import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/dashboard.dart';

void main() {
  group('MasterySnapshot', () {
    group('default constructor', () {
      test('creates instance with all zero defaults', () {
        final snapshot = MasterySnapshot();
        expect(snapshot.totalTopics, 0);
        expect(snapshot.masteredTopics, 0);
        expect(snapshot.weakTopics, 0);
        expect(snapshot.averageAccuracy, 0.0);
        expect(snapshot.totalAttempts, 0);
        expect(snapshot.avgReadiness, 0.0);
        expect(snapshot.avgReviewUrgency, 0.0);
      });

      test('default instance isEmpty is true', () {
        expect(MasterySnapshot().isEmpty, isTrue);
      });
    });

    group('named constructor with values', () {
      test('creates instance with provided values', () {
        final snapshot = MasterySnapshot(
          totalTopics: 10,
          masteredTopics: 5,
          weakTopics: 3,
          averageAccuracy: 0.85,
          totalAttempts: 100,
          avgReadiness: 0.75,
          avgReviewUrgency: 0.3,
        );

        expect(snapshot.totalTopics, 10);
        expect(snapshot.masteredTopics, 5);
        expect(snapshot.weakTopics, 3);
        expect(snapshot.averageAccuracy, 0.85);
        expect(snapshot.totalAttempts, 100);
        expect(snapshot.avgReadiness, 0.75);
        expect(snapshot.avgReviewUrgency, 0.3);
      });

      test('non-empty instance isEmpty is false', () {
        final snapshot = MasterySnapshot(totalTopics: 1);
        expect(snapshot.isEmpty, isFalse);
      });
    });

    group('fromMap', () {
      test('parses fully populated valid map', () {
        final snapshot = MasterySnapshot.fromMap({
          'totalTopics': 10,
          'masteredTopics': 5,
          'weakTopics': 3,
          'averageAccuracy': 0.85,
          'totalAttempts': 100,
          'avgReadiness': 0.75,
          'avgReviewUrgency': 0.3,
        });

        expect(snapshot.totalTopics, 10);
        expect(snapshot.masteredTopics, 5);
        expect(snapshot.weakTopics, 3);
        expect(snapshot.averageAccuracy, 0.85);
        expect(snapshot.totalAttempts, 100);
        expect(snapshot.avgReadiness, 0.75);
        expect(snapshot.avgReviewUrgency, 0.3);
      });

      test('uses fallback defaults for missing keys', () {
        final snapshot = MasterySnapshot.fromMap({});
        expect(snapshot.totalTopics, 0);
        expect(snapshot.masteredTopics, 0);
        expect(snapshot.weakTopics, 0);
        expect(snapshot.averageAccuracy, 0.0);
        expect(snapshot.totalAttempts, 0);
        expect(snapshot.avgReadiness, 0.0);
        expect(snapshot.avgReviewUrgency, 0.0);
      });

      test('handles null values gracefully', () {
        final snapshot = MasterySnapshot.fromMap({
          'totalTopics': null,
          'masteredTopics': null,
          'weakTopics': null,
          'averageAccuracy': null,
          'totalAttempts': null,
          'avgReadiness': null,
          'avgReviewUrgency': null,
        });

        expect(snapshot.totalTopics, 0);
        expect(snapshot.masteredTopics, 0);
        expect(snapshot.weakTopics, 0);
        expect(snapshot.averageAccuracy, 0.0);
        expect(snapshot.totalAttempts, 0);
        expect(snapshot.avgReadiness, 0.0);
        expect(snapshot.avgReviewUrgency, 0.0);
      });
    });
  });

  group('OverallStats', () {
    group('default constructor', () {
      test('creates instance with all zero defaults', () {
        final stats = OverallStats();
        expect(stats.totalAttempts, 0);
        expect(stats.correctAttempts, 0);
        expect(stats.accuracy, 0);
        expect(stats.avgTimePerQuestion, 0);
        expect(stats.totalStudyTimeHours, '0');
        expect(stats.weeklyActivity, 0);
        expect(stats.dailyActivity, 0);
        expect(stats.topicsStudied, 0);
      });

      test('default instance isEmpty is true', () {
        expect(OverallStats().isEmpty, isTrue);
      });
    });

    group('named constructor with values', () {
      test('creates instance with provided values', () {
        final stats = OverallStats(
          totalAttempts: 200,
          correctAttempts: 150,
          accuracy: 75,
          avgTimePerQuestion: 30,
          totalStudyTimeHours: '42',
          weeklyActivity: 5,
          dailyActivity: 3,
          topicsStudied: 8,
        );

        expect(stats.totalAttempts, 200);
        expect(stats.correctAttempts, 150);
        expect(stats.accuracy, 75);
        expect(stats.avgTimePerQuestion, 30);
        expect(stats.totalStudyTimeHours, '42');
        expect(stats.weeklyActivity, 5);
        expect(stats.dailyActivity, 3);
        expect(stats.topicsStudied, 8);
      });

      test('non-empty instance isEmpty is false', () {
        expect(OverallStats(totalAttempts: 1).isEmpty, isFalse);
        expect(OverallStats(accuracy: 1).isEmpty, isFalse);
        expect(OverallStats(weeklyActivity: 1).isEmpty, isFalse);
        expect(OverallStats(topicsStudied: 1).isEmpty, isFalse);
      });
    });

    group('fromMap', () {
      test('parses fully populated valid map', () {
        final stats = OverallStats.fromMap({
          'totalAttempts': 200,
          'correctAttempts': 150,
          'accuracy': 75,
          'avgTimePerQuestion': 30,
          'totalStudyTimeHours': '42',
          'weeklyActivity': 5,
          'dailyActivity': 3,
          'topicsStudied': 8,
        });

        expect(stats.totalAttempts, 200);
        expect(stats.correctAttempts, 150);
        expect(stats.accuracy, 75);
        expect(stats.avgTimePerQuestion, 30);
        expect(stats.totalStudyTimeHours, '42');
        expect(stats.weeklyActivity, 5);
        expect(stats.dailyActivity, 3);
        expect(stats.topicsStudied, 8);
      });

      test('uses fallback defaults for missing keys', () {
        final stats = OverallStats.fromMap({});
        expect(stats.totalAttempts, 0);
        expect(stats.correctAttempts, 0);
        expect(stats.accuracy, 0);
        expect(stats.avgTimePerQuestion, 0);
        expect(stats.totalStudyTimeHours, '0');
        expect(stats.weeklyActivity, 0);
        expect(stats.dailyActivity, 0);
        expect(stats.topicsStudied, 0);
      });

      test('handles null values gracefully', () {
        final stats = OverallStats.fromMap({
          'totalAttempts': null,
          'correctAttempts': null,
          'accuracy': null,
          'avgTimePerQuestion': null,
          'totalStudyTimeHours': null,
          'weeklyActivity': null,
          'dailyActivity': null,
          'topicsStudied': null,
        });

        expect(stats.totalAttempts, 0);
        expect(stats.correctAttempts, 0);
        expect(stats.accuracy, 0);
        expect(stats.avgTimePerQuestion, 0);
        expect(stats.totalStudyTimeHours, '0');
        expect(stats.weeklyActivity, 0);
        expect(stats.dailyActivity, 0);
        expect(stats.topicsStudied, 0);
      });
    });
  });

  group('WeeklyTrendEntry', () {
    group('default constructor', () {
      test('creates instance with all zero defaults', () {
        final entry = WeeklyTrendEntry();
        expect(entry.week, 0);
        expect(entry.month, 0);
        expect(entry.attempts, 0);
        expect(entry.accuracy, 0);
        expect(entry.improvement, 0.0);
      });
    });

    group('named constructor with values', () {
      test('creates instance with provided values', () {
        final entry = WeeklyTrendEntry(
          week: 12,
          month: 3,
          attempts: 50,
          accuracy: 80,
          improvement: 0.15,
        );

        expect(entry.week, 12);
        expect(entry.month, 3);
        expect(entry.attempts, 50);
        expect(entry.accuracy, 80);
        expect(entry.improvement, 0.15);
      });
    });

    group('fromMap', () {
      test('parses fully populated valid map', () {
        final entry = WeeklyTrendEntry.fromMap({
          'week': 12,
          'month': 3,
          'attempts': 50,
          'accuracy': 80,
          'improvement': 0.15,
        });

        expect(entry.week, 12);
        expect(entry.month, 3);
        expect(entry.attempts, 50);
        expect(entry.accuracy, 80);
        expect(entry.improvement, 0.15);
      });

      test('uses fallback defaults for missing keys', () {
        final entry = WeeklyTrendEntry.fromMap({});
        expect(entry.week, 0);
        expect(entry.month, 0);
        expect(entry.attempts, 0);
        expect(entry.accuracy, 0);
        expect(entry.improvement, 0.0);
      });

      test('handles null values gracefully', () {
        final entry = WeeklyTrendEntry.fromMap({
          'week': null,
          'month': null,
          'attempts': null,
          'accuracy': null,
          'improvement': null,
        });

        expect(entry.week, 0);
        expect(entry.month, 0);
        expect(entry.attempts, 0);
        expect(entry.accuracy, 0);
        expect(entry.improvement, 0.0);
      });
    });
  });

  group('FocusTodayStats', () {
    group('default constructor', () {
      test('creates instance with all zero defaults', () {
        final stats = FocusTodayStats();
        expect(stats.totalSeconds, 0);
        expect(stats.completedSessions, 0);
        expect(stats.totalSessions, 0);
        expect(stats.plannedMinutes, 0);
      });

      test('default instance isEmpty is true', () {
        expect(FocusTodayStats().isEmpty, isTrue);
      });
    });

    group('named constructor with values', () {
      test('creates instance with provided values', () {
        final stats = FocusTodayStats(
          totalSeconds: 7200,
          completedSessions: 3,
          totalSessions: 4,
          plannedMinutes: 120,
        );

        expect(stats.totalSeconds, 7200);
        expect(stats.completedSessions, 3);
        expect(stats.totalSessions, 4);
        expect(stats.plannedMinutes, 120);
      });

      test('non-empty instance isEmpty is false', () {
        expect(FocusTodayStats(totalSeconds: 1).isEmpty, isFalse);
        expect(FocusTodayStats(totalSessions: 1).isEmpty, isFalse);
      });
    });

    group('hours', () {
      test('returns 0.0 for 0 seconds', () {
        expect(FocusTodayStats(totalSeconds: 0).hours, '0.0');
      });

      test('returns 1.0 for 3600 seconds', () {
        expect(FocusTodayStats(totalSeconds: 3600).hours, '1.0');
      });

      test('returns 1.0 for 3599 seconds (rounding down)', () {
        expect(FocusTodayStats(totalSeconds: 3599).hours, '1.0');
      });

      test('returns 0.5 for 1800 seconds', () {
        expect(FocusTodayStats(totalSeconds: 1800).hours, '0.5');
      });

      test('returns 2.5 for 9000 seconds', () {
        expect(FocusTodayStats(totalSeconds: 9000).hours, '2.5');
      });

      test('handles large values', () {
        expect(FocusTodayStats(totalSeconds: 86400).hours, '24.0');
      });
    });

    group('fromMap', () {
      test('parses fully populated valid map', () {
        final stats = FocusTodayStats.fromMap({
          'totalSeconds': 7200,
          'completedSessions': 3,
          'totalSessions': 4,
          'plannedMinutes': 120,
        });

        expect(stats.totalSeconds, 7200);
        expect(stats.completedSessions, 3);
        expect(stats.totalSessions, 4);
        expect(stats.plannedMinutes, 120);
      });

      test('uses fallback defaults for missing keys', () {
        final stats = FocusTodayStats.fromMap({});
        expect(stats.totalSeconds, 0);
        expect(stats.completedSessions, 0);
        expect(stats.totalSessions, 0);
        expect(stats.plannedMinutes, 0);
      });

      test('handles null values gracefully', () {
        final stats = FocusTodayStats.fromMap({
          'totalSeconds': null,
          'completedSessions': null,
          'totalSessions': null,
          'plannedMinutes': null,
        });

        expect(stats.totalSeconds, 0);
        expect(stats.completedSessions, 0);
        expect(stats.totalSessions, 0);
        expect(stats.plannedMinutes, 0);
      });
    });
  });

  group('AdherenceData', () {
    group('default constructor', () {
      test('creates instance with all zero defaults', () {
        final data = AdherenceData();
        expect(data.averageAdherence, 0.0);
        expect(data.weeklyAdherence, 0.0);
      });

      test('default instance isEmpty is true', () {
        expect(AdherenceData().isEmpty, isTrue);
      });
    });

    group('named constructor with values', () {
      test('creates instance with provided values', () {
        final data = AdherenceData(
          averageAdherence: 0.85,
          weeklyAdherence: 0.75,
        );

        expect(data.averageAdherence, 0.85);
        expect(data.weeklyAdherence, 0.75);
      });

      test('non-empty instance isEmpty is false', () {
        expect(AdherenceData(averageAdherence: 0.1).isEmpty, isFalse);
        expect(AdherenceData(weeklyAdherence: 0.1).isEmpty, isFalse);
      });
    });
  });

  group('BadgeDisplay', () {
    test('uses default category general', () {
      final badge = BadgeDisplay(name: 'Test Badge', description: 'A badge');
      expect(badge.name, 'Test Badge');
      expect(badge.description, 'A badge');
      expect(badge.category, 'general');
    });

    test('accepts custom category', () {
      final badge = BadgeDisplay(
        name: 'Streak Master',
        description: '7-day streak',
        category: 'streak',
      );
      expect(badge.name, 'Streak Master');
      expect(badge.description, '7-day streak');
      expect(badge.category, 'streak');
    });
  });

  group('DashboardArgs', () {
    test('stores studentId', () {
      final args = DashboardArgs(studentId: 'student_123');
      expect(args.studentId, 'student_123');
    });

    test('accepts different student IDs', () {
      final args = DashboardArgs(studentId: 'abc-def-ghi');
      expect(args.studentId, 'abc-def-ghi');
    });
  });
}
