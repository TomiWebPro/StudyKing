import 'package:hive_flutter/hive_flutter.dart';
import '../models/study_session_model.dart';

class StudySessionRepository {
  late Box<StudySession> _box;

  Future<void> init() async {
    _box = Hive.box<StudySession>('sessions');
  }

  Future<void> create(StudySession session) async {
    await _box.put(session.id, session);
  }

  Future<StudySession?> get(String id) async {
    return _box.get(id);
  }

  Future<List<StudySession>> getAll() async {
    return _box.values.toList();
  }

  Future<List<StudySession>> getByStudent(String studentId) async {
    final all = _box.values.toList();
    return all.where((s) => s.studentId == studentId).toList();
  }

  Future<List<StudySession>> getBySubject(String subjectId) async {
    final all = _box.values.toList();
    return all.where((s) => s.subjectId == subjectId).toList();
  }

  Future<List<StudySession>> getByStudentAndSubject(String studentId, String subjectId) async {
    final all = _box.values.toList();
    return all.where((s) => 
      s.studentId == studentId && s.subjectId == subjectId
    ).toList();
  }

  /// Get recent sessions for a subject
  Future<List<StudySession>> getRecentSessionsForSubject(String subjectId, {int limit = 10}) async {
    final sessions = await getBySubject(subjectId);
    sessions.sort((a, b) => b.startTime.millisecondsSinceEpoch.compareTo(a.startTime.millisecondsSinceEpoch));
    return sessions.take(limit).toList();
  }

  /// Get total study time for a subject
  Future<int> getTotalStudyTimeForSubject(String subjectId) async {
    final sessions = await getBySubject(subjectId);
    return sessions.fold<int>(0, (sum, s) => sum + (s.timeSpentMs ??= 0));
  }

  Future<void> updateQuestionCount(String id, int count) async {
    final session = await get(id);
    if (session != null) {
      final updated = session.copyWith(questionsAnswered: count);
      await _box.put(id, updated);
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
