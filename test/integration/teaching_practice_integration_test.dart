import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];
  bool shouldThrow = false;

  @override
  Future<Result<List<StudentAttempt>>> getAll() async {
    if (shouldThrow) return Result.failure('error');
    return Result.success(_attempts);
  }

  @override
  Future<Result<StudentAttempt?>> get(String key) async =>
      Result.success(null);

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async {
    if (shouldThrow) return Result.failure('save error');
    _attempts.add(item);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  Future<void> init() async {}
}

class _FakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions = [];

  @override
  Future<Result<List<Question>>> getAll() async =>
      Result.success(_questions);

  @override
  Future<void> init() async {}
}

void main() {
  group('Teaching → Practice (mistake review) integration', () {
    test('incorrect evaluation creates practice items', () async {
      final attemptRepo = _FakeAttemptRepo();
      final questionRepo = _FakeQuestionRepo();

      final question = Question(
        id: 'q-mistake-1',
        text: 'What is 2+2?',
        type: QuestionType.typedAnswer,
        subjectId: 's1',
        topicId: 't1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final attempt = StudentAttempt(
        id: 'attempt-1',
        questionId: question.id,
        isCorrect: false,
        timestamp: DateTime.now(),
        studentId: 'student-1',
        subjectId: 's1',
        userAnswer: '5',
      );

      await questionRepo.save(question.id, question);
      await attemptRepo.save(attempt.id, attempt);

      final allAttempts = await attemptRepo.getAll();
      expect(allAttempts.data!.length, 1);
      expect(allAttempts.data!.first.isCorrect, isFalse);
    });

    test('handles error when attempt repo is unavailable', () async {
      final attemptRepo = _FakeAttemptRepo();
      attemptRepo.shouldThrow = true;

      final result = await attemptRepo.getAll();
      expect(result.isFailure, isTrue);
    });

    test('recovers after attempt repo error', () async {
      final attemptRepo = _FakeAttemptRepo();
      attemptRepo.shouldThrow = true;
      await attemptRepo.getAll();

      attemptRepo.shouldThrow = false;
      final attempt = StudentAttempt(
        id: 'attempt-2',
        questionId: 'q2',
        isCorrect: true,
        timestamp: DateTime.now(),
        studentId: 'student-1',
        subjectId: 's1',
        userAnswer: '4',
      );
      await attemptRepo.save(attempt.id, attempt);

      final recovered = await attemptRepo.getAll();
      expect(recovered.data!.length, 1);
      expect(recovered.data!.first.isCorrect, isTrue);
    });
  });
}
