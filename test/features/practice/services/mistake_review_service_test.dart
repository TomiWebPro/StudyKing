import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];

  @override
  Future<void> init() async {}

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
}

class _FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> _questions = {};

  @override
  Future<void> init() async {}

  void addQuestion(Question q) {
    _questions[q.id] = q;
  }

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(_questions[id]);
  }
}

Question _createQuestion({
  String id = 'q1',
  String subjectId = 'sub1',
}) {
  return Question(
    id: id,
    text: 'Test question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: 't1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    markscheme: null,
  );
}

void main() {
  group('MistakeReviewService', () {
    late _FakeAttemptRepository attemptRepo;
    late _FakeQuestionRepository questionRepo;
    late MistakeReviewService service;

    setUp(() {
      attemptRepo = _FakeAttemptRepository();
      questionRepo = _FakeQuestionRepository();
      service = MistakeReviewService(
        attemptRepo: attemptRepo,
        questionRepo: questionRepo,
      );
    });

    group('getMistakesFromSession', () {
      test('returns mistakes for incorrect attempts', () async {
        questionRepo.addQuestion(_createQuestion(id: 'q1'));
        questionRepo.addQuestion(_createQuestion(id: 'q2'));

        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'wrong',
        ));
        attemptRepo.addAttempt(StudentAttempt(
          id: 'a2',
          studentId: 's1',
          questionId: 'q2',
          subjectId: 'sub1',
          isCorrect: true,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'correct',
        ));

        final mistakes = await service.getMistakesFromSession(
          studentId: 's1',
          subjectId: 'sub1',
        );

        expect(mistakes, hasLength(1));
        expect(mistakes.data!.first.attempt!.questionId, 'q1');
      });

      test('returns empty when no incorrect attempts', () async {
        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: true,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'correct',
        ));

        final mistakes = await service.getMistakesFromSession(
          studentId: 's1',
          subjectId: 'sub1',
        );

        expect(mistakes, isEmpty);
      });

      test('applies date filter', () async {
        questionRepo.addQuestion(_createQuestion(id: 'q1'));

        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2025, 1, 1),
          userAnswer: 'wrong',
        ));

        final mistakes = await service.getMistakesFromSession(
          studentId: 's1',
          subjectId: 'sub1',
          after: DateTime(2026, 1, 1),
        );

        expect(mistakes, isEmpty);
      });

      test('deduplicates repeated mistakes for same question', () async {
        questionRepo.addQuestion(_createQuestion(id: 'q1'));

        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'wrong1',
        ));
        attemptRepo.addAttempt(StudentAttempt(
          id: 'a2',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 2),
          userAnswer: 'wrong2',
        ));

        final mistakes = await service.getMistakesFromSession(
          studentId: 's1',
          subjectId: 'sub1',
        );

        expect(mistakes, hasLength(1));
      });
    });

    group('getPendingMistakes', () {
      test('returns mistakes not yet corrected', () async {
        questionRepo.addQuestion(_createQuestion(id: 'q1'));

        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'wrong',
        ));

        final pending = await service.getPendingMistakes(
          studentId: 's1',
          subjectId: 'sub1',
        );

        expect(pending, hasLength(1));
      });

      test('excludes questions corrected after mistake', () async {
        questionRepo.addQuestion(_createQuestion(id: 'q1'));

        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'wrong',
        ));
        attemptRepo.addAttempt(StudentAttempt(
          id: 'a2',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: true,
          timestamp: DateTime(2026, 1, 2),
          userAnswer: 'correct',
        ));

        final pending = await service.getPendingMistakes(
          studentId: 's1',
          subjectId: 'sub1',
        );

        expect(pending, isEmpty);
      });
    });

    group('isQuestionCorrected', () {
      test('returns true when question has been answered correctly', () async {
        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: true,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'correct',
        ));

        final corrected = await service.isQuestionCorrected('q1');
        expect(corrected, isTrue);
      });

      test('returns false when question never answered correctly', () async {
        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'wrong',
        ));

        final corrected = await service.isQuestionCorrected('q1');
        expect(corrected, isFalse);
      });
    });

    group('extractRedoQuestions', () {
      test('extracts questions from mistake entries', () async {
        questionRepo.addQuestion(_createQuestion(id: 'q1'));
        questionRepo.addQuestion(_createQuestion(id: 'q2'));

        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'wrong',
        ));

        final mistakes = await service.getMistakesFromSession(
          studentId: 's1',
          subjectId: 'sub1',
        );

        final redoQuestions = service.extractRedoQuestions(mistakes.data!);
        expect(redoQuestions, hasLength(1));
        expect(redoQuestions.first.id, 'q1');
      });
    });

    test('returns empty for student with no attempts', () async {
      final mistakes = await service.getMistakesFromSession(
        studentId: 'nonexistent',
        subjectId: 'sub1',
      );
      expect(mistakes, isEmpty);
    });

    group('error-state: repository failures', () {
      test('getMistakesFromSession handles attemptRepo failure', () async {
        final failingRepo = _FailingAttemptRepository();
        final localService = MistakeReviewService(
          attemptRepo: failingRepo,
          questionRepo: questionRepo,
        );
        final mistakes = await localService.getMistakesFromSession(
          studentId: 's1',
          subjectId: 'sub1',
        );
        expect(mistakes, isEmpty);
      });

      test('getMistakesFromSession handles questionRepo failure', () async {
        attemptRepo.addAttempt(StudentAttempt(
          id: 'a1',
          studentId: 's1',
          questionId: 'q1',
          subjectId: 'sub1',
          isCorrect: false,
          timestamp: DateTime(2026, 1, 1),
          userAnswer: 'wrong',
        ));
        final failingRepo = _FailingQuestionRepository();
        final localService = MistakeReviewService(
          attemptRepo: attemptRepo,
          questionRepo: failingRepo,
        );
        final mistakes = await localService.getMistakesFromSession(
          studentId: 's1',
          subjectId: 'sub1',
        );
        expect(mistakes, isEmpty);
      });

      test('getPendingMistakes handles attemptRepo failure', () async {
        final failingRepo = _FailingAttemptRepository();
        final localService = MistakeReviewService(
          attemptRepo: failingRepo,
          questionRepo: questionRepo,
        );
        final pending = await localService.getPendingMistakes(
          studentId: 's1',
          subjectId: 'sub1',
        );
        expect(pending, isEmpty);
      });
    });
  });


  group('MistakeReviewService - coverage gaps', () {
  late _FakeAttemptRepo3 attemptRepo;
  late _FakeQuestionRepo3 questionRepo;
  late MistakeReviewService service;

  setUp(() {
    attemptRepo = _FakeAttemptRepo3();
    questionRepo = _FakeQuestionRepo3();
    service = MistakeReviewService(
      attemptRepo: attemptRepo,
      questionRepo: questionRepo,
    );
  });

  test('getMistakesFromSession skips when question not found', () async {
    attemptRepo.addAttempt(StudentAttempt(
      id: 'a1',
      studentId: 's1',
      questionId: 'nonexistent',
      subjectId: 'sub1',
      isCorrect: false,
      timestamp: DateTime(2026, 1, 1),
      userAnswer: 'wrong',
    ));

    final mistakes = await service.getMistakesFromSession(
      studentId: 's1',
      subjectId: 'sub1',
    );

    expect(mistakes, isEmpty);
  });

  test('getMistakesFromSession handles exception gracefully', () async {
    attemptRepo.shouldThrow = true;

    final mistakes = await service.getMistakesFromSession(
      studentId: 's1',
      subjectId: 'sub1',
    );

    expect(mistakes, isEmpty);
  });

  test('getPendingMistakes handles exception gracefully', () async {
    attemptRepo.shouldThrow = true;

    final pending = await service.getPendingMistakes(
      studentId: 's1',
      subjectId: 'sub1',
    );

    expect(pending, isEmpty);
  });

  test('isQuestionCorrected handles exception gracefully', () async {
    attemptRepo.shouldThrow = true;

    final corrected = await service.isQuestionCorrected('q1');
    expect(corrected, isFalse);
  });

  test('extractRedoQuestions returns empty for empty input', () {
    final result = service.extractRedoQuestions([]);
    expect(result, isEmpty);
  });

  test('extractRedoQuestions extracts all questions', () {
    final mistakes = [
      MistakeEntry(
        question: _createQ(id: 'q1'),
        correctAnswer: 'A',
      ),
      MistakeEntry(
        question: _createQ(id: 'q2'),
        correctAnswer: 'B',
      ),
    ];
    final result = service.extractRedoQuestions(mistakes);
    expect(result, hasLength(2));
    expect(result[0].id, 'q1');
    expect(result[1].id, 'q2');
  });

  test('getMistakesFromSession uses markscheme for correct answer', () async {
    questionRepo.addQuestion(Question(
      id: 'q1',
      text: 'Test?',
      type: QuestionType.singleChoice,
      subjectId: 'sub1',
      topicId: 't1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      markscheme: Markscheme(
        questionId: 'q1',
        correctAnswer: 'Correct Answer',
        explanation: 'Exp',
      ),
    ));

    attemptRepo.addAttempt(StudentAttempt(
      id: 'a1',
      studentId: 's1',
      questionId: 'q1',
      subjectId: 'sub1',
      isCorrect: false,
      timestamp: DateTime(2026, 1, 1),
      userAnswer: 'wrong',
    ));

    final mistakes = await service.getMistakesFromSession(
      studentId: 's1',
      subjectId: 'sub1',
    );

    expect(mistakes, hasLength(1));
    expect(mistakes.data!.first.correctAnswer, 'Correct Answer');
    expect(mistakes.data!.first.explanation, 'Exp');
  });
}

class _FailingAttemptRepository extends AttemptRepository {
  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.failure('Storage error');
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    return Result.failure('Storage error');
  }

  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async {
    return Result.failure('Storage error');
  }
}

class _FailingQuestionRepository extends QuestionRepository {
  @override
  Future<Result<Question?>> get(String id) async {
    return Result.failure('Storage error');
  }
}

class _FakeAttemptRepo3 extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];
  bool shouldThrow = false;

  @override
  Future<void> init() async {}

  void addAttempt(StudentAttempt attempt) {
    _attempts.add(attempt);
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    if (shouldThrow) throw Exception('Error');
    return Result.success(
        _attempts.where((a) => a.studentId == studentId).toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    if (shouldThrow) throw Exception('Error');
    return Result.success(_attempts
        .where((a) => a.studentId == studentId && a.subjectId == subjectId)
        .toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async {
    if (shouldThrow) throw Exception('Error');
    return Result.success(
        _attempts.where((a) => a.questionId == questionId).toList());
  }
}

class _FakeQuestionRepo3 extends QuestionRepository {
  final Map<String, Question> _questions = {};

  @override
  Future<void> init() async {}

  void addQuestion(Question q) {
    _questions[q.id] = q;
  }

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(_questions[id]);
  }
}

Question _createQ({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  int difficulty = 1,
  String? srDataJson,
}) {
  return Question(
    id: id,
    text: 'Sample question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    difficulty: difficulty,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
    srDataJson: srDataJson,
  );
}
