import 'package:studyking/core/data/models/mastery_state_model.dart';

class ProgressReport {
  final int totalAttempts;
  final int correctAttempts;
  final double accuracy;
  final int topicsStudied;
  final int completedLessons;
  final int weeklyActivity;
  final String totalStudyTimeHours;
  final List<MasteryState> weakTopics;
  final List<Map<String, dynamic>> badges;
  final List<Map<String, dynamic>> recommendations;

  const ProgressReport({
    required this.totalAttempts,
    required this.correctAttempts,
    required this.accuracy,
    required this.topicsStudied,
    required this.completedLessons,
    required this.weeklyActivity,
    required this.totalStudyTimeHours,
    this.weakTopics = const [],
    this.badges = const [],
    this.recommendations = const [],
  });
}
