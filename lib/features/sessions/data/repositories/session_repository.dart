import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/logger.dart';

class SessionRepository {
  final Logger _logger = const Logger('SessionRepository');

  Box<String> get _box => Hive.box<String>(HiveBoxNames.sessions);

  Future<void> init() async {}

  Future<void> save(Session session) async {
    await _box.put(session.id, jsonEncode(session.toJson()));
  }

  Future<Session?> get(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw));
    } catch (e) {
      _logger.e('Error decoding session $id', e);
      return null;
    }
  }

  Future<List<Session>> getAll() async {
    final sessions = <Session>[];
    for (final raw in _box.values) {
      try {
        sessions.add(Session.fromJson(jsonDecode(raw)));
      } catch (e) {
        _logger.e('Error decoding session', e);
      }
    }
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<List<Session>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final all = await getAll();
    return all.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
  }

  Future<List<Session>> getByType(SessionType type) async {
    final all = await getAll();
    return all.where((s) => s.type == type).toList();
  }

  Future<List<Session>> getByStudent(String studentId) async {
    final all = await getAll();
    return all.where((s) => s.studentId == studentId).toList();
  }

  Future<List<Session>> getBySubject(String subjectId) async {
    final all = await getAll();
    return all.where((s) => s.subjectId == subjectId).toList();
  }

  Future<List<Session>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    final all = await getAll();
    return all.where((s) => s.studentId == studentId && s.subjectId == subjectId).toList();
  }

  Future<List<Session>> getRecentSessionsForSubject(String subjectId,
      {int limit = 10}) async {
    final all = await getAll();
    final filtered = all.where((s) => s.subjectId == subjectId).toList();
    filtered.sort((a, b) =>
        b.startTime.millisecondsSinceEpoch
            .compareTo(a.startTime.millisecondsSinceEpoch));
    return filtered.take(limit).toList();
  }

  Future<int> getTotalStudyTimeForSubject(String subjectId) async {
    final all = await getAll();
    return all
        .where((s) => s.subjectId == subjectId)
        .fold<int>(0, (sum, s) => sum + s.actualDurationMs);
  }

  Future<List<Session>> getActive() async {
    final all = await getAll();
    return all.where((s) => s.isActive).toList();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<int> getTodayDurationMs() async {
    final today = await getByDate(DateTime.now());
    return today.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
  }

  Future<int> getTodaySessionCount() async {
    final today = await getByDate(DateTime.now());
    return today.length;
  }

  Future<int> getTodayCompletedSessionCount() async {
    final today = await getByDate(DateTime.now());
    return today.where((s) => s.completed).length;
  }

  Future<int> getWeeklyDurationMs() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final all = await getAll();
    return all
        .where((s) => s.startTime.isAfter(weekAgo))
        .fold<int>(0, (sum, s) => sum + s.actualDurationMs);
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final now = DateTime.now();
    final sessions = await getByDate(now);
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
      'hours': ((totalMs / 3600000)).toStringAsFixed(1),
    };
  }

  Future<Map<String, dynamic>> getSubjectStats(String subjectId) async {
    final sessions = await getBySubject(subjectId);
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
  }
}
