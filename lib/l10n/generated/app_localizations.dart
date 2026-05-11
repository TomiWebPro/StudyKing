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
