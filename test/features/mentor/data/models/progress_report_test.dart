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
        totalStudyTimeHours: '42.5',
      );

      expect(report.totalAttempts, 100);
      expect(report.correctAttempts, 75);
      expect(report.accuracy, 0.75);
      expect(report.topicsStudied, 5);
      expect(report.completedLessons, 10);
      expect(report.weeklyActivity, 7);
      expect(report.totalStudyTimeHours, '42.5');
    });

    test('uses default empty lists when not provided', () {
      final report = ProgressReport(
        totalAttempts: 0,
        correctAttempts: 0,
        accuracy: 0.0,
        topicsStudied: 0,
        completedLessons: 0,
        weeklyActivity: 0,
        totalStudyTimeHours: '0',
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
        totalStudyTimeHours: '20',
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
        totalStudyTimeHours: '60',
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
        totalStudyTimeHours: '8',
      );
      final b = ProgressReport(
        totalAttempts: 10,
        correctAttempts: 8,
        accuracy: 0.8,
        topicsStudied: 2,
        completedLessons: 4,
        weeklyActivity: 2,
        totalStudyTimeHours: '8',
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
        totalStudyTimeHours: '8',
      );
      final b = ProgressReport(
        totalAttempts: 20,
        correctAttempts: 16,
        accuracy: 0.8,
        topicsStudied: 4,
        completedLessons: 8,
        weeklyActivity: 4,
        totalStudyTimeHours: '16',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
