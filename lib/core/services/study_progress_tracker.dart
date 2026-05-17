import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/localization_helpers.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'mastery_graph_service.dart';
import 'student_id_service.dart';
import 'badge_service.dart';

class StudyProgressTracker {
  final Logger _logger = const Logger('StudyProgressTracker');
  final AttemptRepository _attemptRepo;
  final MasteryGraphService _masteryService;
  final SessionRepository? _sessionRepo;
  final AppLocalizations? _l10n;

  StudyProgressTracker({
    required AttemptRepository attemptRepo,
    MasteryGraphService? masteryService,
    SessionRepository? sessionRepo,
    AppLocalizations? l10n,
  })  : _attemptRepo = attemptRepo,
        _masteryService = masteryService ?? MasteryGraphService(),
        _sessionRepo = sessionRepo,
        _l10n = l10n;

  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    final attempts = await _attemptRepo.getByStudent(studentId);

    final totalAttempts = attempts.length;
    final correctAttempts = attempts.where((a) => a.isCorrect).length;
    final accuracy = totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;

    final totalTimeMs = attempts.fold<int>(0, (sum, a) => sum + a.timeSpentMs);
    final avgTimePerQuestion = totalAttempts > 0
        ? totalTimeMs / totalAttempts
        : 0.0;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyAttempts = attempts.where((a) => a.timestamp.isAfter(weekAgo)).length;

    final today = DateTime(now.year, now.month, now.day);
    final dailyAttempts = attempts.where((a) {
      final date = DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day);
      return date == today;
    }).length;

    var sessionTimeMs = 0;
    var sessionCount = 0;
    var tutorSessionCount = 0;
    var focusSessionCount = 0;

    if (_sessionRepo != null) {
      final sessionsResult = await _sessionRepo.getByStudent(studentId);
      if (sessionsResult.isSuccess) {
        final sessions = sessionsResult.data!;
        sessionCount = sessions.length;
        for (final s in sessions) {
          if (s.type == SessionType.tutoring) {
            tutorSessionCount++;
          } else if (s.type == SessionType.focus) {
            focusSessionCount++;
          }
          sessionTimeMs += s.actualDurationMs;
        }
      }
    }

    final totalStudyTimeMs = totalTimeMs + sessionTimeMs;

    return {
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'accuracy': (accuracy * 100).round(),
      'avgTimePerQuestion': (avgTimePerQuestion / 1000).round(),
      'totalStudyTimeHours': totalStudyTimeMs / 3600000,
      'weeklyActivity': weeklyAttempts,
      'dailyActivity': dailyAttempts,
      'topicsStudied': attempts
        .map((a) => a.questionId.split('_').first)
        .toSet()
        .length,
      'sessionCount': sessionCount,
      'tutorSessionCount': tutorSessionCount,
      'focusSessionCount': focusSessionCount,
    };
  }

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

  Future<List<Map<String, dynamic>>> getWeeklyTrend(int weeks, {String? studentId}) async {
    studentId ??= StudentIdService().getStudentId();
    final allAttempts = await _attemptRepo.getByStudent(studentId);

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

    final previousAccuracy = (previousWeek['accuracy'] as num).toDouble();
    final previousRatio = previousAccuracy / 100.0;
    return ((currentAccuracy - previousRatio) * 100).roundToDouble();
  }

  Future<List<Map<String, dynamic>>> getRecommendations(String studentId) async {
    final stats = await getOverallStats(studentId);

    final recommendations = <Map<String, dynamic>>[];

    if ((stats['accuracy'] as int) < 60) {
      recommendations.add({
        'type': 'review',
        'priority': 'high',
        'message': _l10n?.recommendAccuracyBelow60 ?? 'Your overall accuracy is below 60%. Focus on reviewing fundamental concepts.',
        'action': _l10n?.recommendReviewBasics ?? 'Review basic topics before advancing',
      });
    } else if ((stats['accuracy'] as int) > 85) {
      recommendations.add({
        'type': 'advanced',
        'priority': 'medium',
        'message': _l10n?.recommendAccuracyExcellent ?? 'Excellent progress! Ready for advanced topics.',
        'action': _l10n?.recommendChallengingQuestions ?? 'Try challenging practice questions',
      });
    }

    final totalHours = (stats['totalStudyTimeHours'] as num).toDouble();
    if (totalHours < 1) {
      recommendations.add({
        'type': 'engagement',
        'priority': 'medium',
        'message': _l10n?.recommendConsistency ?? 'You studied less than 1 hour total. Consistency is key!',
        'action': _l10n?.recommendSetDailyGoal ?? 'Set a daily study goal of 30 minutes',
      });
    }

    if ((stats['weeklyActivity'] as int) == 0) {
      recommendations.add({
        'type': 'reminder',
        'priority': 'high',
        'message': _l10n?.recommendNoActivity ?? 'No study activity this week. Get back on track!',
        'action': _l10n?.recommendQuickReview ?? 'Start with a quick 15-minute review session',
      });
    }

    try {
      final weakTopics =
          await _masteryService.getWeakTopics(studentId);
      if (weakTopics.isSuccess && weakTopics.data!.isNotEmpty) {
        recommendations.add({
          'type': 'weakness',
          'priority': 'high',
          'message': _l10n?.recommendWeakTopics(weakTopics.data!.length) ??
              'You have ${weakTopics.data!.length} topic(s) that need improvement. Focus on strengthening these areas.',
          'action': _l10n?.recommendAiTutor ?? 'Review weak topics with the AI tutor',
        });
      }
    } catch (e) {
      _logger.w('Failed to get weak topics for recommendations: $e');
    }

    return recommendations;
  }

  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    try {
      final badgeService = BadgeService(
        tracker: this,
      );
      final badges = await badgeService.getBadges(studentId);
      final l10n = _l10n;
      return badges.map((b) => {
        'id': b.id,
        'name': l10n != null ? badgeName(b.id, l10n) : b.name,
        'description': l10n != null ? badgeDescription(b.id, l10n) : b.description,
        'unlockedAt': b.unlockedAt.toIso8601String(),
      }).toList();
    } catch (e) {
      _logger.w('Failed to get badges: $e');
      return [];
    }
  }

  Future<String> getTopicMasteryLevel(String topicId, {String? studentId}) async {
    studentId ??= StudentIdService().getStudentId();
    try {
      final result = await _masteryService.getTopicMastery(studentId, topicId);
      if (result.isSuccess && result.data != null) {
        final state = result.data!;
        return switch (state.masteryLevel) {
          MasteryLevel.novice => 'Novice',
          MasteryLevel.browsing => 'Browsing',
          MasteryLevel.developing => 'Developing',
          MasteryLevel.proficient => 'Proficient',
          MasteryLevel.expert => 'Expert',
        };
      }
    } catch (e) {
      _logger.w('Failed to get topic mastery level from service: $e');
    }

    try {
      final stats = await getTopicProgress(studentId, topicId);
      final attempts = stats['attempts'] as int? ?? 0;
      final accuracy = (stats['accuracy'] as int? ?? 0) / 100.0;
      if (attempts == 0) return 'Novice';
      if (accuracy >= 0.9 && attempts >= 10) return 'Expert';
      if (accuracy >= 0.8 && attempts >= 5) return 'Proficient';
      if (accuracy >= 0.6 && attempts >= 3) return 'Developing';
      if (attempts >= 1) return 'Browsing';
    } catch (e) {
      _logger.w('Failed to get topic progress for mastery level: $e');
    }

    return 'Novice';
  }

  Future<String> exportProgressCSV(String studentId) async {
    final stats = await getOverallStats(studentId);
    final trend = await getWeeklyTrend(4, studentId: studentId);
    final badges = await getBadges(studentId);

    final csvLines = <String>[];

    csvLines.add('"Date","Metric","Value"');

    csvLines.add('"$studentId","totalAttempts","${stats['totalAttempts']}"');
    csvLines.add('"$studentId","correctAttempts","${stats['correctAttempts']}"');
    csvLines.add('"$studentId","accuracy","${stats['accuracy']}%"');
    csvLines.add('"$studentId","avgTimePerQuestion","${stats['avgTimePerQuestion']}"');
    csvLines.add('"$studentId","totalStudyTimeHours","${(stats['totalStudyTimeHours'] as num).toStringAsFixed(1)}"');
    csvLines.add('"$studentId","weeklyActivity","${stats['weeklyActivity']}"');
    csvLines.add('"$studentId","dailyActivity","${stats['dailyActivity']}"');

    csvLines.add('"Weekly Trend","Week","Attempts","Accuracy"');
    for (var item in trend) {
      csvLines.add('"$studentId",${item['week']}-W${item['month']},"${item['attempts']}" ,"${item['accuracy']}%"');
    }

    csvLines.add('"Badges","Badge Name","Date Unlocked"');
    for (var badge in badges) {
      csvLines.add('"$studentId","${badge['name']}","${badge['unlockedAt']}"');
    }

    return csvLines.join('\n');
  }

  Future<String> exportQuestionsAndAttemptsCSV(String studentId) async {
    final attempts = await _attemptRepo.getByStudent(studentId);

    final csvLines = <String>[];
    csvLines.add('"Question ID","Student ID","Correct","Time (s)","Timestamp"');

    for (final attempt in attempts) {
      csvLines.add('"${attempt.questionId}","$studentId","${attempt.isCorrect}","${attempt.timeSpentMs ~/ 1000}","${attempt.timestamp.toIso8601String()}"');
    }

    if (attempts.isEmpty) {
      csvLines.add('"","$studentId","No attempts recorded","",""');
    }

    return csvLines.join('\n');
  }

  Future<String> exportSessionHistoryCSV(String studentId) async {
    final attempts = await _attemptRepo.getByStudent(studentId);
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates = masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];

    final csvLines = <String>[];
    csvLines.add('"Topic ID","Total Attempts","Correct","Accuracy","Mastery Level","Last Practiced","Review Urgency"');

    for (final ms in masteryStates) {
      final level = switch (ms.masteryLevel) {
        MasteryLevel.novice => 'Novice',
        MasteryLevel.browsing => 'Browsing',
        MasteryLevel.developing => 'Developing',
        MasteryLevel.proficient => 'Proficient',
        MasteryLevel.expert => 'Expert',
      };
      final topicId = ms.topicId;
      csvLines.add('"$topicId","${ms.totalAttempts}","${ms.correctAttempts}","${(ms.accuracy * 100).toStringAsFixed(1)}%","$level","${ms.lastAttempt.toIso8601String()}","${(ms.reviewUrgency * 100).toStringAsFixed(0)}%"');
    }

    if (masteryStates.isEmpty) {
      csvLines.add('"No session data available for $studentId","","","","","",""');
    }

    csvLines.add('');
    csvLines.add('"All Attempts (${attempts.length} total):","","","","","",""');
    csvLines.add('"Question ID","Correct","Time (s)","Subject ID","Timestamp"');
    for (final attempt in attempts) {
      csvLines.add('"${attempt.questionId}","${attempt.isCorrect}","${attempt.timeSpentMs ~/ 1000}","${attempt.subjectId}","${attempt.timestamp.toIso8601String()}"');
    }

    return csvLines.join('\n');
  }
}
