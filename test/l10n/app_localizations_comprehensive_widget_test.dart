import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {




  group('AppLocalizations.of() - Widget Tests for Remaining Sections', () {
    testWidgets('mentor labels render correctly in English', (tester) async {
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
                    Text(l.mentor),
                    Text(l.aiTutor),
                    Text(l.startAiTutoring),
                    Text(l.endLesson),
                    Text(l.typeYourMessage),
                    Text(l.send),
                    Text(l.progressReport),
                    Text(l.askMentorAnything),
                    Text(l.mentorGreeting),
                    Text(l.mentorSubtitle),
                    Text(l.startingLesson),
                    Text(l.lessonComplete),
                    Text(l.inProgress),
                    Text(l.completed),
                    Text(l.notStarted),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Start AI Tutoring'), findsOneWidget);
      expect(find.text('End Lesson'), findsOneWidget);
      expect(find.text('Type your message...'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Progress Report'), findsOneWidget);
      expect(find.text('Ask your mentor anything...'), findsOneWidget);
      expect(find.text('AI Mentor'), findsOneWidget);
      expect(find.text('Your personal AI academic assistant'), findsOneWidget);
      expect(find.text('Starting your lesson...'), findsOneWidget);
      expect(find.text('Lesson Complete'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Not Started'), findsOneWidget);
    });

    testWidgets('roadmap labels render correctly in English', (tester) async {
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
                    Text(l.roadmaps),
                    Text(l.createRoadmap),
                    Text(l.roadmapGoal),
                    Text(l.roadmapGoalHint),
                    Text(l.generateRoadmap),
                    Text(l.myRoadmaps),
                    Text(l.milestones),
                    Text(l.milestone),
                    Text(l.targetCompletion),
                    Text(l.noRoadmapsYet),
                    Text(l.timeline),
                    Text(l.weekNumber(3)),
                    Text(l.milestoneForWeek(1)),
                    Text(l.completionOfValue('75.0%')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Roadmaps'), findsOneWidget);
      expect(find.text('Create Roadmap'), findsOneWidget);
      expect(find.text('Learning Goal'), findsOneWidget);
      expect(find.text('e.g., I want to learn IB Physics in 180 days'), findsOneWidget);
      expect(find.text('Generate Roadmap'), findsOneWidget);
      expect(find.text('My Roadmaps'), findsOneWidget);
      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('Milestone'), findsOneWidget);
      expect(find.text('Target Completion'), findsOneWidget);
      expect(find.text('No roadmaps yet'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Week 3'), findsOneWidget);
      expect(find.text('Milestone for week 1'), findsOneWidget);
      expect(find.text('75.0% Complete'), findsOneWidget);
    });

    testWidgets('notification labels render correctly in English', (tester) async {
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
                    Text(l.enableNotifications),
                    Text(l.notificationPreferences),
                    Text(l.dailyReminders),
                    Text(l.revisionReminders),
                    Text(l.notifChannelLessons),
                    Text(l.overworkAlerts),
                    Text(l.planAdjustmentNotifications),
                    Text(l.quietHours),
                    Text(l.quietHoursStart),
                    Text(l.quietHoursEnd),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Daily Reminders'), findsOneWidget);
      expect(find.text('Revision Reminders'), findsOneWidget);
      expect(find.text('Lesson Notifications'), findsOneWidget);
      expect(find.text('Overwork Alerts'), findsOneWidget);
      expect(find.text('Plan Adjustment Alerts'), findsOneWidget);
      expect(find.text('Quiet Hours'), findsOneWidget);
      expect(find.text('Quiet Hours Start'), findsOneWidget);
      expect(find.text('Quiet Hours End'), findsOneWidget);
    });

    testWidgets('focus mode labels render correctly in English', (tester) async {
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
                    Text(l.focusMode),
                    Text(l.newFocusSession),
                    Text(l.refreshStats),
                    Text(l.dailyLimitReached),
                    Text(l.dailyLimitReachedBody),
                    Text(l.breakTime),
                    Text(l.focusTime),
                    Text(l.timerRemaining),
                    Text(l.timerPaused),
                    Text(l.timerDone),
                    Text(l.resume),
                    Text(l.pause),
                    Text(l.markComplete),
                    Text(l.errorStartingSession('timeout')),
                    Text(l.sessionCompleted(25)),
                    Text(l.focusForMinutes(25)),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Study'), findsOneWidget);
      expect(find.text('New Focus Session'), findsOneWidget);
      expect(find.text('Refresh stats'), findsOneWidget);
      expect(find.text('Daily Limit Reached'), findsOneWidget);
      expect(find.text('Break Time!'), findsOneWidget);
      expect(find.text('Focus Time'), findsOneWidget);
      expect(find.text('remaining'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('DONE!'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Mark Complete'), findsOneWidget);
      expect(find.text('Error starting session: timeout'), findsOneWidget);
      expect(find.text('Session completed: 25m'), findsOneWidget);
      expect(find.text('Focus for 25 minutes'), findsOneWidget);
    });

    testWidgets('upload content labels render correctly in English', (tester) async {
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
                    Text(l.uploadContent),
                    Text(l.addStudyMaterials),
                    Text(l.titleRequired),
                    Text(l.titleHint),
                    Text(l.subjectOptional),
                    Text(l.none),
                    Text(l.pasteText),
                    Text(l.urlLink),
                    Text(l.urlRequired),
                    Text(l.urlHint),
                    Text(l.contentRequired),
                    Text(l.contentHint),
                    Text(l.uploading),
                    Text(l.fillRequiredFields),
                    Text(l.contentUploadedSuccessfully),
                    Text(l.uploadFailed('error')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Upload Content'), findsOneWidget);
      expect(find.text('Add study materials to your library'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('e.g. Chapter 5 Notes'), findsOneWidget);
      expect(find.text('Subject (optional)'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Paste Text'), findsOneWidget);
      expect(find.text('URL / Link'), findsOneWidget);
      expect(find.text('URL *'), findsOneWidget);
      expect(find.text('https://example.com/notes'), findsOneWidget);
      expect(find.text('Content *'), findsOneWidget);
      expect(find.text('Paste your study material here...'), findsOneWidget);
      expect(find.text('Uploading...'), findsOneWidget);
      expect(find.text('Please fill in all required fields.'), findsOneWidget);
      expect(find.text('Content uploaded successfully!'), findsOneWidget);
      expect(find.text('Upload failed: error'), findsOneWidget);
    });

    testWidgets('llm task manager labels render correctly in English', (tester) async {
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
                    Text(l.llmTaskManager),
                    Text(l.noLlmTasksYet),
                    Text(l.testConnection),
                    Text(l.testing),
                    Text(l.noPlanForToday),
                    Text(l.adjustPlan),
                    Text(l.dismiss),
                    Text(l.voiceInput),
                    Text(l.captureImage),
                    Text(l.camera),
                    Text(l.connectionSuccessful(120)),
                    Text(l.connectionFailed('timeout')),
                    Text(l.dailyPlanTarget(10, 60)),
                    Text(l.planAdjustmentSuggested(3)),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('LLM Task Manager'), findsOneWidget);
      expect(find.text('No LLM tasks yet'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Testing...'), findsOneWidget);
      expect(find.text('No plan for today'), findsOneWidget);
      expect(find.text('Adjust Plan'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Voice input'), findsOneWidget);
      expect(find.text('Capture Image'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Connection successful! Latency: 120ms'), findsOneWidget);
      expect(find.text('Connection failed: timeout'), findsOneWidget);
      expect(find.text('Today: 10Q, 60min'), findsOneWidget);
    });

    testWidgets('answer feedback labels render correctly in English', (tester) async {
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
                    Text(l.markschemeUnavailable),
                    Text(l.answerTooShort),
                    Text(l.goodResponseLength),
                    Text(l.answerTooShortForCredit),
                    Text(l.noDrawingDetected),
                    Text(l.invalidDrawingData),
                    Text(l.allStepsIdentified),
                    Text(l.specialHandlingRequired),
                    Text(l.someAnswersIncorrect),
                    Text(l.allRequiredStepsMissing),
                    Text(l.correctAnswerIs('Paris')),
                    Text(l.allStepsFormat(5)),
                    Text(l.partialStepsFormat(2, 5, 'step3')),
                    Text(l.noStepsFormat('step1')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('No markscheme available'), findsOneWidget);
      expect(find.text('Answer is too short. Please provide more details.'), findsOneWidget);
      expect(find.text('Good response length.'), findsOneWidget);
      expect(find.text('Answer too short for full credit.'), findsOneWidget);
      expect(find.text('No drawing detected. Please draw something.'), findsOneWidget);
      expect(find.text('Invalid drawing data. Please redraw.'), findsOneWidget);
      expect(find.text('All required steps identified.'), findsOneWidget);
      expect(find.text('This question type requires special handling.'), findsOneWidget);
      expect(find.text('Some answers are incorrect'), findsOneWidget);
      expect(find.text('Some required steps missing'), findsOneWidget);
      expect(find.text('The correct answer is: Paris'), findsOneWidget);
      expect(find.text('All 5 steps identified correctly!'), findsOneWidget);
      expect(find.text('Identified 2 of 5 steps. Missing: step3'), findsOneWidget);
      expect(find.text('No required steps found in your answer. Key steps to include: step1'),
          findsOneWidget);
    });

    testWidgets('ai tutor mode selection labels render correctly in English', (tester) async {
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
                    Text(l.aiTutor),
                    Text(l.interactiveConversationalLessons),
                    Text(l.personalStudyAssistantPlanner),
                    Text(l.chooseStudyMode),
                    Text(l.clearConversation),
                    Text(l.senderYou),
                    Text(l.senderTutor),
                    Text(l.senderSystem),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('AI Tutor'), findsWidgets);
      expect(find.text('Interactive conversational lessons'), findsOneWidget);
      expect(find.text('Personal study assistant & planner'), findsOneWidget);
      expect(find.text('Choose a study mode'), findsOneWidget);
      expect(find.text('Clear conversation'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Tutor'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('remaining parameterized labels render in widget tree', (tester) async {
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
                    Text(l.readyToLearnAbout('Math')),
                    Text(l.paceLabel(80)),
                    Text(l.correctCount(5)),
                    Text(l.remainingMinLabel(5)),
                    Text(l.correctCountLabel(7)),
                    Text(l.questionsAndMinutes(5, 30)),
                    Text(l.topicQuestionsAndMinutes(3, 15)),
                    Text(l.activeCount(3)),
                    Text(l.modelLabel('gpt-4')),
                    Text(l.startedLabel('10:00')),
                    Text(l.endedLabel('11:30')),
                    Text(l.tokensAndCost(1500, '0.03')),
                    Text(l.sessionHistoryCsvGenerated(1024)),
                    Text(l.pdfGenerated('2026-05-14')),
                    Text(l.pdfStudentId('STU001')),
                    Text(l.pdfTotalAttemptsRecorded(100)),
                    Text(l.pdfDateRange('2026-01-01', '2026-05-14')),
                    Text(l.pdfCorrectFraction(17, 20)),
                    Text(l.attemptsCount(5)),
                    Text(l.focusLabel('Math')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('I\'m ready to learn about Math. Please teach me!'), findsOneWidget);
      expect(find.text('80% pace'), findsOneWidget);
      expect(find.text('5 correct'), findsOneWidget);
      expect(find.text('5 min remaining'), findsOneWidget);
      expect(find.text('7 correct'), findsOneWidget);
      expect(find.text('5Q \u00b7 30min'), findsOneWidget);
      expect(find.text('3Q \u00b7 15min'), findsOneWidget);
      expect(find.text('3 active'), findsOneWidget);
      expect(find.text('Model: gpt-4'), findsOneWidget);
      expect(find.text('Started: 10:00'), findsOneWidget);
      expect(find.text('Ended: 11:30'), findsOneWidget);
      expect(find.text('Tokens: 1500 (0.03)'), findsOneWidget);
      expect(find.text('Session history CSV generated (1024 chars)'), findsOneWidget);
      expect(find.text('Generated: 2026-05-14'), findsOneWidget);
      expect(find.text('Student ID: STU001'), findsOneWidget);
      expect(find.text('Total attempts recorded: 100'), findsOneWidget);
      expect(find.text('Date range: 2026-01-01 to 2026-05-14'), findsOneWidget);
      expect(find.text('Correct: 17/20'), findsOneWidget);
      expect(find.text('5 attempts'), findsOneWidget);
      expect(find.text('Focus: Math'), findsOneWidget);
    });
  });



}
