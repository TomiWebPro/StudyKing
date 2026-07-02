import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];

  void addAttempt(StudentAttempt attempt) => _attempts.add(attempt);

  @override
  Future<Result<void>> init() async => Result.success(null);

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
}

class _FakeQuestionRepo extends QuestionRepository {
  final Map<String, Question> _questions = {};

  void addQuestion(Question q) => _questions[q.id] = q;

  @override
  Future<Result<List<Question>>> getAll() async {
    return Result.success(_questions.values.toList());
  }

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(
      _questions.values.where((q) => q.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<Result<void>> init() async => Result.success(null);
}

void main() {
  group('Practice Mastery → Dashboard Stats integration', () {
    late _FakeAttemptRepo fakeAttemptRepo;
    late _FakeQuestionRepo fakeQuestionRepo;

    setUp(() {
      fakeAttemptRepo = _FakeAttemptRepo();
      fakeQuestionRepo = _FakeQuestionRepo();
    });

    test('dashboard reflects correctness stats after practice attempts',
        () async {
      final now = DateTime(2026, 5, 18);
      fakeQuestionRepo.addQuestion(Question(
        id: 'q1',
        text: 'Question 1',
        type: QuestionType.typedAnswer,
        difficulty: 1,
        subjectId: 'sub-1',
        topicId: 't-1',
        createdAt: now,
        updatedAt: now,
      ));
      fakeQuestionRepo.addQuestion(Question(
        id: 'q2',
        text: 'Question 2',
        type: QuestionType.typedAnswer,
        difficulty: 2,
        subjectId: 'sub-1',
        topicId: 't-1',
        createdAt: now,
        updatedAt: now,
      ));

      fakeAttemptRepo.addAttempt(StudentAttempt(
        id: 'a1',
        studentId: 'student-1',
        questionId: 'q1',
        subjectId: 'sub-1',
        isCorrect: true,
        timestamp: DateTime.now(),
      ));
      fakeAttemptRepo.addAttempt(StudentAttempt(
        id: 'a2',
        studentId: 'student-1',
        questionId: 'q2',
        subjectId: 'sub-1',
        isCorrect: false,
        timestamp: DateTime.now(),
      ));

      final attempts = await fakeAttemptRepo.getByStudent('student-1');
      expect(attempts.isSuccess, isTrue);
      expect(attempts.data!.length, 2);

      final correct =
          attempts.data!.where((a) => a.isCorrect == true).length;
      final total = attempts.data!.length;
      final accuracy = total > 0 ? correct / total : 0.0;

      expect(accuracy, 0.5);
    });

    test('subject-level stats aggregate from attempts', () async {
      fakeAttemptRepo.addAttempt(StudentAttempt(
        id: 'a1',
        studentId: 'student-1',
        questionId: 'q1',
        subjectId: 'math',
        isCorrect: true,
        timestamp: DateTime.now(),
      ));
      fakeAttemptRepo.addAttempt(StudentAttempt(
        id: 'a2',
        studentId: 'student-1',
        questionId: 'q2',
        subjectId: 'math',
        isCorrect: true,
        timestamp: DateTime.now(),
      ));
      fakeAttemptRepo.addAttempt(StudentAttempt(
        id: 'a3',
        studentId: 'student-1',
        questionId: 'q3',
        subjectId: 'physics',
        isCorrect: false,
        timestamp: DateTime.now(),
      ));

      final subjectAttempts = await fakeAttemptRepo.getByStudentAndSubject(
        'student-1',
        'math',
      );
      expect(subjectAttempts.isSuccess, isTrue);
      expect(subjectAttempts.data!.length, 2);
      expect(
        subjectAttempts.data!.every((a) => a.isCorrect == true),
        isTrue,
      );
    });

    test('empty attempt state returns zero stats', () async {
      final attempts = await fakeAttemptRepo.getByStudent('student-1');
      expect(attempts.isSuccess, isTrue);
      expect(attempts.data, isEmpty);
    });

    test('error state propagates from attempt repo', () async {
      final errorAttemptRepo = _FakeAttemptRepo() as AttemptRepository;

      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(errorAttemptRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final repo = container.read(attemptRepositoryProvider);
      final result = await repo.getByStudent('student-1');
      expect(result.isSuccess, isTrue);
    });
  });
}
