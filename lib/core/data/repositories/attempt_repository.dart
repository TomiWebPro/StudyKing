import 'package:hive_flutter/hive_flutter.dart';
import '../models/student_attempt_model.dart';

class AttemptRepository {
  late Box<StudentAttempt> _box;

  Future<void> init() async {
    _box = Hive.box<StudentAttempt>('attempts');
  }

  Future<void> create(StudentAttempt attempt) async {
    await _box.put(attempt.id, attempt);
  }

  Future<StudentAttempt?> get(String id) async {
    return _box.get(id);
  }

  Future<List<StudentAttempt>> getAll() async {
    return _box.values.toList();
  }

  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    final all = _box.values.toList();
    return all.where((a) => a.studentId == studentId).toList();
  }

  Future<List<StudentAttempt>> getByStudentAndSubject(String studentId, String subjectId) async {
    final all = _box.values.toList();
    return all.where((a) => 
      a.studentId == studentId && a.subjectId == subjectId
    ).toList();
  }

  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    final all = _box.values.toList();
    return all.where((a) => a.questionId == questionId).toList();
  }

  Future<List<StudentAttempt>> getBySubject(String subjectId) async {
    final all = _box.values.toList();
    return all.where((a) => a.subjectId == subjectId).toList();
  }

  /// Get correct and incorrect counts for a subject
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

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
