import 'package:hive_flutter/hive_flutter.dart';
import '../models/tutor_session_model.dart';

class TutorSessionRepository {
  Box<TutorSession>? _sessionBox;

  TutorSessionRepository({Box<TutorSession>? sessionBox})
      : _sessionBox = sessionBox;

  Future<void> init() async {
    _sessionBox = await Hive.openBox<TutorSession>('tutor_sessions');
  }

  Box<TutorSession> get _box {
    if (_sessionBox == null) {
      throw StateError('TutorSessionRepository not initialized');
    }
    return _sessionBox!;
  }

  Future<void> saveSession(TutorSession session) async {
    await _box.put(session.id, session);
  }

  Future<TutorSession?> getSession(String id) async {
    return _box.get(id);
  }

  Future<List<TutorSession>> getAllSessions() async {
    final all = _box.values.toList();
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    return all;
  }

  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    final sessions = _box.values
        .where((s) => s.studentId == studentId)
        .toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<List<TutorSession>> getSubjectSessions(
    String studentId,
    String subjectId,
  ) async {
    return _box.values
        .where((s) => s.studentId == studentId && s.subjectId == subjectId)
        .toList();
  }

  Future<List<TutorSession>> getActiveSessions() async {
    return _box.values
        .where((s) => s.status == SessionStatus.inProgress)
        .toList();
  }

  Future<List<TutorSession>> getCompletedSessions(String studentId) async {
    return _box.values
        .where((s) =>
            s.studentId == studentId && s.status == SessionStatus.completed)
        .toList();
  }

  Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<Map<String, dynamic>> getSessionStats(String studentId) async {
    final sessions = await getStudentSessions(studentId);
    final completed =
        sessions.where((s) => s.status == SessionStatus.completed);

    return {
      'totalSessions': sessions.length,
      'completedSessions': completed.length,
      'totalHours': completed.fold<double>(
          0, (sum, s) => sum + (s.elapsedMinutes / 60.0)),
      'totalQuestions': completed.fold<int>(
          0, (sum, s) => sum + s.questionsAsked),
      'averageAccuracy': completed.isEmpty
          ? 0.0
          : completed.fold<double>(0, (sum, s) => sum + s.accuracy) /
              completed.length,
    };
  }
}
