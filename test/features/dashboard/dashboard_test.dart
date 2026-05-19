import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/dashboard.dart';

void main() {
  group('Dashboard barrel', () {
    test('exports DashboardScreen', () {
      expect(DashboardScreen, isNotNull);
    });

    test('exports BadgesCard', () => expect(BadgesCard, isNotNull));
    test('exports DashboardHeader', () => expect(DashboardHeader, isNotNull));
    test('exports ExportSection', () => expect(ExportSection, isNotNull));
    test('exports MasteryProgressCard', () => expect(MasteryProgressCard, isNotNull));
    test('exports SummaryRow', () => expect(SummaryRow, isNotNull));
    test('exports TopicBreakdownCard', () => expect(TopicBreakdownCard, isNotNull));
    test('exports WeakAreasCard', () => expect(WeakAreasCard, isNotNull));
    test('exports WeeklyChart', () => expect(WeeklyChart, isNotNull));
    test('exports CollapsibleCard', () => expect(CollapsibleCard, isNotNull));
    test('exports EmptyDashboardChecklist', () => expect(EmptyDashboardChecklist, isNotNull));
    test('MasterySnapshot can be constructed with values', () {
      const snapshot = MasterySnapshot(
        totalTopics: 10,
        masteredTopics: 5,
        weakTopics: 3,
        averageAccuracy: 0.85,
        totalAttempts: 50,
      );
      expect(snapshot.totalTopics, 10);
      expect(snapshot.masteredTopics, 5);
      expect(snapshot.weakTopics, 3);
      expect(snapshot.averageAccuracy, 0.85);
      expect(snapshot.totalAttempts, 50);
      expect(snapshot.isEmpty, isFalse);
    });

    test('MasterySnapshot.isEmpty returns true when all fields are zero', () {
      const snapshot = MasterySnapshot();
      expect(snapshot.isEmpty, isTrue);
    });

    test('OverallStats can be constructed and isEmpty works', () {
      const stats = OverallStats(
        totalAttempts: 100,
        correctAttempts: 85,
        accuracy: 85,
        weeklyActivity: 5,
        topicsStudied: 3,
      );
      expect(stats.totalAttempts, 100);
      expect(stats.correctAttempts, 85);
      expect(stats.accuracy, 85);
      expect(stats.weeklyActivity, 5);
      expect(stats.topicsStudied, 3);
      expect(stats.isEmpty, isFalse);
    });

    test('WeeklyTrendEntry can be constructed with values', () {
      const entry = WeeklyTrendEntry(
        week: 3,
        month: 1,
        attempts: 20,
        accuracy: 80,
        improvement: 0.05,
        isGap: false,
      );
      expect(entry.week, 3);
      expect(entry.attempts, 20);
      expect(entry.accuracy, 80);
      expect(entry.improvement, 0.05);
    });

    test('FocusTodayStats can be constructed and hours computed', () {
      const stats = FocusTodayStats(
        totalSeconds: 3600,
        completedSessions: 2,
        totalSessions: 3,
        plannedMinutes: 60,
      );
      expect(stats.totalSeconds, 3600);
      expect(stats.completedSessions, 2);
      expect(stats.hours, 1.0);
      expect(stats.isEmpty, isFalse);
    });

    test('AdherenceData can be constructed with values', () {
      const data = AdherenceData(averageAdherence: 0.85, weeklyAdherence: 0.9);
      expect(data.averageAdherence, 0.85);
      expect(data.weeklyAdherence, 0.9);
      expect(data.isEmpty, isFalse);
    });

    test('BadgeDisplay preserves provided values', () {
      const badge = BadgeDisplay(
        name: 'Early Bird',
        description: 'Completed 10 morning sessions',
        category: 'consistency',
      );
      expect(badge.name, 'Early Bird');
      expect(badge.description, 'Completed 10 morning sessions');
      expect(badge.category, 'consistency');
    });

    test('SubjectDueCount can be constructed with values', () {
      const subjectDue = SubjectDueCount(
        subjectId: 'math',
        subjectName: 'Mathematics',
        dueCount: 5,
      );
      expect(subjectDue.subjectId, 'math');
      expect(subjectDue.subjectName, 'Mathematics');
      expect(subjectDue.dueCount, 5);
    });

    test('DueReviewsData can be constructed with subject breakdown', () {
      const subjectDue = SubjectDueCount(
        subjectId: 'math',
        subjectName: 'Mathematics',
        dueCount: 5,
      );
      const data = DueReviewsData(
        totalDue: 5,
        subjectBreakdown: [subjectDue],
      );
      expect(data.totalDue, 5);
      expect(data.subjectBreakdown.length, 1);
      expect(data.subjectBreakdown[0].subjectId, 'math');
    });

    test('DashboardLayoutPreferences can be constructed', () {
      const prefs = DashboardLayoutPreferences(collapsedCards: {'card1'});
      expect(prefs.collapsedCards, contains('card1'));
    });

    test('MasterySnapshot.fromMap parses map correctly', () {
      final snapshot = MasterySnapshot.fromMap({
        'totalTopics': 10,
        'masteredTopics': 5,
        'weakTopics': 3,
        'averageAccuracy': 0.85,
        'totalAttempts': 50,
      });
      expect(snapshot.totalTopics, 10);
      expect(snapshot.masteredTopics, 5);
      expect(snapshot.weakTopics, 3);
    });

    test('OverallStats.fromMap parses map correctly', () {
      final stats = OverallStats.fromMap({
        'totalAttempts': 100,
        'correctAttempts': 85,
        'accuracy': 85,
        'totalStudyTimeHours': '10.5',
        'weeklyActivity': 5,
      });
      expect(stats.totalAttempts, 100);
      expect(stats.correctAttempts, 85);
      expect(stats.totalStudyTimeHours, 10.5);
    });
  });
}
