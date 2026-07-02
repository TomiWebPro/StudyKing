import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/localization_helpers.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../errors/result.dart';
import 'mastery_graph_service.dart';
import 'student_id_service.dart';
import '../utils/logger.dart';
import 'badge_service.dart';

class StudyProgressTracker {
  static final Logger _logger = const Logger('StudyProgressTracker');
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

  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    try {
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

      return Result.success({
        'totalAttempts': totalAttempts,
        'correctAttempts': correctAttempts,
        'accuracy': (accuracy * 100).round(),
        'avgTimePerQuestion': (avgTimePerQuestion / msPerSecond).round(),
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
      });
    } catch (e) {
      _logger.w('Failed to get overall stats: $e');
      return Result.failure('StudyProgressTracker.getOverallStats: $e');
    }
  }

  Future<Result<Map<String, dynamic>>> getTopicProgress(String studentId, String topicId) async {
    try {
      final attemptsResult = await _attemptRepo.getByStudent(studentId);
      final attempts = attemptsResult.data ?? [];
      final topicAttempts = attempts.where((a) => a.questionId.contains(topicId)).toList();

      if (topicAttempts.isEmpty) {
        return Result.success({
          'topicId': topicId,
          'attempts': 0,
          'accuracy': 0.0,
          'timeSpentMinutes': 0,
          'lastAttempted': null,
        });
      }

      final correct = topicAttempts.where((a) => a.isCorrect).length;
      final totalTimeMs = topicAttempts.fold<int>(0, (sum, a) => sum + a.timeSpentMs);

      return Result.success({
        'topicId': topicId,
        'attempts': topicAttempts.length,
        'accuracy': (correct / topicAttempts.length * 100).round(),
        'timeSpentMinutes': (totalTimeMs / msPerMinute).round(),
        'lastAttempted': topicAttempts.last.timestamp.toIso8601String(),
        'conceptsMastered': correct >= topicAttempts.length.ceil() / 2
            ? true
            : false,
      });
    } catch (e) {
      _logger.w('getTopicProgress failed: $e');
      return Result.failure('StudyProgressTracker.getTopicProgress: $e');
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getWeeklyTrend(int weeks, {String? studentId}) async {
    try {
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

      trend.sort((a, b) => (b['week'] as int).compareTo(a['week']));
      return Result.success(trend);
    } catch (e) {
      _logger.w('getWeeklyTrend failed: $e');
      return Result.failure('StudyProgressTracker.getWeeklyTrend: $e');
    }
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

  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async {
    try {
      final statsResult = await getOverallStats(studentId);
      final stats = statsResult.data ?? <String, dynamic>{};

      final recommendations = <Map<String, dynamic>>[];

      final totalAttempts = stats['totalAttempts'] as int? ?? 0;
      if (totalAttempts == 0) {
        recommendations.add({
          'type': 'onboarding',
          'priority': 'high',
          'message': _l10n.mentorNoPracticeData,
          'action': _l10n.mentorStartPracticing,
        });
      } else if ((stats['accuracy'] as int) < 60) {
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

      return Result.success(recommendations);
    } catch (e) {
      _logger.w('getRecommendations failed: $e');
      return Result.failure('StudyProgressTracker.getRecommendations: $e');
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getBadges(String studentId) async {
    try {
      final badgeService = BadgeService(
        getStats: getOverallStats,
      );
      final badgesResult = await badgeService.getBadges(studentId);
      final badges = badgesResult.data ?? [];
      final l10n = _l10n;
      final result = badges.map((b) => {
        'name': badgeName(b.id, l10n),
        'description': badgeDescription(b.id, l10n),
        'unlockedAt': b.unlockedAt.toIso8601String(),
      }).toList();
      return Result.success(result);
    } catch (e) {
      _logger.w('getBadges failed: $e');
      return Result.failure('StudyProgressTracker.getBadges: $e');
    }
  }

  Future<Result<String>> getTopicMasteryLevel(String topicId, {String? studentId}) async {
    try {
      final levelResult = await getTopicMasteryLevelEnum(topicId, studentId: studentId);
      if (levelResult.isFailure) return Result.failure(levelResult.error);
      return Result.success(_masteryLevelLabel(levelResult.data!));
    } catch (e) {
      _logger.w('getTopicMasteryLevel failed: $e');
      return Result.failure('StudyProgressTracker.getTopicMasteryLevel: $e');
    }
  }

  Future<Result<MasteryLevel>> getTopicMasteryLevelEnum(String topicId, {String? studentId}) async {
    try {
      studentId ??= StudentIdService().getStudentId();
      final result = await _masteryService.getTopicMastery(studentId, topicId);
      if (result.isSuccess && result.data != null) {
        return Result.success(result.data!.masteryLevel);
      }

      final statsResult = await getTopicProgress(studentId, topicId);
      final stats = statsResult.data ?? <String, dynamic>{};
      final attempts = stats['attempts'] as int? ?? 0;
      final accuracy = (stats['accuracy'] as int? ?? 0) / 100.0;
      MasteryLevel level;
      if (attempts == 0) {
        level = MasteryLevel.novice;
      } else if (accuracy >= 0.9 && attempts >= 10) {
        level = MasteryLevel.expert;
      } else if (accuracy >= 0.8 && attempts >= 5) {
        level = MasteryLevel.proficient;
      } else if (accuracy >= 0.6 && attempts >= 3) {
        level = MasteryLevel.developing;
      } else if (attempts >= 1) {
        level = MasteryLevel.browsing;
      } else {
        level = MasteryLevel.novice;
      }
      return Result.success(level);
    } catch (e) {
      _logger.w('getTopicMasteryLevelEnum failed: $e');
      return Result.failure('StudyProgressTracker.getTopicMasteryLevelEnum: $e');
    }
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

  Future<Result<String>> exportProgressCSV(String studentId) async {
    try {
      final statsResult = await getOverallStats(studentId);
      final stats = statsResult.data ?? <String, dynamic>{};
      final trendResult = await getWeeklyTrend(4, studentId: studentId);
      final trend = trendResult.data ?? [];
      final badgesResult = await getBadges(studentId);
      final badges = badgesResult.data ?? [];

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

      return Result.success(csvLines.join('\n'));
    } catch (e) {
      _logger.w('exportProgressCSV failed: $e');
      return Result.failure('StudyProgressTracker.exportProgressCSV: $e');
    }
  }

  Future<Result<String>> exportQuestionsAndAttemptsCSV(String studentId) async {
    try {
      final attemptsResult = await _attemptRepo.getByStudent(studentId);
      final attempts = attemptsResult.data ?? [];

      final csvLines = <String>[];
      csvLines.add('"Question ID","Student ID","Correct","Time (s)","Timestamp"');

      for (final attempt in attempts) {
        csvLines.add('"${attempt.questionId}","$studentId","${attempt.isCorrect}","${attempt.timeSpentMs ~/ msPerSecond}","${attempt.timestamp.toIso8601String()}"');
      }

      return Result.success(csvLines.join('\n'));
    } catch (e) {
      _logger.w('exportQuestionsAndAttemptsCSV failed: $e');
      return Result.failure('StudyProgressTracker.exportQuestionsAndAttemptsCSV: $e');
    }
  }

  Future<Result<String>> exportSessionHistoryCSV(String studentId) async {
    try {
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

      return Result.success(csvLines.join('\n'));
    } catch (e) {
      _logger.w('exportSessionHistoryCSV failed: $e');
      return Result.failure('StudyProgressTracker.exportSessionHistoryCSV: $e');
    }
  }
}
