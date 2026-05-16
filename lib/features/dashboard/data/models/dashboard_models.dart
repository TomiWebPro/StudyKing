class MasterySnapshot {
  final int totalTopics;
  final int masteredTopics;
  final int weakTopics;
  final double averageAccuracy;
  final int totalAttempts;
  final double avgReadiness;
  final double avgReviewUrgency;

  const MasterySnapshot({
    this.totalTopics = 0,
    this.masteredTopics = 0,
    this.weakTopics = 0,
    this.averageAccuracy = 0.0,
    this.totalAttempts = 0,
    this.avgReadiness = 0.0,
    this.avgReviewUrgency = 0.0,
  });

  factory MasterySnapshot.fromMap(Map<String, dynamic> map) {
    return MasterySnapshot(
      totalTopics: (map['totalTopics'] as num?)?.toInt() ?? 0,
      masteredTopics: (map['masteredTopics'] as num?)?.toInt() ?? 0,
      weakTopics: (map['weakTopics'] as num?)?.toInt() ?? 0,
      averageAccuracy: (map['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      totalAttempts: (map['totalAttempts'] as num?)?.toInt() ?? 0,
      avgReadiness: (map['avgReadiness'] as num?)?.toDouble() ?? 0.0,
      avgReviewUrgency: (map['avgReviewUrgency'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isEmpty =>
      totalTopics == 0 &&
      masteredTopics == 0 &&
      weakTopics == 0 &&
      averageAccuracy == 0.0;
}

class OverallStats {
  final int totalAttempts;
  final int correctAttempts;
  final int accuracy;
  final int avgTimePerQuestion;
  final num totalStudyTimeHours;
  final int weeklyActivity;
  final int dailyActivity;
  final int topicsStudied;

  const OverallStats({
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.accuracy = 0,
    this.avgTimePerQuestion = 0,
    this.totalStudyTimeHours = 0,
    this.weeklyActivity = 0,
    this.dailyActivity = 0,
    this.topicsStudied = 0,
  });

  factory OverallStats.fromMap(Map<String, dynamic> map) {
    return OverallStats(
      totalAttempts: (map['totalAttempts'] as num?)?.toInt() ?? 0,
      correctAttempts: (map['correctAttempts'] as num?)?.toInt() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      avgTimePerQuestion: (map['avgTimePerQuestion'] as num?)?.toInt() ?? 0,
      totalStudyTimeHours: (map['totalStudyTimeHours'] is String
          ? double.tryParse(map['totalStudyTimeHours'] as String) ?? 0
          : (map['totalStudyTimeHours'] as num?) ?? 0),
      weeklyActivity: (map['weeklyActivity'] as num?)?.toInt() ?? 0,
      dailyActivity: (map['dailyActivity'] as num?)?.toInt() ?? 0,
      topicsStudied: (map['topicsStudied'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isEmpty =>
      totalAttempts == 0 &&
      accuracy == 0 &&
      weeklyActivity == 0 &&
      topicsStudied == 0;
}

class WeeklyTrendEntry {
  final int week;
  final int month;
  final int attempts;
  final int accuracy;
  final double improvement;

  const WeeklyTrendEntry({
    this.week = 0,
    this.month = 0,
    this.attempts = 0,
    this.accuracy = 0,
    this.improvement = 0.0,
  });

  factory WeeklyTrendEntry.fromMap(Map<String, dynamic> map) {
    return WeeklyTrendEntry(
      week: (map['week'] as num?)?.toInt() ?? 0,
      month: (map['month'] as num?)?.toInt() ?? 0,
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      improvement: (map['improvement'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FocusTodayStats {
  final int totalSeconds;
  final int completedSessions;
  final int totalSessions;
  final int plannedMinutes;

  const FocusTodayStats({
    this.totalSeconds = 0,
    this.completedSessions = 0,
    this.totalSessions = 0,
    this.plannedMinutes = 0,
  });

  factory FocusTodayStats.fromMap(Map<String, dynamic> map) {
    return FocusTodayStats(
      totalSeconds: (map['totalSeconds'] as num?)?.toInt() ?? 0,
      completedSessions: (map['completedSessions'] as num?)?.toInt() ?? 0,
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      plannedMinutes: (map['plannedMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  double get hours => totalSeconds / 3600;

  bool get isEmpty => totalSeconds == 0 && totalSessions == 0;
}

class AdherenceData {
  final double averageAdherence;
  final double weeklyAdherence;

  const AdherenceData({
    this.averageAdherence = 0.0,
    this.weeklyAdherence = 0.0,
  });

  bool get isEmpty => averageAdherence == 0.0 && weeklyAdherence == 0.0;
}

class BadgeDisplay {
  final String name;
  final String description;
  final String category;

  const BadgeDisplay({
    required this.name,
    required this.description,
    this.category = 'general',
  });
}

class DashboardArgs {
  final String studentId;

  const DashboardArgs({required this.studentId});
}
