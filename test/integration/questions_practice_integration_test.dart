import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;

class _FakeAttemptRepo extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];

  @override
  Future<void> init() async {}

  void addAttempt(StudentAttempt attempt) {
    _attempts.add(attempt);
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
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(
        _attempts.where((a) => a.studentId == studentId).toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getByQuestion(String questionId) async {
    return Result.success(
        _attempts.where((a) => a.questionId == questionId).toList());
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
  Future<Result<void>> create(Question question) async {
    _questions[question.id] = question;
    return Result.success(null);
  }
}

void main() {
  group('Questions + Practice Integration', () {
    const studentId = 'test-student';
    const subjectId = 'biology';
    final now = DateTime.now();

    late _FakeQuestionRepo questionRepo;
    late _FakeAttemptRepo attemptRepo;

    setUp(() {
      questionRepo = _FakeQuestionRepo();
      attemptRepo = _FakeAttemptRepo();
    });

    Question makeQuestion({required String id, required String topicId}) {
      return Question(
        id: id,
        text: 'Question $id?',
        type: QuestionType.singleChoice,
        subjectId: subjectId,
        topicId: topicId,
        markscheme: Markscheme(correctAnswer: 'A', explanation: 'Explanation $id'),
        options: ['A', 'B', 'C', 'D'],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      );
    }

    StudentAttempt makeAttempt({
      required String id,
      required String questionId,
      bool isCorrect = false,
    }) {
      return StudentAttempt(
        id: id,
        studentId: studentId,
        questionId: questionId,
        subjectId: subjectId,
        isCorrect: isCorrect,
        timestamp: now.subtract(const Duration(hours: 1)),
        userAnswer: isCorrect ? 'A' : 'B',
      );
    }

    test('full question source to practice pipeline', () async {
      final qCellStructure = makeQuestion(id: 'q-cell', topicId: 'cell-biology');
      final qGenetics = makeQuestion(id: 'q-gen', topicId: 'genetics');
      final qEcology = makeQuestion(id: 'q-eco', topicId: 'ecology');
      final qMetabolism = makeQuestion(id: 'q-meta', topicId: 'metabolism');

      questionRepo.addQuestion(qCellStructure);
      questionRepo.addQuestion(qGenetics);
      questionRepo.addQuestion(qEcology);
      questionRepo.addQuestion(qMetabolism);

      await attemptRepo.save('a1', makeAttempt(id: 'a1', questionId: 'q-cell', isCorrect: false));
      await attemptRepo.save('a2', makeAttempt(id: 'a2', questionId: 'q-gen', isCorrect: false));
      await attemptRepo.save('a3', makeAttempt(id: 'a3', questionId: 'q-eco', isCorrect: true));

      final mistakeRepo = MistakeReviewService(
        attemptRepo: attemptRepo,
        questionRepo: questionRepo,
      );

      final pendingMistakes = await mistakeRepo.getPendingMistakes(
        studentId: studentId,
        subjectId: subjectId,
      );

      expect(pendingMistakes.data!, hasLength(2));
      final mistakeIds = pendingMistakes.data!.map((m) => m.question.id).toSet();
      expect(mistakeIds, contains('q-cell'));
      expect(mistakeIds, contains('q-gen'));
      expect(mistakeIds, isNot(contains('q-eco')));
      expect(mistakeIds, isNot(contains('q-meta')));

      for (final mistake in pendingMistakes.data!) {
        expect(mistake.correctAnswer, isNotEmpty);
        expect(mistake.explanation, isNotNull);
      }

      final redoQuestions = mistakeRepo.extractRedoQuestions(pendingMistakes.data!);
      expect(redoQuestions, hasLength(2));

      final scorer = ReadinessScorer();
      final scored = await scorer.scoreQuestions(redoQuestions);
      expect(scored, hasLength(2));
      expect(scored.every((s) => s.score >= 0.0 && s.score <= 1.0), isTrue);
      expect(scored[0].score, greaterThanOrEqualTo(scored[1].score));

      await attemptRepo.save('a4', makeAttempt(id: 'a4', questionId: 'q-cell', isCorrect: true));

      final updatedPending = await mistakeRepo.getPendingMistakes(
        studentId: studentId,
        subjectId: subjectId,
      );

      expect(updatedPending.data!, hasLength(1));
      expect(updatedPending.data!.first.question.id, 'q-gen');
    });

    test('mistake review with date-filtered session', () async {
      final qRecent = makeQuestion(id: 'q-recent', topicId: 'cell-biology');
      final qOld = makeQuestion(id: 'q-old', topicId: 'genetics');
      questionRepo.addQuestion(qRecent);
      questionRepo.addQuestion(qOld);

      await attemptRepo.save('a-old', StudentAttempt(
        id: 'a-old',
        studentId: studentId,
        questionId: 'q-old',
        subjectId: subjectId,
        isCorrect: false,
        timestamp: now.subtract(const Duration(days: 14)),
        userAnswer: 'B',
      ));

      await attemptRepo.save('a-recent', StudentAttempt(
        id: 'a-recent',
        studentId: studentId,
        questionId: 'q-recent',
        subjectId: subjectId,
        isCorrect: false,
        timestamp: now.subtract(const Duration(hours: 2)),
        userAnswer: 'C',
      ));

      final mistakeRepo = MistakeReviewService(
        attemptRepo: attemptRepo,
        questionRepo: questionRepo,
      );

      final sessionMistakes = await mistakeRepo.getMistakesFromSession(
        studentId: studentId,
        subjectId: subjectId,
        after: now.subtract(const Duration(days: 7)),
      );

      expect(sessionMistakes.data!, hasLength(1));
      expect(sessionMistakes.data!.first.question.id, 'q-recent');
      expect(sessionMistakes.data!.first.correctAnswer, 'A');
    });

    test('spaced repetition integrates questions and attempts', () async {
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
          attemptRepositoryProvider.overrideWithValue(attemptRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final q1 = makeQuestion(id: 'q-sr1', topicId: 'cell-biology');
      final q2 = makeQuestion(id: 'q-sr2', topicId: 'genetics');
      questionRepo.addQuestion(q1);
      questionRepo.addQuestion(q2);

      await attemptRepo.save('sr-a1', makeAttempt(id: 'sr-a1', questionId: 'q-sr1', isCorrect: true));
      await attemptRepo.save('sr-a2', makeAttempt(id: 'sr-a2', questionId: 'q-sr2', isCorrect: false));

      final mistakes = await container.read(mistakeReviewServiceProvider).getPendingMistakes(
        studentId: studentId,
        subjectId: subjectId,
      );

      expect(mistakes.data!, hasLength(1));
      expect(mistakes.data!.first.question.id, 'q-sr2');

      final redoQuestions = container.read(mistakeReviewServiceProvider).extractRedoQuestions(mistakes.data!);
      expect(redoQuestions, hasLength(1));
      expect(redoQuestions.first.id, 'q-sr2');
    });
  });
}
