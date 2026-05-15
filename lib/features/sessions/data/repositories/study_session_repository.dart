import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/core/data/repository.dart';

class StudySessionRepository extends Repository<StudySession> {
  Future<void> init() async {
    await openBox(HiveBoxNames.sessions);
  }

  Future<void> create(StudySession session) async {
    await save(session.id, session);
  }

  Future<List<StudySession>> getByStudent(String studentId) async {
    return filterBy((s) => s.studentId, studentId);
  }

  Future<List<StudySession>> getBySubject(String subjectId) async {
    return filterBy((s) => s.subjectId, subjectId);
  }

  Future<List<StudySession>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    final byStudent = filterBy((s) => s.studentId, studentId);
    return byStudent.where((s) => s.subjectId == subjectId).toList();
  }

  Future<List<StudySession>> getRecentSessionsForSubject(String subjectId,
      {int limit = 10}) async {
    final sessions = await getBySubject(subjectId);
    sessions.sort((a, b) =>
        b.startTime.millisecondsSinceEpoch
            .compareTo(a.startTime.millisecondsSinceEpoch));
    return sessions.take(limit).toList();
  }

  Future<int> getTotalStudyTimeForSubject(String subjectId) async {
    final sessions = await getBySubject(subjectId);
    return sessions.fold<int>(0, (sum, s) => sum + s.timeSpentMs);
  }

  Future<void> updateQuestionCount(String id, int count) async {
    final session = await get(id);
    if (session != null) {
      final updated = session.copyWith(questionsAnswered: count);
      await save(id, updated);
    }
  }
}
