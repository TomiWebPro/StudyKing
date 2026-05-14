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
  /// **'e.g., IB Physics'**
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

  /// Message when no weak areas are found
  ///
  /// In en, this message translates to:
  /// **'No weak areas found. Keep up the great work!'**
  String get noWeakAreasFound;

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
  /// **'{count} due'**
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

  /// Error message when student ID is not numeric
  ///
  /// In en, this message translates to:
  /// **'Student ID must be numeric'**
  String get studentIdMustBeNumeric;

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

  /// Label for student ID input field
  ///
  /// In en, this message translates to:
  /// **'Student ID (Optional)'**
  String get studentIdOptional;

  /// Hint text for student ID input field
  ///
  /// In en, this message translates to:
  /// **'Your student ID number'**
  String get yourStudentIdNumber;

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

  /// Label for preferred study time input field
  ///
  /// In en, this message translates to:
  /// **'Preferred Study Time'**
  String get preferredStudyTime;

  /// Hint text for preferred study time input field
  ///
  /// In en, this message translates to:
  /// **'e.g., Evening (6-9 PM)'**
  String get preferredStudyTimeHint;

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
  /// **'{count} seconds'**
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
  /// **'{count} minutes'**
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

  /// Generic retry button label
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
  /// **'e.g., IB-PHYS'**
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

  /// Button label for instrumentation export
  ///
  /// In en, this message translates to:
  /// **'Instrumentation'**
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
  /// **'{count} attempts'**
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
  /// **'{count} active'**
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
  /// **'Tokens: {count} (\${cost})'**
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
  /// **'You\'ve had {count} days of low plan adherence. Would you like to adjust your study plan?'**
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

  /// Label for AI tutor mode button
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get teachingMode;

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

  /// Accuracy percentage label
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {percent}'**
  String accuracyLabel(String percent);

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

  /// Average accuracy percentage
  ///
  /// In en, this message translates to:
  /// **'Avg Accuracy: {percent}'**
  String avgAccuracyLabel(String percent);

  /// Average readiness percentage
  ///
  /// In en, this message translates to:
  /// **'Avg Readiness: {percent}'**
  String avgReadinessLabel(String percent);

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

  /// Application name for About dialog
  ///
  /// In en, this message translates to:
  /// **'StudyKing'**
  String get aboutApplicationName;

  /// Application version for About dialog
  ///
  /// In en, this message translates to:
  /// **'v0.1.0'**
  String get aboutVersion;

  /// Copyright notice for About dialog
  ///
  /// In en, this message translates to:
  /// **'© 2026 StudyKing.'**
  String get aboutLegalese;

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

  /// Title for the progress report
  ///
  /// In en, this message translates to:
  /// **'📊 **Your Study Progress Report**\n'**
  String get mentorProgressReportTitle;

  /// Overall accuracy line in progress report
  ///
  /// In en, this message translates to:
  /// **'**Overall Accuracy:** {accuracy}% ({correct}/{total} correct)'**
  String mentorOverallAccuracy(String accuracy, String correct, String total);

  /// Total study time line in progress report
  ///
  /// In en, this message translates to:
  /// **'**Total Study Time:** {hours} hours'**
  String mentorTotalStudyTime(String hours);

  /// Weekly activity line in progress report
  ///
  /// In en, this message translates to:
  /// **'**Weekly Activity:** {attempts} attempts'**
  String mentorWeeklyActivity(String attempts);

  /// Completed lessons line in progress report
  ///
  /// In en, this message translates to:
  /// **'**Completed Lessons:** {count}'**
  String mentorCompletedLessons(String count);

  /// Topics studied line in progress report
  ///
  /// In en, this message translates to:
  /// **'**Topics Studied:** {count}'**
  String mentorTopicsStudied(String count);

  /// Section header for weak topics
  ///
  /// In en, this message translates to:
  /// **'\n**Areas needing attention:**'**
  String get mentorAreasNeedingAttention;

  /// Single topic accuracy entry
  ///
  /// In en, this message translates to:
  /// **'• {topic} (accuracy: {accuracy}%)'**
  String mentorTopicAccuracyEntry(String topic, int accuracy);

  /// Section header for badges
  ///
  /// In en, this message translates to:
  /// **'\n**Badges earned:**'**
  String get mentorBadgesEarned;

  /// Single badge entry
  ///
  /// In en, this message translates to:
  /// **'• {name}: {description}'**
  String mentorBadgeEntry(String name, String description);

  /// Section header for recommendations
  ///
  /// In en, this message translates to:
  /// **'\n**Recommendations:**'**
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
  /// **'e.g., I want to learn IB Physics in 180 days'**
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

  /// Title for roadmap detail view
  ///
  /// In en, this message translates to:
  /// **'Roadmap Overview'**
  String get roadmapOverview;

  /// Timeline view label
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// Completion percentage
  ///
  /// In en, this message translates to:
  /// **'{value}% Complete'**
  String completionOfValue(double value);

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

  /// Lesson notification toggle
  ///
  /// In en, this message translates to:
  /// **'Lesson Notifications'**
  String get lessonNotifications;

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
