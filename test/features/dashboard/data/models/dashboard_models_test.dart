import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';

void main() {
  group('MasterySnapshot', () {
    test('default constructor sets default values', () {
      const snapshot = MasterySnapshot();
      expect(snapshot.totalTopics, 0);
      expect(snapshot.masteredTopics, 0);
      expect(snapshot.weakTopics, 0);
      expect(snapshot.averageAccuracy, 0.0);
      expect(snapshot.totalAttempts, 0);
      expect(snapshot.avgReadiness, 0.0);
      expect(snapshot.avgReviewUrgency, 0.0);
    });

    test('isEmpty returns true when all fields are default', () {
      const snapshot = MasterySnapshot();
      expect(snapshot.isEmpty, isTrue);
    });

    test('isEmpty returns false when a field is non-default', () {
      const snapshot = MasterySnapshot(totalTopics: 5);
      expect(snapshot.isEmpty, isFalse);
    });

    test('fromMap parses all fields', () {
      final snapshot = MasterySnapshot.fromMap({
        'totalTopics': 10,
        'masteredTopics': 4,
        'weakTopics': 2,
        'averageAccuracy': 0.85,
        'totalAttempts': 50,
        'avgReadiness': 0.7,
        'avgReviewUrgency': 0.3,
      });
      expect(snapshot.totalTopics, 10);
      expect(snapshot.masteredTopics, 4);
      expect(snapshot.weakTopics, 2);
      expect(snapshot.averageAccuracy, 0.85);
      expect(snapshot.totalAttempts, 50);
      expect(snapshot.avgReadiness, 0.7);
      expect(snapshot.avgReviewUrgency, 0.3);
    });

    test('fromMap handles null/empty map with defaults', () {
      final snapshot = MasterySnapshot.fromMap({});
      expect(snapshot.totalTopics, 0);
      expect(snapshot.averageAccuracy, 0.0);
    });

    test('fromMap handles null values with defaults', () {
      final snapshot = MasterySnapshot.fromMap({
        'totalTopics': null,
        'averageAccuracy': null,
      });
      expect(snapshot.totalTopics, 0);
      expect(snapshot.averageAccuracy, 0.0);
    });
  });

  group('OverallStats', () {
    test('default constructor sets default values', () {
      const stats = OverallStats();
      expect(stats.totalAttempts, 0);
      expect(stats.correctAttempts, 0);
      expect(stats.accuracy, 0);
      expect(stats.totalStudyTimeHours, 0);
    });

    test('isEmpty returns true when all tracking fields are zero', () {
      const stats = OverallStats();
      expect(stats.isEmpty, isTrue);
    });

    test('isEmpty returns false when a field is non-zero', () {
      const stats = OverallStats(totalAttempts: 5);
      expect(stats.isEmpty, isFalse);
    });

    test('fromMap parses all fields', () {
      final stats = OverallStats.fromMap({
        'totalAttempts': 100,
        'correctAttempts': 80,
        'accuracy': 80,
        'avgTimePerQuestion': 30,
        'totalStudyTimeHours': 15.5,
        'weeklyActivity': 7,
        'dailyActivity': 2,
        'topicsStudied': 5,
      });
      expect(stats.totalAttempts, 100);
      expect(stats.correctAttempts, 80);
      expect(stats.accuracy, 80);
      expect(stats.avgTimePerQuestion, 30);
      expect(stats.totalStudyTimeHours, 15.5);
      expect(stats.weeklyActivity, 7);
      expect(stats.dailyActivity, 2);
      expect(stats.topicsStudied, 5);
    });

    test('fromMap handles totalStudyTimeHours as string', () {
      final stats = OverallStats.fromMap({'totalStudyTimeHours': '10.5'});
      expect(stats.totalStudyTimeHours, 10.5);
    });

    test('fromMap handles invalid totalStudyTimeHours string', () {
      final stats = OverallStats.fromMap({'totalStudyTimeHours': 'invalid'});
      expect(stats.totalStudyTimeHours, 0);
    });

    test('fromMap handles null fields', () {
      final stats = OverallStats.fromMap({
        'totalAttempts': null,
        'accuracy': null,
      });
      expect(stats.totalAttempts, 0);
      expect(stats.accuracy, 0);
    });

    test('fromMap handles empty map with defaults', () {
      final stats = OverallStats.fromMap({});
      expect(stats.totalAttempts, 0);
    });
  });

  group('WeeklyTrendEntry', () {
    test('default constructor sets default values', () {
      const entry = WeeklyTrendEntry();
      expect(entry.week, 0);
      expect(entry.improvement, 0.0);
      expect(entry.isGap, isFalse);
    });

    test('fromMap parses all fields', () {
      final entry = WeeklyTrendEntry.fromMap({
        'week': 12,
        'month': 3,
        'attempts': 20,
        'accuracy': 85,
        'improvement': 0.05,
        'isGap': true,
      });
      expect(entry.week, 12);
      expect(entry.month, 3);
      expect(entry.attempts, 20);
      expect(entry.accuracy, 85);
      expect(entry.improvement, 0.05);
      expect(entry.isGap, isTrue);
    });

    test('fromMap handles missing fields', () {
      final entry = WeeklyTrendEntry.fromMap({});
      expect(entry.week, 0);
      expect(entry.isGap, isFalse);
    });
  });

  group('FocusTodayStats', () {
    test('default constructor sets default values', () {
      const stats = FocusTodayStats();
      expect(stats.totalSeconds, 0);
      expect(stats.completedSessions, 0);
      expect(stats.hours, 0.0);
    });

    test('hours getter calculates correctly', () {
      const stats = FocusTodayStats(totalSeconds: 3600);
      expect(stats.hours, 1.0);
    });

    test('isEmpty returns true when zero', () {
      const stats = FocusTodayStats();
      expect(stats.isEmpty, isTrue);
    });

    test('fromMap parses all fields', () {
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
  });

  group('AdherenceData', () {
    test('default constructor sets default values', () {
      const data = AdherenceData();
      expect(data.averageAdherence, 0.0);
      expect(data.weeklyAdherence, 0.0);
    });

    test('isEmpty returns true when zero', () {
      const data = AdherenceData();
      expect(data.isEmpty, isTrue);
    });

    test('isEmpty returns false when non-zero', () {
      const data = AdherenceData(averageAdherence: 0.5);
      expect(data.isEmpty, isFalse);
    });
  });

  group('BadgeDisplay', () {
    test('constructor assigns fields', () {
      const badge = BadgeDisplay(
        name: 'Test Badge',
        description: 'Test Description',
      );
      expect(badge.name, 'Test Badge');
      expect(badge.description, 'Test Description');
      expect(badge.category, 'general');
    });

    test('accepts custom category', () {
      const badge = BadgeDisplay(
        name: 'Test',
        description: 'Desc',
        category: 'milestone',
      );
      expect(badge.category, 'milestone');
    });
  });

  group('SubjectDueCount', () {
    test('constructor assigns fields', () {
      const s = SubjectDueCount(
        subjectId: 's1',
        subjectName: 'Math',
        dueCount: 5,
      );
      expect(s.subjectId, 's1');
      expect(s.subjectName, 'Math');
      expect(s.dueCount, 5);
    });
  });

  group('DueReviewsData', () {
    test('constructor assigns fields', () {
      const data = DueReviewsData(
        totalDue: 10,
        subjectBreakdown: [
          SubjectDueCount(subjectId: 's1', subjectName: 'Math', dueCount: 5),
        ],
      );
      expect(data.totalDue, 10);
      expect(data.subjectBreakdown.length, 1);
      expect(data.subjectBreakdown[0].subjectName, 'Math');
    });

    test('handles empty breakdown', () {
      const data = DueReviewsData(
        totalDue: 0,
        subjectBreakdown: [],
      );
      expect(data.totalDue, 0);
      expect(data.subjectBreakdown, isEmpty);
    });
  });

  group('ChecklistProgress', () {
    test('default constructor has all false', () {
      const cp = ChecklistProgress();
      expect(cp.hasSubjects, isFalse);
      expect(cp.completedCount, 0);
      expect(cp.totalCount, 4);
      expect(cp.isComplete, isFalse);
      expect(cp.isEmpty, isTrue);
    });

    test('completedCount counts trues', () {
      const cp = ChecklistProgress(hasSubjects: true, hasSources: true);
      expect(cp.completedCount, 2);
      expect(cp.isComplete, isFalse);
      expect(cp.isEmpty, isFalse);
    });

    test('isComplete returns true when all true', () {
      const cp = ChecklistProgress(
        hasSubjects: true,
        hasSources: true,
        hasPracticeSessions: true,
        hasScheduledLessons: true,
      );
      expect(cp.isComplete, isTrue);
      expect(cp.completedCount, 4);
    });
  });

  group('BadgeModel', () {
    test('constructor assigns required fields', () {
      final badge = BadgeModel(
        id: 'b1',
        studentId: 's1',
        name: 'Test Badge',
        description: 'A test badge',
      );
      expect(badge.id, 'b1');
      expect(badge.studentId, 's1');
      expect(badge.name, 'Test Badge');
      expect(badge.description, 'A test badge');
      expect(badge.iconName, 'emoji_events');
      expect(badge.category, 'general');
    });

    test('toJson/fromJson round-trip', () {
      final now = DateTime(2026, 5, 18);
      final original = BadgeModel(
        id: 'b2',
        studentId: 's1',
        name: 'Century',
        description: '100 questions',
        iconName: 'military_tech',
        category: 'milestone',
        unlockedAt: now,
        criteria: {'totalAttempts': 100},
      );
      final json = original.toJson();
      final restored = BadgeModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.studentId, original.studentId);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.iconName, original.iconName);
      expect(restored.category, original.category);
      expect(restored.unlockedAt, original.unlockedAt);
      expect(restored.criteria, original.criteria);
    });

    test('toJson/fromJson with null criteria', () {
      final original = BadgeModel(
        id: 'b3',
        studentId: 's1',
        name: 'Test',
        description: 'Desc',
      );
      final json = original.toJson();
      final restored = BadgeModel.fromJson(json);
      expect(restored.criteria, isNull);
    });

    test('fromJson fills defaults for optional fields', () {
      final restored = BadgeModel.fromJson({
        'id': 'b4',
        'studentId': 's1',
        'name': 'Test',
        'description': 'Desc',
      });
      expect(restored.iconName, 'emoji_events');
      expect(restored.category, 'general');
    });
  });

  group('BadgeDefinition', () {
    test('isSatisfiedBy with greaterOrEqual returns true when sufficient', () {
      final def = BadgeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        iconName: 'icon',
        category: 'general',
        checkKey: 'totalAttempts',
        checkOperator: CheckOperator.greaterOrEqual,
        checkValue: 5,
      );
      expect(def.isSatisfiedBy({'totalAttempts': 10}), isTrue);
    });

    test('isSatisfiedBy with greaterOrEqual returns false when insufficient', () {
      final def = BadgeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        iconName: 'icon',
        category: 'general',
        checkKey: 'totalAttempts',
        checkOperator: CheckOperator.greaterOrEqual,
        checkValue: 5,
      );
      expect(def.isSatisfiedBy({'totalAttempts': 3}), isFalse);
    });

    test('isSatisfiedBy returns false when key missing', () {
      final def = BadgeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        iconName: 'icon',
        category: 'general',
        checkKey: 'nonexistent',
        checkOperator: CheckOperator.greaterOrEqual,
        checkValue: 5,
      );
      expect(def.isSatisfiedBy({'totalAttempts': 10}), isFalse);
    });

    test('isSatisfiedBy handles string values', () {
      final def = BadgeDefinition(
        id: 'test',
        name: 'Test',
        description: 'Test',
        iconName: 'icon',
        category: 'general',
        checkKey: 'totalAttempts',
        checkOperator: CheckOperator.greaterOrEqual,
        checkValue: 5,
      );
      expect(def.isSatisfiedBy({'totalAttempts': '6'}), isTrue);
      expect(def.isSatisfiedBy({'totalAttempts': '3'}), isFalse);
    });

    test('BadgeDefinitions.all contains all badges', () {
      expect(BadgeDefinitions.all.length, 6);
      expect(BadgeDefinitions.getById('first_attempt'), isNotNull);
      expect(BadgeDefinitions.getById('nonexistent'), isNull);
    });
  });
}
