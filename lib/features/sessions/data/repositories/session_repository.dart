import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';

class SessionRepository {
  final Logger _logger = const Logger('SessionRepository');
  late Box<Session> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);
  }

  Box<Session> get box => _box;

  Future<Result<void>> save(Session session) async {
    try {
      await _box.put(session.id, session);
      return Result.success(null);
    } catch (e) {
      _logger.w('Error saving session', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Session?>> get(String id) async {
    try {
      final session = _box.get(id);
      return Result.success(session);
    } catch (e) {
      _logger.w('Error getting session $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getAll() async {
    try {
      final sessions = _box.values.toList();
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return Result.success(sessions);
    } catch (e) {
      _logger.w('Error getting all sessions', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getByDate(DateTime date) async {
    try {
      final start = date.dateOnly;
      final end = start.add(Timeouts.day);
      final all = _box.values.toList();
      final filtered = all.where((s) =>
          s.startTime.isAfter(start.subtract(Timeouts.second)) &&
          s.startTime.isBefore(end)).toList();
      return Result.success(filtered);
    } catch (e) {
      _logger.w('Error getting sessions by date', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getByType(SessionType type) async {
    try {
      final all = _box.values.toList();
      return Result.success(all.where((s) => s.type == type).toList());
    } catch (e) {
      _logger.w('Error getting sessions by type', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getByStudent(String studentId) async {
    try {
      final all = _box.values.toList();
      return Result.success(all.where((s) => s.studentId == studentId).toList());
    } catch (e) {
      _logger.w('Error getting sessions by student', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getBySubject(String subjectId) async {
    try {
      final all = _box.values.toList();
      return Result.success(all.where((s) => s.subjectId == subjectId).toList());
    } catch (e) {
      _logger.w('Error getting sessions by subject', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    try {
      final all = _box.values.toList();
      return Result.success(all
          .where((s) => s.studentId == studentId && s.subjectId == subjectId)
          .toList());
    } catch (e) {
      _logger.w('Error getting sessions by student and subject', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getRecentSessionsForSubject(String subjectId,
      {int limit = 10}) async {
    try {
      final all = _box.values.toList();
      final filtered = all.where((s) => s.subjectId == subjectId).toList();
      filtered.sort((a, b) =>
          b.startTime.millisecondsSinceEpoch
              .compareTo(a.startTime.millisecondsSinceEpoch));
      return Result.success(filtered.take(limit).toList());
    } catch (e) {
      _logger.w('Error getting recent sessions', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getTotalStudyTimeForSubject(String subjectId) async {
    try {
      final all = _box.values.toList();
      return Result.success(all
          .where((s) => s.subjectId == subjectId)
          .fold<int>(0, (sum, s) => sum + s.actualDurationMs));
    } catch (e) {
      _logger.w('Error getting total study time', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Session>>> getActive() async {
    try {
      final all = _box.values.toList();
      return Result.success(all.where((s) => s.isActive).toList());
    } catch (e) {
      _logger.w('Error getting active sessions', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _box.delete(id);
      return Result.success(null);
    } catch (e) {
      _logger.w('Error deleting session', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> clearAll() async {
    try {
      await _box.clear();
      return Result.success(null);
    } catch (e) {
      _logger.w('Error clearing sessions', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getTodayDurationMs() async {
    try {
      final todayResult = await getByDate(DateTime.now());
      if (todayResult.isFailure) return Result.failure(todayResult.error);
      return Result.success(
          todayResult.data!.fold<int>(0, (sum, s) => sum + s.actualDurationMs));
    } catch (e) {
      _logger.w('Error getting today duration', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getTodaySessionCount() async {
    try {
      final todayResult = await getByDate(DateTime.now());
      if (todayResult.isFailure) return Result.failure(todayResult.error);
      return Result.success(todayResult.data!.length);
    } catch (e) {
      _logger.w('Error getting today session count', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getTodayCompletedSessionCount() async {
    try {
      final todayResult = await getByDate(DateTime.now());
      if (todayResult.isFailure) return Result.failure(todayResult.error);
      return Result.success(todayResult.data!.where((s) => s.completed).length);
    } catch (e) {
      _logger.w('Error getting completed session count', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getWeeklyDurationMs() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(Timeouts.week);
      final all = _box.values.toList();
      return Result.success(all
          .where((s) => s.startTime.isAfter(weekAgo))
          .fold<int>(0, (sum, s) => sum + s.actualDurationMs));
    } catch (e) {
      _logger.w('Error getting weekly duration', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getTodayStats() async {
    try {
      final now = DateTime.now();
      final sessionsResult = await getByDate(now);
      if (sessionsResult.isFailure) return Result.failure(sessionsResult.error);
      final sessions = sessionsResult.data!;
      final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
      final completed = sessions.where((s) => s.completed).length;
      final plannedMinutes = sessions.fold<int>(0, (sum, s) =>
          sum + (s.plannedDurationMinutes ?? 0));

      return Result.success({
        'totalMs': totalMs,
        'totalSeconds': totalMs ~/ 1000,
        'completedSessions': completed,
        'totalSessions': sessions.length,
        'plannedMinutes': plannedMinutes,
      });
    } catch (e) {
      _logger.w('Error getting today stats', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getSubjectStats(String subjectId) async {
    try {
      final sessionsResult = await getBySubject(subjectId);
      if (sessionsResult.isFailure) return Result.failure(sessionsResult.error);
      final sessions = sessionsResult.data!;
      final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
      final totalQuestions = sessions.fold<int>(0, (sum, s) => sum + s.questionsAnswered);
      final totalCorrect = sessions.fold<int>(0, (sum, s) => sum + s.correctAnswers);
      return Result.success({
        'totalSessions': sessions.length,
        'totalDurationMs': totalMs,
        'totalQuestions': totalQuestions,
        'totalCorrect': totalCorrect,
        'avgScore': totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0,
      });
    } catch (e) {
      _logger.w('Error getting subject stats', e);
      return Result.failure(e.toString());
    }
  }
}