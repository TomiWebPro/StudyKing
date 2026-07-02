import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'StudyKing'**
  String get appTitle;

  /// Bottom navigation label for subjects
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// Bottom navigation label for practice
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// Bottom navigation label for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// App bar title for planner screen
  ///
  /// In en, this message translates to:
  /// **'Study Planner'**
  String get studyPlanner;

  /// Title for study plan creation section
  ///
  /// In en, this message translates to:
  /// **'Create Study Plan'**
  String get createStudyPlan;

  /// Label for course/subject text field
  ///
  /// In en, this message translates to:
  /// **'Course/Subject'**
  String get courseSubject;

  /// Hint text for course input
  ///
  /// In en, this message translates to:
  /// **'e.g., Organic Chemistry'**
  String get courseHint;

  /// Label for days input
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Label for hours per day input
  ///
  /// In en, this message translates to:
  /// **'Hours/Day'**
  String get hoursPerDay;

  /// Button label to generate study plan
  ///
  /// In en, this message translates to:
  /// **'Generate Plan'**
  String get generatePlan;

  /// Button label when plan is being generated
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// Loading message while generating progress report
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get generatingReport;

  /// Title for the generated study schedule
  ///
  /// In en, this message translates to:
  /// **'Your Study Schedule'**
  String get yourStudySchedule;

  /// Label for a topic with number
  ///
  /// In en, this message translates to:
  /// **'Topic {number}'**
  String topicLabel(int number);

  /// Session duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min session'**
  String sessionDurationMinutes(int minutes);

  /// Error message when form fields are invalid
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields correctly'**
  String get fillAllFieldsCorrectly;

  /// Snackbar message when plan is generated
  ///
  /// In en, this message translates to:
  /// **'Generated plan for {course} over {days} days ({totalHours} total hours)'**
  String generatedPlanOverDays(String course, int days, int totalHours);

  /// Pluralized phrase for days
  ///
  /// In en, this message translates to:
  /// **'over {count, plural, =0{no days} =1{1 day} other{{count} days}}'**
  String overDaysPlural(int count);

  /// Pluralized phrase for total hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 total hour} other{{count} total hours}}'**
  String totalHoursPlural(int count);

  /// Label for today's date
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for yesterday's date
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Fallback label when date is null
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Duration in days abbreviated
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1d} other{{count}d}}'**
  String durationDays(int count);

  /// Duration in hours abbreviated
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1h} other{{count}h}}'**
  String durationHours(int count);

  /// Duration in minutes abbreviated
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1m} other{{count}m}}'**
  String durationMinutes(int count);

  /// Duration in seconds abbreviated
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1s} other{{count}s}}'**
  String durationSeconds(int count);

  /// AppBar title for practice screen
  ///
  /// In en, this message translates to:
  /// **'Practice Mode'**
  String get practiceMode;

  /// Tooltip for practice options button
  ///
  /// In en, this message translates to:
  /// **'Practice Options'**
  String get practiceOptions;

  /// FAB label when no subjects available
  ///
  /// In en, this message translates to:
  /// **'No Subjects'**
  String get noSubjects;

  /// Empty state heading for practice screen
  ///
  /// In en, this message translates to:
  /// **'No Practice Sessions Yet'**
  String get noPracticeSessionsYet;

  /// Empty state body text for practice screen
  ///
  /// In en, this message translates to:
  /// **'Add subjects and questions to start practicing'**
  String get addSubjectsAndQuestionsToStartPracticing;

  /// Snackbar message directing to subjects tab
  ///
  /// In en, this message translates to:
  /// **'Add subjects from the Subjects tab'**
  String get addSubjectsFromSubjectsTab;

  /// Button label to add a subject
  ///
  /// In en, this message translates to:
  /// **'Add Subject'**
  String get addSubject;

  /// Section heading for practice modes
  ///
  /// In en, this message translates to:
  /// **'Practice Modes'**
  String get practiceModes;

  /// Quick practice mode title
  ///
  /// In en, this message translates to:
  /// **'Quick Practice'**
  String get quickPractice;

  /// Subtitle for quick practice mode
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 random question} other{{count} random questions}}'**
  String randomQuestions(int count);

  /// Label for unavailable features
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Spaced repetition mode title
  ///
  /// In en, this message translates to:
  /// **'Spaced Repetition'**
  String get spacedRepetition;

  /// Topic focus mode title
  ///
  /// In en, this message translates to:
  /// **'Topic Focus'**
  String get topicFocus;

  /// Subtitle for topic focus mode
  ///
  /// In en, this message translates to:
  /// **'Practice specific topics'**
  String get practiceSpecificTopics;

  /// Weak areas mode title
  ///
  /// In en, this message translates to:
  /// **'Weak Areas'**
  String get weakAreas;

  /// Subtitle for weak areas mode
  ///
  /// In en, this message translates to:
  /// **'Focus on mistakes'**
  String get focusOnMistakes;

  /// Section heading for subjects
  ///
  /// In en, this message translates to:
  /// **'Your Subjects'**
  String get yourSubjects;

  /// Subtitle for single subject card
  ///
  /// In en, this message translates to:
  /// **'Ready for practice'**
  String get readyForPractice;

  /// Label showing practice is available
  ///
  /// In en, this message translates to:
  /// **'Practice available'**
  String get practiceAvailable;

  /// Title for subject selector bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Select Subject'**
  String get selectSubject;

  /// Title for practice mode bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Practice Mode'**
  String get practiceModeTitle;

  /// Auto select option title
  ///
  /// In en, this message translates to:
  /// **'Auto Select'**
  String get autoSelect;

  /// Auto select option subtitle
  ///
  /// In en, this message translates to:
  /// **'AI picks optimal questions'**
  String get aiPicksOptimalQuestions;

  /// Title for choose subject section
  ///
  /// In en, this message translates to:
  /// **'Choose Subject'**
  String get chooseSubject;

  /// Fallback for missing subject code
  ///
  /// In en, this message translates to:
  /// **'No code'**
  String get noCode;

  /// Snackbar message for unavailable topic selection
  ///
  /// In en, this message translates to:
  /// **'Topic selection coming soon!'**
  String get topicSelectionComingSoon;

  /// Message shown when the user has no weak topics
  ///
  /// In en, this message translates to:
  /// **'No weak areas found. Keep up the great work!'**
  String get noWeakAreasFound;

  /// Title for at-risk practice mode
  ///
  /// In en, this message translates to:
  /// **'At-Risk Questions'**
  String get atRiskQuestions;

  /// Description for at-risk practice mode
  ///
  /// In en, this message translates to:
  /// **'Practice questions with lowest mastery scores'**
  String get atRiskQuestionsDescription;

  /// Message when no questions found for weak areas
  ///
  /// In en, this message translates to:
  /// **'No questions available for your weak areas.'**
  String get noWeakAreasQuestions;

  /// Dialog title when no questions available
  ///
  /// In en, this message translates to:
  /// **'No Questions Available'**
  String get noQuestionsAvailable;

  /// Dialog content when no questions available
  ///
  /// In en, this message translates to:
  /// **'There are no questions for the selected subject/topic. Start creating questions!'**
  String get noQuestionsForSelectedSubject;

  /// Label for time stat
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Label for score stat
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// Label for correct answers stat
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// Label for answer input field
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get yourAnswer;

  /// Label for essay answer input with character count
  ///
  /// In en, this message translates to:
  /// **'Your Answer ({count} characters)'**
  String yourAnswerCharacters(int count);

  /// Button label to submit answer
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get submitAnswer;

  /// Feedback message for correct answer
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correctFeedback;

  /// Feedback message for incorrect answer
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrectFeedback;

  /// Button label for previous question
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Button label for next question
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// AppBar title for results screen
  ///
  /// In en, this message translates to:
  /// **'Session Results'**
  String get sessionResults;

  /// Heading for completed practice session
  ///
  /// In en, this message translates to:
  /// **'Practice Complete!'**
  String get practiceComplete;

  /// Label for total questions stat
  ///
  /// In en, this message translates to:
  /// **'Total Questions'**
  String get totalQuestions;

  /// Label for correct answers stat in results
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get correctAnswers;

  /// Label for accuracy stat
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// Heading for exam configuration screen
  ///
  /// In en, this message translates to:
  /// **'Exam Configuration'**
  String get examConfiguration;

  /// Button label to start an exam
  ///
  /// In en, this message translates to:
  /// **'Start Exam'**
  String get startExam;

  /// Label for exam duration selector
  ///
  /// In en, this message translates to:
  /// **'Exam Duration'**
  String get examDuration;

  /// Label for number of questions selector
  ///
  /// In en, this message translates to:
  /// **'Number of Questions'**
  String get numberOfQuestions;

  /// Label for number of incorrect answers in results
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrectLabel;

  /// Label for number of skipped questions in results
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skippedLabel;

  /// Message shown when exam is auto-submitted due to time
  ///
  /// In en, this message translates to:
  /// **'Exam was auto-submitted when time ran out.'**
  String get examAutoSubmitted;

  /// Heading for topic breakdown section in results
  ///
  /// In en, this message translates to:
  /// **'Topic Breakdown'**
  String get topicBreakdown;

  /// Heading for mastery change/delta section in session results
  ///
  /// In en, this message translates to:
  /// **'Mastery Change'**
  String get masteryDelta;

  /// Dialog text shown when starting practice
  ///
  /// In en, this message translates to:
  /// **'Starting {mode}...'**
  String startingPractice(String mode);

  /// Button label to navigate back to practice
  ///
  /// In en, this message translates to:
  /// **'Back to Practice'**
  String get backToPractice;

  /// Semantic hint for swipe to delete gesture
  ///
  /// In en, this message translates to:
  /// **'Swipe to delete'**
  String get swipeToDelete;

  /// Validation error for non-positive numeric input
  ///
  /// In en, this message translates to:
  /// **'Value must be positive'**
  String get valueMustBePositive;

  /// Validation error when correct answers exceed total questions
  ///
  /// In en, this message translates to:
  /// **'Correct answers cannot exceed total questions'**
  String get correctExceedsQuestions;

  /// Button label to restart practice
  ///
  /// In en, this message translates to:
  /// **'Practice Again'**
  String get practiceAgain;

  /// Message when no questions are due for review
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// Subtitle when no questions are due for review
  ///
  /// In en, this message translates to:
  /// **'No reviews scheduled.'**
  String get noReviewsScheduled;

  /// Badge showing number of due questions
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 due} other{{count} due}}'**
  String dueQuestionsCount(int count);

  /// Button to start reviewing due questions
  ///
  /// In en, this message translates to:
  /// **'Review due questions'**
  String get reviewDueQuestions;

  /// Title for topic selector
  ///
  /// In en, this message translates to:
  /// **'Select Topic'**
  String get selectTopic;

  /// Message when no topics are available for a subject
  ///
  /// In en, this message translates to:
  /// **'No topics available'**
  String get noTopicsAvailable;

  /// Subtitle showing questions due for a subject
  ///
  /// In en, this message translates to:
  /// **'questions due for review'**
  String get questionsDueForReview;

  /// Title for spaced repetition practice session
  ///
  /// In en, this message translates to:
  /// **'Spaced Repetition'**
  String get spacedRepetitionMode;

  /// Color label for blue
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// Color label for green
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// Color label for orange
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// Color label for purple
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// Color label for pink
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// Color label for cyan
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get colorCyan;

  /// Color label for amber
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// Color label for deep orange
  ///
  /// In en, this message translates to:
  /// **'Deep Orange'**
  String get colorDeepOrange;

  /// Color label for blue grey
  ///
  /// In en, this message translates to:
  /// **'Blue Grey'**
  String get colorBlueGrey;

  /// Title for profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Error message when name field is empty
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// Snackbar message when profile is saved
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileSavedSuccessfully;

  /// Error message when saving profile fails
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {error}'**
  String errorSavingProfile(String error);

  /// Title for avatar picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseAvatar;

  /// Button label to confirm an action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Semantic label for avatar selection
  ///
  /// In en, this message translates to:
  /// **'Select avatar {iconKey}'**
  String selectAvatar(String iconKey);

  /// Label for full name input field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Hint text for name input field
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// Label for learning goal input field
  ///
  /// In en, this message translates to:
  /// **'Learning Goal'**
  String get learningGoal;

  /// Hint text for learning goal input field
  ///
  /// In en, this message translates to:
  /// **'e.g., Final Exams, Certifications'**
  String get learningGoalHint;

  /// Section title for account information
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// Label for language selector
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language option: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Language option: Spanish
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// Label for notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Warning text about account deletion
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove all study data'**
  String get deleteAccountWarning;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title for delete account confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Confirmation text for account deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your study data.'**
  String get deleteAccountConfirmation;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Section title for user management in settings
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// Tile title for current user in settings
  ///
  /// In en, this message translates to:
  /// **'Current User'**
  String get currentUser;

  /// Subtitle for current user settings tile
  ///
  /// In en, this message translates to:
  /// **'Manage your profile'**
  String get manageYourProfile;

  /// Section title for quick access in settings
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// Title for quick guide screen
  ///
  /// In en, this message translates to:
  /// **'Quick Guide'**
  String get quickGuide;

  /// Subtitle for quick guide settings tile
  ///
  /// In en, this message translates to:
  /// **'AI-powered study assistant'**
  String get aiPoweredStudyAssistant;

  /// Section title for appearance settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Tile title for theme selection
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// System default theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Tile title for font size setting
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// Small font size label
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// Medium font size label
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontSizeMedium;

  /// Large font size label
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// Button label to confirm leaving despite active timer
  ///
  /// In en, this message translates to:
  /// **'Leave anyway'**
  String get leaveAnyway;

  /// Extra large font size label
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get extraLarge;

  /// Section title for AI configuration in settings
  ///
  /// In en, this message translates to:
  /// **'AI Configuration'**
  String get aiConfiguration;

  /// Tile title for API keys
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get apiKeys;

  /// Status label when API key is configured
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// Status label when API key is not configured
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// Tile title for AI model selection
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get aiModel;

  /// Default label when no AI model is selected
  ///
  /// In en, this message translates to:
  /// **'Select a model from API'**
  String get selectModelFromApi;

  /// Tile title for request timeout setting
  ///
  /// In en, this message translates to:
  /// **'Request Timeout'**
  String get requestTimeout;

  /// Duration in seconds
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 second} other{{count} seconds}}'**
  String secondsValue(int count);

  /// Section title for study preferences
  ///
  /// In en, this message translates to:
  /// **'Study Preferences'**
  String get studyPreferences;

  /// Title for study reminders toggle
  ///
  /// In en, this message translates to:
  /// **'Study Reminders'**
  String get studyReminders;

  /// Subtitle for study reminders toggle
  ///
  /// In en, this message translates to:
  /// **'Enable notification alerts'**
  String get enableNotificationAlerts;

  /// Tile title for session duration setting
  ///
  /// In en, this message translates to:
  /// **'Session Duration'**
  String get sessionDuration;

  /// Duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 minute} other{{count} minutes}}'**
  String minutesValue(int count);

  /// Section title for study analytics
  ///
  /// In en, this message translates to:
  /// **'Study Analytics'**
  String get studyAnalytics;

  /// Tile title for total study sessions
  ///
  /// In en, this message translates to:
  /// **'Total Study Sessions'**
  String get totalStudySessions;

  /// Number of sessions
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String sessionsCount(int count);

  /// Tile title for total study time
  ///
  /// In en, this message translates to:
  /// **'Total Study Time'**
  String get totalStudyTime;

  /// Section title for about section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// Tile title for about
  ///
  /// In en, this message translates to:
  /// **'About StudyKing'**
  String get aboutStudyKing;

  /// App version info
  ///
  /// In en, this message translates to:
  /// **'Version 0.1.0'**
  String get versionInfo;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Dialog title when API key is missing
  ///
  /// In en, this message translates to:
  /// **'API Key Required'**
  String get apiKeyRequired;

  /// Dialog content when API key is missing
  ///
  /// In en, this message translates to:
  /// **'Please configure your API key first.'**
  String get pleaseConfigureApiKey;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Error message when models fail to load
  ///
  /// In en, this message translates to:
  /// **'Unable to load models right now.'**
  String get unableToLoadModels;

  /// Hint text for model search field
  ///
  /// In en, this message translates to:
  /// **'Search models'**
  String get searchModels;

  /// Error message when model request times out
  ///
  /// In en, this message translates to:
  /// **'Model request timed out. Please try again.'**
  String get modelRequestTimedOut;

  /// Error message when models cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Unable to load models. Please try again.'**
  String get unableToLoadModelsTryAgain;

  /// Error message when mentor initialisation fails
  ///
  /// In en, this message translates to:
  /// **'Mentor initialization failed: {error}. Go to Settings to configure your AI provider, or retry.'**
  String mentorInitFailed(String error);

  /// Message shown when content pipeline is null
  ///
  /// In en, this message translates to:
  /// **'Content pipeline not available'**
  String get contentPipelineNotAvailable;

  /// Hint text in the input field when mentor init failed
  ///
  /// In en, this message translates to:
  /// **'Connectivity issue — configure AI provider in Settings'**
  String get mentorInitFailedHint;

  /// Error message when tutor initialisation fails
  ///
  /// In en, this message translates to:
  /// **'Tutor initialization failed: {error}. Go to Settings to configure your AI provider, or retry.'**
  String tutorInitFailed(String error);

  /// Button label to navigate back
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Accessibility hint for collapsible cards in dashboard
  ///
  /// In en, this message translates to:
  /// **'Tap to refresh this section'**
  String get tapToRefreshSection;

  /// Button label to retry an operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Confirmation text for sign out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// Label for sessions count
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsLabel;

  /// Tooltip for gap weeks with zero activity
  ///
  /// In en, this message translates to:
  /// **'No activity — you were away this week.'**
  String get noActivity;

  /// Label for questions count
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questionsLabel;

  /// Title for subjects list screen
  ///
  /// In en, this message translates to:
  /// **'My Subjects'**
  String get mySubjects;

  /// Title for add new subject screen
  ///
  /// In en, this message translates to:
  /// **'Add New Subject'**
  String get addNewSubject;

  /// Label for subject name field
  ///
  /// In en, this message translates to:
  /// **'Subject Name'**
  String get subjectName;

  /// Hint text for subject name
  ///
  /// In en, this message translates to:
  /// **'e.g., Physics'**
  String get subjectNameHint;

  /// Label for subject code field
  ///
  /// In en, this message translates to:
  /// **'Subject Code (Optional)'**
  String get subjectCodeOptional;

  /// Hint text for subject code
  ///
  /// In en, this message translates to:
  /// **'e.g., BIO-101'**
  String get subjectCodeHint;

  /// Label for theme color selection
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// Label for subject color picker
  ///
  /// In en, this message translates to:
  /// **'Subject Color'**
  String get subjectColor;

  /// Label for exam date picker
  ///
  /// In en, this message translates to:
  /// **'Exam Date (Optional)'**
  String get examDateOptional;

  /// Section title for backup & restore in settings
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// Semantic tooltip for backup and restore action
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestoreTooltip;

  /// Tile title for exporting backup
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// Tile subtitle for export backup
  ///
  /// In en, this message translates to:
  /// **'Export all your study data'**
  String get exportAllDataDescription;

  /// Tile title for importing backup
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// Tile subtitle for import backup
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file'**
  String get importFromFileDescription;

  /// Snackbar message when backup export succeeds
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get backupExported;

  /// Error message when backup export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup'**
  String get backupExportFailed;

  /// Title for import confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importConfirmTitle;

  /// Preview message before importing a backup with box and record counts
  ///
  /// In en, this message translates to:
  /// **'This backup contains {boxes,plural,=1{1 section} other{{boxes} sections}} with {records,plural,=1{1 record} other{{records} records}}. Existing data may be overwritten. Continue?'**
  String importPreview(int boxes, int records);

  /// Snackbar message when data restore succeeds
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get importSuccess;

  /// Error message when data restore fails
  ///
  /// In en, this message translates to:
  /// **'Failed to restore data'**
  String get importFailed;

  /// Error message when backup file format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get invalidBackupFile;

  /// Hint text for selecting a backup file
  ///
  /// In en, this message translates to:
  /// **'Select backup file'**
  String get selectBackupFile;

  /// Hint text for date picker button
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Button label to create a subject
  ///
  /// In en, this message translates to:
  /// **'Create Subject'**
  String get createSubject;

  /// Snackbar message when subject is created
  ///
  /// In en, this message translates to:
  /// **'Subject created successfully'**
  String get subjectCreatedSuccessfully;

  /// Prompt after creating a subject
  ///
  /// In en, this message translates to:
  /// **'Would you like to upload study material for {subject}?'**
  String uploadPrompt(String subject);

  /// Decline offer button
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get noThanks;

  /// Error message when creating subject fails
  ///
  /// In en, this message translates to:
  /// **'Error creating subject: {error}'**
  String errorCreatingSubject(String error);

  /// Validation error when subject name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject name'**
  String get pleaseEnterSubjectName;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// Hint text for description field
  ///
  /// In en, this message translates to:
  /// **'Brief description of the subject'**
  String get descriptionHint;

  /// Label for teacher name field
  ///
  /// In en, this message translates to:
  /// **'Teacher (Optional)'**
  String get teacherOptional;

  /// Hint text for teacher name
  ///
  /// In en, this message translates to:
  /// **'e.g., Dr. John Smith'**
  String get teacherHint;

  /// Label for syllabus field
  ///
  /// In en, this message translates to:
  /// **'Syllabus/Scope (Optional)'**
  String get syllabusScopeOptional;

  /// Hint text for syllabus field
  ///
  /// In en, this message translates to:
  /// **'Brief overview of the syllabus'**
  String get syllabusHint;

  /// Hint text for teacher name field in form
  ///
  /// In en, this message translates to:
  /// **'Enter teacher name'**
  String get teacherNameHint;

  /// Hint text for syllabus description in form
  ///
  /// In en, this message translates to:
  /// **'Enter syllabus description'**
  String get syllabusDescriptionHint;

  /// Empty state message for subjects list
  ///
  /// In en, this message translates to:
  /// **'No subjects yet'**
  String get noSubjectsYet;

  /// Empty state subtitle for subjects list
  ///
  /// In en, this message translates to:
  /// **'Add your first subject to begin studying'**
  String get addFirstSubject;

  /// Label for practice sessions in subject card
  ///
  /// In en, this message translates to:
  /// **'Practice sessions'**
  String get practiceSessions;

  /// Button label to start practice
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get startPractice;

  /// Empty state message for practice history
  ///
  /// In en, this message translates to:
  /// **'No practice history'**
  String get noPracticeHistory;

  /// Button label to view all sessions
  ///
  /// In en, this message translates to:
  /// **'View All Sessions'**
  String get viewAllSessions;

  /// Menu option to edit subject
  ///
  /// In en, this message translates to:
  /// **'Edit Subject'**
  String get editSubject;

  /// Menu option to delete subject
  ///
  /// In en, this message translates to:
  /// **'Delete Subject'**
  String get deleteSubject;

  /// Confirmation text for subject deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this subject? This will also delete all associated lessons and questions.'**
  String get deleteSubjectConfirmation;

  /// Title for session details dialog
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Label for date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Label for duration field
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Label for questions field
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// Tab label for lessons
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessonsTab;

  /// Tab label for practice
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceTab;

  /// Tab label for history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// Tab label for stats
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// Empty state message for lessons
  ///
  /// In en, this message translates to:
  /// **'No lessons yet'**
  String get noLessonsYet;

  /// Empty state subtitle for lessons
  ///
  /// In en, this message translates to:
  /// **'Start learning by creating topics and questions'**
  String get startLearningByCreatingTopics;

  /// Button label to add a topic
  ///
  /// In en, this message translates to:
  /// **'Add Topic'**
  String get addTopic;

  /// Default lesson label
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lesson;

  /// Label showing number of questions
  ///
  /// In en, this message translates to:
  /// **'Questions: {count}'**
  String questionsCount(int count);

  /// Subtitle for practice tab showing subject name
  ///
  /// In en, this message translates to:
  /// **'Practice questions from {subjectName}'**
  String practiceQuestionsFrom(String subjectName);

  /// Section header for practice progress
  ///
  /// In en, this message translates to:
  /// **'Practice Progress'**
  String get practiceProgress;

  /// Label for overall score
  ///
  /// In en, this message translates to:
  /// **'Overall Score'**
  String get overallScore;

  /// Encouragement message for practice
  ///
  /// In en, this message translates to:
  /// **'Keep practicing to improve your score!'**
  String get keepPracticing;

  /// Label for a session with number
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String sessionNumber(int number);

  /// Label for question format selection
  ///
  /// In en, this message translates to:
  /// **'Select question format:'**
  String get selectFormat;

  /// Title for session tracker screen
  ///
  /// In en, this message translates to:
  /// **'Study Session Tracker'**
  String get studySessionTracker;

  /// Start button label
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// End button label
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// Title for session end dialog
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get sessionComplete;

  /// Prompt for questions answered in session
  ///
  /// In en, this message translates to:
  /// **'How many questions did you answer?'**
  String get howManyQuestions;

  /// Label for questions answered field
  ///
  /// In en, this message translates to:
  /// **'Questions Answered'**
  String get questionsAnswered;

  /// Skip button label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Title for graph rendering page
  ///
  /// In en, this message translates to:
  /// **'Graph Renderer'**
  String get graphRenderer;

  /// Tooltip for refresh graph button
  ///
  /// In en, this message translates to:
  /// **'Refresh graph'**
  String get refreshGraph;

  /// Tooltip for validate graph type button
  ///
  /// In en, this message translates to:
  /// **'Validate graph type'**
  String get validateGraphType;

  /// Section title for data upload
  ///
  /// In en, this message translates to:
  /// **'Upload Data'**
  String get uploadData;

  /// Button label to upload data file
  ///
  /// In en, this message translates to:
  /// **'Upload Data File'**
  String get uploadDataFile;

  /// Label for manual data entry option
  ///
  /// In en, this message translates to:
  /// **'Or paste data directly:'**
  String get orPasteDataDirectly;

  /// Hint text for data input field
  ///
  /// In en, this message translates to:
  /// **'Paste comma-separated data...'**
  String get pasteDataHint;

  /// Section title for graph type detection
  ///
  /// In en, this message translates to:
  /// **'Graph Type Detection'**
  String get graphTypeDetection;

  /// Label for auto-detection option
  ///
  /// In en, this message translates to:
  /// **'Auto-detect from data:'**
  String get autoDetectFromData;

  /// Line graph type option
  ///
  /// In en, this message translates to:
  /// **'Line Graph'**
  String get lineGraph;

  /// Bar chart type option
  ///
  /// In en, this message translates to:
  /// **'Bar Chart'**
  String get barChart;

  /// Scatter plot type option
  ///
  /// In en, this message translates to:
  /// **'Scatter Plot'**
  String get scatterPlot;

  /// Pie chart type option
  ///
  /// In en, this message translates to:
  /// **'Pie Chart'**
  String get pieChart;

  /// Section title for LLM validation
  ///
  /// In en, this message translates to:
  /// **'LLM Validation'**
  String get llmValidation;

  /// Label for LLM validation option
  ///
  /// In en, this message translates to:
  /// **'Use LLM to validate graph:'**
  String get useLlmToValidateGraph;

  /// Hint text for validation input
  ///
  /// In en, this message translates to:
  /// **'Describe what you see in the graph...'**
  String get describeWhatYouSee;

  /// Button label to validate with LLM
  ///
  /// In en, this message translates to:
  /// **'Validate with LLM'**
  String get validateWithLlm;

  /// Button label while validating
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get validating;

  /// Section title for rendered graph
  ///
  /// In en, this message translates to:
  /// **'Rendered Graph'**
  String get renderedGraph;

  /// Empty state message when no data is uploaded
  ///
  /// In en, this message translates to:
  /// **'No data uploaded'**
  String get noDataUploaded;

  /// Empty state subtitle for graph
  ///
  /// In en, this message translates to:
  /// **'Upload or paste data to visualize'**
  String get uploadOrPasteData;

  /// Message when no graph type is selected
  ///
  /// In en, this message translates to:
  /// **'Select a graph type to visualize'**
  String get selectGraphType;

  /// Graph visualization title with type
  ///
  /// In en, this message translates to:
  /// **'{graphType} Visualization'**
  String graphVisualization(String graphType);

  /// Label showing number of data points
  ///
  /// In en, this message translates to:
  /// **'Data points: {count}'**
  String dataPointsCount(int count);

  /// Snackbar message when graph type is changed
  ///
  /// In en, this message translates to:
  /// **'Graph type set to {graphType}'**
  String graphTypeSetTo(String graphType);

  /// Title for upload file dialog
  ///
  /// In en, this message translates to:
  /// **'Upload Data File'**
  String get uploadDataFileDialog;

  /// Content for upload file dialog
  ///
  /// In en, this message translates to:
  /// **'File upload functionality would be implemented here.'**
  String get fileUploadImplemented;

  /// Title for graph validation dialog
  ///
  /// In en, this message translates to:
  /// **'Graph Validation'**
  String get graphValidation;

  /// Label showing graph type
  ///
  /// In en, this message translates to:
  /// **'Type: {graphType}'**
  String typeLabel(String graphType);

  /// Recommendation when data has few points
  ///
  /// In en, this message translates to:
  /// **'Consider using Pie Chart for small datasets'**
  String get considerUsingPieChart;

  /// Recommendation when data has many points
  ///
  /// In en, this message translates to:
  /// **'Consider using Bar Chart for larger datasets'**
  String get considerUsingBarChart;

  /// Message when graph type is appropriate for data
  ///
  /// In en, this message translates to:
  /// **'Graph type matches data structure'**
  String get graphTypeMatchesData;

  /// Snackbar message when graph is refreshed
  ///
  /// In en, this message translates to:
  /// **'Graph refreshed'**
  String get graphRefreshed;

  /// Error message when no graph type is selected
  ///
  /// In en, this message translates to:
  /// **'Please select a graph type first'**
  String get pleaseSelectGraphType;

  /// Message when validation completes without content
  ///
  /// In en, this message translates to:
  /// **'Validation complete'**
  String get validationComplete;

  /// Error message when validation fails
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {error}'**
  String validationFailed(String error);

  /// Error message for graph type detection failure
  ///
  /// In en, this message translates to:
  /// **'Graph type detection failed'**
  String get graphTypeDetectionError;

  /// Snackbar message when image is captured from camera
  ///
  /// In en, this message translates to:
  /// **'Image captured. You can add notes in the content field above.'**
  String get imageCaptured;

  /// Error message when camera capture fails
  ///
  /// In en, this message translates to:
  /// **'Camera error: {error}'**
  String cameraError(String error);

  /// Title for lesson scheduling page
  ///
  /// In en, this message translates to:
  /// **'Lesson Scheduler'**
  String get lessonScheduler;

  /// Section title for upcoming lessons
  ///
  /// In en, this message translates to:
  /// **'Upcoming Lessons'**
  String get upcomingLessons;

  /// Label for subject selection
  ///
  /// In en, this message translates to:
  /// **'Select Subject'**
  String get selectSubjectLabel;

  /// Section title for question types
  ///
  /// In en, this message translates to:
  /// **'Generate Question Types'**
  String get generateQuestionTypes;

  /// Section title for lesson progress
  ///
  /// In en, this message translates to:
  /// **'Lesson Progress'**
  String get lessonProgress;

  /// Progress message showing completion percentage
  ///
  /// In en, this message translates to:
  /// **'{percent}% Complete: {completed}/{total} questions generated'**
  String percentComplete(int percent, int completed, int total);

  /// Title for schedule lesson dialog
  ///
  /// In en, this message translates to:
  /// **'Schedule Lesson'**
  String get scheduleLesson;

  /// Content for schedule lesson dialog
  ///
  /// In en, this message translates to:
  /// **'Select calendar date for lesson'**
  String get selectCalendarDate;

  /// Done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Menu option to create new lesson
  ///
  /// In en, this message translates to:
  /// **'Create New Lesson'**
  String get createNewLesson;

  /// Menu option to edit existing lesson
  ///
  /// In en, this message translates to:
  /// **'Edit Existing Lesson'**
  String get editExistingLesson;

  /// Multiple choice question type label
  ///
  /// In en, this message translates to:
  /// **'MCQ'**
  String get mcq;

  /// Input question type label
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get inputLabel;

  /// Graph question type label
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get graphLabel;

  /// Semantic label for help button
  ///
  /// In en, this message translates to:
  /// **'Quick Guide help'**
  String get quickGuideHelp;

  /// Help button tooltip
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Status indicator when AI is thinking
  ///
  /// In en, this message translates to:
  /// **'Quick Guide is thinking...'**
  String get quickGuideIsThinking;

  /// Label for suggested prompt chips
  ///
  /// In en, this message translates to:
  /// **'Suggested prompts'**
  String get suggestedPrompts;

  /// Hint text for message input
  ///
  /// In en, this message translates to:
  /// **'Ask anything...'**
  String get askAnything;

  /// Tooltip for send button
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// Semantic hint for message input
  ///
  /// In en, this message translates to:
  /// **'Type your question here'**
  String get messageInputHint;

  /// Title for help dialog
  ///
  /// In en, this message translates to:
  /// **'Quick Guide Help'**
  String get quickGuideHelpTitle;

  /// Button label to dismiss help dialog
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// Error message when answer is empty
  ///
  /// In en, this message translates to:
  /// **'Add an answer before submitting.'**
  String get addAnswerBeforeSubmitting;

  /// Button label for next question
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// Label for type field
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Label for PDF source type
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdfLabel;

  /// Label for syllabus source type
  ///
  /// In en, this message translates to:
  /// **'Syllabus'**
  String get syllabusLabel;

  /// Label for textbook source type
  ///
  /// In en, this message translates to:
  /// **'Textbook'**
  String get textbookLabel;

  /// Label for video source type
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// Label for lecture notes source type
  ///
  /// In en, this message translates to:
  /// **'Lecture Notes'**
  String get lectureNotesLabel;

  /// Label for external resource source type
  ///
  /// In en, this message translates to:
  /// **'External Resource'**
  String get externalResourceLabel;

  /// Label for image source type
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// Label for web page source type
  ///
  /// In en, this message translates to:
  /// **'Web Page'**
  String get webPageLabel;

  /// Label for audio source type
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioLabel;

  /// Label for document source type
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentLabel;

  /// Hint text for text answer input
  ///
  /// In en, this message translates to:
  /// **'Type your answer here...'**
  String get typeYourAnswerHere;

  /// Hint text for essay answer input
  ///
  /// In en, this message translates to:
  /// **'Write your essay answer...'**
  String get writeYourEssayAnswer;

  /// Message for unsupported question types
  ///
  /// In en, this message translates to:
  /// **'This question type is not yet supported in this view.'**
  String get questionTypeNotSupported;

  /// Label for single choice question type
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get multipleChoice;

  /// Label for multi choice question type
  ///
  /// In en, this message translates to:
  /// **'Multiple Select'**
  String get multipleSelect;

  /// Label for text answer question type
  ///
  /// In en, this message translates to:
  /// **'Text Answer'**
  String get textAnswer;

  /// Label for math question type
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get math;

  /// Label for essay question type
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get essay;

  /// Label for diagram question type
  ///
  /// In en, this message translates to:
  /// **'Diagram'**
  String get diagram;

  /// Label for graph question type
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get graphQuestion;

  /// Label for step-by-step question type
  ///
  /// In en, this message translates to:
  /// **'Step-by-Step'**
  String get stepByStep;

  /// Label for audio recording question type
  ///
  /// In en, this message translates to:
  /// **'Audio Recording'**
  String get audioRecording;

  /// Label for canvas/drawing question type
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get canvas;

  /// Label for file upload question type
  ///
  /// In en, this message translates to:
  /// **'File Upload'**
  String get fileUpload;

  /// Label for graph drawing question type
  ///
  /// In en, this message translates to:
  /// **'Graph Drawing'**
  String get graphDrawing;

  /// Label showing difficulty level
  ///
  /// In en, this message translates to:
  /// **'Difficulty: {level}'**
  String difficultyLabel(String level);

  /// Easy difficulty level
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// Medium difficulty level
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// Hard difficulty level
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// Semantic hint for selecting an answer
  ///
  /// In en, this message translates to:
  /// **'Select as answer'**
  String get selectAsAnswer;

  /// Feedback text when correct option is selected
  ///
  /// In en, this message translates to:
  /// **'Selected right option'**
  String get selectedRightOption;

  /// Feedback text when wrong option is selected
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Placeholder text for empty canvas
  ///
  /// In en, this message translates to:
  /// **'Draw here...'**
  String get drawHere;

  /// Semantic label for undo button
  ///
  /// In en, this message translates to:
  /// **'Undo last stroke'**
  String get undoLastStroke;

  /// Semantic label for redo button
  ///
  /// In en, this message translates to:
  /// **'Redo last stroke'**
  String get redoLastStroke;

  /// Tooltip for opening the drawing canvas in tutor chat
  ///
  /// In en, this message translates to:
  /// **'Open drawing canvas'**
  String get openDrawingCanvas;

  /// Semantic label for clear button
  ///
  /// In en, this message translates to:
  /// **'Clear all drawings'**
  String get clearAllDrawings;

  /// Status text when canvas is empty
  ///
  /// In en, this message translates to:
  /// **'Canvas is empty'**
  String get canvasIsEmpty;

  /// Status text showing stroke count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Drawing with 1 stroke} other{Drawing with {count} strokes}}'**
  String drawingWithStrokes(int count);

  /// Button label to save drawing
  ///
  /// In en, this message translates to:
  /// **'Save Drawing'**
  String get saveDrawing;

  /// Success message for drawing save
  ///
  /// In en, this message translates to:
  /// **'Drawing saved.'**
  String get drawingSaved;

  /// Error message for drawing save failure
  ///
  /// In en, this message translates to:
  /// **'Failed to save drawing. Retry.'**
  String get failedToSaveDrawing;

  /// Semantic label for drawing canvas
  ///
  /// In en, this message translates to:
  /// **'Drawing canvas'**
  String get drawingCanvas;

  /// Semantic hint for drawing canvas
  ///
  /// In en, this message translates to:
  /// **'Draw your answer on the canvas using your finger or stylus'**
  String get drawYourAnswer;

  /// Title for API configuration screen
  ///
  /// In en, this message translates to:
  /// **'API Configuration'**
  String get apiConfiguration;

  /// Section title for API key configuration
  ///
  /// In en, this message translates to:
  /// **'Configure API Keys'**
  String get configureApiKeys;

  /// Description text for API key configuration
  ///
  /// In en, this message translates to:
  /// **'Enter your OpenRouter API credentials below. These are used to power the AI features.'**
  String get configureApiKeysDescription;

  /// Label for API key field
  ///
  /// In en, this message translates to:
  /// **'OpenRouter API Key'**
  String get openRouterApiKey;

  /// Label for API base URL field
  ///
  /// In en, this message translates to:
  /// **'API Base URL'**
  String get apiBaseUrl;

  /// Hint text for API key input
  ///
  /// In en, this message translates to:
  /// **'sk-or-v1-...'**
  String get apiKeyHint;

  /// Hint text for API base URL input
  ///
  /// In en, this message translates to:
  /// **'https://openrouter.ai/api/v1'**
  String get apiBaseUrlHint;

  /// Description text for API key
  ///
  /// In en, this message translates to:
  /// **'Required for LLM content generation. Get your key from https://openrouter.ai/keys'**
  String get apiKeyDescription;

  /// Description text for API base URL
  ///
  /// In en, this message translates to:
  /// **'The endpoint URL for the AI service'**
  String get apiBaseUrlDescription;

  /// Button label to save API keys
  ///
  /// In en, this message translates to:
  /// **'Save API Keys'**
  String get saveApiKeys;

  /// Error message when API key is empty
  ///
  /// In en, this message translates to:
  /// **'API key cannot be empty'**
  String get apiKeyCannotBeEmpty;

  /// Success message when API keys are saved
  ///
  /// In en, this message translates to:
  /// **'API keys saved successfully'**
  String get apiKeysSavedSuccessfully;

  /// Error message when API config save fails
  ///
  /// In en, this message translates to:
  /// **'Unable to save API configuration. Please try again.'**
  String get unableToSaveApiConfig;

  /// Label for active study session
  ///
  /// In en, this message translates to:
  /// **'Current Session'**
  String get currentSession;

  /// Label when no session is active
  ///
  /// In en, this message translates to:
  /// **'No Active Session'**
  String get noActiveSession;

  /// Hint text when session is not started
  ///
  /// In en, this message translates to:
  /// **'Tap start to begin tracking'**
  String get tapStartToBegin;

  /// Section title for recent sessions
  ///
  /// In en, this message translates to:
  /// **'Recent Sessions'**
  String get recentSessions;

  /// Label showing count of items
  ///
  /// In en, this message translates to:
  /// **'{count1} of {count2}'**
  String ofLabel(int count1, int count2);

  /// Button label to view all items
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Empty state message for sessions
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// Empty state subtitle for sessions
  ///
  /// In en, this message translates to:
  /// **'Start your first session!'**
  String get startYourFirstSession;

  /// Button label for date filter
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// Button label for subject filter
  ///
  /// In en, this message translates to:
  /// **'Filter by Subject'**
  String get filterBySubject;

  /// Tooltip for clearing filters
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Clear button label in filter dialog
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilterLabel;

  /// Label for total time stat
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// Label for average stat
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// Empty state when filters yield no results
  ///
  /// In en, this message translates to:
  /// **'No sessions found for selected filters'**
  String get noSessionsFoundForFilters;

  /// Suggestion when filters yield no results
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// Empty state message for session history
  ///
  /// In en, this message translates to:
  /// **'Start studying to track your progress'**
  String get startStudyingToTrack;

  /// Snackbar message when session is deleted
  ///
  /// In en, this message translates to:
  /// **'Session deleted'**
  String get sessionDeleted;

  /// Undo action label
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Error message when session deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete session: {error}'**
  String failedToDeleteSession(String error);

  /// Title for delete session dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get deleteSession;

  /// Confirmation text for session deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this session?'**
  String get deleteSessionConfirmation;

  /// Label when there are no questions
  ///
  /// In en, this message translates to:
  /// **'No questions'**
  String get noQuestions;

  /// Label showing number of questions
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String questionsCountLabel(int count);

  /// Label showing correct answers out of total
  ///
  /// In en, this message translates to:
  /// **'Correct: {correct}/{total}'**
  String correctOf(int correct, int total);

  /// Help text for date picker in session filter
  ///
  /// In en, this message translates to:
  /// **'Select a date to filter sessions'**
  String get selectDateToFilter;

  /// Title for subject filter dialog
  ///
  /// In en, this message translates to:
  /// **'Filter by Subject'**
  String get filterBySubjectTitle;

  /// Title for session history screen
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistory;

  /// Navigation label for dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Study Dashboard'**
  String get studyDashboard;

  /// Label for total study time metric
  ///
  /// In en, this message translates to:
  /// **'Study Time'**
  String get studyTime;

  /// Section title for plan adherence
  ///
  /// In en, this message translates to:
  /// **'Plan Adherence'**
  String get planAdherence;

  /// Section title for mastery overview
  ///
  /// In en, this message translates to:
  /// **'Mastery Overview'**
  String get masteryOverview;

  /// Section header for topic performance breakdown
  ///
  /// In en, this message translates to:
  /// **'Topic Performance'**
  String get topicPerformance;

  /// Section header for achievements/badges
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// Button label to export data as CSV
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// Button label for progress analytics export
  ///
  /// In en, this message translates to:
  /// **'Progress Analytics'**
  String get instrumentation;

  /// Label for overall stat
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// Label for current week activity stat
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Label for total topics stat
  ///
  /// In en, this message translates to:
  /// **'Total Topics'**
  String get totalTopics;

  /// Label for mastered count
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get mastered;

  /// Label for topics count
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// Button to practice all weak areas
  ///
  /// In en, this message translates to:
  /// **'Practice All Weak Areas'**
  String get practiceAllWeakAreas;

  /// Tooltip for practice topic button
  ///
  /// In en, this message translates to:
  /// **'Practice this topic'**
  String get practiceThisTopic;

  /// Empty state message when no topic mastery data exists
  ///
  /// In en, this message translates to:
  /// **'No topic data yet. Start studying to see your progress!'**
  String get noTopicDataYet;

  /// Mastery level label for novice
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get masteryLevelNovice;

  /// Mastery level label for browsing
  ///
  /// In en, this message translates to:
  /// **'Browsing'**
  String get masteryLevelBrowsing;

  /// Mastery level label for developing
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get masteryLevelDeveloping;

  /// Mastery level label for proficient
  ///
  /// In en, this message translates to:
  /// **'Proficient'**
  String get masteryLevelProficient;

  /// Mastery level label for expert
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get masteryLevelExpert;

  /// Label for mastery level section heading
  ///
  /// In en, this message translates to:
  /// **'Mastery Level'**
  String get masteryLevel;

  /// Label for best streak stat
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// Snackbar when CSV is generated
  ///
  /// In en, this message translates to:
  /// **'Progress CSV generated ({length} chars)'**
  String progressCsvGenerated(int length);

  /// Error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// Snackbar for instrumentation export
  ///
  /// In en, this message translates to:
  /// **'Instrumentation data exported'**
  String get instrumentationDataExported;

  /// Label showing number of attempts
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 attempt} other{{count} attempts}}'**
  String attemptsCount(int count);

  /// Section title for weak areas with accuracy threshold
  ///
  /// In en, this message translates to:
  /// **'Weak Areas (Accuracy < 60%)'**
  String get weakAreasAccuracy;

  /// Title for upload screen
  ///
  /// In en, this message translates to:
  /// **'Upload Content'**
  String get uploadContent;

  /// Subtitle for upload screen
  ///
  /// In en, this message translates to:
  /// **'Add study materials to your library'**
  String get addStudyMaterials;

  /// Label for title field
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// Hint text for title field
  ///
  /// In en, this message translates to:
  /// **'e.g. Chapter 5 Notes'**
  String get titleHint;

  /// Label for subject dropdown
  ///
  /// In en, this message translates to:
  /// **'Subject (optional)'**
  String get subjectOptional;

  /// Dropdown option for no selection
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Chip label for text input mode
  ///
  /// In en, this message translates to:
  /// **'Paste Text'**
  String get pasteText;

  /// Chip label for URL input mode
  ///
  /// In en, this message translates to:
  /// **'URL / Link'**
  String get urlLink;

  /// Label for URL field
  ///
  /// In en, this message translates to:
  /// **'URL *'**
  String get urlRequired;

  /// Hint text for URL field
  ///
  /// In en, this message translates to:
  /// **'https://example.com/notes'**
  String get urlHint;

  /// Label for content field
  ///
  /// In en, this message translates to:
  /// **'Content *'**
  String get contentRequired;

  /// Hint text for content field
  ///
  /// In en, this message translates to:
  /// **'Paste your study material here...'**
  String get contentHint;

  /// Button label while uploading
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// Error message when required fields are empty
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get fillRequiredFields;

  /// Success message after upload
  ///
  /// In en, this message translates to:
  /// **'Content uploaded successfully!'**
  String get contentUploadedSuccessfully;

  /// Error message when upload fails
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// Section title for plan summary
  ///
  /// In en, this message translates to:
  /// **'Plan Summary'**
  String get planSummary;

  /// Label for total count
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Label for new topics
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get newTopics;

  /// Label for review topics
  ///
  /// In en, this message translates to:
  /// **'review'**
  String get reviewTopics;

  /// Label for coverage percentage
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get coverage;

  /// Label showing focus areas
  ///
  /// In en, this message translates to:
  /// **'Focus: {areas}'**
  String focusLabel(String areas);

  /// Default label for a study day
  ///
  /// In en, this message translates to:
  /// **'Study Day'**
  String get studyDay;

  /// Label for rest day
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get rest;

  /// Tooltip for tutoring button
  ///
  /// In en, this message translates to:
  /// **'Start tutoring'**
  String get startTutoring;

  /// Label showing questions and minutes
  ///
  /// In en, this message translates to:
  /// **'{questions}Q · {minutes}min'**
  String questionsAndMinutes(int questions, int minutes);

  /// Label showing topic questions and minutes
  ///
  /// In en, this message translates to:
  /// **'{questions}Q · {minutes}min'**
  String topicQuestionsAndMinutes(int questions, int minutes);

  /// Error message when plan generation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate plan'**
  String get failedToGeneratePlan;

  /// Title for LLM task manager screen
  ///
  /// In en, this message translates to:
  /// **'LLM Task Manager'**
  String get llmTaskManager;

  /// Label showing active task count
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 active} other{{count} active}}'**
  String activeCount(int count);

  /// Empty state for task manager
  ///
  /// In en, this message translates to:
  /// **'No LLM tasks yet'**
  String get noLlmTasksYet;

  /// Label showing model ID
  ///
  /// In en, this message translates to:
  /// **'Model: {modelId}'**
  String modelLabel(String modelId);

  /// Label showing start time
  ///
  /// In en, this message translates to:
  /// **'Started: {time}'**
  String startedLabel(String time);

  /// Label showing end time
  ///
  /// In en, this message translates to:
  /// **'Ended: {time}'**
  String endedLabel(String time);

  /// Label showing token count and cost
  ///
  /// In en, this message translates to:
  /// **'Tokens: {count} ({cost})'**
  String tokensAndCost(int count, String cost);

  /// Button to cancel a task
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTask;

  /// Button to test API connection
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// Button label while testing connection
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// Success message for connection test
  ///
  /// In en, this message translates to:
  /// **'Connection successful! Latency: {latency}ms'**
  String connectionSuccessful(int latency);

  /// Error message for connection test
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailed(String error);

  /// Snackbar for session history CSV export
  ///
  /// In en, this message translates to:
  /// **'Session history CSV generated ({length} chars)'**
  String sessionHistoryCsvGenerated(int length);

  /// Today's plan target
  ///
  /// In en, this message translates to:
  /// **'Today: {questions}Q, {minutes}min'**
  String dailyPlanTarget(int questions, int minutes);

  /// When there is no plan for today
  ///
  /// In en, this message translates to:
  /// **'No plan for today'**
  String get noPlanForToday;

  /// Nudge to adjust plan due to low adherence
  ///
  /// In en, this message translates to:
  /// **'You\'ve had {count,plural,=1{1 day} other{{count} days}} of low plan adherence. Would you like to adjust your study plan?'**
  String planAdjustmentSuggested(int count);

  /// Button to adjust study plan
  ///
  /// In en, this message translates to:
  /// **'Adjust Plan'**
  String get adjustPlan;

  /// Button to dismiss a nudge
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Tooltip for voice input button
  ///
  /// In en, this message translates to:
  /// **'Voice Input'**
  String get voiceInput;

  /// Tooltip for capture image button
  ///
  /// In en, this message translates to:
  /// **'Capture Image'**
  String get captureImage;

  /// Camera option label
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Error message when saving subject fails
  ///
  /// In en, this message translates to:
  /// **'Error saving subject: {error}'**
  String errorSavingSubject(String error);

  /// Error message when saving session fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save session: {error}'**
  String failedToSaveSession(String error);

  /// Metric card label for average session time
  ///
  /// In en, this message translates to:
  /// **'Avg Session'**
  String get avgSession;

  /// Metric card label for total sessions count
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessionsLabel;

  /// Metric card label for current streak
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreakLabel;

  /// Section header for day-of-week chart
  ///
  /// In en, this message translates to:
  /// **'Sessions by Day of Week'**
  String get sessionsByDayOfWeek;

  /// Section header for performance metrics
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// Number of days (e.g. for streak count)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// Empty state message for topic list
  ///
  /// In en, this message translates to:
  /// **'No topics yet - add some!'**
  String get noTopicsYetAddSome;

  /// Empty state message for lesson list
  ///
  /// In en, this message translates to:
  /// **'No lessons - use Planner to generate!'**
  String get noLessonsUsePlanner;

  /// Bottom navigation label for AI mentor
  ///
  /// In en, this message translates to:
  /// **'Mentor'**
  String get mentor;

  /// Button label to start AI tutoring session
  ///
  /// In en, this message translates to:
  /// **'Start AI Tutoring'**
  String get startAiTutoring;

  /// Button to end the current lesson
  ///
  /// In en, this message translates to:
  /// **'End Lesson'**
  String get endLesson;

  /// Hint text for message input field
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// Send button label
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Title for progress report dialog
  ///
  /// In en, this message translates to:
  /// **'Progress Report'**
  String get progressReport;

  /// Hint text for mentor chat input
  ///
  /// In en, this message translates to:
  /// **'Ask your mentor anything...'**
  String get askMentorAnything;

  /// Welcome title for mentor screen
  ///
  /// In en, this message translates to:
  /// **'AI Mentor'**
  String get mentorGreeting;

  /// Subtitle for mentor screen
  ///
  /// In en, this message translates to:
  /// **'Your personal AI academic assistant'**
  String get mentorSubtitle;

  /// Loading message while lesson initializes
  ///
  /// In en, this message translates to:
  /// **'Starting your lesson...'**
  String get startingLesson;

  /// Message shown when lesson time is up
  ///
  /// In en, this message translates to:
  /// **'Lesson time has ended. Click \'End Lesson\' to finish.'**
  String get lessonTimeEnded;

  /// Title for lesson completion dialog
  ///
  /// In en, this message translates to:
  /// **'Lesson Complete'**
  String get lessonComplete;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// Status label for in-progress items
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Status label for completed items
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Status label for not started items
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// Number of lesson blocks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 block} other{{count} blocks}}'**
  String blocksCount(int count);

  /// Label for explanation block type
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get blockTypeExplanation;

  /// Label for example block type
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get blockTypeExample;

  /// Label for exercise block type
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get blockTypeExercise;

  /// Label for slide block type
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get blockTypeSlide;

  /// Label for quiz block type
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get blockTypeQuiz;

  /// Label for summary block type
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get blockTypeSummary;

  /// App bar title with practice mode and question type
  ///
  /// In en, this message translates to:
  /// **'{mode} - {type}'**
  String practiceModeType(String mode, String type);

  /// Exam mode title
  ///
  /// In en, this message translates to:
  /// **'Exam Mode'**
  String get examMode;

  /// Description for exam mode
  ///
  /// In en, this message translates to:
  /// **'Timed exam simulation'**
  String get examModeDescription;

  /// Source practice mode title
  ///
  /// In en, this message translates to:
  /// **'Source Practice'**
  String get sourcePractice;

  /// Description for source practice mode
  ///
  /// In en, this message translates to:
  /// **'Practice by source'**
  String get sourcePracticeDescription;

  /// Message when no sources are available
  ///
  /// In en, this message translates to:
  /// **'No sources available'**
  String get noSourcesAvailable;

  /// Label for confidence selector
  ///
  /// In en, this message translates to:
  /// **'How confident are you?'**
  String get howConfident;

  /// Screen reader label fragment for range indicator, e.g. '3 of 5'
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get confidenceRatingOf;

  /// Confidence level 1
  ///
  /// In en, this message translates to:
  /// **'Not confident at all'**
  String get notConfidentAtAll;

  /// Confidence level 2
  ///
  /// In en, this message translates to:
  /// **'Slightly confident'**
  String get slightlyConfident;

  /// Confidence level 3
  ///
  /// In en, this message translates to:
  /// **'Moderately confident'**
  String get moderatelyConfident;

  /// Confidence level 4
  ///
  /// In en, this message translates to:
  /// **'Quite confident'**
  String get quiteConfident;

  /// Confidence level 5
  ///
  /// In en, this message translates to:
  /// **'Very confident'**
  String get veryConfident;

  /// Title for mistake review section
  ///
  /// In en, this message translates to:
  /// **'Review Mistakes'**
  String get reviewMistakes;

  /// Description for mistake review
  ///
  /// In en, this message translates to:
  /// **'Review {count} mistakes from this session'**
  String reviewMistakesDescription(int count);

  /// Message when there are no mistakes to review
  ///
  /// In en, this message translates to:
  /// **'No mistakes to review'**
  String get noMistakesToReview;

  /// Button to redo incorrect questions
  ///
  /// In en, this message translates to:
  /// **'Redo Incorrect Questions'**
  String get redoIncorrectQuestions;

  /// Fallback text when no answer was given
  ///
  /// In en, this message translates to:
  /// **'No answer provided'**
  String get noAnswerProvided;

  /// Label for correct answer
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswer;

  /// Title for practice by source sheet
  ///
  /// In en, this message translates to:
  /// **'Practice by Source'**
  String get practiceBySource;

  /// Description for practice by source sheet
  ///
  /// In en, this message translates to:
  /// **'Select a source to practice questions from'**
  String get practiceBySourceDescription;

  /// Fallback option label for multiple choice questions
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String fallbackOption(int number);

  /// Message when drawing is submitted as answer
  ///
  /// In en, this message translates to:
  /// **'Drawing submitted'**
  String get drawingSubmitted;

  /// Error message for unsupported question type
  ///
  /// In en, this message translates to:
  /// **'Unsupported question type: {type}'**
  String unsupportedQuestionType(String type);

  /// Section title for today's study plan
  ///
  /// In en, this message translates to:
  /// **'Today\'s Plan'**
  String get todaysPlan;

  /// Empty state message when no plan exists for today
  ///
  /// In en, this message translates to:
  /// **'No study plan for today'**
  String get noStudyPlanToday;

  /// Metric label for question count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String questionsCountMetric(int count);

  /// Abbreviated question count (e.g., 5Q)
  ///
  /// In en, this message translates to:
  /// **'{count}Q'**
  String questionsAbbreviation(int count);

  /// Metric label for minutes
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesCountMetric(int count);

  /// Section title for at-risk topics
  ///
  /// In en, this message translates to:
  /// **'At Risk Topics'**
  String get atRiskTopics;

  /// Empty state message when no at-risk topics
  ///
  /// In en, this message translates to:
  /// **'No at-risk topics. Keep up the good work!'**
  String get noAtRiskTopics;

  /// Section title for ready-to-advance topics
  ///
  /// In en, this message translates to:
  /// **'Ready to Advance'**
  String get readyToAdvance;

  /// Empty state message for ready-to-advance section
  ///
  /// In en, this message translates to:
  /// **'Keep practicing to unlock advanced topics!'**
  String get keepPracticingToUnlock;

  /// Label for total topics count
  ///
  /// In en, this message translates to:
  /// **'Total Topics'**
  String get totalTopicsLabel;

  /// Label for mastered topic count
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get masteredLabel;

  /// Label for weak topic count
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weakLabel;

  /// Label for a course session in planner
  ///
  /// In en, this message translates to:
  /// **'{course} - Session {number}'**
  String courseSessionLabel(String course, int number);

  /// Welcome message shown in Quick Guide chat
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m StudyKing\'s Quick Guide. Ask me anything about your studies!'**
  String get quickGuideWelcomeMessage;

  /// Suggested prompt for explain concept
  ///
  /// In en, this message translates to:
  /// **'Explain photosynthesis'**
  String get suggestedPromptExplain;

  /// Suggested prompt for quiz
  ///
  /// In en, this message translates to:
  /// **'Quiz me on history'**
  String get suggestedPromptQuiz;

  /// Suggested prompt for math help
  ///
  /// In en, this message translates to:
  /// **'Help with math problems'**
  String get suggestedPromptMath;

  /// Help dialog content for Quick Guide
  ///
  /// In en, this message translates to:
  /// **'Quick Guide is your AI study assistant. You can:\n\n• Ask questions about any subject\n• Request explanations for concepts\n• Get help with practice problems\n\nJust type your question and tap send!'**
  String get quickGuideHelpContent;

  /// Semantic label for user chat message
  ///
  /// In en, this message translates to:
  /// **'You said: {message}'**
  String semanticsYouSaid(String message);

  /// Semantic label for AI chat message
  ///
  /// In en, this message translates to:
  /// **'Quick Guide said: {message}'**
  String semanticsQuickGuideSaid(String message);

  /// Semantic label for sending a suggested prompt
  ///
  /// In en, this message translates to:
  /// **'Send prompt: {prompt}'**
  String semanticsSendPrompt(String prompt);

  /// Semantic label for message input field
  ///
  /// In en, this message translates to:
  /// **'Message input for Quick Guide'**
  String get semanticsMessageInput;

  /// Fallback AI response when user asks for explanation
  ///
  /// In en, this message translates to:
  /// **'Sure! I can help explain concepts. What topic would you like me to explain?'**
  String get fallbackExplainResponse;

  /// Fallback AI response when user asks for quiz
  ///
  /// In en, this message translates to:
  /// **'I can help with questions! Ask away and I\'ll do my best.'**
  String get fallbackQuizResponse;

  /// Fallback AI response when user asks for math help
  ///
  /// In en, this message translates to:
  /// **'I\'d be happy to help with math! What specific problem or topic would you like to work on?'**
  String get fallbackMathResponse;

  /// Fallback AI response for general questions
  ///
  /// In en, this message translates to:
  /// **'That\'s an interesting question! Let me help you understand it better.'**
  String get fallbackGeneralResponse;

  /// System prompt for Quick Guide AI in the current locale
  ///
  /// In en, this message translates to:
  /// **'You are StudyKing Quick Guide, a helpful AI study assistant. Provide concise, educational answers. Help with explanations, quiz questions, and math problems. Respond conversationally.'**
  String get quickGuideSystemPrompt;

  /// System prompt for Mentor AI in the current locale
  ///
  /// In en, this message translates to:
  /// **'You are a knowledgeable and encouraging AI mentor for a student. Your role is to guide their learning journey, provide motivation, and help them develop effective study habits. Keep responses concise, supportive, and actionable.'**
  String get mentorSystemPrompt;

  /// Additional scheduling instructions appended to Mentor system prompt
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: When the student asks about scheduling lessons, creating plans, or rescheduling, your response should acknowledge the request and indicate that you will present a confirmation proposal. Do not state or imply that the scheduling or plan change has been committed or completed. Use conditional language such as \"I can help with that\", \"Let me check availability\", or \"I\'ll prepare a proposal for you to confirm\". After your response, the system will present a confirmation dialog to the student before any changes are applied.'**
  String get mentorSystemPromptScheduling;

  /// Application name for About dialog
  ///
  /// In en, this message translates to:
  /// **'StudyKing'**
  String get aboutApplicationName;

  /// Application version for About dialog
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get aboutVersion;

  /// Copyright notice for About dialog
  ///
  /// In en, this message translates to:
  /// **'© 2026 StudyKing.'**
  String get aboutLegalese;

  /// Title for exit confirmation when lesson timer is active
  ///
  /// In en, this message translates to:
  /// **'You have an active lesson timer. Leave anyway?'**
  String get activeLessonTimer;

  /// Fallback model ID when unknown
  ///
  /// In en, this message translates to:
  /// **'unknown-model'**
  String get unknownModelId;

  /// Fallback provider name when unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownProviderName;

  /// Label for exam date field with colon included for locale-aware punctuation
  ///
  /// In en, this message translates to:
  /// **'Exam Date (Optional):'**
  String get examDateOptionalLabel;

  /// Fallback title for a lesson when name is missing
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonFallbackTitle;

  /// Fallback content template for a lesson when LLM generation fails
  ///
  /// In en, this message translates to:
  /// **'Study the key concepts of {topicTitle}. Focus on understanding the core principles.'**
  String lessonFallbackContent(String topicTitle);

  /// Fallback title for a lesson plan when JSON parsing fails
  ///
  /// In en, this message translates to:
  /// **'Lesson plan for this session'**
  String get lessonPlanFallbackTitle;

  /// Error message with error details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// Default label for unknown question type
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionTypeDefault;

  /// Separator between duration parts
  ///
  /// In en, this message translates to:
  /// **' '**
  String get durationSeparator;

  /// Section title for accessibility settings
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// Title for high contrast toggle
  ///
  /// In en, this message translates to:
  /// **'High Contrast Mode'**
  String get highContrastMode;

  /// Subtitle for high contrast toggle
  ///
  /// In en, this message translates to:
  /// **'Increase contrast for better visibility'**
  String get highContrastDescription;

  /// Title for large touch targets toggle
  ///
  /// In en, this message translates to:
  /// **'Large Touch Targets'**
  String get largeTouchTargets;

  /// Subtitle for large touch targets toggle
  ///
  /// In en, this message translates to:
  /// **'Increase tap target sizes'**
  String get largeTouchTargetsDescription;

  /// Title for reduce motion toggle
  ///
  /// In en, this message translates to:
  /// **'Reduce Motion'**
  String get reduceMotion;

  /// Subtitle for reduce motion toggle
  ///
  /// In en, this message translates to:
  /// **'Reduce or disable motion animations'**
  String get reduceMotionDescription;

  /// Error message when network connection fails
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server. Please check your internet connection and try again.'**
  String get errorNetworkConnection;

  /// Error message when API key is missing
  ///
  /// In en, this message translates to:
  /// **'API key is required. Please configure it in Settings.'**
  String get errorApiKeyMissing;

  /// Error message when API key is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid API key. Please check your credentials in Settings.'**
  String get errorInvalidApiKey;

  /// Error message when API rate limit is hit
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get errorApiRateLimit;

  /// Error message when API resource is not found
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get errorApiNotFound;

  /// Error message when server error occurs
  ///
  /// In en, this message translates to:
  /// **'The server encountered an error. Please try again later.'**
  String get errorApiInternalServer;

  /// Error message for database errors
  ///
  /// In en, this message translates to:
  /// **'A database error occurred. Please try again.'**
  String get errorDatabase;

  /// Error message when PDF parsing fails
  ///
  /// In en, this message translates to:
  /// **'Unable to parse the PDF file. Please ensure it is a valid PDF.'**
  String get errorPdfParse;

  /// Error message when content generation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate content. Please try again.'**
  String get errorContentGeneration;

  /// Error message when AI service is unavailable
  ///
  /// In en, this message translates to:
  /// **'The AI service is temporarily unavailable. Please try again.'**
  String get errorLlmUnavailable;

  /// Error message when API authentication fails
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your API credentials.'**
  String get errorApiAuth;

  /// Generic unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnexpected;

  /// Button label to retry connection
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// Button label to retry after rate limit wait
  ///
  /// In en, this message translates to:
  /// **'Retry After Wait'**
  String get retryAfterWait;

  /// Label for weekly activity metric
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// Label for topics count metric
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topicsLabel;

  /// Label for readiness metric
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get readiness;

  /// Label for confidence stat
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// Label for forgetting risk stat
  ///
  /// In en, this message translates to:
  /// **'Forgetting Risk'**
  String get forgettingRisk;

  /// Label for review urgency stat
  ///
  /// In en, this message translates to:
  /// **'Review Urgency'**
  String get reviewUrgency;

  /// Label for last attempted date
  ///
  /// In en, this message translates to:
  /// **'Last Attempted'**
  String get lastAttempted;

  /// Label for last updated date
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Heading for accuracy trend chart
  ///
  /// In en, this message translates to:
  /// **'Accuracy Trend'**
  String get accuracyTrend;

  /// Loading text shown while syllabus progress is being fetched
  ///
  /// In en, this message translates to:
  /// **'Loading syllabus progress...'**
  String get loadingSyllabusProgress;

  /// Semantics label for page indicator dots
  ///
  /// In en, this message translates to:
  /// **'Page {count} of {total}'**
  String pageIndicatorAria(int count, int total);

  /// Label for overall mastery progress section
  ///
  /// In en, this message translates to:
  /// **'Overall Mastery'**
  String get overallMastery;

  /// Label for average time per question
  ///
  /// In en, this message translates to:
  /// **'Avg Time'**
  String get avgTime;

  /// Label for badges count
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// Button label to export session history
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistoryExport;

  /// Snackbar message when progress CSV is exported
  ///
  /// In en, this message translates to:
  /// **'Progress exported to CSV'**
  String get progressExportedCsv;

  /// Snackbar message when session history CSV is exported
  ///
  /// In en, this message translates to:
  /// **'Session history exported to CSV'**
  String get sessionHistoryExportedCsv;

  /// Button label to export data as PDF
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// Snackbar message when session history PDF is exported
  ///
  /// In en, this message translates to:
  /// **'Session history exported to PDF'**
  String get sessionHistoryExportedPdf;

  /// Snackbar message when session history JSON is exported
  ///
  /// In en, this message translates to:
  /// **'Session history exported to JSON'**
  String get sessionHistoryExportedJson;

  /// Label for JSON export format
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get labelJson;

  /// Title for unsaved changes confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// Body text for unsaved changes confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get unsavedChangesDescription;

  /// Button label to discard unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Button label to navigate to settings
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// Error message when lesson fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load lesson. Please check your connection and try again.'**
  String get failedToLoadLesson;

  /// Error message when practice session fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start practice session'**
  String get failedToStartPractice;

  /// Mode card title for AI Tutor
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get aiTutor;

  /// Mode card subtitle for AI Tutor
  ///
  /// In en, this message translates to:
  /// **'Interactive conversational lessons'**
  String get interactiveConversationalLessons;

  /// Mode card subtitle for Mentor
  ///
  /// In en, this message translates to:
  /// **'Personal study assistant & planner'**
  String get personalStudyAssistantPlanner;

  /// Heading for mode selection cards
  ///
  /// In en, this message translates to:
  /// **'Choose a study mode'**
  String get chooseStudyMode;

  /// Tooltip/label for clearing chat conversation
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get clearConversation;

  /// Sender label for the student in chat
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get senderYou;

  /// Sender label for the AI tutor in chat
  ///
  /// In en, this message translates to:
  /// **'Tutor'**
  String get senderTutor;

  /// Sender label for system messages in chat
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get senderSystem;

  /// Label showing remaining minutes in lesson
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min remaining} other{{count} min remaining}}'**
  String remainingMinLabel(int count);

  /// Label showing correct answer count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 correct} other{{count} correct}}'**
  String correctCountLabel(int count);

  /// Welcome message body in mentor screen
  ///
  /// In en, this message translates to:
  /// **'I can help with:\n• Scheduling and rescheduling lessons\n• Reviewing your study progress\n• Planning long-term study goals\n• Motivation and encouragement\n• Deciding what to study next\n\nHow can I help you today?'**
  String get mentorWelcomeBody;

  /// Initial greeting prompt from student to AI tutor
  ///
  /// In en, this message translates to:
  /// **'I\'m ready to learn about {topic}. Please teach me!'**
  String readyToLearnAbout(String topic);

  /// Initial greeting prompt from student to AI tutor for a scheduled lesson
  ///
  /// In en, this message translates to:
  /// **'Welcome to my scheduled lesson on {topic}. I\'m ready to learn!'**
  String scheduledLessonGreeting(String topic);

  /// System prompt context added when lesson is part of a pre-scheduled session
  ///
  /// In en, this message translates to:
  /// **'Note: This student has pre-scheduled this lesson session. The session has a fixed duration set in the student\'s study plan. Acknowledge the scheduled nature appropriately and respect the time limit.'**
  String get scheduledLessonSystemContext;

  /// Label showing correct count in summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 correct} other{{count} correct}}'**
  String correctCount(int count);

  /// Label showing adaptive pace percentage
  ///
  /// In en, this message translates to:
  /// **'{pace}% pace'**
  String paceLabel(int pace);

  /// Error message when AI response fails
  ///
  /// In en, this message translates to:
  /// **'Sorry, I encountered an error. Please try again.'**
  String get errorWithResponse;

  /// Mentor response when user rejects a pending action
  ///
  /// In en, this message translates to:
  /// **'No problem! I won\'t make any changes. Let me know if you need anything else.'**
  String get mentorRejectionResponse;

  /// Mentor message when no lessons are scheduled
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any lessons scheduled yet. Would you like me to help you create a study plan? I can help you set up regular study sessions for your subjects.'**
  String get mentorNoLessonsScheduled;

  /// Header for upcoming lessons list
  ///
  /// In en, this message translates to:
  /// **'Here are your upcoming lessons:\n'**
  String get mentorUpcomingLessonsHeader;

  /// Single lesson entry in schedule list
  ///
  /// In en, this message translates to:
  /// **'• {topic} on {date} ({duration} min)\n'**
  String mentorLessonEntry(String topic, String date, int duration);

  /// Prompt asking if user wants to reschedule
  ///
  /// In en, this message translates to:
  /// **'\nWould you like to reschedule any of these?'**
  String get mentorReschedulePrompt;

  /// Message showing recent session date
  ///
  /// In en, this message translates to:
  /// **'Your most recent study session was on {date}. Would you like to schedule a new lesson?'**
  String mentorRecentSessionOnDate(String date);

  /// Mentor message when student hasn't started studying
  ///
  /// In en, this message translates to:
  /// **'It looks like you haven\'t started yet. Would you like me to help you schedule your first lesson?'**
  String get mentorNotStarted;

  /// Error message when schedule lookup fails
  ///
  /// In en, this message translates to:
  /// **'I had trouble looking up your schedule. Please try again later.'**
  String get mentorScheduleError;

  /// Error message when progress report generation fails
  ///
  /// In en, this message translates to:
  /// **'I had trouble generating your progress report. Please try again later.'**
  String get mentorProgressError;

  /// Mentor message when no study sessions exist
  ///
  /// In en, this message translates to:
  /// **'You haven\'t started studying yet! Would you like me to help you create a study plan to get started?'**
  String get mentorNotStartedStudying;

  /// Word for today (used in inactivity check)
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get mentorToday;

  /// Formatted days ago string
  ///
  /// In en, this message translates to:
  /// **'{daysCount, plural, =1{1 day ago} other{{daysCount} days ago}}'**
  String mentorDaysAgo(int daysCount);

  /// Mentor message when student has been inactive for 3+ days
  ///
  /// In en, this message translates to:
  /// **'I noticed you haven\'t studied in {daysCount} days. Would you like to schedule a study session to get back on track? Consistency is key to making progress!'**
  String mentorInactiveDays(int daysCount);

  /// Mentor praise when student is active
  ///
  /// In en, this message translates to:
  /// **'Great job staying active! Your last study session was {daysAgo}. Keep up the good work!'**
  String mentorGreatJobStayingActive(String daysAgo);

  /// Mentor welcome message for new students
  ///
  /// In en, this message translates to:
  /// **'Welcome! Let\'s get started with your studies. Would you like to schedule a lesson?'**
  String get mentorWelcomeStart;

  /// Error message when activity check fails
  ///
  /// In en, this message translates to:
  /// **'I had trouble checking your activity. How can I help you today?'**
  String get mentorActivityCheckError;

  /// Confirmation after rescheduling a lesson
  ///
  /// In en, this message translates to:
  /// **'I\'ve noted the change. Your lesson \"{topic}\" has been rescheduled. Is there anything else I can help with?'**
  String mentorRescheduledConfirmation(String topic);

  /// Confirmation after adding a new session
  ///
  /// In en, this message translates to:
  /// **'Great! I\'ve added a new study session to your schedule. You can check your planner for details.'**
  String get mentorNewSessionAdded;

  /// Generic confirmation after schedule changes
  ///
  /// In en, this message translates to:
  /// **'Done! The changes have been made to your schedule.'**
  String get mentorChangesDone;

  /// Section header for accuracy in progress report
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get mentorAccuracy;

  /// Section header for badges in progress report
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get mentorBadges;

  /// Section header for recommendations in progress report
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get mentorRecommendationsSection;

  /// Title for the progress report
  ///
  /// In en, this message translates to:
  /// **'📊 Your Study Progress Report\n'**
  String get mentorProgressReportTitle;

  /// Overall accuracy line in progress report
  ///
  /// In en, this message translates to:
  /// **'Overall Accuracy: {accuracy}% ({correct}/{total} correct)'**
  String mentorOverallAccuracy(String accuracy, String correct, String total);

  /// Total study time line in progress report
  ///
  /// In en, this message translates to:
  /// **'Total Study Time: {hours} hours'**
  String mentorTotalStudyTime(String hours);

  /// Weekly activity line in progress report
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity: {attempts} attempts'**
  String mentorWeeklyActivity(String attempts);

  /// Completed lessons line in progress report
  ///
  /// In en, this message translates to:
  /// **'Completed Lessons: {count}'**
  String mentorCompletedLessons(String count);

  /// Topics studied line in progress report
  ///
  /// In en, this message translates to:
  /// **'Topics Studied: {count}'**
  String mentorTopicsStudied(String count);

  /// Section header for weak topics
  ///
  /// In en, this message translates to:
  /// **'\nAreas needing attention:'**
  String get mentorAreasNeedingAttention;

  /// Single topic accuracy entry
  ///
  /// In en, this message translates to:
  /// **'• {topic} (accuracy: {accuracy}%)'**
  String mentorTopicAccuracyEntry(String topic, int accuracy);

  /// Section header for badges
  ///
  /// In en, this message translates to:
  /// **'\nBadges earned:'**
  String get mentorBadgesEarned;

  /// Single badge entry
  ///
  /// In en, this message translates to:
  /// **'• {name}: {description}'**
  String mentorBadgeEntry(String name, String description);

  /// Section header for recommendations
  ///
  /// In en, this message translates to:
  /// **'\nRecommendations:'**
  String get mentorRecommendations;

  /// Single recommendation entry
  ///
  /// In en, this message translates to:
  /// **'• {message}'**
  String mentorRecommendationEntry(String message);

  /// Error when progress report generation fails
  ///
  /// In en, this message translates to:
  /// **'Unable to generate progress report. Please try again later.'**
  String get mentorProgressReportError;

  /// Message when API key is missing for mentor chat
  ///
  /// In en, this message translates to:
  /// **'AI service not configured.'**
  String get mentorApiKeyMissing;

  /// Mentor message when no subjects exist
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any subjects yet. Would you like help setting up your first subject?'**
  String get mentorNoSubjects;

  /// Mentor suggestion when student is doing well
  ///
  /// In en, this message translates to:
  /// **'You\'re doing well! Would you like to review your progress, schedule a new lesson, or practice some questions?'**
  String get mentorDoingWell;

  /// Section title for roadmaps
  ///
  /// In en, this message translates to:
  /// **'Roadmaps'**
  String get roadmaps;

  /// Button to create a new roadmap
  ///
  /// In en, this message translates to:
  /// **'Create Roadmap'**
  String get createRoadmap;

  /// Label for roadmap goal input
  ///
  /// In en, this message translates to:
  /// **'Learning Goal'**
  String get roadmapGoal;

  /// Hint text for roadmap goal
  ///
  /// In en, this message translates to:
  /// **'e.g., I want to learn Python in 90 days'**
  String get roadmapGoalHint;

  /// Button to generate a roadmap
  ///
  /// In en, this message translates to:
  /// **'Generate Roadmap'**
  String get generateRoadmap;

  /// Title for list of roadmaps
  ///
  /// In en, this message translates to:
  /// **'My Roadmaps'**
  String get myRoadmaps;

  /// Section title for milestones
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// A single milestone
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get milestone;

  /// Short milestone label in timeline
  ///
  /// In en, this message translates to:
  /// **'M{order}'**
  String milestoneShort(int order);

  /// Target completion date label
  ///
  /// In en, this message translates to:
  /// **'Target Completion'**
  String get targetCompletion;

  /// Empty state for roadmaps
  ///
  /// In en, this message translates to:
  /// **'No roadmaps yet'**
  String get noRoadmapsYet;

  /// Timeline view label
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// Completion percentage
  ///
  /// In en, this message translates to:
  /// **'{value} Complete'**
  String completionOfValue(String value);

  /// Milestone with deadline
  ///
  /// In en, this message translates to:
  /// **'{title} - Due {deadline}'**
  String milestoneOfWithDeadline(String title, String deadline);

  /// Toggle to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// Section title for notification settings
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// Daily reminder toggle
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get dailyReminders;

  /// Revision reminder toggle
  ///
  /// In en, this message translates to:
  /// **'Revision Reminders'**
  String get revisionReminders;

  /// Overwork alert toggle
  ///
  /// In en, this message translates to:
  /// **'Overwork Alerts'**
  String get overworkAlerts;

  /// Plan adjustment notification toggle
  ///
  /// In en, this message translates to:
  /// **'Plan Adjustment Alerts'**
  String get planAdjustmentNotifications;

  /// Quiet hours section label
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// Start time for quiet hours
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours Start'**
  String get quietHoursStart;

  /// End time for quiet hours
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours End'**
  String get quietHoursEnd;

  /// Button to export comprehensive report
  ///
  /// In en, this message translates to:
  /// **'Export Full Progress Report'**
  String get exportComprehensiveReport;

  /// Export full progress as CSV
  ///
  /// In en, this message translates to:
  /// **'Full Progress CSV'**
  String get comprehensiveCsv;

  /// Export full progress as PDF
  ///
  /// In en, this message translates to:
  /// **'Full Progress PDF'**
  String get comprehensivePdf;

  /// Export full progress as JSON
  ///
  /// In en, this message translates to:
  /// **'Full Progress JSON'**
  String get comprehensiveJson;

  /// Snackbar when comprehensive report is exported
  ///
  /// In en, this message translates to:
  /// **'Comprehensive progress report exported'**
  String get comprehensiveReportExported;

  /// Detail description for CSV export confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'CSV: overall stats, topic mastery, all attempts (one per row), weekly trend, badges.'**
  String get exportCsvDetail;

  /// Detail description for PDF export confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'PDF: formatted report with tables, charts, and mastery breakdowns suitable for printing.'**
  String get exportPdfDetail;

  /// Detail description for JSON export confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'JSON: structured data export for programmatic analysis.'**
  String get exportJsonDetail;

  /// Detail description for progress CSV export confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Stats CSV: summary statistics and progress overview (lighter than full CSV).'**
  String get exportProgressCsvDetail;

  /// Detail description for instrumentation export confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Progress Analytics: plan adherence and mastery improvement metrics for analysis.'**
  String get exportInstrumentationDetail;

  /// Hint text suggesting to use Settings for full data backup
  ///
  /// In en, this message translates to:
  /// **'For a full data backup (subjects, questions, settings), go to Settings → Backup & Restore.'**
  String get backupRestoreHint;

  /// Label for active roadmaps count
  ///
  /// In en, this message translates to:
  /// **'Active Roadmaps'**
  String get activeRoadmaps;

  /// Label for completed roadmaps
  ///
  /// In en, this message translates to:
  /// **'Completed Roadmaps'**
  String get completedRoadmaps;

  /// Section title for per-subject progress
  ///
  /// In en, this message translates to:
  /// **'Progress by Subject'**
  String get progressBySubject;

  /// Label for a numbered week in a roadmap
  ///
  /// In en, this message translates to:
  /// **'Week {number}'**
  String weekNumber(int number);

  /// Description for a milestone in a roadmap
  ///
  /// In en, this message translates to:
  /// **'Milestone for week {number}'**
  String milestoneForWeek(int number);

  /// Message when no markscheme exists for a question
  ///
  /// In en, this message translates to:
  /// **'No markscheme available'**
  String get markschemeUnavailable;

  /// Feedback when the answer is too short
  ///
  /// In en, this message translates to:
  /// **'Answer is too short. Please provide more details.'**
  String get answerTooShort;

  /// Feedback when answer length is adequate
  ///
  /// In en, this message translates to:
  /// **'Good response length.'**
  String get goodResponseLength;

  /// Feedback when answer is too short for full credit
  ///
  /// In en, this message translates to:
  /// **'Answer too short for full credit.'**
  String get answerTooShortForCredit;

  /// Feedback when no drawing content is detected
  ///
  /// In en, this message translates to:
  /// **'No drawing detected. Please draw something.'**
  String get noDrawingDetected;

  /// Feedback when drawing data is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid drawing data. Please redraw.'**
  String get invalidDrawingData;

  /// Feedback when all steps are identified correctly
  ///
  /// In en, this message translates to:
  /// **'All required steps identified.'**
  String get allStepsIdentified;

  /// Message for question types that need special handling
  ///
  /// In en, this message translates to:
  /// **'This question type requires special handling.'**
  String get specialHandlingRequired;

  /// Feedback for partially incorrect multi-choice answers
  ///
  /// In en, this message translates to:
  /// **'Some answers are incorrect'**
  String get someAnswersIncorrect;

  /// Message showing the correct answer
  ///
  /// In en, this message translates to:
  /// **'The correct answer is: {answer}'**
  String correctAnswerIs(String answer);

  /// Feedback when all required steps are identified
  ///
  /// In en, this message translates to:
  /// **'All {count} steps identified correctly!'**
  String allStepsFormat(int count);

  /// Feedback when some steps are missing
  ///
  /// In en, this message translates to:
  /// **'Identified {matched} of {total} steps. Missing: {missing}'**
  String partialStepsFormat(int matched, int total, String missing);

  /// Feedback when no required steps are found
  ///
  /// In en, this message translates to:
  /// **'No required steps found in your answer. Key steps to include: {steps}'**
  String noStepsFormat(String steps);

  /// Feedback when required steps are missing from answer
  ///
  /// In en, this message translates to:
  /// **'Some required steps missing'**
  String get allRequiredStepsMissing;

  /// AppBar title for study hub screen (formerly Focus Mode)
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get focusMode;

  /// Title for creating a new focus session
  ///
  /// In en, this message translates to:
  /// **'New Focus Session'**
  String get newFocusSession;

  /// Tooltip for refresh stats button
  ///
  /// In en, this message translates to:
  /// **'Refresh stats'**
  String get refreshStats;

  /// Error message when starting a session fails
  ///
  /// In en, this message translates to:
  /// **'Error starting session: {error}'**
  String errorStartingSession(String error);

  /// Dialog title when daily study limit is reached
  ///
  /// In en, this message translates to:
  /// **'Daily Limit Reached'**
  String get dailyLimitReached;

  /// Dialog body when daily study limit is reached
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your daily study limit — well done! Take a rest and come back tomorrow.'**
  String get dailyLimitReachedBody;

  /// Title shown during break after a focus session
  ///
  /// In en, this message translates to:
  /// **'Break Time!'**
  String get breakTime;

  /// Label showing completed session duration in minutes
  ///
  /// In en, this message translates to:
  /// **'Session completed: {minutes}m'**
  String sessionCompleted(int minutes);

  /// Bottom navigation label for study tab
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get focus;

  /// Button label to start a focus session with specified minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes,plural,=1{Focus for 1 minute} other{Focus for {minutes} minutes}}'**
  String focusForMinutes(int minutes);

  /// Section title for focus time statistics
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTime;

  /// Label indicating remaining time on timer
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get timerRemaining;

  /// Label indicating timer is paused
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get timerPaused;

  /// Label for title sort option
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Label indicating timer is complete
  ///
  /// In en, this message translates to:
  /// **'DONE!'**
  String get timerDone;

  /// Button label to resume a paused timer
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Button label to pause a running timer
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Button label to mark a session as complete
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// CSV section header for overall statistics
  ///
  /// In en, this message translates to:
  /// **'OVERALL STATS'**
  String get csvOverallStats;

  /// CSV section header for topic mastery breakdown
  ///
  /// In en, this message translates to:
  /// **'TOPIC MASTERY'**
  String get csvTopicMastery;

  /// CSV section header for all question attempts
  ///
  /// In en, this message translates to:
  /// **'ALL ATTEMPTS'**
  String get csvAllAttempts;

  /// CSV section header for weekly performance trend
  ///
  /// In en, this message translates to:
  /// **'WEEKLY TREND'**
  String get csvWeeklyTrend;

  /// CSV section header for earned badges
  ///
  /// In en, this message translates to:
  /// **'BADGES'**
  String get csvBadges;

  /// CSV column: total number of attempts
  ///
  /// In en, this message translates to:
  /// **'Total Attempts'**
  String get csvColTotalAttempts;

  /// CSV column: number of correct answers
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get csvColCorrect;

  /// CSV column: accuracy percentage
  ///
  /// In en, this message translates to:
  /// **'Accuracy (%)'**
  String get csvColAccuracy;

  /// CSV column: average time per question in seconds
  ///
  /// In en, this message translates to:
  /// **'Avg Time (s)'**
  String get csvColAvgTime;

  /// CSV column: total study hours
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get csvColTotalHours;

  /// CSV column: number of questions answered this week
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get csvColWeeklyActivity;

  /// CSV column: number of questions answered today
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get csvColDailyActivity;

  /// CSV column: number of distinct topics studied
  ///
  /// In en, this message translates to:
  /// **'Topics Studied'**
  String get csvColTopicsStudied;

  /// CSV column: topic identifier
  ///
  /// In en, this message translates to:
  /// **'Topic ID'**
  String get csvColTopicId;

  /// CSV column: mastery level label for a topic
  ///
  /// In en, this message translates to:
  /// **'Mastery Level'**
  String get csvColMasteryLevel;

  /// CSV column: date when topic was last practiced
  ///
  /// In en, this message translates to:
  /// **'Last Practiced'**
  String get csvColLastPracticed;

  /// CSV column: review urgency score
  ///
  /// In en, this message translates to:
  /// **'Review Urgency'**
  String get csvColReviewUrgency;

  /// CSV column: question identifier
  ///
  /// In en, this message translates to:
  /// **'Question ID'**
  String get csvColQuestionId;

  /// CSV column: subject identifier
  ///
  /// In en, this message translates to:
  /// **'Subject ID'**
  String get csvColSubjectId;

  /// CSV column: time in seconds
  ///
  /// In en, this message translates to:
  /// **'Time (s)'**
  String get csvColTime;

  /// CSV column: timestamp of the event
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get csvColTimestamp;

  /// CSV column: week number/identifier
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get csvColWeek;

  /// CSV column: number of attempts
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get csvColAttempts;

  /// CSV column: improvement percentage over previous period
  ///
  /// In en, this message translates to:
  /// **'Improvement'**
  String get csvColImprovement;

  /// CSV column: name of the badge
  ///
  /// In en, this message translates to:
  /// **'Badge Name'**
  String get csvColBadgeName;

  /// CSV column: description of the badge
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get csvColBadgeDescription;

  /// CSV column: date when badge was unlocked
  ///
  /// In en, this message translates to:
  /// **'Date Unlocked'**
  String get csvColDateUnlocked;

  /// Title for the PDF progress report document
  ///
  /// In en, this message translates to:
  /// **'StudyKing Progress Report'**
  String get pdfProgressReport;

  /// Generated date label in PDF report
  ///
  /// In en, this message translates to:
  /// **'Generated: {date}'**
  String pdfGenerated(String date);

  /// Student ID label in PDF report
  ///
  /// In en, this message translates to:
  /// **'Student ID: {id}'**
  String pdfStudentId(String id);

  /// Section heading for overall statistics in PDF
  ///
  /// In en, this message translates to:
  /// **'Overall Statistics'**
  String get pdfOverallStatistics;

  /// Table column header for metric name in PDF
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get pdfMetric;

  /// Table column header for metric value in PDF
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get pdfValue;

  /// Section heading for topic mastery breakdown in PDF
  ///
  /// In en, this message translates to:
  /// **'Topic Mastery Breakdown'**
  String get pdfTopicMasteryBreakdown;

  /// Table column header for number of attempts in PDF
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get pdfTableAttempts;

  /// Table column header for mastery level in PDF
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get pdfTableLevel;

  /// Table column header for topic name in PDF
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get pdfTableTopic;

  /// Section heading for badges earned in PDF
  ///
  /// In en, this message translates to:
  /// **'Badges Earned'**
  String get pdfBadgesEarned;

  /// Section heading for recent activity summary in PDF
  ///
  /// In en, this message translates to:
  /// **'Recent Activity Summary'**
  String get pdfRecentActivitySummary;

  /// Empty state message when no mastery data is available in PDF
  ///
  /// In en, this message translates to:
  /// **'No mastery data available yet.'**
  String get pdfNoMasteryData;

  /// Empty state message when no badges have been earned in PDF
  ///
  /// In en, this message translates to:
  /// **'No badges earned yet. Keep studying!'**
  String get pdfNoBadges;

  /// Total attempts recorded count in PDF
  ///
  /// In en, this message translates to:
  /// **'Total attempts recorded: {count}'**
  String pdfTotalAttemptsRecorded(int count);

  /// Date range in PDF report
  ///
  /// In en, this message translates to:
  /// **'Date range: {start} to {end}'**
  String pdfDateRange(String start, String end);

  /// Correct answers fraction in PDF
  ///
  /// In en, this message translates to:
  /// **'Correct: {correct}/{total}'**
  String pdfCorrectFraction(int correct, int total);

  /// Heading for empty dashboard getting started checklist
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// Subtitle for empty dashboard checklist
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to get the most out of StudyKing'**
  String get gettingStartedDesc;

  /// Description for add subject checklist item
  ///
  /// In en, this message translates to:
  /// **'Create your first subject to organize your study material'**
  String get addSubjectDesc;

  /// Label for uploading study materials
  ///
  /// In en, this message translates to:
  /// **'Upload Study Material'**
  String get uploadMaterial;

  /// Button label to upload and auto-generate questions
  ///
  /// In en, this message translates to:
  /// **'Upload & Analyze'**
  String get uploadAndAnalyze;

  /// Description for upload material checklist item
  ///
  /// In en, this message translates to:
  /// **'Upload PDFs, notes, and question banks to get started'**
  String get uploadMaterialDesc;

  /// Checklist item for taking first practice quiz
  ///
  /// In en, this message translates to:
  /// **'Take Your First Practice Quiz'**
  String get takePracticeQuiz;

  /// Description for practice quiz checklist item
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge with adaptive practice questions'**
  String get takePracticeQuizDesc;

  /// Checklist item for scheduling AI tutor
  ///
  /// In en, this message translates to:
  /// **'Schedule an AI Tutor Session'**
  String get scheduleAiTutor;

  /// Description for AI tutor checklist item
  ///
  /// In en, this message translates to:
  /// **'Get personalized one-on-one tutoring with AI'**
  String get scheduleAiTutorDesc;

  /// Badge label for the next incomplete step in the getting started checklist
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// Snackbar message when topics are auto-created from seed data
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 topic auto-created from curriculum} other{{count} topics auto-created from curriculum}}'**
  String topicsAutoCreated(int count);

  /// Snackbar message when file is saved
  ///
  /// In en, this message translates to:
  /// **'File saved successfully'**
  String get fileSaved;

  /// Snackbar message when file is shared
  ///
  /// In en, this message translates to:
  /// **'File shared successfully'**
  String get fileShared;

  /// Empty state message when no badges earned
  ///
  /// In en, this message translates to:
  /// **'No achievements yet. Keep studying!'**
  String get noBadgesYet;

  /// Message when a multiple choice question has no options
  ///
  /// In en, this message translates to:
  /// **'No options available'**
  String get noOptionsAvailable;

  /// Section title for subject progress in planner
  ///
  /// In en, this message translates to:
  /// **'Subject Progress'**
  String get subjectProgress;

  /// Section title for pending actions in planner
  ///
  /// In en, this message translates to:
  /// **'Pending Actions'**
  String get pendingActions;

  /// Section title for scheduled lessons in planner
  ///
  /// In en, this message translates to:
  /// **'Scheduled Lessons'**
  String get scheduledLessons;

  /// Button label to regenerate study plan
  ///
  /// In en, this message translates to:
  /// **'Regenerate Plan'**
  String get regeneratePlan;

  /// Button to view all scheduled lessons
  ///
  /// In en, this message translates to:
  /// **'View All Lessons'**
  String get viewAllLessons;

  /// Button label to change date/time
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Button label while scheduling a lesson
  ///
  /// In en, this message translates to:
  /// **'Scheduling...'**
  String get scheduling;

  /// Tooltip for accept action
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Action title for scheduling a lesson
  ///
  /// In en, this message translates to:
  /// **'Schedule a lesson'**
  String get scheduleALesson;

  /// Action title for rescheduling a lesson
  ///
  /// In en, this message translates to:
  /// **'Reschedule lesson'**
  String get rescheduleLesson;

  /// Action title for plan adjustment suggestion
  ///
  /// In en, this message translates to:
  /// **'Plan adjustment suggested'**
  String get planAdjustmentTitle;

  /// Fallback action title
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get actionNeeded;

  /// Error message when something goes wrong
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Button to open the study planner
  ///
  /// In en, this message translates to:
  /// **'Open Planner'**
  String get openPlanner;

  /// Section title for study plan overview in dashboard
  ///
  /// In en, this message translates to:
  /// **'Study Plan Overview'**
  String get studyPlanOverview;

  /// Label showing number of additional lessons
  ///
  /// In en, this message translates to:
  /// **'{count} more...'**
  String moreLessonsCount(int count);

  /// Name of the badge earned for answering the first question
  ///
  /// In en, this message translates to:
  /// **'First Step'**
  String get badgeFirstStepName;

  /// Description for the 'first attempt' badge
  ///
  /// In en, this message translates to:
  /// **'Answered your first question!'**
  String get badgeFirstStepDesc;

  /// Name for the 'accuracy gold' badge
  ///
  /// In en, this message translates to:
  /// **'Accuracy Gold'**
  String get badgeAccuracyGoldName;

  /// Description for the 'accuracy gold' badge
  ///
  /// In en, this message translates to:
  /// **'Achieved 90%+ accuracy!'**
  String get badgeAccuracyGoldDesc;

  /// Name for the 'daily streak' badge
  ///
  /// In en, this message translates to:
  /// **'Daily Scholar'**
  String get badgeDailyScholarName;

  /// Description for the 'daily streak' badge
  ///
  /// In en, this message translates to:
  /// **'Studied consistently today!'**
  String get badgeDailyScholarDesc;

  /// Name for the 'ten hours' badge
  ///
  /// In en, this message translates to:
  /// **'Dedicated Learner'**
  String get badgeDedicatedLearnerName;

  /// Description for the 'ten hours' badge
  ///
  /// In en, this message translates to:
  /// **'Studied 10+ hours total!'**
  String get badgeDedicatedLearnerDesc;

  /// Name for the 'week streak' badge
  ///
  /// In en, this message translates to:
  /// **'Weekly Warrior'**
  String get badgeWeeklyWarriorName;

  /// Description for the 'week streak' badge
  ///
  /// In en, this message translates to:
  /// **'Active for a full week!'**
  String get badgeWeeklyWarriorDesc;

  /// General notification channel name
  ///
  /// In en, this message translates to:
  /// **'StudyKing Notifications'**
  String get notifChannelGeneral;

  /// General notification channel description
  ///
  /// In en, this message translates to:
  /// **'General StudyKing notifications'**
  String get notifChannelGeneralDesc;

  /// Revision reminder notification channel name
  ///
  /// In en, this message translates to:
  /// **'Revision Reminders'**
  String get notifChannelRevision;

  /// Wellbeing notification channel name
  ///
  /// In en, this message translates to:
  /// **'Wellbeing Alerts'**
  String get notifChannelWellbeing;

  /// Planning suggestion notification channel name
  ///
  /// In en, this message translates to:
  /// **'Planning Suggestions'**
  String get notifChannelPlanning;

  /// Lesson notification channel name
  ///
  /// In en, this message translates to:
  /// **'Lesson Notifications'**
  String get notifChannelLessons;

  /// Mastery alert notification channel name
  ///
  /// In en, this message translates to:
  /// **'Mastery Alerts'**
  String get notifChannelMastery;

  /// Badge notification channel name
  ///
  /// In en, this message translates to:
  /// **'Badge Notifications'**
  String get notifChannelBadges;

  /// Daily study reminder channel name
  ///
  /// In en, this message translates to:
  /// **'Daily Study Reminders'**
  String get notifChannelDailyReminder;

  /// Daily study reminder channel description
  ///
  /// In en, this message translates to:
  /// **'Daily reminders to study'**
  String get notifChannelDailyReminderDesc;

  /// Title for revision reminder notification
  ///
  /// In en, this message translates to:
  /// **'Time to Review!'**
  String get notifTitleTimeToReview;

  /// Title for overwork warning notification
  ///
  /// In en, this message translates to:
  /// **'Take a Break'**
  String get notifTitleTakeBreak;

  /// Body for overwork warning
  ///
  /// In en, this message translates to:
  /// **'You\'ve studied {hours,plural,=1{1 hour} other{{hours} hours}} today. Remember to rest!'**
  String notifBodyOverwork(int hours);

  /// Title for plan adjustment notification
  ///
  /// In en, this message translates to:
  /// **'Plan Adjustment'**
  String get notifTitlePlanAdjustment;

  /// Body for plan adjustment suggestion
  ///
  /// In en, this message translates to:
  /// **'You\'ve had {days} days of low adherence. Shall we adjust your plan?'**
  String notifBodyPlanAdjustment(int days);

  /// Title for upcoming lesson notification
  ///
  /// In en, this message translates to:
  /// **'Upcoming Lesson'**
  String get notifTitleUpcomingLesson;

  /// Title for low mastery warning notification
  ///
  /// In en, this message translates to:
  /// **'Topics Need Attention'**
  String get notifTitleTopicsNeedAttention;

  /// Body for low mastery warning
  ///
  /// In en, this message translates to:
  /// **'Low mastery detected in: {topics}'**
  String notifBodyLowMastery(String topics);

  /// Title for badge unlock notification
  ///
  /// In en, this message translates to:
  /// **'Badge Unlocked!'**
  String get notifTitleBadgeUnlocked;

  /// Recommendation when accuracy is below 60%
  ///
  /// In en, this message translates to:
  /// **'Your overall accuracy is below 60%. Focus on reviewing fundamental concepts.'**
  String get recommendAccuracyBelow60;

  /// Action recommendation to review basics
  ///
  /// In en, this message translates to:
  /// **'Review basic topics before advancing'**
  String get recommendReviewBasics;

  /// Recommendation when accuracy is above 85%
  ///
  /// In en, this message translates to:
  /// **'Excellent progress! Ready for advanced topics.'**
  String get recommendAccuracyExcellent;

  /// Action recommendation for advanced practice
  ///
  /// In en, this message translates to:
  /// **'Try challenging practice questions'**
  String get recommendChallengingQuestions;

  /// Recommendation when study time is low
  ///
  /// In en, this message translates to:
  /// **'You studied less than 1 hour total. Consistency is key!'**
  String get recommendConsistency;

  /// Action recommendation to set daily goal
  ///
  /// In en, this message translates to:
  /// **'Set a daily study goal of 30 minutes'**
  String get recommendSetDailyGoal;

  /// Recommendation when no weekly activity
  ///
  /// In en, this message translates to:
  /// **'No study activity this week. Get back on track!'**
  String get recommendNoActivity;

  /// Action recommendation for quick review
  ///
  /// In en, this message translates to:
  /// **'Start with a quick 15-minute review session'**
  String get recommendQuickReview;

  /// Recommendation when weak topics exist
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{You have 1 topic that needs improvement. Focus on strengthening this area.} other{You have {count} topics that need improvement. Focus on strengthening these areas.}}'**
  String recommendWeakTopics(int count);

  /// Action recommendation for AI tutor review
  ///
  /// In en, this message translates to:
  /// **'Review weak topics with the AI tutor'**
  String get recommendAiTutor;

  /// Overwork nudge message
  ///
  /// In en, this message translates to:
  /// **'You have studied {hours} hours today. Consider taking a break!'**
  String nudgeOverwork(String hours);

  /// Revision nudge message
  ///
  /// In en, this message translates to:
  /// **'It has been {days} days since you practiced \"{topic}\". Time for a review!'**
  String nudgeRevision(int days, String topic);

  /// Plan adjustment nudge message
  ///
  /// In en, this message translates to:
  /// **'You have had {days} days of low plan adherence. Would you like to adjust your study plan?'**
  String nudgePlanAdjustment(int days);

  /// Reason for prerequisite topics
  ///
  /// In en, this message translates to:
  /// **'Required for dependent topics'**
  String get planReasonRequiredDependent;

  /// Reason for weak performance
  ///
  /// In en, this message translates to:
  /// **'Weak performance'**
  String get planReasonWeakPerformance;

  /// Reason for high forgetting risk
  ///
  /// In en, this message translates to:
  /// **'High forgetting risk'**
  String get planReasonHighForgettingRisk;

  /// Reason for new syllabus topic
  ///
  /// In en, this message translates to:
  /// **'New syllabus topic'**
  String get planReasonNewSyllabusTopic;

  /// Reason related to syllabus goal
  ///
  /// In en, this message translates to:
  /// **'Part of syllabus goal'**
  String get planReasonPartOfGoal;

  /// General review focus label
  ///
  /// In en, this message translates to:
  /// **'General review'**
  String get planFocusGeneralReview;

  /// Weak areas focus label
  ///
  /// In en, this message translates to:
  /// **'Focus on weak areas'**
  String get planFocusWeakAreas;

  /// Practice and review focus label
  ///
  /// In en, this message translates to:
  /// **'Practice and review'**
  String get planFocusPracticeReview;

  /// Rest day focus label
  ///
  /// In en, this message translates to:
  /// **'Rest and review'**
  String get planFocusRestAndReview;

  /// Suggestion to review fundamentals
  ///
  /// In en, this message translates to:
  /// **'Review basic concepts first'**
  String get adapSuggestionFundamentals;

  /// Suggestion for more practice
  ///
  /// In en, this message translates to:
  /// **'More practice questions recommended'**
  String get adapSuggestionMorePractice;

  /// Suggestion for advanced topics
  ///
  /// In en, this message translates to:
  /// **'Ready for advanced topics'**
  String get adapSuggestionAdvancedTopics;

  /// Name of the badge earned for answering 100 questions
  ///
  /// In en, this message translates to:
  /// **'Century Club'**
  String get badgeCenturyClubName;

  /// Description of the Century Club badge
  ///
  /// In en, this message translates to:
  /// **'Answered 100+ questions!'**
  String get badgeCenturyClubDesc;

  /// Weekly digest message summarizing student activity
  ///
  /// In en, this message translates to:
  /// **'Weekly Digest: {weeklyActivity} questions answered, {accuracy}% accuracy, {totalHours} hours studied, {weakCount} weak areas, {badgeCount} badges earned.'**
  String nudgeWeeklyDigest(
    int weeklyActivity,
    int accuracy,
    String totalHours,
    int weakCount,
    int badgeCount,
  );

  /// Body of revision reminder notification
  ///
  /// In en, this message translates to:
  /// **'It\'s been {days} days since you practiced \"{topic}\".'**
  String notificationTimeToReviewBody(int days, String topic);

  /// Body of upcoming lesson reminder notification
  ///
  /// In en, this message translates to:
  /// **'Your lesson \"{lesson}\" starts at {time}'**
  String notificationUpcomingLessonBody(String lesson, String time);

  /// Body of badge unlocked notification
  ///
  /// In en, this message translates to:
  /// **'You earned the \"{badge}\" badge: {description}'**
  String notificationBadgeUnlockedBody(String badge, String description);

  /// Description of the revision reminders channel
  ///
  /// In en, this message translates to:
  /// **'Reminders to review topics that need practice'**
  String get notifChannelRevisionDesc;

  /// Description of the wellbeing alerts channel
  ///
  /// In en, this message translates to:
  /// **'Alerts about study-life balance and overwork'**
  String get notifChannelWellbeingDesc;

  /// Description of the planning suggestions channel
  ///
  /// In en, this message translates to:
  /// **'Suggestions about study plan adjustments'**
  String get notifChannelPlanningDesc;

  /// Description of the lesson notifications channel
  ///
  /// In en, this message translates to:
  /// **'Notifications about upcoming lessons'**
  String get notifChannelLessonsDesc;

  /// Description of the mastery alerts channel
  ///
  /// In en, this message translates to:
  /// **'Alerts about low topic mastery and weak areas'**
  String get notifChannelMasteryDesc;

  /// Description of the badge notifications channel
  ///
  /// In en, this message translates to:
  /// **'Notifications about earned badges and achievements'**
  String get notifChannelBadgesDesc;

  /// Notification channel name for mentor messages
  ///
  /// In en, this message translates to:
  /// **'Mentor Messages'**
  String get notifChannelMentor;

  /// Description of the mentor messages channel
  ///
  /// In en, this message translates to:
  /// **'Proactive mentor check-ins and nudges'**
  String get notifChannelMentorDesc;

  /// Notification body when a lesson is ready
  ///
  /// In en, this message translates to:
  /// **'{topicTitle} has a lesson ready'**
  String lessonReadyBody(String topicTitle);

  /// Explanation when topic accuracy is below 60 percent
  ///
  /// In en, this message translates to:
  /// **'Accuracy is below 60% — needs focused practice'**
  String get planAccuracyLow;

  /// Explanation when review is overdue and forgetting risk is high
  ///
  /// In en, this message translates to:
  /// **'Review is overdue — forgetting risk is high'**
  String get planReviewOverdue;

  /// Explanation when current streak is low
  ///
  /// In en, this message translates to:
  /// **'Streak is low — consistency needed'**
  String get planStreakLow;

  /// Explanation when topic is a prerequisite for other topics
  ///
  /// In en, this message translates to:
  /// **'Prerequisite for upcoming topics — must master first'**
  String get planPrerequisite;

  /// Explanation when topic blocks downstream topics
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{Blocks 1 downstream topic} other{Blocks {count} downstream topics}}'**
  String planBlocksDownstream(int count);

  /// Reason label for prerequisite topics
  ///
  /// In en, this message translates to:
  /// **'Required for dependent topics'**
  String get planRequiredForDependent;

  /// Reason label for topics with weak performance
  ///
  /// In en, this message translates to:
  /// **'Weak performance'**
  String get planWeakPerformance;

  /// Reason label for topics with high forgetting risk
  ///
  /// In en, this message translates to:
  /// **'High forgetting risk'**
  String get planHighForgettingRisk;

  /// Reason label for new syllabus topics
  ///
  /// In en, this message translates to:
  /// **'New syllabus topic'**
  String get planNewSyllabusTopic;

  /// Explanation for syllabus goal topic inclusion
  ///
  /// In en, this message translates to:
  /// **'Part of syllabus goal'**
  String get planPartOfSyllabusGoal;

  /// Recommendation reason for high mastery topics
  ///
  /// In en, this message translates to:
  /// **'High mastery — ready to advance'**
  String get planHighMastery;

  /// Recommendation reason for topics with good progress
  ///
  /// In en, this message translates to:
  /// **'Good progress — maintain consistency'**
  String get planGoodProgress;

  /// Recommendation reason for developing topics
  ///
  /// In en, this message translates to:
  /// **'Developing — needs more practice'**
  String get planDeveloping;

  /// Recommendation reason for at-risk topics
  ///
  /// In en, this message translates to:
  /// **'At risk — review overdue'**
  String get planAtRisk;

  /// Recommendation reason for topics needing attention
  ///
  /// In en, this message translates to:
  /// **'Needs attention — focus on fundamentals'**
  String get planNeedsAttention;

  /// Focus label for rest days
  ///
  /// In en, this message translates to:
  /// **'Rest and review'**
  String get planRestAndReview;

  /// Focus label when no priority topics are scheduled
  ///
  /// In en, this message translates to:
  /// **'General review'**
  String get planGeneralReview;

  /// Default focus label for study plans
  ///
  /// In en, this message translates to:
  /// **'Practice and review'**
  String get planPracticeAndReview;

  /// Message shown when adherence is low for many days, suggesting mentor consultation
  ///
  /// In en, this message translates to:
  /// **'You have had {days} consecutive days of low adherence. Consider adjusting your study plan or discussing with your mentor.'**
  String adherenceLowDaysAdjust(int days);

  /// Message shown when adherence is low, suggesting plan regeneration
  ///
  /// In en, this message translates to:
  /// **'You have had {days} consecutive days of low adherence. Would you like to regenerate your plan with adjusted targets?'**
  String adherenceLowDaysRegenerate(int days);

  /// Share text when sharing study session files
  ///
  /// In en, this message translates to:
  /// **'Study Sessions'**
  String get shareSessionsText;

  /// Section title for summary card on dashboard
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Label when there is no daily cap set
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// Subtitle for focus timer settings tile
  ///
  /// In en, this message translates to:
  /// **'Start a focused study session'**
  String get focusTimerDescription;

  /// Tile title for daily study cap setting
  ///
  /// In en, this message translates to:
  /// **'Daily Study Cap'**
  String get dailyStudyCap;

  /// Section title for token usage summary
  ///
  /// In en, this message translates to:
  /// **'Token Usage Summary'**
  String get tokenUsageSummary;

  /// Label for total tokens stat
  ///
  /// In en, this message translates to:
  /// **'Total Tokens'**
  String get totalTokens;

  /// Label for total cost stat
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// Label for failed tasks count
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Label for queued LLM task status
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get llmStatusQueued;

  /// Label for cancelled LLM task status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get llmStatusCancelled;

  /// Hint text for subject ID field in planner
  ///
  /// In en, this message translates to:
  /// **'e.g. sub_physics'**
  String get subjectIdHint;

  /// Message when student is far below daily study target
  ///
  /// In en, this message translates to:
  /// **'You studied {actualMinutes} min today vs {plannedMinutes} min planned. Consider redistributing the remaining workload.'**
  String adherenceLowToday(int actualMinutes, int plannedMinutes);

  /// Message when student partially meets daily study target
  ///
  /// In en, this message translates to:
  /// **'You studied {actualMinutes} min today vs {plannedMinutes} min planned. Try to catch up with the remaining topics.'**
  String adherencePartialToday(int actualMinutes, int plannedMinutes);

  /// Message when student exceeds daily study target
  ///
  /// In en, this message translates to:
  /// **'Great work! You studied {actualMinutes} min vs {plannedMinutes} min planned.'**
  String adherenceExceededToday(int actualMinutes, int plannedMinutes);

  /// Label showing overtime duration in minutes
  ///
  /// In en, this message translates to:
  /// **'+{minutes}m'**
  String overtimeLabel(int minutes);

  /// Comma-separated list of keywords indicating a correct answer
  ///
  /// In en, this message translates to:
  /// **'correct,right,yes,got it,understood,i see,that makes sense,true,exactly'**
  String get correctAnswerKeywords;

  /// Comma-separated list of keywords indicating an incorrect answer
  ///
  /// In en, this message translates to:
  /// **'wrong,incorrect,not sure,confused,don\'t know,don\'t understand,no,mistake,error'**
  String get incorrectAnswerKeywords;

  /// Comma-separated list of keywords indicating an exercise request
  ///
  /// In en, this message translates to:
  /// **'exercise,practice,question,quiz,problem,test me,challenge,example'**
  String get exerciseKeywords;

  /// Error message when a lesson time conflicts with an existing scheduled lesson
  ///
  /// In en, this message translates to:
  /// **'Time conflict with existing scheduled lesson'**
  String get timeConflict;

  /// Success message when plan is generated
  ///
  /// In en, this message translates to:
  /// **'Plan generated successfully'**
  String get planGeneratedSuccessfully;

  /// Success message when syllabus-based plan is generated
  ///
  /// In en, this message translates to:
  /// **'Syllabus-based plan generated successfully'**
  String get syllabusPlanGenerated;

  /// Error message when syllabus plan generation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate syllabus plan'**
  String get failedToGenerateSyllabusPlan;

  /// Error message when roadmap creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create roadmap'**
  String get failedToCreateRoadmap;

  /// Error message when milestone update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update milestone'**
  String get failedToUpdateMilestone;

  /// Success message when roadmap is created
  ///
  /// In en, this message translates to:
  /// **'Roadmap \"{goal}\" created!'**
  String roadmapCreated(String goal);

  /// Snackbar when roadmap is deleted
  ///
  /// In en, this message translates to:
  /// **'Roadmap deleted'**
  String get roadmapDeleted;

  /// Confirmation dialog for roadmap deletion
  ///
  /// In en, this message translates to:
  /// **'Delete this roadmap?'**
  String get roadmapDeleteConfirm;

  /// Success message when roadmap is updated
  ///
  /// In en, this message translates to:
  /// **'Roadmap updated'**
  String get roadmapUpdated;

  /// Success message when milestone is toggled
  ///
  /// In en, this message translates to:
  /// **'Milestone updated'**
  String get milestoneUpdated;

  /// Validation error for numeric input
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// Success message when action is accepted
  ///
  /// In en, this message translates to:
  /// **'Action accepted'**
  String get actionAccepted;

  /// Error message when action execution fails due to missing parameters
  ///
  /// In en, this message translates to:
  /// **'Failed to execute action — missing parameters'**
  String get failedToExecuteAction;

  /// Error message when accepting action fails
  ///
  /// In en, this message translates to:
  /// **'Failed to accept action'**
  String get failedToAcceptAction;

  /// Error message when dismissing action fails
  ///
  /// In en, this message translates to:
  /// **'Failed to dismiss action'**
  String get failedToDismissAction;

  /// Success message when lesson is scheduled
  ///
  /// In en, this message translates to:
  /// **'Lesson scheduled'**
  String get lessonScheduled;

  /// Error message when lesson scheduling fails
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule lesson'**
  String get failedToScheduleLesson;

  /// Success message when plan is regenerated from adherence
  ///
  /// In en, this message translates to:
  /// **'Plan regenerated based on your adherence'**
  String get planRegeneratedFromAdherence;

  /// Error message when plan regeneration fails
  ///
  /// In en, this message translates to:
  /// **'Failed to regenerate plan'**
  String get failedToRegeneratePlan;

  /// Success message when workload is redistributed
  ///
  /// In en, this message translates to:
  /// **'Missed workload redistributed over next 3 days'**
  String get missedWorkloadRedistributed;

  /// Error message when workload redistribution fails
  ///
  /// In en, this message translates to:
  /// **'Failed to redistribute workload'**
  String get failedToRedistributeWorkload;

  /// Success message when study pace is adjusted
  ///
  /// In en, this message translates to:
  /// **'Study pace adjusted successfully'**
  String get planAdjusted;

  /// Error message when pace adjustment fails
  ///
  /// In en, this message translates to:
  /// **'Failed to adjust study pace'**
  String get failedToAdjustPlan;

  /// Error message when adding a subject to the plan fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add subject to study plan'**
  String get failedToAddSubjectToPlan;

  /// Title for the progress overview section
  ///
  /// In en, this message translates to:
  /// **'Progress Overview'**
  String get progressOverview;

  /// Title for today's progress section
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// Label for weekly view
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Label for actual (real) values
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actual;

  /// Label for planned values
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// Empty state message when no study plan exists
  ///
  /// In en, this message translates to:
  /// **'No study plan yet'**
  String get noStudyPlanYet;

  /// Tab label for calendar view
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Button label to redistribute workload
  ///
  /// In en, this message translates to:
  /// **'Redistribute'**
  String get redistribute;

  /// Pluralized topic count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 topic} other{{count} topics}}'**
  String topicCount(int count);

  /// Milestone description when syllabus is linked
  ///
  /// In en, this message translates to:
  /// **'Topics: {count} syllabus topics'**
  String syllabusTopics(int count);

  /// Assessment criteria for milestone completion
  ///
  /// In en, this message translates to:
  /// **'Mastery >= 80% on all milestone topics'**
  String get masteryRequirement;

  /// Error message when no topics are found for a subject
  ///
  /// In en, this message translates to:
  /// **'No topics found for subject {subjectId}'**
  String noTopicsFoundForSubject(String subjectId);

  /// Error message when syllabus resolution fails
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve syllabus: {error}'**
  String failedToResolveSyllabus(String error);

  /// Error message when getting questions for a topic fails
  ///
  /// In en, this message translates to:
  /// **'Failed to get questions for topic: {error}'**
  String failedToGetQuestionsForTopic(String error);

  /// Error message when getting questions for topics fails
  ///
  /// In en, this message translates to:
  /// **'Failed to get questions for topics: {error}'**
  String failedToGetQuestionsForTopics(String error);

  /// Error message when file picker fails
  ///
  /// In en, this message translates to:
  /// **'File picker error: {error}'**
  String filePickerError(String error);

  /// Success message when URL content is fetched
  ///
  /// In en, this message translates to:
  /// **'URL content fetched successfully'**
  String get urlFetchSuccess;

  /// Error message when URL fetch fails
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch URL: {error}'**
  String urlFetchFailed(String error);

  /// Error message for URL fetch exception
  ///
  /// In en, this message translates to:
  /// **'URL fetch error: {error}'**
  String urlFetchError(String error);

  /// Chip label for file upload mode
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// Button label to fetch and scrape URL content
  ///
  /// In en, this message translates to:
  /// **'Fetch & Scrape'**
  String get fetchAndScrape;

  /// Hours abbreviation with formatted number
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String hoursAbbreviation(String hours);

  /// Token count label with formatted number
  ///
  /// In en, this message translates to:
  /// **'{count} tokens'**
  String tokensLabel(String count);

  /// Usage record format with date, cost, and cost per token
  ///
  /// In en, this message translates to:
  /// **'{date}: {cost}, cost/tk: {costPerToken}'**
  String usageRecordFormat(String date, String cost, String costPerToken);

  /// Summary of total usage statistics
  ///
  /// In en, this message translates to:
  /// **'Usage: {totalCost} over {totalTokens} tokens, avg: {avgCost} per 1k tokens'**
  String usageSummary(String totalCost, String totalTokens, String avgCost);

  /// Semantic hint for expanding a card section
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get tapToExpand;

  /// Semantic hint for collapsing a card section
  ///
  /// In en, this message translates to:
  /// **'Tap to collapse'**
  String get tapToCollapse;

  /// Hint text below chat input field
  ///
  /// In en, this message translates to:
  /// **'Press Enter to send, Ctrl+Enter for new line'**
  String get sendHint;

  /// Share text for progress report CSV
  ///
  /// In en, this message translates to:
  /// **'StudyKing Progress Report'**
  String get shareProgressReport;

  /// Share text for session history CSV
  ///
  /// In en, this message translates to:
  /// **'StudyKing Session History'**
  String get shareSessionHistory;

  /// Share text for instrumentation data export
  ///
  /// In en, this message translates to:
  /// **'StudyKing Instrumentation Data'**
  String get shareInstrumentationData;

  /// Header for instrumentation dashboard export
  ///
  /// In en, this message translates to:
  /// **'=== Instrumentation Dashboard ==='**
  String get instrumentationDashboard;

  /// Generated timestamp line in instrumentation export
  ///
  /// In en, this message translates to:
  /// **'Generated: {date}'**
  String instrumentationGenerated(String date);

  /// Section header for plan adherence in instrumentation export
  ///
  /// In en, this message translates to:
  /// **'--- Plan Adherence ---'**
  String get instrumentationPlanAdherence;

  /// Section header for mastery improvement in instrumentation export
  ///
  /// In en, this message translates to:
  /// **'--- Mastery Improvement ---'**
  String get instrumentationMasteryImprovement;

  /// Accessibility label for partially correct evaluation
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialLabel;

  /// Label for English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEn;

  /// Label for Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get localeEs;

  /// Onboarding dialog title
  ///
  /// In en, this message translates to:
  /// **'Welcome to StudyKing'**
  String get welcomeToStudyKing;

  /// Onboarding description
  ///
  /// In en, this message translates to:
  /// **'Your AI-native learning companion. StudyKing helps you master any subject with intelligent planning, adaptive practice, and AI tutoring.'**
  String get onboardingDescription;

  /// Subjects tab description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Add and organize your subjects and topics'**
  String get onboardingSubjectsDesc;

  /// Practice tab description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Practice with adaptive questions and spaced repetition'**
  String get onboardingPracticeDesc;

  /// Mentor tab description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Get personalized study recommendations and nudges'**
  String get onboardingMentorDesc;

  /// Study hub description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Quick practice hub with timer — practice questions and track focus'**
  String get onboardingFocusDesc;

  /// Settings tab description in onboarding
  ///
  /// In en, this message translates to:
  /// **'Configure API keys, appearance, and preferences'**
  String get onboardingSettingsDesc;

  /// Checkbox label to suppress recurring dialog
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get dontShowAgain;

  /// API key notice in onboarding
  ///
  /// In en, this message translates to:
  /// **'Note: AI features require an API key. Configure one in Settings.'**
  String get needApiKeyNotice;

  /// Main CTA button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// API key banner message
  ///
  /// In en, this message translates to:
  /// **'StudyKing needs an API key to use AI features. Configure one now.'**
  String get apiKeyNeeded;

  /// Button to configure API key
  ///
  /// In en, this message translates to:
  /// **'Configure Now'**
  String get configureNow;

  /// Data storage notice title
  ///
  /// In en, this message translates to:
  /// **'Local Data Storage'**
  String get dataStorageNotice;

  /// Data storage explanation
  ///
  /// In en, this message translates to:
  /// **'StudyKing stores all your data locally on this device. To avoid data loss, use the Backup & Restore feature in Settings (Settings > Backup & Restore).'**
  String get dataStorageDescription;

  /// Tooltip for visibility toggle button
  ///
  /// In en, this message translates to:
  /// **'Toggle visibility'**
  String get toggleVisibility;

  /// Tooltip for more options button
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Acknowledgement button
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// Message when AI Tutor is accessed without a subject context
  ///
  /// In en, this message translates to:
  /// **'Please create a subject and study plan first before using the AI Tutor. The tutor needs a topic context to provide effective lessons.'**
  String get tutorNeedsSubject;

  /// Title for AI task monitor / token usage screen
  ///
  /// In en, this message translates to:
  /// **'AI Task Monitor'**
  String get aiTaskMonitor;

  /// Subtitle for AI tasks monitoring tile in settings
  ///
  /// In en, this message translates to:
  /// **'View active AI inference tasks and token usage'**
  String get viewActiveAiTasks;

  /// Subtitle for AI tasks tile when there are no active tasks
  ///
  /// In en, this message translates to:
  /// **'No active AI tasks'**
  String get noActiveAiTasks;

  /// Snackbar message when user tries to practice without subjects
  ///
  /// In en, this message translates to:
  /// **'Add a subject first to start practicing'**
  String get addSubjectFirst;

  /// Error message when subjects fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load subjects'**
  String get failedToLoadSubjects;

  /// Message shown when user has too few attempts to determine weak areas
  ///
  /// In en, this message translates to:
  /// **'Need at least {minAttempts} attempted questions for {subjectName} to identify weak areas'**
  String insufficientAttemptsForWeakAreas(String subjectName, int minAttempts);

  /// Confirmation dialog text when ending a lesson
  ///
  /// In en, this message translates to:
  /// **'End your lesson? Your progress will be saved.'**
  String get endLessonConfirmation;

  /// Button to dismiss end lesson dialog and continue the lesson
  ///
  /// In en, this message translates to:
  /// **'Continue Lesson'**
  String get continueLesson;

  /// Confirmation text when user presses back during a lesson
  ///
  /// In en, this message translates to:
  /// **'End lesson and save progress?'**
  String get backNavigationConfirm;

  /// Button to discard lesson progress and exit
  ///
  /// In en, this message translates to:
  /// **'Discard and Exit'**
  String get discardAndExit;

  /// Button to save lesson progress and exit
  ///
  /// In en, this message translates to:
  /// **'Save and Exit'**
  String get saveAndExit;

  /// Message shown after lesson is saved successfully
  ///
  /// In en, this message translates to:
  /// **'Your lesson has been saved successfully.'**
  String get lessonSavedMessage;

  /// Confirmation dialog when cancelling a lesson
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this lesson?'**
  String get cancelLessonConfirmation;

  /// Dialog title when an incomplete tutor lesson is found on startup
  ///
  /// In en, this message translates to:
  /// **'Incomplete Lesson Found'**
  String get orphanedSessionFound;

  /// Message shown when an incomplete tutor session is found on startup
  ///
  /// In en, this message translates to:
  /// **'An incomplete lesson on \"{topicTitle}\" from {time} was found. What would you like to do?'**
  String orphanedSessionMessage(String topicTitle, String time);

  /// Semantic label for session progress bar
  ///
  /// In en, this message translates to:
  /// **'Session progress: {current} of {total}'**
  String sessionProgressLabel(int current, int total);

  /// Semantic label for exam progress bar
  ///
  /// In en, this message translates to:
  /// **'Exam progress: {current} of {total}'**
  String examProgressLabel(int current, int total);

  /// Semantic label for decrease duration button
  ///
  /// In en, this message translates to:
  /// **'Decrease duration'**
  String get decreaseDuration;

  /// Semantic label for increase duration button
  ///
  /// In en, this message translates to:
  /// **'Increase duration'**
  String get increaseDuration;

  /// Overwork nudge showing minutes
  ///
  /// In en, this message translates to:
  /// **'You have studied {minutes} minutes today, which exceeds your daily cap of {cap} minutes. Consider taking a break!'**
  String nudgeOverworkMinutes(int minutes, int cap);

  /// Late-night study warning nudge
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{I noticed you had 1 late-night study session. Remember that rest is important for effective learning!} other{I noticed you had {count} late-night study sessions. Remember that rest is important for effective learning!}}'**
  String nudgeLateNight(int count);

  /// Revision reminder nudge
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{You have 1 question approaching its review date. Time for a revision session!} other{You have {count} questions approaching their review date. Time for a revision session!}}'**
  String nudgeRevisionNeeded(int count);

  /// Study streak celebration message
  ///
  /// In en, this message translates to:
  /// **'Congratulations on your {count}-day study streak! Keep up the amazing consistency!'**
  String nudgeStreakDays(int count);

  /// Message when student hasn't studied for 48+ hours
  ///
  /// In en, this message translates to:
  /// **'It has been over 48 hours since your last study session. Is everything okay? Would you like to schedule a short review?'**
  String get nudgeInactive48h;

  /// Nudge after 7+ days of inactivity
  ///
  /// In en, this message translates to:
  /// **'It\'s been {days} days. Let\'s ease back in with a short review session!'**
  String nudgeInactive7d(int days);

  /// Nudge after 14+ days of inactivity
  ///
  /// In en, this message translates to:
  /// **'Welcome back! It\'s been {days} days. Let\'s plan your re-engagement.'**
  String nudgeInactive14d(int days);

  /// Nudge after 30+ days of inactivity
  ///
  /// In en, this message translates to:
  /// **'It\'s been {days} days since your last session. Would you like help creating a personalized return plan?'**
  String nudgeInactive30d(int days);

  /// Welcome back message after absence
  ///
  /// In en, this message translates to:
  /// **'Welcome back! You\'ve been away for {days} days.'**
  String welcomeBackDays(int days);

  /// Title for absence detection banner
  ///
  /// In en, this message translates to:
  /// **'Absence Detected'**
  String get absenceDetectedTitle;

  /// Body for absence detection banner
  ///
  /// In en, this message translates to:
  /// **'You haven\'t used StudyKing in {days} days. How would you like to proceed?'**
  String absenceDetectedBody(int days);

  /// Button to extend study plan
  ///
  /// In en, this message translates to:
  /// **'Extend study plan by {days} days'**
  String extendPlan(int days);

  /// Label for missed lessons
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missedLessonLabel;

  /// Label for stale sessions
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get staleSessionLabel;

  /// Button to catch up after absence
  ///
  /// In en, this message translates to:
  /// **'Catch Up'**
  String get catchUp;

  /// Title for catch-up bottom sheet
  ///
  /// In en, this message translates to:
  /// **'How would you like to catch up?'**
  String get catchUpTitle;

  /// Description for catch-up bottom sheet
  ///
  /// In en, this message translates to:
  /// **'You were away for {days} days. Choose a catch-up strategy:'**
  String catchUpDescription(int days);

  /// Redistribute workload option in catch-up sheet
  ///
  /// In en, this message translates to:
  /// **'Redistribute across remaining days'**
  String get catchUpRedistribute;

  /// Extend plan option in catch-up sheet
  ///
  /// In en, this message translates to:
  /// **'Extend plan by {days} days'**
  String catchUpExtend(int days);

  /// Success message after extending plan
  ///
  /// In en, this message translates to:
  /// **'Study plan extended by {days} days'**
  String planExtended(int days);

  /// Error message when extending plan fails
  ///
  /// In en, this message translates to:
  /// **'Failed to extend study plan'**
  String get failedToExtendPlan;

  /// Error message when catch-up fails
  ///
  /// In en, this message translates to:
  /// **'Failed to process catch-up strategy'**
  String get failedToCatchUp;

  /// Success message after dismissing missed lessons
  ///
  /// In en, this message translates to:
  /// **'Missed lessons dismissed'**
  String get missedDismissed;

  /// Error message when dismissing missed lessons fails
  ///
  /// In en, this message translates to:
  /// **'Failed to dismiss missed lessons'**
  String get failedToDismissMissed;

  /// Button to dismiss all missed lessons
  ///
  /// In en, this message translates to:
  /// **'Dismiss All Missed'**
  String get dismissAllMissed;

  /// Section header for missed lessons with count
  ///
  /// In en, this message translates to:
  /// **'Missed Lessons ({count})'**
  String missedLessonsCount(int count);

  /// Message when scheduling conflicts with existing lesson
  ///
  /// In en, this message translates to:
  /// **'The proposed time ({time}) conflicts with an existing lesson. Suggested free slot: {freeSlot}. Shall I book it there?'**
  String mentorScheduleConflict(String time, String freeSlot);

  /// Success message after scheduling a lesson
  ///
  /// In en, this message translates to:
  /// **'Lesson on \"{topic}\" scheduled for {time} (30 min). You can review or reschedule anytime.'**
  String mentorScheduleSuccess(String topic, String time);

  /// Failure message when lesson cannot be scheduled
  ///
  /// In en, this message translates to:
  /// **'I was unable to schedule the lesson. Please try again or check your planner.'**
  String get mentorScheduleFail;

  /// Result message when a lesson is scheduled via tool
  ///
  /// In en, this message translates to:
  /// **'Lesson scheduled: {topicTitle}'**
  String toolScheduleLessonResult(String topicTitle);

  /// Result message when scheduling fails via tool
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule lesson'**
  String get toolScheduleLessonFail;

  /// Result message when lesson block generation fails via tool
  ///
  /// In en, this message translates to:
  /// **'Failed to generate lesson blocks'**
  String get toolGenerateBlocksFail;

  /// Result message when a plan is created via tool
  ///
  /// In en, this message translates to:
  /// **'Plan created for {course} over {days} days'**
  String toolCreatePlanResult(String course, int days);

  /// Result message when plan creation fails via tool
  ///
  /// In en, this message translates to:
  /// **'Failed to create plan'**
  String get toolCreatePlanFail;

  /// Message when the session to reschedule is not found
  ///
  /// In en, this message translates to:
  /// **'Could not find the lesson to reschedule. It may have already been removed or completed.'**
  String get mentorRescheduleNotFound;

  /// Message when no free slot found for rescheduling
  ///
  /// In en, this message translates to:
  /// **'Unable to find a free slot for rescheduling \"{topic}\". Please check your availability in the planner.'**
  String mentorRescheduleNoFreeSlot(String topic);

  /// Message when rescheduling suggestion is pending
  ///
  /// In en, this message translates to:
  /// **'Suggested rescheduling \"{topic}\" to {time} - pending confirmation stored in repository.'**
  String mentorReschedulePending(String topic, String time);

  /// Prompt asking user to confirm study plan creation
  ///
  /// In en, this message translates to:
  /// **'I can help create a study plan. Would you like me to set up a {days}-day learning roadmap? Please confirm and provide the subject or goal you\'d like to focus on.'**
  String mentorPlanDaysPrompt(int days);

  /// System prompt for lesson plan generation
  ///
  /// In en, this message translates to:
  /// **'You are a curriculum designer creating lesson plans. Respond only with valid JSON.'**
  String get lessonPlanSystemPrompt;

  /// User prompt for lesson plan generation
  ///
  /// In en, this message translates to:
  /// **'You are a knowledgeable AI tutor for {subjectId}. Create a structured lesson plan for the topic \"{topicTitle}\".\n\nThe lesson should be {durationMinutes} minutes long.\n\nReturn a JSON object.'**
  String lessonPlanUserPrompt(
    String subjectId,
    String topicTitle,
    int durationMinutes,
  );

  /// System prompt for AI tutor
  ///
  /// In en, this message translates to:
  /// **'You are an AI tutor for {subjectId} teaching \"{topicTitle}\". Be conversational, warm, and educational.'**
  String tutorSystemPrompt(String subjectId, String topicTitle);

  /// Instruction prompt for AI tutor
  ///
  /// In en, this message translates to:
  /// **'Guidelines:\n- {timeContext}\n- {paceContext}\n- Explain concepts step by step\n- Adapt to the student\'s level\n- Encourage the student always\n- If they answer correctly, accelerate; if struggling, simplify\n- Keep track of the lesson hour - be mindful of time\n- Ask questions to check understanding\n- Never give away answers directly - guide the student\n- Insert inline exercises naturally into the conversation\n- Celebrate correct answers with specific praise\n- For wrong answers, explain why and guide toward the correct reasoning'**
  String tutorInstructionPrompt(String timeContext, String paceContext);

  /// System prompt for lesson summary generation
  ///
  /// In en, this message translates to:
  /// **'You are a tutor writing lesson notes.'**
  String get summarySystemPrompt;

  /// User prompt for lesson summary
  ///
  /// In en, this message translates to:
  /// **'Summarize what was covered in this lesson about \"{topicTitle}\".\nInclude:\n1. Key concepts explained\n2. Questions answered ({exerciseCount} exercises, {correctCount} correct)\n3. Student\'s apparent understanding level (confidence: {confidencePercent}%)\n4. Adaptive pace used ({adaptivePace}x)\n5. Recommendations for next lesson\n\nKeep it concise and constructive.'**
  String summaryUserPrompt(
    String topicTitle,
    int exerciseCount,
    int correctCount,
    int confidencePercent,
    String adaptivePace,
  );

  /// Instruction for LLM to respond in the student's language
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: Respond in the same language as the student (locale: {localeName}). Do not use English unless the student does.'**
  String languageInstruction(String localeName);

  /// System prompt for answer evaluation
  ///
  /// In en, this message translates to:
  /// **'You are an expert academic evaluator. Return only valid JSON.'**
  String get evaluationSystemPrompt;

  /// System prompt for exercise evaluator
  ///
  /// In en, this message translates to:
  /// **'You are an expert academic evaluator. Assess the student\'s answer and return a JSON object with: score (0.0-1.0), explanation, partialCredit (optional), conceptBreakdown (optional map of concept->score). Be fair and encouraging. Consider partial credit for partially correct answers.'**
  String get evaluatorSystemPrompt;

  /// System prompt for content classification
  ///
  /// In en, this message translates to:
  /// **'You are a content classifier. Respond only with the topic name.'**
  String get classifySystemPrompt;

  /// User prompt for content classification
  ///
  /// In en, this message translates to:
  /// **'Classify the following content into one of these topics: {topics}.\n\nContent:\n{content}\n\nReturn only the single most relevant topic name from the list. Do not explain. Do not add extra text.'**
  String classifyUserPrompt(String topics, String content);

  /// System prompt for content summarization
  ///
  /// In en, this message translates to:
  /// **'You are a summarization assistant. Provide concise summaries.'**
  String get summarizeSystemPrompt;

  /// User prompt for content summarization
  ///
  /// In en, this message translates to:
  /// **'Summarize the following content in 3-5 concise sentences.\n\nContent:\n{content}\n\nProvide only the summary text.'**
  String summarizeUserPrompt(String content);

  /// System prompt for question generation
  ///
  /// In en, this message translates to:
  /// **'You are a question generator. Return only valid JSON array.'**
  String get generateQuestionSystemPrompt;

  /// User prompt for question generation
  ///
  /// In en, this message translates to:
  /// **'Analyze the following content and extract any existing questions it contains.\nAlso generate 3-5 new practice questions based on the content.\nReturn ONLY a JSON array of question objects.\nEach object must have: \"text\" (the question), \"type\" (one of: \"singleChoice\", \"multiChoice\", \"typedAnswer\", \"mathExpression\", \"essay\"), \"options\" (list of answer strings, required for singleChoice and multiChoice), \"correctAnswer\" (the correct option text), \"explanation\" (brief explanation).\nFor multiChoice questions, correctAnswer should be the first correct option and include an \"acceptableAnswers\" array with all correct options.\nFor typedAnswer and mathExpression, provide options as an empty list and correctAnswer as the expected answer.\n\nContent:\n{content}'**
  String generateQuestionUserPrompt(String content);

  /// Default system prompt for AI assistant
  ///
  /// In en, this message translates to:
  /// **'You are a helpful AI study assistant called StudyKing. Keep responses concise and educational.'**
  String get aiDefaultSystemPrompt;

  /// System prompt for transcription
  ///
  /// In en, this message translates to:
  /// **'You are a transcription assistant. Transcribe audio/video content accurately.'**
  String get transcribeSystemPrompt;

  /// User prompt for transcription
  ///
  /// In en, this message translates to:
  /// **'Transcribe the following audio/video content.\nReturn only the transcribed text. Preserve the natural language and formatting.\n\nContent: {content}'**
  String transcribeUserPrompt(String content);

  /// System prompt for OCR extraction
  ///
  /// In en, this message translates to:
  /// **'You are an OCR assistant. Extract text from images accurately.'**
  String get ocrSystemPrompt;

  /// User prompt for OCR extraction
  ///
  /// In en, this message translates to:
  /// **'Extract all text visible in this image content.\nReturn only the extracted text, preserving the original formatting as much as possible.\nIf no text is visible, return an empty string.\n\nImage content (base64 or reference): {content}'**
  String ocrUserPrompt(String content);

  /// Error shown when user tries to generate questions without configuring a model
  ///
  /// In en, this message translates to:
  /// **'No AI model is configured. Please go to Settings and select a model provider before generating questions.'**
  String get modelNotConfigured;

  /// Checkbox label to enable question generation during upload
  ///
  /// In en, this message translates to:
  /// **'Generate questions from this content'**
  String get generateQuestionsFromContent;

  /// Hint text for the question generation checkbox
  ///
  /// In en, this message translates to:
  /// **'AI will create practice questions based on the uploaded material'**
  String get generateQuestionsFromContentHint;

  /// Subtitle shown when no questions exist yet
  ///
  /// In en, this message translates to:
  /// **'Upload materials to create questions'**
  String get uploadMaterialsToCreateQuestions;

  /// Hint shown on practice tab when there are no questions
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any practice questions yet. Upload study materials to generate questions.'**
  String get noQuestionsPracticeHint;

  /// Button label to navigate to upload screen
  ///
  /// In en, this message translates to:
  /// **'Upload Materials'**
  String get uploadMaterials;

  /// Label for questions answered today count
  ///
  /// In en, this message translates to:
  /// **'Questions Today'**
  String get questionsToday;

  /// Label for current correct answer streak
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// Label for spaced repetition due count
  ///
  /// In en, this message translates to:
  /// **'Due for Review'**
  String get dueForReview;

  /// Message shown when user has too few attempts to determine weak areas
  ///
  /// In en, this message translates to:
  /// **'Practice at least 10 questions to identify weak areas'**
  String get practiceAtLeastTen;

  /// Message shown when no topics are available yet
  ///
  /// In en, this message translates to:
  /// **'Upload materials to generate topics'**
  String get uploadMaterialsToGenerateTopics;

  /// Title for exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Exit practice session?'**
  String get confirmExitPractice;

  /// Body for exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Your progress in this session will be saved, but you will leave before completing all questions.'**
  String get confirmExitPracticeBody;

  /// Button to stay in current session
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// Button to exit current session
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Message shown when a subject has no questions
  ///
  /// In en, this message translates to:
  /// **'No practice questions found for this subject. Try uploading study materials first.'**
  String get noQuestionsForSubject;

  /// Title for focus session exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'End focus session?'**
  String get confirmExitFocus;

  /// Body for focus session exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'You have an active focus session. Ending it early will save your progress so far.'**
  String get confirmExitFocusBody;

  /// Button to end the current session
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// Label shown for sources that have no generated questions
  ///
  /// In en, this message translates to:
  /// **'0 questions — generate questions from this source'**
  String get sourceWithNoQuestions;

  /// Semantic label for required field indicator
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// Gallery option in image picker
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Required field indicator symbol
  ///
  /// In en, this message translates to:
  /// **'*'**
  String get requiredFieldIndicator;

  /// Label prefix for math expression display
  ///
  /// In en, this message translates to:
  /// **'Expression: '**
  String get expressionLabel;

  /// Default lesson goal text
  ///
  /// In en, this message translates to:
  /// **'Understand the topic'**
  String get defaultLessonGoal;

  /// Default section title for introduction
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get sectionIntroduction;

  /// Default section title for main content
  ///
  /// In en, this message translates to:
  /// **'Main Content'**
  String get sectionMainContent;

  /// Default section title for practice
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get sectionPractice;

  /// Default checkpoint for lesson started
  ///
  /// In en, this message translates to:
  /// **'Lesson started'**
  String get checkpointStarted;

  /// Default checkpoint for topic covered
  ///
  /// In en, this message translates to:
  /// **'Topic covered'**
  String get checkpointTopicCovered;

  /// Default checkpoint for practice completed
  ///
  /// In en, this message translates to:
  /// **'Practice completed'**
  String get checkpointPracticeCompleted;

  /// Column header for session type in PDF export
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sessionType;

  /// Label for practice session type
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get sessionTypePractice;

  /// Label for focus session type
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get sessionTypeFocus;

  /// Label for tutoring session type
  ///
  /// In en, this message translates to:
  /// **'Tutoring'**
  String get sessionTypeTutoring;

  /// Label for manual session type
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sessionTypeManual;

  /// Button label to add a course or subject
  ///
  /// In en, this message translates to:
  /// **'Add Course/Subject'**
  String get addCourseSubject;

  /// Hours per day abbreviation with separator
  ///
  /// In en, this message translates to:
  /// **'{hours}h/day'**
  String hoursPerDayAbbrev(String hours);

  /// Lesson time status with topic and completion marker
  ///
  /// In en, this message translates to:
  /// **'{topicId}, {time}{completedSuffix}'**
  String lessonTimeStatus(String topicId, String time, String completedSuffix);

  /// AppBar title combining practice mode and subject name
  ///
  /// In en, this message translates to:
  /// **'{mode} - {subject}'**
  String practiceModeWithSubject(String mode, String subject);

  /// Full mentor welcome message with greeting and body
  ///
  /// In en, this message translates to:
  /// **'{greeting}\n\n{body}'**
  String mentorWelcomeFull(String greeting, String body);

  /// Fallback when error message is null
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Error message when plan fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load plan: {error}'**
  String failedToLoadPlan(String error);

  /// Error message when backup export fails with details
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup: {error}'**
  String backupExportFailedWithError(String error);

  /// Error message when backup file format is invalid with details
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file: {error}'**
  String invalidBackupFileWithError(String error);

  /// Backup box display name for subjects
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get backupBoxSubjects;

  /// Backup box display name for topics
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get backupBoxTopics;

  /// Backup box display name for questions
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get backupBoxQuestions;

  /// Backup box display name for sources
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get backupBoxSources;

  /// Backup box display name for lessons
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get backupBoxLessons;

  /// Backup box display name for lesson blocks
  ///
  /// In en, this message translates to:
  /// **'Lesson Blocks'**
  String get backupBoxLessonBlocks;

  /// Backup box display name for typed sessions
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get backupBoxSessionsTyped;

  /// Backup box display name for old sessions
  ///
  /// In en, this message translates to:
  /// **'Sessions (old)'**
  String get backupBoxSessions;

  /// Backup box display name for mastery states
  ///
  /// In en, this message translates to:
  /// **'Mastery States'**
  String get backupBoxMasteryStates;

  /// Backup box display name for question mastery
  ///
  /// In en, this message translates to:
  /// **'Question Mastery'**
  String get backupBoxQuestionMasteryStates;

  /// Backup box display name for question evaluations
  ///
  /// In en, this message translates to:
  /// **'Question Evaluations'**
  String get backupBoxQuestionEvaluations;

  /// Backup box display name for learning plans
  ///
  /// In en, this message translates to:
  /// **'Learning Plans'**
  String get backupBoxLearningPlans;

  /// Backup box display name for plan adherence
  ///
  /// In en, this message translates to:
  /// **'Plan Adherence'**
  String get backupBoxPlanAdherence;

  /// Backup box display name for plan metrics
  ///
  /// In en, this message translates to:
  /// **'Plan Metrics'**
  String get backupBoxPlanAdherenceMetrics;

  /// Backup box display name for mastery metrics
  ///
  /// In en, this message translates to:
  /// **'Mastery Metrics'**
  String get backupBoxMasteryImprovementMetrics;

  /// Backup box display name for conversations
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get backupBoxConversations;

  /// Backup box display name for tutor sessions
  ///
  /// In en, this message translates to:
  /// **'Tutor Sessions'**
  String get backupBoxTutorSessions;

  /// Backup box display name for topic dependencies
  ///
  /// In en, this message translates to:
  /// **'Topic Dependencies'**
  String get backupBoxTopicDependencies;

  /// Backup box display name for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get backupBoxSettings;

  /// Backup box display name for profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get backupBoxProfile;

  /// Backup box display name for answers
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get backupBoxAnswers;

  /// Backup box display name for attempts
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get backupBoxAttempts;

  /// Backup box display name for badges
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get backupBoxBadges;

  /// Backup box display name for engagement nudges
  ///
  /// In en, this message translates to:
  /// **'Engagement Nudges'**
  String get backupBoxEngagementNudges;

  /// Backup box display name for focus sessions
  ///
  /// In en, this message translates to:
  /// **'Focus Sessions'**
  String get backupBoxFocusSessions;

  /// Backup box display name for pending actions
  ///
  /// In en, this message translates to:
  /// **'Pending Actions'**
  String get backupBoxPendingActions;

  /// Backup box display name for progress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get backupBoxProgress;

  /// Backup box display name for tasks
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get backupBoxTasks;

  /// Backup box display name for student availability
  ///
  /// In en, this message translates to:
  /// **'Student Availability'**
  String get backupBoxStudentAvailability;

  /// Backup box display name for roadmaps
  ///
  /// In en, this message translates to:
  /// **'Roadmaps'**
  String get backupBoxRoadmaps;

  /// Backup box display name for LLM tasks
  ///
  /// In en, this message translates to:
  /// **'LLM Tasks'**
  String get backupBoxLlmTasks;

  /// Backup box display name for LLM usage records
  ///
  /// In en, this message translates to:
  /// **'LLM Usage Records'**
  String get backupBoxLlmUsageRecords;

  /// Warning when exporting backup with sensitive data included
  ///
  /// In en, this message translates to:
  /// **'Your API keys will be readable as plaintext in the backup file. Anyone with access to this file can use your API keys.'**
  String get apiKeyPlaintextWarning;

  /// Count of boxes in backup summary
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 box} other{{count} boxes}}'**
  String boxCountLabel(int count);

  /// Truncated list indicator showing additional items
  ///
  /// In en, this message translates to:
  /// **'... and {count,plural, =1{1 more} other{{count} more}}'**
  String andMoreCount(int count);

  /// Header for list of items cleared on sign out
  ///
  /// In en, this message translates to:
  /// **'What will be cleared:'**
  String get signOutClearList;

  /// Item in sign-out clear list: API key
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get signOutClearsApiKey;

  /// Item in sign-out clear list: AI model selection
  ///
  /// In en, this message translates to:
  /// **'Selected AI model'**
  String get signOutClearsAiModel;

  /// Reassurance that study data is not deleted on sign out
  ///
  /// In en, this message translates to:
  /// **'Your study data will be preserved.'**
  String get signOutPreservesStudyData;

  /// Checkbox label to clear all study data on sign out
  ///
  /// In en, this message translates to:
  /// **'Clear all study data'**
  String get signOutClearAllData;

  /// Subtitle explaining what clearing data removes
  ///
  /// In en, this message translates to:
  /// **'Removes all subjects, questions, attempts, and progress'**
  String get signOutRemovesAllData;

  /// Checkbox label to back up before clearing data
  ///
  /// In en, this message translates to:
  /// **'Back up before signing out'**
  String get signOutBackupBeforeSignOut;

  /// Subtitle explaining what backing up does
  ///
  /// In en, this message translates to:
  /// **'Creates a backup file before clearing data'**
  String get signOutCreatesBackupFile;

  /// Hint shown after successful data import
  ///
  /// In en, this message translates to:
  /// **'A restart may be needed for all changes to appear.'**
  String get importRestartHint;

  /// Title for student ID mismatch dialog
  ///
  /// In en, this message translates to:
  /// **'Student ID mismatch detected'**
  String get studentIdMismatchTitle;

  /// Body showing current and backup student IDs
  ///
  /// In en, this message translates to:
  /// **'Current: {currentId}\nBackup: {backupId}'**
  String studentIdMismatchBody(String currentId, String backupId);

  /// Question to reconcile student ID mismatch
  ///
  /// In en, this message translates to:
  /// **'Update student records to match current ID?'**
  String get studentIdMismatchAction;

  /// Plural count of available questions
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No questions available} =1{1 question available} other{{count} questions available}}'**
  String questionsCountPlural(int count);

  /// Bullet point prefix for mentor recommendation list items
  ///
  /// In en, this message translates to:
  /// **'• '**
  String get mentorBulletPoint;

  /// Title shown when a route is not found
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// Description shown on the not-found page
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist or the link may be invalid.'**
  String get pageNotFoundDescription;

  /// Button label to navigate to the dashboard
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// Label shown when a message is being sent
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending;

  /// Subtitle for daily reminder toggle
  ///
  /// In en, this message translates to:
  /// **'Get a daily reminder to study at your preferred time'**
  String get dailyReminderDescription;

  /// Tile title for daily reminder time setting
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// Help text for the daily reminder time picker
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder Time'**
  String get dailyReminderTimeHelp;

  /// Button title to run nudge checks immediately
  ///
  /// In en, this message translates to:
  /// **'Check Nudges Now'**
  String get checkNudgesNow;

  /// Subtitle for nudge check button
  ///
  /// In en, this message translates to:
  /// **'Run nudge checks immediately'**
  String get runNudgeChecks;

  /// Snackbar message after successful nudge check
  ///
  /// In en, this message translates to:
  /// **'Nudge check complete'**
  String get nudgeCheckComplete;

  /// Snackbar message after failed nudge check
  ///
  /// In en, this message translates to:
  /// **'Nudge check failed'**
  String get nudgeCheckFailed;

  /// Title for daily cap warning dialog
  ///
  /// In en, this message translates to:
  /// **'Daily Cap Warning'**
  String get dailyCapWarningTitle;

  /// Body for daily cap warning dialog
  ///
  /// In en, this message translates to:
  /// **'Starting this session will exceed your daily cap. {selectedMinutes} min selected, {remaining} min remaining. Continue?'**
  String dailyCapWarningBody(int selectedMinutes, int remaining);

  /// Button to proceed despite warning
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// Help text shown on first visit to focus mode explaining the dual-mode design
  ///
  /// In en, this message translates to:
  /// **'Focus Mode has two modes: Practice (study hub with inline and full practice sessions) and Timer (silent focus timer). Session types (Quick Practice, Spaced Repetition, Weak Areas, Free Focus) affect which questions appear in inline practice. Timer mode is for distraction-free focus without questions. Session stats appear below.'**
  String get focusFirstVisitHelp;

  /// Section title for content management settings
  ///
  /// In en, this message translates to:
  /// **'Content Management'**
  String get contentManagement;

  /// Tile title for uploaded materials
  ///
  /// In en, this message translates to:
  /// **'My Uploads'**
  String get myUploads;

  /// Subtitle for uploads tile
  ///
  /// In en, this message translates to:
  /// **'View your uploaded materials'**
  String get viewMyUploads;

  /// Tile title for question bank
  ///
  /// In en, this message translates to:
  /// **'Question Bank'**
  String get questionBank;

  /// Subtitle for question bank tile
  ///
  /// In en, this message translates to:
  /// **'Browse and manage questions'**
  String get browseAndManageQuestions;

  /// Tile title for failed uploads
  ///
  /// In en, this message translates to:
  /// **'Failed Uploads'**
  String get failedUploads;

  /// Failed upload count message
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 source failed to process} other{{count} sources failed to process}}'**
  String sourceCountFailed(int count);

  /// Message when no failed uploads exist
  ///
  /// In en, this message translates to:
  /// **'No failed uploads'**
  String get noFailedUploads;

  /// Tile title for break duration setting
  ///
  /// In en, this message translates to:
  /// **'Break Duration'**
  String get breakDuration;

  /// Title for session tracking section
  ///
  /// In en, this message translates to:
  /// **'Session Tracking'**
  String get sessionTracking;

  /// Title for manual session tracker
  ///
  /// In en, this message translates to:
  /// **'Manual Session Tracker'**
  String get manualSessionTracker;

  /// Description for manual session tracking
  ///
  /// In en, this message translates to:
  /// **'Track your study sessions manually'**
  String get manualSessionTrackerDescription;

  /// Description for session history
  ///
  /// In en, this message translates to:
  /// **'View your session history'**
  String get sessionHistoryDescription;

  /// Export progress as CSV
  ///
  /// In en, this message translates to:
  /// **'Export Progress CSV'**
  String get exportProgressCsv;

  /// Feature label for ingestion in token usage dialog
  ///
  /// In en, this message translates to:
  /// **'Ingestion'**
  String get featureLabelIngestion;

  /// Feature label for general in token usage dialog
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get featureLabelGeneral;

  /// Title for delete source confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Source'**
  String get deleteSourceTitle;

  /// Body for delete source confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this source?'**
  String get deleteSourceBody;

  /// Title for daily reminder study notification
  ///
  /// In en, this message translates to:
  /// **'Daily Study Reminder'**
  String get dailyReminderNotificationTitle;

  /// Body for daily reminder study notification
  ///
  /// In en, this message translates to:
  /// **'Time to study! You have study tasks planned for today.'**
  String get dailyReminderNotificationBody;

  /// Hint shown in focus timer when no subjects exist yet
  ///
  /// In en, this message translates to:
  /// **'Add subjects in Settings to track focus by subject.'**
  String get addSubjectsForFocusHint;

  /// Button label when retrying an operation
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get retrying;

  /// Snackbar message when subject cannot be resolved for a topic
  ///
  /// In en, this message translates to:
  /// **'Could not find subject for this topic.'**
  String get unableToResolveSubject;

  /// Snackbar message when a question is deleted
  ///
  /// In en, this message translates to:
  /// **'Question deleted'**
  String get questionDeleted;

  /// Title for delete question confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Question'**
  String get deleteQuestion;

  /// Body for delete question confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this question?'**
  String get deleteQuestionConfirm;

  /// Title for delete multiple questions dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Questions'**
  String get deleteQuestions;

  /// Body for delete multiple questions confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} {count, plural, =1{question} other{questions}}?'**
  String deleteQuestionsConfirm(int count);

  /// Snackbar when multiple questions are deleted
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{question} other{questions}} deleted'**
  String questionsDeleted(int count);

  /// Title for edit question dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get editQuestion;

  /// Label for question text input field
  ///
  /// In en, this message translates to:
  /// **'Question text'**
  String get questionText;

  /// Title for the question bank screen
  ///
  /// In en, this message translates to:
  /// **'Question Bank'**
  String get questionBankScreen;

  /// Subtitle for a question item showing type and difficulty
  ///
  /// In en, this message translates to:
  /// **'{questionType} • {difficulty}'**
  String questionSubtitle(String questionType, String difficulty);

  /// Tooltip for cancel selection button
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get cancelSelection;

  /// Tooltip for delete selected button
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// Tooltip for select multiple mode
  ///
  /// In en, this message translates to:
  /// **'Select multiple'**
  String get selectMultiple;

  /// Hint text for question search field
  ///
  /// In en, this message translates to:
  /// **'Search questions'**
  String get searchQuestions;

  /// Filter label showing all subjects
  ///
  /// In en, this message translates to:
  /// **'All subjects'**
  String get allSubjects;

  /// Filter label showing all question types
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allTypes;

  /// Filter label showing all sources
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// LLM pace context when student is doing well
  ///
  /// In en, this message translates to:
  /// **'The student is doing well. Accelerate pace.'**
  String get acceleratePace;

  /// LLM pace context when student is struggling
  ///
  /// In en, this message translates to:
  /// **'The student seems to be struggling. Slow down, simplify explanations, and provide more examples.'**
  String get slowDownPace;

  /// LLM pace context for normal pace
  ///
  /// In en, this message translates to:
  /// **'Maintain a steady teaching pace.'**
  String get maintainPace;

  /// LLM time context for greeting phase
  ///
  /// In en, this message translates to:
  /// **'Start the lesson warmly.'**
  String get greetingContext;

  /// LLM time context for teaching phase
  ///
  /// In en, this message translates to:
  /// **'Teach the concept step by step. Engage the student with questions.'**
  String get teachingContext;

  /// LLM time context for exercise phase
  ///
  /// In en, this message translates to:
  /// **'Give the student a practice question to assess understanding.'**
  String get exerciseContext;

  /// LLM time context for feedback phase
  ///
  /// In en, this message translates to:
  /// **'Provide constructive feedback on their answer.'**
  String get feedbackContext;

  /// LLM time context for adaptive review phase
  ///
  /// In en, this message translates to:
  /// **'The student needs extra help. Re-explain the concept more simply. Use different examples.'**
  String get adaptiveReviewContext;

  /// LLM time context for closing phase
  ///
  /// In en, this message translates to:
  /// **'Wrap up the lesson. Summarize key points.'**
  String get closingContext;

  /// Introduction for the evaluation prompt template
  ///
  /// In en, this message translates to:
  /// **'Evaluate this student answer for the subject \"{subjectId}\" on topic \"{topicTitle}\".\n\nQuestion: {question}\n\nStudent Answer: {studentAnswer}\n\nReturn a JSON object with:'**
  String evaluateStudentAnswerIntro(
    String subjectId,
    String topicTitle,
    String question,
    String studentAnswer,
  );

  /// JSON template description for score field in evaluation prompt
  ///
  /// In en, this message translates to:
  /// **'<0.0 to 1.0>'**
  String get evalScoreDesc;

  /// JSON template description for explanation field in evaluation prompt
  ///
  /// In en, this message translates to:
  /// **'<detailed feedback explaining what was correct/incorrect>'**
  String get evalExplanationDesc;

  /// JSON template description for partial credit field in evaluation prompt
  ///
  /// In en, this message translates to:
  /// **'<optional 0.0-1.0 for partially correct parts>'**
  String get evalPartialCreditDesc;

  /// JSON template description for concept breakdown field in evaluation prompt
  ///
  /// In en, this message translates to:
  /// **'<optional map of concept name to mastery score 0.0-1.0>'**
  String get evalConceptBreakdownDesc;

  /// JSON template description for correct answer field in evaluation prompt
  ///
  /// In en, this message translates to:
  /// **'<the correct answer to the exercise question>'**
  String get evalCorrectAnswerDesc;

  /// JSON template description for type field in evaluation prompt
  ///
  /// In en, this message translates to:
  /// **'<question type: typedAnswer|singleChoice|multiChoice|essay|mathExpression>'**
  String get evalTypeDesc;

  /// JSON template description for options field in evaluation prompt
  ///
  /// In en, this message translates to:
  /// **'<for singleChoice/multiChoice, list of answer options; otherwise empty>'**
  String get evalOptionsDesc;

  /// Semantics label for minutes in focus timer
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{minute} other{minutes}}'**
  String minutesSemantics(int count);

  /// Semantics label for break remaining time
  ///
  /// In en, this message translates to:
  /// **'Break remaining {formattedTime}'**
  String breakRemainingLabel(String formattedTime);

  /// Generic loading indicator label
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Status label for pending processing
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Status label for extracting text
  ///
  /// In en, this message translates to:
  /// **'Extracting'**
  String get extracting;

  /// Status label for processing data
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// Status label for generating summary
  ///
  /// In en, this message translates to:
  /// **'Summarizing'**
  String get summarizing;

  /// Status label for generating questions
  ///
  /// In en, this message translates to:
  /// **'Generating Questions'**
  String get generatingQuestions;

  /// App bar title for content library screen
  ///
  /// In en, this message translates to:
  /// **'Content Library'**
  String get contentLibrary;

  /// Tooltip for sort order toggle
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get sortOrder;

  /// Tooltip for sort menu
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Filter label showing all statuses
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// Snackbar message when a source is deleted
  ///
  /// In en, this message translates to:
  /// **'Source deleted'**
  String get sourceDeleted;

  /// Checkbox label to delete associated questions with source
  ///
  /// In en, this message translates to:
  /// **'Also delete questions generated from this source'**
  String get alsoDeleteQuestions;

  /// Button label to reprocess a source
  ///
  /// In en, this message translates to:
  /// **'Reprocess'**
  String get reprocess;

  /// Label showing number of sources with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source} other{{count} sources}}'**
  String sourcesCount(int count);

  /// Error message when source is not found
  ///
  /// In en, this message translates to:
  /// **'Source not found'**
  String get sourceNotFound;

  /// Error message when loading source fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading the source. Please try again.'**
  String get errorLoadingSource;

  /// Error message when loading source fails, with error detail
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading the source: {error}'**
  String errorLoadingSourceWithDetail(String error);

  /// Dialog title for source reprocessing
  ///
  /// In en, this message translates to:
  /// **'Reprocess Source'**
  String get reprocessSource;

  /// Warning body for source reprocessing dialog
  ///
  /// In en, this message translates to:
  /// **'Reprocessing will replace existing generated questions. Continue?'**
  String get reprocessingWarning;

  /// Status label during reprocessing
  ///
  /// In en, this message translates to:
  /// **'Reprocessing...'**
  String get reprocessing;

  /// App bar title for source detail screen
  ///
  /// In en, this message translates to:
  /// **'Source Detail'**
  String get sourceDetail;

  /// Label for status field
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Label for subject field
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// Label for ID field
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// Label for upload date field
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// Error banner text when processing fails
  ///
  /// In en, this message translates to:
  /// **'Processing failed'**
  String get processingFailed;

  /// Section header for topic classification
  ///
  /// In en, this message translates to:
  /// **'Topic Classification'**
  String get topicClassification;

  /// Label when source has no topic classification
  ///
  /// In en, this message translates to:
  /// **'Not yet classified'**
  String get notYetClassified;

  /// Button to classify source topic
  ///
  /// In en, this message translates to:
  /// **'Classify Now'**
  String get classifyNow;

  /// Section header for summary
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summarySection;

  /// Placeholder when no summary exists
  ///
  /// In en, this message translates to:
  /// **'No summary available'**
  String get noSummaryAvailable;

  /// Section header for extracted text
  ///
  /// In en, this message translates to:
  /// **'Extracted Text'**
  String get extractedText;

  /// Section header for extracted text with character count
  ///
  /// In en, this message translates to:
  /// **'Extracted Text ({count})'**
  String extractedTextCount(int count);

  /// Hint text for searching within extracted text
  ///
  /// In en, this message translates to:
  /// **'Search in text'**
  String get searchInText;

  /// Placeholder when no extracted text exists
  ///
  /// In en, this message translates to:
  /// **'No extracted text available'**
  String get noExtractedText;

  /// Section header for generated questions
  ///
  /// In en, this message translates to:
  /// **'Generated Questions'**
  String get generatedQuestions;

  /// Section header for generated questions with count
  ///
  /// In en, this message translates to:
  /// **'Generated Questions ({count})'**
  String generatedQuestionsCount(int count);

  /// Placeholder when source has no questions
  ///
  /// In en, this message translates to:
  /// **'No questions from this source'**
  String get noQuestionsFromSource;

  /// Label for difficulty level
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// Edit action label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Label for AI-generated content
  ///
  /// In en, this message translates to:
  /// **'AI-generated'**
  String get aiGenerated;

  /// Label for manually created content
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// Tab label for sources
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// Semantic label for view sources action
  ///
  /// In en, this message translates to:
  /// **'View Sources'**
  String get viewSources;

  /// Empty state for subject sources tab
  ///
  /// In en, this message translates to:
  /// **'No sources for this subject'**
  String get noSourcesForSubject;

  /// Card title for remaining workload section
  ///
  /// In en, this message translates to:
  /// **'Remaining Workload'**
  String get remainingWorkload;

  /// Label for explanation input field
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// Label showing number of sources with capital S
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Source} other{{count} Sources}}'**
  String sourcesCountLabel(int count);

  /// Title for difficulty tier selection in exam config
  ///
  /// In en, this message translates to:
  /// **'Difficulty Distribution'**
  String get difficultyDistribution;

  /// Hint for difficulty distribution controls
  ///
  /// In en, this message translates to:
  /// **'Set the number of Easy, Medium, and Hard questions. Leave all at 0 for balanced random selection.'**
  String get difficultyDistributionHint;

  /// Label for easy difficulty questions count
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easyQuestions;

  /// Label for medium difficulty questions count
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumQuestions;

  /// Label for hard difficulty questions count
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hardQuestions;

  /// Label showing total selected question count
  ///
  /// In en, this message translates to:
  /// **'Total Selected'**
  String get totalSelected;

  /// Popup menu action to practice from a source
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceAction;

  /// Popup menu action to view source details
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsAction;

  /// Label for topic title in schedule confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Topic: {topicTitle}'**
  String mentorScheduleTopic(String topicTitle);

  /// Warning about late-night study sessions in mentor context
  ///
  /// In en, this message translates to:
  /// **'WARNING: {count} session(s) started after 10 PM (late-night study detected)'**
  String mentorContextLateNightWarning(int count);

  /// Label for average time per question in exam results
  ///
  /// In en, this message translates to:
  /// **'Avg time/question'**
  String get avgTimePerQuestion;

  /// Message about spaced repetition impact in exam results
  ///
  /// In en, this message translates to:
  /// **'Results will affect spaced repetition scheduling for {count} questions.'**
  String examResultsSrsImpact(int count);

  /// Section header for question overview in exam results
  ///
  /// In en, this message translates to:
  /// **'Questions at a glance'**
  String get questionsAtAGlance;

  /// Message shown when no exam history exists
  ///
  /// In en, this message translates to:
  /// **'No exam history available'**
  String get noExamHistory;

  /// Title for exam history dialog
  ///
  /// In en, this message translates to:
  /// **'Exam History'**
  String get examHistory;

  /// Duration format with minutes and seconds
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// Description for exam history card
  ///
  /// In en, this message translates to:
  /// **'View past exam results'**
  String get viewPastExamResults;

  /// Header for student context section in mentor prompt
  ///
  /// In en, this message translates to:
  /// **'Current student context:'**
  String get mentorContextHeader;

  /// Label for total attempts count in mentor context
  ///
  /// In en, this message translates to:
  /// **'Total attempts: {count}'**
  String mentorContextTotalAttempts(int count);

  /// Label for correct attempts count in mentor context
  ///
  /// In en, this message translates to:
  /// **'Correct attempts: {count}'**
  String mentorContextCorrectAttempts(int count);

  /// Label for accuracy percentage in mentor context
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {percent}%'**
  String mentorContextAccuracy(String percent);

  /// Label for topics studied count in mentor context
  ///
  /// In en, this message translates to:
  /// **'Topics studied: {count}'**
  String mentorContextTopicsStudied(int count);

  /// Label for weekly activity count in mentor context
  ///
  /// In en, this message translates to:
  /// **'Weekly activity: {count} attempts'**
  String mentorContextWeeklyActivity(int count);

  /// Label for total study time in mentor context
  ///
  /// In en, this message translates to:
  /// **'Total study time: {hours} hours'**
  String mentorContextTotalStudyTime(String hours);

  /// Label for plan phase in mentor context
  ///
  /// In en, this message translates to:
  /// **'Plan exists: current phase (day {currentDay} of {totalDays})'**
  String mentorContextPlanPhase(int currentDay, int totalDays);

  /// Label for plan adherence in mentor context
  ///
  /// In en, this message translates to:
  /// **'Plan adherence: {percent}%'**
  String mentorContextPlanAdherence(String percent);

  /// Label for low adherence warning in mentor context
  ///
  /// In en, this message translates to:
  /// **'Low adherence for {count} consecutive days'**
  String mentorContextLowAdherence(int count);

  /// Label for days since last activity in mentor context
  ///
  /// In en, this message translates to:
  /// **'Days since last activity: {count}'**
  String mentorContextDaysSinceActivity(int count);

  /// Welcome back message after absence in mentor context
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: The student is returning after a {count}-day absence. Provide a warm welcome-back and suggest specific catch-up steps.'**
  String mentorContextWelcomeBack(int count);

  /// Label for active roadmaps count in mentor context
  ///
  /// In en, this message translates to:
  /// **'Active roadmaps: {count}'**
  String mentorContextActiveRoadmaps(int count);

  /// Label for roadmap progress in mentor context
  ///
  /// In en, this message translates to:
  /// **'{goal}: {completed}/{total} milestones completed'**
  String mentorContextRoadmapProgress(String goal, int completed, int total);

  /// Label for next milestone in mentor context
  ///
  /// In en, this message translates to:
  /// **'Next milestone: \"{title}\" due {dueDate}'**
  String mentorContextNextMilestone(String title, String dueDate);

  /// Label for pending actions count in mentor context
  ///
  /// In en, this message translates to:
  /// **'Pending actions awaiting decision: {count}'**
  String mentorContextPendingActions(int count);

  /// Format for a pending action item in mentor context
  ///
  /// In en, this message translates to:
  /// **'{type}: {topic}'**
  String mentorContextPendingActionItem(String type, String topic);

  /// Header for upcoming lessons in mentor context
  ///
  /// In en, this message translates to:
  /// **'Upcoming lessons (next {count}):'**
  String mentorContextUpcomingLessons(int count);

  /// Format for a lesson item in mentor context
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" at {time} ({duration}min)'**
  String mentorContextLessonItem(String title, String time, int duration);

  /// Header for weak topics section in mentor context
  ///
  /// In en, this message translates to:
  /// **'Weak topics needing attention:'**
  String get mentorContextWeakTopics;

  /// Format for a weak topic item in mentor context
  ///
  /// In en, this message translates to:
  /// **'{topic} (accuracy: {accuracy}%)'**
  String mentorContextWeakTopicItem(String topic, String accuracy);

  /// Label for today's study time in mentor context
  ///
  /// In en, this message translates to:
  /// **'Today\'s study time: {minutes} minutes'**
  String mentorContextStudyTimeToday(int minutes);

  /// Warning when daily study cap is exceeded in mentor context
  ///
  /// In en, this message translates to:
  /// **'WARNING: Daily study cap ({cap} min) exceeded by {today} minutes'**
  String mentorContextCapExceeded(int cap, int today);

  /// Label for daily cap remaining in mentor context
  ///
  /// In en, this message translates to:
  /// **'Daily cap: {cap} minutes ({remaining} min remaining)'**
  String mentorContextCapRemaining(int cap, int remaining);

  /// Congratulations message for long study streak in mentor context
  ///
  /// In en, this message translates to:
  /// **'Congratulations! {count} day study streak!'**
  String mentorContextStreak(int count);

  /// Positive message for good study consistency in mentor context
  ///
  /// In en, this message translates to:
  /// **'{count} consecutive study days - good consistency!'**
  String mentorContextStreakGood(int count);

  /// Label for sessions today count in mentor context
  ///
  /// In en, this message translates to:
  /// **'Sessions today: {count}'**
  String mentorContextSessionsToday(int count);

  /// Button to create a new question
  ///
  /// In en, this message translates to:
  /// **'Create Question'**
  String get createQuestion;

  /// Hint text for question text field
  ///
  /// In en, this message translates to:
  /// **'Enter the question text'**
  String get questionTextHint;

  /// Label for answer options section
  ///
  /// In en, this message translates to:
  /// **'Answer Options'**
  String get answerOptions;

  /// Button to add an option
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOption;

  /// Label for correct answer field
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswerLabel;

  /// Hint to select correct answer
  ///
  /// In en, this message translates to:
  /// **'Select correct answer'**
  String get selectCorrectAnswer;

  /// Message shown when question is created
  ///
  /// In en, this message translates to:
  /// **'Question created successfully'**
  String get questionCreated;

  /// Title for question management section
  ///
  /// In en, this message translates to:
  /// **'Manage Questions'**
  String get manageQuestions;

  /// Warning about sensitive data in backup
  ///
  /// In en, this message translates to:
  /// **'This backup contains sensitive data (API key, model configuration). Be cautious when sharing this file.'**
  String get backupContainsSensitiveData;

  /// Option to exclude sensitive data from backup
  ///
  /// In en, this message translates to:
  /// **'Exclude sensitive data'**
  String get excludeSensitiveData;

  /// Info about sensitive data exclusion
  ///
  /// In en, this message translates to:
  /// **'Sensitive data will be excluded. You will need to re-enter your API key after restore.'**
  String get sensitiveDataWillBeExcluded;

  /// Prompt to select restore sections
  ///
  /// In en, this message translates to:
  /// **'Select sections to restore'**
  String get selectBoxesToRestore;

  /// Button to select all items
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Button to deselect all items
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// Warning about selected sections being overwritten
  ///
  /// In en, this message translates to:
  /// **'Selected sections will be completely overwritten.'**
  String get selectedBoxesWillBeOverwritten;

  /// Title for automatic backup settings
  ///
  /// In en, this message translates to:
  /// **'Automatic Backup'**
  String get autoBackup;

  /// Description for automatic backup
  ///
  /// In en, this message translates to:
  /// **'Schedule automatic backups'**
  String get autoBackupDescription;

  /// Daily backup interval option
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get backupIntervalDaily;

  /// Weekly backup interval option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backupIntervalWeekly;

  /// Never backup option
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get backupIntervalNever;

  /// Label for last backup timestamp
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get lastBackup;

  /// Notification title for AI task failure
  ///
  /// In en, this message translates to:
  /// **'AI task failed: {feature}'**
  String aiTaskFailedNotification(String feature);

  /// Notification body for AI task failure
  ///
  /// In en, this message translates to:
  /// **'Task \'{feature}\' failed. {error}'**
  String aiTaskFailedBody(String feature, String error);

  /// Link label for question bank
  ///
  /// In en, this message translates to:
  /// **'Question Bank'**
  String get questionBankLink;

  /// Option to overwrite all data on restore
  ///
  /// In en, this message translates to:
  /// **'Overwrite all'**
  String get overwriteRestore;

  /// Option to merge data, skipping existing records
  ///
  /// In en, this message translates to:
  /// **'Merge (skip existing)'**
  String get mergeRestore;

  /// Message shown when automatic backup completes
  ///
  /// In en, this message translates to:
  /// **'Backup completed automatically'**
  String get backupCompleted;

  /// Button to navigate to settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get viewInSettings;

  /// Label for the greeting phase in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Greeting'**
  String get phaseGreeting;

  /// Label for the teaching phase in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get phaseTeaching;

  /// Label for the exercise phase in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get phaseExercise;

  /// Label for the feedback phase in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get phaseFeedback;

  /// Label for the adaptive review phase in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Adaptive Review'**
  String get phaseAdaptiveReview;

  /// Label for the closing phase in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get phaseClosing;

  /// Title for the exam session screen combining mode and subject
  ///
  /// In en, this message translates to:
  /// **'{mode} – {subject}'**
  String examSessionTitle(String mode, String subject);

  /// Message shown after sign out is complete
  ///
  /// In en, this message translates to:
  /// **'Sign out – Done'**
  String get signOutComplete;

  /// Error message for import failure with error detail
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedWithError(String error);

  /// Label for scheduled time
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String scheduleTimeLabel(String time);

  /// Label for scheduled duration
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String scheduleDurationLabel(String duration);

  /// Count of records with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 record} other{{count} records}}'**
  String recordCount(int count);

  /// Error message when evaluation fails without an error detail
  ///
  /// In en, this message translates to:
  /// **'Could not evaluate answer.'**
  String get couldNotEvaluateAnswer;

  /// Error message when evaluation fails with an error detail
  ///
  /// In en, this message translates to:
  /// **'Could not evaluate answer: {error}'**
  String couldNotEvaluateAnswerWithError(String error);

  /// Prompt sent to LLM when student submits an image for analysis
  ///
  /// In en, this message translates to:
  /// **'The student submitted handwritten work / an image. Analyze and provide feedback, identifying any errors and suggesting improvements.\n\n{imageData}'**
  String tutorImageAnalysisUserPrompt(String imageData);

  /// System prompt for image analysis by the tutor LLM
  ///
  /// In en, this message translates to:
  /// **'The student submitted this work. Analyze and provide feedback.'**
  String get tutorImageAnalysisSystemPrompt;

  /// Dialog title for topic dependencies
  ///
  /// In en, this message translates to:
  /// **'{topic} — Dependencies'**
  String dependenciesTitle(String topic);

  /// Label for prerequisites section
  ///
  /// In en, this message translates to:
  /// **'Prerequisites'**
  String get prerequisites;

  /// Message when no topics are available
  ///
  /// In en, this message translates to:
  /// **'No other topics available for prerequisites.'**
  String get noTopicsForPrerequisites;

  /// Fallback when a topic has no description
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// Label for mastery threshold slider
  ///
  /// In en, this message translates to:
  /// **'Mastery Threshold: {percent}%'**
  String masteryThreshold(String percent);

  /// Label for required topic toggle
  ///
  /// In en, this message translates to:
  /// **'Required Topic'**
  String get requiredTopic;

  /// Description when topic is required
  ///
  /// In en, this message translates to:
  /// **'Student must master this topic'**
  String get requiredTopicOn;

  /// Description when topic is optional
  ///
  /// In en, this message translates to:
  /// **'Optional topic — can be skipped'**
  String get requiredTopicOff;

  /// Label for syllabus weight slider
  ///
  /// In en, this message translates to:
  /// **'Syllabus Weight: {weight}'**
  String syllabusWeight(String weight);

  /// Label for parent topic dropdown
  ///
  /// In en, this message translates to:
  /// **'Parent Topic'**
  String get parentTopic;

  /// Dropdown option for root topic
  ///
  /// In en, this message translates to:
  /// **'None (Root Topic)'**
  String get rootTopic;

  /// Label showing sort order value
  ///
  /// In en, this message translates to:
  /// **'Sort Order: {order}'**
  String sortOrderValue(int order);

  /// Snackbar message when topic is created
  ///
  /// In en, this message translates to:
  /// **'Topic \"{title}\" created'**
  String topicCreated(String title);

  /// Error message when topic creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create topic: {error}'**
  String topicCreateFailed(String error);

  /// Popup menu title for edit topic
  ///
  /// In en, this message translates to:
  /// **'Edit Topic'**
  String get editTopicTitle;

  /// Snackbar message when topic is updated
  ///
  /// In en, this message translates to:
  /// **'Topic \"{title}\" updated'**
  String topicUpdated(String title);

  /// Error message when topic update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update topic: {error}'**
  String topicUpdateFailed(String error);

  /// Snackbar message when dependencies are updated
  ///
  /// In en, this message translates to:
  /// **'Dependencies updated'**
  String get dependenciesUpdated;

  /// Error message when dependency update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update dependencies: {error}'**
  String dependenciesUpdateFailed(String error);

  /// Dialog title for topic deletion
  ///
  /// In en, this message translates to:
  /// **'Delete Topic'**
  String get deleteTopicTitle;

  /// Confirmation message for topic deletion
  ///
  /// In en, this message translates to:
  /// **'Delete \"{topic}\"? This will remove it from all dependency lists.'**
  String deleteTopicConfirm(String topic);

  /// Snackbar message when topic is deleted
  ///
  /// In en, this message translates to:
  /// **'Topic deleted'**
  String get topicDeleted;

  /// Error message when topic deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete topic: {error}'**
  String topicDeleteFailed(String error);

  /// Label for topic title input field
  ///
  /// In en, this message translates to:
  /// **'Topic Title'**
  String get topicTitleLabel;

  /// Hint text for topic title
  ///
  /// In en, this message translates to:
  /// **'e.g. Atomic Structure'**
  String get topicTitleHint;

  /// Label for topic description input field
  ///
  /// In en, this message translates to:
  /// **'Topic Description'**
  String get topicDescriptionLabel;

  /// Hint text for topic description
  ///
  /// In en, this message translates to:
  /// **'Describe the topic scope'**
  String get topicDescriptionHint;

  /// Label for syllabus text input field
  ///
  /// In en, this message translates to:
  /// **'Syllabus Text'**
  String get syllabusTextLabel;

  /// Hint text for syllabus text
  ///
  /// In en, this message translates to:
  /// **'Syllabus points covered'**
  String get syllabusTextHint;

  /// Dialog title for adding a topic
  ///
  /// In en, this message translates to:
  /// **'Add Topic'**
  String get addTopicTitle;

  /// Label showing number of topics
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String topicCountTemplate(int count);

  /// Popup menu item for topic dependencies
  ///
  /// In en, this message translates to:
  /// **'Dependencies'**
  String get dependenciesNav;

  /// Label showing prerequisite count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 prerequisite} other{{count} prerequisites}}'**
  String prerequisitesCount(int count);

  /// Label showing downstream topic count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 downstream} other{{count} downstream}}'**
  String downstreamCount(int count);

  /// Label indicating a topic has a parent
  ///
  /// In en, this message translates to:
  /// **'Has parent'**
  String get hasParent;

  /// Tooltip for add topic button
  ///
  /// In en, this message translates to:
  /// **'Add Topic'**
  String get addTopicTooltip;

  /// Warning about downstream dependencies when deleting a topic
  ///
  /// In en, this message translates to:
  /// **'⚠ {count, plural, =1{1 downstream topic depends} other{{count} downstream topics depend}} on this topic and may need to be updated.'**
  String downstreamTopicWarning(int count);

  /// Dialog title when prerequisites are not met
  ///
  /// In en, this message translates to:
  /// **'Prerequisites Not Met'**
  String get prerequisitesNotMet;

  /// Button to practice prerequisite topics
  ///
  /// In en, this message translates to:
  /// **'Practice Prerequisites'**
  String get practicePrerequisites;

  /// Body text for prerequisite dialog
  ///
  /// In en, this message translates to:
  /// **'This topic requires mastery of: {topicNames}. Would you like to practice those first?'**
  String prerequisiteMasteryRequired(String topicNames);

  /// Subtitle for inline practice option in focus mode
  ///
  /// In en, this message translates to:
  /// **'Practice directly in focus mode — timer keeps running'**
  String get inlinePracticeSubtitle;

  /// Subtitle for full practice session option in focus mode
  ///
  /// In en, this message translates to:
  /// **'Navigate to full practice session screen'**
  String get fullPracticeSubtitle;

  /// Description shown in the mode toggle when timer mode is selected
  ///
  /// In en, this message translates to:
  /// **'Timer mode is a silent focus timer. Questions and practice are available in the Practice tab.'**
  String get timerOnlyDescription;

  /// Checkbox label to generate AI lesson from uploaded content
  ///
  /// In en, this message translates to:
  /// **'Generate lesson from this material'**
  String get generateLessonFromContent;

  /// Hint text for generate lesson checkbox
  ///
  /// In en, this message translates to:
  /// **'Creates an AI-generated lesson with slides, exercises, and summary blocks'**
  String get generateLessonFromContentHint;

  /// Error message when a subject has no topics
  ///
  /// In en, this message translates to:
  /// **'{subjectName} has no topics. Add topics first or upload a syllabus.'**
  String subjectNoTopics(String subjectName);

  /// Visual placeholder for weeks with no activity in bar chart
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get noActivityShort;

  /// Error message when a course/subject name typed by the user does not match any existing subject
  ///
  /// In en, this message translates to:
  /// **'Course \'{courseName}\' not found. Create it first in the Subjects tab, or select from existing subjects using multi-syllabus mode.'**
  String courseNotFound(String courseName);

  /// Helper text explaining that the user should enter a subject name that already exists
  ///
  /// In en, this message translates to:
  /// **'Enter an existing subject name to base the plan on its syllabus'**
  String get planSubjectHint;

  /// Tooltip label for chat view in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Tooltip label for slides view in tutor screen
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get slides;

  /// Tile title for API connection health indicator in settings
  ///
  /// In en, this message translates to:
  /// **'Connection Health'**
  String get connectionHealth;

  /// Label when connection has not been tested yet
  ///
  /// In en, this message translates to:
  /// **'Not tested'**
  String get notTested;

  /// Label on retry banner for failed chat messages
  ///
  /// In en, this message translates to:
  /// **'Message failed. Tap to retry.'**
  String get messageFailedRetry;

  /// SnackBarAction label for sharing backup
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Share text for backup file
  ///
  /// In en, this message translates to:
  /// **'StudyKing Backup — {date}'**
  String backupShareText(String date);

  /// FilledButton label for manual backup
  ///
  /// In en, this message translates to:
  /// **'Back Up Now'**
  String get backupNow;

  /// TextButton label to share the last backup
  ///
  /// In en, this message translates to:
  /// **'Share last backup'**
  String get shareLastBackup;

  /// Semantics label and tooltip for export reports button
  ///
  /// In en, this message translates to:
  /// **'Export Reports'**
  String get exportReports;

  /// Tooltip for read aloud button on chat bubble
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// Semantics label and button label for file upload
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFile;

  /// Button label when a file is attached
  ///
  /// In en, this message translates to:
  /// **'File attached'**
  String get fileAttached;

  /// Semantics label for audio recording button
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get recordAudio;

  /// Button label when recording is complete
  ///
  /// In en, this message translates to:
  /// **'Recording complete'**
  String get recordingComplete;

  /// Label shown while audio recording is active
  ///
  /// In en, this message translates to:
  /// **'Recording in progress'**
  String get recordingInProgress;

  /// Button label for idle recording state
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// System prompt for lesson generation LLM
  ///
  /// In en, this message translates to:
  /// **'You are a lesson planning AI. Generate educational content in {localeName}. Your response must be valid JSON.'**
  String lessonSystemPrompt(String localeName);

  /// Prompt for generating lesson blocks from LLM
  ///
  /// In en, this message translates to:
  /// **'Generate a structured lesson plan for the topic: \"{topicTitle}\". Include slides (key concepts), examples, exercises, and a summary. Respond in {localeName}. Format your response as a JSON array of blocks, each with \"type\" (slide, text, example, exercise, quiz, summary) and \"content\" fields.'**
  String lessonBuildPrompt(String topicTitle, String localeName);

  /// Prompt for generating lesson from source material
  ///
  /// In en, this message translates to:
  /// **'Based on the following source material, generate a structured lesson:\n\n{sourceContent}\n\nTopic: {topicTitle}\nGenerate slides, examples, exercises, and a summary. Respond in {localeName} as a JSON array of blocks.'**
  String lessonBuildPromptFromSource(
    String sourceContent,
    String topicTitle,
    String localeName,
  );

  /// Title for mentor check-in notification
  ///
  /// In en, this message translates to:
  /// **'Mentor Check-In'**
  String get mentorCheckIn;

  /// Dashboard card title for next upcoming items
  ///
  /// In en, this message translates to:
  /// **'Next Up'**
  String get nextUp;

  /// Fallback text for a scheduled lesson with no topic title
  ///
  /// In en, this message translates to:
  /// **'Scheduled lesson'**
  String get scheduledLesson;

  /// Number of upcoming lessons
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 upcoming lesson} other{{count} upcoming lessons}}'**
  String upcomingLessonsCount(int count);

  /// Number of reviews due for spaced repetition
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 review due} other{{count} reviews due}}'**
  String reviewsDueCount(int count);

  /// Subtitle for due review items
  ///
  /// In en, this message translates to:
  /// **'Due for spaced repetition review'**
  String get dueForReviewSubtitle;

  /// Number of weak topics needing practice
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 weak topic} other{{count} weak topics}}'**
  String weakTopicsCount(int count);

  /// Subtitle for practicing weak topic areas
  ///
  /// In en, this message translates to:
  /// **'Practice weak areas'**
  String get practiceWeakAreas;

  /// Number of estimated lessons remaining with tilde prefix
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{~{count} lesson} other{~{count} lessons}}'**
  String lessonsCount(int count);

  /// Number of topics that need attention in workload card
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 topic needs attention} other{{count} topics need attention}}'**
  String topicsNeedAttention(int count);

  /// Tooltip for voice input button when recording
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// Feedback shown when quiz answer is incorrect
  ///
  /// In en, this message translates to:
  /// **'Incorrect answer'**
  String get incorrectAnswer;

  /// Accessible label for shimmer loading state
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingWithEllipsis;

  /// Section header for mentor messages received while away
  ///
  /// In en, this message translates to:
  /// **'--- While you were away ---'**
  String get whileYouWereAway;

  /// Section footer for end of pending mentor messages
  ///
  /// In en, this message translates to:
  /// **'--- End of pending messages ---'**
  String get endOfPendingMessages;

  /// Label shown during focus mode indicating lesson practice
  ///
  /// In en, this message translates to:
  /// **'Lesson Practice'**
  String get lessonPractice;

  /// Label shown during focus mode with topic name
  ///
  /// In en, this message translates to:
  /// **'Lesson Practice: {topic}'**
  String lessonPracticeWithTopic(String topic);

  /// Page number indicator showing current page out of total
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String pageIndicator(int current, int total);

  /// Notification channel name for mentor messages
  ///
  /// In en, this message translates to:
  /// **'Mentor Messages'**
  String get mentorMessages;

  /// Notification text to nudge the student to resume learning
  ///
  /// In en, this message translates to:
  /// **'Ready to continue learning?'**
  String get readyToContinueLearning;

  /// Accessibility label for graph drawing canvas
  ///
  /// In en, this message translates to:
  /// **'Graph canvas'**
  String get graphCanvas;

  /// Hint text for graph drawing area
  ///
  /// In en, this message translates to:
  /// **'Draw your graph here'**
  String get drawYourGraphHere;

  /// Count of strokes and points in drawing
  ///
  /// In en, this message translates to:
  /// **'{strokes} strokes, {points} points'**
  String strokesCountPoints(int strokes, int points);

  /// Tool name for freehand drawing tool
  ///
  /// In en, this message translates to:
  /// **'Freehand'**
  String get toolFreehand;

  /// Tool name for line drawing tool
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get toolLine;

  /// Tool name for rectangle drawing tool
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get toolRectangle;

  /// Tool name for circle drawing tool
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get toolCircle;

  /// Tool name for text drawing tool
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get toolText;

  /// Tool name for plot point drawing tool
  ///
  /// In en, this message translates to:
  /// **'Plot Point'**
  String get toolPlotPoint;

  /// Tool name for eraser drawing tool
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get toolEraser;

  /// Fallback message when evaluation JSON cannot be parsed
  ///
  /// In en, this message translates to:
  /// **'Unable to display evaluation result'**
  String get unableToDisplayEvaluation;

  /// Snackbar message when microphone permission is denied
  ///
  /// In en, this message translates to:
  /// **'Microphone access denied. Please enable it in Settings to use voice input.'**
  String get micPermissionDenied;

  /// Label appended to subject name in focus timer title
  ///
  /// In en, this message translates to:
  /// **'(Focus)'**
  String get focusTimerLabel;

  /// Semantics label for voice bar when actively listening
  ///
  /// In en, this message translates to:
  /// **'Listening. Speak now.'**
  String get voiceListeningHint;

  /// Accessibility setting: bold font weight toggle label
  ///
  /// In en, this message translates to:
  /// **'Bold Text'**
  String get boldText;

  /// Description for bold text accessibility setting
  ///
  /// In en, this message translates to:
  /// **'Use bold font weight for text throughout the app'**
  String get boldTextDescription;

  /// Tooltip for voice input button when speech recognition is unavailable
  ///
  /// In en, this message translates to:
  /// **'Voice input not available'**
  String get voiceInputNotAvailable;

  /// Dialog title when microphone permission is needed
  ///
  /// In en, this message translates to:
  /// **'Microphone Permission Required'**
  String get microphonePermissionRequired;

  /// Settings option to re-trigger the onboarding tour
  ///
  /// In en, this message translates to:
  /// **'Show onboarding tour'**
  String get showOnboardingTour;

  /// Button label to save content without AI processing
  ///
  /// In en, this message translates to:
  /// **'Save Only'**
  String get saveOnly;

  /// Button label to proceed despite a warning
  ///
  /// In en, this message translates to:
  /// **'Proceed Anyway'**
  String get proceedAnyway;

  /// Dialog title when model may not support image/audio content
  ///
  /// In en, this message translates to:
  /// **'Model Capability Notice'**
  String get modelCapabilityWarningTitle;

  /// Dialog body warning about model capability for image/audio
  ///
  /// In en, this message translates to:
  /// **'Your selected model may not support image or audio analysis. Proceed anyway?'**
  String get modelCapabilityWarningBody;

  /// Elapsed time during processing
  ///
  /// In en, this message translates to:
  /// **'Processing... {seconds}s elapsed'**
  String processingElapsed(int seconds);

  /// Progress stage counter label
  ///
  /// In en, this message translates to:
  /// **'Stage {current} of {total}'**
  String progressStageLabel(int current, int total);

  /// Button label to practice all questions from a source
  ///
  /// In en, this message translates to:
  /// **'Practice All Questions'**
  String get practiceAllQuestions;

  /// Disabled button hint when no questions are available
  ///
  /// In en, this message translates to:
  /// **'No questions to practice'**
  String get noQuestionsToPractice;

  /// Warning when generated questions have no topic assigned
  ///
  /// In en, this message translates to:
  /// **'These questions aren\'t linked to any topic. Use the topic classifier or edit the source\'s topic to enable topic-specific practice.'**
  String get questionsWithoutTopicWarning;

  /// Checkbox label to keep old questions during reprocess
  ///
  /// In en, this message translates to:
  /// **'Keep old questions'**
  String get keepOldQuestionsLabel;

  /// Hint text for keep old questions checkbox
  ///
  /// In en, this message translates to:
  /// **'Old questions will be preserved alongside new ones'**
  String get keepOldQuestionsHint;

  /// Guidance message shown after successful upload
  ///
  /// In en, this message translates to:
  /// **'You can now practice the generated questions in the Practice tab!'**
  String get postUploadGuidance;

  /// Dialog title when user tries to navigate away during upload
  ///
  /// In en, this message translates to:
  /// **'Upload in Progress'**
  String get uploadInProgressTitle;

  /// Dialog body when user tries to navigate away during upload
  ///
  /// In en, this message translates to:
  /// **'An upload is in progress. Cancel and go back?'**
  String get uploadInProgressBody;

  /// Label indicating items are selected
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// Checkbox label to upload content as a syllabus
  ///
  /// In en, this message translates to:
  /// **'Upload as syllabus'**
  String get syllabusUploadToggle;

  /// Hint text for syllabus upload checkbox
  ///
  /// In en, this message translates to:
  /// **'Marks this upload as a syllabus for structured topic generation'**
  String get syllabusUploadToggleHint;

  /// Section title for backup AI provider configuration
  ///
  /// In en, this message translates to:
  /// **'Backup Provider'**
  String get backupProvider;

  /// Description text for backup provider
  ///
  /// In en, this message translates to:
  /// **'Optional secondary AI provider for failover'**
  String get backupProviderDescription;

  /// Label for backup API key field
  ///
  /// In en, this message translates to:
  /// **'Backup API Key'**
  String get backupApiKey;

  /// Description text for backup API key
  ///
  /// In en, this message translates to:
  /// **'API key for the backup provider'**
  String get backupApiKeyDescription;

  /// Label for backup API base URL field
  ///
  /// In en, this message translates to:
  /// **'Backup Base URL'**
  String get backupBaseUrl;

  /// Label for backup AI model field
  ///
  /// In en, this message translates to:
  /// **'Backup Model'**
  String get backupModel;

  /// Hint text for backup model input
  ///
  /// In en, this message translates to:
  /// **'e.g., gpt-4o-mini'**
  String get backupModelHint;

  /// Description text for backup model
  ///
  /// In en, this message translates to:
  /// **'Model ID for the backup provider'**
  String get backupModelDescription;

  /// Error message when provider times out
  ///
  /// In en, this message translates to:
  /// **'{providerName} timed out. Please try again.'**
  String providerTimedOut(String providerName);

  /// Error message when provider connection fails
  ///
  /// In en, this message translates to:
  /// **'Connection to {providerName} failed. Please check your network and API key.'**
  String providerConnectionFailed(String providerName);

  /// Error message when response is interrupted
  ///
  /// In en, this message translates to:
  /// **'Response interrupted. Please try again.'**
  String get responseInterrupted;

  /// Expandable section title in onboarding asking what an API key is
  ///
  /// In en, this message translates to:
  /// **'What is an API key?'**
  String get whatIsApiKey;

  /// Explanation of what an API key is for onboarding
  ///
  /// In en, this message translates to:
  /// **'An API key lets StudyKing use AI services like generating questions and tutoring. You can get one for free from providers like OpenRouter or OpenAI, or run a local model with Ollama.'**
  String get whatIsApiKeyDescription;

  /// Placeholder shown in empty dashboard cards for first-time users
  ///
  /// In en, this message translates to:
  /// **'You\'ll see your stats here once you start learning!'**
  String get statsAppearAfterLearning;

  /// Dialog title showing auto-created topics
  ///
  /// In en, this message translates to:
  /// **'Topics Created'**
  String get topicsCreatedTitle;

  /// Dialog description for auto-created topics
  ///
  /// In en, this message translates to:
  /// **'Topics were automatically created based on our standard curriculum. You can review and edit them anytime.'**
  String get topicsCreatedDescription;

  /// Button label to review and edit auto-created topics
  ///
  /// In en, this message translates to:
  /// **'Review & Edit'**
  String get reviewAndEdit;

  /// Label showing count of subtopics for a topic
  ///
  /// In en, this message translates to:
  /// **'{count} subtopics'**
  String topicSubtopicsCount(int count);

  /// Dialog title when API key is needed for upload
  ///
  /// In en, this message translates to:
  /// **'API Key Required'**
  String get apiKeyRequiredForUploadTitle;

  /// Dialog message when user tries to upload without API key
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to configure an API key first to upload and process content. Would you like to configure it now?'**
  String get apiKeyRequiredForUpload;

  /// Button label to go to API configuration
  ///
  /// In en, this message translates to:
  /// **'Configure API Key'**
  String get configureApiKey;

  /// Button label to postpone an action
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// Badge label for recommended option
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// Setup guide for OpenRouter API key
  ///
  /// In en, this message translates to:
  /// **'Visit openrouter.ai/keys → Create account → Copy API key → Paste here'**
  String get openRouterSetupGuide;

  /// Setup guide for Ollama
  ///
  /// In en, this message translates to:
  /// **'Download Ollama from ollama.ai → Run locally → Use default URL'**
  String get ollamaSetupGuide;

  /// Setup guide for OpenAI API key
  ///
  /// In en, this message translates to:
  /// **'Visit platform.openai.com/api-keys → Create new key → Copy here'**
  String get openAiSetupGuide;

  /// Hint banner shown on practice screen for new users
  ///
  /// In en, this message translates to:
  /// **'First time practicing? Quick Practice is a great place to start!'**
  String get firstPracticeBanner;

  /// Badge text for beginner-friendly options
  ///
  /// In en, this message translates to:
  /// **'Recommended for beginners'**
  String get recommendedForBeginners;

  /// Welcome card title on planner for first-time visitors
  ///
  /// In en, this message translates to:
  /// **'Let\'s create your study plan!'**
  String get letsCreatePlanTitle;

  /// Welcome card description on planner
  ///
  /// In en, this message translates to:
  /// **'Tell me what you want to learn and for how long. I\'ll create a personalized plan.'**
  String get letsCreatePlanDesc;

  /// Button to auto-generate a study plan with defaults
  ///
  /// In en, this message translates to:
  /// **'Quick Plan'**
  String get quickPlan;

  /// Checklist item label for taking a practice quiz
  ///
  /// In en, this message translates to:
  /// **'Start Practicing'**
  String get startPracticing;

  /// Celebration title when checklist completes
  ///
  /// In en, this message translates to:
  /// **'Great job setting up!'**
  String get setupCompleteTitle;

  /// Celebration description when checklist completes
  ///
  /// In en, this message translates to:
  /// **'You\'re ready to start learning. Here\'s what you can do next:'**
  String get setupCompleteDesc;

  /// Label for suggested next actions after setup
  ///
  /// In en, this message translates to:
  /// **'Suggested next actions'**
  String get suggestedNextActions;

  /// Provider-specific setup guide header
  ///
  /// In en, this message translates to:
  /// **'How to get started with {providerName}:'**
  String providerSetupGuide(String providerName);

  /// Hint text shown with auto-created topics
  ///
  /// In en, this message translates to:
  /// **'These topics are based on our standard curriculum. You can edit them anytime.'**
  String get curriculumBasedTopics;

  /// Transient indicator shown when a message was rate-limited
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// Hint shown when no difficulty counts are specified for exam
  ///
  /// In en, this message translates to:
  /// **'Questions will be randomly distributed by difficulty'**
  String get difficultyRandomDistribution;

  /// Count of questions still needing difficulty assignment
  ///
  /// In en, this message translates to:
  /// **'Remaining: {count}'**
  String questionsRemainingCount(String count);

  /// Snackbar message after profile deletion
  ///
  /// In en, this message translates to:
  /// **'Profile deleted successfully'**
  String get profileDeleted;

  /// Label for optional encryption password field in backup dialog
  ///
  /// In en, this message translates to:
  /// **'Encryption password (optional)'**
  String get backupEncryptionPassword;

  /// Hint text for encryption password field
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no encryption'**
  String get backupEncryptionPasswordHint;

  /// Button label in lesson summary to practice lesson topics in study hub
  ///
  /// In en, this message translates to:
  /// **'Practice These Topics'**
  String get practiceTheseTopics;

  /// Button label in lesson summary to replay lesson blocks as quiz questions
  ///
  /// In en, this message translates to:
  /// **'Practice Lesson Blocks'**
  String get practiceLessonBlocks;

  /// Generic error message when tutor initialization fails (no error details exposed to user)
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize tutor. Please check your API configuration in Settings and try again.'**
  String get tutorInitFailedGeneric;

  /// Tagline shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'AI-Native Learning Companion'**
  String get tagline;

  /// Loading message shown while tutor initializes
  ///
  /// In en, this message translates to:
  /// **'Preparing your lesson...'**
  String get preparingTutorLesson;

  /// Mentor suggestion action for new users with no practice data
  ///
  /// In en, this message translates to:
  /// **'Start a practice session to see your stats!'**
  String get mentorStartPracticing;

  /// Mentor onboarding message shown when user has no practice attempts
  ///
  /// In en, this message translates to:
  /// **'No practice data yet — start practicing to unlock personalized insights!'**
  String get mentorNoPracticeData;

  /// Short label for accuracy section when user has no practice data
  ///
  /// In en, this message translates to:
  /// **'No practice data yet.'**
  String get mentorNoPracticeDataShort;

  /// Title for the mentor capabilities help dialog
  ///
  /// In en, this message translates to:
  /// **'What I Can Do'**
  String get mentorHelpTitle;

  /// Intro text for the mentor help capabilities dialog
  ///
  /// In en, this message translates to:
  /// **'I\'m your AI academic assistant. Here\'s what I can help you with:'**
  String get mentorCapabilitiesIntro;

  /// Mentor capability: progress review
  ///
  /// In en, this message translates to:
  /// **'Review your study progress and accuracy'**
  String get mentorCapabilityProgress;

  /// Mentor capability: scheduling
  ///
  /// In en, this message translates to:
  /// **'Schedule and reschedule lessons'**
  String get mentorCapabilitySchedule;

  /// Mentor capability: study planning
  ///
  /// In en, this message translates to:
  /// **'Create long-term study plans and roadmaps'**
  String get mentorCapabilityPlan;

  /// Mentor capability: motivation
  ///
  /// In en, this message translates to:
  /// **'Keep you motivated and on track'**
  String get mentorCapabilityMotivate;

  /// Mentor capability: topic decisions
  ///
  /// In en, this message translates to:
  /// **'Help you decide what to study next'**
  String get mentorCapabilityTopics;

  /// Mentor capability: reminders and nudges
  ///
  /// In en, this message translates to:
  /// **'Send reminders and wellbeing check-ins'**
  String get mentorCapabilityNudge;

  /// Short label for progress chip in mentor empty state
  ///
  /// In en, this message translates to:
  /// **'View Progress'**
  String get mentorCapabilityProgressShort;

  /// Pre-filled text shown when user taps Schedule chip in mentor empty state
  ///
  /// In en, this message translates to:
  /// **'Help me schedule a study session'**
  String get mentorHelpScheduleHint;

  /// Pre-filled text shown when user taps Topics chip in mentor empty state
  ///
  /// In en, this message translates to:
  /// **'What should I study next?'**
  String get mentorHelpTopicsHint;

  /// Section title for Spaced Repetition settings
  ///
  /// In en, this message translates to:
  /// **'Spaced Repetition'**
  String get srSectionTitle;

  /// Tile title for spaced repetition minimum interval setting
  ///
  /// In en, this message translates to:
  /// **'Min interval'**
  String get srMinInterval;

  /// Tile title for spaced repetition maximum interval setting
  ///
  /// In en, this message translates to:
  /// **'Max interval'**
  String get srMaxInterval;

  /// Tile title for spaced repetition daily review limit setting
  ///
  /// In en, this message translates to:
  /// **'Daily review limit'**
  String get srDailyReviewLimit;

  /// SnackBar error when saving API config without selecting a model
  ///
  /// In en, this message translates to:
  /// **'Please select a model before saving.'**
  String get selectModelWarning;

  /// AlertDialog title when switching AI provider
  ///
  /// In en, this message translates to:
  /// **'Provider Changed'**
  String get providerChangedTitle;

  /// AlertDialog body when changing AI provider
  ///
  /// In en, this message translates to:
  /// **'Changing the provider will clear the selected model. You\'ll need to select a new model.'**
  String get providerChangedBody;

  /// ActionChip label for practice questions
  ///
  /// In en, this message translates to:
  /// **'Practice Questions'**
  String get practiceQuestions;

  /// ActionChip label to start a lesson
  ///
  /// In en, this message translates to:
  /// **'Start Lesson'**
  String get startLesson;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
