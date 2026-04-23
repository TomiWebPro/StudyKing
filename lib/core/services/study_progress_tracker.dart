import '../data/repositories/attempt_repository.dart';

/// 📊 Study Progress Analytics & Tracking System
/// 
/// This service provides comprehensive tracking of study sessions,
/// progress metrics, and actionable insights for the student.
class StudyProgressTracker {
  final AttemptRepository _attemptRepo;

  StudyProgressTracker({
    required AttemptRepository attemptRepo,
  }) : _attemptRepo = attemptRepo;

  /// 📈 Get overall study statistics
  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    final attempts = await _attemptRepo.getByStudent(studentId);
    
    // Calculate metrics
    final totalAttempts = attempts.length;
    final correctAttempts = attempts.where((a) => a.isCorrect).length;
    final accuracy = totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;
    
    final totalTimeMs = attempts.fold<int>(0, (sum, a) => sum + a.timeSpentMs);
    final avgTimePerQuestion = totalAttempts > 0 
        ? totalTimeMs / totalAttempts 
        : 0.0;

    // Weekly activity
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyAttempts = attempts.where((a) => a.timestamp.isAfter(weekAgo)).length;

    // Daily activity
    final today = DateTime(now.year, now.month, now.day);
    final dailyAttempts = attempts.where((a) {
      final date = DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day);
      return date == today;
    }).length;

    return {
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'accuracy': (accuracy * 100).round(),
      'avgTimePerQuestion': (avgTimePerQuestion / 1000).round(), // seconds
      'totalStudyTimeHours': (totalTimeMs / 3600000).toStringAsFixed(1),
      'weeklyActivity': weeklyAttempts,
      'dailyActivity': dailyAttempts,
      'topicsStudied': attempts
        .map((a) => a.questionId.split('_').first)
        .toSet()
        .length,
    };
  }

  /// 📊 Get topic-wise progress
  Future<Map<String, dynamic>> getTopicProgress(String studentId, String topicId) async {
    final attempts = await _attemptRepo.getByStudent(studentId);
    final topicAttempts = attempts.where((a) => a.questionId.contains(topicId)).toList();
    
    if (topicAttempts.isEmpty) {
      return {
        'topicId': topicId,
        'attempts': 0,
        'accuracy': 0.0,
        'timeSpentMinutes': 0,
        'lastAttempted': null,
      };
    }

    final correct = topicAttempts.where((a) => a.isCorrect).length;
    final totalTimeMs = topicAttempts.fold<int>(0, (sum, a) => sum + a.timeSpentMs);

    return {
      'topicId': topicId,
      'attempts': topicAttempts.length,
      'accuracy': (correct / topicAttempts.length * 100).round(),
      'timeSpentMinutes': (totalTimeMs / 60000).round(),
      'lastAttempted': topicAttempts.last.timestamp.toIso8601String(),
      'conceptsMastered': correct >= topicAttempts.length.ceil() / 2
          ? true
          : false,
    };
  }

  /// 🎯 Get weekly performance trend
  Future<List<Map<String, dynamic>>> getWeeklyTrend(int weeks) async {
    final allAttempts = await _attemptRepo.getByStudent('student_1');
    
    final trend = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (var i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: i * 7 + 6));

      final weekAttempts = allAttempts.where((a) {
        return a.timestamp.isAfter(weekStart.subtract(const Duration(days: 1))) &&
               a.timestamp.isBefore(now.subtract(Duration(days: i * 7)).add(const Duration(days: 1)));
      }).toList();

      final correct = weekAttempts.where((a) => a.isCorrect).length;
      final accuracy = weekAttempts.isEmpty ? 0.0 : correct / weekAttempts.length;

      trend.add({
        'week': weekStart.year,
        'month': weekStart.month,
        'attempts': weekAttempts.length,
        'accuracy': (accuracy * 100).round(),
        'improvement': _calculateImprovement(weekAttempts, trend.isNotEmpty ? trend.first : {}),
      });
    }

    return trend..sort((a, b) => (b['week'] as int).compareTo(a['week']));
  }

  double _calculateImprovement(
    List<dynamic> currentWeek,
    Map<String, dynamic> previousWeek,
  ) {
    if (previousWeek.isEmpty || previousWeek['accuracy'] == null) return 0.0;

    final currentAccuracy = currentWeek.isEmpty
        ? 0.0
        : currentWeek.where((a) => a.isCorrect).length / currentWeek.length;

    final previousAccuracy = previousWeek['accuracy'] as double;
    return ((currentAccuracy - previousAccuracy / 100.0) * 100).roundToDouble();
  }

  /// 💡 Get personalized recommendations
  Future<List<Map<String, dynamic>>> getRecommendations(String studentId) async {
    final stats = await getOverallStats(studentId);

    final recommendations = <Map<String, dynamic>>[];

    // Accuracy-based recommendation
    if ((stats['accuracy'] as int) < 60) {
      recommendations.add({
        'type': 'review',
        'priority': 'high',
        'message': 'Your overall accuracy is below 60%. Focus on reviewing fundamental concepts.',
        'action': 'Review basic topics before advancing',
      });
    } else if ((stats['accuracy'] as int) > 85) {
      recommendations.add({
        'type': 'advanced',
        'priority': 'medium',
        'message': 'Excellent progress! Ready for advanced topics.',
        'action': 'Try challenging practice questions',
      });
    }

    // Study time recommendation
    final totalHours = double.parse(stats['totalStudyTimeHours'] as String);
    if (totalHours < 1) {
      recommendations.add({
        'type': 'engagement',
        'priority': 'medium',
        'message': 'You studied less than 1 hour total. Consistency is key!',
        'action': 'Set a daily study goal of 30 minutes',
      });
    }

    // Weekly activity recommendation
    if ((stats['weeklyActivity'] as int) == 0) {
      recommendations.add({
        'type': 'reminder',
        'priority': 'high',
        'message': 'No study activity this week. Get back on track!',
        'action': 'Start with a quick 15-minute review session',
      });
    }

    return recommendations;
  }

  /// 🏆 Get performance badges
  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    final stats = await getOverallStats(studentId);
    final badges = <Map<String, dynamic>>[];

    // First attempt badge
    if ((stats['totalAttempts'] as int) >= 1) {
      badges.add({
        'id': 'first_attempt',
        'name': 'First Step',
        'description': 'Answered your first question!',
        'unlockedAt': DateTime.now().toIso8601String(),
      });
    }

    // Century badge
    if ((stats['totalAttempts'] as int) >= 100) {
      badges.add({
        'id': 'century',
        'name': 'Century Club',
        'description': 'Answered 100+ questions!',
        'unlockedAt': DateTime.now().toIso8601String(),
      });
    }

    // Accuracy badge - Gold
    if ((stats['accuracy'] as int) >= 90) {
      badges.add({
        'id': 'accuracy_gold',
        'name': 'Accuracy Gold',
        'description': 'Achieved 90%+ accuracy!',
        'unlockedAt': DateTime.now().toIso8601String(),
      });
    }

    // Study streak badge
    if ((stats['dailyActivity'] as int) >= 5) {
      badges.add({
        'id': 'daily_streak',
        'name': 'Daily Scholar',
        'description': 'Studied today consistently!',
        'unlockedAt': DateTime.now().toIso8601String(),
      });
    }

    return badges;
  }

  /// 📈 Calculate mastery level for a topic
  String getTopicMasteryLevel(String topicId) {
    // In production, this would use actual data
    // For now, return a reasonable default
    return 'Browsing'; // Novice, Browsing, Developing, Proficient, Expert
  }

  /// 📊 Export progress as JSON
  Future<Map<String, dynamic>> exportProgress(String studentId) async {
    final stats = await getOverallStats(studentId);
    final trend = await getWeeklyTrend(4);
    final badges = await getBadges(studentId);
    final recommendations = await getRecommendations(studentId);

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'studentId': studentId,
      'statistics': stats,
      'weeklyTrend': trend,
      'badges': badges,
      'recommendations': recommendations,
    };
  }
}
