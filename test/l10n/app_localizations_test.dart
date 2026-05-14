import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';
import 'package:studyking/l10n/generated/app_localizations_es.dart';

void main() {
  group('AppLocalizations', () {
    group('Static Properties', () {
      test('delegate is a LocalizationsDelegate', () {
        expect(AppLocalizations.delegate, isA<LocalizationsDelegate<AppLocalizations>>());
      });

      test('delegate is const', () {
        const delegate = AppLocalizations.delegate;
        expect(delegate, isNotNull);
      });

      test('localizationsDelegates contains expected delegates', () {
        expect(AppLocalizations.localizationsDelegates, isA<List<LocalizationsDelegate<dynamic>>>());
        expect(AppLocalizations.localizationsDelegates.length, 4);
        expect(AppLocalizations.localizationsDelegates.contains(AppLocalizations.delegate), isTrue);
        expect(AppLocalizations.localizationsDelegates.contains(GlobalMaterialLocalizations.delegate), isTrue);
        expect(AppLocalizations.localizationsDelegates.contains(GlobalCupertinoLocalizations.delegate), isTrue);
        expect(AppLocalizations.localizationsDelegates.contains(GlobalWidgetsLocalizations.delegate), isTrue);
      });

      test('supportedLocales contains en and es', () {
        expect(AppLocalizations.supportedLocales, isA<List<Locale>>());
        expect(AppLocalizations.supportedLocales.length, 2);
        final locales = AppLocalizations.supportedLocales;
        expect(locales.any((l) => l.languageCode == 'en'), isTrue);
        expect(locales.any((l) => l.languageCode == 'es'), isTrue);
      });

      test('supportedLocales locales are properly formed', () {
        for (final locale in AppLocalizations.supportedLocales) {
          expect(locale.languageCode, isNotEmpty);
          expect(locale.countryCode, isNull);
        }
      });
    });

    group('AppLocalizations.of(context)', () {
      testWidgets('returns null when no localization is available', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Test'),
              ),
            ),
          ),
        );
        final context = tester.element(find.text('Test'));
        final localizations = AppLocalizations.of(context);
        expect(localizations, isNull);
      });

      testWidgets('returns AppLocalizations when delegate is provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isA<AppLocalizations>());
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns correct English localization for en locale', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isNotNull);
                expect(localizations!.appTitle, 'StudyKing');
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('returns correct Spanish localization for es locale', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isNotNull);
                expect(localizations!.appTitle, 'StudyKing');
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });
  });

  group('AppLocalizationsEn', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('has correct localeName', () {
      expect(l10n.localeName, 'en');
    });

    test('constructor accepts custom locale', () {
      final customLoc = AppLocalizationsEn('en-GB');
      expect(customLoc.localeName.startsWith('en'), isTrue);
    });

    test('locale name works with only language code', () {
      final loc = AppLocalizationsEn('en');
      expect(loc.localeName, 'en');
    });

    group('Simple Getters', () {
      test('study planner section', () {
        expect(l10n.appTitle, 'StudyKing');
        expect(l10n.subjects, 'Subjects');
        expect(l10n.practice, 'Practice');
        expect(l10n.settings, 'Settings');
        expect(l10n.studyPlanner, 'Study Planner');
        expect(l10n.createStudyPlan, 'Create Study Plan');
        expect(l10n.courseSubject, 'Course/Subject');
        expect(l10n.courseHint, 'e.g., IB Physics');
        expect(l10n.days, 'Days');
        expect(l10n.hoursPerDay, 'Hours/Day');
        expect(l10n.generatePlan, 'Generate Plan');
        expect(l10n.generating, 'Generating...');
        expect(l10n.yourStudySchedule, 'Your Study Schedule');
        expect(l10n.fillAllFieldsCorrectly, 'Please fill in all fields correctly');
        expect(l10n.today, 'Today');
        expect(l10n.yesterday, 'Yesterday');
        expect(l10n.unknown, 'Unknown');
      });

      test('practice section', () {
        expect(l10n.practiceMode, 'Practice Mode');
        expect(l10n.practiceOptions, 'Practice Options');
        expect(l10n.noSubjects, 'No Subjects');
        expect(l10n.noPracticeSessionsYet, 'No Practice Sessions Yet');
        expect(l10n.addSubjectsAndQuestionsToStartPracticing, 'Add subjects and questions to start practicing');
        expect(l10n.addSubjectsFromSubjectsTab, 'Add subjects from the Subjects tab');
        expect(l10n.addSubject, 'Add Subject');
        expect(l10n.practiceModes, 'Practice Modes');
        expect(l10n.quickPractice, 'Quick Practice');
        expect(l10n.comingSoon, 'Coming soon');
        expect(l10n.spacedRepetition, 'Spaced Repetition');
        expect(l10n.topicFocus, 'Topic Focus');
        expect(l10n.practiceSpecificTopics, 'Practice specific topics');
        expect(l10n.weakAreas, 'Weak Areas');
        expect(l10n.focusOnMistakes, 'Focus on mistakes');
        expect(l10n.yourSubjects, 'Your Subjects');
        expect(l10n.readyForPractice, 'Ready for practice');
        expect(l10n.practiceAvailable, 'Practice available');
        expect(l10n.selectSubject, 'Select Subject');
        expect(l10n.practiceModeTitle, 'Practice Mode');
        expect(l10n.autoSelect, 'Auto Select');
        expect(l10n.aiPicksOptimalQuestions, 'AI picks optimal questions');
        expect(l10n.chooseSubject, 'Choose Subject');
        expect(l10n.noCode, 'No code');
        expect(l10n.topicSelectionComingSoon, 'Topic selection coming soon!');
        expect(l10n.noQuestionsAvailable, 'No Questions Available');
        expect(l10n.noQuestionsForSelectedSubject, 'There are no questions for the selected subject/topic. Start creating questions!');
      });

      test('session results section', () {
        expect(l10n.time, 'Time');
        expect(l10n.score, 'Score');
        expect(l10n.correct, 'Correct');
        expect(l10n.yourAnswer, 'Your Answer');
        expect(l10n.submitAnswer, 'Submit Answer');
        expect(l10n.correctFeedback, 'Correct!');
        expect(l10n.incorrectFeedback, 'Incorrect');
        expect(l10n.previous, 'Previous');
        expect(l10n.next, 'Next');
        expect(l10n.sessionResults, 'Session Results');
        expect(l10n.practiceComplete, 'Practice Complete!');
        expect(l10n.totalQuestions, 'Total Questions');
        expect(l10n.correctAnswers, 'Correct Answers');
        expect(l10n.accuracy, 'Accuracy');
        expect(l10n.practiceAgain, 'Practice Again');
      });

      test('spaced repetition section', () {
        expect(l10n.allCaughtUp, 'All caught up!');
        expect(l10n.noReviewsScheduled, 'No reviews scheduled.');
        expect(l10n.reviewDueQuestions, 'Review due questions');
        expect(l10n.selectTopic, 'Select Topic');
        expect(l10n.noTopicsAvailable, 'No topics available');
        expect(l10n.noWeakAreasFound, 'No weak areas found. Keep up the great work!');
        expect(l10n.noWeakAreasQuestions, 'No questions available for your weak areas.');
        expect(l10n.questionsDueForReview, 'questions due for review');
        expect(l10n.spacedRepetitionMode, 'Spaced Repetition');
      });

      test('colors', () {
        expect(l10n.colorBlue, 'Blue');
        expect(l10n.colorGreen, 'Green');
        expect(l10n.colorOrange, 'Orange');
        expect(l10n.colorPurple, 'Purple');
        expect(l10n.colorPink, 'Pink');
        expect(l10n.colorCyan, 'Cyan');
        expect(l10n.colorAmber, 'Amber');
        expect(l10n.colorDeepOrange, 'Deep Orange');
        expect(l10n.colorBlueGrey, 'Blue Grey');
      });

      test('profile section', () {
        expect(l10n.profile, 'Profile');
        expect(l10n.nameIsRequired, 'Name is required');
        expect(l10n.studentIdMustBeNumeric, 'Student ID must be numeric');
        expect(l10n.profileSavedSuccessfully, 'Profile saved successfully');
        expect(l10n.chooseAvatar, 'Choose Avatar');
        expect(l10n.cancel, 'Cancel');
        expect(l10n.fullName, 'Full Name');
        expect(l10n.enterYourName, 'Enter your name');
        expect(l10n.studentIdOptional, 'Student ID (Optional)');
        expect(l10n.yourStudentIdNumber, 'Your student ID number');
        expect(l10n.learningGoal, 'Learning Goal');
        expect(l10n.learningGoalHint, 'e.g., Final Exams, Certifications');
        expect(l10n.preferredStudyTime, 'Preferred Study Time');
        expect(l10n.preferredStudyTimeHint, 'e.g., Evening (6-9 PM)');
        expect(l10n.accountInformation, 'Account Information');
        expect(l10n.language, 'Language');
        expect(l10n.english, 'English');
        expect(l10n.spanish, 'Spanish');
        expect(l10n.notifications, 'Notifications');
        expect(l10n.deleteAccountWarning, 'Deleting your account will permanently remove all study data');
        expect(l10n.delete, 'Delete');
        expect(l10n.deleteAccount, 'Delete Account');
        expect(l10n.deleteAccountConfirmation, 'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your study data.');
        expect(l10n.save, 'Save');
      });

      test('settings section', () {
        expect(l10n.userManagement, 'User Management');
        expect(l10n.currentUser, 'Current User');
        expect(l10n.manageYourProfile, 'Manage your profile');
        expect(l10n.quickAccess, 'Quick Access');
        expect(l10n.quickGuide, 'Quick Guide');
        expect(l10n.aiPoweredStudyAssistant, 'AI-powered study assistant');
        expect(l10n.appearance, 'Appearance');
        expect(l10n.theme, 'Theme');
        expect(l10n.light, 'Light');
        expect(l10n.dark, 'Dark');
        expect(l10n.system, 'System');
        expect(l10n.fontSize, 'Font Size');
        expect(l10n.small, 'Small');
        expect(l10n.fontSizeMedium, 'Medium');
        expect(l10n.large, 'Large');
        expect(l10n.extraLarge, 'Extra Large');
        expect(l10n.aiConfiguration, 'AI Configuration');
        expect(l10n.apiKeys, 'API Keys');
        expect(l10n.configured, 'Configured');
        expect(l10n.notConfigured, 'Not configured');
        expect(l10n.aiModel, 'AI Model');
        expect(l10n.selectModelFromApi, 'Select a model from API');
        expect(l10n.requestTimeout, 'Request Timeout');
      });

      test('study preferences section', () {
        expect(l10n.studyPreferences, 'Study Preferences');
        expect(l10n.studyReminders, 'Study Reminders');
        expect(l10n.enableNotificationAlerts, 'Enable notification alerts');
        expect(l10n.sessionDuration, 'Session Duration');
        expect(l10n.studyAnalytics, 'Study Analytics');
        expect(l10n.totalStudySessions, 'Total Study Sessions');
        expect(l10n.totalStudyTime, 'Total Study Time');
        expect(l10n.aboutSection, 'About');
        expect(l10n.aboutStudyKing, 'About StudyKing');
        expect(l10n.versionInfo, 'Version 0.1.0');
        expect(l10n.signOut, 'Sign Out');
      });

      test('API section', () {
        expect(l10n.apiKeyRequired, 'API Key Required');
        expect(l10n.pleaseConfigureApiKey, 'Please configure your API key first.');
        expect(l10n.ok, 'OK');
        expect(l10n.unableToLoadModels, 'Unable to load models right now.');
        expect(l10n.searchModels, 'Search models');
        expect(l10n.modelRequestTimedOut, 'Model request timed out. Please try again.');
        expect(l10n.unableToLoadModelsTryAgain, 'Unable to load models. Please try again.');
        expect(l10n.signOutConfirmation, 'Are you sure you want to sign out?');
        expect(l10n.sessionsLabel, 'Sessions');
        expect(l10n.questionsLabel, 'Questions');
      });

      test('subjects section', () {
        expect(l10n.mySubjects, 'My Subjects');
        expect(l10n.addNewSubject, 'Add New Subject');
        expect(l10n.subjectName, 'Subject Name');
        expect(l10n.subjectNameHint, 'e.g., Physics');
        expect(l10n.subjectCodeOptional, 'Subject Code (Optional)');
        expect(l10n.subjectCodeHint, 'e.g., IB-PHYS');
        expect(l10n.themeColor, 'Theme Color');
        expect(l10n.subjectColor, 'Subject Color');
        expect(l10n.examDateOptional, 'Exam Date (Optional)');
        expect(l10n.selectDate, 'Select date');
        expect(l10n.createSubject, 'Create Subject');
        expect(l10n.subjectCreatedSuccessfully, 'Subject created successfully');
        expect(l10n.pleaseEnterSubjectName, 'Please enter a subject name');
        expect(l10n.descriptionOptional, 'Description (Optional)');
        expect(l10n.descriptionHint, 'Brief description of the subject');
        expect(l10n.teacherOptional, 'Teacher (Optional)');
        expect(l10n.teacherHint, 'e.g., Dr. John Smith');
        expect(l10n.syllabusScopeOptional, 'Syllabus/Scope (Optional)');
        expect(l10n.syllabusHint, 'Brief overview of the syllabus');
        expect(l10n.teacherNameHint, 'Enter teacher name');
        expect(l10n.syllabusDescriptionHint, 'Enter syllabus description');
        expect(l10n.noSubjectsYet, 'No subjects yet');
        expect(l10n.addFirstSubject, 'Add your first subject to begin studying');
        expect(l10n.practiceSessions, 'Practice sessions');
        expect(l10n.startPractice, 'Start Practice');
        expect(l10n.noPracticeHistory, 'No practice history');
        expect(l10n.viewAllSessions, 'View All Sessions');
        expect(l10n.editSubject, 'Edit Subject');
        expect(l10n.deleteSubject, 'Delete Subject');
        expect(l10n.deleteSubjectConfirmation, 'Are you sure you want to delete this subject? This will also delete all associated lessons and questions.');
      });

      test('session details section', () {
        expect(l10n.sessionDetails, 'Session Details');
        expect(l10n.close, 'Close');
        expect(l10n.date, 'Date');
        expect(l10n.duration, 'Duration');
        expect(l10n.questions, 'Questions');
      });

      test('tabs section', () {
        expect(l10n.lessonsTab, 'Lessons');
        expect(l10n.practiceTab, 'Practice');
        expect(l10n.historyTab, 'History');
        expect(l10n.statsTab, 'Stats');
        expect(l10n.noLessonsYet, 'No lessons yet');
        expect(l10n.startLearningByCreatingTopics, 'Start learning by creating topics and questions');
        expect(l10n.addTopic, 'Add Topic');
        expect(l10n.lesson, 'Lesson');
        expect(l10n.practiceProgress, 'Practice Progress');
        expect(l10n.overallScore, 'Overall Score');
        expect(l10n.keepPracticing, 'Keep practicing to improve your score!');
        expect(l10n.selectFormat, 'Select question format:');
      });

      test('session tracker section', () {
        expect(l10n.studySessionTracker, 'Study Session Tracker');
        expect(l10n.start, 'Start');
        expect(l10n.end, 'End');
        expect(l10n.sessionComplete, 'Session Complete');
        expect(l10n.howManyQuestions, 'How many questions did you answer?');
        expect(l10n.questionsAnswered, 'Questions Answered');
        expect(l10n.skip, 'Skip');
      });

      test('graph section', () {
        expect(l10n.graphRenderer, 'Graph Renderer');
        expect(l10n.refreshGraph, 'Refresh graph');
        expect(l10n.validateGraphType, 'Validate graph type');
        expect(l10n.uploadData, 'Upload Data');
        expect(l10n.uploadDataFile, 'Upload Data File');
        expect(l10n.orPasteDataDirectly, 'Or paste data directly:');
        expect(l10n.pasteDataHint, 'Paste comma-separated data...');
        expect(l10n.graphTypeDetection, 'Graph Type Detection');
        expect(l10n.autoDetectFromData, 'Auto-detect from data:');
        expect(l10n.lineGraph, 'Line Graph');
        expect(l10n.barChart, 'Bar Chart');
        expect(l10n.scatterPlot, 'Scatter Plot');
        expect(l10n.pieChart, 'Pie Chart');
        expect(l10n.llmValidation, 'LLM Validation');
        expect(l10n.useLlmToValidateGraph, 'Use LLM to validate graph:');
        expect(l10n.describeWhatYouSee, 'Describe what you see in the graph...');
        expect(l10n.validateWithLlm, 'Validate with LLM');
        expect(l10n.validating, 'Validating...');
        expect(l10n.renderedGraph, 'Rendered Graph');
        expect(l10n.noDataUploaded, 'No data uploaded');
        expect(l10n.uploadOrPasteData, 'Upload or paste data to visualize');
        expect(l10n.selectGraphType, 'Select a graph type to visualize');
        expect(l10n.uploadDataFileDialog, 'Upload Data File');
        expect(l10n.fileUploadImplemented, 'File upload functionality would be implemented here.');
        expect(l10n.graphValidation, 'Graph Validation');
        expect(l10n.considerUsingPieChart, 'Consider using Pie Chart for small datasets');
        expect(l10n.considerUsingBarChart, 'Consider using Bar Chart for larger datasets');
        expect(l10n.graphTypeMatchesData, 'Graph type matches data structure');
        expect(l10n.graphRefreshed, 'Graph refreshed');
        expect(l10n.pleaseSelectGraphType, 'Please select a graph type first');
        expect(l10n.validationComplete, 'Validation complete');
        expect(l10n.graphTypeDetectionError, 'Graph type detection failed');
      });

      test('lesson scheduler section', () {
        expect(l10n.lessonScheduler, 'Lesson Scheduler');
        expect(l10n.upcomingLessons, 'Upcoming Lessons');
        expect(l10n.selectSubjectLabel, 'Select Subject');
        expect(l10n.generateQuestionTypes, 'Generate Question Types');
        expect(l10n.lessonProgress, 'Lesson Progress');
        expect(l10n.scheduleLesson, 'Schedule Lesson');
        expect(l10n.selectCalendarDate, 'Select calendar date for lesson');
        expect(l10n.done, 'Done');
        expect(l10n.createNewLesson, 'Create New Lesson');
        expect(l10n.editExistingLesson, 'Edit Existing Lesson');
        expect(l10n.mcq, 'MCQ');
        expect(l10n.inputLabel, 'Input');
        expect(l10n.graphLabel, 'Graph');
      });

      test('quick guide section', () {
        expect(l10n.quickGuideHelp, 'Quick Guide help');
        expect(l10n.help, 'Help');
        expect(l10n.quickGuideIsThinking, 'Quick Guide is thinking...');
        expect(l10n.suggestedPrompts, 'Suggested prompts');
        expect(l10n.askAnything, 'Ask anything...');
        expect(l10n.sendMessage, 'Send message');
        expect(l10n.messageInputHint, 'Type your question here');
        expect(l10n.quickGuideHelpTitle, 'Quick Guide Help');
        expect(l10n.gotIt, 'Got it');
      });

      test('answer section', () {
        expect(l10n.addAnswerBeforeSubmitting, 'Add an answer before submitting.');
        expect(l10n.nextQuestion, 'Next Question');
        expect(l10n.typeYourAnswerHere, 'Type your answer here...');
        expect(l10n.writeYourEssayAnswer, 'Write your essay answer...');
        expect(l10n.questionTypeNotSupported, 'This question type is not yet supported in this view.');
        expect(l10n.multipleChoice, 'Multiple Choice');
        expect(l10n.multipleSelect, 'Multiple Select');
        expect(l10n.textAnswer, 'Text Answer');
        expect(l10n.math, 'Math');
        expect(l10n.essay, 'Essay');
        expect(l10n.diagram, 'Diagram');
        expect(l10n.graphQuestion, 'Graph');
        expect(l10n.stepByStep, 'Step-by-Step');
        expect(l10n.easy, 'Easy');
        expect(l10n.hard, 'Hard');
        expect(l10n.selectAsAnswer, 'Select as answer');
        expect(l10n.selectedRightOption, 'Selected right option');
        expect(l10n.tryAgain, 'Try again');
      });

      test('canvas section', () {
        expect(l10n.drawHere, 'Draw here...');
        expect(l10n.undoLastStroke, 'Undo last stroke');
        expect(l10n.clearAllDrawings, 'Clear all drawings');
        expect(l10n.canvasIsEmpty, 'Canvas is empty');
        expect(l10n.saveDrawing, 'Save Drawing');
        expect(l10n.drawingSaved, 'Drawing saved.');
        expect(l10n.failedToSaveDrawing, 'Failed to save drawing. Retry.');
        expect(l10n.drawingCanvas, 'Drawing canvas');
        expect(l10n.drawYourAnswer, 'Draw your answer on the canvas using your finger or stylus');
      });

      test('API configuration section', () {
        expect(l10n.apiConfiguration, 'API Configuration');
        expect(l10n.configureApiKeys, 'Configure API Keys');
        expect(l10n.configureApiKeysDescription, 'Enter your OpenRouter API credentials below. These are used to power the AI features.');
        expect(l10n.openRouterApiKey, 'OpenRouter API Key');
        expect(l10n.apiBaseUrl, 'API Base URL');
        expect(l10n.apiKeyHint, 'sk-or-v1-...');
        expect(l10n.apiBaseUrlHint, 'https://openrouter.ai/api/v1');
        expect(l10n.apiKeyDescription, 'Required for LLM content generation. Get your key from https://openrouter.ai/keys');
        expect(l10n.apiBaseUrlDescription, 'The endpoint URL for the AI service');
        expect(l10n.saveApiKeys, 'Save API Keys');
        expect(l10n.apiKeyCannotBeEmpty, 'API key cannot be empty');
        expect(l10n.apiKeysSavedSuccessfully, 'API keys saved successfully');
        expect(l10n.unableToSaveApiConfig, 'Unable to save API configuration. Please try again.');
      });

      test('session history section', () {
        expect(l10n.currentSession, 'Current Session');
        expect(l10n.noActiveSession, 'No Active Session');
        expect(l10n.tapStartToBegin, 'Tap start to begin tracking');
        expect(l10n.recentSessions, 'Recent Sessions');
        expect(l10n.viewAll, 'View All');
        expect(l10n.noSessionsYet, 'No sessions yet');
        expect(l10n.startYourFirstSession, 'Start your first session!');
        expect(l10n.filterByDate, 'Filter by Date');
        expect(l10n.filterBySubject, 'Filter by Subject');
        expect(l10n.clearFilters, 'Clear filters');
        expect(l10n.clearFilterLabel, 'Clear');
        expect(l10n.totalTime, 'Total Time');
        expect(l10n.average, 'Average');
        expect(l10n.noSessionsFoundForFilters, 'No sessions found for selected filters');
        expect(l10n.tryAdjustingFilters, 'Try adjusting your filters');
        expect(l10n.startStudyingToTrack, 'Start studying to track your progress');
        expect(l10n.sessionDeleted, 'Session deleted');
        expect(l10n.undo, 'Undo');
        expect(l10n.deleteSession, 'Delete Session');
        expect(l10n.deleteSessionConfirmation, 'Are you sure you want to delete this session?');
        expect(l10n.noQuestions, 'No questions');
        expect(l10n.selectDateToFilter, 'Select a date to filter sessions');
        expect(l10n.filterBySubjectTitle, 'Filter by Subject');
        expect(l10n.sessionHistory, 'Session History');
      });
    });

    group('Parameterized Methods', () {
      test('topicLabel', () {
        expect(l10n.topicLabel(1), 'Topic 1');
        expect(l10n.topicLabel(5), 'Topic 5');
        expect(l10n.topicLabel(100), 'Topic 100');
      });

      test('sessionDurationMinutes', () {
        expect(l10n.sessionDurationMinutes(1), '1 min session');
        expect(l10n.sessionDurationMinutes(30), '30 min session');
        expect(l10n.sessionDurationMinutes(60), '60 min session');
      });

      test('generatedPlanOverDays', () {
        expect(l10n.generatedPlanOverDays('Math', 7, 14), 'Generated plan for Math over 7 days (14 total hours)');
        expect(l10n.generatedPlanOverDays('Physics', 30, 60), 'Generated plan for Physics over 30 days (60 total hours)');
      });

      group('overDaysPlural', () {
        test('zero', () => expect(l10n.overDaysPlural(0), 'over no days'));
        test('one', () => expect(l10n.overDaysPlural(1), 'over 1 day'));
        test('other', () {
          expect(l10n.overDaysPlural(2), 'over 2 days');
          expect(l10n.overDaysPlural(7), 'over 7 days');
          expect(l10n.overDaysPlural(30), 'over 30 days');
        });
      });

      group('totalHoursPlural', () {
        test('one', () => expect(l10n.totalHoursPlural(1), '1 total hour'));
        test('other', () {
          expect(l10n.totalHoursPlural(2), '2 total hours');
          expect(l10n.totalHoursPlural(10), '10 total hours');
          expect(l10n.totalHoursPlural(100), '100 total hours');
        });
      });

      group('durationDays', () {
        test('one', () => expect(l10n.durationDays(1), '1d'));
        test('other', () {
          expect(l10n.durationDays(2), '2d');
          expect(l10n.durationDays(7), '7d');
          expect(l10n.durationDays(30), '30d');
        });
      });

      group('durationHours', () {
        test('one', () => expect(l10n.durationHours(1), '1h'));
        test('other', () {
          expect(l10n.durationHours(2), '2h');
          expect(l10n.durationHours(5), '5h');
          expect(l10n.durationHours(24), '24h');
        });
      });

      group('durationMinutes', () {
        test('one', () => expect(l10n.durationMinutes(1), '1m'));
        test('other', () {
          expect(l10n.durationMinutes(2), '2m');
          expect(l10n.durationMinutes(30), '30m');
          expect(l10n.durationMinutes(60), '60m');
        });
      });

      group('durationSeconds', () {
        test('one', () => expect(l10n.durationSeconds(1), '1s'));
        test('other', () {
          expect(l10n.durationSeconds(2), '2s');
          expect(l10n.durationSeconds(30), '30s');
          expect(l10n.durationSeconds(59), '59s');
        });
      });

      test('randomQuestions', () {
        expect(l10n.randomQuestions(5), '5 random questions');
        expect(l10n.randomQuestions(10), '10 random questions');
        expect(l10n.randomQuestions(1), '1 random question');
      });

      test('yourAnswerCharacters', () {
        expect(l10n.yourAnswerCharacters(0), 'Your Answer (0 characters)');
        expect(l10n.yourAnswerCharacters(100), 'Your Answer (100 characters)');
        expect(l10n.yourAnswerCharacters(500), 'Your Answer (500 characters)');
      });

      test('dueQuestionsCount', () {
        expect(l10n.dueQuestionsCount(0), '0 due');
        expect(l10n.dueQuestionsCount(3), '3 due');
        expect(l10n.dueQuestionsCount(10), '10 due');
      });

      test('secondsValue', () {
        expect(l10n.secondsValue(0), '0 seconds');
        expect(l10n.secondsValue(30), '30 seconds');
        expect(l10n.secondsValue(60), '60 seconds');
      });

      test('minutesValue', () {
        expect(l10n.minutesValue(0), '0 minutes');
        expect(l10n.minutesValue(15), '15 minutes');
        expect(l10n.minutesValue(60), '60 minutes');
      });

      test('sessionsCount', () {
        expect(l10n.sessionsCount(0), '0 sessions');
        expect(l10n.sessionsCount(1), '1 session');
        expect(l10n.sessionsCount(10), '10 sessions');
      });

      test('errorSavingProfile', () {
        expect(l10n.errorSavingProfile('timeout'), 'Error saving profile: timeout');
        expect(l10n.errorSavingProfile('network error'), 'Error saving profile: network error');
        expect(l10n.errorSavingProfile(''), 'Error saving profile: ');
      });

      test('selectAvatar', () {
        expect(l10n.selectAvatar('robot'), 'Select avatar robot');
        expect(l10n.selectAvatar('cat'), 'Select avatar cat');
      });

      test('questionsCount', () {
        expect(l10n.questionsCount(0), 'Questions: 0');
        expect(l10n.questionsCount(5), 'Questions: 5');
        expect(l10n.questionsCount(100), 'Questions: 100');
      });

      test('practiceQuestionsFrom', () {
        expect(l10n.practiceQuestionsFrom('Math'), 'Practice questions from Math');
        expect(l10n.practiceQuestionsFrom('Physics'), 'Practice questions from Physics');
      });

      test('sessionNumber', () {
        expect(l10n.sessionNumber(1), 'Session 1');
        expect(l10n.sessionNumber(5), 'Session 5');
      });

      test('graphVisualization', () {
        expect(l10n.graphVisualization('Line Graph'), 'Line Graph Visualization');
        expect(l10n.graphVisualization('Bar Chart'), 'Bar Chart Visualization');
      });

      test('dataPointsCount', () {
        expect(l10n.dataPointsCount(0), 'Data points: 0');
        expect(l10n.dataPointsCount(10), 'Data points: 10');
        expect(l10n.dataPointsCount(1000), 'Data points: 1000');
      });

      test('graphTypeSetTo', () {
        expect(l10n.graphTypeSetTo('Line'), 'Graph type set to Line');
        expect(l10n.graphTypeSetTo('Pie'), 'Graph type set to Pie');
      });

      test('typeLabel', () {
        expect(l10n.typeLabel('Line'), 'Type: Line');
        expect(l10n.typeLabel('Bar'), 'Type: Bar');
      });

      test('validationFailed', () {
        expect(l10n.validationFailed('mismatch'), 'Validation failed: mismatch');
        expect(l10n.validationFailed('error'), 'Validation failed: error');
      });

      test('percentComplete', () {
        expect(l10n.percentComplete(50, 5, 10), '50% Complete: 5/10 questions generated');
        expect(l10n.percentComplete(100, 10, 10), '100% Complete: 10/10 questions generated');
        expect(l10n.percentComplete(0, 0, 10), '0% Complete: 0/10 questions generated');
      });

      test('difficultyLabel', () {
        expect(l10n.difficultyLabel('Easy'), 'Difficulty: Easy');
        expect(l10n.difficultyLabel('Hard'), 'Difficulty: Hard');
        expect(l10n.difficultyLabel('Medium'), 'Difficulty: Medium');
      });

      test('drawingWithStrokes', () {
        expect(l10n.drawingWithStrokes(1), 'Drawing with 1 stroke');
        expect(l10n.drawingWithStrokes(3), 'Drawing with 3 strokes');
      });

      test('ofLabel', () {
        expect(l10n.ofLabel(1, 10), '1 of 10');
        expect(l10n.ofLabel(5, 5), '5 of 5');
        expect(l10n.ofLabel(0, 10), '0 of 10');
      });

      test('questionsCountLabel', () {
        expect(l10n.questionsCountLabel(0), '0 questions');
        expect(l10n.questionsCountLabel(5), '5 questions');
        expect(l10n.questionsCountLabel(100), '100 questions');
      });

      test('correctOf', () {
        expect(l10n.correctOf(3, 5), 'Correct: 3/5');
        expect(l10n.correctOf(0, 10), 'Correct: 0/10');
        expect(l10n.correctOf(10, 10), 'Correct: 10/10');
      });

      test('errorCreatingSubject', () {
        expect(l10n.errorCreatingSubject('duplicate'), 'Error creating subject: duplicate');
        expect(l10n.errorCreatingSubject(''), 'Error creating subject: ');
      });

      test('errorSavingSubject', () {
        expect(l10n.errorSavingSubject('timeout'), 'Error saving subject: timeout');
      });

      test('failedToDeleteSession', () {
        expect(l10n.failedToDeleteSession('not found'), 'Failed to delete session: not found');
      });

      test('failedToSaveSession', () {
        expect(l10n.failedToSaveSession('disk full'), 'Failed to save session: disk full');
      });
    });
  });

  group('AppLocalizationsEs', () {
    late AppLocalizationsEs l10n;

    setUp(() {
      l10n = AppLocalizationsEs();
    });

    test('has correct localeName', () {
      expect(l10n.localeName, 'es');
    });

    test('constructor accepts custom locale', () {
      final customLoc = AppLocalizationsEs('es-MX');
      expect(customLoc.localeName.startsWith('es'), isTrue);
    });

    test('locale name works with only language code', () {
      final loc = AppLocalizationsEs('es');
      expect(loc.localeName, 'es');
    });

    group('Simple Getters', () {
      test('study planner section', () {
        expect(l10n.appTitle, 'StudyKing');
        expect(l10n.subjects, 'Materias');
        expect(l10n.practice, 'Práctica');
        expect(l10n.settings, 'Ajustes');
        expect(l10n.studyPlanner, 'Planificador de Estudio');
        expect(l10n.createStudyPlan, 'Crear Plan de Estudio');
        expect(l10n.courseSubject, 'Curso/Materia');
        expect(l10n.courseHint, 'p. ej., Física IB');
        expect(l10n.days, 'Días');
        expect(l10n.hoursPerDay, 'Horas/Día');
        expect(l10n.generatePlan, 'Generar Plan');
        expect(l10n.generating, 'Generando...');
        expect(l10n.yourStudySchedule, 'Su Horario de Estudio');
        expect(l10n.fillAllFieldsCorrectly, 'Por favor complete todos los campos correctamente');
        expect(l10n.today, 'Hoy');
        expect(l10n.yesterday, 'Ayer');
        expect(l10n.unknown, 'Desconocido');
      });

      test('practice section', () {
        expect(l10n.practiceMode, 'Modo de Práctica');
        expect(l10n.practiceOptions, 'Opciones de Práctica');
        expect(l10n.noSubjects, 'Sin Materias');
        expect(l10n.noPracticeSessionsYet, 'Sin Sesiones de Práctica');
        expect(l10n.addSubjectsAndQuestionsToStartPracticing, 'Agregue materias y preguntas para comenzar a practicar');
        expect(l10n.addSubjectsFromSubjectsTab, 'Agregue materias desde la pestaña Materias');
        expect(l10n.addSubject, 'Agregar Materia');
        expect(l10n.practiceModes, 'Modos de Práctica');
        expect(l10n.quickPractice, 'Práctica Rápida');
        expect(l10n.comingSoon, 'Próximamente');
        expect(l10n.spacedRepetition, 'Repetición Espaciada');
        expect(l10n.topicFocus, 'Enfoque por Tema');
        expect(l10n.practiceSpecificTopics, 'Practique temas específicos');
        expect(l10n.weakAreas, 'Áreas por mejorar');
        expect(l10n.focusOnMistakes, 'Concéntrese en sus errores');
        expect(l10n.yourSubjects, 'Sus Materias');
        expect(l10n.readyForPractice, 'Listo para practicar');
        expect(l10n.practiceAvailable, 'Práctica disponible');
        expect(l10n.selectSubject, 'Seleccionar Materia');
        expect(l10n.practiceModeTitle, 'Modo de Práctica');
        expect(l10n.autoSelect, 'Selección Automática');
        expect(l10n.aiPicksOptimalQuestions, 'La IA selecciona preguntas óptimas');
        expect(l10n.chooseSubject, 'Elegir Materia');
        expect(l10n.noCode, 'Sin código');
        expect(l10n.topicSelectionComingSoon, '¡Selección de temas próximamente!');
        expect(l10n.noQuestionsAvailable, 'No Hay Preguntas Disponibles');
        expect(l10n.noQuestionsForSelectedSubject, 'No hay preguntas para la materia/tema seleccionado. ¡Comience a crear preguntas!');
      });

      test('session results section', () {
        expect(l10n.time, 'Tiempo');
        expect(l10n.score, 'Puntuación');
        expect(l10n.correct, 'Correctas');
        expect(l10n.yourAnswer, 'Su Respuesta');
        expect(l10n.submitAnswer, 'Enviar Respuesta');
        expect(l10n.correctFeedback, '¡Correcto!');
        expect(l10n.incorrectFeedback, 'Incorrecto');
        expect(l10n.previous, 'Anterior');
        expect(l10n.next, 'Siguiente');
        expect(l10n.sessionResults, 'Resultados de la Sesión');
        expect(l10n.practiceComplete, '¡Práctica Completada!');
        expect(l10n.totalQuestions, 'Total de Preguntas');
        expect(l10n.correctAnswers, 'Respuestas Correctas');
        expect(l10n.accuracy, 'Precisión');
        expect(l10n.practiceAgain, 'Practicar de Nuevo');
      });

      test('spaced repetition section', () {
        expect(l10n.allCaughtUp, '¡Todo al día!');
        expect(l10n.noReviewsScheduled, 'No hay repasos programados.');
        expect(l10n.reviewDueQuestions, 'Repasar preguntas pendientes');
        expect(l10n.selectTopic, 'Seleccionar Tema');
        expect(l10n.noTopicsAvailable, 'No hay temas disponibles');
        expect(l10n.noWeakAreasFound, 'No se encontraron áreas débiles. ¡Siga así!');
        expect(l10n.noWeakAreasQuestions, 'No hay preguntas disponibles para sus áreas débiles.');
        expect(l10n.questionsDueForReview, 'preguntas pendientes de repaso');
        expect(l10n.spacedRepetitionMode, 'Repetición Espaciada');
      });

      test('colors', () {
        expect(l10n.colorBlue, 'Azul');
        expect(l10n.colorGreen, 'Verde');
        expect(l10n.colorOrange, 'Naranja');
        expect(l10n.colorPurple, 'Morado');
        expect(l10n.colorPink, 'Rosa');
        expect(l10n.colorCyan, 'Cian');
        expect(l10n.colorAmber, 'Ámbar');
        expect(l10n.colorDeepOrange, 'Naranja Oscuro');
        expect(l10n.colorBlueGrey, 'Gris Azulado');
      });

      test('profile section', () {
        expect(l10n.profile, 'Perfil');
        expect(l10n.nameIsRequired, 'El nombre es obligatorio');
        expect(l10n.studentIdMustBeNumeric, 'El ID de estudiante debe ser numérico');
        expect(l10n.profileSavedSuccessfully, 'Perfil guardado exitosamente');
        expect(l10n.chooseAvatar, 'Elegir Avatar');
        expect(l10n.cancel, 'Cancelar');
        expect(l10n.fullName, 'Nombre Completo');
        expect(l10n.enterYourName, 'Ingrese su nombre');
        expect(l10n.studentIdOptional, 'ID de Estudiante (Opcional)');
        expect(l10n.yourStudentIdNumber, 'Su número de ID de estudiante');
        expect(l10n.learningGoal, 'Objetivo de Aprendizaje');
        expect(l10n.learningGoalHint, 'p. ej., Exámenes Finales, Certificaciones');
        expect(l10n.preferredStudyTime, 'Horario de Estudio Preferido');
        expect(l10n.preferredStudyTimeHint, 'p. ej., Tarde (6-9 PM)');
        expect(l10n.accountInformation, 'Información de la Cuenta');
        expect(l10n.language, 'Idioma');
        expect(l10n.english, 'Inglés');
        expect(l10n.spanish, 'Español');
        expect(l10n.notifications, 'Notificaciones');
        expect(l10n.deleteAccountWarning, 'Eliminar su cuenta eliminará permanentemente todos los datos de estudio');
        expect(l10n.delete, 'Eliminar');
        expect(l10n.deleteAccount, 'Eliminar Cuenta');
        expect(l10n.deleteAccountConfirmation, '¿Está seguro de que desea eliminar su cuenta? Esta acción no se puede deshacer y eliminará permanentemente todos sus datos de estudio.');
        expect(l10n.save, 'Guardar');
      });

      test('settings section', () {
        expect(l10n.userManagement, 'Gestión de Usuarios');
        expect(l10n.currentUser, 'Usuario Actual');
        expect(l10n.manageYourProfile, 'Administre su perfil');
        expect(l10n.quickAccess, 'Acceso Rápido');
        expect(l10n.quickGuide, 'Guía Rápida');
        expect(l10n.aiPoweredStudyAssistant, 'Asistente de estudio impulsado por IA');
        expect(l10n.appearance, 'Apariencia');
        expect(l10n.theme, 'Tema');
        expect(l10n.light, 'Claro');
        expect(l10n.dark, 'Oscuro');
        expect(l10n.system, 'Sistema');
        expect(l10n.fontSize, 'Tamaño de Fuente');
        expect(l10n.small, 'Pequeño');
        expect(l10n.fontSizeMedium, 'Mediano');
        expect(l10n.large, 'Grande');
        expect(l10n.extraLarge, 'Extra Grande');
        expect(l10n.aiConfiguration, 'Configuración de IA');
        expect(l10n.apiKeys, 'Claves API');
        expect(l10n.configured, 'Configurado');
        expect(l10n.notConfigured, 'No configurado');
        expect(l10n.aiModel, 'Modelo de IA');
        expect(l10n.selectModelFromApi, 'Seleccione un modelo desde la API');
        expect(l10n.requestTimeout, 'Tiempo de Espera');
      });

      test('study preferences section', () {
        expect(l10n.studyPreferences, 'Preferencias de Estudio');
        expect(l10n.studyReminders, 'Recordatorios de Estudio');
        expect(l10n.enableNotificationAlerts, 'Activar alertas de notificación');
        expect(l10n.sessionDuration, 'Duración de la Sesión');
        expect(l10n.studyAnalytics, 'Analíticas de Estudio');
        expect(l10n.totalStudySessions, 'Sesiones de Estudio Totales');
        expect(l10n.totalStudyTime, 'Tiempo Total de Estudio');
        expect(l10n.aboutSection, 'Acerca de');
        expect(l10n.aboutStudyKing, 'Acerca de StudyKing');
        expect(l10n.versionInfo, 'Versión 0.1.0');
        expect(l10n.signOut, 'Cerrar Sesión');
      });

      test('API section', () {
        expect(l10n.apiKeyRequired, 'Clave API Requerida');
        expect(l10n.pleaseConfigureApiKey, 'Por favor configure su clave API primero.');
        expect(l10n.ok, 'OK');
        expect(l10n.unableToLoadModels, 'No se pueden cargar los modelos en este momento.');
        expect(l10n.searchModels, 'Buscar modelos');
        expect(l10n.modelRequestTimedOut, 'La solicitud del modelo superó el tiempo de espera. Intente de nuevo.');
        expect(l10n.unableToLoadModelsTryAgain, 'No se pueden cargar los modelos. Intente de nuevo.');
        expect(l10n.signOutConfirmation, '¿Está seguro de que desea cerrar sesión?');
        expect(l10n.sessionsLabel, 'Sesiones');
        expect(l10n.questionsLabel, 'Preguntas');
      });

      test('subjects section', () {
        expect(l10n.mySubjects, 'Mis Materias');
        expect(l10n.addNewSubject, 'Agregar Nueva Materia');
        expect(l10n.subjectName, 'Nombre de la Materia');
        expect(l10n.subjectNameHint, 'p. ej., Física');
        expect(l10n.subjectCodeOptional, 'Código de Materia (Opcional)');
        expect(l10n.subjectCodeHint, 'p. ej., IB-FIS');
        expect(l10n.themeColor, 'Color del Tema');
        expect(l10n.subjectColor, 'Color de la Materia');
        expect(l10n.examDateOptional, 'Fecha de Examen (Opcional)');
        expect(l10n.selectDate, 'Seleccionar fecha');
        expect(l10n.createSubject, 'Crear Materia');
        expect(l10n.subjectCreatedSuccessfully, 'Materia creada exitosamente');
        expect(l10n.pleaseEnterSubjectName, 'Por favor ingrese un nombre para la materia');
        expect(l10n.descriptionOptional, 'Descripción (Opcional)');
        expect(l10n.descriptionHint, 'Breve descripción de la materia');
        expect(l10n.teacherOptional, 'Profesor (Opcional)');
        expect(l10n.teacherHint, 'p. ej., Dr. Juan García');
        expect(l10n.syllabusScopeOptional, 'Plan de Estudios/Alcance (Opcional)');
        expect(l10n.syllabusHint, 'Breve resumen del plan de estudios');
        expect(l10n.teacherNameHint, 'Ingrese el nombre del profesor');
        expect(l10n.syllabusDescriptionHint, 'Ingrese la descripción del plan de estudios');
        expect(l10n.noSubjectsYet, 'Sin materias todavía');
        expect(l10n.addFirstSubject, 'Agregue su primera materia para comenzar a estudiar');
        expect(l10n.practiceSessions, 'Sesiones de práctica');
        expect(l10n.startPractice, 'Comenzar Práctica');
        expect(l10n.noPracticeHistory, 'Sin historial de práctica');
        expect(l10n.viewAllSessions, 'Ver Todas las Sesiones');
        expect(l10n.editSubject, 'Editar Materia');
        expect(l10n.deleteSubject, 'Eliminar Materia');
        expect(l10n.deleteSubjectConfirmation, '¿Está seguro de que desea eliminar esta materia? Esto también eliminará todas las lecciones y preguntas asociadas.');
      });

      test('session details section', () {
        expect(l10n.sessionDetails, 'Detalles de la Sesión');
        expect(l10n.close, 'Cerrar');
        expect(l10n.date, 'Fecha');
        expect(l10n.duration, 'Duración');
        expect(l10n.questions, 'Preguntas');
      });

      test('tabs section', () {
        expect(l10n.lessonsTab, 'Lecciones');
        expect(l10n.practiceTab, 'Práctica');
        expect(l10n.historyTab, 'Historial');
        expect(l10n.statsTab, 'Estadísticas');
        expect(l10n.noLessonsYet, 'Sin lecciones todavía');
        expect(l10n.startLearningByCreatingTopics, 'Comience a aprender creando temas y preguntas');
        expect(l10n.addTopic, 'Agregar Tema');
        expect(l10n.lesson, 'Lección');
        expect(l10n.practiceProgress, 'Progreso de la Práctica');
        expect(l10n.overallScore, 'Puntuación General');
        expect(l10n.keepPracticing, '¡Siga practicando para mejorar su puntuación!');
        expect(l10n.selectFormat, 'Seleccione el formato de pregunta:');
      });

      test('session tracker section', () {
        expect(l10n.studySessionTracker, 'Rastreador de Sesiones de Estudio');
        expect(l10n.start, 'Iniciar');
        expect(l10n.end, 'Finalizar');
        expect(l10n.sessionComplete, 'Sesión Completada');
        expect(l10n.howManyQuestions, '¿Cuántas preguntas respondió?');
        expect(l10n.questionsAnswered, 'Preguntas Respondidas');
        expect(l10n.skip, 'Omitir');
      });

      test('graph section', () {
        expect(l10n.graphRenderer, 'Renderizador de Gráficos');
        expect(l10n.refreshGraph, 'Actualizar gráfico');
        expect(l10n.validateGraphType, 'Validar tipo de gráfico');
        expect(l10n.uploadData, 'Subir Datos');
        expect(l10n.uploadDataFile, 'Subir Archivo de Datos');
        expect(l10n.orPasteDataDirectly, 'O pegue los datos directamente:');
        expect(l10n.pasteDataHint, 'Pegue datos separados por comas...');
        expect(l10n.graphTypeDetection, 'Detección de Tipo de Gráfico');
        expect(l10n.autoDetectFromData, 'Detección automática desde datos:');
        expect(l10n.lineGraph, 'Gráfico de Líneas');
        expect(l10n.barChart, 'Gráfico de Barras');
        expect(l10n.scatterPlot, 'Diagrama de Dispersión');
        expect(l10n.pieChart, 'Gráfico Circular');
        expect(l10n.llmValidation, 'Validación con LLM');
        expect(l10n.useLlmToValidateGraph, 'Usar LLM para validar el gráfico:');
        expect(l10n.describeWhatYouSee, 'Describa lo que ve en el gráfico...');
        expect(l10n.validateWithLlm, 'Validar con LLM');
        expect(l10n.validating, 'Validando...');
        expect(l10n.renderedGraph, 'Gráfico Renderizado');
        expect(l10n.noDataUploaded, 'No hay datos subidos');
        expect(l10n.uploadOrPasteData, 'Sube o pegue datos para visualizar');
        expect(l10n.selectGraphType, 'Seleccione un tipo de gráfico para visualizar');
        expect(l10n.uploadDataFileDialog, 'Subir Archivo de Datos');
        expect(l10n.fileUploadImplemented, 'La funcionalidad de carga de archivos se implementaría aquí.');
        expect(l10n.graphValidation, 'Validación de Gráfico');
        expect(l10n.considerUsingPieChart, 'Considere usar un Gráfico Circular para conjuntos pequeños de datos');
        expect(l10n.considerUsingBarChart, 'Considere usar un Gráfico de Barras para conjuntos grandes de datos');
        expect(l10n.graphTypeMatchesData, 'El tipo de gráfico coincide con la estructura de datos');
        expect(l10n.graphRefreshed, 'Gráfico actualizado');
        expect(l10n.pleaseSelectGraphType, 'Por favor seleccione un tipo de gráfico primero');
        expect(l10n.validationComplete, 'Validación completada');
        expect(l10n.graphTypeDetectionError, 'La detección del tipo de gráfico falló');
      });

      test('lesson scheduler section', () {
        expect(l10n.lessonScheduler, 'Planificador de Lecciones');
        expect(l10n.upcomingLessons, 'Próximas Lecciones');
        expect(l10n.selectSubjectLabel, 'Seleccionar Materia');
        expect(l10n.generateQuestionTypes, 'Generar Tipos de Preguntas');
        expect(l10n.lessonProgress, 'Progreso de la Lección');
        expect(l10n.scheduleLesson, 'Programar Lección');
        expect(l10n.selectCalendarDate, 'Seleccione una fecha de calendario para la lección');
        expect(l10n.done, 'Hecho');
        expect(l10n.createNewLesson, 'Crear Nueva Lección');
        expect(l10n.editExistingLesson, 'Editar Lección Existente');
        expect(l10n.mcq, 'Opción Múltiple');
        expect(l10n.inputLabel, 'Entrada');
        expect(l10n.graphLabel, 'Gráfico');
      });

      test('quick guide section', () {
        expect(l10n.quickGuideHelp, 'Ayuda de Guía Rápida');
        expect(l10n.help, 'Ayuda');
        expect(l10n.quickGuideIsThinking, 'Guía Rápida está pensando...');
        expect(l10n.suggestedPrompts, 'Sugerencias');
        expect(l10n.askAnything, 'Pregunte lo que sea...');
        expect(l10n.sendMessage, 'Enviar mensaje');
        expect(l10n.messageInputHint, 'Escriba su pregunta aquí');
        expect(l10n.quickGuideHelpTitle, 'Ayuda de Guía Rápida');
        expect(l10n.gotIt, 'Entendido');
      });

      test('answer section', () {
        expect(l10n.addAnswerBeforeSubmitting, 'Agregue una respuesta antes de enviar.');
        expect(l10n.nextQuestion, 'Siguiente Pregunta');
        expect(l10n.typeYourAnswerHere, 'Escriba su respuesta aquí...');
        expect(l10n.writeYourEssayAnswer, 'Escriba su respuesta de ensayo...');
        expect(l10n.questionTypeNotSupported, 'Este tipo de pregunta aún no es compatible en esta vista.');
        expect(l10n.multipleChoice, 'Opción Múltiple');
        expect(l10n.multipleSelect, 'Selección Múltiple');
        expect(l10n.textAnswer, 'Respuesta de Texto');
        expect(l10n.math, 'Matemáticas');
        expect(l10n.essay, 'Ensayo');
        expect(l10n.diagram, 'Diagrama');
        expect(l10n.graphQuestion, 'Gráfico');
        expect(l10n.stepByStep, 'Paso a Paso');
        expect(l10n.easy, 'Fácil');
        expect(l10n.hard, 'Difícil');
        expect(l10n.selectAsAnswer, 'Seleccionar como respuesta');
        expect(l10n.selectedRightOption, 'Opción correcta seleccionada');
        expect(l10n.tryAgain, 'Intente de nuevo');
      });

      test('canvas section', () {
        expect(l10n.drawHere, 'Dibuje aquí...');
        expect(l10n.undoLastStroke, 'Deshacer último trazo');
        expect(l10n.clearAllDrawings, 'Borrar todos los dibujos');
        expect(l10n.canvasIsEmpty, 'El lienzo está vacío');
        expect(l10n.saveDrawing, 'Guardar Dibujo');
        expect(l10n.drawingSaved, 'Dibujo guardado.');
        expect(l10n.failedToSaveDrawing, 'Error al guardar el dibujo. Reintente.');
        expect(l10n.drawingCanvas, 'Lienzo de dibujo');
        expect(l10n.drawYourAnswer, 'Dibuje su respuesta en el lienzo usando su dedo o lápiz');
      });

      test('API configuration section', () {
        expect(l10n.apiConfiguration, 'Configuración de API');
        expect(l10n.configureApiKeys, 'Configurar Claves API');
        expect(l10n.configureApiKeysDescription, 'Ingrese sus credenciales de OpenRouter a continuación. Se utilizan para impulsar las funciones de IA.');
        expect(l10n.openRouterApiKey, 'Clave API de OpenRouter');
        expect(l10n.apiBaseUrl, 'URL Base de la API');
        expect(l10n.apiKeyHint, 'sk-or-v1-...');
        expect(l10n.apiBaseUrlHint, 'https://openrouter.ai/api/v1');
        expect(l10n.apiKeyDescription, 'Requerido para la generación de contenido con LLM. Obtenga su clave en https://openrouter.ai/keys');
        expect(l10n.apiBaseUrlDescription, 'La URL del endpoint para el servicio de IA');
        expect(l10n.saveApiKeys, 'Guardar Claves API');
        expect(l10n.apiKeyCannotBeEmpty, 'La clave API no puede estar vacía');
        expect(l10n.apiKeysSavedSuccessfully, 'Claves API guardadas exitosamente');
        expect(l10n.unableToSaveApiConfig, 'No se puede guardar la configuración de API. Intente de nuevo.');
      });

      test('session history section', () {
        expect(l10n.currentSession, 'Sesión Actual');
        expect(l10n.noActiveSession, 'Sin Sesión Activa');
        expect(l10n.tapStartToBegin, 'Toque Iniciar para comenzar a rastrear');
        expect(l10n.recentSessions, 'Sesiones Recientes');
        expect(l10n.viewAll, 'Ver Todo');
        expect(l10n.noSessionsYet, 'Sin sesiones todavía');
        expect(l10n.startYourFirstSession, '¡Comience su primera sesión!');
        expect(l10n.filterByDate, 'Filtrar por Fecha');
        expect(l10n.filterBySubject, 'Filtrar por Materia');
        expect(l10n.clearFilters, 'Limpiar filtros');
        expect(l10n.clearFilterLabel, 'Limpiar');
        expect(l10n.totalTime, 'Tiempo Total');
        expect(l10n.average, 'Promedio');
        expect(l10n.noSessionsFoundForFilters, 'No se encontraron sesiones para los filtros seleccionados');
        expect(l10n.tryAdjustingFilters, 'Intente ajustar sus filtros');
        expect(l10n.startStudyingToTrack, 'Comience a estudiar para rastrear su progreso');
        expect(l10n.sessionDeleted, 'Sesión eliminada');
        expect(l10n.undo, 'Deshacer');
        expect(l10n.deleteSession, 'Eliminar Sesión');
        expect(l10n.deleteSessionConfirmation, '¿Está seguro de que desea eliminar esta sesión?');
        expect(l10n.noQuestions, 'Sin preguntas');
        expect(l10n.selectDateToFilter, 'Seleccione una fecha para filtrar sesiones');
        expect(l10n.filterBySubjectTitle, 'Filtrar por Materia');
        expect(l10n.sessionHistory, 'Historial de Sesiones');
      });
    });

    group('Parameterized Methods', () {
      test('topicLabel', () {
        expect(l10n.topicLabel(1), 'Tema 1');
        expect(l10n.topicLabel(5), 'Tema 5');
        expect(l10n.topicLabel(100), 'Tema 100');
      });

      test('sessionDurationMinutes', () {
        expect(l10n.sessionDurationMinutes(1), '1 min de sesión');
        expect(l10n.sessionDurationMinutes(30), '30 min de sesión');
        expect(l10n.sessionDurationMinutes(60), '60 min de sesión');
      });

      test('generatedPlanOverDays', () {
        expect(l10n.generatedPlanOverDays('Matemáticas', 7, 14), 'Plan generado para Matemáticas en 7 días (14 horas totales)');
        expect(l10n.generatedPlanOverDays('Física', 30, 60), 'Plan generado para Física en 30 días (60 horas totales)');
      });

      group('overDaysPlural', () {
        test('zero', () => expect(l10n.overDaysPlural(0), 'en 0 días'));
        test('one', () => expect(l10n.overDaysPlural(1), 'en 1 día'));
        test('other', () {
          expect(l10n.overDaysPlural(2), 'en 2 días');
          expect(l10n.overDaysPlural(7), 'en 7 días');
        });
      });

      group('totalHoursPlural', () {
        test('one', () => expect(l10n.totalHoursPlural(1), '1 hora total'));
        test('other', () {
          expect(l10n.totalHoursPlural(2), '2 horas totales');
          expect(l10n.totalHoursPlural(10), '10 horas totales');
        });
      });

      group('durationDays', () {
        test('one', () => expect(l10n.durationDays(1), '1d'));
        test('other', () {
          expect(l10n.durationDays(2), '2d');
          expect(l10n.durationDays(7), '7d');
        });
      });

      group('durationHours', () {
        test('one', () => expect(l10n.durationHours(1), '1h'));
        test('other', () {
          expect(l10n.durationHours(2), '2h');
          expect(l10n.durationHours(5), '5h');
        });
      });

      group('durationMinutes', () {
        test('one', () => expect(l10n.durationMinutes(1), '1min'));
        test('other', () {
          expect(l10n.durationMinutes(2), '2min');
          expect(l10n.durationMinutes(30), '30min');
        });
      });

      group('durationSeconds', () {
        test('one', () => expect(l10n.durationSeconds(1), '1s'));
        test('other', () {
          expect(l10n.durationSeconds(2), '2s');
          expect(l10n.durationSeconds(30), '30s');
        });
      });

      test('randomQuestions', () {
        expect(l10n.randomQuestions(5), '5 preguntas aleatorias');
        expect(l10n.randomQuestions(1), '1 pregunta aleatoria');
      });

      test('yourAnswerCharacters', () {
        expect(l10n.yourAnswerCharacters(100), 'Su Respuesta (100 caracteres)');
        expect(l10n.yourAnswerCharacters(500), 'Su Respuesta (500 caracteres)');
      });

      test('dueQuestionsCount', () {
        expect(l10n.dueQuestionsCount(3), '3 pendientes');
        expect(l10n.dueQuestionsCount(0), '0 pendientes');
      });

      test('secondsValue', () {
        expect(l10n.secondsValue(30), '30 segundos');
        expect(l10n.secondsValue(60), '60 segundos');
      });

      test('minutesValue', () {
        expect(l10n.minutesValue(15), '15 minutos');
        expect(l10n.minutesValue(60), '60 minutos');
      });

      test('sessionsCount', () {
        expect(l10n.sessionsCount(5), '5 sesiones');
        expect(l10n.sessionsCount(1), '1 sesión');
      });

      test('errorSavingProfile', () {
        expect(l10n.errorSavingProfile('timeout'), 'Error al guardar el perfil: timeout');
      });

      test('selectAvatar', () {
        expect(l10n.selectAvatar('robot'), 'Seleccionar avatar robot');
      });

      test('questionsCount', () {
        expect(l10n.questionsCount(5), 'Preguntas: 5');
        expect(l10n.questionsCount(0), 'Preguntas: 0');
      });

      test('practiceQuestionsFrom', () {
        expect(l10n.practiceQuestionsFrom('Matemáticas'), 'Practica preguntas de Matemáticas');
      });

      test('sessionNumber', () {
        expect(l10n.sessionNumber(1), 'Sesión 1');
        expect(l10n.sessionNumber(5), 'Sesión 5');
      });

      test('graphVisualization', () {
        expect(l10n.graphVisualization('Líneas'), 'Visualización de Líneas');
      });

      test('dataPointsCount', () {
        expect(l10n.dataPointsCount(10), 'Puntos de datos: 10');
      });

      test('graphTypeSetTo', () {
        expect(l10n.graphTypeSetTo('Líneas'), 'Tipo de gráfico cambiado a Líneas');
      });

      test('typeLabel', () {
        expect(l10n.typeLabel('Líneas'), 'Tipo: Líneas');
      });

      test('validationFailed', () {
        expect(l10n.validationFailed('error'), 'Validación fallida: error');
      });

      test('percentComplete', () {
        expect(l10n.percentComplete(50, 5, 10), '50% Completado: 5/10 preguntas generadas');
        expect(l10n.percentComplete(100, 10, 10), '100% Completado: 10/10 preguntas generadas');
      });

      test('difficultyLabel', () {
        expect(l10n.difficultyLabel('Fácil'), 'Dificultad: Fácil');
      });

      test('drawingWithStrokes', () {
        expect(l10n.drawingWithStrokes(1), 'Dibujando con 1 trazo');
        expect(l10n.drawingWithStrokes(3), 'Dibujando con 3 trazos');
      });

      test('ofLabel', () {
        expect(l10n.ofLabel(1, 10), '1 de 10');
      });

      test('questionsCountLabel', () {
        expect(l10n.questionsCountLabel(5), '5 preguntas');
      });

      test('correctOf', () {
        expect(l10n.correctOf(3, 5), 'Correctas: 3/5');
      });

      test('errorCreatingSubject', () {
        expect(l10n.errorCreatingSubject('duplicate'), 'Error al crear la materia: duplicate');
      });

      test('errorSavingSubject', () {
        expect(l10n.errorSavingSubject('timeout'), 'Error al guardar la materia: timeout');
      });

      test('failedToDeleteSession', () {
        expect(l10n.failedToDeleteSession('error'), 'Error al eliminar la sesión: error');
      });

      test('failedToSaveSession', () {
        expect(l10n.failedToSaveSession('error'), 'Error al guardar la sesión: error');
      });
    });
  });

  group('Delegate Behavior', () {
    testWidgets('delegate loads English localization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);
              expect(localizations, isNotNull);
              expect(localizations!.localeName, 'en');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('delegate loads Spanish localization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);
              expect(localizations, isNotNull);
              expect(localizations!.localeName, 'es');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    test('delegate does not reload unnecessarily', () async {
      final delegate = AppLocalizations.delegate;
      final locale = const Locale('en');
      final result1 = await delegate.load(locale);
      final result2 = await delegate.load(locale);
      expect(result1.localeName, result2.localeName);
    });

    test('delegate isSupported returns true for en', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    });

    test('delegate isSupported returns true for es', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('es')), isTrue);
    });

    test('delegate isSupported returns true for en with region', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('en', 'US')), isTrue);
    });

    test('delegate isSupported returns true for es with region', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('es', 'MX')), isTrue);
    });

    test('delegate isSupported returns false for unsupported locale', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
      expect(AppLocalizations.delegate.isSupported(const Locale('de')), isFalse);
      expect(AppLocalizations.delegate.isSupported(const Locale('zh')), isFalse);
    });

    test('delegate shouldReload returns false', () {
      expect(AppLocalizations.delegate.shouldReload(AppLocalizations.delegate), isFalse);
    });

    test('delegate load returns English for en locale', () async {
      final result = await AppLocalizations.delegate.load(const Locale('en'));
      expect(result, isA<AppLocalizationsEn>());
    });

    test('delegate load returns Spanish for es locale', () async {
      final result = await AppLocalizations.delegate.load(const Locale('es'));
      expect(result, isA<AppLocalizationsEs>());
    });

    test('delegate type is not null', () {
      expect(AppLocalizations.delegate.type, isNotNull);
    });
  });

  group('lookupAppLocalizations', () {
    test('returns AppLocalizationsEn for en locale', () {
      final result = lookupAppLocalizations(const Locale('en'));
      expect(result, isA<AppLocalizationsEn>());
      expect(result.localeName, 'en');
    });

    test('returns AppLocalizationsEs for es locale', () {
      final result = lookupAppLocalizations(const Locale('es'));
      expect(result, isA<AppLocalizationsEs>());
      expect(result.localeName, 'es');
    });

    test('throws FlutterError for unsupported locale', () {
      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  group('Widget Integration Tests', () {
    testWidgets('localizations work in MaterialApp context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TestWidget(),
        ),
      );
    });

    testWidgets('localizations update when locale changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const TestWidget(),
        ),
      );

      final localizations1 = AppLocalizations.of(tester.element(find.byType(TestWidget)));
      expect(localizations1?.appTitle, 'StudyKing');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: const TestWidget(),
        ),
      );

      final localizations2 = AppLocalizations.of(tester.element(find.byType(TestWidget)));
      expect(localizations2?.appTitle, 'StudyKing');
    });

    testWidgets('localizations are accessible in nested widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                expect(localizations, isNotNull);
                return Column(
                  children: [
                    Text(localizations!.appTitle),
                    Text(localizations.settings),
                    Builder(
                      builder: (innerContext) {
                        final innerLoc = AppLocalizations.of(innerContext);
                        expect(innerLoc, isNotNull);
                        return Text(innerLoc!.practice);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('StudyKing'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('all bottom nav labels are accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Edge Cases', () {
    test('AppLocalizationsEn instances are independent', () {
      final en1 = AppLocalizationsEn();
      final en2 = AppLocalizationsEn();
      expect(identical(en1, en2), isFalse);
    });

    test('AppLocalizationsEs instances are independent', () {
      final es1 = AppLocalizationsEs();
      final es2 = AppLocalizationsEs();
      expect(identical(es1, es2), isFalse);
    });

    test('AppLocalizationsEn can be compared', () {
      final en1 = AppLocalizationsEn();
      expect(en1.hashCode, isNotNull);
    });

    test('supported locales are equal for same language code', () {
      const en1 = Locale('en');
      const en2 = Locale('en');
      expect(en1.languageCode, en2.languageCode);
    });

    testWidgets('localizations work without specifying locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              expect(l10n, isNotNull);
              return Text(l10n!.appTitle);
            },
          ),
        ),
      );
      expect(find.text('StudyKing'), findsOneWidget);
    });

    testWidgets('localizations with region code en_US', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              expect(l10n, isNotNull);
              return Text(l10n!.localeName);
            },
          ),
        ),
      );
      expect(find.text('en'), findsOneWidget);
    });

    testWidgets('localizations with Spanish region code es_MX', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es', 'MX'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              expect(l10n, isNotNull);
              return Text(l10n!.localeName);
            },
          ),
        ),
      );
      expect(find.text('es'), findsOneWidget);
    });

    test('delegate hashcode is consistent', () {
      final d1 = AppLocalizations.delegate;
      final d2 = AppLocalizations.delegate;
      expect(d1.hashCode, d2.hashCode);
    });
  });

  group('Locale-specific Plural Rules', () {
    group('English plurals', () {
      late AppLocalizationsEn l10n;
      setUp(() => l10n = AppLocalizationsEn());

      test('overDaysPlural handles all English plural forms', () {
        expect(l10n.overDaysPlural(0), 'over no days');
        expect(l10n.overDaysPlural(1), 'over 1 day');
        expect(l10n.overDaysPlural(2), 'over 2 days');
        expect(l10n.overDaysPlural(100), 'over 100 days');
      });

      test('totalHoursPlural handles all English plural forms', () {
        expect(l10n.totalHoursPlural(1), '1 total hour');
        expect(l10n.totalHoursPlural(2), '2 total hours');
      });

      test('durationDays handles all English plural forms', () {
        expect(l10n.durationDays(1), '1d');
        expect(l10n.durationDays(2), '2d');
      });

      test('durationHours handles all English plural forms', () {
        expect(l10n.durationHours(1), '1h');
        expect(l10n.durationHours(2), '2h');
      });

      test('durationMinutes handles all English plural forms', () {
        expect(l10n.durationMinutes(1), '1m');
        expect(l10n.durationMinutes(2), '2m');
      });

      test('durationSeconds handles all English plural forms', () {
        expect(l10n.durationSeconds(1), '1s');
        expect(l10n.durationSeconds(2), '2s');
      });
    });

    group('Spanish plurals', () {
      late AppLocalizationsEs l10n;
      setUp(() => l10n = AppLocalizationsEs());

      test('overDaysPlural handles all Spanish plural forms', () {
        expect(l10n.overDaysPlural(0), 'en 0 días');
        expect(l10n.overDaysPlural(1), 'en 1 día');
        expect(l10n.overDaysPlural(2), 'en 2 días');
      });

      test('totalHoursPlural handles all Spanish plural forms', () {
        expect(l10n.totalHoursPlural(1), '1 hora total');
        expect(l10n.totalHoursPlural(2), '2 horas totales');
      });
    });
  });
}

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Text(localizations?.appTitle ?? '');
  }
}
