import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repository.dart';

class AttemptRepository extends Repository<StudentAttempt> {
  Future<void> init() async {
    await openBox(HiveBoxNames.attempts);
  }

  Future<void> create(StudentAttempt attempt) async {
    await save(attempt.id, attempt);
  }

  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return filterBy((a) => a.studentId, studentId);
  }

  Future<List<StudentAttempt>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    final byStudent = filterBy((a) => a.studentId, studentId);
    return byStudent.where((a) => a.subjectId == subjectId).toList();
  }

  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    return filterBy((a) => a.questionId, questionId);
  }

  Future<List<StudentAttempt>> getBySubject(String subjectId) async {
    return filterBy((a) => a.subjectId, subjectId);
  }

  Future<Map<String, dynamic>> getSubjectStats(String subjectId) async {
    final attempts = await getBySubject(subjectId);
    final correct = attempts.where((a) => a.isCorrect).length;
    final total = attempts.length;

    return {
      'total': total,
      'correct': correct,
      'incorrect': total - correct,
      'accuracy': total > 0 ? correct / total : 0.0,
    };
  }
}
