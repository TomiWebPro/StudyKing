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
}
