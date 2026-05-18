import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/contracts/session_query_contract.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';

class SessionRepository extends Repository<Session>
    implements SessionQueryContract {
  final Logger _logger = const Logger('SessionRepository');

  @override
  Future<void> init() async {
    await openBox(HiveBoxNames.sessionsTyped);
  }

  @override
  Future<Result<void>> save(String key, Session item) async {
    return super.put(key, item);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.capture(() async {
      final sessions = box.values.toList();
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    }, context: 'getAll');
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    return Result.capture(() async {
      final start = date.dateOnly;
      final end = start.add(Timeouts.day);
      final all = box.values.toList();
      final filtered = all.where((s) =>
          s.startTime.isAfter(start.subtract(Timeouts.second)) &&
          s.startTime.isBefore(end)).toList();
      return filtered;
    }, context: 'getByDate');
  }

  Future<Result<List<Session>>> getByType(SessionType type) async {
    return Result.capture(() async {
      final all = box.values.toList();
      return all.where((s) => s.type == type).toList();
    }, context: 'getByType');
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.capture(() async {
      final all = box.values.toList();
      return all.where((s) => s.studentId == studentId).toList();
    }, context: 'getByStudent');
  }

  Future<Result<List<Session>>> getBySubject(String subjectId) async {
    return Result.capture(() async {
      final all = box.values.toList();
      return all.where((s) => s.subjectId == subjectId).toList();
    }, context: 'getBySubject');
  }

  Future<Result<List<Session>>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    return Result.capture(() async {
      final all = box.values.toList();
      return all
          .where((s) => s.studentId == studentId && s.subjectId == subjectId)
          .toList();
    }, context: 'getByStudentAndSubject');
  }

  Future<Result<List<Session>>> getRecentSessionsForSubject(String subjectId,
      {int limit = 10}) async {
    return Result.capture(() async {
      final all = box.values.toList();
      final filtered = all.where((s) => s.subjectId == subjectId).toList();
      filtered.sort((a, b) =>
          b.startTime.millisecondsSinceEpoch
              .compareTo(a.startTime.millisecondsSinceEpoch));
      return filtered.take(limit).toList();
    }, context: 'getRecentSessionsForSubject');
  }

  Future<Result<int>> getTotalStudyTimeForSubject(String subjectId) async {
    return Result.capture(() async {
      final all = box.values.toList();
      return all
          .where((s) => s.subjectId == subjectId)
          .fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    }, context: 'getTotalStudyTimeForSubject');
  }

  Future<Result<List<Session>>> getActive() async {
    return Result.capture(() async {
      final all = box.values.toList();
      return all.where((s) => s.isActive).toList();
    }, context: 'getActive');
  }

  @override
  Future<Result<int>> getTodayDurationMs() async {
    return Result.capture(() async {
      final todayResult = await getByDate(DateTime.now());
      if (todayResult.isFailure) throw Exception(todayResult.error);
      return todayResult.data!.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    }, context: 'getTodayDurationMs');
  }

  @override
  Future<bool> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    try {
      final proposedEnd = startTime.add(Duration(minutes: durationMinutes));
      final all = box.values.toList();
      for (final s in all) {
        if (excludeSessionId != null && s.id == excludeSessionId) continue;
        final sEnd = s.endTime ??
            (s.plannedDurationMinutes != null
                ? s.startTime.add(Duration(minutes: s.plannedDurationMinutes!))
                : null);
        if (sEnd == null) continue;
        if (s.startTime.isBefore(proposedEnd) && sEnd.isAfter(startTime)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.w('Error checking time conflict', e);
      return false;
    }
  }

  @override
  Future<List<Session>> getScheduledLessons() async {
    try {
      final all = box.values.toList();
      return all.where((s) => s.status == SessionStatus.planned).toList();
    } catch (e) {
      _logger.w('Error getting scheduled lessons', e);
      return [];
    }
  }

  Future<Result<int>> getTodaySessionCount() async {
    return Result.capture(() async {
      final todayResult = await getByDate(DateTime.now());
      if (todayResult.isFailure) throw Exception(todayResult.error);
      return todayResult.data!.length;
    }, context: 'getTodaySessionCount');
  }

  Future<Result<int>> getTodayCompletedSessionCount() async {
    return Result.capture(() async {
      final todayResult = await getByDate(DateTime.now());
      if (todayResult.isFailure) throw Exception(todayResult.error);
      return todayResult.data!.where((s) => s.completed).length;
    }, context: 'getTodayCompletedSessionCount');
  }

  Future<Result<int>> getWeeklyDurationMs() async {
    return Result.capture(() async {
      final now = DateTime.now();
      final weekAgo = now.subtract(Timeouts.week);
      final all = box.values.toList();
      return all
          .where((s) => s.startTime.isAfter(weekAgo))
          .fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    }, context: 'getWeeklyDurationMs');
  }

  Future<Result<Map<String, dynamic>>> getTodayStats() async {
    return Result.capture(() async {
      final now = DateTime.now();
      final sessionsResult = await getByDate(now);
      if (sessionsResult.isFailure) throw Exception(sessionsResult.error);
      final sessions = sessionsResult.data!;
      final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
      final completed = sessions.where((s) => s.completed).length;
      final plannedMinutes = sessions.fold<int>(0, (sum, s) =>
          sum + (s.plannedDurationMinutes ?? 0));

      return {
        'totalMs': totalMs,
        'totalSeconds': totalMs ~/ 1000,
        'completedSessions': completed,
        'totalSessions': sessions.length,
        'plannedMinutes': plannedMinutes,
      };
    }, context: 'getTodayStats');
  }

  Future<Result<Map<String, dynamic>>> getSubjectStats(String subjectId) async {
    return Result.capture(() async {
      final sessionsResult = await getBySubject(subjectId);
      if (sessionsResult.isFailure) throw Exception(sessionsResult.error);
      final sessions = sessionsResult.data!;
      final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
      final totalQuestions = sessions.fold<int>(0, (sum, s) => sum + s.questionsAnswered);
      final totalCorrect = sessions.fold<int>(0, (sum, s) => sum + s.correctAnswers);
      return {
        'totalSessions': sessions.length,
        'totalDurationMs': totalMs,
        'totalQuestions': totalQuestions,
        'totalCorrect': totalCorrect,
        'avgScore': totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0,
      };
    }, context: 'getSubjectStats');
  }

  Future<Result<void>> clearAll() async {
    return Result.capture(() async {
      await box.clear();
    }, context: 'clearAll');
  }
}
