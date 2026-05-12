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
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
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
  /// **'{count} random questions'**
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
  String get noWeakAreasFound;
  String get noWeakAreasQuestions;

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
  String get medium;

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
  /// **'{count} sessions'**
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
  /// **'Drawing with {count} stroke{plural}'**
  String drawingWithStrokes(int count, String plural);

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
  /// **'{count} questions'**
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
