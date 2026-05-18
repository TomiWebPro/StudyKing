import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repository.dart';

class AttemptRepository extends Repository<StudentAttempt> {
  Future<void> init() async {
    await openBox(HiveBoxNames.attempts);
  }

  Future<Result<void>> create(StudentAttempt attempt) async {
    return super.put(attempt.id, attempt);
  }

  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.capture(
      () async => filterBy((a) => a.studentId, studentId),
      context: 'getByStudent',
    );
  }

  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    return Result.capture(() async {
      final byStudent = filterBy((a) => a.studentId, studentId);
      return byStudent.where((a) => a.subjectId == subjectId).toList();
    }, context: 'getByStudentAndSubject');
  }

  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async {
    return Result.capture(
      () async => filterBy((a) => a.questionId, questionId),
      context: 'getByQuestion',
    );
  }

  Future<Result<List<StudentAttempt>>> getBySubject(String subjectId) async {
    return Result.capture(
      () async => filterBy((a) => a.subjectId, subjectId),
      context: 'getBySubject',
    );
  }

  Future<Result<Map<String, dynamic>>> getSubjectStats(
      String subjectId) async {
    try {
      final attemptsResult = await getBySubject(subjectId);
      if (attemptsResult.isFailure) {
        return Result.failure(attemptsResult.error);
      }
      final attempts = attemptsResult.data!;
      final correct = attempts.where((a) => a.isCorrect).length;
      final total = attempts.length;

      return Result.success({
        'total': total,
        'correct': correct,
        'incorrect': total - correct,
        'accuracy': total > 0 ? correct / total : 0.0,
      });
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
