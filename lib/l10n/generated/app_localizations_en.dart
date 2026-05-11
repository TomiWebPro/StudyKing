// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StudyKing';

  @override
  String get subjects => 'Subjects';

  @override
  String get practice => 'Practice';

  @override
  String get settings => 'Settings';

  @override
  String get studyPlanner => 'Study Planner';

  @override
  String get createStudyPlan => 'Create Study Plan';

  @override
  String get courseSubject => 'Course/Subject';

  @override
  String get courseHint => 'e.g., IB Physics';

  @override
  String get days => 'Days';

  @override
  String get hoursPerDay => 'Hours/Day';

  @override
  String get generatePlan => 'Generate Plan';

  @override
  String get generating => 'Generating...';

  @override
  String get yourStudySchedule => 'Your Study Schedule';

  @override
  String topicLabel(int number) {
    return 'Topic $number';
  }

  @override
  String sessionDurationMinutes(int minutes) {
    return '$minutes min session';
  }

  @override
  String get fillAllFieldsCorrectly => 'Please fill in all fields correctly';

  @override
  String generatedPlanOverDays(String course, int days, int totalHours) {
    return 'Generated plan for $course over $days days ($totalHours total hours)';
  }

  @override
  String overDaysPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'no days',
    );
    return 'over $_temp0';
  }

  @override
  String totalHoursPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count total hours',
      one: '1 total hour',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get unknown => 'Unknown';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}d',
      one: '1d',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}h',
      one: '1h',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}m',
      one: '1m',
    );
    return '$_temp0';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}s',
      one: '1s',
    );
    return '$_temp0';
  }

  @override
  String get practiceMode => 'Practice Mode';

  @override
  String get practiceOptions => 'Practice Options';

  @override
  String get noSubjects => 'No Subjects';

  @override
  String get noPracticeSessionsYet => 'No Practice Sessions Yet';

  @override
  String get addSubjectsAndQuestionsToStartPracticing =>
      'Add subjects and questions to start practicing';

  @override
  String get addSubjectsFromSubjectsTab => 'Add subjects from the Subjects tab';

  @override
  String get addSubject => 'Add Subject';

  @override
  String get practiceModes => 'Practice Modes';

  @override
  String get quickPractice => 'Quick Practice';

  @override
  String randomQuestions(int count) {
    return '$count random questions';
  }

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get spacedRepetition => 'Spaced Repetition';

  @override
  String get topicFocus => 'Topic Focus';

  @override
  String get practiceSpecificTopics => 'Practice specific topics';

  @override
  String get weakAreas => 'Weak Areas';

  @override
  String get focusOnMistakes => 'Focus on mistakes';

  @override
  String get yourSubjects => 'Your Subjects';

  @override
  String get readyForPractice => 'Ready for practice';

  @override
  String get practiceAvailable => 'Practice available';

  @override
  String get selectSubject => 'Select Subject';

  @override
  String get practiceModeTitle => 'Practice Mode';

  @override
  String get autoSelect => 'Auto Select';

  @override
  String get aiPicksOptimalQuestions => 'AI picks optimal questions';

  @override
  String get chooseSubject => 'Choose Subject';

  @override
  String get noCode => 'No code';

  @override
  String get topicSelectionComingSoon => 'Topic selection coming soon!';

  @override
  String get noQuestionsAvailable => 'No Questions Available';

  @override
  String get noQuestionsForSelectedSubject =>
      'There are no questions for the selected subject/topic. Start creating questions!';

  @override
  String get time => 'Time';

  @override
  String get score => 'Score';

  @override
  String get correct => 'Correct';

  @override
  String get yourAnswer => 'Your Answer';

  @override
  String yourAnswerCharacters(int count) {
    return 'Your Answer ($count characters)';
  }

  @override
  String get submitAnswer => 'Submit Answer';

  @override
  String get correctFeedback => 'Correct!';

  @override
  String get incorrectFeedback => 'Incorrect';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get sessionResults => 'Session Results';

  @override
  String get practiceComplete => 'Practice Complete!';

  @override
  String get totalQuestions => 'Total Questions';

  @override
  String get correctAnswers => 'Correct Answers';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get practiceAgain => 'Practice Again';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noReviewsScheduled => 'No reviews scheduled.';

  @override
  String dueQuestionsCount(int count) {
    return '$count due';
  }

  @override
  String get reviewDueQuestions => 'Review due questions';

  @override
  String get selectTopic => 'Select Topic';

  @override
  String get noTopicsAvailable => 'No topics available';

  @override
  String get questionsDueForReview => 'questions due for review';

  @override
  String get spacedRepetitionMode => 'Spaced Repetition';
}
