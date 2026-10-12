import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/localization_helpers.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../errors/result.dart';
import 'mastery_graph_service.dart';
import 'student_id_service.dart';
import '../utils/logger.dart';
import 'badge_service.dart';
import '../data/repositories/question_lookup.dart';

class StudyProgressTracker {
  static final Logger _logger = const Logger('StudyProgressTracker');
  final AttemptRepository _attemptRepo;
  final MasteryGraphService _masteryService;
  final SessionRepository? _sessionRepo;
  final QuestionLookup? _questionRepo;
  AppLocalizations _l10n;

  StudyProgressTracker({
    required AttemptRepository attemptRepo,
    MasteryGraphService? masteryService,
    SessionRepository? sessionRepo,
    QuestionLookup? questionRepo,
    required AppLocalizations l10n,
  })  : _attemptRepo = attemptRepo,
        _masteryService = masteryService ?? MasteryGraphService(),
        _sessionRepo = sessionRepo,
        _questionRepo = questionRepo,
        _l10n = l10n;

  void updateLocalization(AppLocalizations l10n) {
    _l10n = l10n;
  }

  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    try {
      final attemptsResult = await _attemptRepo.getByStudent(studentId);
      if (attemptsResult.isFailure) {
        _logger.w('Failed to get overall stats', attemptsResult.error);
        return Result.failure(attemptsResult.error);
      }
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
        'topicsStudied': await _countDistinctTopicsStudied(attempts),
        'sessionCount': sessionCount,
        'tutorSessionCount': tutorSessionCount,
        'focusSessionCount': focusSessionCount,
      });
    } catch (e) {
      _logger.w('Failed to get overall stats: $e');
      return Result.failure('StudyProgressTracker.getOverallStats: $e');
    }
  }

  /// Counts the distinct topics the student has actually attempted.
  ///
  /// Production question IDs (`q_<timestamp>_<counter>`) carry no topic
  /// information, so the topic is resolved by joining attempts to their
  /// questions through [QuestionLookup]. When no repository is wired
  /// (tests, legacy call sites) or no question resolves (box not open,
  /// question deleted), falls back to the question-ID prefix heuristic.
  Future<int> _countDistinctTopicsStudied(List<StudentAttempt> attempts) async {
    if (_questionRepo == null) {
      return attempts.map((a) => a.questionId.split('_').first).toSet().length;
    }
    final topics = <String>{};
    var resolvedAny = false;
    for (final questionId in attempts.map((a) => a.questionId).toSet()) {
      final result = await _questionRepo.get(questionId);
      final question = result.data;
      if (question != null && question.topicId.isNotEmpty) {
        topics.add(question.topicId);
        resolvedAny = true;
      }
    }
    if (!resolvedAny) {
      return attempts.map((a) => a.questionId.split('_').first).toSet().length;
    }
    return topics.length;
  }

  /// Selects the attempts whose questions belong to [topicId].
  ///
  /// Production question IDs (`q_<timestamp>_<counter>`) carry no topic
  /// information, so the topic is resolved by joining attempts to their
  /// questions through [QuestionLookup] — the same join used by
  /// [_countDistinctTopicsStudied]. When no repository is wired (tests,
  /// legacy call sites) or no question resolves (box not open, question
  /// deleted), falls back to the question-ID substring heuristic.
  Future<List<StudentAttempt>> _selectTopicAttempts(
    List<StudentAttempt> attempts,
    String topicId,
  ) async {
    if (_questionRepo == null) {
      return attempts.where((a) => a.questionId.contains(topicId)).toList();
    }
    final matched = <StudentAttempt>[];
    var resolvedAny = false;
    for (final attempt in attempts) {
      final result = await _questionRepo.get(attempt.questionId);
      final question = result.data;
      if (question != null) {
        resolvedAny = true;
        if (question.topicId == topicId) {
          matched.add(attempt);
        }
      }
    }
    if (!resolvedAny) {
      return attempts.where((a) => a.questionId.contains(topicId)).toList();
    }
    return matched;
  }

  Future<Result<Map<String, dynamic>>> getTopicProgress(String studentId, String topicId) async {
    try {
      final attemptsResult = await _attemptRepo.getByStudent(studentId);
      if (attemptsResult.isFailure) {
        _logger.w('getTopicProgress failed', attemptsResult.error);
        return Result.failure(attemptsResult.error);
      }
      final attempts = attemptsResult.data ?? [];
      final topicAttempts = await _selectTopicAttempts(attempts, topicId);

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

      // Hive stores attempts under keys '<questionId>_<timestamp>', so the
      // repository returns them grouped by question ID, not by time. Pick the
      // chronologically latest attempt explicitly rather than `.last`.
      final latestAttempt = topicAttempts.reduce(
        (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
      );

      return Result.success({
        'topicId': topicId,
        'attempts': topicAttempts.length,
        'accuracy': (correct / topicAttempts.length * 100).round(),
        'timeSpentMinutes': (totalTimeMs / msPerMinute).round(),
        'lastAttempted': latestAttempt.timestamp.toIso8601String(),
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
      studentId ??= StudentIdService().getStudentId().data ?? '';
      final allAttemptsResult = await _attemptRepo.getByStudent(studentId);
      if (allAttemptsResult.isFailure) {
        _logger.w('getWeeklyTrend failed', allAttemptsResult.error);
        return Result.failure(allAttemptsResult.error);
      }
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
        final windowStart = now.subtract(Duration(days: (i + 1) * 7));
        final windowEnd = now.subtract(Duration(days: i * 7));

        // Half-open (windowStart, windowEnd] windows keep consecutive
        // weeks disjoint: an attempt on a boundary day lands in exactly
        // one bucket, and future-dated attempts (clock skew) are never
        // counted in the current week.
        final weekAttempts = allAttempts.where((a) {
          return a.timestamp.isAfter(windowStart) &&
                 !a.timestamp.isAfter(windowEnd);
        }).toList();

        final correct = weekAttempts.where((a) => a.isCorrect).length;
        final accuracy = weekAttempts.isEmpty ? 0.0 : correct / weekAttempts.length;

        final isGap = weekAttempts.isEmpty && hasPriorData;

        trend.add({
          'week': weekStart.year,
          'month': weekStart.month,
          'weekNumber': _isoWeekNumber(weekStart),
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

  Future<Result<List<Map<String, dynamic>>>> getDailyTrend(int days, {String? studentId}) async {
    try {
      studentId ??= StudentIdService().getStudentId().data ?? '';
      final allAttemptsResult = await _attemptRepo.getByStudent(studentId);
      if (allAttemptsResult.isFailure) {
        _logger.w('getDailyTrend failed', allAttemptsResult.error);
        return Result.failure(allAttemptsResult.error);
      }
      final allAttempts = allAttemptsResult.data ?? [];

      List<Session> allSessions = [];
      if (_sessionRepo != null) {
        final sessionsResult = await _sessionRepo.getByStudent(studentId);
        if (sessionsResult.isFailure) {
          _logger.w('getDailyTrend failed', sessionsResult.error);
          return Result.failure(sessionsResult.error);
        }
        if (sessionsResult.isSuccess) {
          allSessions = sessionsResult.data ?? [];
        }
      }

      final now = DateTime.now();
      final today = now.dateOnly;
      final cutoff = today.subtract(Duration(days: days - 1));

      final dayMap = <DateTime, Map<String, dynamic>>{};
      for (var i = 0; i < days; i++) {
        final day = cutoff.add(Duration(days: i));
        dayMap[day] = {
          'date': day.toIso8601String(),
          'attempts': 0,
          'correct': 0,
          'focusSeconds': 0,
          'sessions': 0,
        };
      }

      for (final a in allAttempts) {
        final day = a.timestamp.dateOnly;
        if (dayMap.containsKey(day)) {
          final entry = dayMap[day]!;
          entry['attempts'] = (entry['attempts'] as int) + 1;
          if (a.isCorrect) {
            entry['correct'] = (entry['correct'] as int) + 1;
          }
        }
      }

      for (final s in allSessions) {
        final day = s.startTime.dateOnly;
        if (dayMap.containsKey(day)) {
          final entry = dayMap[day]!;
          entry['sessions'] = (entry['sessions'] as int) + 1;
          if (s.type == SessionType.focus) {
            entry['focusSeconds'] =
                (entry['focusSeconds'] as int) + (s.actualDurationMs ~/ msPerSecond);
          }
        }
      }

      final maxAttempts = dayMap.values
          .map((e) => e['attempts'] as int)
          .fold<int>(0, (a, b) => a > b ? a : b);
      final maxFocus = dayMap.values
          .map((e) => e['focusSeconds'] as int)
          .fold<int>(0, (a, b) => a > b ? a : b);
      final maxSessions = dayMap.values
          .map((e) => e['sessions'] as int)
          .fold<int>(0, (a, b) => a > b ? a : b);

      final results = <Map<String, dynamic>>[];
      for (final entry in dayMap.values) {
        final attempts = entry['attempts'] as int;
        final correct = entry['correct'] as int;
        final focusSeconds = entry['focusSeconds'] as int;
        final sessionCount = entry['sessions'] as int;
        final accuracy = attempts > 0 ? correct / attempts : 0.0;

        final attemptScore = maxAttempts > 0 ? attempts / maxAttempts : 0.0;
        final accuracyScore = accuracy;
        final focusScore = maxFocus > 0 ? focusSeconds / maxFocus : 0.0;
        final sessionScore = maxSessions > 0 ? sessionCount / maxSessions : 0.0;

        final composite = (attemptScore * 0.4 +
                accuracyScore * 0.3 +
                focusScore * 0.2 +
                sessionScore * 0.1)
            .clamp(0.0, 1.0);

        results.add({
          'date': entry['date'],
          'attempts': attempts,
          'accuracy': (accuracy * 100).round(),
          'focusSeconds': focusSeconds,
          'sessions': sessionCount,
          'compositeScore': composite,
        });
      }

      return Result.success(results);
    } catch (e) {
      _logger.w('getDailyTrend failed: $e');
      return Result.failure('StudyProgressTracker.getDailyTrend: $e');
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

  /// ISO 8601 week number (1-53) of the week containing [date].
  ///
  /// Weeks run Monday-Sunday and week 1 contains the year's first
  /// Thursday, so the week number is unambiguous across years and
  /// never confused with the calendar month (1-12).
  int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final firstJan = DateTime(thursday.year, 1, 1);
    final firstThursday =
        firstJan.add(Duration(days: DateTime.thursday - firstJan.weekday));
    return 1 + thursday.difference(firstThursday).inDays ~/ 7;
  }

  Future<Result<List<Map<String, dynamic>>>> getRecommendations(String studentId) async {
    try {
      final statsResult = await getOverallStats(studentId);
      if (statsResult.isFailure) {
        _logger.w('getRecommendations failed', statsResult.error);
        return Result.failure(statsResult.error);
      }
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
      if (badgesResult.isFailure) {
        _logger.w('getBadges failed', badgesResult.error);
        return Result.failure(badgesResult.error);
      }
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
      studentId ??= StudentIdService().getStudentId().data ?? '';
      final result = await _masteryService.getTopicMastery(studentId, topicId);
      if (result.isSuccess && result.data != null) {
        return Result.success(result.data!.masteryLevel);
      }

      final statsResult = await getTopicProgress(studentId, topicId);
      if (statsResult.isFailure) {
        _logger.w('getTopicMasteryLevelEnum failed', statsResult.error);
        return Result.failure(statsResult.error);
      }
      final stats = statsResult.data ?? <String, dynamic>{};
      final attempts = (stats['attempts'] as num? ?? 0).toInt();
      final accuracy = ((stats['accuracy'] as num? ?? 0).toDouble()) / 100.0;
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
      if (statsResult.isFailure) {
        _logger.w('exportProgressCSV failed', statsResult.error);
        return Result.failure(statsResult.error);
      }
      final stats = statsResult.data ?? <String, dynamic>{};
      final trendResult = await getWeeklyTrend(4, studentId: studentId);
      if (trendResult.isFailure) {
        _logger.w('exportProgressCSV failed', trendResult.error);
        return Result.failure(trendResult.error);
      }
      final trend = trendResult.data ?? [];
      final badgesResult = await getBadges(studentId);
      if (badgesResult.isFailure) {
        _logger.w('exportProgressCSV failed', badgesResult.error);
        return Result.failure(badgesResult.error);
      }
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
        csvLines.add('"$studentId",${item['week']}-W${item['weekNumber']},"${item['attempts']}" ,"${item['accuracy']}%"');
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
      if (attemptsResult.isFailure) {
        _logger.w('exportQuestionsAndAttemptsCSV failed', attemptsResult.error);
        return Result.failure(attemptsResult.error);
      }
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
      if (attemptsResult.isFailure) {
        _logger.w('exportSessionHistoryCSV failed', attemptsResult.error);
        return Result.failure(attemptsResult.error);
      }
      final attempts = attemptsResult.data ?? [];
      final masteryResult = await _masteryService.getAllTopicMastery(studentId);
      if (masteryResult.isFailure) {
        _logger.w('exportSessionHistoryCSV failed', masteryResult.error);
        return Result.failure(masteryResult.error);
      }
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
