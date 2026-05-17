import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];
  bool trackSessionCalls = false;
  int sessionCallCount = 0;

  @override
  Future<void> init() async {}

  void addAttempt(StudentAttempt attempt) {
    _attempts.add(attempt);
  }

  @override
  Future<List<StudentAttempt>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    if (trackSessionCalls) sessionCallCount++;
    return _attempts
        .where((a) => a.studentId == studentId && a.subjectId == subjectId)
        .toList();
  }

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    return _attempts.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    return _attempts.where((a) => a.questionId == questionId).toList();
  }
}

class _FakeQuestionRepo extends QuestionRepository {
  final Map<String, Question> _questions = {};

  @override
  Future<void> init() async {}

  void addQuestion(Question question) {
    _questions[question.id] = question;
  }

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(_questions[id]);
  }

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
  Future<Result<List<Question>>> getByTopic(String topicId) async {
    return Result.success(
      _questions.values.where((q) => q.topicId == topicId).toList(),
    );
  }

  @override
  Future<Result<void>> create(Question question) async {
    _questions[question.id] = question;
    return Result.success(null);
  }
}

void main() {
  group('Practice + Teaching Integration — mistake review produces re-teach',
      () {
    test(
        'getPendingMistakes identifies unanswered incorrect questions '
        'and extractRedoQuestions returns them for re-teaching', () async {
      const studentId = 'test-student';
      const subjectId = 'math';

      final now = DateTime.now();

      // Set up questions
      final questionRepo = _FakeQuestionRepo();
      final q1 = Question(
        id: 'q1',
        text: 'What is 2+2?',
        type: QuestionType.typedAnswer,
        subjectId: subjectId,
        topicId: 'arithmetic',
        markscheme: Markscheme(correctAnswer: '4', explanation: '2+2=4'),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );
      final q2 = Question(
        id: 'q2',
        text: 'What is 5*3?',
        type: QuestionType.typedAnswer,
        subjectId: subjectId,
        topicId: 'arithmetic',
        markscheme: Markscheme(correctAnswer: '15', explanation: '5*3=15'),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );
      final q3 = Question(
        id: 'q3',
        text: 'What is 10/2?',
        type: QuestionType.typedAnswer,
        subjectId: subjectId,
        topicId: 'arithmetic',
        markscheme: Markscheme(correctAnswer: '5', explanation: '10/2=5'),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );
      questionRepo.addQuestion(q1);
      questionRepo.addQuestion(q2);
      questionRepo.addQuestion(q3);

      // Set up incorrect attempts (mistakes) — never answered correctly
      final attemptRepo = _FakeAttemptRepo();
      attemptRepo.addAttempt(StudentAttempt(
        id: 'a1',
        studentId: studentId,
        questionId: 'q1',
        subjectId: subjectId,
        isCorrect: false,
        timestamp: now.subtract(const Duration(days: 1)),
        userAnswer: '3',
      ));
      attemptRepo.addAttempt(StudentAttempt(
        id: 'a2',
        studentId: studentId,
        questionId: 'q2',
        subjectId: subjectId,
        isCorrect: false,
        timestamp: now.subtract(const Duration(days: 2)),
        userAnswer: '10',
      ));

      // q3 has a correct answer followed by incorrect — should NOT appear
      attemptRepo.addAttempt(StudentAttempt(
        id: 'a3_correct',
        studentId: studentId,
        questionId: 'q3',
        subjectId: subjectId,
        isCorrect: true,
        timestamp: now.subtract(const Duration(days: 3)),
        userAnswer: '5',
      ));
      attemptRepo.addAttempt(StudentAttempt(
        id: 'a3_wrong',
        studentId: studentId,
        questionId: 'q3',
        subjectId: subjectId,
        isCorrect: false,
        timestamp: now.subtract(const Duration(days: 1)),
        userAnswer: '2',
      ));

      // Wire through the container using the real provider
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
          attemptRepositoryProvider.overrideWithValue(attemptRepo),
        ],
      );

      final mistakeService = container.read(mistakeReviewServiceProvider);

      // Get pending mistakes
      final pendingMistakes =
          await mistakeService.getPendingMistakes(
        studentId: studentId,
        subjectId: subjectId,
      );

      // q1 and q2 should be pending mistakes (last attempt incorrect,
      // no prior correct attempt). q3 should NOT be pending (had correct).
      expect(pendingMistakes.length, 2);
      final mistakeQuestionIds =
          pendingMistakes.map((m) => m.question.id).toSet();
      expect(mistakeQuestionIds, contains('q1'));
      expect(mistakeQuestionIds, contains('q2'));
      expect(mistakeQuestionIds, isNot(contains('q3')));

      // Verify mistake details
      for (final mistake in pendingMistakes) {
        expect(mistake.correctAnswer, isNotEmpty);
        expect(mistake.explanation, isNotNull);
      }

      // Extract re-teach questions
      final redoQuestions = mistakeService.extractRedoQuestions(pendingMistakes);
      expect(redoQuestions.length, 2);
      expect(redoQuestions.map((q) => q.id).toSet(),
          equals({'q1', 'q2'}));

      container.dispose();
    });

    test(
        'getMistakesFromSession filters by date and returns '
        'questions needing re-teaching', () async {
      const studentId = 'test-student';
      const subjectId = 'physics';
      final now = DateTime.now();

      final questionRepo = _FakeQuestionRepo();
      final q1 = Question(
        id: 'q_p1',
        text: 'Question 1',
        type: QuestionType.singleChoice,
        subjectId: subjectId,
        topicId: 'mechanics',
        markscheme: Markscheme(correctAnswer: 'A', explanation: 'Explanation'),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );
      final q2 = Question(
        id: 'q_p2',
        text: 'Question 2',
        type: QuestionType.singleChoice,
        subjectId: subjectId,
        topicId: 'mechanics',
        markscheme: Markscheme(correctAnswer: 'C', explanation: 'Explanation'),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );
      questionRepo.addQuestion(q1);
      questionRepo.addQuestion(q2);

      final attemptRepo = _FakeAttemptRepo();
      // Old incorrect attempt (before cutoff)
      attemptRepo.addAttempt(StudentAttempt(
        id: 'old_wrong',
        studentId: studentId,
        questionId: 'q_p1',
        subjectId: subjectId,
        isCorrect: false,
        timestamp: now.subtract(const Duration(days: 10)),
        userAnswer: 'B',
      ));
      // Recent incorrect attempt (after cutoff)
      attemptRepo.addAttempt(StudentAttempt(
        id: 'recent_wrong',
        studentId: studentId,
        questionId: 'q_p2',
        subjectId: subjectId,
        isCorrect: false,
        timestamp: now.subtract(const Duration(hours: 6)),
        userAnswer: 'D',
      ));

      attemptRepo.trackSessionCalls = true;

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
          attemptRepositoryProvider.overrideWithValue(attemptRepo),
        ],
      );

      final mistakeService = container.read(mistakeReviewServiceProvider);

      // Get mistakes from the last 24 hours
      final sessionMistakes = await mistakeService.getMistakesFromSession(
        studentId: studentId,
        subjectId: subjectId,
        after: now.subtract(const Duration(days: 1)),
      );

      // Only the recent wrong attempt should be included
      expect(sessionMistakes.length, 1);
      expect(sessionMistakes.first.question.id, 'q_p2');
      expect(sessionMistakes.first.correctAnswer, 'C');

      // extractRedoQuestions for re-teaching
      final redoQuestions =
          mistakeService.extractRedoQuestions(sessionMistakes);
      expect(redoQuestions.length, 1);
      expect(redoQuestions.first.id, 'q_p2');
      expect(redoQuestions.first.text, 'Question 2');

      container.dispose();
    });
  });
}
