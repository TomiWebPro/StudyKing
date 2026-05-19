import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/localization_helpers.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../errors/result.dart';
import 'mastery_graph_service.dart';
import 'student_id_service.dart';
import 'badge_service.dart';

class StudyProgressTracker {
  final AttemptRepository _attemptRepo;
  final MasteryGraphService _masteryService;
  final SessionRepository? _sessionRepo;
  AppLocalizations _l10n;

  StudyProgressTracker({
    required AttemptRepository attemptRepo,
    MasteryGraphService? masteryService,
    SessionRepository? sessionRepo,
    required AppLocalizations l10n,
  })  : _attemptRepo = attemptRepo,
        _masteryService = masteryService ?? MasteryGraphService(),
        _sessionRepo = sessionRepo,
        _l10n = l10n;

  void updateLocalization(AppLocalizations l10n) {
    _l10n = l10n;
  }

  Future<Map<String, dynamic>> getOverallStats(String studentId) async {
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];

    final totalAttempts = attempts.length;
    final correctAttempts = attempts.where((a) => a.isCorrect).length;
    final accuracy = totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;

    final totalTimeMs = attempts.fold<int>(0, (sum, a) => sum + a.timeSpentMs);
    final avgTimePerQuestion = totalAttempts > 0
        ? totalTimeMs / totalAttempts
        : 0.0;

    final now = DateTime.now();
    final weekAgo = now.subtract(Timeouts.week);
    final weeklyAttempts = attempts.where((a) => a.timestamp.isAfter(weekAgo)).length;

    final today = now.dateOnly;
    final dailyAttempts = attempts.where((a) {
      final date = a.timestamp.dateOnly;
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
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];
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
    final allAttemptsResult = await _attemptRepo.getByStudent(studentId);
    final allAttempts = allAttemptsResult.data ?? [];

    bool hasPriorData = false;
    for (final a in allAttempts) {
      if (a.timestamp.isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        hasPriorData = true;
        break;
      }
    }

    final trend = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (var i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: i * 7 + 6));

      final weekAttempts = allAttempts.where((a) {
        return a.timestamp.isAfter(weekStart.subtract(Timeouts.day)) &&
               a.timestamp.isBefore(now.subtract(Duration(days: i * 7)).add(Timeouts.day));
      }).toList();

      final correct = weekAttempts.where((a) => a.isCorrect).length;
      final accuracy = weekAttempts.isEmpty ? 0.0 : correct / weekAttempts.length;

      final isGap = weekAttempts.isEmpty && hasPriorData;

      trend.add({
        'week': weekStart.year,
        'month': weekStart.month,
        'attempts': weekAttempts.length,
        'accuracy': (accuracy * 100).round(),
        'improvement': _calculateImprovement(weekAttempts, trend.isNotEmpty ? trend.first : {}),
        'isGap': isGap,
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
        'message': _l10n.recommendAccuracyBelow60,
        'action': _l10n.recommendReviewBasics,
      });
    } else if ((stats['accuracy'] as int) > 85) {
      recommendations.add({
        'type': 'advanced',
        'priority': 'medium',
        'message': _l10n.recommendAccuracyExcellent,
        'action': _l10n.recommendChallengingQuestions,
      });
    }

    final totalHours = (stats['totalStudyTimeHours'] as num).toDouble();
    if (totalHours < 1) {
      recommendations.add({
        'type': 'engagement',
        'priority': 'medium',
        'message': _l10n.recommendConsistency,
        'action': _l10n.recommendSetDailyGoal,
      });
    }

    if ((stats['weeklyActivity'] as int) == 0) {
      recommendations.add({
        'type': 'reminder',
        'priority': 'high',
        'message': _l10n.recommendNoActivity,
        'action': _l10n.recommendQuickReview,
      });
    }

    final weakTopics = await _masteryService.getWeakTopics(studentId);
    if (weakTopics.isSuccess && weakTopics.data!.isNotEmpty) {
      recommendations.add({
        'type': 'weakness',
        'priority': 'high',
        'message': _l10n.recommendWeakTopics(weakTopics.data!.length),
        'action': _l10n.recommendAiTutor,
      });
    }

    return recommendations;
  }

  Future<List<Map<String, dynamic>>> getBadges(String studentId) async {
    final result = await Result.capture(() async {
      final badgeService = BadgeService(
        getStats: getOverallStats,
      );
      final badges = await badgeService.getBadges(studentId);
      final l10n = _l10n;
      return badges.map((b) => {
        'name': badgeName(b.id, l10n),
        'description': badgeDescription(b.id, l10n),
        'unlockedAt': b.unlockedAt.toIso8601String(),
      }).toList();
    }, context: 'getBadges');
    return result.data ?? [];
  }

  Future<String> getTopicMasteryLevel(String topicId, {String? studentId}) async {
    final level = await getTopicMasteryLevelEnum(topicId, studentId: studentId);
    return _masteryLevelLabel(level);
  }

  Future<MasteryLevel> getTopicMasteryLevelEnum(String topicId, {String? studentId}) async {
    studentId ??= StudentIdService().getStudentId();
    final result = await _masteryService.getTopicMastery(studentId, topicId);
    if (result.isSuccess && result.data != null) {
      return result.data!.masteryLevel;
    }

    final stats = await getTopicProgress(studentId, topicId);
    final attempts = stats['attempts'] as int? ?? 0;
    final accuracy = (stats['accuracy'] as int? ?? 0) / 100.0;
    if (attempts == 0) return MasteryLevel.novice;
    if (accuracy >= 0.9 && attempts >= 10) return MasteryLevel.expert;
    if (accuracy >= 0.8 && attempts >= 5) return MasteryLevel.proficient;
    if (accuracy >= 0.6 && attempts >= 3) return MasteryLevel.developing;
    if (attempts >= 1) return MasteryLevel.browsing;

    return MasteryLevel.novice;
  }

  String _masteryLevelLabel(MasteryLevel level) {
    return switch (level) {
      MasteryLevel.novice => _l10n.masteryLevelNovice,
      MasteryLevel.browsing => _l10n.masteryLevelBrowsing,
      MasteryLevel.developing => _l10n.masteryLevelDeveloping,
      MasteryLevel.proficient => _l10n.masteryLevelProficient,
      MasteryLevel.expert => _l10n.masteryLevelExpert,
    };
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
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];

    final csvLines = <String>[];
    csvLines.add('"Question ID","Student ID","Correct","Time (s)","Timestamp"');

    for (final attempt in attempts) {
      csvLines.add('"${attempt.questionId}","$studentId","${attempt.isCorrect}","${attempt.timeSpentMs ~/ 1000}","${attempt.timestamp.toIso8601String()}"');
    }

    return csvLines.join('\n');
  }

  Future<String> exportSessionHistoryCSV(String studentId) async {
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates = masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];

    final csvLines = <String>[];
    csvLines.add('"Topic ID","Total Attempts","Correct","Accuracy","Mastery Level","Last Practiced","Review Urgency"');

    for (final ms in masteryStates) {
      final level = _masteryLevelLabel(ms.masteryLevel);
      final topicId = ms.topicId;
      csvLines.add('"$topicId","${ms.totalAttempts}","${ms.correctAttempts}","${(ms.accuracy * 100).toStringAsFixed(1)}%","$level","${ms.lastAttempt.toIso8601String()}","${(ms.reviewUrgency * 100).toStringAsFixed(0)}%"');
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
