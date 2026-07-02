import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];
  bool throwOnGetBySubject = false;

  @override
  Future<Result<void>> init() async => Result.success(null);

  void addAttempt(StudentAttempt attempt) {
    _attempts.add(attempt);
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(
      _attempts.where((a) => a.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    return Result.success(
      _attempts
          .where((a) => a.studentId == studentId && a.subjectId == subjectId)
          .toList(),
    );
  }

  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async {
    return Result.success(
      _attempts.where((a) => a.questionId == questionId).toList(),
    );
  }

  @override
  Future<Result<List<StudentAttempt>>> getBySubject(String subjectId) async {
    if (throwOnGetBySubject) {
      return Result.failure('getBySubject error');
    }
    return Result.success(
      _attempts.where((a) => a.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    _attempts.add(attempt);
    return Result.success(null);
  }
}

StudentAttempt _createAttempt({
  String id = 'a1',
  String studentId = 'stu1',
  String questionId = 'q1',
  String subjectId = 'sub1',
  bool isCorrect = true,
}) {
  return StudentAttempt(
    id: id,
    studentId: studentId,
    questionId: questionId,
    subjectId: subjectId,
    isCorrect: isCorrect,
    timestamp: DateTime(2025, 1, 15, 10, 0),
  );
}

void main() {
  group('AttemptRepository', () {
    late _FakeAttemptRepository repo;

    setUp(() {
      repo = _FakeAttemptRepository();
    });

    group('create', () {
      test('stores attempt and returns success', () async {
        final attempt = _createAttempt();
        final result = await repo.create(attempt);
        expect(result.isSuccess, isTrue);
        final byStudent = await repo.getByStudent('stu1');
        expect(byStudent.data!.length, 1);
        expect(byStudent.data!.first.id, 'a1');
      });
    });

    group('getByStudent', () {
      test('returns attempts for given student', () async {
        repo.addAttempt(_createAttempt(id: 'a1', studentId: 'stu1'));
        repo.addAttempt(_createAttempt(id: 'a2', studentId: 'stu2'));

        final result = await repo.getByStudent('stu1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'a1');
      });

      test('returns empty list when no attempts exist', () async {
        final result = await repo.getByStudent('unknown');
        expect(result.isSuccess, isTrue);
        expect(result.data!, isEmpty);
      });
    });

    group('getByStudentAndSubject', () {
      test('returns filtered attempts', () async {
        repo.addAttempt(_createAttempt(id: 'a1', studentId: 'stu1', subjectId: 'math'));
        repo.addAttempt(_createAttempt(id: 'a2', studentId: 'stu1', subjectId: 'science'));

        final result = await repo.getByStudentAndSubject('stu1', 'math');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'a1');
      });
    });

    group('getByQuestion', () {
      test('returns attempts for given question', () async {
        repo.addAttempt(_createAttempt(id: 'a1', questionId: 'q1'));
        repo.addAttempt(_createAttempt(id: 'a2', questionId: 'q2'));

        final result = await repo.getByQuestion('q1');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'a1');
      });
    });

    group('getBySubject', () {
      test('returns attempts for given subject', () async {
        repo.addAttempt(_createAttempt(id: 'a1', subjectId: 'math'));
        repo.addAttempt(_createAttempt(id: 'a2', subjectId: 'science'));

        final result = await repo.getBySubject('math');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'a1');
      });

      test('returns failure when repository errors', () async {
        repo.throwOnGetBySubject = true;
        final result = await repo.getBySubject('math');
        expect(result.isFailure, isTrue);
      });
    });

    group('getSubjectStats', () {
      test('calculates correct stats', () async {
        repo.addAttempt(_createAttempt(id: 'a1', subjectId: 'math', isCorrect: true));
        repo.addAttempt(_createAttempt(id: 'a2', subjectId: 'math', isCorrect: false));

        final result = await repo.getSubjectStats('math');
        expect(result.isSuccess, isTrue);
        expect(result.data!['total'], 2);
        expect(result.data!['correct'], 1);
        expect(result.data!['incorrect'], 1);
        expect(result.data!['accuracy'], 0.5);
      });

      test('returns zero stats when no attempts', () async {
        final result = await repo.getSubjectStats('empty');
        expect(result.isSuccess, isTrue);
        expect(result.data!['total'], 0);
        expect(result.data!['accuracy'], 0.0);
      });

      test('returns failure when getBySubject fails', () async {
        repo.throwOnGetBySubject = true;
        final result = await repo.getSubjectStats('math');
        expect(result.isFailure, isTrue);
      });
    });
  });
}
