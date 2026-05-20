import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {







  group('Widget Tests for Missing Localizations', () {
    testWidgets('localized bottom nav labels render correctly in Spanish', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return BottomNavigationBar(
                  currentIndex: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.school),
                      label: l10n.subjects,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.edit),
                      label: l10n.practice,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings),
                      label: l10n.settings,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Materias'), findsOneWidget);
      expect(find.text('Práctica'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
    });

    testWidgets('all mastery labels accessible in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.masteryOverview),
                    Text(l10n.totalTopicsLabel),
                    Text(l10n.masteredLabel),
                    Text(l10n.weakLabel),
                    Text(l10n.accuracyLabel('80%')),
                    Text(l10n.avgAccuracyLabel('75%')),
                    Text(l10n.avgReadinessLabel('85%')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Mastery Overview'), findsOneWidget);
      expect(find.text('Total Topics'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);
      expect(find.text('Accuracy: 80%'), findsOneWidget);
      expect(find.text('Avg Accuracy: 75%'), findsOneWidget);
      expect(find.text('Avg Readiness: 85%'), findsOneWidget);
    });

    testWidgets('block types and study plan labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.blockTypeExplanation),
                    Text(l10n.blockTypeExample),
                    Text(l10n.blockTypeExercise),
                    Text(l10n.blockTypeSlide),
                    Text(l10n.blockTypeQuiz),
                    Text(l10n.blockTypeSummary),
                    Text(l10n.blocksCount(3)),
                    Text(l10n.todaysPlan),
                    Text(l10n.noStudyPlanToday),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Slide'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('3 blocks'), findsOneWidget);
      expect(find.text('Today\'s Plan'), findsOneWidget);
      expect(find.text('No study plan for today'), findsOneWidget);
    });

    testWidgets('at-risk and ready-to-advance labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.atRiskTopics),
                    Text(l10n.noAtRiskTopics),
                    Text(l10n.readyToAdvance),
                    Text(l10n.keepPracticingToUnlock),
                    Text(l10n.practiceModeType('Quick', 'MCQ')),
                    Text(l10n.fallbackOption(2)),
                    Text(l10n.unsupportedQuestionType('audio')),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('At Risk Topics'), findsOneWidget);
      expect(find.text('No at-risk topics. Keep up the good work!'), findsOneWidget);
      expect(find.text('Ready to Advance'), findsOneWidget);
      expect(find.text('Keep practicing to unlock advanced topics!'), findsOneWidget);
      expect(find.text('Quick - MCQ'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Unsupported question type: audio'), findsOneWidget);
    });

    testWidgets('quick guide extended labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.quickGuideWelcomeMessage),
                    Text(l10n.suggestedPromptExplain),
                    Text(l10n.suggestedPromptQuiz),
                    Text(l10n.suggestedPromptMath),
                    Text(l10n.semanticsMessageInput),
                    Text(l10n.fallbackExplainResponse),
                    Text(l10n.fallbackQuizResponse),
                    Text(l10n.fallbackMathResponse),
                    Text(l10n.fallbackGeneralResponse),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!'), findsOneWidget);
      expect(find.text('Explain photosynthesis'), findsOneWidget);
      expect(find.text('Quiz me on history'), findsOneWidget);
      expect(find.text('Help with math problems'), findsOneWidget);
      expect(find.text('Message input for Quick Guide'), findsOneWidget);
    });

    testWidgets('session analytics labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  Text(l10n.avgSession),
                  Text(l10n.totalSessionsLabel),
                  Text(l10n.currentStreakLabel),
                  Text(l10n.sessionsByDayOfWeek),
                  Text(l10n.performanceMetrics),
                  Text(l10n.daysCount(5)),
                  Text(l10n.courseSessionLabel('Math', 3)),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Avg Session'), findsOneWidget);
      expect(find.text('Total Sessions'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Sessions by Day of Week'), findsOneWidget);
      expect(find.text('Performance Metrics'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('Math - Session 3'), findsOneWidget);
    });

    testWidgets('about and misc labels in widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(l10n.aboutApplicationName),
                    Text(l10n.aboutVersion),
                    Text(l10n.aboutLegalese),
                    Text(l10n.unknownModelId),
                    Text(l10n.unknownProviderName),
                    Text(l10n.examDateOptionalLabel),
                    Text(l10n.lessonFallbackTitle),
                    Text(l10n.questionTypeDefault),
                    Text('"${l10n.durationSeparator}"'),
                    Text(l10n.errorWithMessage('test')),
                    Text(l10n.semanticsYouSaid('hi')),
                    Text(l10n.semanticsQuickGuideSaid('hello')),
                    Text(l10n.semanticsSendPrompt('explain')),
                    Text(l10n.drawingSubmitted),
                    Text(l10n.questionsCountMetric(3)),
                    Text(l10n.minutesCountMetric(45)),
                    Text(l10n.noTopicsYetAddSome),
                    Text(l10n.noLessonsUsePlanner),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('StudyKing'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('\u00a9 2026 StudyKing.'), findsOneWidget);
      expect(find.text('unknown-model'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Exam Date (Optional):'), findsOneWidget);
      expect(find.text('Lesson'), findsOneWidget);
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('" "'), findsOneWidget);
      expect(find.text('Error: test'), findsOneWidget);
      expect(find.text('You said: hi'), findsOneWidget);
      expect(find.text('Quick Guide said: hello'), findsOneWidget);
      expect(find.text('Send prompt: explain'), findsOneWidget);
      expect(find.text('Drawing submitted'), findsOneWidget);
      expect(find.text('3 questions'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('No topics yet - add some!'), findsOneWidget);
      expect(find.text('No lessons - use Planner to generate!'), findsOneWidget);
    });
  });

  group('Locale Switching with Missing Locales', () {
    testWidgets('localizations fall back when no locale specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.subjects);
            },
          ),
        ),
      );

      expect(find.text('Subjects'), findsOneWidget);
    });

    testWidgets('localization works for all supported locales', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.appTitle);
              },
            ),
          ),
        );

        expect(find.text('StudyKing'), findsOneWidget);
      }
    });
  });


}
