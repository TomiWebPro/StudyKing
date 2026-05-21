import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';

class TutorSessionRepository extends Repository<TutorSession> {
  Future<void> init() async {
    await openBox(HiveBoxNames.tutorSessions);
  }

  Future<Result<void>> create(TutorSession session) async {
    return super.put(session.id, session);
  }

  Future<Result<void>> saveSession(TutorSession session) async {
    return create(session);
  }

  Future<Result<TutorSession?>> getSession(String id) async {
    return super.get(id);
  }

  Future<Result<List<TutorSession>>> getAllSessions() async {
    return Result.capture(() async {
      final getAllResult = await getAll();
      final all = getAllResult.data ?? [];
      all.sort((a, b) => b.startTime.compareTo(a.startTime));
      return all;
    }, context: 'getAllSessions');
  }

  Future<Result<List<TutorSession>>> getStudentSessions(
      String studentId) async {
    return Result.capture(() async {
      final sessions = filterBy((s) => s.studentId, studentId);
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    }, context: 'getStudentSessions');
  }

  Future<Result<List<TutorSession>>> getSubjectSessions(
    String studentId,
    String subjectId,
  ) async {
    return Result.capture(() async {
      final byStudent = filterBy((s) => s.studentId, studentId);
      return byStudent.where((s) => s.subjectId == subjectId).toList();
    }, context: 'getSubjectSessions');
  }

  Future<Result<List<TutorSession>>> getActiveSessions() async {
    return Result.capture(
      () async => filterBy((s) => s.status, SessionStatus.inProgress),
      context: 'getActiveSessions',
    );
  }

  Future<Result<List<TutorSession>>> getCompletedSessions(
      String studentId) async {
    return Result.capture(() async {
      final byStudent = filterBy((s) => s.studentId, studentId);
      return byStudent.where((s) => s.status == SessionStatus.completed).toList();
    }, context: 'getCompletedSessions');
  }

  Future<Result<void>> deleteSession(String id) async {
    return super.delete(id);
  }

  Future<Result<void>> clearAll() async {
    return Result.capture(() async {
      await box.clear();
    }, context: 'clearAll');
  }

  Future<Result<Map<String, dynamic>>> getSessionStats(
      String studentId) async {
    try {
      final sessionsResult = await getStudentSessions(studentId);
      if (sessionsResult.isFailure) {
        return Result.failure(sessionsResult.error);
      }
      final sessions = sessionsResult.data!;
      final completed =
          sessions.where((s) => s.status == SessionStatus.completed);

      return Result.success({
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
      });
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
