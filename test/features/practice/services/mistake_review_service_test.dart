import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
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
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return _attempts.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<List<StudentAttempt>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    return _attempts
        .where((a) => a.studentId == studentId && a.subjectId == subjectId)
        .toList();
  }

  @override
  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    return _attempts.where((a) => a.questionId == questionId).toList();
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
  Future<Question?> get(String id) async {
    return _questions[id];
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
        expect(mistakes.first.attempt!.questionId, 'q1');
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

        final redoQuestions = service.extractRedoQuestions(mistakes);
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
  });
}
