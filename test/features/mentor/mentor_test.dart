import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/mentor/mentor.dart';

void main() {
  group('mentor barrel', () {
    test('exports MentorService', () => expect(MentorService, isNotNull));
    test('exports MentorScreen', () => expect(MentorScreen, isNotNull));
    test('exports mentorModelIdProvider', () => expect(mentorModelIdProvider, isNotNull));
    test('exports MentorAction', () => expect(MentorAction, isNotNull));
    test('exports ProgressReport', () => expect(ProgressReport, isNotNull));

    test('MentorAction holds message and type', () {
      final action = const MentorAction(message: 'Study more', type: 'generic');
      expect(action.message, 'Study more');
      expect(action.type, 'generic');
    });

    test('MentorAction defaults type to generic', () {
      final action = const MentorAction(message: 'Review needed');
      expect(action.message, 'Review needed');
      expect(action.type, 'generic');
    });

    test('ProgressReport stores values', () {
      final report = const ProgressReport(
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

    test('ScheduleProposal stores values', () {
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

    test('ScheduleProposal defaults durationMinutes to 30', () {
      final proposal = ScheduleProposal(
        topicTitle: 'Math',
        proposedTime: DateTime(2025, 1, 15),
      );
      expect(proposal.durationMinutes, 30);
    });

    test('PlanProposal stores values', () {
      final proposal = PlanProposal(days: 60, goal: 'Master Calculus', subjectId: 'subj_2');
      expect(proposal.days, 60);
      expect(proposal.goal, 'Master Calculus');
      expect(proposal.subjectId, 'subj_2');
    });

    test('PlanProposal defaults days to 30', () {
      final proposal = PlanProposal();
      expect(proposal.days, 30);
      expect(proposal.goal, isNull);
      expect(proposal.subjectId, isNull);
    });
  });
}
