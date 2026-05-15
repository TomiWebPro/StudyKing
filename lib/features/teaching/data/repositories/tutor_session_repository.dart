import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/core/data/repository.dart';

class TutorSessionRepository extends Repository<TutorSession> {
  Future<void> init() async {
    await openBox(HiveBoxNames.tutorSessions);
  }

  Future<void> create(TutorSession session) async {
    await save(session.id, session);
  }

  Future<void> saveSession(TutorSession session) async {
    await create(session);
  }

  Future<TutorSession?> getSession(String id) async {
    return get(id);
  }

  Future<List<TutorSession>> getAllSessions() async {
    final all = await getAll();
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    return all;
  }

  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    final sessions = filterBy((s) => s.studentId, studentId);
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  Future<List<TutorSession>> getSubjectSessions(
    String studentId,
    String subjectId,
  ) async {
    final byStudent = filterBy((s) => s.studentId, studentId);
    return byStudent.where((s) => s.subjectId == subjectId).toList();
  }

  Future<List<TutorSession>> getActiveSessions() async {
    return filterBy((s) => s.status, SessionStatus.inProgress);
  }

  Future<List<TutorSession>> getCompletedSessions(String studentId) async {
    final byStudent = filterBy((s) => s.studentId, studentId);
    return byStudent.where((s) => s.status == SessionStatus.completed).toList();
  }

  Future<void> deleteSession(String id) async {
    await delete(id);
  }

  Future<void> clearAll() async {
    await box.clear();
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
      'totalQuestions':
          completed.fold<int>(0, (sum, s) => sum + s.questionsAsked),
      'averageAccuracy': completed.isEmpty
          ? 0.0
          : completed.fold<double>(0, (sum, s) => sum + s.accuracy) /
              completed.length,
    };
  }
}
