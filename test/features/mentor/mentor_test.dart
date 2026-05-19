import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/mentor.dart';

void main() {
  group('mentor barrel', () {
    test('exports MentorService', () => expect(MentorService, isNotNull));
    test('exports MentorScreen', () => expect(MentorScreen, isNotNull));
    test('exports mentorModelIdProvider', () => expect(mentorModelIdProvider, isNotNull));
    test('exports MentorAction', () => expect(MentorAction, isNotNull));
    test('exports ProgressReport', () => expect(ProgressReport, isNotNull));

    group('MentorAction', () {
      test('holds message and type', () {
        final action = const MentorAction(message: 'Study more', type: 'generic');
        expect(action.message, 'Study more');
        expect(action.type, 'generic');
      });

      test('defaults type to generic', () {
        final action = const MentorAction(message: 'Review needed');
        expect(action.message, 'Review needed');
        expect(action.type, 'generic');
      });

      test('message is accessible as String', () {
        const action = MentorAction(message: 'Hello');
        expect(action.message, isA<String>());
      });

      test('type is accessible as String', () {
        const action = MentorAction(message: 'Hello', type: 'alert');
        expect(action.type, isA<String>());
      });
    });

    group('ProgressReport', () {
      test('stores values', () {
        const report = ProgressReport(
          totalAttempts: 100,
          correctAttempts: 75,
          accuracy: 75.0,
          topicsStudied: 5,
          completedLessons: 3,
          weeklyActivity: 20,
          totalStudyTimeHours: 12.5,
        );
        expect(report.totalAttempts, 100);
        expect(report.correctAttempts, 75);
        expect(report.accuracy, 75.0);
        expect(report.topicsStudied, 5);
        expect(report.completedLessons, 3);
        expect(report.weeklyActivity, 20);
        expect(report.totalStudyTimeHours, 12.5);
      });

      test('has a const constructor', () {
        const report = ProgressReport(
          totalAttempts: 0, correctAttempts: 0, accuracy: 0,
          topicsStudied: 0, completedLessons: 0, weeklyActivity: 0,
          totalStudyTimeHours: 0,
        );
        expect(report, isA<ProgressReport>());
      });

      test('all numeric fields accept int values', () {
        const report = ProgressReport(
          totalAttempts: 1, correctAttempts: 1, accuracy: 1,
          topicsStudied: 1, completedLessons: 1, weeklyActivity: 1,
          totalStudyTimeHours: 1,
        );
        expect(report.totalAttempts, isA<int>());
        expect(report.correctAttempts, isA<int>());
        expect(report.topicsStudied, isA<int>());
        expect(report.completedLessons, isA<int>());
        expect(report.weeklyActivity, isA<int>());
      });
    });

    group('ScheduleProposal', () {
      test('stores values', () {
        final now = DateTime(2025, 1, 15, 14, 0);
        final proposal = ScheduleProposal(
          topicTitle: 'Algebra Basics',
          topicId: 'topic_1',
          subjectId: 'subj_1',
          proposedTime: now,
          durationMinutes: 45,
        );
        expect(proposal.topicTitle, 'Algebra Basics');
        expect(proposal.topicId, 'topic_1');
        expect(proposal.subjectId, 'subj_1');
        expect(proposal.proposedTime, now);
        expect(proposal.durationMinutes, 45);
      });

      test('defaults durationMinutes to 30', () {
        final proposal = ScheduleProposal(
          topicTitle: 'Math',
          proposedTime: DateTime(2025, 1, 15),
        );
        expect(proposal.durationMinutes, 30);
      });

      test('defaults topicId and subjectId to null', () {
        final proposal = ScheduleProposal(
          topicTitle: 'Science',
          proposedTime: DateTime(2025, 1, 15),
        );
        expect(proposal.topicId, isNull);
        expect(proposal.subjectId, isNull);
      });
    });

    group('PlanProposal', () {
      test('stores values', () {
        final proposal = PlanProposal(days: 60, goal: 'Master Calculus', subjectId: 'subj_2');
        expect(proposal.days, 60);
        expect(proposal.goal, 'Master Calculus');
        expect(proposal.subjectId, 'subj_2');
      });

      test('defaults days to 30', () {
        final proposal = PlanProposal();
        expect(proposal.days, 30);
        expect(proposal.goal, isNull);
        expect(proposal.subjectId, isNull);
      });

      test('defaults goal and subjectId to null', () {
        final proposal = PlanProposal(days: 45);
        expect(proposal.goal, isNull);
        expect(proposal.subjectId, isNull);
      });
    });
  });
}
