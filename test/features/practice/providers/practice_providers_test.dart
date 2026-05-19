import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/cross_feature_integrator.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/services/student_id_service.dart';
import '../../../helpers/fakes.dart';

void main() {
  group('PracticeProviders', () {
    test('spacedRepetitionServiceProvider can be overridden', () {
      final fakeService = SpacedRepetitionService(
        questionRepo: QuestionRepository(),
        attemptRepo: FakeAttemptRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          spacedRepetitionServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionServiceProvider);
      expect(result, same(fakeService));
    });

    test('questionRepositoryProvider can be overridden', () {
      final fakeRepo = QuestionRepository();
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(questionRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('masteryGraphServiceProvider can be overridden', () {
      final fakeService = FakeMasteryGraphService();
      final container = ProviderContainer(
        overrides: [
          masteryGraphServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryGraphServiceProvider);
      expect(result, same(fakeService));
    });

    test('sessionRepositoryProvider can be overridden', () {
      final fakeRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(sessionRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('subjectRepositoryProvider can be overridden', () {
      final fakeRepo = SubjectRepository();
      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('attemptRepositoryProvider can be overridden', () {
      final fakeRepo = FakeAttemptRepository();
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(attemptRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('masteryStateRepositoryProvider can be overridden', () {
      final fakeRepo = FakeMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          masteryStateRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryStateRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('questionMasteryStateRepositoryProvider can be overridden', () {
      final fakeRepo = FakeQuestionMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          questionMasteryStateRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(questionMasteryStateRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('topicDependencyRepositoryProvider can be overridden', () {
      final fakeRepo = FakeTopicDependencyRepository();
      final container = ProviderContainer(
        overrides: [
          topicDependencyRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(topicDependencyRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('questionEvaluationRepositoryProvider can be overridden', () {
      final fakeRepo = FakeQuestionEvaluationRepository();
      final container = ProviderContainer(
        overrides: [
          questionEvaluationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(questionEvaluationRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('masteryGraphServiceProvider is wired to masteryStateRepositoryProvider', () {
      final fakeMasteryState = FakeMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          masteryStateRepositoryProvider.overrideWithValue(fakeMasteryState),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(masteryGraphServiceProvider);
      expect(service, isA<MasteryGraphService>());
    });

    test('masteryRecorderProvider uses overridden attemptRepositoryProvider for recording', () {
      final seededAttemptRepo = FakeAttemptRepository();
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(seededAttemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final recorder = container.read(masteryRecorderProvider);
      expect(recorder, isA<MasteryRecorder>());
    });

    test('spacedRepetitionEngineProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(spacedRepetitionEngineProvider);
      final b = container.read(spacedRepetitionEngineProvider);
      expect(a, same(b));
    });

    test('readinessScorerProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(readinessScorerProvider);
      final b = container.read(readinessScorerProvider);
      expect(a, same(b));
    });

    test('examSessionServiceProvider can be overridden', () {
      final fakeService = FakeExamSessionService();
      final container = ProviderContainer(
        overrides: [
          examSessionServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(examSessionServiceProvider);
      expect(result, same(fakeService));
    });

    test('examSessionServiceProvider is singleton', () {
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
        ],
      );
      addTearDown(container.dispose);

      final a = container.read(examSessionServiceProvider);
      final b = container.read(examSessionServiceProvider);
      expect(a, same(b));
    });

  });

  group('PracticeProviders behavioral assertions', () {
    test('attemptRepositoryProvider with seeded data returns attempts', () async {
      final attempts = [
        StudentAttempt(
          id: 'a1',
          studentId: 'student-1',
          questionId: 'q1',
          subjectId: 'sub-1',
          isCorrect: true,
          timestamp: DateTime(2026, 5, 1),
        ),
        StudentAttempt(
          id: 'a2',
          studentId: 'student-1',
          questionId: 'q2',
          subjectId: 'sub-1',
          isCorrect: false,
          timestamp: DateTime(2026, 5, 1),
        ),
      ];
      final seededRepo = FakeAttemptRepositoryWithSeed(attempts);

      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(seededRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(attemptRepositoryProvider);
      final allResult = await repo.getAll();
      expect(allResult.isSuccess, isTrue);
      expect(allResult.data!.length, 2);
    });

    test('mistakeReviewServiceProvider uses overridden attemptRepo to find mistakes', () async {
      final attempts = [
        StudentAttempt(
          id: 'a1',
          studentId: 'student-1',
          questionId: 'q1',
          subjectId: 'sub-1',
          isCorrect: false,
          timestamp: DateTime(2026, 5, 1, 10, 0),
        ),
      ];
      final seededRepo = FakeAttemptRepositoryWithSeed(attempts);
      final fakeQuestionRepo = _FakeQuestionRepo([]);

      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(seededRepo),
          questionRepositoryProvider.overrideWithValue(fakeQuestionRepo),
        ],
      );
      addTearDown(container.dispose);

      final mistakeService = container.read(mistakeReviewServiceProvider);
      final mistakes = await mistakeService.getMistakesFromSession(
        studentId: 'student-1',
        subjectId: 'sub-1',
        after: DateTime(2026, 5, 1, 9, 0),
      );
      expect(mistakes, isA<List>());
    });

    test('masteryGraphServiceProvider handles error-state when repo fails', () async {
      final throwingRepo = _FailingMasteryStateRepo();

      final container = ProviderContainer(
        overrides: [
          masteryStateRepositoryProvider.overrideWithValue(throwingRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(masteryGraphServiceProvider);
      final result = await service.getAllTopicMastery('student-1');
      expect(result.isFailure, isTrue);
    });

    test('spacedRepetitionServiceProvider updateNextReviewDate uses overridden repos', () async {
      final now = DateTime(2026, 5, 1);
      final question = Question(
        id: 'q-behave',
        subjectId: 'sub-1',
        topicId: 't-1',
        text: 'Behavioral test question?',
        type: QuestionType.typedAnswer,
        difficulty: 2,
        markscheme: Markscheme(correctAnswer: 'yes'),
        createdAt: now,
        updatedAt: now,
      );
      final questionRepo = _FakeQuestionRepo([question]);
      final attemptRepo = FakeAttemptRepository();

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
          attemptRepositoryProvider.overrideWithValue(attemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final srService = container.read(spacedRepetitionServiceProvider);
      final result = await srService.updateNextReviewDate('q-behave', 0.9);
      expect(result.isSuccess, isTrue);
    });

    test('spacedRepetitionServiceProvider handles error-state when questionRepo fails', () async {
      final failingQuestionRepo = _FailingQuestionRepo();
      final attemptRepo = FakeAttemptRepository();

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(failingQuestionRepo),
          attemptRepositoryProvider.overrideWithValue(attemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final srService = container.read(spacedRepetitionServiceProvider);
      final result = await srService.updateNextReviewDate('q-nonexistent', 0.5);
      expect(result.isFailure, isTrue);
    });

    test('mistakeReviewServiceProvider handles error-state when attemptRepo fails', () async {
      final failingAttemptRepo = _FailingAttemptRepository();
      final questionRepo = _FakeQuestionRepo([]);

      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(failingAttemptRepo),
          questionRepositoryProvider.overrideWithValue(questionRepo),
        ],
      );
      addTearDown(container.dispose);

      final mistakeService = container.read(mistakeReviewServiceProvider);
      final mistakes = await mistakeService.getMistakesFromSession(
        studentId: 'student-1',
        subjectId: 'sub-1',
      );
      expect(mistakes, isEmpty);
    });

    test('examSessionServiceProvider wired to overridden dependencies', () {
      final fakeSessionRepo = FakeSessionRepository();
      final fakeStudentId = FakeStudentIdService();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
          studentIdServiceProvider.overrideWithValue(fakeStudentId),
        ],
      );
      addTearDown(container.dispose);

      final examService = container.read(examSessionServiceProvider);
      expect(examService, isA<ExamSessionService>());
    });

    test('examSessionServiceProvider selectQuestions filters by subject and respects count', () {
      final now = DateTime(2026, 5, 1);
      final questions = [
        Question(id: 'q1', subjectId: 'sub-1', topicId: 't-1', text: 'q1', type: QuestionType.typedAnswer, difficulty: 2, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
        Question(id: 'q2', subjectId: 'sub-2', topicId: 't-2', text: 'q2', type: QuestionType.typedAnswer, difficulty: 3, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
        Question(id: 'q3', subjectId: 'sub-1', topicId: 't-1', text: 'q3', type: QuestionType.typedAnswer, difficulty: 4, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
      ];
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
        ],
      );
      addTearDown(container.dispose);

      final examService = container.read(examSessionServiceProvider);
      final config = ExamConfig(subjectId: 'sub-1', durationMinutes: 60, questionCount: 2);
      final selected = examService.selectQuestions(pool: questions, config: config);

      expect(selected.length, 2);
      expect(selected.every((q) => q.subjectId == 'sub-1'), isTrue);
    });

    test('examSessionServiceProvider selectQuestions respects topicIds filter', () {
      final now = DateTime(2026, 5, 1);
      final questions = [
        Question(id: 'q1', subjectId: 'sub-1', topicId: 't-1', text: 'q1', type: QuestionType.typedAnswer, difficulty: 2, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
        Question(id: 'q2', subjectId: 'sub-1', topicId: 't-2', text: 'q2', type: QuestionType.typedAnswer, difficulty: 3, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
        Question(id: 'q3', subjectId: 'sub-1', topicId: 't-3', text: 'q3', type: QuestionType.typedAnswer, difficulty: 4, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
      ];
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
        ],
      );
      addTearDown(container.dispose);

      final examService = container.read(examSessionServiceProvider);
      final config = ExamConfig(subjectId: 'sub-1', durationMinutes: 60, questionCount: 3, topicIds: ['t-1', 't-3']);
      final selected = examService.selectQuestions(pool: questions, config: config);

      expect(selected.length, 2);
      expect(selected.every((q) => q.topicId == 't-1' || q.topicId == 't-3'), isTrue);
    });

    test('examSessionServiceProvider selectQuestions handles difficulty distribution', () {
      final now = DateTime(2026, 5, 1);
      final questions = [
        Question(id: 'q1', subjectId: 'sub-1', topicId: 't-1', text: 'q1', type: QuestionType.typedAnswer, difficulty: 1, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
        Question(id: 'q2', subjectId: 'sub-1', topicId: 't-1', text: 'q2', type: QuestionType.typedAnswer, difficulty: 1, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
        Question(id: 'q3', subjectId: 'sub-1', topicId: 't-1', text: 'q3', type: QuestionType.typedAnswer, difficulty: 3, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
        Question(id: 'q4', subjectId: 'sub-1', topicId: 't-1', text: 'q4', type: QuestionType.typedAnswer, difficulty: 5, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now),
      ];
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
        ],
      );
      addTearDown(container.dispose);

      final examService = container.read(examSessionServiceProvider);
      final config = ExamConfig(subjectId: 'sub-1', durationMinutes: 60, questionCount: 3, easyCount: 1, mediumCount: 1, hardCount: 1);
      final selected = examService.selectQuestions(pool: questions, config: config);

      expect(selected.length, 3);
    });

    test('examSessionServiceProvider startExam activates and cancelExam deactivates', () {
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
        ],
      );
      addTearDown(container.dispose);

      final examService = container.read(examSessionServiceProvider);

      expect(examService.isActive, isFalse);
      expect(examService.examActiveNotifier.value, isFalse);

      examService.startExam(ExamConfig(subjectId: 'sub-1', durationMinutes: 60, questionCount: 1));

      expect(examService.isActive, isTrue);
      expect(examService.examActiveNotifier.value, isTrue);

      examService.cancelExam();

      expect(examService.isActive, isFalse);
      expect(examService.examActiveNotifier.value, isFalse);
      expect(examService.timeRemainingNotifier.value, Duration.zero);
    });

    test('examSessionServiceProvider finishExam saves session to repository', () async {
      final fakeSessionRepo = FakeSessionRepository();
      final fakeStudentId = FakeStudentIdService();
      fakeStudentId.setStudentId('test-student');
      final now = DateTime(2026, 5, 1);

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
          studentIdServiceProvider.overrideWithValue(fakeStudentId),
        ],
      );
      addTearDown(container.dispose);

      final examService = container.read(examSessionServiceProvider);
      examService.startExam(ExamConfig(subjectId: 'sub-1', durationMinutes: 60, questionCount: 1));

      final question = Question(id: 'q1', subjectId: 'sub-1', topicId: 't-1', text: 'q1', type: QuestionType.typedAnswer, difficulty: 2, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now);
      final config = ExamConfig(subjectId: 'sub-1', durationMinutes: 60, questionCount: 1);
      final questionResults = [
        ExamQuestionResult(question: question, isCorrect: true, timeSpentMs: 5000),
      ];

      final result = await examService.finishExam(config: config, questionResults: questionResults);

      expect(result.accuracy, 1.0);
      expect(result.totalCorrect, 1);
      expect(result.questionResults.length, 1);

      final allSessionsResult = await fakeSessionRepo.getAll();
      expect(allSessionsResult.isSuccess, isTrue);
      expect(allSessionsResult.data!.length, 1);
      expect(allSessionsResult.data!.first.subjectId, 'sub-1');
      expect(allSessionsResult.data!.first.completed, isTrue);
    });

    test('readinessScorerProvider scoreQuestions uses seeded mastery data', () async {
      final now = DateTime(2026, 5, 1);
      final topicMastery = MasteryState.initial(studentId: 'test-student', topicId: 't-1');
      final questionMastery = QuestionMasteryState.initial(
        studentId: 'test-student',
        questionId: 'q1',
        now: now,
      );
      final seededService = _SeededMasteryGraphService(
        topicMastery: [topicMastery],
        questionMastery: [questionMastery],
      );

      final container = ProviderContainer(
        overrides: [
          masteryGraphServiceProvider.overrideWithValue(seededService),
          studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
        ],
      );
      addTearDown(container.dispose);

      final scorer = container.read(readinessScorerProvider);
      final question = Question(id: 'q1', subjectId: 'sub-1', topicId: 't-1', text: 'q1', type: QuestionType.typedAnswer, difficulty: 2, markscheme: Markscheme(correctAnswer: 'yes'), createdAt: now, updatedAt: now);

      final scored = await scorer.scoreQuestions([question]);

      expect(scored.length, 1);
      expect(scored.first.question.id, 'q1');
      expect(scored.first.score, greaterThanOrEqualTo(0.0));
      expect(scored.first.score, lessThanOrEqualTo(1.0));
    });

    test('spacedRepetitionEngineProvider maps confidence to grade correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(spacedRepetitionEngineProvider);

      expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 5), 5);
      expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 1), 3);
      expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 0), 0);
      expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 5), 2);
    });

    test('spacedRepetitionEngineProvider scheduleReview computes correct intervals', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(spacedRepetitionEngineProvider);
      final now = DateTime(2026, 5, 1);

      final result = engine.scheduleReview(
        questionId: 'q1',
        grade: 5,
        now: now,
      );

      expect(result.nextReview, now.add(const Duration(days: 1)));
      expect(result.updatedData.repetitions, 1);
      expect(result.updatedData.easeFactor, greaterThan(2.5));
    });
  });
}

class _FakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepo([this._questions = const []]);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.success(_questions.where((q) => q.id == key).firstOrNull);
}

class _FailingQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.failure('Question repo failure');

  @override
  Future<Result<List<Question>>> getAll() async =>
      Result.failure('Question repo failure');
}

class _FailingMasteryStateRepo extends MasteryStateRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAll() async => Result.failure('Repo failure');

  Future<Result<List<MasteryState>>> getBySubject(String subjectId) async =>
      Result.failure('Repo failure');
}

class FakeMasteryStateRepository extends MasteryStateRepository {
  FakeMasteryStateRepository();
}

class FakeQuestionMasteryStateRepository extends QuestionMasteryStateRepository {
  FakeQuestionMasteryStateRepository();
}

class FakeTopicDependencyRepository extends TopicDependencyRepository {
  FakeTopicDependencyRepository();
}

class FakeQuestionEvaluationRepository extends QuestionEvaluationRepository {
  FakeQuestionEvaluationRepository();
}

class FakeAttemptRepository extends AttemptRepository {
  FakeAttemptRepository();
}

class FakeMasteryGraphService extends MasteryGraphService {
  FakeMasteryGraphService();
}

class FakeMasteryRecorder extends MasteryRecorder {
  FakeMasteryRecorder()
      : super(
          masteryGraphService: MasteryGraphService(),
          srEngine: SpacedRepetitionEngine(),
          attemptRepo: AttemptRepository(),
          questionMasteryRepo: QuestionMasteryStateRepository(),
          questionRepo: QuestionRepository(),
        );
}

class FakeExamSessionService extends ExamSessionService {
  FakeExamSessionService()
      : super(
          sessionRepo: SessionRepository(),
          studentIdService: FakeStudentIdService(),
        );
}

class FakeMistakeReviewService extends MistakeReviewService {
  FakeMistakeReviewService()
      : super(
          attemptRepo: AttemptRepository(),
          questionRepo: QuestionRepository(),
        );
}

class FakeCrossFeatureIntegrator extends CrossFeatureIntegrator {
  FakeCrossFeatureIntegrator()
      : super(
          sessionRepo: SessionRepository(),
          studentIdService: FakeStudentIdService(),
        );
}

class _SeededMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> _topicMastery;
  final List<QuestionMasteryState> _questionMastery;

  _SeededMasteryGraphService({
    List<MasteryState>? topicMastery,
    List<QuestionMasteryState>? questionMastery,
  })  : _topicMastery = topicMastery ?? [],
        _questionMastery = questionMastery ?? [],
        super();

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return Result.success(_topicMastery);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAllQuestionMastery(
      String studentId) async {
    return Result.success(_questionMastery);
  }
}

class _FailingAttemptRepository extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getAll() async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<StudentAttempt?>> get(String key) async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<void>> delete(String key) async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    return Result.failure('Attempt repo failure');
  }
}

class FakeAttemptRepositoryWithSeed extends AttemptRepository {
  final List<StudentAttempt> _attempts;
  FakeAttemptRepositoryWithSeed(this._attempts);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success(_attempts);

  @override
  Future<Result<StudentAttempt?>> get(String key) async =>
      Result.success(_attempts.where((a) => a.id == key).firstOrNull);

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    return Result.success(_attempts);
  }
}
