import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {





  group('Widget Tests for Remaining Sections', () {
    testWidgets('planner and badge labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l.subjectProgress),
                    Text(l.pendingActions),
                    Text(l.scheduledLessons),
                    Text(l.regeneratePlan),
                    Text(l.viewAllLessons),
                    Text(l.change),
                    Text(l.scheduling),
                    Text(l.accept),
                    Text(l.scheduleALesson),
                    Text(l.rescheduleLesson),
                    Text(l.planAdjustmentTitle),
                    Text(l.actionNeeded),
                    Text(l.somethingWentWrong),
                    Text(l.openPlanner),
                    Text(l.studyPlanOverview),
                    Text(l.moreLessonsCount(5)),
                    Text(l.badgeFirstStepName),
                    Text(l.badgeFirstStepDesc),

                    Text(l.badgeAccuracyGoldName),
                    Text(l.badgeAccuracyGoldDesc),
                    Text(l.badgeDailyScholarName),
                    Text(l.badgeDailyScholarDesc),
                    Text(l.badgeDedicatedLearnerName),
                    Text(l.badgeDedicatedLearnerDesc),
                    Text(l.badgeWeeklyWarriorName),
                    Text(l.badgeWeeklyWarriorDesc),
                    Text(l.noBadgesYet),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Subject Progress'), findsOneWidget);
      expect(find.text('Pending Actions'), findsOneWidget);
      expect(find.text('Scheduled Lessons'), findsOneWidget);
      expect(find.text('Regenerate Plan'), findsOneWidget);
      expect(find.text('View All Lessons'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Scheduling...'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Schedule a lesson'), findsOneWidget);
      expect(find.text('Reschedule lesson'), findsOneWidget);
      expect(find.text('Plan adjustment suggested'), findsOneWidget);
      expect(find.text('Action needed'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Open Planner'), findsOneWidget);
      expect(find.text('Study Plan Overview'), findsOneWidget);
      expect(find.text('5 more...'), findsOneWidget);
    });

    testWidgets('notification labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l.notifChannelGeneral),
                    Text(l.notifChannelGeneralDesc),
                    Text(l.notifTitleTimeToReview),
                    Text(l.notifTitleTakeBreak),
                    Text(l.notifBodyOverwork(5)),
                    Text(l.notifTitlePlanAdjustment),
                    Text(l.notifBodyPlanAdjustment(3)),
                    Text(l.notifTitleUpcomingLesson),
                    Text(l.notifTitleTopicsNeedAttention),
                    Text(l.notifBodyLowMastery('Physics')),
                    Text(l.notifTitleBadgeUnlocked),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('StudyKing Notifications'), findsOneWidget);
      expect(
          find.text('General StudyKing notifications'), findsOneWidget);
      expect(find.text('Time to Review!'), findsOneWidget);
      expect(find.text('Take a Break'), findsOneWidget);
      expect(find.text('You\'ve studied 5 hours today. Remember to rest!'),
          findsOneWidget);
      expect(find.text('Plan Adjustment'), findsOneWidget);
      expect(find.text(
          'You\'ve had 3 days of low adherence. Shall we adjust your plan?'),
          findsOneWidget);
      expect(find.text('Upcoming Lesson'), findsOneWidget);
      expect(find.text('Topics Need Attention'), findsOneWidget);
      expect(find.text('Low mastery detected in: Physics'), findsOneWidget);
      expect(find.text('Badge Unlocked!'), findsOneWidget);
    });

    testWidgets('plan explanation labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l.planAccuracyLow),
                    Text(l.planReviewOverdue),
                    Text(l.planStreakLow),
                    Text(l.planPrerequisite),
                    Text(l.planHighMastery),
                    Text(l.planGoodProgress),
                    Text(l.planDeveloping),
                    Text(l.planAtRisk),
                    Text(l.planNeedsAttention),
                    Text(l.planReasonRequiredDependent),
                    Text(l.planReasonWeakPerformance),
                    Text(l.planReasonHighForgettingRisk),
                    Text(l.planReasonNewSyllabusTopic),
                    Text(l.planReasonPartOfGoal),
                    Text(l.planFocusGeneralReview),
                    Text(l.planFocusWeakAreas),
                    Text(l.planFocusPracticeReview),
                    Text(l.planFocusRestAndReview),
                    Text(l.planBlocksDownstream(3)),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Accuracy is below 60% — needs focused practice'),
          findsOneWidget);
      expect(find.text('Review is overdue — forgetting risk is high'),
          findsOneWidget);
      expect(find.text('Streak is low — consistency needed'), findsOneWidget);
      expect(find.text(
          'Prerequisite for upcoming topics — must master first'),
          findsOneWidget);
      expect(find.text('High mastery — ready to advance'), findsOneWidget);
      expect(find.text('Good progress — maintain consistency'),
          findsOneWidget);
      expect(find.text('Developing — needs more practice'), findsOneWidget);
      expect(find.text('At risk — review overdue'), findsOneWidget);
      expect(
          find.text('Needs attention — focus on fundamentals'),
          findsOneWidget);
    });

    testWidgets('nudge and adherence labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l.nudgeOverwork('6')),
                    Text(l.nudgeRevision(7, 'Biology')),
                    Text(l.nudgePlanAdjustment(5)),
                    Text(l.nudgeWeeklyDigest(50, 85, '12.5', 3, 2)),
                    Text(l.adherenceLowDaysAdjust(10)),
                    Text(l.adherenceLowDaysRegenerate(5)),
                    Text(l.adherenceLowToday(30, 60)),
                    Text(l.adherencePartialToday(45, 60)),
                    Text(l.adherenceExceededToday(75, 60)),
                    Text(l.recommendWeakTopics(3)),
                    Text(l.recommendAccuracyBelow60),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(
        find.text(
            'You have studied 6 hours today. Consider taking a break!'),
        findsOneWidget,
      );
      expect(
        find.text(
            'It has been 7 days since you practiced "Biology". Time for a review!'),
        findsOneWidget,
      );
      expect(find.text(
          'You have had 5 days of low plan adherence. Would you like to adjust your study plan?'),
          findsOneWidget);
    });

    testWidgets('getting started labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l.gettingStarted),
                    Text(l.gettingStartedDesc),
                    Text(l.addSubjectDesc),
                    Text(l.uploadMaterial),
                    Text(l.uploadMaterialDesc),
                    Text(l.takePracticeQuiz),
                    Text(l.takePracticeQuizDesc),
                    Text(l.scheduleAiTutor),
                    Text(l.scheduleAiTutorDesc),
                    Text(l.fileSaved),
                    Text(l.fileShared),
                    Text(l.noOptionsAvailable),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.text('Upload Study Material'), findsOneWidget);
      expect(find.text('Take Your First Practice Quiz'), findsOneWidget);
      expect(find.text('Schedule an AI Tutor Session'), findsOneWidget);
      expect(find.text('File saved successfully'), findsOneWidget);
      expect(find.text('File shared successfully'), findsOneWidget);
      expect(find.text('No options available'), findsOneWidget);
    });

    testWidgets('miscellaneous labels render correctly in English',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l.focus),
                    Text(l.shareSessionsText),
                    Text(l.summary),
                    Text(l.noLimit),
                    Text(l.focusTimerDescription),
                    Text(l.dailyStudyCap),
                    Text(l.tokenUsageSummary),
                    Text(l.totalTokens),
                    Text(l.totalCost),
                    Text(l.failed),
                    Text(l.subjectIdHint),
                    Text(l.adapSuggestionFundamentals),
                    Text(l.adapSuggestionMorePractice),
                    Text(l.adapSuggestionAdvancedTopics),
                    Text(l.recommendAccuracyBelow60),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Study Sessions'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('No limit'), findsOneWidget);
      expect(find.text('Start a focused study session'), findsOneWidget);
      expect(find.text('Daily Study Cap'), findsOneWidget);
      expect(find.text('Token Usage Summary'), findsOneWidget);
      expect(find.text('Total Tokens'), findsOneWidget);
      expect(find.text('Total Cost'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('e.g. sub_physics'), findsOneWidget);
      expect(find.text('Review basic concepts first'), findsOneWidget);
      expect(find.text('More practice questions recommended'),
          findsOneWidget);
      expect(find.text('Ready for advanced topics'), findsOneWidget);
    });

    testWidgets('notification aliases render correctly in English',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l.notifTitleTimeToReview),
                    Text(l.notificationTimeToReviewBody(5, 'History')),
                    Text(l.notifTitleTakeBreak),
                    Text(l.notifBodyOverwork(3)),
                    Text(l.notifTitlePlanAdjustment),
                    Text(l.notifBodyPlanAdjustment(7)),
                    Text(l.notifTitleUpcomingLesson),
                    Text(l.notificationUpcomingLessonBody('Physics', '2:00')),
                    Text(l.notifTitleTopicsNeedAttention),
                    Text(l.notifBodyLowMastery('Math')),
                    Text(l.notifTitleBadgeUnlocked),
                    Text(l.notificationBadgeUnlockedBody('Gold', '90%')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Hora de Repasar!'), findsNothing);
      expect(find.text('Time to Review!'), findsWidgets);
      expect(find.text(
          'It\'s been 5 days since you practiced "History".'),
          findsOneWidget);
      expect(find.text('Take a Break'), findsWidgets);
    });
  });

  group('Locale Switching Edge Cases', () {
    testWidgets('localization switches between en and es', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final l = AppLocalizations.of(context)!;
                return Text(l.focus);
              },
            ),
          ),
        );

        if (locale.languageCode == 'en') {
          expect(find.text('Study'), findsOneWidget);
        } else {
          expect(find.text('Estudio'), findsOneWidget);
        }
      }
    });

    testWidgets('all supported locales render without error',
        (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final l = AppLocalizations.of(context)!;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(l.focus),
                      Text(l.fileSaved),
                      Text(l.summary),
                      Text(l.noLimit),
                      Text(l.failed),
                      Text(l.gettingStarted),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    });
  });
}
