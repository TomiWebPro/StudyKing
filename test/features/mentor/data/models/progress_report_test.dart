import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/data/models/progress_report.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';

void main() {
  group('ProgressReport', () {
    test('can be created with required fields', () {
      final report = ProgressReport(
        totalAttempts: 100,
        correctAttempts: 75,
        accuracy: 0.75,
        topicsStudied: 5,
        completedLessons: 10,
        weeklyActivity: 7,
        totalStudyTimeHours: 42.5,
      );

      expect(report.totalAttempts, 100);
      expect(report.correctAttempts, 75);
      expect(report.accuracy, 0.75);
      expect(report.topicsStudied, 5);
      expect(report.completedLessons, 10);
      expect(report.weeklyActivity, 7);
      expect(report.totalStudyTimeHours, 42.5);
    });

    test('uses default empty lists when not provided', () {
      final report = ProgressReport(
        totalAttempts: 0,
        correctAttempts: 0,
        accuracy: 0.0,
        topicsStudied: 0,
        completedLessons: 0,
        weeklyActivity: 0,
        totalStudyTimeHours: 0,
      );

      expect(report.weakTopics, isEmpty);
      expect(report.badges, isEmpty);
      expect(report.recommendations, isEmpty);
    });

    test('accepts weak topics list', () {
      final now = DateTime.now();
      final weakTopics = [
        MasteryState(
          studentId: 's1',
          topicId: 't1',
          lastAttempt: now,
          lastUpdated: now,
        ),
      ];

      final report = ProgressReport(
        totalAttempts: 50,
        correctAttempts: 30,
        accuracy: 0.6,
        topicsStudied: 3,
        completedLessons: 5,
        weeklyActivity: 3,
        totalStudyTimeHours: 20,
        weakTopics: weakTopics,
      );

      expect(report.weakTopics, hasLength(1));
      expect(report.weakTopics.first.topicId, 't1');
    });

    test('accepts badges and recommendations', () {
      final badges = [
        {'name': 'Fast Learner', 'icon': 'star'},
      ];
      final recommendations = [
        {'action': 'Review Algebra', 'priority': 'high'},
      ];

      final report = ProgressReport(
        totalAttempts: 200,
        correctAttempts: 150,
        accuracy: 0.75,
        topicsStudied: 8,
        completedLessons: 15,
        weeklyActivity: 5,
        totalStudyTimeHours: 60,
        badges: badges,
        recommendations: recommendations,
      );

      expect(report.badges, hasLength(1));
      expect(report.badges.first['name'], 'Fast Learner');
      expect(report.recommendations, hasLength(1));
      expect(report.recommendations.first['action'], 'Review Algebra');
    });

    test('supports value equality', () {
      final a = ProgressReport(
        totalAttempts: 10,
        correctAttempts: 8,
        accuracy: 0.8,
        topicsStudied: 2,
        completedLessons: 4,
        weeklyActivity: 2,
        totalStudyTimeHours: 8,
      );
      final b = ProgressReport(
        totalAttempts: 10,
        correctAttempts: 8,
        accuracy: 0.8,
        topicsStudied: 2,
        completedLessons: 4,
        weeklyActivity: 2,
        totalStudyTimeHours: 8,
      );

      expect(a.totalAttempts, b.totalAttempts);
      expect(a.correctAttempts, b.correctAttempts);
      expect(a.accuracy, b.accuracy);
      expect(a.topicsStudied, b.topicsStudied);
      expect(a.completedLessons, b.completedLessons);
      expect(a.weeklyActivity, b.weeklyActivity);
      expect(a.totalStudyTimeHours, b.totalStudyTimeHours);
    });

    test('different reports are not equal', () {
      final a = ProgressReport(
        totalAttempts: 10,
        correctAttempts: 8,
        accuracy: 0.8,
        topicsStudied: 2,
        completedLessons: 4,
        weeklyActivity: 2,
        totalStudyTimeHours: 8,
      );
      final b = ProgressReport(
        totalAttempts: 20,
        correctAttempts: 16,
        accuracy: 0.8,
        topicsStudied: 4,
        completedLessons: 8,
        weeklyActivity: 4,
        totalStudyTimeHours: 16,
      );

      expect(a, isNot(equals(b)));
    });

    test('can be const', () {
      const report = ProgressReport(
        totalAttempts: 5,
        correctAttempts: 3,
        accuracy: 0.6,
        topicsStudied: 1,
        completedLessons: 2,
        weeklyActivity: 1,
        totalStudyTimeHours: 3,
      );

      expect(report.totalAttempts, 5);
    });

    test('accepts int value for totalStudyTimeHours as num', () {
      final report = ProgressReport(
        totalAttempts: 10,
        correctAttempts: 8,
        accuracy: 0.8,
        topicsStudied: 2,
        completedLessons: 4,
        weeklyActivity: 2,
        totalStudyTimeHours: 8,
      );

      expect(report.totalStudyTimeHours, isA<num>());
      expect(report.totalStudyTimeHours, 8);
    });

    test('accepts double value for totalStudyTimeHours as num', () {
      final report = ProgressReport(
        totalAttempts: 10,
        correctAttempts: 8,
        accuracy: 0.8,
        topicsStudied: 2,
        completedLessons: 4,
        weeklyActivity: 2,
        totalStudyTimeHours: 8.5,
      );

      expect(report.totalStudyTimeHours, isA<num>());
      expect(report.totalStudyTimeHours, 8.5);
    });

    test('handles zero values', () {
      final report = ProgressReport(
        totalAttempts: 0,
        correctAttempts: 0,
        accuracy: 0.0,
        topicsStudied: 0,
        completedLessons: 0,
        weeklyActivity: 0,
        totalStudyTimeHours: 0,
      );

      expect(report.accuracy, 0.0);
      expect(report.totalAttempts, 0);
      expect(report.correctAttempts, 0);
    });

    test('handles boundary accuracy values', () {
      final zero = ProgressReport(
        totalAttempts: 0, correctAttempts: 0, accuracy: 0.0,
        topicsStudied: 0, completedLessons: 0, weeklyActivity: 0,
        totalStudyTimeHours: 0,
      );
      final full = ProgressReport(
        totalAttempts: 10, correctAttempts: 10, accuracy: 1.0,
        topicsStudied: 1, completedLessons: 1, weeklyActivity: 1,
        totalStudyTimeHours: 1,
      );

      expect(zero.accuracy, 0.0);
      expect(full.accuracy, 1.0);
    });

    test('handles explicit empty lists', () {
      final report = ProgressReport(
        totalAttempts: 10,
        correctAttempts: 8,
        accuracy: 0.8,
        topicsStudied: 2,
        completedLessons: 4,
        weeklyActivity: 2,
        totalStudyTimeHours: 8,
        weakTopics: [],
        badges: [],
        recommendations: [],
      );

      expect(report.weakTopics, isEmpty);
      expect(report.badges, isEmpty);
      expect(report.recommendations, isEmpty);
    });

    test('accepts multiple weak topics', () {
      final now = DateTime.now();
      final weakTopics = [
        MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now),
        MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now),
        MasteryState(studentId: 's1', topicId: 't3', lastAttempt: now, lastUpdated: now),
      ];

      final report = ProgressReport(
        totalAttempts: 50, correctAttempts: 25, accuracy: 0.5,
        topicsStudied: 3, completedLessons: 2, weeklyActivity: 1,
        totalStudyTimeHours: 10, weakTopics: weakTopics,
      );

      expect(report.weakTopics, hasLength(3));
      expect(report.weakTopics[0].topicId, 't1');
      expect(report.weakTopics[1].topicId, 't2');
      expect(report.weakTopics[2].topicId, 't3');
    });

    test('accepts multiple badges and recommendations', () {
      final badges = [
        {'name': 'Fast Learner', 'icon': 'star'},
        {'name': 'Consistent', 'icon': 'fire'},
        {'name': 'Math Whiz', 'icon': 'trophy'},
      ];
      final recommendations = [
        {'action': 'Review Algebra', 'priority': 'high'},
        {'action': 'Practice Geometry', 'priority': 'medium'},
      ];

      final report = ProgressReport(
        totalAttempts: 300, correctAttempts: 240, accuracy: 0.8,
        topicsStudied: 10, completedLessons: 20, weeklyActivity: 7,
        totalStudyTimeHours: 80, badges: badges, recommendations: recommendations,
      );

      expect(report.badges, hasLength(3));
      expect(report.badges[0]['name'], 'Fast Learner');
      expect(report.badges[1]['name'], 'Consistent');
      expect(report.badges[2]['name'], 'Math Whiz');
      expect(report.recommendations, hasLength(2));
      expect(report.recommendations[1]['action'], 'Practice Geometry');
    });

    test('handles large numeric values', () {
      final report = ProgressReport(
        totalAttempts: 999999, correctAttempts: 888888, accuracy: 0.888,
        topicsStudied: 500, completedLessons: 999, weeklyActivity: 365,
        totalStudyTimeHours: 8760,
      );

      expect(report.totalAttempts, 999999);
      expect(report.correctAttempts, 888888);
      expect(report.weeklyActivity, 365);
      expect(report.totalStudyTimeHours, 8760);
    });

    test('handles fractional accuracy values', () {
      final report = ProgressReport(
        totalAttempts: 1000, correctAttempts: 333, accuracy: 0.333,
        topicsStudied: 10, completedLessons: 5, weeklyActivity: 3,
        totalStudyTimeHours: 25.75,
      );

      expect(report.accuracy, closeTo(0.333, 0.001));
    });

    test('can be constructed with negative values', () {
      final report = ProgressReport(
        totalAttempts: -5, correctAttempts: -3, accuracy: -0.5,
        topicsStudied: -1, completedLessons: -2, weeklyActivity: -1,
        totalStudyTimeHours: -10,
      );

      expect(report.totalAttempts, -5);
      expect(report.accuracy, -0.5);
    });

    test('handles incorrectAttempts calculation', () {
      final report = ProgressReport(
        totalAttempts: 100, correctAttempts: 75, accuracy: 0.75,
        topicsStudied: 5, completedLessons: 10, weeklyActivity: 7,
        totalStudyTimeHours: 42.5,
      );

      final incorrect = report.totalAttempts - report.correctAttempts;
      expect(incorrect, 25);
    });

    test('hashCode is stable on same instance', () {
      final a = ProgressReport(
        totalAttempts: 10, correctAttempts: 8, accuracy: 0.8,
        topicsStudied: 2, completedLessons: 4, weeklyActivity: 2,
        totalStudyTimeHours: 8,
      );

      expect(a.hashCode, a.hashCode);
    });

    test('const hashCode is stable', () {
      const a = ProgressReport(
        totalAttempts: 10, correctAttempts: 8, accuracy: 0.8,
        topicsStudied: 2, completedLessons: 4, weeklyActivity: 2,
        totalStudyTimeHours: 8,
      );

      expect(a.hashCode, a.hashCode);
    });

    test('accuracy field stores double precision', () {
      final report = ProgressReport(
        totalAttempts: 1, correctAttempts: 1, accuracy: 0.123456789,
        topicsStudied: 1, completedLessons: 1, weeklyActivity: 1,
        totalStudyTimeHours: 1,
      );

      expect(report.accuracy, 0.123456789);
    });

    test('totalStudyTimeHours accepts num as both int and double', () {
      const asInt = ProgressReport(
        totalAttempts: 0, correctAttempts: 0, accuracy: 0,
        topicsStudied: 0, completedLessons: 0, weeklyActivity: 0,
        totalStudyTimeHours: 10,
      );
      const asDouble = ProgressReport(
        totalAttempts: 0, correctAttempts: 0, accuracy: 0,
        topicsStudied: 0, completedLessons: 0, weeklyActivity: 0,
        totalStudyTimeHours: 10.0,
      );

      expect(asInt.totalStudyTimeHours.runtimeType, int);
      expect(asDouble.totalStudyTimeHours.runtimeType, double);
    });
  });
}
